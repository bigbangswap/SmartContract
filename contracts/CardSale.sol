// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import './interfaces/ISwapRouter.sol';

contract CardSale is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    struct CardRecord {
        uint256 cardType;
        uint256 timestamp;
        bool isLiquidityAdded;
        bool isUsed;
    }

    address public usdt;
    address public bbg;
    address public router;

    uint256 public totalUsdt;
    uint256 public totalAccount;
    uint256 public totalCardSales;

    address public rewardWallet;
    address public techWallet;
    address public opWallet;
    address public feeWallet;

    uint256[] public cardPriceTier;
    uint256[] public cardSales;
    uint256[] public cardSupply;
    mapping (address => CardRecord) cardHolders;
    
    event BuyCardEvent(address buyer, uint256 cardType, address refer1, address refer2, uint256 timestamp);
    event AddLiquidityEvent(address caller, uint256 cardType, uint256 timestamp);

    function initialize (
        address usdtAddress,
        address bbgAddress,
        address routerAddress,
        address rewardPoolAddress,
        address techWalletAddress,
        address opWalletAddress,
        address feeWalletAddress
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        usdt = usdtAddress;
        bbg = bbgAddress;
        router = routerAddress;
        rewardWallet = rewardPoolAddress;
        techWallet = techWalletAddress;
        opWallet = opWalletAddress;
        feeWallet = feeWalletAddress;

        cardPriceTier = [500e18, 1_500e18, 3_000e18, 5_000e18, 50_000e18, 500_000e18];
        cardSales = [0, 0, 0, 0, 0, 0];
        cardSupply = [3000, 2000, 1500, 200, 88, 20];

        IERC20Upgradeable(usdt).safeApprove(router, type(uint256).max); 
        IERC20Upgradeable(bbg).safeApprove(router, type(uint256).max);
    }

    function BuyCard(uint256 cardType, address refer1, address refer2) external nonReentrant {
        require(cardType >= 0 && cardType < 6, "invalid card type");
        require(cardHolders[msg.sender].isUsed == false, "owns a card already");
        require(cardSupply[cardType] > 0, "insufficient inventory");

        uint256 amount = cardPriceTier[cardType];
        require(IERC20Upgradeable(usdt).allowance(msg.sender, address(this)) >= amount, "insufficient allowance");

        IERC20Upgradeable(usdt).safeTransferFrom(msg.sender, address(this), amount);
        uint256 bonus1 = amount * 45 * 95 / 1000 / 100;
        if (refer1 == address(0))
            bonus1 = 0;
        uint256 bonus2 = amount * 30 * 95 / 1000 / 100;
        if (refer2 == address(0))
            bonus2 = 0;
        if (bonus1 > 0)
            IERC20Upgradeable(usdt).safeTransfer(refer1, bonus1);
        if (bonus2 > 0)
            IERC20Upgradeable(usdt).safeTransfer(refer2, bonus2);

        // reward pool
        uint256 rewardAmount = amount * 225 / 1000;
        IERC20Upgradeable(usdt).safeTransfer(rewardWallet, rewardAmount);

        uint256 techAmount = amount * 100 / 1000;
        IERC20Upgradeable(usdt).safeTransfer(techWallet, techAmount);

        uint256 opAmount = amount * 100 / 1000;
        IERC20Upgradeable(usdt).safeTransfer(opWallet, opAmount);

        uint256 protocolFeeAmount = amount * 75 * 5 / 1000 / 100;
        IERC20Upgradeable(usdt).safeTransfer(feeWallet, protocolFeeAmount);

        cardHolders[msg.sender] = CardRecord(cardType, block.timestamp, false, true);
        cardSupply[cardType]--;
        cardSales[cardType]++;
        totalAccount++;
        totalCardSales++;
        totalUsdt += amount;

        emit BuyCardEvent(msg.sender, cardType, refer1, refer2, block.timestamp);
    }

    function AddLiquidity() external nonReentrant {
        require(cardHolders[msg.sender].isUsed == true, "no card owns");

        require(cardHolders[msg.sender].isLiquidityAdded == false, "liquidity added already");
        cardHolders[msg.sender].isLiquidityAdded = true;

        uint256 cardType = cardHolders[msg.sender].cardType;
        require(cardType >= 0 && cardType < 6, "invalid card type");

        uint256 amount = cardPriceTier[cardType];
        _addLiquidity(amount/2);

        emit AddLiquidityEvent(msg.sender, cardType, block.timestamp);
    }

    function _addLiquidity (uint256 amount) internal {
        ISwapRouter swapRouter = ISwapRouter(router);
        uint stakingTokenAmount = amount / 2;
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = bbg;
        uint balanceBefore = IERC20Upgradeable(bbg).balanceOf(address(this));
        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(stakingTokenAmount, 1, path, address(this), type(uint256).max);
        uint swapedAmount = IERC20Upgradeable(bbg).balanceOf(address(this)) - balanceBefore;

        swapRouter.addLiquidity(usdt, bbg, stakingTokenAmount, swapedAmount, 1, 1, address(this), type(uint256).max);
    }

    function infos() external view returns (
        uint256 _totalUsdt,
        uint256 _totalAccount,
        uint256 _totalCardSales
    ) {
        _totalUsdt = totalUsdt;
        _totalAccount = totalAccount;
        _totalCardSales = totalCardSales;
    }

    function getUserCardInfo (address account) external view returns (
        uint256 _cardType,
        uint256 _timestamp,
        bool _isLiquidityAdded
    ) {
        require(cardHolders[account].isUsed == true, "no record");
        CardRecord memory rec = cardHolders[account];
        _cardType = rec.cardType;
        _timestamp = rec.timestamp;
        _isLiquidityAdded = rec.isLiquidityAdded; 
    }

    function getCardSalesInfo (uint256 cardType) external view returns (
        uint256 _salesNum,
        uint256 _availableNum
    ){
        require(cardType >= 0 && cardType < 6, "invalid card type");
        _salesNum = cardSales[cardType];
        _availableNum = cardSupply[cardType];
    }

    function setUsdtAddress(address addr) external onlyOwner {
        require(addr != address(0), "invalid address");
        usdt = addr;
    }

    function setBbgAddress(address addr) external onlyOwner {
        require(addr != address(0), "invalid address");
        bbg = addr;
    }

    function setRouterAddress(address addr) external onlyOwner {
        require(addr != address(0), "invalid address");
        router = addr;
    }

    function rescueERC20(address token, address recipient, uint256 amount) external onlyOwner {
        require(recipient!= address(0), "invalid address");
        require(amount > 0 && IERC20Upgradeable(token).balanceOf(address(this)) >= amount, "invalid amount");

        IERC20Upgradeable(token).safeTransfer(recipient, amount);
    }

    function fixPlan() external onlyOwner {
        IERC20Upgradeable(usdt).approve(router, type(uint256).max); 
        IERC20Upgradeable(bbg).approve(router, type(uint256).max);
    }
}
