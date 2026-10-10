# Current Task

## No open ticket — documentation buildout complete (2026-10-10)

The `ere-infra` documentation set is complete and audited. Start from here.

### What this workstream produced

- **`docs/ARCHITECTURE.md`** — the record of reality (repo layout, backend, frontend, containers,
  known gaps), every load-bearing claim cited by `file:line`, **audited in T8.1**.
- **`docs/PROJECT_STATE.md`** — final snapshot + the P7 corrections to the entry-point docs.
- **`docs/DECISIONS.md`** — D1–D14 (decisions and documented realities, each with evidence).
- **`docs/PRODUCTION_CHECKLIST.md`** — dev-seam registry (backend B1–B6, frontend F1–F3, infra,
  keys/secrets, smoke tests).
- **`docs/ROADMAP.md`** — the plan; all of P0–P8 are `done`.
- **`README.md` / `DOCUMENTATION.md`** — corrected in T7.1 and now point at `docs/`.

No application source, config, or Docker file was changed (D3); the only non-`docs/` edits were
the T7.1 corrections to the two entry-point documents.

### Verify (already done in T8.1)

- Every `file:line` citation in `ARCHITECTURE.md` resolves against the tree.
- `PRODUCTION_CHECKLIST.md` rows and artifact references all verified.
- Drift found and fixed: seed counts (17 thesis nodes / 17 thesis edges), service-worker
  registration in `src/index.html:24-30`, and the obsolete §6 note about stale entry-point docs.

### Next action

No documentation ticket remains. The open work is **product** follow-up in
`PRODUCTION_CHECKLIST.md` (connection-string seam, migrations, auth/CORS, hardcoded API URL) and,
optionally, a backend test project. To resume documentation, add a ticket to `ROADMAP.md`.

## One-ticket-at-a-time loop (the rule)

Top `todo` ticket in ROADMAP → copy fresh here → write → verify against code → mark done (date,
bump progress table) → next ticket. `ARCHITECTURE.md` is reality, `ROADMAP.md` is the plan.
