// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract DigitalLibrary {

    enum EBookStatus { Active, Outdated, Archived }

    struct EBook {
        uint256 id;
        string title;
        string author;
        uint256 publicationDate;
        uint256 expirationDate;
        EBookStatus status;
        address primaryLibrarian;
        uint256 readCount;
    }

    EBook[] public books;
    uint256 public defaultExpirationDate = block.timestamp + 180 days;
    mapping(uint256 => mapping(address => bool)) public authorizedLibrariansByBook;
    error InvalidExpirationDate();

    event BookStatusChanged(EBookStatus oldStatus, EBookStatus newStatus);
    event EBookAccessed(uint256 bookId, string title, string author, uint256 readCount);

    function isAuthorized(uint256 bookId, address librarian) internal view returns (bool) {
        return authorizedLibrariansByBook[bookId][librarian];
    }

    // Creates book and returns book id (equal to array index)
    function createBook (string memory title, string memory author, uint256 publicationDate) external returns (uint256 bookId) {
        require(publicationDate > 0, "Not a valid publicationDate ");
        require(bytes(title).length != 0 || bytes(author).length != 0, "Empty title or author");
        require(bytes(title).length <= 100, "Title too long");
        require(bytes(author).length <= 100, "Author too long");

        EBook memory newBook = EBook({
            id: books.length,
            title: title,
            author: author,
            publicationDate: publicationDate,
            expirationDate: defaultExpirationDate,
            status: EBookStatus.Active,
            primaryLibrarian: msg.sender,
            readCount: 0
        });
        
        books.push(newBook);
        
        return books.length-1;
    }

    // Only the primary librarian can add additional authorized librarians for an e-book.
    // Returns true if successfully added
    function addLibrarian(uint256 bookId, address librarian) external returns (bool) {
        require(msg.sender == books[bookId].primaryLibrarian, "Unauthorized primary librarian");
        return authorizedLibrariansByBook[bookId][librarian] = true;
    }

    // Only authorized librarians can extend the expiration date.
    // Returns the newExpDate if successful txn
    function extendExpDate(uint256 bookId, uint256 newExpDate) external returns (uint256) {
        require(isAuthorized(bookId, msg.sender), "Unauthorized librarian");
        require(newExpDate != 0, "Expiration date cannot be zero");
    
        return books[bookId].expirationDate = newExpDate;
    }

    // Only primary librarian can change book status
    function changeBookStatus(uint256 bookId, EBookStatus newStatus) external {
        require(msg.sender == books[bookId].primaryLibrarian, "Not a primary librarian");
        EBookStatus oldStatus = books[bookId].status;
        books[bookId].status = newStatus;

        emit BookStatusChanged(oldStatus, newStatus);
    }

    // Increases the read count and returns whether the e-book is outdated (real-time)
    // based on the expiration date.
    function isExpired(uint256 bookId) external returns (bool) {
        books[bookId].readCount += 1;
        return books[bookId].expirationDate < block.timestamp;
    }

    // Returns EBook and increaes read count
    function getEBook(uint256 bookId) external {
        books[bookId].readCount += 1;
        emit EBookAccessed(bookId, books[bookId].title, books[bookId].author, books[bookId].readCount);
    }
}
