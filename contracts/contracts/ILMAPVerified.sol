// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

/// @title ILMAPVerified
/// @notice Interface for contracts implementing the Liquid Media Access Protocol (LMAP).
/// @dev Replaces the legacy IWyllohVerified interface with a media-agnostic surface.
///      Any contract claiming LMAP compliance should implement this interface so that
///      LMAP-compatible clients can introspect spec version, media type, and
///      registration status uniformly.
interface ILMAPVerified {
    /// @notice Reports the LMAP specification version this contract implements.
    /// @dev Allows future clients to verify which spec version a contract conforms to.
    /// @return version Specification version string, e.g., "1.0".
    function lmapSpecVersion() external pure returns (string memory version);

    /// @notice Returns the media type of a specific tokenized title.
    /// @dev Replaces the legacy `contentType()` which returned a hardcoded "film".
    ///      Media type identifiers come from the LMAP media-type registry
    ///      (e.g., "film", "music", "software", "book", "image", "game").
    /// @param tokenId The token ID to query.
    /// @return mediaTypeId A media-type identifier registered in the LMAP spec.
    function mediaType(uint256 tokenId) external view returns (string memory mediaTypeId);

    /// @notice Returns the origin / content ID of a tokenized title.
    /// @dev The titleId set at mint time, unique within this contract.
    /// @param tokenId The token ID to query.
    /// @return origin The content identifier registered at mint time.
    function tokenOrigin(uint256 tokenId) external view returns (string memory origin);

    /// @notice Reports whether a token ID corresponds to a registered title.
    /// @param tokenId The token ID to query.
    /// @return verified True if the token exists and is LMAP-compliant.
    function isTokenVerified(uint256 tokenId) external view returns (bool verified);
}
