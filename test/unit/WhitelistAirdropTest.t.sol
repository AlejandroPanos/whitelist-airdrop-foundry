// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
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

    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
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
}
