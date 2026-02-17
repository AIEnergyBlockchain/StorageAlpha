# Judge Readability Rubric

## Goal

Help judges understand value, implementation, and delivery proof within minutes.

## Scoring Model

- status mapping: `pass=1.0`, `partial=0.5`, `missing=0.0`
- judge score = average of all judge findings * 100
- default audience weight in final score: judge 50

## Checks

| ID | Severity | What to verify | Pass condition |
| --- | --- | --- | --- |
| `J-README-HOOK-001` | P1 | One-line hook | README contains a clear product-value hook |
| `J-DEMO-VIDEO-001` | P1 | Demo evidence | demo video link or explicit walkthrough asset exists |
| `J-LIVE-DEMO-001` | P1 | Live proof | live demo URL or direct fallback is documented |
| `J-ARCH-001` | P1 | Architecture clarity | architecture diagram or Mermaid flow exists |
| `J-PITCH-001` | P2 | Story package | pitch deck outline/file exists |
| `J-ONCHAIN-001` | P1 | Chain evidence | testnet network + verified contract address evidence exists |
| `J-CHALLENGE-001` | P2 | Engineering depth | technical challenges and solutions are documented |
| `J-BOUNTY-001` | P2 | Sponsor alignment | sponsor/bounty integration statement exists |

## Severity Notes

- Missing chain evidence (`J-ONCHAIN-001`) is `P1` by default.
- `P1` findings are considered blocking for hackathon submission quality.
