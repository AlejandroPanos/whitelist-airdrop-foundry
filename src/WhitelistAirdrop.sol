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
    function claim(address _account, uint256 _amount, bytes32[] calldata _merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // Checks
        if (s_hasClaimed[_account] == true) {
            revert WhitelistAirdrop__AlreadyClaimed();
        }
    }

    function getMessage(address _account, uint256 _amount) public view returns (bytes32) {
        // Create the struct
        AirdropClaim memory airdrop = AirdropClaim({account: _account, amount: _amount});

        // Return the bytes32 hashed digest
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, airdrop)));
        return digest;
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        // Retrieve the signer
        (address recovered,,) = ECDSA.tryRecover(digest, v, r, s);

        // Check if signer matches
        bool isSigner = recovered == account;

        // Return the value
        return isSigner;
    }
}
