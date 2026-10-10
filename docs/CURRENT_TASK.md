# Current Task

## T10.1 done — next ticket T10.2 (2026-10-10)

Part I (P0–P8) is complete and audited. **Part II (P9–P14, full `ARCHITECTURE.md` coverage)**: P9 is
done and **P10 (backend reference) has started** — **T10.1** (per-file / per-class reference →
§3.6) is done. The next ticket is **T10.2** (endpoint reference — request/response schemas & status
codes) in `ROADMAP.md`.

### What this workstream produced

- **`docs/ARCHITECTURE.md`** — the record of reality (repo layout, backend, frontend, containers,
  known gaps), every load-bearing claim cited by `file:line`, **audited in T8.1**; Part II adds
  the node-content schema in **§3.5** (T9.1), the Mermaid lifecycle sequences in **§2.1–§2.5**
  (T9.2: bootstrap, refresh pipeline, write path, `X-Connection-String`, popup spawn), the
  settings/ports matrix in **§5.2** (T9.3, with §5 split into §5.1/§5.2), the vocabulary →
  code map in **§2.6** (T9.4), and the file-by-file backend reference in **§3.6** (T10.1); a §3.1
  drift about `DefaultConnection`/LocalDB was corrected. T9.4 also adds cross-links at §3.3, §4.4
  and §4.6.
- **`docs/PROJECT_STATE.md`** — final snapshot + the P7 corrections to the entry-point docs.
- **`docs/DECISIONS.md`** — D1–D15 (decisions and documented realities, each with evidence).
- **`docs/PRODUCTION_CHECKLIST.md`** — dev-seam registry (backend B1–B6, frontend F1–F3, infra,
  keys/secrets, smoke tests).
- **`docs/ROADMAP.md`** — the plan; P0–P9 `done`, P10 **in progress (1/4)**.
- **`README.md`** — corrected in T7.1; the redundant `DOCUMENTATION.md` was **removed** (D15).

No application source, config, or Docker file was changed (D3); the only non-`docs/` edits were
the T7.1 corrections to the entry-point docs and the D15 removal of `DOCUMENTATION.md`.

### Verify

- Every `file:line` citation in `ARCHITECTURE.md` resolves against the tree (T8.1 for Part I;
  re-checked for the T9.1–T10.1 additions).
- T9.2 sequences: each actor/message maps to a verified call site — bootstrap (`main.ts:5`,
  `app.config.ts:11-16`, `app.component.ts:35-61`), refresh (`htn-state.service.ts:105-162`),
  writes (`htn.service.ts:94-181`, `htn-graph.service.ts:15,239`), connection
  (`connection.interceptor.ts:5-25`, `HttpConnectionProvider.cs:18-42`, `Program.cs:28-40`),
  ping (`HtnController.cs:55-87`), popup spawn (`window-manager.service.ts:23-33`).
- T9.3 matrix: every setting/port cell cites `launchSettings.json`, `appsettings*.json`,
  `Program.cs`, `docker-compose.yml`, the Dockerfiles/`nginx.conf`, `angular.json`, `package.json`
  or `app-config.ts`; §3.1 now matches `appsettings*.json`.
- T9.4 §2.6: every term maps to a real symbol/column/route/file (`types.ts`, `models.ts`,
  `graph.utils.ts`, `Models/Htn*.cs`, `HtnController.cs`, `dockable-panels.service.ts`); the
  `antithesis` alias is attributed to D4; no terms invented.
- T10.1 §3.6: every backend `.cs` file has a subsection and every public member is listed with a
  resolving `file:line`; config/artifact values are cross-linked to §3.1–§3.5/§5, not duplicated.
- Two reality notes recorded, not fixed, in `ARCHITECTURE.md` §6 (items 9–10).

### Next action

**P10 (backend reference) is underway — T10.1 done.** The next documentation ticket is **T10.2**
(endpoint reference — request/response schemas & status codes → `ARCHITECTURE.md` §3.2) in
`ROADMAP.md`. After the Part II documentation work, the remaining **product** follow-up is in
`PRODUCTION_CHECKLIST.md` (connection-string seam, migrations, auth/CORS, hardcoded API URL) and,
optionally, a backend test project.

## One-ticket-at-a-time loop (the rule)

Top `todo` ticket in ROADMAP → copy fresh here → write → verify against code → mark done (date,
bump progress table) → next ticket. `ARCHITECTURE.md` is reality, `ROADMAP.md` is the plan.
