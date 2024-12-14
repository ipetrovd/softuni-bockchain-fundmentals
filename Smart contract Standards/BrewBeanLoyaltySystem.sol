// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

// ERC20-compliant BBP token, implementing loyalty system of BrewBean.
// Partnering cofee shops of BrewBean can reward customers with points on each purchase.
// Customers can earn loyalty points on their purchases and can redeem points.
// Each partner can customize the rules for rewarding and redeeming points.

interface ILoyaltyPoints {
    // Allows cafes to issue BBP tokens to customer
    function rewardPoints(
        uint256 shopId,
        address _customer
    ) external returns (uint256 points);

    // Allows users to spend their points
    function redeemPoints(
        uint256 shopId,
        uint256 _points
    ) external returns (uint256 points);
}

abstract contract BaseLoyaltyProgram is ILoyaltyPoints {
    uint256 shopId;

    struct RewardConditions {
        uint256 minimumSpendingTarget;
        uint256 rewardPercentage;
    }

    struct CofeeShop {
        uint256 id;
        string shopName;
        address shopOwner;
        RewardConditions conditions;
        // Tracks the spending and loyalty points of each customer of the shop
        mapping(address customer => mapping(uint256 spending => uint256 points)) loyalCustomers;
    }

    mapping(uint256 shopId => mapping(CofeeShop shop => bool isAuthorized)) cofeeShops;

    event Rewarded(
        address indexed customer,
        CofeeShop indexed shop,
        uint256 indexed points
    );
    event Redeemed(
        address indexed customer,
        CofeeShop indexed shop,
        uint256 indexed points
    );

    modifier _isAuthCofeeShop(uint256 _shopId) {
        require(cofeeShops[_shopId] != false, "!auth shop");
        _;
    }

    // verify if a customer is eligible for points
    modifier _authorizeReward(uint256 _shopId, address _customer) {
        CofeeShop _shop = _getShop(_shopId);

        require(
            _shop[_customer] >=
                cofeeShops[_shopId].conditions.minimumSpendingTarget,
            "!minimum spending target"
        );
        _;
    }

    function _getShop(
        uint256 _shopId
    ) internal view _isAuthCofeeShop(_shopId) returns (CofeeShop) {
        return cofeeShops[_shopId];
    }

    function rewardPoints(
        uint256 _shopId,
        address _customer
    )
        external
        _isAuthCofeeShop(_shopId)
        _authorizeReward(_shopId, _customer)
        returns (uint256 points)
    {}

    function redeemPoints(
        uint256 _shopId,
        uint256 _points
    ) external returns (uint256 points);
}

contract BrewBeanPoints is BaseLoyaltyProgram {
    address public owner;
    string public name = "BrewBeanPoints";
    string public symbol = "BBP";
    uint256 public decimals = 1e18;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyPartner(uint256 _id) {
        require(msg.sender == cofeeShops[_id].shopOwner, "!auth");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier validatePercentage(uint8 _rewardPercentage) {
        require(
            _rewardPercentage > 0 && _rewardPercentage <= 100,
            "!_rewardPercentage"
        );
        _;
    }

    modifier validateTarget(uint256 _minSpendingTarget) {
        require(_minSpendingTarget > 0, "!_minSpendingTarget");
        _;
    }

    function createCofeeShop(
        string calldata _shopName,
        uint256 _minSpendingTarget,
        uint256 _rewardPercentage
    ) public validatePercentage(_rewardPercentage) returns (uint256 shopId) {
        shopId++;
        cofeeShops[shopId] = new CofeeShop({
            id: shopId,
            shopName: _shopName,
            shopOwner: msg.sender,
            conditions: RewardConditions({
                minimumSpendingTarget: _minSpendingTarget,
                rewardPercentage: _rewardPercentage
            })
        });
    }
}
