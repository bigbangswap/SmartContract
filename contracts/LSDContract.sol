// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract LSDContract is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable{

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    struct UserInfo {
        uint256 totalStaked;
        uint256 updateTime;
        bool isUsed;
    }

    address public bbg;
    uint256 public minStakeAmount;
    uint256 public maxStakeAmount;

    uint256 public totalStaked;
    uint256 public totalUnstaked;

    mapping(address => UserInfo) public userInfo;

    event Staked( address user, uint256 amount, uint256 timestamp);
    event Unstaked(address user, uint256 amount, uint256 leftAmount);

    function initialize (
        address bbgAddress
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        bbg = bbgAddress;
        minStakeAmount = 200 * 1e18;
        maxStakeAmount = 99999999 * 1e18;
    }

    // owner 
    function _setStakeMinAmount(uint256 amount) external onlyOwner {
        minStakeAmount = amount;
    }

    // owner 
    function _setStakeMaxAmount(uint256 amount) external onlyOwner {
        maxStakeAmount = amount;
    }

    // staked user 
    function staked(address user) external view returns (uint256) {
        if (userInfo[user].isUsed)
            return userInfo[user].totalStaked;
        return 0;
    }

    // stake BBG
    function stake(uint256 amount) external nonReentrant {
        require(amount >= minStakeAmount && amount <= maxStakeAmount, "exceeds stake amount");

        UserInfo memory oldInfo = userInfo[msg.sender];
        uint256 oldStakedAmount = 0;
        if(oldInfo.isUsed)
        {
            oldStakedAmount = oldInfo.totalStaked;
        }
        IERC20Upgradeable(bbg).transferFrom(msg.sender, address(this), amount);

        UserInfo memory newInfo = UserInfo(
            oldStakedAmount + amount,
            block.timestamp,
            true
        );
        userInfo[msg.sender] = newInfo;
        totalStaked += amount;

        emit Staked(msg.sender, amount, block.timestamp);
    }

    // unstake BBG
    function unstake(uint256 amount) external nonReentrant{
        UserInfo storage info = userInfo[msg.sender];
        require(info.isUsed == true, "no stake record");
        require(amount > 0 && info.totalStaked >= amount, "not enough to withdraw");

        info.totalStaked -= amount;
        info.updateTime = block.timestamp;

        totalStaked -= amount;
        totalUnstaked += amount;
        IERC20Upgradeable(bbg).transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount, info.totalStaked);
    }
}
