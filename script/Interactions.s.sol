// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {WhitelistAirdrop} from "src/WhitelistAirdrop.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Interactions is Script {
    /* State variables */
    address private constant ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant AMOUNT = 25 * 1e18;

    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof = [PROOF_ONE, PROOF_TWO];

    bytes private SIGNATURE =
        hex"e6daba7e95f9099d91a9302ad015d956e1798978b0632a0eb8798d5e13f7f734407ba27caaded62631223d997180924ead95c3d5fe8e7953ba8658b91e115e051b";

    /* Functions */
    function claim(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        WhitelistAirdrop(airdrop).claim(ACCOUNT, AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
        console.log("Airdrop Completed");
    }

    function getMostRecentlyDeployed() internal returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("WhitelistAirdrop", block.chainid);
        claim(mostRecentlyDeployed);
    }
}
