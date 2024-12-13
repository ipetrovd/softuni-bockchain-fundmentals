// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

// ERC20-compliant BBP token, implementing loyalty system of BrewBean.
// Partnering cofee shops of BrewBean can reward customers with points on each purchase.
// Customers can earn loyalty points on their purchases and can redeem points.
// Each partner can customize the rules for rewarding and redeeming points.

interface ILoyaltyPoints {
    // Allows cafes to issue BBP tokens to customer
    function rewardPoints(address _customer) external returns (uint256 points);

    // Allows users to spend their points
    function redeemPoints(uint256 _points) external returns (uint256 points);
}

abstract contract BaseLoyaltyProgram is ILoyaltyPoints {



    event Rewarded(address indexed customer, CofeeShop indexed shop, uint256 indexed points);
    event Redeemed(address indexed customer, CofeeShop indexed shop, uint256 indexed points);

    // verify if a customer is eligible for points
    function _authorizeReward(
        address _customer
    ) internal returns (bool isEligible) {

    };

    function rewardPoints(address _customer) external returns (uint256 points);

    function redeemPoints(uint256 _points) external returns (uint256 points);

}


contract BrewBeanPoints is BaseLoyaltyProgram {

    address public owner;
    string public name = "BrewBeanPoints";
    string public symbol = "BBP";
    uint256 public decimals = 1e18;

    constructor() {
        owner = msg.sender;
    }

    struct CofeeShop {
        uint256 id;
        string shopName;
        address shopOwner;
        uint256 
        // Tracks the spending and loyalty points of each customer of the shop
        mapping(address customer => mapping(uint256 spending => uint256 points)) loyalCustomers;
    }

    uint256 shopId;
    mapping(uint256 shopId => mapping(CofeeShop shop => bool authorized)) authorizedCofeeShops;

    modifier onlyPartner(uint256 _id) {
        require(msg.sender == authorizedCofeeShops[_id].shopOwner, "!auth");
        _;
    };

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function createCofeeShop(string calldata shopName) public onlyOwner() {
    
        authorizedCofeeShops[]

    };

}
