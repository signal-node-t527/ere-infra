# Current Task

## T9.1 done — next ticket T9.2 (2026-10-10)

Part I (P0–P8) is complete and audited. **Part II (P9–P14, full `ARCHITECTURE.md` coverage)** has
started: **T9.1** (node-content schema → `ARCHITECTURE.md` §3.5) is done. The next ticket is
**T9.2** (request/response lifecycle & sequence diagrams) in `ROADMAP.md`.

### What this workstream produced

- **`docs/ARCHITECTURE.md`** — the record of reality (repo layout, backend, frontend, containers,
  known gaps), every load-bearing claim cited by `file:line`, **audited in T8.1**; Part II adds
  the node-content schema in **§3.5** (T9.1).
- **`docs/PROJECT_STATE.md`** — final snapshot + the P7 corrections to the entry-point docs.
- **`docs/DECISIONS.md`** — D1–D15 (decisions and documented realities, each with evidence).
- **`docs/PRODUCTION_CHECKLIST.md`** — dev-seam registry (backend B1–B6, frontend F1–F3, infra,
  keys/secrets, smoke tests).
- **`docs/ROADMAP.md`** — the plan; P0–P8 `done`, P9 **in progress (1/4)**.
- **`README.md`** — corrected in T7.1; the redundant `DOCUMENTATION.md` was **removed** (D15).

No application source, config, or Docker file was changed (D3); the only non-`docs/` edits were
the T7.1 corrections to the entry-point docs and the D15 removal of `DOCUMENTATION.md`.

### Verify (already done in T8.1)

- Every `file:line` citation in `ARCHITECTURE.md` resolves against the tree.
- `PRODUCTION_CHECKLIST.md` rows and artifact references all verified.
- Drift found and fixed: seed counts (17 thesis nodes / 17 thesis edges), service-worker
  registration in `src/index.html:24-30`, and the obsolete §6 note about stale entry-point docs.

### Next action

**T9.2** — request/response lifecycle & sequence diagrams (`ARCHITECTURE.md` new §2.x). After the
Part II documentation work, the remaining **product** follow-up is in `PRODUCTION_CHECKLIST.md`
(connection-string seam, migrations, auth/CORS, hardcoded API URL) and, optionally, a backend test
project.

## One-ticket-at-a-time loop (the rule)

Top `todo` ticket in ROADMAP → copy fresh here → write → verify against code → mark done (date,
bump progress table) → next ticket. `ARCHITECTURE.md` is reality, `ROADMAP.md` is the plan.
