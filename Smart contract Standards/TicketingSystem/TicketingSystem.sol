// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketingSystem is ERC721, Ownable {
    uint256 private _ticketIds; // Counter for token IDs
    uint256 public ticketPrice;

    constructor() ERC721("EventTicketNFT", "ETN") Ownable(msg.sender) {}

    function _setTicketPrice(uint256 newTicketPrice) public onlyOwner {}

    function _mint() public onlyOwner {}
}
