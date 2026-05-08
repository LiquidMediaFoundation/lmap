# ADR 001: Blockchain-First Data Architecture

## Status
Accepted

## Context
LMAP is a platform-agnostic tokenized film distribution system. The blockchain must remain the source of truth for all tokenized content, not the backend API.

## Decision
**All content discovery and display must query the blockchain FIRST, not the backend API.**

### Critical Principle
The blockchain is the source of truth. The backend API is only for:
- Enrichment (additional metadata like view counts)
- Performance optimization (caching)
- User-specific data (purchase history, favorites)

### Implementation Requirements

1. **Store Page**:
   - Must call `blockchainService.getAllBlockchainFilms()` to get tokens
   - Must fetch IPFS metadata for each token to get poster/trailer
   - MAY layer API enrichment on top (views, user-specific data)
   - MUST NOT rely solely on backend API

2. **Dashboard (Pro User)**:
   - Must query blockchain for tokens where `creator === user.walletAddress`
   - Must fetch IPFS metadata for each token
   - MUST NOT rely solely on backend API

3. **Content Display**:
   - Poster image: `metadata.image` from IPFS (via metadata CID)
   - Trailer: `metadata.animation_url` from IPFS
   - Feature film CID: `metadata.properties.feature_film.encrypted_main_file_cid` from IPFS
   - MUST NOT use placeholder URLs or backend-provided URLs

## Consequences

### Positive
- Platform remains decentralized and censorship-resistant
- Works even if the reference implementation backend goes down
- True ownership - data on blockchain + IPFS
- No vendor lock-in

### Negative
- Slightly slower initial load (blockchain queries + IPFS fetches)
- More complex error handling (blockchain + IPFS + optional API)
- Need to handle cases where IPFS metadata is unavailable

## Enforcement
1. Code reviews must verify blockchain-first approach
2. Tests must mock blockchain service, not API service
3. This ADR must be referenced in all content-related PRs

## Related Files
- `client/src/services/content.service.ts` - Content discovery logic
- `client/src/services/blockchain.service.ts` - Blockchain queries
- `client/src/services/tokenMetadata.service.ts` - IPFS metadata fetching
- `client/src/pages/store/EnhancedStorePage.tsx` - Store page
- `client/src/pages/pro/DashboardPage.tsx` - Creator dashboard

## Date
2025-01-16

## Authors
Harrison Kavanaugh, Claude (AI Assistant)
