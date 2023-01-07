// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        address newCampaign = address(new Campaign(minimum, msg.sender));
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {

    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        uint approvalsId;
    }


    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    uint approvalsIdGlob = 0;
    mapping(address => bool) public approvers;
    mapping(uint => mapping(address => bool)) requestApprovals;
    uint public approversCount = 0;

    modifier restricted() {
        require(msg.sender == manager, "Only the manager may access this functionality");
        _;
    } 

    constructor(uint minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value >= minimumContribution, string.concat("Need to contribute at least ", Strings.toString(minimumContribution), " wei"));

        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory description, 
        uint value, 
        address recipient
    ) public restricted {  
        // value may not exceed the balance of the contract
        require(address(this).balance >= value, "Not enough funds to complete the request.");

        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0,
            approvalsId: approvalsIdGlob
        });
        // keep track of the index of the approvals
        approvalsIdGlob++;
        requests.push(newRequest);
    }

    function approveRequest(uint requestIndex, bool vote) public {
        Request storage activeRequest = requests[requestIndex]; 
        mapping(address => bool) storage activeRequestApprovals = requestApprovals[activeRequest.approvalsId]; 

        require(approvers[msg.sender], "Need to be a contributer to be able to vote.");
        require(!activeRequestApprovals[msg.sender], "You have already voted on this request.");

        // record the vote
        activeRequestApprovals[msg.sender] = true;

        // if the vote is true append to the count otherwise do nothing
        if (vote) {
            activeRequest.approvalCount += 1;
        }
    }

    function finalizeRequest(uint requestIndex) public restricted {
        Request storage activeRequest = requests[requestIndex];
        // mapping(address => bool) storage activeRequestApprovals = requestApprovals[activeRequest.approvalsId]; 

        require(!activeRequest.complete, "Request has already been finalized.");
        require(activeRequest.approvalCount > (approversCount / 2), "Not enough votes to finalize the request.");

        // send the money to the recipient
        payable(activeRequest.recipient).transfer(activeRequest.value);

        // mark the request as complete
        activeRequest.complete = true;
    }

}