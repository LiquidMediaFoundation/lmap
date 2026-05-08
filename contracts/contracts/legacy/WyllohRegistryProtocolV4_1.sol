// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// =============================================================================
// LMAP 1.0-compatible (open-tier only) — legacy deployment.
//
// Deployed at 0x8e834c6031A2d59e1cADd24Ab24F668301ed7c1D on Polygon mainnet
// (chain ID 137). Bytecode is immutable and source is verified on Polygonscan;
// this file is preserved verbatim for verification purposes — including the
// original SPDX identifier, the contract name (WyllohRegistryProtocolV4_1),
// and all inline NatSpec.
//
// This contract implements LMAP Specification v1.0 at the open-tier level
// only. It does not support certified-tier hardware attestation. New
// tokenizations with full open + certified tier support are directed to
// LMAPRegistryV5 (in development).
//
// Original deployer: the team operating Wylloh, the reference commercial
// implementation of the LMAP protocol. Stewardship of the LMAP
// specification rests with the Liquid Media Foundation.
// =============================================================================

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IWyllohVerified.sol";

// Custom errors for gas efficiency
error Unauthorized();
error InvalidInput();
error InsufficientBalance();
error NotFound();
error Expired();
error InvalidState();

// Wylloh Registry Protocol v4.1 - Optimized with struct packing
contract WyllohRegistryProtocolV4_1 is 
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    AccessControl,
    ReentrancyGuard,
    IWyllohVerified
{
    bytes32 public constant FILM_CREATOR_ROLE = keccak256("FILM_CREATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PRICE_MANAGER_ROLE = keccak256("PRICE_MANAGER_ROLE");
    bytes32 public constant METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER_ROLE");
    
    IERC20 public constant USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    
    uint256 public nextTokenId = 1;
    mapping(uint256 => FilmInfo) public films;
    mapping(string => uint256) public filmIdToTokenId;
    
    struct FilmInfo {
        string filmId;
        string title;
        address creator;
        uint256 maxSupply;
        uint256 pricePerToken;
        bool isActive;
        uint256 createdAt;
        string metadataUri;
        bool exists;
        uint256 totalSales;
        uint256 totalRevenue;
    }
    
    struct RightsThreshold {
        uint256 quantity;
        string rightsLevel;
        uint256 priceMultiplier;
        bool enabled;
    }
    
    
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
    
    mapping(uint256 => RightsThreshold[]) public filmTiers;
    
    uint256 public nextListingId = 1;
    mapping(uint256 => MarketplaceListing) public listings;
    mapping(address => uint256[]) public userListings;
    mapping(uint256 => uint256[]) public tokenListings;
    
    // Platform economics
    uint256 public platformFeePercentage = 250;
    address public platformTreasury;
    
    // Events - Frontend Compatible
    event FilmCreated(uint256 indexed tokenId, string filmId, string title, address indexed creator, uint256 maxSupply, uint256 pricePerToken);
    event TokensPurchased(uint256 indexed tokenId, address indexed buyer, uint256 quantity, uint256 totalPrice, string rightsLevel);
    event TokensListed(uint256 indexed listingId, uint256 indexed tokenId, address indexed seller, uint256 quantity, uint256 pricePerToken);
    event AuctionStarted(uint256 indexed listingId, uint256 indexed tokenId, address indexed seller, uint256 quantity, uint256 startingBid, uint256 auctionEnd);
    event TokensSold(uint256 indexed listingId, uint256 indexed tokenId, address indexed buyer, uint256 quantity, uint256 totalPrice);
    event BidPlaced(uint256 indexed listingId, address indexed bidder, uint256 bidAmount);
    
    // Additional events expected by frontend
    event FilmMetadataUpdated(uint256 indexed tokenId, string metadataUri);
    event RoyaltyRecipientsUpdated(uint256 indexed tokenId, address[] recipients, uint256[] shares);
    event TokenListed(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 quantity, uint256 pricePerToken);
    event TokenSold(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 tokenId, uint256 quantity, uint256 totalPrice);
    event OfferMade(uint256 indexed offerId, address indexed offerer, address indexed target, uint256 tokenId, uint256 quantity, uint256 pricePerToken);
    event OfferAccepted(uint256 indexed offerId, address indexed accepter, address indexed offerer, uint256 tokenId, uint256 quantity, uint256 totalPrice);
    event RoyaltyPaid(uint256 indexed tokenId, address indexed creator, uint256 amount);
    
    constructor(address _platformTreasury) ERC1155("") {
        if (_platformTreasury == address(0)) revert InvalidInput();
        
        platformTreasury = _platformTreasury;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(FILM_CREATOR_ROLE, msg.sender);
        _setRoleAdmin(FILM_CREATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PRICE_MANAGER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(METADATA_MANAGER_ROLE, ADMIN_ROLE);
        
        _setDefaultRoyalty(_platformTreasury, 250);
    }
    
    function createFilm(
        string memory filmId,
        string memory title,
        address creator,
        uint256 maxSupply,
        uint256 pricePerToken,
        RightsThreshold[] memory rightsThresholds,
        string memory metadataUri
    ) external onlyRole(FILM_CREATOR_ROLE) nonReentrant returns (uint256 tokenId) {
        if (bytes(filmId).length == 0 || bytes(title).length == 0) revert InvalidInput();
        if (creator == address(0) || maxSupply == 0 || pricePerToken == 0) revert InvalidInput();
        if (filmIdToTokenId[filmId] != 0) revert InvalidState();
        
        tokenId = nextTokenId++;
        
        films[tokenId] = FilmInfo({
            filmId: filmId,
            title: title,
            creator: creator,
            maxSupply: maxSupply,
            pricePerToken: pricePerToken,
            isActive: true,
            createdAt: block.timestamp,
            metadataUri: metadataUri,
            exists: true,
            totalSales: 0,
            totalRevenue: 0
        });
        
        for (uint256 i = 0; i < rightsThresholds.length; i++) {
            filmTiers[tokenId].push(rightsThresholds[i]);
        }
        
        filmIdToTokenId[filmId] = tokenId;
        
        emit FilmCreated(tokenId, filmId, title, creator, maxSupply, pricePerToken);
    }
    
    
    function purchaseTokens(uint256 tokenId, uint256 quantity) external nonReentrant {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        if (quantity == 0) revert InvalidInput();
        
        FilmInfo storage film = films[tokenId];
        if (!film.exists || !film.isActive) revert NotFound();
        
        uint256 currentSupply = totalSupply(tokenId);
        if (currentSupply + quantity > film.maxSupply) revert InsufficientBalance();
        
        uint256 totalPrice = film.pricePerToken * quantity;
        if (USDC.balanceOf(msg.sender) < totalPrice) revert InsufficientBalance();
        if (!USDC.transferFrom(msg.sender, address(this), totalPrice)) revert InvalidState();
        
        uint256 platformFee = (totalPrice * platformFeePercentage) / 10000;
        uint256 creatorPayment = totalPrice - platformFee;
        
        if (!USDC.transfer(film.creator, creatorPayment)) revert InvalidState();
        if (!USDC.transfer(platformTreasury, platformFee)) revert InvalidState();
        
        _mint(msg.sender, tokenId, quantity, "");
        
        // Update film metrics
        film.totalSales += quantity;
        film.totalRevenue += totalPrice;
        
        string memory rightsLevel = _getRightsLevel(tokenId, quantity);
        emit TokensPurchased(tokenId, msg.sender, quantity, totalPrice, rightsLevel);
    }
    
    function updateFilmPrice(uint256 tokenId, uint256 newPrice) external {
        if (!films[tokenId].exists) revert NotFound();
        if (msg.sender != films[tokenId].creator && !hasRole(PRICE_MANAGER_ROLE, msg.sender)) revert Unauthorized();
        
        films[tokenId].pricePerToken = newPrice;
    }
    
    function _getRightsLevel(uint256 tokenId, uint256 quantity) internal view returns (string memory) {
        RightsThreshold[] storage tiers = filmTiers[tokenId];
        
        for (uint256 i = tiers.length; i > 0; i--) {
            if (tiers[i-1].enabled && quantity >= tiers[i-1].quantity) {
                return tiers[i-1].rightsLevel;
            }
        }
        
        return "Basic Rights";
    }
    
    function getRightsThresholds(uint256 tokenId) external view returns (RightsThreshold[] memory) {
        return filmTiers[tokenId];
    }
    
    function getFilmsByCreator(address creator) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (films[i].creator == creator && films[i].exists) {
                count++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (films[i].creator == creator && films[i].exists) {
                result[index] = i;
                index++;
            }
        }
        
        return result;
    }
    
    function updateFilmMetadataURI(uint256 tokenId, string memory newMetadataURI) external {
        if (!films[tokenId].exists) revert NotFound();
        if (bytes(newMetadataURI).length == 0) revert InvalidInput();
        if (msg.sender != films[tokenId].creator && !hasRole(ADMIN_ROLE, msg.sender) && !hasRole(METADATA_MANAGER_ROLE, msg.sender)) revert Unauthorized();
        
        films[tokenId].metadataUri = newMetadataURI;
        emit FilmMetadataUpdated(tokenId, newMetadataURI);
    }
    
    function initializeToken1Data(
        string memory filmId,
        string memory title,
        address creator,
        uint256 maxSupply,
        uint256 pricePerToken,
        string memory metadataURI
    ) external onlyRole(ADMIN_ROLE) {
        if (films[1].exists) revert InvalidState();
        
        films[1] = FilmInfo({
            filmId: filmId,
            title: title,
            creator: creator,
            maxSupply: maxSupply,
            pricePerToken: pricePerToken,
            isActive: true,
            createdAt: block.timestamp,
            metadataUri: metadataURI,
            exists: true,
            totalSales: 0,
            totalRevenue: 0
        });
        
        filmIdToTokenId[filmId] = 1;
        if (nextTokenId <= 1) nextTokenId = 2;
        
        emit FilmCreated(1, filmId, title, creator, maxSupply, pricePerToken);
    }
    
    function updateRoyaltyRecipients(uint256 tokenId, address[] memory recipients, uint256[] memory shares) external {
        if (!films[tokenId].exists) revert NotFound();
        if (msg.sender != films[tokenId].creator && !hasRole(ADMIN_ROLE, msg.sender)) revert Unauthorized();
        
        emit RoyaltyRecipientsUpdated(tokenId, recipients, shares);
    }
    
    function getTokenListings(uint256 tokenId) external view returns (uint256[] memory) {
        return tokenListings[tokenId];
    }
    
    function getUserListings(address user) external view returns (uint256[] memory) {
        return userListings[user];
    }
    
    function getUserOffers(address) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }
    
    // Enhanced tier management
    function getEnhancedTiers(uint256 tokenId) external view returns (string[] memory rightsLevels, uint256[] memory quantities) {
        RightsThreshold[] storage tiers = filmTiers[tokenId];
        rightsLevels = new string[](tiers.length);
        quantities = new uint256[](tiers.length);
        
        for (uint256 i = 0; i < tiers.length; i++) {
            rightsLevels[i] = tiers[i].rightsLevel;
            quantities[i] = tiers[i].quantity;
        }
    }
    
    // Marketplace functions with proper type casting
    function listTokens(uint256 tokenId, uint256 quantity, uint256 pricePerToken, uint256 duration) external nonReentrant returns (uint256 listingId) {
        if (balanceOf(msg.sender, tokenId) < quantity) revert InsufficientBalance();
        if (quantity == 0 || pricePerToken == 0) revert InvalidInput();
        if (tokenId > type(uint32).max || quantity > type(uint32).max) revert InvalidInput(); // Check fits in uint32
        
        listingId = nextListingId++;
        
        listings[listingId] = MarketplaceListing({
            seller: msg.sender,
            highestBidder: address(0),
            isActive: true,
            isAuction: false,
            tokenId: uint32(tokenId), // Safe cast after check
            quantity: uint32(quantity), // Safe cast after check
            listingExpiry: uint64(block.timestamp + duration), // Safe cast
            auctionEnd: 0,
            pricePerToken: pricePerToken,
            currentBid: 0
        });
        
        userListings[msg.sender].push(listingId);
        tokenListings[tokenId].push(listingId);
        
        safeTransferFrom(msg.sender, address(this), tokenId, quantity, "");
        
        emit TokensListed(listingId, tokenId, msg.sender, quantity, pricePerToken);
    }
    
    function startAuction(uint256 tokenId, uint256 quantity, uint256 startingBid, uint256 duration) external nonReentrant returns (uint256 listingId) {
        if (balanceOf(msg.sender, tokenId) < quantity) revert InsufficientBalance();
        if (quantity == 0 || startingBid == 0) revert InvalidInput();
        if (tokenId > type(uint32).max || quantity > type(uint32).max) revert InvalidInput(); // Check fits in uint32
        
        uint64 auctionEnd = uint64(block.timestamp + duration); // Safe cast
        listingId = nextListingId++;
        
        listings[listingId] = MarketplaceListing({
            seller: msg.sender,
            highestBidder: address(0),
            isActive: true,
            isAuction: true,
            tokenId: uint32(tokenId), // Safe cast after check
            quantity: uint32(quantity), // Safe cast after check
            listingExpiry: auctionEnd,
            auctionEnd: auctionEnd,
            pricePerToken: 0,
            currentBid: startingBid
        });
        
        userListings[msg.sender].push(listingId);
        tokenListings[tokenId].push(listingId);
        
        safeTransferFrom(msg.sender, address(this), tokenId, quantity, "");
        
        emit AuctionStarted(listingId, tokenId, msg.sender, quantity, startingBid, uint256(auctionEnd));
    }
    
    function buyTokens(uint256 listingId) external nonReentrant {
        MarketplaceListing storage listing = listings[listingId];
        if (!listing.isActive || listing.isAuction) revert InvalidState();
        if (block.timestamp > listing.listingExpiry) revert Expired();
        
        uint256 totalPrice = listing.pricePerToken * listing.quantity;
        if (USDC.balanceOf(msg.sender) < totalPrice) revert InsufficientBalance();
        if (!USDC.transferFrom(msg.sender, listing.seller, totalPrice)) revert InvalidState();
        
        safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.quantity, "");
        
        listing.isActive = false;
        
        emit TokensSold(listingId, listing.tokenId, msg.sender, listing.quantity, totalPrice);
    }
    
    function placeBid(uint256 listingId, uint256 bidAmount) external nonReentrant {
        MarketplaceListing storage listing = listings[listingId];
        if (!listing.isActive || !listing.isAuction) revert InvalidState();
        if (block.timestamp > listing.auctionEnd) revert Expired();
        if (bidAmount <= listing.currentBid) revert InvalidInput();
        
        if (listing.highestBidder != address(0)) {
            if (!USDC.transfer(listing.highestBidder, listing.currentBid)) revert InvalidState();
        }
        
        if (!USDC.transferFrom(msg.sender, address(this), bidAmount)) revert InvalidState();
        
        listing.currentBid = bidAmount;
        listing.highestBidder = msg.sender;
        
        emit BidPlaced(listingId, msg.sender, bidAmount);
    }
    
    function finalizeAuction(uint256 listingId) external nonReentrant {
        MarketplaceListing storage listing = listings[listingId];
        if (!listing.isActive || !listing.isAuction) revert InvalidState();
        if (block.timestamp <= listing.auctionEnd) revert InvalidState();
        
        if (listing.highestBidder != address(0)) {
            if (!USDC.transfer(listing.seller, listing.currentBid)) revert InvalidState();
            safeTransferFrom(address(this), listing.highestBidder, listing.tokenId, listing.quantity, "");
            
            emit TokensSold(listingId, listing.tokenId, listing.highestBidder, listing.quantity, listing.currentBid);
        } else {
            safeTransferFrom(address(this), listing.seller, listing.tokenId, listing.quantity, "");
        }
        
        listing.isActive = false;
    }
    
    function purchaseFilmTokens(uint256 filmId, uint256 quantity) external nonReentrant {
        if (filmId == 0 || filmId >= nextTokenId) revert NotFound();
        if (quantity == 0) revert InvalidInput();
        
        FilmInfo storage film = films[filmId];
        if (!film.exists || !film.isActive) revert NotFound();
        
        uint256 currentSupply = totalSupply(filmId);
        if (currentSupply + quantity > film.maxSupply) revert InsufficientBalance();
        
        uint256 totalPrice = film.pricePerToken * quantity;
        if (USDC.balanceOf(msg.sender) < totalPrice) revert InsufficientBalance();
        if (!USDC.transferFrom(msg.sender, address(this), totalPrice)) revert InvalidState();
        
        uint256 platformFee = (totalPrice * platformFeePercentage) / 10000;
        uint256 creatorPayment = totalPrice - platformFee;
        
        if (!USDC.transfer(film.creator, creatorPayment)) revert InvalidState();
        if (!USDC.transfer(platformTreasury, platformFee)) revert InvalidState();
        
        _mint(msg.sender, filmId, quantity, "");
        
        film.totalSales += quantity;
        film.totalRevenue += totalPrice;
        
        string memory rightsLevel = _getRightsLevel(filmId, quantity);
        emit TokensPurchased(filmId, msg.sender, quantity, totalPrice, rightsLevel);
    }
    
    function getAvailableTokens(uint256 tokenId) external view returns (uint256) {
        if (tokenId == 0 || tokenId >= nextTokenId) return 0;
        return films[tokenId].maxSupply - totalSupply(tokenId);
    }
    
    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        if (tokenId == 0 || tokenId >= nextTokenId) return 0;
        return films[tokenId].pricePerToken;
    }
    
    function getFilmInfo(uint256 tokenId) external view returns (string memory, string memory, address, uint256, uint256) {
        FilmInfo storage film = films[tokenId];
        return (film.filmId, film.title, film.creator, film.maxSupply, film.pricePerToken);
    }
    
    function getTokenIdByFilmId(string memory filmId) external view returns (uint256) {
        return filmIdToTokenId[filmId];
    }
    
    // Core overrides
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        return films[tokenId].metadataUri;
    }
    
    // IWyllohVerified implementation
    function isWyllohVerified() external pure returns (bool) {
        return true;
    }
    
    function contentType() external pure returns (string memory) {
        return "film";
    }
    
    function qualityLevel() external pure returns (uint8) {
        return 255;
    }
    
    function getWyllohVerificationSignature(uint256 tokenId) external view returns (bytes memory) {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        return abi.encodePacked("WYLLOH_VERIFIED_", address(this), "_", tokenId);
    }
    
    function isTokenVerified(uint256 tokenId) external view returns (bool) {
        return tokenId > 0 && tokenId < nextTokenId && films[tokenId].exists;
    }
    
    function tokenOrigin(uint256 tokenId) external view returns (string memory) {
        if (tokenId == 0 || tokenId >= nextTokenId) revert NotFound();
        return films[tokenId].filmId;
    }
    
    // Required overrides
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
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