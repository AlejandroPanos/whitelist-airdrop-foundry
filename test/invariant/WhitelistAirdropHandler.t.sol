// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {WhitelistAirdrop} from "src/WhitelistAirdrop.sol";

contract WhitelistAirdropHandler is Test {
    /* Instantiate contract */
    WhitelistAirdrop airdrop;

    /* State variable */
    uint256 public s_totalClaimed;
    mapping(address user => bool hasClaimed) public s_hasClaimed;

    uint256 private constant AMOUNT = 25 * 1e18;

    bytes32 private constant PROOF_ONE = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof;

    address public user;
    uint256 public userPrivateKey;

    /* Constructor */
    constructor(WhitelistAirdrop _airdrop) {
        airdrop = _airdrop;
        (user, userPrivateKey) = makeAddrAndKey("user");

        proof.push(PROOF_ONE);
        proof.push(PROOF_TWO);
    }

    /* Testing functions */
    function claim() public {
        if (airdrop.getClaimStatus(user)) return;

        bytes32 digest = airdrop.getMessage(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        airdrop.claim(user, AMOUNT, proof, v, r, s);

        s_totalClaimed += AMOUNT;
        s_hasClaimed[user] = true;
    }
}
