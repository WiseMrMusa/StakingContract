// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeSystem is ERC20 {
    constructor() ERC20("Staking Reward Token","SRT"){}

    struct StakeDetail {
        uint256 stakeAmount;
        uint256 accruedReward;
        uint256 lastTime;
    }

    mapping(address => bool) internal tokenExist_;
    address[] internal stakeHolders;

    mapping(address => bool) internal userExist_;
    address[] internal stakeTokens;

    // tokenContract => tokenStakers
    mapping(address => address[]) public tokenStakers;

    // tokenContract => tokenStaker => tokenStakeRecord
    mapping(address => mapping(address => StakeDetail)) public tokenStakeRecord;

    function StakeToken(address _tokenContractAddress, uint256 _amount) public {
        if(!tokenExist_[_tokenContractAddress]){
            _addTokenToRecord(_tokenContractAddress);
        }
        if(!userExist_[msg.sender]){
            _addUserToRecord(msg.sender);
        }
        StakeDetail storage MyStakeDetail = tokenStakeRecord[_tokenContractAddress][msg.sender];
        if(MyStakeDetail.lastTime == 0){
            _addUserToTokenRecord(_tokenContractAddress,msg.sender);
        }
        require(IERC20(_tokenContractAddress).transferFrom(msg.sender,address(this),_amount),"TransferFrom Failed");
        MyStakeDetail.stakeAmount += _amount;
        MyStakeDetail.lastTime = block.timestamp;
    }

    function ClaimReward(address _tokenContractAddress, uint256 _rewardAmount) public {
        StakeDetail storage MyStakeDetail = tokenStakeRecord[_tokenContractAddress][msg.sender];
        uint256 newReward = CalculateReward(MyStakeDetail.stakeAmount,MyStakeDetail.lastTime);
        MyStakeDetail.accruedReward += newReward;
        MyStakeDetail.lastTime = block.timestamp;
        require(_rewardAmount <= MyStakeDetail.accruedReward, "You don't have enough claimable reward");
        _mint(msg.sender, _rewardAmount);
        MyStakeDetail.accruedReward -= _rewardAmount;
    }

    function WithdrawStake(address _tokenContractAddress, uint256 _amountToWithdraw) public {
        StakeDetail storage MyStakeDetail = tokenStakeRecord[_tokenContractAddress][msg.sender];
        require(MyStakeDetail.stakeAmount >= _amountToWithdraw, "Insufficient Fund");
        MyStakeDetail.accruedReward += CalculateReward(MyStakeDetail.stakeAmount, MyStakeDetail.lastTime);
        MyStakeDetail.lastTime = block.timestamp;
        IERC20(_tokenContractAddress).transfer(msg.sender,_amountToWithdraw);
    }

    function checkRewardValue(address _tokenContractAddress, address _stakeHolder) public view returns (uint256) {
        StakeDetail memory MyStakeDetail = tokenStakeRecord[_tokenContractAddress][_stakeHolder];
        return MyStakeDetail.accruedReward + CalculateReward(MyStakeDetail.stakeAmount, MyStakeDetail.lastTime);
    }



    function CalculateReward(uint256 _stakeAmount, uint256 _lastTime) internal view returns (uint256){
        uint256 period = block.timestamp - _lastTime;
        return (_stakeAmount * period) / 72000;
    }


    function _addTokenToRecord(address _tokenContractAddress) internal {
        tokenExist_[_tokenContractAddress] = true;
        stakeTokens.push(_tokenContractAddress);
    }
    function _addUserToRecord(address _userAddress) internal {
        userExist_[_userAddress] = true;
        stakeHolders.push(_userAddress);
    }

    function _addUserToTokenRecord(address _tokenContractAddress, address _userAddress) internal {
        tokenStakers[_tokenContractAddress].push(_userAddress);
    }


}