---
name: project-maintenance-hackathon-web3
description: Audits and minimally repairs maintenance gaps in hackathon Web3 repositories using weighted developer and judge scorecards. Use when users ask for 项目维护检查/修复, README and delivery-doc hardening, hackathon submission readiness audits, or maintenance gap triage. Do NOT use for feature coding, market verdicts, legal rulings, or standalone strategy debates.
---

# Project Maintenance Hackathon Web3

Audit maintenance quality with evidence, prioritize P0/P1/P2 gaps, and apply only bounded safe fixes after explicit confirmation.

## Scope

In scope:
- inspect repository maintenance assets for developer onboarding friendliness
- inspect judge-facing assets for one-glance hackathon readability
- produce weighted scorecards (`developer=50`, `judge=50`) and blocking findings
- generate a plan-first repair checklist and optional safe autofix actions
- support bilingual output for judge-facing sections when requested

Out of scope:
- coding product features or refactoring application logic
- legal/compliance conclusions
- market/funding verdicts
- pure strategy roundtable requests without maintenance intent

Routing guidance:
- feature coding -> `backend-product-core` or `frontend-product-grade`
- market verdict -> `market-advisor`
- legal/compliance -> `energy-web3-legal-advisor`
- strategy and pitch debate -> `hackathon-playbook`

## Execution Workflow

1. Confirm intent and constraints.
- verify user wants maintenance audit or maintenance repair planning
- capture target repo path, language preference, and whether fix execution is requested

2. Run deterministic maintenance audit.
- execute `scripts/audit_hackathon_maintenance.py`
- collect repository evidence inventory and produce JSON + Markdown report

3. Classify findings and score quality.
- apply severity policy (`P0`, `P1`, `P2`)
- compute audience scorecards and weighted overall score
- highlight blocking findings (`P0` and `P1` non-pass)

4. Provide plan-first repair proposal.
- output minimal repair plan without editing files
- mark each fix as safe-autofix or manual-only

5. Execute safe autofix only after explicit approval.
- use `scripts/apply_safe_maintenance_fixes.py --dry-run` first
- require `--apply --confirm APPLY_SAFE_FIXES` before writing changes

6. Verify post-fix status.
- re-run audit script
- compare blocking findings, scores, and residual risks

## Severity Policy

- `P0`: project lacks actionable entry documentation or basic quick-start cannot be inferred.
- `P1`: major maintainability or submission risks, including missing testnet contract evidence.
- `P2`: quality uplift opportunities that improve clarity, polish, and consistency.

## Repair Policy

- default mode is plan-first
- no repository edits before explicit confirmation
- safe autofix is limited to:
  - create missing files
  - bounded append blocks with stable markers
- destructive overwrite is not allowed by default

## Score Policy

- developer score is computed from developer-facing maintenance checks
- judge score is computed from judge-facing readability checks
- overall score uses fixed weight `developer=50`, `judge=50`
- always output numeric scores plus blocking finding list

## Output Contract

Use this section order exactly:
1. `Request Snapshot`
2. `Evidence Inventory`
3. `Developer Maintenance Scorecard`
4. `Judge Readability Scorecard`
5. `P0/P1/P2 Findings`
6. `Minimal Repair Plan (No Edit Yet)`
7. `Approval Checkpoint`
8. `Post-Fix Verification`

Additional output requirements:
- include command lines used to generate evidence
- include blocking findings list and direct remediation links
- when language mode is bilingual, include English and Chinese summary lines in judge-facing content

## Commands

Audit command:
```bash
python3 scripts/audit_hackathon_maintenance.py \
  --repo-root <path> \
  --report-json <path> \
  --report-md <path> \
  --lang zh|en|bilingual \
  --weights 50,50
```

Safe fix command:
```bash
python3 scripts/apply_safe_maintenance_fixes.py \
  --repo-root <path> \
  --report-json <path> \
  --dry-run|--apply \
  --confirm APPLY_SAFE_FIXES
```

## Quality Checklist

- [ ] Trigger boundaries are explicit and route non-maintenance intents.
- [ ] Output uses fixed section order.
- [ ] Severity assignment follows P0/P1/P2 policy.
- [ ] Scores include developer, judge, and weighted overall values.
- [ ] Repair output stays plan-first unless explicit apply confirmation is provided.
- [ ] Safe autofix only uses create-missing or bounded append operations.

## References

- `references/developer-rubric.md`
- `references/judge-rubric.md`
- `references/output-contract.md`
- `references/repair-playbook.md`
- `references/readme-template-zh-en.md`
- `references/env-example-template.md`
- `references/adr-template.md`
- `references/troubleshooting-template.md`
- `references/glossary-template.md`
- `references/architecture-mermaid-template.md`
- `references/demo-video-template.md`
- `references/pitch-deck-template.md`
- `references/ci-maintenance-workflow-template.yml`
