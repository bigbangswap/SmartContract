// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import './interfaces/IWETH.sol';
import './interfaces/ISwapRouter.sol';
import './interfaces/ISwapFactory.sol';

interface IRewardToken {
    function burn(uint amount) external returns(uint256); 
}

contract StakingContract is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    uint256 public RATE_PERCISION;
    uint256 public periodDuration;  // 24h
    uint256 public totalReleased;   // BBG total released 
    uint256 public startTime;

    address public creator;
    address public operator;
    address public techEcoFund;     //10%
    address public marketingFund;   //10%
    address public circulatingPool; 
    address public lpRewardPool; 
    address public factory;
    address public router;
    address public weth;
    address public pair;
    address public stakingToken;    // USDT
    address public rewardToken;     // BBG
    address public feeCollector;    // cold wallet 

    struct ReleaseInfo {
        uint256 lpMining;           // 55%
        uint256 teamFund;           // 30%
        uint256 lsdStaking;         // 3%
        uint256 goldenCard;         // 3%
        uint256 globalPartner;      // 3%
        uint256 foundation;         // 2%
        uint256 techTeam;           // 2%
        uint256 opTeam;             // 2%
    
    }
    mapping(address => bool) public isRewardOperator;
    mapping(address => uint256) public stakedOf;
    mapping(uint256 => uint256) public dayReleased;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardsClaimed;
    mapping(address => uint256) public usdtRewards;
    mapping(address => uint256) public usdtRewardsClaimed;
    mapping(uint256 => ReleaseInfo) public dayReleasedInfo;

    event Staked(address user, uint256 amount, uint256 timestamp);
    event RewardSold(address user, uint256 amount, uint256 receivedUsdtAmount, uint256 backFillUsdAmount, uint256 timestamp);
    event RewardPaid(address user, address token,uint256 reward, uint256 timestamp);
    event RewardSynced(uint256 batchNo, address token, uint256 timestamp);
    event DailyReleaseTrigerred(uint256 amount, uint256 timestamp);

    modifier onlyCreator() {
        require(msg.sender == creator, "caller must be creator");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == creator || msg.sender == operator || isRewardOperator[msg.sender] == true, "caller must be operator or creator");
        _;
    }

    function initialize (
        address operatorAddress,
        address factoryAddress,
        address routerAddress,
        address pairAddress,
        address usdtAddress,
        address bbgAddress,
        address wbnbAddress,
        address _circulatingPool,
        address _lpRewardPool,
        address _techEcoFund,
        address _marketingFund,
        address _feeTo,
        uint256 _startTime
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        creator = msg.sender;
	RATE_PERCISION = 10000;
        periodDuration = 86400;
        startTime = _startTime;
        operator = operatorAddress;
        factory = factoryAddress;
        router = routerAddress;
        pair = pairAddress;
        stakingToken = usdtAddress;
        rewardToken = bbgAddress;
        weth = wbnbAddress;
        circulatingPool = _circulatingPool;
        lpRewardPool = _lpRewardPool;
        techEcoFund = _techEcoFund;
        marketingFund = _marketingFund;
        feeCollector = _feeTo;

	isRewardOperator[operator] = true;

        IERC20Upgradeable(stakingToken).approve(router, type(uint256).max); 
        IERC20Upgradeable(rewardToken).approve(router, type(uint256).max);
        IERC20Upgradeable(pair).approve(router, type(uint256).max);
    }

    /*** internal functions **/

    function _transferFrom(address from,address token,uint amount) internal returns(uint receivedAmount){
        if(token == weth){
            require(msg.value >= amount,"insufficient input value");
            IWETH(weth).deposit{value : msg.value}();
            return msg.value;
        }

        uint beforeBalance = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).transferFrom(from, address(this), amount);
        return IERC20Upgradeable(token).balanceOf(address(this)) - beforeBalance;
    }

    function _transferTo(address token, address to, uint amount) internal {
        if(token == weth){
            IWETH(weth).withdraw(amount);
            _safeTransferETH(to,amount);
        }else{
            IERC20Upgradeable(token).safeTransfer(to,amount);
        }
    }

    function _addLiquidity(uint stakeAmount) internal {
        uint stakingTokenAmount = stakeAmount / 2;
        ISwapRouter swapRouter = ISwapRouter(router);
        address[] memory path = new address[](2);
        path[0] = stakingToken;
        path[1] = rewardToken;
        uint balanceBefore = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(stakingTokenAmount,1,path,address(this),type(uint256).max);
        uint swapedAmount = IERC20Upgradeable(rewardToken).balanceOf(address(this)) - balanceBefore;

        swapRouter.addLiquidity(stakingToken, rewardToken, stakingTokenAmount, swapedAmount, 1, 1, address(this), type(uint256).max);
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    /*** read functions ***/

    function infos() external view returns(
        address _factory,
        address _router,
        address _creator,
        address _pair,
        address _stakingToken,
        address _rewardToken,
        uint256 _periodDuration,
        uint256 _startTime
    ){
        _factory = factory;
        _router = router;
        _creator = creator;
        _pair = pair;
        _stakingToken = stakingToken;
        _rewardToken = rewardToken;
        _periodDuration = periodDuration;
        _startTime = startTime;
    }

    function exists(address account) public view returns (bool) {
        return stakedOf[account] > 0;
    }

    function getDayReleased(uint256 dayTimestamp) external view returns (uint256) {
        return dayReleased[dayTimestamp];
    }

    // BBG rewards
    function userRewards(address account) external view returns (uint256 totalReward, uint256 totalClaimed) {
        totalReward = rewards[account];
        totalClaimed = rewardsClaimed[account];
    }

    // USDT rewards
    function userUSDTRewards(address account) external view returns (uint256 totalReward, uint256 totalClaimed) {
        totalReward = usdtRewards[account];
        totalClaimed = usdtRewardsClaimed[account];
    }

    function availableRewards(address account, address token) external view returns (uint256) {
        if (token == rewardToken)
            return rewards[account] - rewardsClaimed[account];
        else if (token == stakingToken) 
            return usdtRewards[account] - usdtRewardsClaimed[account];
        return 0;
    }

    function isStopped() external view returns (bool) {
        return IERC20Upgradeable(rewardToken).totalSupply() <= 1_000_000e18;
    }

    function getBBGBalance() external view returns (uint256) {
        return IERC20Upgradeable(rewardToken).balanceOf(pair);
    }

    function getUSDTBalance() external view returns (uint256) {
        return IERC20Upgradeable(stakingToken).balanceOf(pair);
    }

    function getBBGPrice() external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = rewardToken;
        path[1] = stakingToken;
        uint256[] memory amounts = ISwapFactory(factory).getAmountsOut(1e18, path);
        return amounts[1];
    }

    // base is 10000
    function releaseRate() external view returns (uint256) {
        if (IERC20Upgradeable(rewardToken).totalSupply() > 1_000_000e18) {
            uint256 month = (block.timestamp - startTime ) / ( periodDuration * 30 );
            return 80 + 10 * month; 
        } else
            return 80;
    }

    function getBBGReleasedVolume() external view returns (uint256) {
        return totalReleased;
    }

    function getSwapUSDTOut(uint256 bbgAmountIn) external view returns (uint256 userReceivedUsdt, uint256 fillBackUsdt, uint256 protocolFeeUsdt, uint256 burnedBBG) {
        uint256 usdtAmount = bbgAmountIn * IERC20Upgradeable(stakingToken).balanceOf(pair) / IERC20Upgradeable(rewardToken).balanceOf(pair); 
        userReceivedUsdt = usdtAmount * 45 * 95 / 10000;
        fillBackUsdt = usdtAmount * 55  / 100;
        protocolFeeUsdt = usdtAmount * 45 * 5 / 10000;
        burnedBBG = bbgAmountIn + bbgAmountIn * 55 / 100;
    }

    /*** write functions ***/

    function stake(uint amount) external whenNotPaused nonReentrant {
        require(amount >= 1e20, "amount can not be less than 100");
        require(block.timestamp >= startTime, "not start");

        uint receivedAmount = _transferFrom(msg.sender, stakingToken, amount);

        uint256 marketingAmount = receivedAmount * 10 / 100;
        uint256 techEcoAmount = receivedAmount * 10 / 100;
        uint256 lpFundAmount = receivedAmount * 50 / 100; 
        _transferTo(stakingToken, marketingFund, marketingAmount);
        _transferTo(stakingToken, techEcoFund, techEcoAmount);
	uint256 bbgBefore = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        _addLiquidity(lpFundAmount);
	uint256 bbgAfter = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        if ( bbgAfter > bbgBefore) {
        	IERC20Upgradeable(rewardToken).safeTransfer(pair, bbgAfter - bbgBefore);
        	ISwapRouter(router).takeToken(pair, rewardToken, 0); // update pair balance and reserve
        }
        
        stakedOf[msg.sender] = stakedOf[msg.sender] + receivedAmount;

        emit Staked(msg.sender, receivedAmount, block.timestamp);
    }

    // sell BBG
    function sellRewardToken(uint amount) external whenNotPaused nonReentrant {
        require(block.timestamp >= startTime,"not start");
        require(exists(msg.sender), "no stake record");

        _transferFrom(msg.sender, rewardToken, amount); 
        require(IERC20Upgradeable(rewardToken).totalSupply() - amount >= 1_000_000e18, "break the limit of 1 million");
        uint256 burned = IRewardToken(rewardToken).burn(amount);

        uint256 liquidity = burned * IERC20Upgradeable(pair).totalSupply() / IERC20Upgradeable(rewardToken).balanceOf(pair); 
        (uint256 bbgAmount, uint256 usdtAmount) = ISwapRouter(router).removeLiquidity(rewardToken, stakingToken, liquidity, 1, 1, address(this), block.timestamp + 60);

        // USDT
        uint256 receivedUsdtAmount = usdtAmount * 45/100;
	uint256 bbgBefore = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        _addLiquidity(usdtAmount - receivedUsdtAmount); // 55% fill back to pool
	uint256 bbgAfter = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        if ( bbgAfter > bbgBefore) {
        	IERC20Upgradeable(rewardToken).safeTransfer(pair, bbgAfter - bbgBefore);
        	ISwapRouter(router).takeToken(pair, rewardToken, 0); // update pair balance and reserve
        }
        _transferTo(stakingToken, msg.sender, receivedUsdtAmount);

        // BBG
        IRewardToken(rewardToken).burn(bbgAmount * 55 / 100);
        _transferTo(rewardToken, circulatingPool, bbgAmount * 35 / 100);
        _transferTo(rewardToken, lpRewardPool, bbgAmount * 10 / 100);

        emit RewardSold(msg.sender, burned, receivedUsdtAmount, usdtAmount - receivedUsdtAmount, block.timestamp);
    }

    function claimRewards(address token) external whenNotPaused nonReentrant {

        uint256 amount = 0;
        if (token == rewardToken) {
            amount = rewards[msg.sender] - rewardsClaimed[msg.sender];
            if (amount > 0) {
                _transferTo(rewardToken, msg.sender, amount * 95 / 100);
                _transferTo(rewardToken, feeCollector, amount * 5 / 100);
                rewardsClaimed[msg.sender] += amount;
            }
        } else {
            amount = usdtRewards[msg.sender] - usdtRewardsClaimed[msg.sender];
            if (amount > 0) {
                _transferTo(stakingToken, msg.sender, amount * 95 / 100);
                _transferTo(stakingToken, feeCollector, amount * 5 / 100);
                usdtRewardsClaimed[msg.sender] += amount;
            }
        }
        require(amount > 0, "reward amount is zero");
        emit RewardPaid(msg.sender, token, amount, block.timestamp);
    }

    function notifyRewards(uint256 batchNo, address token, address[] calldata accounts, uint256[] calldata values) external onlyOperator nonReentrant {
        require(accounts.length == values.length, "not match");

        if (token == rewardToken) {
            for(uint i = 0; i < accounts.length; i++) {
                rewards[accounts[i]] += values[i];
            }
        } else {
            for(uint i = 0; i < accounts.length; i++) {
                usdtRewards[accounts[i]] += values[i];
            }
        }
        
        emit RewardSynced(batchNo, token, block.timestamp);
    }

    function trigerDailyRelease(uint256 timestamp, uint256 amount) external onlyOperator returns (uint256) {
        require(timestamp >= startTime && timestamp <= block.timestamp && timestamp%86400 == 0, "invalid timestamp");
        require(dayReleased[timestamp] == 0, "already released");

        ISwapRouter(router).takeToken(pair, rewardToken, amount);
        totalReleased += amount;
        dayReleased[timestamp] = amount; 
        dayReleasedInfo[timestamp] = ReleaseInfo(amount*55/100, amount*30/100, amount*3/100, amount*3/100, amount*3/100, amount*2/100, amount*2/100, amount*2/100);
        emit DailyReleaseTrigerred(amount, timestamp);
        return amount;
    }

    // admin functions
    
    function setRewardOperator(address account,bool status) external onlyCreator {
        require(account != address(0),"account can not be address 0");
        isRewardOperator[account] = status;
    }

    function takeToken(address token, address to, uint amount) external onlyCreator {
        if(token == address(0)){
            _safeTransferETH(to, amount);
        }else{
            IERC20Upgradeable(token).safeTransfer(to, amount);
        }
    }

    function processRewards(address token, address recipient, uint256 amount) external onlyOperator returns (bool) {
        require(token != address(0) && recipient != address(0), "invalid token or recipient");
        require(amount > 0, "invalid amount");
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
        return true;
    }

    function burnBBG(uint256 amount) external onlyOperator returns (uint256) {
        require(amount > 0, "invalid amount");
        uint256 burned = IRewardToken(rewardToken).burn(amount);
        return burned;
    }

    function setPauseStatus(bool _paused) external onlyCreator {
        if(_paused){
            _pause();
        }else{
            _unpause();
        }
    }

    function transferCreator(address newCreator) external onlyCreator {
        require(newCreator != address(0), "new creator can not be address 0");
        creator = newCreator;
    }
}
