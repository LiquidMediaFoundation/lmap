// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

// =============================================================================
// LMAP Registry V5 — Reference Implementation of LMAP Specification v1.0
//
// The Liquid Media Access Protocol (LMAP) is an open standard for tokenized
// media ownership and peer-distributed delivery, stewarded by the Liquid
// Media Foundation. This contract is the foundation's reference distribution
// registry implementing LMAP Spec v1.0.
//
// Design principles (vs. legacy WyllohRegistryProtocolV4_1):
//
//   1. Permissionless minting. Anyone can call createTitle(). The publisher
//      identity is the caller's wallet (cryptographically authentic). No
//      role-gated minting; curation happens at the application layer via the
//      Liquid Media Foundation's verified publishers registry and individual
//      platforms' editorial choices.
//
//   2. Media-agnostic. Each title carries a `mediaType` identifier. LMAP 1.0
//      ships film as the canonical reference rights-tier schema; companion
//      schemas for music, software, books, etc. are added off-chain without
//      contract changes.
//
//   3. Three-way revenue split set per title at mint time:
//      - Protocol: 2.5% (immutable, hardcoded)
//      - Publisher: 0-25% (set per title, immutable)
//      - Author: remainder, distributed via per-title shareholder mapping
//
//   4. Updateable platformTreasury via timelocked admin proposal. Foundation
//      multi-sig holds ADMIN_ROLE, proposes updates, executes after timelock.
//
//   5. ERC-4337 paymaster hook for gas abstraction (paymaster contract
//      deployed and wired separately).
//
// Royalty enforcement boundary (documented honestly):
//
//   - Sales through this contract's purchaseTokens / buyListing /
//     finalizeAuction functions enforce all splits cryptographically.
//   - Sales through external marketplaces honoring ERC-2981 will pay the
//     configured royalty (caveat: marketplace must respect the standard).
//   - Direct ERC-1155 transfers (safeTransferFrom) preserve the gift /
//     inheritance use case and do not trigger royalties. This is a property
//     of the underlying token standard, not a defect.
//
// Stewardship: Liquid Media Foundation. Reference implementation operated
// by Wylloh, the first commercial LMAP implementation (focused on film).
// Other commercial implementations are welcome.
// =============================================================================

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILMAPVerified.sol";

// === Custom errors (gas-efficient) ===
error Unauthorized();
error InvalidInput();
error InsufficientBalance();
error NotFound();
error Expired();
error InvalidState();
error TimelockNotElapsed();
error PublisherFeeTooHigh();
error RoyaltyTooHigh();
error TooManyShareholders();
error SharesExceedTotal();
error TitleIdAlreadyUsed();

contract LMAPRegistryV5 is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    AccessControl,
    ReentrancyGuard,
    ILMAPVerified
{
    // =========================================================================
    // CONSTANTS
    // =========================================================================

    /// @notice Foundation multi-sig and emergency operations role.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Polygon mainnet USDC.e (bridged USDC). Hardcoded as the only
    ///         payment token for LMAP 1.0; future versions may parameterize.
    IERC20 public constant USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    /// @notice Protocol fee in basis points (immutable). 2.5%.
    uint256 public constant PROTOCOL_FEE_BPS = 250;

    /// @notice Maximum publisher fee in basis points. 25%.
    uint256 public constant MAX_PUBLISHER_FEE_BPS = 2500;

    /// @notice Maximum secondary-sale royalty in basis points. 15%.
    uint256 public constant MAX_ROYALTY_BPS = 1500;

    /// @notice Maximum royalty shareholders per title (gas-bounded).
    ///         Composable with external splitter contracts for larger cap tables.
    uint256 public constant MAX_SHAREHOLDERS = 50;

    /// @notice Treasury update timelock duration. 7 days.
    uint256 public constant TREASURY_UPDATE_TIMELOCK = 7 days;

    /// @notice The LMAP specification version this contract implements.
    string public constant LMAP_SPEC_VERSION = "1.0";

    // =========================================================================
    // STRUCTS
    // =========================================================================

    /// @notice On-chain record of a tokenized title.
    /// @dev `publisher` is set from msg.sender at mint time (cryptographically
    ///      authentic). `author` is provided by the publisher and receives the
    ///      author share (distributed via royaltyShareholders if configured).
    struct TitleInfo {
        string mediaType;             // e.g., "film", "music", "software"
        string titleId;               // human-readable unique identifier
        string title;                 // display name
        address author;               // receives author share (or shareholder distribution)
        address publisher;            // msg.sender at mint, cannot be faked
        uint256 maxSupply;            // max tokens that can be minted for this title
        uint256 pricePerToken;        // primary sale price in USDC.e (6 decimals)
        uint256 publisherFeeBps;      // publisher's cut on primary sales (0-2500)
        uint256 royaltyBps;           // secondary-sale royalty (0-1500), ERC-2981
        string metadataUri;           // IPFS URI to title metadata JSON
        string rightsTierSchemaURI;   // URI to the rights-tier schema for this mediaType
        bool isActive;                // author can deactivate (no new sales)
        bool exists;
        uint256 createdAt;
        uint256 totalSales;
        uint256 totalRevenue;
    }

    /// @notice A rights tier defining what privileges holding N tokens unlocks.
    /// @dev `tierIdentifier` is machine-readable (must match the rightsTierSchemaURI).
    ///      `displayName` is human-readable.
    struct RightsTier {
        uint256 minQuantity;
        string tierIdentifier;
        string displayName;
        bool enabled;
    }

    /// @notice A royalty shareholder for an author's share of sales.
    /// @dev `sharesBps` is a fraction of the AUTHOR'S share, not of the total sale.
    struct RoyaltyShareholder {
        address recipient;
        uint256 sharesBps;            // basis points of the author share (0-10000)
    }

    /// @notice Marketplace listing (fixed-price or auction).
    struct MarketplaceListing {
        address seller;
        address highestBidder;
        bool isActive;
        bool isAuction;
        uint32 tokenId;
        uint32 quantity;
        uint64 listingExpiry;
        uint64 auctionEnd;
        uint256 pricePerToken;
        uint256 currentBid;
    }

    // =========================================================================
    // STATE
    // =========================================================================

    uint256 public nextTokenId = 1;
    mapping(uint256 => TitleInfo) public titles;
    mapping(string => uint256) public titleIdToTokenId;
    mapping(uint256 => RightsTier[]) public titleRightsTiers;
    mapping(uint256 => RoyaltyShareholder[]) private _royaltyShareholders;

    uint256 public nextListingId = 1;
    mapping(uint256 => MarketplaceListing) public listings;

    // Treasury update with timelock
    address public platformTreasury;
    address public pendingPlatformTreasury;
    uint256 public pendingTreasuryActivationTime;

    // ERC-4337 paymaster hook
    address public paymaster;

    // =========================================================================
    // EVENTS
    // =========================================================================

    event TitleCreated(
        uint256 indexed tokenId,
        string titleId,
        string title,
        string mediaType,
        address indexed author,
        address indexed publisher,
        uint256 maxSupply,
        uint256 pricePerToken,
        uint256 publisherFeeBps,
        uint256 royaltyBps
    );
    event TokensPurchased(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 quantity,
        uint256 totalPrice,
        string rightsTierIdentifier
    );
    event RoyaltyShareholdersUpdated(uint256 indexed tokenId, RoyaltyShareholder[] shareholders);
    event TitleMetadataUpdated(uint256 indexed tokenId, string metadataUri);
    event TitlePriceUpdated(uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);
    event TitleStatusUpdated(uint256 indexed tokenId, bool isActive);

    event TitleListed(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 quantity,
        uint256 pricePerToken,
        uint256 expiry
    );
    event AuctionStarted(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 quantity,
        uint256 startingBid,
        uint256 auctionEnd
    );
    event TokensSold(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 quantity,
        uint256 totalPrice
    );
    event BidPlaced(uint256 indexed listingId, address indexed bidder, uint256 bidAmount);
    event ListingCancelled(uint256 indexed listingId);

    event PlatformTreasuryUpdateProposed(address indexed newTreasury, uint256 activationTime);
    event PlatformTreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event PaymasterUpdated(address indexed oldPaymaster, address indexed newPaymaster);

    // =========================================================================
    // CONSTRUCTOR
    // =========================================================================

    /// @param _platformTreasury Initial address receiving the 2.5% protocol fee.
    ///        For deploys under foundation governance, set to the foundation
    ///        multi-sig (Gnosis Safe). For early deploys, set to a wallet that
    ///        can be transferred to the foundation later via the timelock
    ///        update mechanism.
    constructor(address _platformTreasury) ERC1155("") {
        if (_platformTreasury == address(0)) revert InvalidInput();

        platformTreasury = _platformTreasury;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        // ERC-2981 default royalty (per-title royalties override this).
        // Default: pays the protocol fee to the platform treasury for any
        // token that doesn't have a per-token royalty configured.
        _setDefaultRoyalty(_platformTreasury, uint96(PROTOCOL_FEE_BPS));
    }

    // =========================================================================
    // TITLE CREATION (PERMISSIONLESS)
    // =========================================================================

    /// @notice Register a new title. Permissionless: any wallet can call.
    /// @dev `publisher` is set from `msg.sender` automatically.
    /// @param _titleId Unique human-readable identifier (e.g., "the-cocoanuts-1929").
    /// @param _title Display name.
    /// @param _mediaType LMAP media-type identifier (e.g., "film", "music").
    /// @param _author Address that receives the author share (or via shareholders).
    /// @param _maxSupply Maximum tokens that can be minted for this title.
    /// @param _pricePerToken Primary sale price in USDC.e units (6 decimals).
    /// @param _publisherFeeBps Publisher's cut in basis points (0-2500).
    /// @param _royaltyBps Secondary-sale royalty in basis points (0-1500).
    /// @param _rightsTiers Array of rights tier definitions for stacking.
    /// @param _metadataUri IPFS URI to title metadata JSON.
    /// @param _rightsTierSchemaURI URI to the rights-tier schema (per mediaType).
    /// @return tokenId The new token ID assigned to this title.
    function createTitle(
        string memory _titleId,
        string memory _title,
        string memory _mediaType,
        address _author,
        uint256 _maxSupply,
        uint256 _pricePerToken,
        uint256 _publisherFeeBps,
        uint256 _royaltyBps,
        RightsTier[] memory _rightsTiers,
        string memory _metadataUri,
        string memory _rightsTierSchemaURI
    ) external nonReentrant returns (uint256 tokenId) {
        if (bytes(_titleId).length == 0) revert InvalidInput();
        if (bytes(_title).length == 0) revert InvalidInput();
        if (bytes(_mediaType).length == 0) revert InvalidInput();
        if (_author == address(0)) revert InvalidInput();
        if (_maxSupply == 0) revert InvalidInput();
        if (_pricePerToken == 0) revert InvalidInput();
        if (titleIdToTokenId[_titleId] != 0) revert TitleIdAlreadyUsed();
        if (_publisherFeeBps > MAX_PUBLISHER_FEE_BPS) revert PublisherFeeTooHigh();
        if (_royaltyBps > MAX_ROYALTY_BPS) revert RoyaltyTooHigh();

        tokenId = nextTokenId++;

        titles[tokenId] = TitleInfo({
            mediaType: _mediaType,
            titleId: _titleId,
            title: _title,
            author: _author,
            publisher: msg.sender,
            maxSupply: _maxSupply,
            pricePerToken: _pricePerToken,
            publisherFeeBps: _publisherFeeBps,
            royaltyBps: _royaltyBps,
            metadataUri: _metadataUri,
            rightsTierSchemaURI: _rightsTierSchemaURI,
            isActive: true,
            exists: true,
            createdAt: block.timestamp,
            totalSales: 0,
            totalRevenue: 0
        });

        for (uint256 i = 0; i < _rightsTiers.length; i++) {
            titleRightsTiers[tokenId].push(_rightsTiers[i]);
        }

        titleIdToTokenId[_titleId] = tokenId;

        // Per-title ERC-2981 royalty: royalty info points to this contract,
        // which redistributes via shareholders on receipt (see royaltyInfo).
        _setTokenRoyalty(tokenId, address(this), uint96(_royaltyBps));

        emit TitleCreated(
            tokenId,
            _titleId,
            _title,
            _mediaType,
            _author,
            msg.sender,
            _maxSupply,
            _pricePerToken,
            _publisherFeeBps,
            _royaltyBps
        );
    }

    // =========================================================================
    // PRIMARY SALE
    // =========================================================================

    /// @notice Purchase tokens at the primary sale price.
    /// @dev Three-way payment split:
    ///      - Protocol fee (2.5%) to platformTreasury
    ///      - Publisher fee (0-25% per title) to title.publisher
    ///      - Author share (remainder) distributed via royaltyShareholders
    ///        (or to title.author directly if no shareholders configured)
    function purchaseTokens(uint256 tokenId, uint256 quantity) external nonReentrant {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        if (quantity == 0) revert InvalidInput();

        TitleInfo storage titleInfo = titles[tokenId];
        if (!titleInfo.exists || !titleInfo.isActive) revert NotFound();

        uint256 currentSupply = totalSupply(tokenId);
        if (currentSupply + quantity > titleInfo.maxSupply) revert InsufficientBalance();

        uint256 totalPrice = titleInfo.pricePerToken * quantity;
        if (USDC.balanceOf(msg.sender) < totalPrice) revert InsufficientBalance();
        if (!USDC.transferFrom(msg.sender, address(this), totalPrice)) revert InvalidState();

        // Three-way split
        uint256 protocolFee = (totalPrice * PROTOCOL_FEE_BPS) / 10000;
        uint256 publisherFee = (totalPrice * titleInfo.publisherFeeBps) / 10000;
        uint256 authorShareTotal = totalPrice - protocolFee - publisherFee;

        if (!USDC.transfer(platformTreasury, protocolFee)) revert InvalidState();
        if (publisherFee > 0) {
            if (!USDC.transfer(titleInfo.publisher, publisherFee)) revert InvalidState();
        }
        _distributeAuthorShare(tokenId, authorShareTotal, titleInfo.author);

        _mint(msg.sender, tokenId, quantity, "");

        titleInfo.totalSales += quantity;
        titleInfo.totalRevenue += totalPrice;

        string memory tierIdentifier = _getRightsTierIdentifier(tokenId, quantity);
        emit TokensPurchased(tokenId, msg.sender, quantity, totalPrice, tierIdentifier);
    }

    // =========================================================================
    // ROYALTY SHAREHOLDER DISTRIBUTION
    // =========================================================================

    /// @notice Update the royalty shareholders for a title's author share.
    /// @dev Only callable by the title's author. Sum of shares must be ≤ 10000;
    ///      any remainder goes to the author wallet on each sale.
    function updateRoyaltyShareholders(
        uint256 tokenId,
        RoyaltyShareholder[] memory _shareholders
    ) external {
        if (!titles[tokenId].exists) revert NotFound();
        if (msg.sender != titles[tokenId].author) revert Unauthorized();
        if (_shareholders.length > MAX_SHAREHOLDERS) revert TooManyShareholders();

        uint256 totalShares;
        for (uint256 i = 0; i < _shareholders.length; i++) {
            if (_shareholders[i].recipient == address(0)) revert InvalidInput();
            totalShares += _shareholders[i].sharesBps;
        }
        if (totalShares > 10000) revert SharesExceedTotal();

        delete _royaltyShareholders[tokenId];
        for (uint256 i = 0; i < _shareholders.length; i++) {
            _royaltyShareholders[tokenId].push(_shareholders[i]);
        }

        emit RoyaltyShareholdersUpdated(tokenId, _shareholders);
    }

    function getRoyaltyShareholders(uint256 tokenId)
        external
        view
        returns (RoyaltyShareholder[] memory)
    {
        return _royaltyShareholders[tokenId];
    }

    /// @dev Internal: distribute the author share across configured shareholders.
    ///      Any remainder (after explicit shareholders) goes to the author wallet.
    function _distributeAuthorShare(
        uint256 tokenId,
        uint256 authorShareTotal,
        address authorAddr
    ) internal {
        if (authorShareTotal == 0) return;

        RoyaltyShareholder[] storage shareholders = _royaltyShareholders[tokenId];
        if (shareholders.length == 0) {
            if (!USDC.transfer(authorAddr, authorShareTotal)) revert InvalidState();
            return;
        }

        uint256 distributed = 0;
        for (uint256 i = 0; i < shareholders.length; i++) {
            uint256 cut = (authorShareTotal * shareholders[i].sharesBps) / 10000;
            if (cut > 0) {
                if (!USDC.transfer(shareholders[i].recipient, cut)) revert InvalidState();
                distributed += cut;
            }
        }

        if (distributed < authorShareTotal) {
            if (!USDC.transfer(authorAddr, authorShareTotal - distributed)) revert InvalidState();
        }
    }

    // =========================================================================
    // TITLE MANAGEMENT (AUTHOR-CONTROLLED)
    // =========================================================================

    function updateTitleMetadataURI(uint256 tokenId, string memory newMetadataURI) external {
        if (!titles[tokenId].exists) revert NotFound();
        if (msg.sender != titles[tokenId].author) revert Unauthorized();
        if (bytes(newMetadataURI).length == 0) revert InvalidInput();

        titles[tokenId].metadataUri = newMetadataURI;
        emit TitleMetadataUpdated(tokenId, newMetadataURI);
    }

    function updateTitlePrice(uint256 tokenId, uint256 newPrice) external {
        if (!titles[tokenId].exists) revert NotFound();
        if (msg.sender != titles[tokenId].author) revert Unauthorized();
        if (newPrice == 0) revert InvalidInput();

        uint256 oldPrice = titles[tokenId].pricePerToken;
        titles[tokenId].pricePerToken = newPrice;
        emit TitlePriceUpdated(tokenId, oldPrice, newPrice);
    }

    function setTitleActive(uint256 tokenId, bool isActive) external {
        if (!titles[tokenId].exists) revert NotFound();
        if (msg.sender != titles[tokenId].author) revert Unauthorized();

        titles[tokenId].isActive = isActive;
        emit TitleStatusUpdated(tokenId, isActive);
    }

    // =========================================================================
    // SECONDARY MARKETPLACE
    // =========================================================================
    //
    // TODO (next session): full implementations of listTitle, buyListing,
    // startAuction, placeBid, finalizeAuction, cancelListing.
    //
    // Reuses V4.1 patterns with two structural changes:
    //   1. Royalty distribution on every sale (V4.1 paid 100% to seller; V5
    //      deducts protocol fee + author royalty before paying seller).
    //   2. Royalty distribution flows through _distributeAuthorShare so
    //      collaborator shareholders get paid on secondary sales too.
    //
    // Function signatures:
    //
    //   function listTitle(uint256 tokenId, uint256 quantity, uint256 pricePerToken, uint256 duration) external nonReentrant returns (uint256 listingId);
    //   function buyListing(uint256 listingId) external nonReentrant;
    //   function startAuction(uint256 tokenId, uint256 quantity, uint256 startingBid, uint256 duration) external nonReentrant returns (uint256 listingId);
    //   function placeBid(uint256 listingId, uint256 bidAmount) external nonReentrant;
    //   function finalizeAuction(uint256 listingId) external nonReentrant;
    //   function cancelListing(uint256 listingId) external nonReentrant;
    //
    // =========================================================================

    // =========================================================================
    // TREASURY UPDATE (TIMELOCKED)
    // =========================================================================

    /// @notice Propose a new platform treasury address. Requires ADMIN_ROLE
    ///         (typically the foundation multi-sig).
    /// @dev Activation requires waiting TREASURY_UPDATE_TIMELOCK seconds, then
    ///      anyone can call executePlatformTreasuryUpdate(). The timelock
    ///      gives integrators visibility into treasury changes before they
    ///      take effect.
    function proposePlatformTreasuryUpdate(address newTreasury) external onlyRole(ADMIN_ROLE) {
        if (newTreasury == address(0)) revert InvalidInput();

        pendingPlatformTreasury = newTreasury;
        pendingTreasuryActivationTime = block.timestamp + TREASURY_UPDATE_TIMELOCK;

        emit PlatformTreasuryUpdateProposed(newTreasury, pendingTreasuryActivationTime);
    }

    /// @notice Execute a previously-proposed treasury update after timelock.
    /// @dev Permissionless: anyone can trigger the activation once the
    ///      timelock has elapsed. The proposal authorization (ADMIN_ROLE)
    ///      and timelock together provide the security model.
    function executePlatformTreasuryUpdate() external {
        if (pendingPlatformTreasury == address(0)) revert InvalidState();
        if (block.timestamp < pendingTreasuryActivationTime) revert TimelockNotElapsed();

        address oldTreasury = platformTreasury;
        platformTreasury = pendingPlatformTreasury;

        pendingPlatformTreasury = address(0);
        pendingTreasuryActivationTime = 0;

        emit PlatformTreasuryUpdated(oldTreasury, platformTreasury);
    }

    /// @notice Cancel a pending treasury update before it activates.
    function cancelPendingPlatformTreasuryUpdate() external onlyRole(ADMIN_ROLE) {
        if (pendingPlatformTreasury == address(0)) revert InvalidState();

        pendingPlatformTreasury = address(0);
        pendingTreasuryActivationTime = 0;
    }

    // =========================================================================
    // PAYMASTER (ERC-4337 HOOK)
    // =========================================================================

    /// @notice Set the ERC-4337 paymaster contract address (or zero to disable).
    /// @dev The paymaster contract handles gas abstraction so users can pay
    ///      USDC.e for both their token AND gas, without holding MATIC.
    ///      Paymaster contract is deployed and managed separately.
    function setPaymaster(address newPaymaster) external onlyRole(ADMIN_ROLE) {
        address oldPaymaster = paymaster;
        paymaster = newPaymaster;
        emit PaymasterUpdated(oldPaymaster, newPaymaster);
    }

    // =========================================================================
    // VIEW HELPERS
    // =========================================================================

    /// @dev Returns the highest-tier identifier whose minQuantity is met.
    ///      Returns empty string if no tier matches.
    function _getRightsTierIdentifier(uint256 tokenId, uint256 quantity)
        internal
        view
        returns (string memory)
    {
        RightsTier[] storage tiers = titleRightsTiers[tokenId];
        for (uint256 i = tiers.length; i > 0; i--) {
            if (tiers[i - 1].enabled && quantity >= tiers[i - 1].minQuantity) {
                return tiers[i - 1].tierIdentifier;
            }
        }
        return "";
    }

    function getRightsTiers(uint256 tokenId) external view returns (RightsTier[] memory) {
        return titleRightsTiers[tokenId];
    }

    function getAvailableTokens(uint256 tokenId) external view returns (uint256) {
        if (tokenId == 0 || tokenId >= nextTokenId) return 0;
        return titles[tokenId].maxSupply - totalSupply(tokenId);
    }

    function getTitlePrice(uint256 tokenId) external view returns (uint256) {
        if (tokenId == 0 || tokenId >= nextTokenId) return 0;
        return titles[tokenId].pricePerToken;
    }

    function getTokenIdByTitleId(string memory _titleId) external view returns (uint256) {
        return titleIdToTokenId[_titleId];
    }

    // =========================================================================
    // ILMAPVerified IMPLEMENTATION
    // =========================================================================

    function lmapSpecVersion() external pure override returns (string memory) {
        return LMAP_SPEC_VERSION;
    }

    function mediaType(uint256 tokenId) external view override returns (string memory) {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        return titles[tokenId].mediaType;
    }

    function tokenOrigin(uint256 tokenId) external view override returns (string memory) {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        return titles[tokenId].titleId;
    }

    function isTokenVerified(uint256 tokenId) external view override returns (bool) {
        return tokenId > 0 && tokenId < nextTokenId && titles[tokenId].exists;
    }

    // =========================================================================
    // STANDARD OVERRIDES
    // =========================================================================

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        return titles[tokenId].metadataUri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(ILMAPVerified).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
