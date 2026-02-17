// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEventManagerView {
    enum Status {
        Pending,
        Active,
        Closed,
        Settled
    }

    struct EventData {
        bytes32 eventId;
        uint64 startTime;
        uint64 endTime;
        uint256 targetKw;
        uint256 rewardRate;
        uint256 penaltyRate;
        Status status;
        address creator;
    }

    function getEventInfo(bytes32 eventId) external view returns (EventData memory);
}

contract ProofRegistry {
    struct SiteProof {
        bytes32 siteId;
        uint256 baselineKwh;
        uint256 actualKwh;
        uint256 reductionKwh;
        bytes32 proofHash;
        string uri;
        uint64 submittedAt;
        address submitter;
    }

    IEventManagerView public eventManager;

    mapping(bytes32 => mapping(bytes32 => SiteProof)) private proofs;
    mapping(bytes32 => mapping(bytes32 => bool)) private submitted;

    event ProofSubmitted(
        bytes32 indexed eventId,
        bytes32 indexed siteId,
        bytes32 proofHash,
        uint256 reductionKwh,
        address indexed submitter
    );

    constructor(address eventManagerAddress) {
        require(eventManagerAddress != address(0), "Zero address");
        eventManager = IEventManagerView(eventManagerAddress);
    }

    function submitProof(
        bytes32 eventId,
        bytes32 siteId,
        uint256 baselineKwh,
        uint256 actualKwh,
        bytes32 proofHash,
        string calldata uri
    ) external {
        require(!submitted[eventId][siteId], "Proof already submitted");

        IEventManagerView.EventData memory eventData = eventManager.getEventInfo(
            eventId
        );
        require(
            eventData.status == IEventManagerView.Status.Active,
            "Event not active"
        );

        uint256 reductionKwh = baselineKwh > actualKwh
            ? baselineKwh - actualKwh
            : 0;

        proofs[eventId][siteId] = SiteProof({
            siteId: siteId,
            baselineKwh: baselineKwh,
            actualKwh: actualKwh,
            reductionKwh: reductionKwh,
            proofHash: proofHash,
            uri: uri,
            submittedAt: uint64(block.timestamp),
            submitter: msg.sender
        });

        submitted[eventId][siteId] = true;

        emit ProofSubmitted(
            eventId,
            siteId,
            proofHash,
            reductionKwh,
            msg.sender
        );
    }

    function getSiteProof(bytes32 eventId, bytes32 siteId)
        external
        view
        returns (SiteProof memory)
    {
        require(submitted[eventId][siteId], "Proof not found");
        return proofs[eventId][siteId];
    }

    function isSubmitted(bytes32 eventId, bytes32 siteId)
        external
        view
        returns (bool)
    {
        return submitted[eventId][siteId];
    }
}
