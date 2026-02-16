# DR Agent

[中文版本 (README_ZH.md)](README_ZH.md)

## Why This Builder

> Huawei Digital Energy engineer with 3+ years in photovoltaic systems,
> combining embedded firmware, AI optimization, and smart contract development.

| Domain | Experience |
|--------|-----------|
| Energy | PV inverter firmware (embedded C) · PVEMS AI algorithm optimization |
| AI | LSTM load forecasting · MILP dispatch optimization |
| Blockchain | Solidity · Chainlink Oracle · Hardhat |
| Education | Zhejiang University B.S. |

---

## Full Commercial Document

# DR Agent — Demand Response Automated Settlement (Commercial Version)

---

## 1. Problem We Solve

Demand Response (DR) has two persistent real-world pain points:

1. Fulfillment is hard to verify

- After an event is issued, whether participants actually reduced load (and by how much) is often based on centralized reports.
- Different parties (aggregators, participants, grid operators) frequently disagree on data and outcomes.

2. Settlement is slow and manual

- Reward distribution often spans multiple systems after the event ends.
- The process is inefficient, expensive to audit, and creates trust friction for smaller participants.

## 2. Product Definition

**DR Agent** is an Avalanche-based automated settlement layer for demand response:

- Event publishing: operator/aggregator defines event time window, target reduction, and settlement rules.
- Proof submission: participants submit verifiable load-reduction proofs.
- Automated settlement: smart contracts compute rewards/penalties.
- Auditability: full lifecycle is replayable and verifiable.

One sentence:
**DR Agent upgrades DR from "human-operated workflow" to "verifiable execution + automated settlement."**

## 3. Why Now

- Grid flexibility demand is increasing.
- AI can improve event-time dispatch decisions, but a trusted shared settlement layer is missing.
- Avalanche’s app-chain and interoperability capabilities are well suited to multi-party, rule-based, auditable energy settlement.

## 4. Why Avalanche (not generic chain positioning)

1. Low latency and deterministic settlement for event-driven workflows.
2. Customizable L1/Subnet path for energy-specific rule encoding.
3. Interchain interoperability for splitting data, asset, and settlement domains when needed.

## 5. Target Customers and Value

### Initial customers (3-6 months after hackathon)

- Aggregators / energy service providers managing C&I portfolios.
- Industrial parks requiring peak-shaving and incentive settlement.

### Direct value

- Settlement cycle shortened from days/weeks to minutes/hours.
- Lower dispute cost (event, proof, and payout logic anchored and auditable).
- Higher trust and operational reusability among participants.

## 6. Business Model (MVP Stage)

1. Per-event settlement fee

- Charge by number of participating sites or settlement volume.

2. API/SaaS subscription

- Event management, fulfillment audit, and automated reporting for aggregators.

3. Enterprise deployment

- Private deployment + annual maintenance (later stage).

## 7. Competition and Differentiation

### Competitive landscape

- Traditional DR platforms: mature operations but mainly centralized workflows and higher audit friction.
- Generic energy data platforms: monitoring capabilities exist, but settlement closure is weak.

### Our differentiation

1. **Settlement automation**: not just another dashboard.
2. **Verifiable fulfillment**: disputes can be replayed on-chain.
3. **Programmable rule templates**: configurable for different regional DR programs.

## 8. Hackathon Evaluation Mapping (Avalanche Lens)

1. Builder Drive

- Targets a real operational pain point, not a concept-only agent.

2. Execution

- Demo shows full loop: event issuance -> response proof -> automated settlement -> audit visualization.

3. Crypto Culture

- On-chain state machine is core to trust and settlement, not decorative storage.

4. Long-term Intent

- Start with one region/aggregator, then scale to cross-region rule network.

## 9. 5-Minute Demo Design

1. Publish one DR event (target: 300kW reduction, duration: 60 minutes).
2. Two sites submit fulfillment proofs.
3. Contract computes completion and payouts automatically.
4. Dashboard shows settlement records and audit logs.
5. Compare against manual settlement lead time.

## 10. Risks and Mitigations

1. Compliance and responsibility boundaries

- Position as settlement and audit infrastructure; no delegated dispatch promises.

2. Data authenticity

- Data signatures, device identity, anomaly checks, and dispute process.

3. Regional rule variance

- Template-based rule engine; start with one jurisdiction MVP.

## 11. Suggested Milestones

- Week 1: event model + settlement contracts + basic UI
- Week 2: proof pipeline and automated scoring
- Week 3: end-to-end stress testing and demo hardening

Conclusion:
**DR Agent is an executable, auditable, and commercializable Avalanche-native energy application fit for hackathon visibility and startup extension.**

---

## Full Technical Document

# DR Agent — Technical Development Manual

## 1. Development Goal

Deliver a demo-ready MVP in 3 weeks:

- Event Creation
- Proof Submission
- Automated Settlement
- Audit Query

Core principles:

- Close the end-to-end loop first, then optimize complexity.
- Keep critical states on-chain; keep high-frequency raw telemetry off-chain with hash anchoring.

## 2. System Architecture

### 2.1 Layered Architecture (Detailed)

```mermaid
flowchart TB
    subgraph U["User and Operations Layer"]
        OP["Operator Console\n(Create/Close Events)"]
        DB["Dashboard\n(Status/Settlement/Audit)"]
    end

    subgraph S["Service Layer (FastAPI + Python)"]
        API["API Gateway\n/events /proofs /settle"]
        C["collector.py\nData collection/simulation"]
        B["baseline.py\nBaseline computation"]
        P["proof_builder.py\nPayload + hash builder"]
        SUB["submitter.py\nOn-chain tx submitter"]
        SC["scorer.py\nSettlement trigger after event"]
    end

    subgraph O["Off-chain Data Layer"]
        RAW["Object Storage/IPFS\nRaw telemetry data"]
        IDX["Postgres/SQLite\nEvent/site index (optional)"]
    end

    subgraph A["Avalanche C-Chain (MVP)"]
        EM["EventManager.sol\nEvent lifecycle"]
        PR["ProofRegistry.sol\nProof summary + hash anchoring"]
        ST["Settlement.sol\nReward/penalty and claim"]
    end

    OP --> API
    DB --> API
    API --> C --> B --> P
    P --> RAW
    P --> IDX
    P --> SUB --> PR
    API --> SUB --> EM
    API --> SC --> ST
    ST --> DB
    EM --> DB
    PR --> DB
```

### 2.2 Data Boundary (On-chain vs Off-chain)

1. `On-chain`: event parameters, proof summary, proof hash, settlement result, claim status.
2. `Off-chain`: high-frequency raw load curves, device logs, recomputable payload.
3. `Consistency anchor`: `proofHash = keccak256(rawPayload)` for audit-time recomputation.

### 2.3 Event-to-Settlement Sequence

```mermaid
sequenceDiagram
    participant O as Operator
    participant API as FastAPI
    participant EM as EventManager
    participant AG as Site Agent
    participant PR as ProofRegistry
    participant ST as Settlement
    participant D as Dashboard

    O->>API: POST /events (start,end,target,reward,penalty)
    API->>EM: createEvent(...)
    EM-->>D: EventCreated

    loop Event Active Window
        AG->>API: POST /proofs (baseline,actual,payload)
        API->>API: build proofHash
        API->>PR: submitProof(eventId,siteId,summary,proofHash)
        PR-->>D: ProofSubmitted
    end

    O->>API: POST /settle/{event_id}
    API->>ST: settleEvent(eventId)
    ST-->>D: Settled(payouts)

    AG->>ST: claimReward(eventId,siteId)
    ST-->>AG: payout / penalty result
```

## 3. Contract Design (MVP)

### 3.1 EventManager.sol

Functions:

- createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate)
- closeEvent(eventId)
- getEvent(eventId)

States:

- Pending / Active / Closed / Settled

### 3.2 ProofRegistry.sol

Functions:

- submitProof(eventId, siteId, baselineKwh, actualKwh, proofHash)
- getSiteProof(eventId, siteId)

Notes:

- Store summary + hash on-chain; keep full curve off-chain (IPFS/object storage).
- proofHash = keccak256(rawPayload)

### 3.3 Settlement.sol

Functions:

- settleEvent(eventId)
- claimReward(eventId, siteId)

Simplified MVP formula:

- reduction = baselineKwh - actualKwh
- completion = reduction / targetShare
- if completion >= 1: reward = targetShare \* rewardRate
- else: reward = reduction _ rewardRate - (targetShare - reduction) _ penaltyRate

## 4. Data Models

### Event

- eventId: bytes32
- startTime/endTime: uint64
- targetKw: uint256
- rewardRate: uint256
- penaltyRate: uint256
- status: uint8

### SiteProof

- siteId: bytes32
- baselineKwh: uint256
- actualKwh: uint256
- reductionKwh: uint256
- proofHash: bytes32
- submittedAt: uint64

### SettlementRecord

- eventId: bytes32
- siteId: bytes32
- payout: int256
- settledAt: uint64

## 5. Off-chain Services (Python)

Modules:

1. `collector.py`: collect/simulate load data
2. `baseline.py`: baseline generation (7-day same-hour average for MVP)
3. `proof_builder.py`: payload + hash builder
4. `submitter.py`: submit proof to contracts
5. `scorer.py`: settlement trigger at event end

## 6. API (FastAPI)

- `POST /events` create event
- `POST /proofs` submit site proof
- `POST /settle/{event_id}` trigger settlement
- `GET /events/{event_id}` query event state
- `GET /events/{event_id}/records` query settlement details

## 7. Frontend (Minimum Pages)

1. Event list page

- status, target, time window, participating site count

2. Event detail page

- site completion, payout result, proofHash

3. Audit page

- input eventId/siteId to compare on-chain record with off-chain payload hash

## 8. 6-Week Development Plan

### Week 1

- Build 3 core contracts + unit tests

### Week 2

- Run local flow: createEvent -> submitProof -> settle
- Contract integration tests

### Week 3

- Wrap chain interactions with FastAPI

### Week 4

- Integrate frontend query/trigger actions
- Simulate 2-3 site datasets

### Week 5

- Add exception scenarios (late proof, missing data, under-performance)

### Week 6

- End-to-end stress test
- Harden demo script and recording flow

## 9. Test Checklist

### Contract tests

1. happy path: create, submit, settle, claim
2. duplicate proof prevention
3. invalid time window rejection
4. cannot settle before closure
5. no double settlement

### Integration tests

1. continuous reporting during event window
2. automatic settlement after event end
3. UI state consistent with on-chain state

### Demo tests

1. full walkthrough within 5 minutes
2. random proofHash recomputation checks
3. explainable failure behavior

## 10. Security and Scope Boundaries

1. Access control

- only operator can create/close events
- only registered sites can submit proof

2. Data integrity

- signed payload + on-chain hash anchoring
- keep auditable raw data window

3. Out of MVP scope

- no direct control of real grid dispatch
- no advanced multi-market rule engine
- no cross-jurisdiction compliance engine
