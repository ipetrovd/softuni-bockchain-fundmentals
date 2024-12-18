// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EventTicketNFT is ERC721, Ownable {
    using Strings for uint256;

    constructor() ERC721("EventTicketNFT", "ETN") Ownable(msg.sender) {}

    struct Event {
        uint256 id;
        bool isTicketSaleActive; // TODO could add timestamp for event expiry
        string[20] nameEvent;
        uint256 ticketPrice;
        uint256 availableTickets;
    }

    uint256 internal _nextEventId;
    string internal baseURI = "./Metadata/"; // TODO upload the JSONs to IPFS

    mapping(uint256 eventId => Event _event) public events;
    mapping(uint256 _tokenId => address buyer) public purchases;

    event NewEvent(
        uint256 indexed eventId,
        string[20] indexed name,
        uint256 indexed ticketPrice
    );
    event Purchase(
        uint256 indexed eventId,
        address indexed buyer,
        uint256 indexed tokenId
    );

    error ETNInvalidEventId();
    error ETNInvalidNumberInput();
    error ETNInactiveTicketSale();
    error ETNNoTicketsAvailable();
    error ETNNotEnoughETHforTicket();

    // TODO add receive func

    // TODO add call back

    function createEvent(
        bool _isTicketSaleActive,
        string[20] calldata _name,
        uint256 _ticketPrice,
        uint256 _availableTickets
    )
        external
        onlyOwner
        isNotZero(_ticketPrice)
        isNotZero(_availableTickets)
        returns (uint256 _eventId)
    {
        _eventId = _nextEventId;
        events[_nextEventId] = Event({
            id: _eventId,
            isTicketSaleActive: _isTicketSaleActive,
            nameEvent: _name,
            ticketPrice: _ticketPrice,
            availableTickets: _availableTickets
        });
        _nextEventId++;
        emit NewEvent(_eventId, _name, _ticketPrice);
    }

    /**
     * @dev Purchase one ticket at a time for specific event.
     */
    function purchaseTicket(
        uint256 _eventId,
        uint256 _tokenId
    )
        public
        payable
        eventExist(_eventId)
        checkPrice(_eventId, msg.value)
        hasTicketsAvailable(_eventId)
        returns (bool success)
    {
        events[_eventId].availableTickets--;
        purchases[_tokenId] = msg.sender;
        emit Purchase(_eventId, msg.sender, _tokenId);
        return true;
    }

    // function tokenURI(
    //     uint256 tokenId
    // ) public view override returns (string memory) {
    //     _requireOwned(tokenId);

    //     return
    //         bytes(baseURI).length > 0
    //             ? string.concat(baseURI, tokenId.toString())
    //             : super._baseURI();
    // }

    // function safeMint(
    //     address to,
    //     uint256 tokenId,
    //     bytes memory data
    // ) public onlyOwner {
    //     super._safeMint();
    //     ERC721Utils.checkOnERC721Received(
    //         _msgSender(),
    //         address(0),
    //         to,
    //         tokenId,
    //         data
    //     );
    // }

    function updateActiveTicketSale(
        uint256 _eventId,
        bool _newStatus
    ) external onlyOwner eventExist(_eventId) returns (bool) {
        events[_eventId].isTicketSaleActive = _newStatus;
    }

    modifier eventExist(uint256 _eventId) {
        require(events[_eventId].nameEvent.length > 0, "Event does not exist");
        _;
    }

    modifier checkPrice(uint256 _eventId, uint256 _price) {
        if (events[_eventId].ticketPrice < _price) {
            revert ETNNotEnoughETHforTicket();
        }
        _;
    }

    modifier isNotZero(uint256 _number) {
        if (_number == 0) {
            revert ETNInvalidNumberInput();
        }
        _;
    }

    modifier isTicketSaleActive(uint256 _eventId) {
        if (events[_eventId].isTicketSaleActive == false) {
            revert ETNInactiveTicketSale();
        }
        _;
    }

    modifier hasTicketsAvailable(uint256 _eventId) {
        if (events[_eventId].availableTickets == 0) {
            revert ETNNoTicketsAvailable();
        }
        _;
    }
}
