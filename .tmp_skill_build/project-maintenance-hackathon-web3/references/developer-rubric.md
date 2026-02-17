# Developer Maintenance Rubric

## Goal

Reduce onboarding time and cognitive load for new contributors.

## Scoring Model

- status mapping: `pass=1.0`, `partial=0.5`, `missing=0.0`
- developer score = average of all developer findings * 100
- default audience weight in final score: developer 50

## Checks

| ID | Severity | What to verify | Pass condition |
| --- | --- | --- | --- |
| `D-ENTRY-001` | P0 | Actionable entry docs | README has clear quick-start commands |
| `D-ENV-001` | P1 | Environment template | `.env.example` exists with key descriptions |
| `D-STRUCT-001` | P2 | Structure map | README includes a project structure section |
| `D-AUTO-001` | P1 | Task automation | `Makefile` or `Justfile` exists (or script catalog is clear) |
| `D-LOCK-001` | P1 | Dependency consistency | lock files present and dependency pins are sane |
| `D-TEST-001` | P1 | Test discoverability | test directories and runnable test commands exist |
| `D-ADR-001` | P2 | Decision history | ADR documentation exists |
| `D-TROUBLE-001` | P2 | Failure recovery | troubleshooting/FAQ doc exists |
| `D-GLOSSARY-001` | P2 | Domain consistency | glossary exists for domain terms |
| `D-CI-001` | P1 | Maintenance guardrails | CI workflow exists for maintenance baseline checks |

## Severity Notes

- `P0` must block release readiness.
- `P1` is high priority and should be fixed before submission freeze.
- `P2` can be batched as polish work.
