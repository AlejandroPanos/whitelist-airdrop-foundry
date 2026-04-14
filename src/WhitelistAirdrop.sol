// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract WhitelistAirdrop is EIP712 {
    /* Library */
    using SafeERC20 for IERC20;

    /* Errors */
    error WhitelistAirdrop__AlreadyClaimed();

    /* State variables */
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    mapping(address user => bool hasClaimed) s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /* Events */
    event Claim();

    /* Constructor */
    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("Whitelist Airdrop", "1.0.0") {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
    }

    /* Functions */
}
