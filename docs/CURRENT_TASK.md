# Current Task

## T9.2 done — next ticket T9.3 (2026-10-10)

Part I (P0–P8) is complete and audited. **Part II (P9–P14, full `ARCHITECTURE.md` coverage)** has
started: **T9.1** (node-content schema → `ARCHITECTURE.md` §3.5) and **T9.2** (lifecycle &
sequence diagrams → §2.1–§2.5) are done. The next ticket is **T9.3** (configuration, environment
& ports matrix) in `ROADMAP.md`.

### What this workstream produced

- **`docs/ARCHITECTURE.md`** — the record of reality (repo layout, backend, frontend, containers,
  known gaps), every load-bearing claim cited by `file:line`, **audited in T8.1**; Part II adds
  the node-content schema in **§3.5** (T9.1) and the Mermaid lifecycle sequences in **§2.1–§2.5**
  (T9.2: bootstrap, refresh pipeline, write path, `X-Connection-String`, popup spawn).
- **`docs/PROJECT_STATE.md`** — final snapshot + the P7 corrections to the entry-point docs.
- **`docs/DECISIONS.md`** — D1–D15 (decisions and documented realities, each with evidence).
- **`docs/PRODUCTION_CHECKLIST.md`** — dev-seam registry (backend B1–B6, frontend F1–F3, infra,
  keys/secrets, smoke tests).
- **`docs/ROADMAP.md`** — the plan; P0–P8 `done`, P9 **in progress (2/4)**.
- **`README.md`** — corrected in T7.1; the redundant `DOCUMENTATION.md` was **removed** (D15).

No application source, config, or Docker file was changed (D3); the only non-`docs/` edits were
the T7.1 corrections to the entry-point docs and the D15 removal of `DOCUMENTATION.md`.

### Verify

- Every `file:line` citation in `ARCHITECTURE.md` resolves against the tree (T8.1 for Part I;
  re-checked for the T9.1/T9.2 additions).
- T9.2 sequences: each actor/message maps to a verified call site — bootstrap (`main.ts:5`,
  `app.config.ts:11-16`, `app.component.ts:35-61`), refresh (`htn-state.service.ts:105-162`),
  writes (`htn.service.ts:94-181`, `htn-graph.service.ts:15,239`), connection
  (`connection.interceptor.ts:5-25`, `HttpConnectionProvider.cs:18-42`, `Program.cs:28-40`),
  ping (`HtnController.cs:55-87`), popup spawn (`window-manager.service.ts:23-33`).
- Two reality notes recorded, not fixed, in `ARCHITECTURE.md` §6 (items 9–10).

### Next action

**T9.3** — configuration, environment & ports matrix (`ARCHITECTURE.md` new §5.2). After the
Part II documentation work, the remaining **product** follow-up is in `PRODUCTION_CHECKLIST.md`
(connection-string seam, migrations, auth/CORS, hardcoded API URL) and, optionally, a backend test
project.

## One-ticket-at-a-time loop (the rule)

Top `todo` ticket in ROADMAP → copy fresh here → write → verify against code → mark done (date,
bump progress table) → next ticket. `ARCHITECTURE.md` is reality, `ROADMAP.md` is the plan.
