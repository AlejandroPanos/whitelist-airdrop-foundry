// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployAirdrop} from "script/DeployAirdrop.s.sol";
import {Interactions} from "script/Interactions.s.sol";
import {AirdropToken} from "src/AirdropToken.sol";
import {WhitelistAirdrop} from "src/WhitelistAirdrop.sol";

contract InteractionTest is Test {
    /* Instantiate contracts */
    DeployAirdrop deployer;
    Interactions interactions;
    AirdropToken token;
    WhitelistAirdrop airdrop;

    /* Variables */
    address private constant CLAIM_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant AMOUNT = 25 * 1e18;

    /* Set up function */
    function setUp() external {
        interacitions = new Interactions();
        deployer = new DeployAirdrop();
        (airdrop, token) = deployer.run();
    }
}
