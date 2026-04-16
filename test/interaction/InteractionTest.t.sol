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
        interactions = new Interactions();
        deployer = new DeployAirdrop();
        (airdrop, token) = deployer.run();
    }

    /* Testing functions */
    function testDeployFundsAirdropContractCorrectly() public view {
        uint256 expectedBalance = 4 * AMOUNT;
        assertEq(token.balanceOf(address(airdrop)), expectedBalance);
    }

    function testClaimantReceivesTokens() public {
        // Generate fresh signature against the actual deployed contract address
        uint256 claimantPrivKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        bytes32 digest = airdrop.getMessage(CLAIM_ADDRESS, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimantPrivKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Inject the fresh signature
        interactions.setSignature(signature);

        // Now claim
        uint256 initialBalance = token.balanceOf(CLAIM_ADDRESS);
        interactions.claim(address(airdrop));
        assertEq(token.balanceOf(CLAIM_ADDRESS), initialBalance + AMOUNT);
    }
}
