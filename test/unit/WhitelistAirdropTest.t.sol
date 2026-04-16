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

    bytes32 private constant PROOF_THREE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32[] private invalid_proof = [PROOF_ONE, PROOF_THREE];

    address user;
    uint256 userPrivateKey;
    address gasPayer;

    /* Events */
    event Claim(address indexed claimer);

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

    /* ========================= */
    /* CLAIM FUNCTION TESTING    */
    /* ========================= */
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

    function testClaimRevertsIfAccountHasAlreadyClaimed() public {
        // Arrange
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // Act
        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT, proof, v, r, s);

        // Assert
        vm.prank(gasPayer);
        vm.expectRevert(WhitelistAirdrop.WhitelistAirdrop__AlreadyClaimed.selector);
        airdrop.claim(user, AMOUNT, proof, v, r, s);
    }

    function testClaimRevertsIfProofIsNotValid() public {
        // Arrange
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // Act
        vm.prank(gasPayer);
        vm.expectRevert(WhitelistAirdrop.WhitelistAirdrop__InvalidProof.selector);
        airdrop.claim(user, AMOUNT, invalid_proof, v, r, s);
    }

    function testHasClaimedChangesToTrue() public {
        // Arrange
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bool statusBefore = airdrop.getClaimStatus(user);

        // Act
        vm.prank(user);
        airdrop.claim(user, AMOUNT, proof, v, r, s);
        bool statusAfter = airdrop.getClaimStatus(user);

        // Assert
        assertEq(statusBefore, false);
        assertEq(statusAfter, true);
        assert(statusBefore != statusAfter);
    }

    function testEmitsWhenAUserclaimsCorrectly() public {
        // Arrange
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // Act
        vm.prank(user);
        vm.expectEmit(true, false, false, false);
        emit Claim(user);
        airdrop.claim(user, AMOUNT, proof, v, r, s);
    }

    /* ============================== */
    /* GETMESSAGE FUNCTION TESTING    */
    /* ============================== */
    function testGetMessageReturnsANonZeroValue() public view {
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        assert(digest != bytes32(0));
    }

    function testGetMessageProducesDifferentHashesForDifferentAccounts() public {
        // Arrange
        bytes32 userDigest = airdrop.getMessage(user, AMOUNT);

        address randUser = makeAddr("randUser");
        bytes32 randUserDigest = airdrop.getMessage(randUser, AMOUNT);

        // Act / Assert
        assert(userDigest != randUserDigest);
    }

    function testGetMessageProducesDifferentHashesForDifferentAmounts() public view {
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        bytes32 modifiedDigest = airdrop.getMessage(user, AMOUNT + 1);
        assert(digest != modifiedDigest);
    }

    function testDigestIsDeterministic() public view {
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        bytes32 secondDigest = airdrop.getMessage(user, AMOUNT);
        assertEq(digest, secondDigest);
    }

    /* ========================= */
    /* GETTER FUNCTION TESTING   */
    /* ========================= */

    function testGetMerkleRootReturnsCorrectRoot() public view {
        assertEq(airdrop.getMerkleRoot(), MERKLE_ROOT);
    }

    function testGetAirdropTokenReturnsCorrectToken() public view {
        assertEq(address(airdrop.getAirdropToken()), address(token));
    }

    function testGetClaimStatusReturnsFalseByDefault() public view {
        assertEq(airdrop.getClaimStatus(user), false);
    }

    function testGetClaimStatusReturnsTrueAfterClaim() public {
        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT, proof, v, r, s);

        assertEq(airdrop.getClaimStatus(user), true);
    }
}
