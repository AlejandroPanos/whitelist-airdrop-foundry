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
    /**
     * @notice This value comes straight from the output.json file
     * and it is always the same value since it is the root of the Merkle tree
     */
    bytes32 private constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    /**
     * @notice This value is set up in the GenerateInput.s.sol and
     * should be multiplied by the number of whitelist addresses we have
     */
    uint256 private constant AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    /* Deployment function */
    /**
     * @notice This function does the following:
     * 1. Creates a new AirdropToken.sol contract
     * 2. Creates a new WhitelistAirdrop.sol contract
     * 3. Mints the owner all the tokens from the newly created token contract
     * 4. Immediately transfers all the tokens from the owner's
     * address to the newly created airdrop contract
     * @notice If there was not an immediate transfer after the mint,
     * it would be highly centralised and users would be at risk of never
     * being able to mint or receive their tokens
     * @return WhitelistAirdrop The airdrop contract created
     * @return AirdropToken The airdrop token contract created
     */
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
