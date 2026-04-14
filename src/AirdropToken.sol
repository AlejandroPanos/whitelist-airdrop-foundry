// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AirdropToken is ERC20, Ownable {
    /* Constructor */
    constructor() ERC20("AirdropToken", "AT") Ownable(msg.sender) {}

    /* Functions */
    /**
     * @notice Function that only the owner can call in order to mint
     * all the tokens available in the contract.
     * @param _account The account we want to mint the tokens to
     * @param _value The amount we want to mint
     * @dev Calls the internal _mint() function from the OpenZeppelin
     * ERC20 contract
     */
    function mint(address _account, uint256 _value) external onlyOwner {
        _mint(_account, _value);
    }
}
