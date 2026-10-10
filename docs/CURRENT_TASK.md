# Current Task

## T12.3 done — next ticket T12.4 (2026-10-10)

Part I (P0–P8) is complete and audited. **Part II (P9–P14, full architecture coverage)**: P9 and
**P10 (backend reference) are complete** (T10.1–T10.4); **the T10.5 split is done** (the reference
now lives in the numbered `docs/architecture/` folder; **D16**); **P11 (frontend core
reference) is complete (4/4)**; and **P12 (frontend feature reference) is in progress (3/8)** —
T12.1 (window system reference → §4.2), T12.2 (htn-plan reference → §4.4) and T12.3 (htn-explorer
reference → §4.4, in the new owning part `07_frontend_features.md`) are done, T12.4
(htn-editor & htn-categories reference → §4.4) is next.

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
  barrel) in **§4.7** (T11.1), the graph-algorithm deep-dive (`rebuildAdjacency`,
  `computeTopology`, `refreshGraph`, `populateCrossReferences`, `addEdge`/`removeEdge`,
  `navigationRequest$`, plus a seed-graph worked example) in **§4.6** (T11.2), and the **services
  reference** (per-service surface tables + `:line` for all eight `core/services/*.ts` entries) in
  **§4.3** (T11.3), and the **repository layer reference** (the port→impl→route→JSON→domain table
  for all 13 `HtnRepository`/`HttpHtnRepository` methods, the `getGraph`/domain-class mapping, and
  the error-behaviour/connection-status rules) in **§4.3** (T11.4); a §3.1 drift about
  `DefaultConnection`/LocalDB was corrected. T9.4 also adds cross-links at §3.3, §4.4 and §4.6;
  T11.4 adds §6 item 12. Part II's P12 opened with the **window system reference** in **§4.2**
  (T12.1): `WindowService` (list/z-order, `shiny_window_list` auto-persist, 600 z floor),
  `WindowManagerService` (`shiny_session_id`, `spawn`), `WindowComponent` (`Ctx` geometry,
  close≠remove, 8 resize handles, dock registry lifecycle), `Resize`/`Reposition` components
  (1200 ms dock offer), and the dockable-panels service/component (`dockRequests` queues, DOM
  reparenting, mobile rules) + the persistence/inheritance table — with **§6 item 13**. P12
  continued with the **htn-plan reference** in **§4.4** (T12.2): the `'plan'` window shell,
  the `PlanStateService` table (signals, per-window `htn_plan_*` keys, bootstrap + the only
  inbound `planSearchRequest$`), the `PlanStep` model, `buildTree`'s three loop cuts
  (recursion / priority-inversion / reference-loop), the component behaviours (≤450 px
  compact breakpoint, ctrl-click nav, editor delegation, `exportQueue`), the bezier wire
  overlay, and the presentational `PlanNodeCardComponent` — with two inline realities
  (root-singleton plan windows share one signal set; `"Cycle N"` cycle strings + `[LoopDetect]`
  console.log). P12 continued with the **htn-explorer reference** in **§4.4** (T12.3):
  `§4.4` was **split into a new owning part `07_frontend_features.md`** (04 now owns §4.1–§4.3,
  §4.5; `00_index.md` re-mapped with bold chapter bands + one row per §; **D16 amended** into a
  scalability protocol — owner/ref files, split-at-subsection rules). 07 carries the moved feature
  inventory + `htn-plan reference` verbatim plus the explorer reference: the `'explorer'` window
  shell + `'explorer-menu'` companion (`window-registry.ts:12,17`), per-window `PaneState` +
  name-prefixed `htn_explorer_*` keys, `tree-utils.ts` (`computeMinDepths`/`buildTree` +
  `+N more` truncation), ctrl-inverted click actions + referencer choice overlay, the three
  exclusive modes (add-child/rewire/prune), the operations panel, `activeExplorerTrees` →
  metadata menu → `navigationRequest$`, the `<app-graph>` embed, and `io-utils.ts` import/export —
  with three inline realities (per-window state vs the plan singleton; legacy-key deletion not
  migration; fire-and-forget import).
- **`docs/PROJECT_STATE.md`** — final snapshot + the P7 corrections to the entry-point docs.
- **`docs/DECISIONS.md`** — D1–D16 (decisions and documented realities, each with evidence; D16
  records the doc folder/§ convention — **amended in T12.3 into a scalability protocol** —
  and supersedes locked decision #7).
- **`docs/PRODUCTION_CHECKLIST.md`** — dev-seam registry (backend B1–B6, frontend F1–F3, infra,
  keys/secrets, smoke tests).
- **`docs/ROADMAP.md`** — the plan; P0–P10 `done`, **P10.5 done (T10.5)**, P11 **4/4 (T11.1–T11.4)**, P12 **3/8 (T12.1–T12.3)**.
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
- T11.3 §4.3: every service's table row and `:line` resolves against `core/services/*.ts`
  (`HtnService`, `HtnStateService`, `HtnGraphService`, `HtnValidationService`, `ConnectionService`,
  `connection.interceptor.ts`, `StorageService`, `PwaService`); the `HtnState` shape matches
  `htn-state.service.ts:10-17`, the connection string matches `buildConnectionString` (`:95-109`),
  and the validation error strings match `htn-validation.service.ts`. Four realities recorded inline:
  `detachNode` bypasses `settled`, `performComplexRemoval('cascade')` ≡ `'recursive'`,
  `PwaService` is injected nowhere (**added as §6 item 11**), and the two `condition` defaults
  (§6 item 9).
- T11.4 §4.3: every repository table row and `:line` resolves against
  `core/repository/{htn,http}.repository.ts` — all 11 port methods plus the two class-only category
  methods; each route matches the §3.2 endpoint reference; the `Thesis`/`Counterthesis` constructor
  mapping matches `models.ts:9-45`; the rethrow/swallow split matches the `catchError` operators
  and the only `connectionStatus$ → offline` drivers are the four reads (`htn-state.service.ts:106-112,157-159`).
  Two realities recorded: `HtnRepository` never injected + omits category methods (**§6 item 12**);
  `updateNodeContent` ignores `graphType`.
- T12.1 §4.2: every window-system table row and `:line` resolves against
  `features/window-system/**` — the `WindowService` method table matches `window.service.ts:52-112`
  and the `shiny_window_list` persistence (`:20-47`); the z-index floor (600) and
  `bringToFront`/`ZIndexflag` mechanics match `:63,85-101`; the spawn facts match
  `window-manager.service.ts:11-33`; `WindowComponent` inputs/geometry/handles match
  `window.component.ts:16-30,81-96,184-191` and `window.component.html:1-66`; the 1200 ms dock offer
  (+500 ms stop detection) matches `reposition.component.ts:76-110,129-147`; the dock zones, request
  queues, mobile rules, and `enforceMobileLayout` match `dockable-panels.service.ts:11-180,197-226`;
  the reparenting + `setDocked` backdoor match `dockable-panels.component.ts:78-150`. The persistence
  & inheritance table matches the `StorageService` exclusion list (§4.3). One inline reality
  (DOM reparenting) and **§6 item 13** (partial mobile reflow + mobile-check console logs).
- T12.2 §4.4: every table row and `:line` resolves against `features/htn-plan/**` — the
  `PlanStateService` table matches `plan-state.service.ts:27-38,65-71,40-63,73-125,127-282` (incl.
  the `NAV_HISTORY_LIMIT = 5` slice/`realIndex` remap at `:35,299-308` and the `console.warn` on a
  parse failure at `:278-280`); `PlanStep`/`PendingAnalysis` match `plan.types.ts:3-27`; the three
  `buildTree` loop cuts match `plan-utils.ts:115-145` with the `type:'loop'` stub at `:188-221`,
  priority sort at `:250-259`, referencer `targetStep` at `:146-182`, and the
  `executionOrder==='set'` → `childrenCollapsed` default at `:276`; the component behaviours match
  `htn-plan.component.ts:54-63,96-118,169-181,197-274,276-342,373-413`; wire geometry matches
  `wire-utils.ts:26-37,74-137` and `plan.constants.ts:1-7`; the card matches
  `plan-node-card.component.ts:13-32` and `plan-node-card.component.html:24-132`. The only inbound
  plan channel cited (`planSearchRequest$`, a `Subject` on `htn-state.service.ts:54-55,73-75`
  re-exposed at `htn.service.ts:37,48`) is emitted only by the explorer's/categories' `openInPlan`
  (`htn-explorer.component.ts:697-698`, label `htn-explorer.html:229`;
  `htn-categories.component.ts:271-273`) and consumed only by `plan-state.service.ts:58-62`. Two
  realities recorded inline: the root-singleton `PlanStateService` (all plan windows share one
  signal set), and `"Cycle N"` cycle strings + the `[LoopDetect]` console.log.
- T12.3 §4.4: every row and `:line` resolves against `features/htn-explorer/**` — the window
  shell (`window-registry.ts:12,17`; `htn-explorer.html:1-2`); `PaneState`
  (`htn-explorer.component.ts:19-25`); the four name-prefixed keys (`:46-53`,
  `htn-explorer.constants.ts:2-5`); `restoreState` + its three legacy-key deletions
  (`:334-336`); the bootstrap + `htn-config-changed` listener (`:263-298`);
  `tree-utils.ts:10-33,35-77`; click routing + `effectiveClickAction` + the reference overlay
  (`:366-441`); the modes (`:501-662`); the operations panel (`:467-732`); `activeExplorerTrees`
  → metadata menu → `navigationRequest$` (`:235-245`, `htn-metadata-menu.component.ts:24-30`);
  the `<app-graph>` embed (`htn-explorer.html:210-217`); `io-utils.ts:5-177`. The §4.4 split is
  faithful: the feature-inventory table + `htn-plan reference` in `07_frontend_features.md` are
  byte-identical to their former `04_frontend.md` text; `04_frontend.md` owns §4.1–§4.3, §4.5;
  `00_index.md` maps every `§` to exactly one row (owner-first), with 07 as the §4.4 owner; every
  part header reads `Part N of 7`; all files ≤600 lines. Three realities recorded inline
  (per-window explorer state vs the plan singleton; legacy-key deletion not migration;
  fire-and-forget import).
- Reality notes recorded, not fixed, in `architecture/` §6 (items 9–13).

### Next action

**P12 (frontend feature reference) is underway — T12.3 done.** The next documentation ticket is
**T12.4** (htn-editor & htn-categories reference → `docs/architecture/07_frontend_features.md`
§4.4), in `ROADMAP.md`. After the Part II documentation work, the remaining **product** follow-up
is in `PRODUCTION_CHECKLIST.md` (connection-string seam, migrations, auth/CORS, hardcoded API URL)
and, optionally, a backend test project.

## One-ticket-at-a-time loop (the rule)

Top `todo` ticket in ROADMAP → copy fresh here → write → verify against code → mark done (date,
bump progress table) → next ticket. `docs/architecture/` is reality, `ROADMAP.md` is the plan.
