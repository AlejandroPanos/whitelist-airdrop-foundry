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
    error WhitelistAirdrop__InvalidSignature();
    error WhitelistAirdrop__InvalidProof();

    /* State variables */
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    mapping(address user => bool hasClaimed) s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /* Events */
    event Claim(address indexed claimer);

    /* Constructor */
    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("Whitelist Airdrop", "1.0.0") {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
    }

    /* Functions */
    /**
     * @notice This function allows a user to claim tokens
     * @param _account The address of the user claiming
     * @param _amount The amount the user wants to claim
     * @param _merkleProof The list of sibling hashes needed
     * to reconstruct the path up to the Merkle root
     * @param v Used to recover the public key the user used
     * @param r An x-coord in the elliptic curve
     * @param s The signature proof value
     * @dev The leaf gets hashed twice and concatenated to
     * prevent preimage attacks
     * @dev Uses the safeTransfer() function from IERC20
     */
    function claim(address _account, uint256 _amount, bytes32[] calldata _merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // Checks
        if (s_hasClaimed[_account] == true) {
            revert WhitelistAirdrop__AlreadyClaimed();
        }

        if (!_isValidSignature(_account, getMessage(_account, _amount), v, r, s)) {
            revert WhitelistAirdrop__InvalidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));

        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert WhitelistAirdrop__InvalidProof();
        }

        // Effects
        s_hasClaimed[_account] = true;

        emit Claim(_account);

        // Interactions
        i_airdropToken.safeTransfer(_account, _amount);
    }

    /**
     * @notice This is a helper function that allows us
     * to get the bytes32 digest
     * @param _account The account of the user that signs
     * @param _amount The amount that the user wants to claim
     * @return bytes32 Returns the bytes32 digest object
     */
    function getMessage(address _account, uint256 _amount) public view returns (bytes32) {
        // Create the struct
        AirdropClaim memory airdrop = AirdropClaim({account: _account, amount: _amount});

        // Return the bytes32 hashed digest
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, airdrop)));
        return digest;
    }

    /**
     * @notice Internal function only to be called from
     * within this contract to check if a signature is valid or not
     * @param _account The account of the user we want to check
     * @param _digest The bytes32 digest object calculated in getMessage()
     * @param v Used to recover the public key the user used
     * @param r An x-coord in the elliptic curve
     * @param s The signature proof value
     * @return bool Returns true if the actual signer is the account owner
     * @dev This function uses the EDCSA tryRecover() function. This returns 2 params
     * but we only need the first returned value which is the signer of the txn
     * to compare it with the account passed as an argument and check they are equal
     */
    function _isValidSignature(address _account, bytes32 _digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        // Retrieve the signer
        (address recovered,,) = ECDSA.tryRecover(_digest, v, r, s);

        // Check if signer matches
        bool isSigner = recovered == _account;

        // Return the value
        return isSigner;
    }

    /* Getter functions */
    /**
     * @notice Getter function that returns the merkle root bytes32 object
     * @return bytes32 Returns the merkle root bytes32 object
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /**
     * @notice Getter function that returns the IERC20 token
     * @return IERC20 Returns the IERC20 token
     */
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    /**
     * @notice Getter function that returns the bool value for user claims
     * @return bool Returns the bool value for a user
     */
    function getClaimStatus(address _user) external view returns (bool) {
        return s_hasClaimed[_user];
    }
}
