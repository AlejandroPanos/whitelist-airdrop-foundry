// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {WhitelistAirdrop, IERC20} from "src/WhitelistAirdrop.sol";
import {AirdropToken} from "src/AirdropToken.sol";

contract DeployAirdrop is Script {
    /* Instantiate contracts */
    WhitelistAirdrop airdrop;
    AirdropToken token;

    /* State variables */
    bytes32 private constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    /* Deployment function */
    function run() external returns (WhitelistAirdrop, AirdropToken) {
        vm.startBroadcast();
        token = new AirdropToken();
        airdrop = new WhitelistAirdrop(MERKLE_ROOT, IERC20(token));
        token.mint(token.owner(), AMOUNT_TO_TRANSFER);
        token.transfer(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (airdrop, token);
    }
}
