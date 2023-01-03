// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Campaign {

    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
    }

    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    address[] public approvers;

    modifier restricted() {
        require(msg.sender == manager, "Only the manager may access this functionality");
        _;
    } 

    constructor(uint minimum) {
        manager = msg.sender;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value >= minimumContribution, string.concat("Need to contribute at least ", Strings.toString(minimumContribution), " wei"));

        approvers.push(msg.sender);
    }

    function createRequest(
        string memory description, 
        uint value, 
        address recipient
    ) public restricted {
        Request newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false
        });
    }

}