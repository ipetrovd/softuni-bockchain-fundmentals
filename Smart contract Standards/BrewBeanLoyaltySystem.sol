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
    struct RewardConditions {
        uint256 minimumSpendingTarget;
        uint256 rewardPercentage;
    }

    struct CofeeShop {
        uint256 id;
        string shopName;
        address shopOwner;
        bool isAuthorized;
    }

    uint256 internal shopId;
    // Contains all shops
    mapping(uint256 shopId => CofeeShop shop) public cofeeShops;
    // Cofee shop's reward conditions
    mapping(uint256 shopId => RewardConditions) public rewardConditions;
    // Customer spendings for a specific shop
    mapping(uint256 shopId => mapping(address customer => uint256 spendings))
        public customerSpendingsForShop;
    // Customer BPP points, issued by a specific shop
    mapping(uint256 shopId => mapping(address customer => uint256 points))
        public customerPointsForShop;
    // Total customer BPP points from all shops
    mapping(address customer => uint256 points) public totalCustomerBBPoints;
    // Allowance for withdrawals
    mapping(uint256 shopId => mapping(address approver => mapping(address spender => uint256 points)))
        public allowance;

    event Rewarded(
        uint256 indexed _shopId,
        address indexed customer,
        uint256 indexed points
    );
    event Redeemed(
        uint256 indexed _shopId,
        address indexed customer,
        uint256 indexed points
    );

    function _getRewardPoints(
        uint256 _shopId,
        address _customer
    ) internal view returns (uint256 _points) {
        RewardConditions memory _conditions = rewardConditions[_shopId];
        uint256 _spendings = customerSpendingsForShop[_shopId][_customer];

        uint256 factor = 1e18;
        uint256 scalledPercentage = (_conditions.rewardPercentage * factor) /
            100;
        _points = (_spendings * scalledPercentage) / factor;
    }

    function rewardPoints(
        uint256 _shopId,
        address _customer
    )
        external
        virtual
        isPartnerCofeeShop(_shopId)
        authorizeReward(_shopId, _customer)
        returns (uint256 points)
    {
        points = _getRewardPoints(_shopId, _customer);
        customerPointsForShop[_shopId][_customer] += points;
    }

    function redeemPoints(
        uint256 _shopId,
        uint256 _points
    ) external virtual returns (uint256 points) {} // TODO

    modifier isPartnerCofeeShop(uint256 _shopId) {
        require(cofeeShops[_shopId].isAuthorized == true, "!auth shop");
        _;
    }

    // verify if a customer is eligible for points
    modifier authorizeReward(uint256 _shopId, address _customer) {
        // Customer spendings >= minimum spending target
        require(
            customerSpendingsForShop[_shopId][_customer] >=
                rewardConditions[_shopId].minimumSpendingTarget,
            "!minimum spending target"
        );
        _;
    }
}

contract BrewBeanPoints is BaseLoyaltyProgram {
    address public owner;
    string public name = "BrewBeanPoints";
    string public symbol = "BBP";
    uint256 public decimals = 1e18;
    uint256 public totalSupply;

    constructor() {
        owner = msg.sender;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _oldValue,
        uint256 _value
    );

    error InsufficientBalance();

    function createCofeeShop(
        string calldata _shopName,
        uint256 _minSpendingTarget,
        uint8 _rewardPercentage
    ) public validatePercentage(_rewardPercentage) returns (uint256 shopId) {
        shopId++;

        cofeeShops[shopId] = CofeeShop({
            id: shopId,
            shopName: _shopName,
            shopOwner: msg.sender,
            isAuthorized: false
        });

        rewardConditions[shopId] = RewardConditions({
            minimumSpendingTarget: _minSpendingTarget,
            rewardPercentage: _rewardPercentage
        });
    }

    function rewardPoints(
        uint256 _shopId,
        address _customer
    )
        external
        override
        isPartnerCofeeShop(_shopId)
        authorizeReward(_shopId, _customer)
        returns (uint256 points)
    {
        points = _getRewardPoints(_shopId, _customer);
        customerPointsForShop[_shopId][_customer] += points;
        totalSupply += points;
        totalCustomerBBPoints[_customer] += points;
    }

    // Total BBP tokens for a customer
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return totalCustomerBBPoints[_owner];
    }

    // Tranfers BPP tokens for a specific shop
    function transfer(
        address _to,
        uint256 _value,
        uint256 _shopId
    ) public hasBalance(_shopId, msg.sender, _value) returns (bool success) {
        customerPointsForShop[_shopId][msg.sender] -= _value;
        customerPointsForShop[_shopId][_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.

    // The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
    // This can be used for example to allow a contract to transfer tokens on your behalf and/or to
    // charge fees in sub-currencies. The function SHOULD throw unless the _from account has deliberately authorized
    // the sender of the message via some mechanism.

    // function transferFrom(
    //     address _from,
    //     address _to,
    //     uint256 _value,
    //     uint256 _shopId
    // ) public returns (bool success) {
    //  _value = allowance[_shopId][msg.sender][_spender];
    //allowance[_shopId][....][_spender] = 0;
    // allowance[_shopId][....][.....] = _value;

    //     emit Transfer(msg.sender, _to, _value);
    //     return true;
    // }

    // Allows _spender to withdraw from your account for a specific shop, up to the _value amount.
    // Clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender
    function approve(
        address _spender,
        uint256 _shopId,
        uint256 _currentValue,
        uint256 _value
    ) public validAddress(_spender) returns (bool success) {
        if (allowance[_shopId][msg.sender][_spender] == _currentValue) {
            allowance[_shopId][msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _currentValue, _value);
            return true;
        } else {
            return false;
        }
    }

    // function redeemPoints(
    //     uint256 shopId,
    //     uint256 _points
    // ) external override returns (uint256 points) {}

    modifier hasBalance(
        uint256 _shopId,
        address _customer,
        uint256 _value
    ) {
        if (customerPointsForShop[_shopId][_customer] < _value) {
            revert InsufficientBalance();
        }
        _;
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

    modifier validAddress(address _spender) {
        require(_spender != address(0), "!zero address");
        _;
    }
}
