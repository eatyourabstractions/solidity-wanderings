// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract CrowdFund {
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);

    struct Campaign {
        // Creator of campaign
        address creator;
        // Amount of tokens to raise
        uint goal;
        // Total amount pledged
        uint pledged;
        // Timestamp of start of campaign
        uint32 startAt;
        // Timestamp of end of campaign
        uint32 endAt;
        // True if goal was reached and creator has claimed the tokens.
        bool claimed;
    }

    IERC20 public immutable token;
    // Total count of campaigns created.
    // It is also used to generate id for new campaigns.
    uint public count;
    // Mapping from id to Campaign
    mapping(uint => Campaign) public campaigns;
    // Mapping from campaign id => pledger => amount pledged
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        // code
        require(block.timestamp <= _startAt, "cannot retroactively launch");
        require(_startAt <= _endAt, "cannot end before start");
        require(block.timestamp + 90 days >= _endAt);
        
        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            pledged: 0,
            claimed: false,
            startAt: _startAt,
            endAt: _endAt,
            goal: _goal
        });
        
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id) external {
        // code
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator,"cannot cancel: sender is not campaign creator");
        require(block.timestamp <= campaign.startAt, "campaign has already started");
        
        delete campaigns[_id];
        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount) external {
        // code
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "campaign hasn't started yet");
        require(block.timestamp <= campaign.endAt, "ended");
        
        token.transferFrom(msg.sender, address(this), _amount);
        campaign.pledged += _amount;
        
        pledgedAmount[_id][msg.sender] += _amount;
        
        emit Pledge(_id, msg.sender, _amount);
        
    }

    function unpledge(uint _id, uint _amount) external {
        // code
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended");
        
        token.transfer(msg.sender, _amount);
        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        
        emit Unpledge(_id, msg.sender, _amount);
        
    }

    function claim(uint _id) external {
        // code
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator,"cannot claim: sender is not campaign creator");
        require(block.timestamp >= campaign.endAt, "cannot claim: campaign hasn't ended");
        require(campaign.pledged >= campaign.goal, "campaign didn't reach the goal");
        
        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);
        emit Claim(_id);
        
    }

    function refund(uint _id) external {
        // code
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.endAt, "cannot refund: campaign hasn't ended");
        require(campaign.pledged < campaign.goal, "campaign didn't reach the goal");
        
        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);
        emit Refund(_id, msg.sender, bal);
        
    }
}
