# Whitelist Airdrop

A Merkle tree based ERC20 token airdrop with EIP-712 signature verification. Whitelisted addresses claim a fixed token allocation by submitting a valid Merkle proof and a signed typed data message. Supports gasless claiming — a third party gas payer can submit the claim transaction on behalf of the whitelisted user. Includes unit, fuzz, interaction, and invariant tests.

---

## What It Does

- Distributes a fixed supply of AirdropToken to a predefined whitelist of four addresses
- Verifies claims using a Merkle proof — only addresses in the whitelist can claim
- Verifies claims using an EIP-712 signature — only the account holder can authorise a claim
- Supports gasless claiming — a gas payer submits the transaction, the user only signs off-chain
- Prevents replay attacks via a `s_hasClaimed` mapping — each address can claim exactly once
- Mints the entire token supply at deployment and immediately transfers it to the airdrop contract, eliminating owner custody risk
- Generates the Merkle tree off-chain using the Murky library and stores only the 32-byte root on-chain

---

## Project Structure

```
.
├── src/
│   ├── AirdropToken.sol                        # ERC20 token distributed in the airdrop
│   └── WhitelistAirdrop.sol                    # Main airdrop contract
├── script/
│   ├── DeployAirdrop.s.sol                     # Deploys both contracts and funds the airdrop
│   ├── GenerateInput.s.sol                     # Generates the Merkle tree input JSON
│   ├── MakeMerkle.s.sol                        # Generates Merkle proofs from input JSON
│   ├── Interactions.s.sol                      # Claims the airdrop programmatically
│   └── target/
│       ├── input.json                          # Whitelist input file
│       └── output.json                         # Generated Merkle proofs and root
└── test/
    ├── unit/
    │   └── WhitelistAirdropTest.t.sol          # Unit and fuzz tests
    ├── interaction/
    │   └── InteractionTest.t.sol               # Interaction script tests
    └── invariant/
        ├── WhitelistAirdropHandler.t.sol       # Invariant test handler
        └── WhitelistAirdropInvariantTest.t.sol # Invariant test contract
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Install dependencies and build

```bash
forge install
forge build
```

### Run all tests

```bash
forge test
```

### Run specific test suites

```bash
forge test --match-path test/unit/*
forge test --match-path test/interaction/*
forge test --match-path test/invariant/*
```

### Generate the Merkle tree

Step 1 — Generate the input file from the whitelist:

```bash
forge script script/GenerateInput.s.sol
```

Step 2 — Generate Merkle proofs and root:

```bash
forge script script/MakeMerkle.s.sol
```

The output file containing all proofs and the Merkle root will be written to `script/target/output.json`. Copy the root into `DeployAirdrop.s.sol` and the relevant proofs into your test files.

### Deploy to a local Anvil chain

In one terminal, start Anvil:

```bash
anvil
```

In another terminal:

```bash
forge script script/DeployAirdrop.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast
```

### Claim via the interactions script

Step 1 — Get the EIP-712 digest from the deployed contract:

```bash
cast call $CONTRACT_ADDRESS "getMessage(address,uint256)" $ACCOUNT $AMOUNT --rpc-url http://localhost:8545
```

Step 2 — Sign the digest:

```bash
cast wallet sign --private-key $PRIVATE_KEY <digest> --no-hash
```

Step 3 — Paste the signature into `Interactions.s.sol` and run:

```bash
forge script script/Interactions.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast
```

### Deploy to Sepolia

```bash
forge script script/DeployAirdrop.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## Contract Overview

### AirdropToken

A standard ERC20 token with owner-restricted minting. The entire supply is minted at deployment and transferred to the airdrop contract — the owner retains zero tokens after deployment.

| Function                 | Visibility | Description                                  |
| ------------------------ | ---------- | -------------------------------------------- |
| `mint(address, uint256)` | `external` | Mints tokens to a given address. Owner only. |

### WhitelistAirdrop

The main airdrop contract. Holds the token supply and verifies all claims.

| Variable           | Type                       | Description                                  |
| ------------------ | -------------------------- | -------------------------------------------- |
| `i_merkleRoot`     | `bytes32`                  | The Merkle root used to verify proofs        |
| `i_airdropToken`   | `IERC20`                   | The token distributed in the airdrop         |
| `s_hasClaimed`     | `mapping(address => bool)` | Tracks which addresses have claimed          |
| `MESSAGE_TYPEHASH` | `bytes32`                  | EIP-712 typehash for the AirdropClaim struct |

| Function                                                      | Visibility      | Description                                                          |
| ------------------------------------------------------------- | --------------- | -------------------------------------------------------------------- |
| `claim(address, uint256, bytes32[], uint8, bytes32, bytes32)` | `external`      | Claims tokens using a Merkle proof and EIP-712 signature             |
| `getMessage(address, uint256)`                                | `public view`   | Returns the EIP-712 typed data digest for a given account and amount |
| `getMerkleRoot()`                                             | `external view` | Returns the Merkle root                                              |
| `getAirdropToken()`                                           | `external view` | Returns the airdrop token address                                    |
| `getClaimStatus(address)`                                     | `external view` | Returns whether a given address has claimed                          |

| Error                                  | When It Triggers                                  |
| -------------------------------------- | ------------------------------------------------- |
| `WhitelistAirdrop__AlreadyClaimed()`   | The account has already claimed their allocation  |
| `WhitelistAirdrop__InvalidSignature()` | The EIP-712 signature does not match the account  |
| `WhitelistAirdrop__InvalidProof()`     | The Merkle proof does not verify against the root |

| Event                            | When It Emits                   |
| -------------------------------- | ------------------------------- |
| `Claim(address indexed claimer)` | A successful claim is processed |

---

## Claim Flow

```
1. Deployer generates whitelist input and Merkle tree off-chain
2. Deployer deploys AirdropToken and WhitelistAirdrop
3. Deployer mints total supply to owner then immediately transfers to airdrop contract
4. Whitelisted user signs an EIP-712 typed data message off-chain (free)
5. User or gas payer submits claim() with Merkle proof and signature
6. Contract verifies: not already claimed → valid signature → valid Merkle proof
7. Tokens transferred to the whitelisted address
```

---

## Merkle Tree

The whitelist contains four addresses each eligible to claim 25 AT tokens:

| Address                                    | Amount |
| ------------------------------------------ | ------ |
| 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D | 25 AT  |
| 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 | 25 AT  |
| 0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd | 25 AT  |
| 0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D | 25 AT  |

Merkle Root: `0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4`

The Merkle tree uses double-hashed leaves (`keccak256(bytes.concat(keccak256(abi.encode(account, amount))))`) to prevent preimage attacks where an intermediate node could be submitted as a valid leaf.

---

## Tests

### Unit Tests

| Test                                                        | What It Checks                                        |
| ----------------------------------------------------------- | ----------------------------------------------------- |
| `testUsersCanClaim`                                         | Valid claim transfers correct token amount to account |
| `testClaimRevertsIfAccountHasAlreadyClaimed`                | Reverts with AlreadyClaimed on second claim attempt   |
| `testClaimRevertsIfProofIsNotValid`                         | Reverts with InvalidProof when proof is incorrect     |
| `testHasClaimedChangesToTrue`                               | Claim status correctly transitions from false to true |
| `testEmitsWhenAUserClaimsCorrectly`                         | Claim event emitted with correct address              |
| `testGetMessageReturnsANonZeroValue`                        | getMessage returns a non-zero digest                  |
| `testGetMessageProducesDifferentHashesForDifferentAccounts` | Different accounts produce different digests          |
| `testGetMessageProducesDifferentHashesForDifferentAmounts`  | Different amounts produce different digests           |
| `testDigestIsDeterministic`                                 | Same inputs always produce the same digest            |
| `testGetMerkleRootReturnsCorrectRoot`                       | getMerkleRoot returns the correct root                |
| `testGetAirdropTokenReturnsCorrectToken`                    | getAirdropToken returns the correct token address     |
| `testGetClaimStatusReturnsFalseByDefault`                   | Claim status is false before any claim                |
| `testGetClaimStatusReturnsTrueAfterClaim`                   | Claim status is true after a successful claim         |

### Fuzz Tests

| Test                                       | What It Checks                                                                                               |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `testFuzz_ClaimWithValidProofAndSignature` | Any address not in the whitelist always reverts with InvalidProof regardless of how valid their signature is |

### Interaction Tests

| Test                                                  | What It Checks                                                                |
| ----------------------------------------------------- | ----------------------------------------------------------------------------- |
| `testDeployFundsAirdropContractCorrectly`             | Airdrop contract holds the correct token balance after deployment             |
| `testSetterFunctionSetsTheSignature`                  | Signature setter correctly updates the signature in the interactions contract |
| `testClaimantReceivesTokens`                          | Full end-to-end claim via interactions script transfers tokens to claimant    |
| `testAirdropBalanceDecreasesAfterClaiming`            | Airdrop contract balance decreases by the claimed amount                      |
| `testStatusIsTrueAfterRunningClaim`                   | Claim status is true after interactions script runs                           |
| `testInteractionsRevertsIfCalledTwiceWithSameAddress` | Second claim via interactions script reverts with AlreadyClaimed              |

### Invariant Tests

| Invariant                                     | What It Checks                                                           |
| --------------------------------------------- | ------------------------------------------------------------------------ |
| `invariant_totalClaimedNeverExceedsDeposited` | Contract token balance always equals total deposited minus total claimed |
| `invariant_claimStatusNeverReset`             | Once an address has claimed, its claim status can never return to false  |

---

## Security Properties

- Replay protection via `s_hasClaimed` — each address can claim exactly once
- EIP-712 typed data signing prevents signature reuse across different contracts or chains due to the domain separator
- Merkle proof verification ensures only addresses in the original whitelist can claim
- Double-hash leaf pattern prevents preimage attacks on the Merkle tree
- SafeERC20 used for all token transfers
- Immediate transfer of total supply to airdrop contract at deployment eliminates owner custody risk

---

## Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) — ERC20, Ownable, MerkleProof, EIP712, ECDSA, SafeERC20
- [Murky](https://github.com/dmfxyz/murky) — Merkle tree generation utilities
- [Cyfrin Foundry DevOps](https://github.com/Cyfrin/foundry-devops) — Most recent deployment retrieval for interactions script

---

## License

MIT
