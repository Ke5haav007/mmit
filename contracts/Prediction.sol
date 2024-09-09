// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/Immit.sol";

contract SimplePredictionMarket is 
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable {

    using SafeERC20 for IERC20;
    IERC20 public token; 
    uint256 public rewardMultiplier; // Reward multiplier, default is 1.5x
    uint256 public questionTimeLimit; // The time limit for the question, e.g., 30 minutes or 24 hours

    // Track user rewards
    mapping(address => uint256) public userRewards;

    // Blacklist for restricting addresses
    mapping(address => bool) public blacklist;

    // Question Data
    struct Question {
        uint256 upperLimit;
        uint256 lowerLimit;
        uint256 questionStartTime;
        uint256 settlementTime;
        bool settled;
        bool upperLimitWon;
    }

    Question public currentQuestion;

    // Track deposits and predictions for the current question
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public userPredictions; // true = higher, false = lower
    mapping(address => address) public referrer; 
    mapping(address => uint256) public referrerClaimAmount;
    mapping(address=> uint256) public referrerClaimedAmount;
    address[] public activeParticipants;

    // Events
    event QuestionCreated(uint256 upperLimit, uint256 lowerLimit);
    event UserAnswered(address user, uint256 amount, bool prediction);
    event QuestionSettled(bool upperLimitWon);
    event RewardClaimed(address user, uint256 amount);
    event RewardMultiplierUpdated(uint256 newMultiplier, uint256 newTimeLimit);
    event BlacklistUpdated(address user, bool blacklisted);
    event TokensWithdrawn(uint256 amount);

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Address is blacklisted");
        _;
    }

    modifier withinQuestionTime() {
        require(block.timestamp < currentQuestion.settlementTime, "Question period is over");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(){
        _disableInitializers();
    }

    function initialize(IERC20 _mmitToken) external initializer {
        token = _mmitToken; // Set the ERC-20 token address when deploying the contract
        rewardMultiplier = 15; // Default reward multiplier is 1.5x (stored as 15 to handle decimals easily)
        questionTimeLimit = 30 minutes; // Default question time limit is 30 minutes

        __ReentrancyGuard_init();
      __Ownable_init(msg.sender);
      __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Update reward multiplier and question time limit (only owner)
    function updateRewardMultiplier(uint256 newMultiplier, uint256 newTimeLimit) external onlyOwner {
        require(newMultiplier >= 5 && newMultiplier <= 20, "Multiplier must be between 0.5x and 2x");
        rewardMultiplier = newMultiplier;
        questionTimeLimit = newTimeLimit;
        emit RewardMultiplierUpdated(newMultiplier, newTimeLimit);
    }

    // Create a new question (called by the owner)
    function createQuestion(uint256 _upperLimit, uint256 _lowerLimit) external onlyOwner {
        require(currentQuestion.settled || currentQuestion.settlementTime < block.timestamp, "Previous question not settled yet");

        // Create a new question and clear participants for this question
        currentQuestion = Question({
            upperLimit: _upperLimit,
            lowerLimit: _lowerLimit,
            questionStartTime: block.timestamp,
            settlementTime: block.timestamp + questionTimeLimit,
            settled: false,
            upperLimitWon: false // default value
        });

        // Clear active participants list
        delete activeParticipants;
        emit QuestionCreated(_upperLimit, _lowerLimit);
    }

    // User deposits and makes a prediction
    function depositAndAnswer(bool _prediction, uint256 _amount, address _referrer) external notBlacklisted withinQuestionTime nonReentrant {
        require(_amount > 0, "Deposit must be greater than zero");
         require(_referrer != msg.sender,"referrer can't be the referee");

          bool alreadyActive = false;
        for (uint256 i = 0; i < activeParticipants.length; i++) {
            if (activeParticipants[i] == msg.sender) {
                alreadyActive = true;
                break;
            }
        }
        // Transfer tokens from the user to the contract
        if(referrer[msg.sender]== address(0) && _referrer != address(0) && !alreadyActive){
          referrer[msg.sender] = _referrer;
          referrerClaimAmount[_referrer] += (_amount * 10)/100;
        }else{
           referrerClaimAmount[referrer[msg.sender]] += (_amount * 10)/100; 
        }
        token.transferFrom(msg.sender, address(this), _amount);

        // Overwrite user's deposit and prediction
        userDeposits[msg.sender] = _amount;
        userPredictions[msg.sender] = _prediction;

        // Check if the user is already an active participant
       

        // Add to active participants if not already present
        if (!alreadyActive) {
            activeParticipants.push(msg.sender);
        }

        emit UserAnswered(msg.sender, _amount, _prediction);
        
    }

    // Settlement of the question (called by the owner)
    function settleQuestion(bool _upperLimitWon) external onlyOwner {
        require(!currentQuestion.settled, "Question already settled");

        currentQuestion.settled = true;
        currentQuestion.upperLimitWon = _upperLimitWon;
        emit QuestionSettled(_upperLimitWon);

        // Distribute rewards based on the outcome
        distributeRewards();
    }

    // Distribute rewards to the correct users
    function distributeRewards() internal {
        for (uint256 i = 0; i < activeParticipants.length; i++) {
            address user = activeParticipants[i];
            if (userDeposits[user] > 0) {
                bool userPrediction = userPredictions[user];
                bool correctPrediction = (userPrediction && currentQuestion.upperLimitWon) || (!userPrediction && !currentQuestion.upperLimitWon);
                
                if (correctPrediction) {
                    uint256 reward = (userDeposits[user] * rewardMultiplier) / 10; // Multiply by rewardMultiplier and divide by 10 to get the correct reward
                    userRewards[user] += reward;
                }
                // No need to reset deposit and predictions, they are irrelevant after settlement
            }
        }
    }

    // Claim accumulated rewards at any time
    function claimRewards() external notBlacklisted nonReentrant{
        uint256 reward = userRewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        uint256 adminAmount = (reward * 5)/100;
        uint256 userreward = reward - adminAmount;

        userRewards[msg.sender] = 0; // Reset the rewards

        token.transfer(msg.sender, userreward); // Transfer the token rewards to the user
        token.transfer(owner(),adminAmount);
        emit RewardClaimed(msg.sender, reward);
    }

    // Manage the blacklist (only owner)
    function manageBlacklist(address _user, bool _isBlacklisted) external onlyOwner {
        blacklist[_user] = _isBlacklisted;
        emit BlacklistUpdated(_user, _isBlacklisted);
    }

    // Withdraw all tokens from the contract (only owner)
    function withdrawAllTokens() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        token.safeTransfer(msg.sender, balance);
        emit TokensWithdrawn(balance);
    }


    function referralClaim() external nonReentrant{
        uint256 claimableAmount = referrerClaimAmount[msg.sender];
        uint256 adminAmount = (claimableAmount * 5)/100;
        if(claimableAmount>0 && claimableAmount<= token.balanceOf(address(this))){
            referrerClaimAmount[msg.sender] = 0;
            referrerClaimedAmount[msg.sender] +=(claimableAmount-adminAmount);
            token.safeTransfer(msg.sender, claimableAmount - adminAmount);
            token.safeTransfer(owner(),adminAmount);
        }
    }

    // Fetch user details for the current question, check if user is an active participant
    function getUserDetails(address _user) external view returns (bool isActiveParticipant, uint256 deposit, bool prediction) {
        isActiveParticipant = false;
        for (uint256 i = 0; i < activeParticipants.length; i++) {
            if (activeParticipants[i] == _user) {
                isActiveParticipant = true;
                break;
            }
        }

        if (isActiveParticipant) {
            deposit = userDeposits[_user];
            prediction = userPredictions[_user];
        } else {
            deposit = 0;
            prediction = false;
        }
    }
}
