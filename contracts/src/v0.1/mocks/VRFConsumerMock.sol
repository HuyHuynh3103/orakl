// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../VRFConsumerBase.sol";
import "../interfaces/VRFCoordinatorInterface.sol";

contract VRFConsumerMock is VRFConsumerBase {
    uint256 public s_randomWord;
    address private s_owner;

    VRFCoordinatorInterface COORDINATOR;

    error OnlyOwner(address notOwner);

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert OnlyOwner(msg.sender);
        }
        _;
    }

    constructor(address coordinator) VRFConsumerBase(coordinator) {
        s_owner = msg.sender;
        COORDINATOR = VRFCoordinatorInterface(coordinator);
    }

    // Receive remaining payment from requestRandomWordsPayment
    receive() external payable {}

    function requestRandomWords(
        bytes32 keyHash,
        uint64 accId,
        uint32 callbackGasLimit,
        uint32 numWords
    ) public onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(keyHash, accId, callbackGasLimit, numWords);
    }

    function requestRandomWordsDirect(
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint32 numWords
    ) public payable onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWordsPayment{value: msg.value}(
            keyHash,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        // requestId should be checked if it matches the expected request
        // Generate random value between 1 and 50.
        s_randomWord = (randomWords[0] % 50) + 1;
    }
}
