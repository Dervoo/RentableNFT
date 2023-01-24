// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC4907.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract RentableNFT is ERC721, IERC4907, Ownable {
    IERC4907 public rentInterface;
    using ERC165Checker for *;
    ERC2981 public royalContract;
    uint256 royales;
    uint96 public royaless;
    uint256 price;
    /// @dev royales in Wei or type it as %%%
    address lender;
    address newUser;
    uint256 sixtyDays = 5259486;
    uint256 sixtysecs = 120;
    uint96 fee;
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
        bool isConfirmed;
        uint256 rentDate;
    }
    uint256 royalPrice;
    /// @dev
    // save the transaction timestamp block in a struct and then use it for a casual token sender
    // function depending on whether 60 days have passed and before that it will be for rent and
    // there will be a boolean function for it from openzeppelin defender

    mapping(uint256 => UserInfo) internal _users;
    mapping(bytes4 => bool) private _supportedInterfaces;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo public _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) public _tokenRoyaltyInfo;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function _feeDenominator() public pure virtual returns (uint96) {
        return 10000;
    }

    function _setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view virtual returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }
        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();
        return (royalty.receiver, royaltyAmount);
    }

    function safeMint(address to, uint256 tokenId) public payable onlyOwner {
        /// @dev approach
        // RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];
        // require(msg.value == price + (price * _tokenRoyaltyInfo[tokenId].royaltyFraction / _feeDenominator()));
        require(
            msg.value ==
                price +
                    ((price * _defaultRoyaltyInfo.royaltyFraction) /
                        _feeDenominator())
        );
        _safeMint(to, tokenId);
    }

    /// @dev safeMint function with id boost and then it would fetch the default one

    function getRoyalties() public view returns (uint256) {
        return royales;
    }

    function setRoyalties(uint64 _royales) public onlyOwner {
        royales = _royales;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC4907: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.rentDate = block.timestamp;
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    function validTimeoutTransfer(uint256 tokenId) public onlyOwner {
        // require(msg.sender == ownerOf(tokenId)); inny require na to, przestaje byc ownerem tokena
        UserInfo storage info = _users[tokenId];
        require(_users[tokenId].isConfirmed == true);
        uint256 neededTime = info.rentDate + sixtysecs;
        // do expire przekaze 60 dni wiec wczesniej niz to nie bedzie mozna walnac transferu
        require(_users[tokenId].expires < neededTime);
        transferFrom(msg.sender, info.user, tokenId);
        // this function for autotask in defender
        // mozna sprobowac ustawic if expires 0 > od indexu danego to autotask jakos ruszyc
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    function isConfirmed(uint256 tokenId) public view returns (bool) {
        bool confirmation = _users[tokenId].isConfirmed;
        return confirmation;
    }

    // to mogloby byc platne payable z require msg.value == pricing (web3 msg value to jest tyle ethera i tyle) do tego funkcja setPrice
    function confirmPurchase(uint256 tokenId) public payable {
        require(msg.value == price + (price * royales) / 100);
        /// @dev
        // do withdraw
        // get useraddress through window.eth
        // user needs to pass their cardId (having NFTs)
        // requirements for only user which holds to these specific cardIds(nfts)
        // require(_users[cardId].user == username);
        // change require because in the end they should only suggest that they want and we perform actions !!!
        // after that contract has a token, it needs to be changed
        _users[tokenId].isConfirmed = true;
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (
            from != to &&
            _users[tokenId].user != address(0) &&
            _users[tokenId].isConfirmed == false
        ) {
            // else if  jak bedzie is confirmed false to usuwamy a jak bedzie true to robimy minta (transfer bo juz minted do tego wlasnie uzytkownika)
            delete _users[tokenId];
            emit UpdateUser(tokenId, from, 0); // @dev address[0]
        }
        /// @dev another thinking
        // } else if (_users[tokenId].isConfirmed == true && from != to && _users[tokenId].user != address(0)) {
        //     lender = ownerOf(tokenId);
        //     UserInfo storage info =  _users[tokenId];
        //     newUser = _users[tokenId].user;
        //     safeTransferFrom(lender, info.user, tokenId);
        // } else {

        // }
    }
}
// Note 1: ORACLE DeFi??? Unknown && Who will borrow, who will call setUser? && Add approva to the new owner for the token???
// Note 2: When it performs the validTimeoutTransfer function during the loan (setUser), the address that had the token remains in userOf.
// Note 3: Create timelocked function which returns x days estimate, then use it to be the guarantee for renting - approach