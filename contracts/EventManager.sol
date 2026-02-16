// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EventManager {
    enum Status { Pending, Active, Closed, Settled }

    struct Event {
        bytes32 eventId;
        uint64 startTime;
        uint64 endTime;
        uint256 targetKw;
        uint256 rewardRate;
        uint256 penaltyRate;
        Status status;
        address creator;
    }

    address public operator;
    mapping(bytes32 => Event) private events;

    event EventCreated(bytes32 indexed eventId, uint64 startTime, uint64 endTime, uint256 targetKw);
    event EventClosed(bytes32 indexed eventId);
    event EventSettled(bytes32 indexed eventId);

    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    constructor(address _operator) {
        require(_operator != address(0), "Zero address");
        operator = _operator;
    }

    function createEvent(
        bytes32 eventId,
        uint64 start,
        uint64 end,
        uint256 targetKw,
        uint256 rewardRate,
        uint256 penaltyRate
    ) external onlyOperator {
        require(events[eventId].creator == address(0), "Event already exists");
        require(start < end, "Invalid time window");

        events[eventId] = Event({
            eventId: eventId,
            startTime: start,
            endTime: end,
            targetKw: targetKw,
            rewardRate: rewardRate,
            penaltyRate: penaltyRate,
            status: Status.Active,
            creator: msg.sender
        });

        emit EventCreated(eventId, start, end, targetKw);
    }

    function closeEvent(bytes32 eventId) external onlyOperator {
        require(events[eventId].creator != address(0), "Event not found");
        require(events[eventId].status == Status.Active, "Not active");

        events[eventId].status = Status.Closed;
        emit EventClosed(eventId);
    }

    function getEventInfo(bytes32 eventId) external view returns (Event memory) {
        require(events[eventId].creator != address(0), "Event not found");
        return events[eventId];
    }

    function setEventSettled(bytes32 eventId) external {
        require(events[eventId].creator != address(0), "Event not found");
        require(
            events[eventId].status == Status.Closed,
            "Must be closed first"
        );

        events[eventId].status = Status.Settled;
        emit EventSettled(eventId);
    }
}
