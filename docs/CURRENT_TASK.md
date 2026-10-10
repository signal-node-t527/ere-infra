# Current Task

## T10.5 in progress — next ticket T11.3 (2026-10-10)

Part I (P0–P8) is complete and audited. **Part II (P9–P14, full architecture coverage)**: P9 and
**P10 (backend reference) are complete** (T10.1–T10.4), and **P11 (frontend core reference) is
paused (2/4)** — T11.1 (domain-layer reference → §4.7) and T11.2 (graph algorithms → §4.6) are done.
The **active ticket is T10.5** (ROADMAP **P10.5**): split the former single `docs/ARCHITECTURE.md`
into the numbered `docs/architecture/` folder and record the file convention as **D16**. After
T10.5, the next ticket is **T11.3** (services reference → §4.3), in `ROADMAP.md`.

### What this workstream produced

- **`docs/architecture/`** (formerly `docs/ARCHITECTURE.md`) — the record of reality (repo layout,
  backend, frontend, containers, known gaps), every load-bearing claim cited by `file:line`,
  **audited in T8.1**; split into numbered parts entered via `00_index.md` (T10.5/D16). Part II adds
  the node-content schema in **§3.5** (T9.1), the Mermaid lifecycle sequences in **§2.1–§2.5**
  (T9.2), the settings/ports matrix in **§5.2** (T9.3, with §5 split into §5.1/§5.2), the
  vocabulary → code map in **§2.6** (T9.4), the file-by-file backend reference in **§3.6**
  (T10.1), the per-endpoint wire contract in **§3.2** (T10.2), the persistence schema + full seed
  dataset in **§3.3** (T10.3), the cross-cutting behaviours (connection resolution, JSON
  round-trip, exception→HTTP mapping, diagnostics) in **§3.4** (T10.4), the frontend domain
  layer reference (types/constants, `Thesis`/`Counterthesis` normalization, validation key-sets,
  barrel) in **§4.7** (T11.1), and the graph-algorithm deep-dive (`rebuildAdjacency`,
  `computeTopology`, `refreshGraph`, `populateCrossReferences`, `addEdge`/`removeEdge`,
  `navigationRequest$`, plus a seed-graph worked example) in **§4.6** (T11.2); a §3.1 drift about
  `DefaultConnection`/LocalDB was corrected. T9.4 also adds cross-links at §3.3, §4.4 and §4.6.
- **`docs/PROJECT_STATE.md`** — final snapshot + the P7 corrections to the entry-point docs.
- **`docs/DECISIONS.md`** — D1–D15 (decisions and documented realities, each with evidence).
- **`docs/PRODUCTION_CHECKLIST.md`** — dev-seam registry (backend B1–B6, frontend F1–F3, infra,
  keys/secrets, smoke tests).
- **`docs/ROADMAP.md`** — the plan; P0–P10 `done`, **P10.5 in progress (T10.5)**, P11 **paused (2/4)**.
- **`README.md`** — corrected in T7.1; the redundant `DOCUMENTATION.md` was **removed** (D15).

No application source, config, or Docker file was changed (D3); the only non-`docs/` edits were
the T7.1 corrections to the entry-point docs and the D15 removal of `DOCUMENTATION.md`.

### Verify

- Every `file:line` citation in `docs/architecture/` resolves against the tree (T8.1 for Part I;
  re-checked for the T9.1–T10.4 additions).
- T10.5: the split is byte-faithful — concatenating `docs/architecture/01…06_*.md` (minus the added
  one-line headers) reproduces the former `docs/ARCHITECTURE.md` body exactly (every `§1–§7` present
  once, no drops/dupes, all `file:line` intact); every `docs/architecture/*.md` is ≤600 lines;
  `00_index.md` maps every `§`; the only remaining mentions of `docs/ARCHITECTURE.md` are historical.
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
- T10.2 §3.2: all 15 endpoints documented with params/body/response and the **exact** status codes
  and message strings from `HtnController.cs` (`Node with ID {id} already exists.`,
  `Node {id} not found in graph {graph}.`, `No IDs provided.`, `Edge already exists.`,
  `Source/Target node {id} does not exist in graph {graph}.`, `Edge not found.`,
  `Migration failed: {ex.Message}`, the `ping` bodies) and `HtnCategoriesController.cs`.
- T10.3 §3.3: table/column facts match the model annotations and EF Core 9 conventions; the seed
  tables reproduce the exact 17 + 8 nodes and 17 + 8 edges from `DbInitializer.cs:26-147`.
- T10.4 §3.4: the `resolve()` pseudocode + fallback matrix match `HttpConnectionProvider.cs:20-42`
  and `Program.cs:28-40`; the exception→HTTP rules match every controller `try/catch` and
  `Program.cs:42-58`.
- T11.1 §4.7: every table row resolves to an exported symbol in
  `core/domain/{types,models,constants,htn}.ts`; `Edge`/`Adjacency`/`NodeId` are flagged as
  module-local; the constructor-normalization and key-set facts match `models.ts`/`constants.ts`.
- T11.2 §4.6: every algorithm's pseudocode and `:line` cites match `core/domain/graph.utils.ts`;
  the worked example's layers reproduce the seed thesis edges (`634e76d4` = longest 3 / shortest 1);
  the two realities (`avg` always 0; out-of-graph triggers dropped on the 2nd refresh) are recorded
  inline (no §6 item, per scope).
- Two reality notes recorded, not fixed, in `ARCHITECTURE.md` §6 (items 9–10).

### Next action

**P11 (frontend core reference) is underway — T11.1 and T11.2 done.** The next documentation ticket is
**T11.3** (services reference → `ARCHITECTURE.md` §4.3), in `ROADMAP.md`. After the Part II
documentation work, the remaining **product** follow-up is in `PRODUCTION_CHECKLIST.md`
(connection-string seam, migrations, auth/CORS, hardcoded API URL) and, optionally, a backend test
project.

## One-ticket-at-a-time loop (the rule)

Top `todo` ticket in ROADMAP → copy fresh here → write → verify against code → mark done (date,
bump progress table) → next ticket. `docs/architecture/` is reality, `ROADMAP.md` is the plan.
