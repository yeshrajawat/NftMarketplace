
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import  "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
    
    
    address payable public immutable feeAccount; // Account that receives the fees
    uint public immutable feePercent;
    uint public itemCount;

    struct Item {
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
    }

    event Offered(
       uint itemId,
       address indexed nft,
       uint tokenId,
       uint price,
       address indexed seller 
    );
    event Bought(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer 
    );

    mapping(uint => Item) public items;

    constructor(uint _feePercent) {
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }


    function makeItem(IERC721 _nft,uint _tokenId,uint price) external nonReentrant{
        require(price > 0,"Price must be greater than zero");
        itemCount++;
        _nft.transferFrom(msg.sender, address(this), _tokenId);

        items[itemCount] = Item(
            itemCount,
            _nft,
            _tokenId,
            price,
            payable(msg.sender),
            false
        );

        emit Offered(
            itemCount,
            address(_nft),
            _tokenId,
            price,
            msg.sender
        );



    }


    function purchaseItem(uint _itemId) external payable nonReentrant {
        uint totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];

        require(_itemId > 0 && _itemId <= itemCount,"item Doesn't exist");
        require(msg.value >= totalPrice, "Not enough ether to cover item price and market fee");
        require(!item.sold,"item already sold");


        item.seller.transfer(item.price);
        feeAccount.transfer(totalPrice - item.price);
        item.sold = true;
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);
        
         emit Bought(_itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
            );
    }

    function getTotalPrice(uint _itemId) view public returns(uint) {
         return (items[_itemId].price * ( 100 + feePercent )/ 100);
         
    }





}