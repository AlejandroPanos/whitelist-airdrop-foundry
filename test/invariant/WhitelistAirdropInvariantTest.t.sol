// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {WhitelistAirdropHandler} from "./WhitelistAirdropHandler.t.sol";
import {WhitelistAirdrop} from "src/WhitelistAirdrop.sol";
import {AirdropToken} from "src/AirdropToken.sol";
import {DeployAirdrop} from "script/DeployAirdrop.s.sol";

contract WhitelistAirdropInvariantTest is Test {
    /* Instantiate contracts */
    WhitelistAirdropHandler handler;
    WhitelistAirdrop airdrop;
    AirdropToken token;
    DeployAirdrop deployer;

    /* Set up function */
    function setUp() external {
        deployer = new DeployAirdrop();
        (airdrop, token) = deployer.run();
        handler = new WhitelistAirdropHandler(airdrop);
        targetContract(address(handler));
    }

    /* Invariant tests */
    function invariant_totalClaimedNeverExceedsDeposited() public view {
        uint256 totalDeposited = 4 * 25e18;
        assertGe(token.balanceOf(address(airdrop)), totalDeposited - handler.s_totalClaimed());
    }

    function invariant_invariant_claimStatusNeverReset() public view {
        address user = handler.user();
        if (handler.s_hasClaimed(user)) {
            assert(airdrop.getClaimStatus(user));
        }
    }
}
