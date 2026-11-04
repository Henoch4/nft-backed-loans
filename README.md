# Pawnvault

Request an NFT-backed loan and inspect its funding and repayment state.

## Mainnet status

Contract on BOT Chain mainnet (677): [0x0Fba887e4dc35113dC9700628a9F430b3AB95d5F](https://scan.botchain.ai/address/0x0Fba887e4dc35113dC9700628a9F430b3AB95d5F).

Wallet actions require BOT Chain mainnet, deployed bytecode, and a connected compatible wallet. Every action is simulated before a transaction review; only a subsequent wallet confirmation can send it.

## Interface

- Live reads use the configured mainnet address; an unavailable RPC produces an explicit error.
- No seeded financial metrics, synthetic receipts, or assessment traces appear in the product.
- Management actions require proof of the connected account’s owner, creator, oracle, merchant, guardian, or record role. The contract remains the authority.
- Account/network changes invalidate an open transaction review.
- The footer provides BOT Chain and BOTScan homepage links; deployed products also link to their contract.
- Ethers is vendored locally with its license. No CDN script is required for wallet or contract operations.

## Contract interface

`frontend/product.json` uses the current-source ABI, matched against the deployed mainnet runtime bytecode. Explorer source publication is tracked separately.

| Action | Contract signature |
|---|---|
| Cancel Loan | `cancelLoan(uint256)` |
| Mark a default | `defaultLoan(uint256)` |
| Fund a loan | `fundLoan(uint256)` |
| Repay your loan | `repayLoan(uint256)` |
| Request a loan | `requestLoan(address,uint256,uint256,uint256,uint256)` |

## Run locally

Serve the frontend over HTTP so the browser can load its configuration:

```sh
python -m http.server 8080 --directory frontend
```

Open http://localhost:8080. Only connect a wallet when you intend to use the configured mainnet contract.

## Regression test

```sh
npm install
npm test
```

The test requires Chromium or Edge. Windows defaults to the standard Edge installation; set `BROWSER_PATH` to another Chromium executable when needed. It mocks all chain requests and broadcasts no transactions. Tests cover pending deployment, RPC failure, read-only initialization and missing-wallet handling.

## Deployment and assessment

Update `frontend/product.json` only after confirming the new contract's network, bytecode and ABI. Do not substitute placeholder addresses or remove truthful limitations. Operator-wallet testing proves technical activity, not independent users. Official social accounts, launch posts, independent users and continuous operation require separate evidence.
