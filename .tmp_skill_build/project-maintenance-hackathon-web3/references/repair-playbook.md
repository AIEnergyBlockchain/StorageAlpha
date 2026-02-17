# Repair Playbook (Plan-First)

## Policy

- never edit before presenting a minimal repair plan
- run `--dry-run` first
- only execute `--apply` with `--confirm APPLY_SAFE_FIXES`

## Safe Operations

- create missing files from templates
- bounded append blocks with stable markers in README
- avoid overwrite and destructive deletion

## Manual-Only Operations

- business-specific architecture or tokenomics claims
- rewriting large existing README narrative
- changing application code, tests, or deployment logic

## Typical Sequence

1. Run audit and inspect blocking findings.
2. Produce plan with target file list.
3. Execute safe dry-run and review operations.
4. Confirm apply and create bounded maintenance files.
5. Re-run audit and compare scores.
