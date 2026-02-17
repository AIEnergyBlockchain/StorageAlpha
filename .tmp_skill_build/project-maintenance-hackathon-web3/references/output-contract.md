# Output Contract

## Required Section Order

1. `Request Snapshot`
2. `Evidence Inventory`
3. `Developer Maintenance Scorecard`
4. `Judge Readability Scorecard`
5. `P0/P1/P2 Findings`
6. `Minimal Repair Plan (No Edit Yet)`
7. `Approval Checkpoint`
8. `Post-Fix Verification`

## Required Contents

- repo path, timestamp, language mode, and score weights
- developer score, judge score, overall weighted score
- blocking findings list (`P0`/`P1` non-pass)
- explicit dry-run and apply commands
- post-fix verification command block

## Language Policy

- default audience can be `zh`, `en`, or `bilingual`
- in `bilingual` mode, judge-facing summaries must include Chinese and English lines
