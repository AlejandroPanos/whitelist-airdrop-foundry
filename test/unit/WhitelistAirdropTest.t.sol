// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {AirdropToken} from "src/AirdropToken.sol";
import {WhitelistAirdrop} from "src/WhitelistAirdrop.sol";
import {DeployAirdrop} from "script/DeployAirdrop.s.sol";

contract WhitelistAirdropTest is Test {
    /* Instantiate contracts */
    AirdropToken token;
    WhitelistAirdrop airdrop;
    DeployAirdrop deployer;

    /* State variables */
    bytes32 private constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant AMOUNT = 25 * 1e18;

    bytes32 private constant PROOF_ONE = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof;

    address user;
    uint256 userPrivateKey;
    address gasPayer;

    /* Set up function */
    function setUp() external {
        deployer = new DeployAirdrop();
        (airdrop, token) = deployer.run();
        (user, userPrivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");

        proof.push(PROOF_ONE);
        proof.push(PROOF_TWO);
    }

    /* Testing functions */
    function testUsersCanClaim() public {
        // Arrange
        uint256 initialBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // Act
        vm.prank(gasPayer);
        console2.log(proof.length);
        airdrop.claim(user, AMOUNT, proof, v, r, s);
        uint256 endingBalance = token.balanceOf(user);

        // Assert
        assertEq(endingBalance - initialBalance, AMOUNT);
    }
}
