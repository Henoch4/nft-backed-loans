# Pawnvault — NFT-Backed Loans

> Pawnvault turns NFTs into collateral. Lock a token with a loan principal and rate, trigger liquidation windows on missed deadlines, and borrow against collectible value without leaving the chain.

## What it does

Pawnvault turns NFTs into collateral. Lock a token with a loan principal and rate, trigger liquidation windows on missed deadlines, and borrow against collectible value without leaving the chain. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/NFTBackedLoans.sol` |
| Contract name | `NFTBackedLoans` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 6 (of which 1 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `requestLoan` | write | uint256 |
| `fundLoan` | payable | tx receipt |
| `repayLoan` | write | result / revert |
| `defaultLoan` | write | result / revert |
| `getLoan` | view | address borrower, address lender, address nftContract, uint256 tokenId, uint256 principal, uint256 interestBps, uint256 duration, uint256 startTime, uint256 repayAmount, bool active, bool repaid, bool locked |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `LoanRequested` | (uint256 indexed lid, address indexed borrower, address nftContract, uint256 tokenId, uint256 principal) |
| `LoanFunded` | (uint256 indexed lid, address indexed lender, uint256 amount) |
| `LoanRepaid` | (uint256 indexed lid, address indexed borrower, uint256 amount) |
| `LoanDefaulted` | (uint256 indexed lid, address indexed borrower, address nftContract, uint256 tokenId) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/nft-backed-loans.git
cd nft-backed-loans
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.