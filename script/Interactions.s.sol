// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {WhitelistAirdrop} from "src/WhitelistAirdrop.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Interactions is Script {
    /* Errors */
    error Interactions__InvalidSignatureLength();

    /* State variables */
    address private constant ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant AMOUNT = 25 * 1e18;

    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof = [PROOF_ONE, PROOF_TWO];

    bytes public SIGNATURE =
        hex"26119110b21f3d6cdf5a6da487c675aca3cb2d53cee21c1ea32fca136c2d32fc3bdacdde510f428f2471d04d4d6d61d5dd18a750f2a85004454e8edb464581eb1c";

    /* Functions */
    /**
     * @notice This function acts as a user claiming their allocated amount of tokens
     * @notice This function performs the following actions:
     * 1. Splits the signature so it can be passed to the claim() function
     * 2. Calls the claim() function with the specified params
     * @param airdrop This is the address of the most recently deployer Airdrop contract
     */
    function claim(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(SIGNATURE);
        WhitelistAirdrop(airdrop).claim(ACCOUNT, AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
        console.log("Airdrop Completed");
    }

    function setSignature(bytes memory _signature) external {
        SIGNATURE = _signature;
    }

    /**
     * @notice This is a helper function that splits a signature into its 3 components (v, r, s)
     * @param _signature The signature created
     * @return v Used to recover the public key the user used
     * @return r An x-coord in the elliptic curve
     * @return s The signature proof value
     */
    function _splitSignature(bytes memory _signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (_signature.length != 65) {
            revert Interactions__InvalidSignatureLength();
        }

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    /**
     * @notice Function that returns the most recently deployed Airdrop contract
     * @dev Uses the Fonudry DevOps package
     */
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("WhitelistAirdrop", block.chainid);
        claim(mostRecentlyDeployed);
    }
}
