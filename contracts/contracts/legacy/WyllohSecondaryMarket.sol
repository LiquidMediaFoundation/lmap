// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// =============================================================================
// LMAP 1.0-compatible — legacy secondary marketplace deployment.
//
// Deployed at 0xE171E9db4f2f64d3Fc80AA6E2bdF2770Bb006EC8 on Polygon mainnet
// (chain ID 137). Bytecode is immutable and source is verified on Polygonscan;
// this file is preserved verbatim for verification purposes — including the
// original SPDX identifier, the contract name (WyllohSecondaryMarket), and
// all inline NatSpec.
//
// Companion to WyllohRegistryProtocolV4_1. Original deployer: the team
// operating Wylloh, the reference commercial implementation of the LMAP
// protocol. Stewardship of the LMAP specification rests with the Liquid
// Media Foundation.
// =============================================================================

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title WyllohSecondaryMarket
/// @notice Royalty-aware secondary marketplace for Wylloh film tokens.
///         Sellers list ERC-1155 tokens; buyers pay in USDC.
///         Every sale splits proceeds: seller, film creator (royalty), platform.

interface IWyllohRegistry {
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
    function films(uint256 tokenId) external view returns (
        string memory filmId,
        string memory title,
        address creator,
        uint256 maxSupply,
        uint256 pricePerToken,
        bool isActive,
        uint256 createdAt,
        string memory metadataUri,
        bool exists,
        uint256 totalSales,
        uint256 totalRevenue
    );
}

error NotActive();
error NotSeller();
error NotFound();
error InsufficientBalance();
error InvalidInput();
error ListingExpired();

contract WyllohSecondaryMarket is ERC1155Holder, ReentrancyGuard, Ownable {

    IERC20 public immutable usdc;
    IERC1155 public immutable registry;
    IWyllohRegistry public immutable registryInfo;

    // Basis points: 10000 = 100%
    uint256 public creatorRoyaltyBps = 700;   // 7% to film creator
    uint256 public platformFeeBps = 300;       // 3% to platform
    address public platformTreasury;

    uint256 public nextListingId = 1;

    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerToken;  // USDC units (6 decimals)
        uint256 expiresAt;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256[]) public tokenListings;  // tokenId => listingIds

    event Listed(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 quantity,
        uint256 pricePerToken
    );
    event Sold(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        uint256 quantity,
        uint256 totalPrice
    );
    event RoyaltyPaid(
        uint256 indexed tokenId,
        address indexed creator,
        uint256 amount
    );
    event Cancelled(uint256 indexed listingId);

    constructor(
        address _registry,
        address _usdc,
        address _platformTreasury
    ) {
        registry = IERC1155(_registry);
        registryInfo = IWyllohRegistry(_registry);
        usdc = IERC20(_usdc);
        platformTreasury = _platformTreasury;
    }

    /// @notice List tokens for sale. Caller must have called
    ///         registry.setApprovalForAll(thisContract, true) first.
    function list(
        uint256 tokenId,
        uint256 quantity,
        uint256 pricePerToken,
        uint256 duration
    ) external nonReentrant returns (uint256 listingId) {
        if (quantity == 0 || pricePerToken == 0) revert InvalidInput();
        if (registry.balanceOf(msg.sender, tokenId) < quantity) revert InsufficientBalance();

        // Escrow tokens
        registry.safeTransferFrom(msg.sender, address(this), tokenId, quantity, "");

        listingId = nextListingId++;
        listings[listingId] = Listing({
            seller: msg.sender,
            tokenId: tokenId,
            quantity: quantity,
            pricePerToken: pricePerToken,
            expiresAt: block.timestamp + duration,
            active: true
        });

        tokenListings[tokenId].push(listingId);

        emit Listed(listingId, tokenId, msg.sender, quantity, pricePerToken);
    }

    /// @notice Buy from a listing. Caller must have approved this contract
    ///         to spend sufficient USDC.
    function buy(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert NotActive();
        if (block.timestamp > listing.expiresAt) revert ListingExpired();

        uint256 totalPrice = listing.pricePerToken * listing.quantity;
        if (usdc.balanceOf(msg.sender) < totalPrice) revert InsufficientBalance();

        // Look up the film creator for royalty payment
        (, , address creator, , , , , , , , ) = registryInfo.films(listing.tokenId);

        // Calculate splits
        uint256 royalty = (totalPrice * creatorRoyaltyBps) / 10000;
        uint256 platformFee = (totalPrice * platformFeeBps) / 10000;
        uint256 sellerProceeds = totalPrice - royalty - platformFee;

        // Transfer USDC
        require(usdc.transferFrom(msg.sender, listing.seller, sellerProceeds), "seller payment failed");

        if (royalty > 0 && creator != address(0)) {
            require(usdc.transferFrom(msg.sender, creator, royalty), "royalty payment failed");
            emit RoyaltyPaid(listing.tokenId, creator, royalty);
        }

        if (platformFee > 0) {
            require(usdc.transferFrom(msg.sender, platformTreasury, platformFee), "platform fee failed");
        }

        // Transfer tokens from escrow to buyer
        registry.safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.quantity, "");

        listing.active = false;

        emit Sold(listingId, listing.tokenId, msg.sender, listing.seller, listing.quantity, totalPrice);
    }

    /// @notice Cancel a listing. Only the seller can cancel.
    function cancel(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert NotActive();
        if (listing.seller != msg.sender) revert NotSeller();

        // Return escrowed tokens
        registry.safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.quantity, "");

        listing.active = false;
        emit Cancelled(listingId);
    }

    /// @notice Get all active listing IDs for a token.
    function getActiveListings(uint256 tokenId) external view returns (uint256[] memory) {
        uint256[] memory allIds = tokenListings[tokenId];
        uint256 count = 0;

        // Count active
        for (uint256 i = 0; i < allIds.length; i++) {
            if (listings[allIds[i]].active && block.timestamp <= listings[allIds[i]].expiresAt) {
                count++;
            }
        }

        // Build result
        uint256[] memory activeIds = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < allIds.length; i++) {
            if (listings[allIds[i]].active && block.timestamp <= listings[allIds[i]].expiresAt) {
                activeIds[idx++] = allIds[i];
            }
        }

        return activeIds;
    }

    // --- Admin ---

    function updateFees(uint256 _creatorRoyaltyBps, uint256 _platformFeeBps) external onlyOwner {
        require(_creatorRoyaltyBps + _platformFeeBps <= 3000, "fees too high"); // max 30%
        creatorRoyaltyBps = _creatorRoyaltyBps;
        platformFeeBps = _platformFeeBps;
    }

    function updateTreasury(address _treasury) external onlyOwner {
        platformTreasury = _treasury;
    }
}
