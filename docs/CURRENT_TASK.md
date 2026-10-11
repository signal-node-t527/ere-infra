# Current Task

## Part II complete — no open ticket (2026-10-10)

**All of P0–P14 is done.** Part I (P0–P8) produced the verified overview; **Part II (P9–P14,
full architecture coverage) deepened it into the exhaustive numbered reference in
`docs/architecture/`** (D16) — foundations/schemas (P9), the backend reference (P10 + the T10.5
split), the frontend core reference (P11), the frontend feature reference (P12), the infra &
operations reference (P13), and **P14 (assurance & consistency)**: T14.1 (gaps, assumptions &
unknowns register → §6), T14.2 (full ARCHITECTURE-vs-code audit — 666 citations, 0 out-of-bounds,
0 missing after fixes), T14.3 (entry-point doc symmetry → `README.md`) and T14.4 (this final state
refresh). There is **no open ticket**; the remaining work is **product**, not docs
(`PRODUCTION_CHECKLIST.md`).

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
   migration; fire-and-forget import). P12 continued with the **htn-editor & htn-categories
   reference** in **§4.4** (T12.4): the `'editor'` window with its option build + deliberate
   `editableContent` non-refresh, the `editorSearchRequest$`/`refNodeCreated$` channels, the
   load/create paths, a `HtnContentService` method table (sanitize → `cleanupContent`), the save
   pipeline (`validateNodeContent` gate, create/update, export/import, `switchToPlan`), the
   recursive JSON templates + typed widgets, and the settings/auto-resize subsystem; plus the
   `'categories'` window — the `state$` clone + synthesized `default`/orphans list, `save()`
   flag-stripping, the CRUD actions, navigation, the recursive template, and the `CategoryList`
   model — with five inline realities (editor `editableContent` survives refresh; raw
   `console.log` in the editor's save path; field-type-dependent save timing; categories'
   name-match window activation that never focuses generated-named windows; in-place list
   mutation + `state$` re-clone clobber risk). P12 continued with the **graph-lib reference** in
   **§4.4** (T12.5): the standalone `app-graph` wrapper over `@swimlane/ngx-graph` (`graph.ts:20-27`;
   consumed only at `htn-explorer.html:210-217`), its six inputs/five outputs (`graph.ts:34-44`), the
   module-load `GraphComponent.prototype.ngOnChanges` monkey-patch that unblocks zero-link graphs
   (`:7-18`), `instanceId` namespacing + `layoutSettings` (`BT` thesis / `TB` else, `network-simplex`;
   `:51-58`), `loadGraph`'s BFS over forward `ady` (node shape incl. `labelLines`/`layerAvg`/
   `references`, link labels from the target's `flow[source]`, `skipRecursionEdges`; `:204-329`), the
   constructor `effect` + `update$` re-subscription and the `ResizeObserver` one-time `zoomToFit$`
   (`:149-202`), the click/hover highlight interactions (`:28-132`), the `graph.html`
   node/defs/link templates + `graph.scss` type colors, and `config.ts` (commented-out scratch) /
   `graph.spec.ts` (create only) — with three inline realities (global teardown-less monkey-patch;
   forward-`ady`-only render with cross-graph refs as label bullets; `layerAvg` always `L:0.0`).
   P12 continued with the **connection-string-manager reference** in **§4.4** (T12.6): the
   `'connection-manager'` window shell (`window-registry.ts:16`; `<app-window>` default
   `[30,20,40,60]`, `connection-string-manager.html:1`; input resolution `:17-31`), the list/edit
   views (CRUD + template-driven `FormsModule` form, `html:3-88`), the component actions
   (clone/seed with `crypto.randomUUID()`, save/delete/`confirm()`, `activateConnection` →
   `setActiveConnection` + `htnService.refresh()`; `:39-78`), `testConnection()` (`:80-104`:
   `buildConnectionString` + `btoa` header → `/htn/ping` via raw `HttpClient`, PascalCase body
   mapping), the builder (cross-linked to §4.3, integrated-security example), persistence and
   active-selection (`connection.service.ts:41-83`), styles + spec — with three inline realities
   (the `connection-manager` console command is advertised with no dedicated registration but
   still opens via the dispatcher's window-type fallback; `testConnection()` tests the unsaved
   editing config and bypasses the interceptor; passwords persist in cleartext in `localStorage`
   + base64-only header). Also extended `PRODUCTION_CHECKLIST.md` B1 + §5 for the cleartext
   client-side credentials. P12 continued with the **console command reference** in **§4.5**
   (T12.7): parser grammar (`console.parser.ts:3-54`), dispatch (`console.handler.ts` ten-factory
   map `:122-136`, `handleCommand` fallback chain `:183-209`), the `HandlerContext` contract,
   logger levels/sentinels, a grouped table of all **44 verbs / 45 registrations**, and the script
   engine (cross-linking `console_script_syntax.md`) — with three inline realities (drifted
   hand-maintained `help` table; advisory-only offline gating; trusted-HTML output). Corrected the
   T12.6 record: `connection-manager` is not a dead command. P12 closed with the **shared components
   & styling reference** in **§4.6** (T12.8): a `suggestion-input` contract table + filtering
   (cap-50)/keyboard/blur behaviour + its four consumers, the `units-conversion` helpers, the global
   styling/theming layer (`styles.scss`, `app.component.scss`, per-component SCSS), and the
   window-chrome conventions (header/core/resize/theme inputs, dock chrome, launcher) — with four
   inline realities (units default `window.innerWidth` on both axes; dead `.window-test__span`
   styling; non-signal `inputText` mirror + 200 ms blur timer, no spec; hardcoded-hex theming). §4.6
   retitled to include "shared components".
   **P13 opened with the container / image reference** in **§5.3** (T13.1): per-stage tables for
   `resolution-engine/Dockerfile` and `shiny-computing-machine/Dockerfile` (+ `Dockerfile.dev`),
   a `nginx.conf` rule table (SPA fallback, 6-month asset cache, exact-match `no-store`
   `/scripts/index.json`, 50x page), and the `EXPOSE`/non-root (`USER $APP_UID`)/entrypoint/CMD,
   `.dockerignore`-exclusion, hardcoded-URL (F1) and `(localdb)`-in-container (B3) facts; §5.1's
   duplicated Dockerfile prose was trimmed to point at §5.3. **P13 continued with the compose
   topology reference** grown into **§5.1** (T13.2): per-service key→value→`line` tables for
   `db`/`backend`/`frontend-prod`/`frontend-dev`, the profiles/run-commands matrix + three
   `depends_on` edges, the `ere-network`/`mssql_data`/`./backups` facts, the
   `${MSSQL_SA_PASSWORD}` env-wiring flow, a Mermaid container diagram, and inline realities (no
   `healthcheck:` → start-order-only `depends_on`; fixed `container_name`s; no `restart:`; unpinned
   `:latest`/default password/published `1433`; dev anonymous `node_modules`). Also fixed a §5.2
   drift ("the compose override"). **P13 closed with the build tooling & PWA reference** grown into
   **§4.6** (T13.3): the npm-script table + the `build-script-index.mjs` generator deep-dive (scan /
   record shape / tolerant parse / `parseError` + `--strict`, the 5 shipped scripts), the `angular.json`
   build/serve config, the **Test setup** subsection (Jest builder `angular.json:82-89`,
   `tsconfig.spec.json`, the 21 spec files, and the reality that the Karma/Jasmine deps are dead
   config — D14), the **Lint** subsection (`.eslintrc.js` rules + the reality that line 9's stray
   backticks make it invalid and unwired), the **PWA lifecycle** subsection (manifest, per-strategy
   SW table from `sw.js`, inline registration, dead `PwaService` prompt, and the realities: stale
   "MiApp" title, origin-relative `/api/` bypass, manual cache-version bump) and a consolidated
   **Dead scaffolding** list. Also added **§6 item 14** (broken/unwired `.eslintrc.js`) to
   `06_infrastructure.md`. **P14 opened with the gaps, assumptions & unknowns register** (T14.1):
   §6 recast with a GAP/ASSUMPTION/UNKNOWN taxonomy intro (mirror-renamed in `00_index.md`), seven
   new `[GAP]` items (trusted-HTML console output, cleartext credentials, advisory-only offline
gating, feature-path `console.log` dumps, `layerAvg` always `L:0.0`, Phase-A trigger/effect
    drop, legacy-key deletion), and **PRODUCTION_CHECKLIST rows F4/F5** added.
- **T14.2 (full ARCHITECTURE-vs-code audit) done.** Ran the T8.1 method across the expanded
  reference: programmatic citation pass (666 `file:line` tokens; 0 out-of-bounds, 0 missing after
  fixes, 13 ambiguous — all adjudicated to the verified file), inventory-vs-disk (21 specs, 5
  scripts, 15 endpoints, §3.6 file list, § map, checklist B/F rows), and an intent-over-reality
  sweep (clean). **Docs-only fixes:** §5.3 backend `ENTRYPOINT` citation `:26`→`:28` in
  `06_infrastructure.md`; dropped the stale pre-correction `README`/`DOCUMENTATION` line cites from
  `PROJECT_STATE.md`'s corrections table. Re-verified clean.
- **T14.3 (entry-point doc symmetry) done.** `README.md` (the D15-sanctioned root entry doc): the
  three "Antithesis" spots now read **Counterthesis** (canonical per D4; alias stays in §2.6/§3.2)
  and the prod bash block gained `# Access the application at http://localhost:4200 (nginx)`.
  Pointers already correct. Also fixed two bounds-invisible blank-line cite slips in
  `06_infrastructure.md` (§5.1 run-command table: old `:48`/`:34` → `README.md:44,46`/`:51,52`).
  Verified cited README lines unchanged; audit 666/0/0; git = README + docs only.
- **T14.4 (final state refresh) done.** Closed out Part II the way T8.2 closed Part I:
  `PROJECT_STATE.md` is the final snapshot, `CURRENT_TASK.md` is reset to "Part II complete — no
  open ticket", and the ROADMAP progress table matches every ticket status (**all of P0–P14 done**).
- **`docs/PROJECT_STATE.md`** — final snapshot + the P7 corrections to the entry-point docs.
- **`docs/DECISIONS.md`** — D1–D16 (decisions and documented realities, each with evidence; D16
  records the doc folder/§ convention — **amended in T12.3 into a scalability protocol** —
  and supersedes locked decision #7).
- **`docs/PRODUCTION_CHECKLIST.md`** — dev-seam registry (backend B1–B6, frontend F1–F5, infra,
  keys/secrets, smoke tests).
- **   `docs/ROADMAP.md`** — the plan; P0–P10 `done`, **P10.5 done (T10.5)**, P11 **4/4 (T11.1–T11.4)**, P12 **8/8 (T12.1–T12.8)**, P13 **3/3 (T13.1–T13.3)**, P14 **4/4 (T14.1–T14.4)** — all phases `done`.
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
- T12.4 §4.4: every table row and `:line` resolves against `features/htn-editor/**` and
  `features/htn-categories/**` — the editor window shell (`window-registry.ts:14`,
  `htn-editor.html:1-2`); the `getData()` build + non-refresh (`htn-editor.component.ts:105-137`);
  the `editorSearchRequest$`/`refNodeCreated$` channels (`:169-190`); `loadEntity`/`setupCreation`
  (`:208-264`, `ensureFlowEntries :252`, `getDefaultContent :217`); the `HtnContentService` table
  (`htn-content.service.ts:9-165`); the save pipeline (`save :270-328`, `validateNodeContent :295`,
  `exportJson`/`importJson :330-381`, `close`/`switchToPlan :383-425`); the recursive templates +
  widgets + `isPropertyRemovable :520-538`; the settings/auto-resize run (`:72-75,147-167,431-438,560-606`).
  Categories: the window shell (`window-registry.ts:13`, `htn-categories.html:1-2`); the `state$`
  clone + `default`/orphans synthesis (`htn-categories.component.ts:47-107`); `save :109-124`; the
  CRUD actions (`:128-247`); navigation (`:250-292`); the template + `CategoryList`
  (`types.ts:107-116`). Five realities recorded inline (editor `editableContent` survives refresh;
  editor `console.log` past the logger; field-type-dependent save timing; categories name-match
   activation never focuses generated names; categories in-place mutation + `state$` re-clone).
- T12.5 §4.4: every row and `:line` resolves against `features/graph-lib/**` — the component
  shell (`graph.ts:20-27`; `htn-explorer.html:210-217`); the inputs/outputs (`graph.ts:34-44`);
  the `ngOnChanges` monkey-patch (`:7-18`); `instanceId` (`:145-147`); `layoutSettings`/`viewDimensions`
  + pan/zoom signals (`:46,51-58,120-131`) and the `ngx-graph` bindings (`graph.html:1-5`); `loadGraph`
  node/link construction + forward-`ady` BFS + `flow[source]` labels + `skipRecursionEdges`
  (`:204-329`, incl. `references :262-266`, back-edge `:283`, skip `:286-288`); the constructor
  `effect` + `update$` re-subscription (`:149-173`), `ResizeObserver`/one-time `zoomToFit$`
  (`:175-193`) and teardown (`:195-202`); `onNodeClick`/`onNodeHover`/`onNodeLeave` + link hover
  (`:28-132`); the `graph.html` node/defs/link templates (`:6-31,32-83,84-106`) and `graph.scss`
  type colors (`:11-50`); `config.ts` (commented-out scratch) / `graph.spec.ts:1-23`. Three realities
  recorded inline (global teardown-less monkey-patch; forward-`ady`-only render, cross-graph refs as
  label bullets only; `layerAvg` always `L:0.0`, cross-linking §4.6). Also fixed the explorer's stale
  "(graph-lib, reference pending §4.4)" pointer (07:244) and the §4.4 inventory row (07:11).
- T12.6 §4.4: every row and `:line` resolves against `features/connection-string-manager/**` and
  `core/services/connection.service.ts` — the window shell (`window-registry.ts:16`;
  `connection-string-manager.ts:10-31`; `connection-string-manager.html:1`); the list/edit views
  (`html:3-88`); the component actions (`:39-78`); `testConnection()` (`:80-104`: builder, `btoa`
  header, raw `HttpClient` GET to `/htn/ping`, PascalCase mapping vs `HtnController.cs:60-84`); the
  builder (cross-link §4.3 `04_frontend.md:248-249`, example output); persistence/active-selection
  (`connection.service.ts:41-83`); `connection-string-manager.scss:1-192`;
   `connection-string-manager.spec.ts:1-23`. The command reality is verified by the exhaustive
   `connection-manager` search (only `config-utility.handler.ts:43` and the registry/component files;
   no `map.set`) plus the dispatcher's window-type fallback (`console.handler.ts:190-202`, since
   `connection-manager` is a `WINDOW_REGISTRY` key), with the open paths
   `view.handler.ts:188,193,220-235`. Three realities recorded inline (advertised command with a
   fallback open path rather than a dedicated registration — corrected in T12.7;
   test-from-unsaved-config bypassing the interceptor; cleartext password persistence + base64-only
   header). `PRODUCTION_CHECKLIST.md` B1 and §5 now carry the cleartext-credentials note.
- T12.7 §4.5: every row and `:line` resolves against `features/console/**` — the parser
  (`console.parser.ts:3-54`; token regex `:9`; flag/key-value/positional classification `:25-50`;
  `console.parser.spec.ts:1-51`); the dispatcher (`console.handler.ts:13-22` imports, `:122-136`
  merged map, `:139-172` context, `:183-209` fallback chain, `:211-239` name activation);
  `handler-context.ts:3-34`; `console-logger.service.ts:8-54`; the `SafeHtmlPipe` binding
  (`console.component.ts:9-15,43-107`, `console.html:1-10`); the ten modules' `map.set` keys
  (45 registrations / 44 verbs, `navigation.handler.ts:8-9` alias); and `script.handler.ts`
  guards (`:69,88-89,384-387`). Three realities recorded inline (drifted `help` table —
  `connection-manager` listed, `navigate` + `config-*-integrity` omitted; advisory-only offline
  gating; trusted-HTML output). Also corrected T12.6's "dead command" claim in §4.4. §4.5 grew
  21 → 118 lines; `04_frontend.md` = 436 ≤ 600.
- T12.8 §4.6: every row and `:line` resolves against `shared/**`, `src/styles.scss`,
  `app.component.scss` and the window-system chrome — the suggestion-input contract
  (`suggestion-input.component.ts:5-42,117-131`; keyboard `:63-115`; 200 ms blur `:56-61`; template
  `html:1-12`; SCSS `:1-78`) and its four consumers (`htn-editor.html`, `htn-explorer.html`,
  `htn-plan.html`, `htn-categories.html`; `plan-state.service.ts:8`); `units-conversion.ts:1-7`
  (window-system-only, `window.component.ts:194-263`, `resize.component.ts:3`); `styles.scss:1-52`
  (`.scrolling :42-48`, `.no-select :50-52`) + `app.component.scss:1-46`; the window chrome
  (`window.component.html:27-41`, `window.component.scss:12-70`, `window.table.scss:1-96`, inputs
  `window.component.ts:93-96`, `console.component.ts:38-39`, `console.html:1`, `dockable-panels.scss:16-146`,
  `console-btn.scss:1-37`). Four realities recorded inline (units default `window.innerWidth` on both
  axes; dead `.window-test__span` folded into the §4.6 dead-scaffolding bullet; non-signal `inputText`
  + 200 ms blur timer with no spec; hardcoded-hex theming, no tokens). §4.6 retitled;
  `05_frontend_core.md` = 244 → 320 ≤ 600; `00_index.md` topic cell updated.
- Reality notes recorded, not fixed, in `architecture/` §6 (items 9–13).
- T14.2 audit: a programmatic pass over `docs/architecture/` found **666** `file:line` tokens with
  **0 out-of-bounds and 0 missing** (17 ambiguous, all adjudicated to the verified file); T14.4: the
  progress table matches every ticket status and **all of P0–P14 is `done`**.

### Next action

**Buildout complete — no open ticket.** Every ticket in `docs/ROADMAP.md` (P0–P14) is `done`; the
one-at-a-time loop is closed. The remaining **product** follow-up is in `PRODUCTION_CHECKLIST.md`
(connection-string seam, migrations, auth/CORS, hardcoded API URL) and, optionally, a backend test
project.

## One-ticket-at-a-time loop (the rule)

Top `todo` ticket in ROADMAP → copy fresh here → write → verify against code → mark done (date,
bump progress table) → next ticket. `docs/architecture/` is reality, `ROADMAP.md` is the plan.
