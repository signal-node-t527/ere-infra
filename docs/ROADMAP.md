# Roadmap — Documentation Buildout

Master plan for producing the `ere-infra` documentation set to the **same depth and rigor
as `LilithsTest/docs`**. Documentation *is* the product of this workstream: there is **no
application code change** except correcting the entry-point docs and removing the redundant
`DOCUMENTATION.md` (D15).

The plan has two parts:

- **Part I — Initial buildout (P0–P8): DONE.** Produced a verified **overview** of the system:
  `ARCHITECTURE.md` (~400 lines) with `file:line` evidence, plus `PROJECT_STATE.md`,
  `DECISIONS.md`, `PRODUCTION_CHECKLIST.md`, `CURRENT_TASK.md`, and corrected entry-point docs.
- **Part II — Full ARCHITECTURE coverage (P9–P14): PLANNED.** Raises `ARCHITECTURE.md` from an
  overview to an **exhaustive reference** — the node-content schema, sequence diagrams,
  per-file/per-class, per-endpoint/per-schema, per-service, per-component, and a complete
  console-command reference — targeting the depth of `LilithsTest/docs/ARCHITECTURE.md` (~830
  lines). Part II has begun and progressed: **P9, P10 and P11 are `done`** (T11.4 completes P11);
  the remaining tickets are `[ ] todo`.

This is a **forward-looking plan** — it defines what to document next and tracks progress.
`ARCHITECTURE.md` is the record of reality and is written/updated only when a documentation
phase closes, never before. `PROJECT_STATE.md` is the running snapshot; `DECISIONS.md` the
decision log; `PRODUCTION_CHECKLIST.md` the dev-seam registry; `CURRENT_TASK.md` the single
in-flight ticket.

**Workflow (one ticket at a time):** take the single top `todo` ticket, copy it into
`docs/CURRENT_TASK.md`, write the documentation, **verify every claim against the code**
(`file:line` evidence where it matters), mark `done` (with date), and bump the progress
table. The `Status:` line stays `[ ] todo [ ] in_progress [ ] done` until the ticket is
actually finished — flipping `[x] done` *is* the mark of completion. Don't pre-check a
ticket when scaffolding it.

**Kickoff-session note (2026-10-10):** the first session wrote the P1–P4 and P6 deliverables in
one pass; **T8.1 then audited every load-bearing claim against the code** and moved those tickets
to `[x] done`. The audit found and fixed three drifts — two against the code (seed counts: 17
thesis nodes and 17 thesis edges, not 16/18) and one against the file tree (the service worker is
registered in `src/index.html`, not `pwa.service.ts`); also updated `ARCHITECTURE.md` §6 now that
T7.1 has closed the entry-point-doc contradictions. Details in the T8.1 ticket. The same session
also completed **T5.1** (backfilled D7–D14) and **T8.2** (final state), so **all of P0–P8 is done**.
Remaining work is product, not docs — see `PRODUCTION_CHECKLIST.md`.

## Locked decisions (recorded as D-series in DECISIONS.md)

1. **Docs live in the root `ere-infra` repo** (`docs/`), not in either submodule: the two
   halves (`resolution-engine`, `shiny-computing-machine`) are independent git submodules
   (`.gitmodules`), and the root repo is the integration/infra layer.
2. **`ARCHITECTURE.md` reflects reality, not intent**, backed by `file:line` evidence. Where
   the shipped code contradicts the entry-point docs, the code wins and the contradiction is
   recorded (then fixed in P7; the redundant `DOCUMENTATION.md` was later removed — D15).
3. **Document code terms as they are** — do not rename anything as part of documentation.
   Notably the graph value is `"counterthesis"` with `"antithesis"` kept as a compatibility
   alias in the API layer.
4. **No code changes.** The only non-`docs/` edits this workstream makes are the P7
   corrections to `README.md` and the D15 removal of `DOCUMENTATION.md`.
5. **Quality bar = LilithsTest/docs**: per-endpoint tables, state machines where relevant,
   "known limits / gaps" sections, and a production checklist whose rows each carry a
   *production action* and a *verification*.
6. **Statuses reflect reality.** Do not pre-check tickets; do not claim a section is
   verified until it has been read against the code.
7. ~~**One `ARCHITECTURE.md`, deepened in place** (not split into `docs/architecture/*`).~~
   **SUPERSEDED by D16 (T10.5, 2026-10-10).** The reference is now the numbered folder
   `docs/architecture/` (`00_index.md` + parts), with stable `§` IDs — a single file had reached
   1477 lines (over 2× the quality bar). Part II still grows existing sections (`§3.x`, `§4.x`, …)
   and adds new top-level sections only where §1–§7 cannot absorb the topic (node-content schema,
   console-command reference, sequence diagrams, configuration/ports matrix).
8. **Part II remains docs-only and additive.** It touches only `docs/` and preserves D2 (reality
   over intent), D4 (verbatim terms), and D6 (frontend owns the graph algorithms); no source,
   config, or image changes.

## Progress

| Phase | Scope | Done | Status |
|---|---|---|---|
| P0 | Documentation scaffolding (this doc, AGENTS pointer, DECISIONS seed, CURRENT_TASK) | 1/1 | done |
| P1 | ARCHITECTURE — infrastructure & topology | 2/2 | done |
| P2 | ARCHITECTURE — backend (`resolution-engine`, .NET 9) | 4/4 | done |
| P3 | ARCHITECTURE — frontend (`shiny-computing-machine` / `purgatory-ui`, Angular 20) | 5/5 | done |
| P4 | PROJECT_STATE — snapshot + session log | 1/1 | done |
| P5 | DECISIONS — backfill the decision log | 1/1 | done |
| P6 | PRODUCTION_CHECKLIST — dev-seam registry | 1/1 | done |
| P7 | Root docs reconciliation (`README.md`, then-`DOCUMENTATION.md`) | 1/1 | done |
| P8 | Consistency audit + final state | 2/2 | done |
| P9 | ARCHITECTURE (full) — foundations & schemas | 4/4 | done |
| P10 | ARCHITECTURE (full) — backend reference | 4/4 | done |
| P10.5 | Documentation file convention & ARCHITECTURE split | 1/1 | done |
| P11 | ARCHITECTURE (full) — frontend core reference | 4/4 | done |
| P12 | ARCHITECTURE (full) — frontend feature reference | 3/8 | in_progress |
| P13 | ARCHITECTURE (full) — infra & operations reference | 0/3 | todo |
| P14 | ARCHITECTURE (full) — assurance & consistency | 0/4 | todo |

Last updated: 2026-10-10

---

## Phase 0 — Documentation scaffolding

### T0.1  Docs system scaffolding
Status: [x] done
Blocked by: —
Files: `docs/ROADMAP.md` (new, this doc), `docs/DECISIONS.md` (new, seed), `docs/CURRENT_TASK.md`
       (new), `AGENTS.md` (root, already present — verify its pointers resolve under `docs/`)
Verify: the five doc files exist; `AGENTS.md` "before starting work" list matches the real files;
        no `docs/` path referenced anywhere is missing
Notes: Done 2026-10-10. The AGENTS workflow references `docs/PROJECT_STATE.md`,
       `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/CURRENT_TASK.md`; all now exist (the
       last two plus `DECISIONS.md` from this ticket; `ARCHITECTURE.md`/`PROJECT_STATE.md`/
       `PRODUCTION_CHECKLIST.md` as first drafts). The next logical action was T8.1 (audit).

---

## Phase 1 — ARCHITECTURE: infrastructure & topology

### T1.1  §1 Repository layout & §2 System context
Status: [x] done
Blocked by: T0.1
Files: `docs/ARCHITECTURE.md` (§1 Repository Layout, §2 System Context / Data Flow)
Verify: layout matches `.gitmodules`, `.gitignore`, and the top-level tree; context diagram
        names the real components and the real ports
Notes:
- Monorepo/infra root: `ere-infra/` holds `docker-compose.yml`, `.gitmodules`, `backups/`,
  and the two submodules. Root is itself a git repo; each submodule has its own `.git/`.
- Components: browser SPA (`shiny-computing-machine`) → `resolution-engine` REST API
  (`:5250` dev, `:8080` in-container) → SQL Server 2022 (`:1433`).
- The backend resolves its DB connection **per request** from the `X-Connection-String`
  header (base64 or raw), falling back to config `DefaultConnection`, then LocalDB — a
  distinctive seam (now in `ARCHITECTURE.md` §3.4).
- `exported-plan.json` at the root is a sample data export (a nested thesis/process plan), not
  source.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §1–§2; verified in T8.1 (2026-10-10).

---

### T1.2  Infrastructure, containers & deployment topology
Status: [x] done
Blocked by: T1.1
Files: `docs/ARCHITECTURE.md` (§5 Infrastructure, containers & deployment topology)
Verify: service/port/profile/volume facts match `docker-compose.yml`; Dockerfile/nginx claims
        match the files
Notes:
- `ere-network` bridge; `mssql_data` named volume; `MSSQL_SA_PASSWORD` default `Password123!`
  (a dev-only secret — PRODUCTION_CHECKLIST row B4/infra).
- Backend Dockerfile: multi-stage `dotnet:9.0`, non-root, ports 8080/8081. Frontend prod:
  Angular build + nginx (`nginx.conf` SPA fallback + `location = /scripts/index.json`
  no-store). `Dockerfile.dev` runs node `:4250` with `--poll 2000`.
- PWA: `public/manifest.json`, `public/sw.js` (cache `resolution-engine-v3`; cache-first
  static, network-first navigations, network-only `/api/`).
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §5; verified in T8.1 (2026-10-10).

---

## Phase 2 — ARCHITECTURE: backend (`resolution-engine`, .NET 9)

### T2.1  Solution, entry point & configuration
Status: [x] done
Blocked by: T1.1
Files: `docs/ARCHITECTURE.md` (§3.1 Solution, entry point & configuration)
Verify: service registration and pipeline order match `Program.cs`; framework/package versions
        match `ResolutionEngine.csproj`
Notes:
- Single project `ResolutionEngine` (`Microsoft.NET.Sdk.Web`), **`net9.0`**,
  Nullable/ImplicitUsings enabled; packages `Microsoft.AspNetCore.OpenApi 9.0.9`,
  `Microsoft.EntityFrameworkCore[.SqlServer/.Tools] 9.0.9`.
- `Program.cs` DI: CORS policy `"AllowAngularDev"` (`SetIsOriginAllowed(_ => true)` +
  any header/method), `AddControllers` with `PropertyNameCaseInsensitive`, `AddHttpContextAccessor`,
  scoped `IConnectionProvider → HttpConnectionProvider`, `AddDbContext<ApplicationDbContext>`
  resolving the connection **per scope** and falling back to LocalDB.
- Pipeline: dev-only log → `UseCors("AllowAngularDev")` → HTTPS redirect only when **not**
  Development → `MapControllers`. **No** auth, **no** OpenAPI mapping, **no** static files.
- OpenAPI package is referenced but never wired — recorded as a gap.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §3.1; verified in T8.1 (2026-10-10).

### T2.2  API surface
Status: [x] done
Blocked by: T2.1
Files: `docs/ARCHITECTURE.md` (§3.2 API surface)
Verify: endpoint table matches `Controllers/HtnController.cs` and
        `Controllers/HtnCategoriesController.cs`; alias rules match the code
Notes:
- `HtnController` base `api/htn`: endpoints incl. `thesis-nodes`, `counterthesis-nodes`
  (`graph == "counterthesis" || "antithesis"`), `edges?graph=`, `nodes/{id}?graph=`,
  `nodes`, `nodes/{id}/content`, `DELETE nodes/{id}?graph=`, `nodes/batch-delete`, `edges`,
  `DELETE edges?from=&to=&graph=`, `migrate-graph`, `ping`, `debug-connection`.
- `HtnCategoriesController` base `api/htn-categories`: `GET /` and `POST /` (a single JSON
  blob keyed `Id == "main"`).
- No endpoint is authenticated; no plan/resource gates.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §3.2; verified in T8.1 (2026-10-10).

### T2.3  Domain model & persistence
Status: [x] done
Blocked by: T2.1
Files: `docs/ARCHITECTURE.md` (§3.3 Domain model & persistence)
Verify: model fields match `Models/*.cs`; DbSets match `Services/ApplicationDbContext.cs`; seed
        contents/counts match `Data/DbInitializer.cs`
Notes:
- `HtnNodeModel`: `Id` (string PK), `Graph`, persisted `ContentJson` exposed as
  `[NotMapped] object? Content`, persisted `LayerJson` exposed as `[NotMapped] LayerMetrics?`,
  `LayerMetrics { LongestPath, ShortestPath, Avg }`.
- `HtnEdgeModel` (int PK, FromId/ToId/Graph); `HtnCategoryDoc` (`Id == "main"`, `JsonData`).
- No `OnModelCreating`, no relationships/FKs/indexes; **no `Migrations/`** — `EnsureCreated()`
  only, and `DbInitializer.Initialize` is **not** called from `Program.cs`.
- **No custom polymorphic `JsonConverter`s exist** — content is untyped JSON (contradiction
  with the former `DOCUMENTATION.md`, corrected in T7.1).
- `Models/TestContext.cs` is an unused scaffold DbContext; `cleanup_weight_column.sql` drops a
  legacy `Weight` column.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §3.3; verified in T8.1 (2026-10-10).

### T2.4  Cross-cutting backend behavior
Status: [x] done
Blocked by: T2.1
Files: `docs/ARCHITECTURE.md` (§3.4 Cross-cutting backend behavior)
Verify: connection-header handling matches `Services/HttpConnectionProvider.cs`; JSON behavior
        matches `HtnNode.cs` + `Program.cs`
Notes:
- `HttpConnectionProvider.GetConnectionString()`: `X-Connection-String` → base64-decode (raw
  fallback) → `DefaultConnection` → empty (DbContext substitutes LocalDB).
- `debug-connection` returns the masked connection string + all request headers (security note
  → PRODUCTION_CHECKLIST B4).
- No tests exist in this project — recorded as a gap.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §3.4; verified in T8.1 (2026-10-10).

---

## Phase 3 — ARCHITECTURE: frontend (`shiny-computing-machine` / `purgatory-ui`, Angular 20)

### T3.1  Bootstrap, shell & window system
Status: [x] done
Blocked by: T1.1
Files: `docs/ARCHITECTURE.md` (§4.1 Stack, bootstrap & shell; §4.2 Shell & window system)
Verify: providers match `src/app/app.config.ts`; window behaviours match
        `features/window-system/**`
Notes:
- Angular `^20.2.2`; `package.json` name **`purgatory-ui`**; `ng serve` on port **4250**;
  `app.routes.ts` is **empty** and `<router-outlet>` is inert.
- Providers: `provideZoneChangeDetection({ eventCoalescing: true })`,
  `provideRouter(routes)`, `provideNoopAnimations()`,
  `provideHttpClient(withInterceptors([connectionInterceptor]))`.
- `AppComponent` maintains `WINDOW_REGISTRY`, renders windows via `ngComponentOutlet`; window
  system = service/manager/window/resize/reposition/dockable-panels.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §4.1–§4.2; verified in T8.1 (2026-10-10).

### T3.2  Repository & connection/state layer
Status: [x] done
Blocked by: T3.1
Files: `docs/ARCHITECTURE.md` (§4.3 Repository, connection & state layer)
Verify: endpoints match `core/repository/http.repository.ts`; base URL matches
        `core/config/app-config.ts`
Notes:
- `HtnRepository` port + `HttpHtnRepository` over `${apiUrl}/htn/...` and
  `${apiUrl}/htn-categories`; `APP_CONFIG.apiUrl` is hardcoded
  (`http://localhost:5250/api`) — production seam F1.
- `connectionInterceptor` injects base64 `X-Connection-String` unless already present.
- `HtnService` facade over `HtnStateService` / `HtnGraphService` / `HtnValidationService`.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §4.3; verified in T8.1 (2026-10-10).

### T3.3  Feature inventory
Status: [x] done
Blocked by: T3.1
Files: `docs/ARCHITECTURE.md` (§4.4 Feature inventory)
Verify: feature rows match the `src/app/features/**` tree; `WINDOW_REGISTRY` matches
Notes:
- Features: `graph-lib`, `htn-explorer`, `htn-editor`, `htn-plan`, `htn-categories`,
  `connection-string-manager`, `window-system`, `console`.
- `WINDOW_REGISTRY` maps `plan`/`explorer`/`categories`/`editor`/`console`/
  `connection-manager`/`explorer-menu`.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §4.4; verified in T8.1 (2026-10-10).

### T3.4  Console & scripting subsystem
Status: [x] done
Blocked by: T3.1
Files: `docs/ARCHITECTURE.md` (§4.5 Console & scripting subsystem)
Verify: command registry matches `console.handler.ts` + `handlers/*`; script schema matches
        `handlers/script.handler.ts` + `docs/console_script_syntax.md`
Notes:
- Parser (`console.parser.ts`), handler registry/dispatch (`console.handler.ts`), logger
  levels, `handler-context`.
- Handlers: node-crud, graph, navigation, referencer, category, integrity, view,
  config-utility, bulk-data, script.
- Script engine (`script.handler.ts`): manifest `public/scripts/index.json` generated by
  `tools/build-script-index.mjs`. Reference the shipped `docs/console_script_syntax.md`.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §4.5; verified in T8.1 (2026-10-10).

### T3.5  Domain graph algorithms, PWA, styling & tests
Status: [x] done
Blocked by: T3.1
Files: `docs/ARCHITECTURE.md` (§4.6 Domain graph algorithms, PWA, styling & tests)
Verify: algorithm names match `core/domain/graph.utils.ts`; spec count matches the tree
Notes:
- Graph logic lives here: `computeTopology`/`rebuildAdjacency`/`populateCrossReferences`/
  `refreshGraph` (`core/domain/graph.utils.ts`); `Thesis`/`Counterthesis` in
  `core/domain/models.ts`.
- PWA: `public/manifest.json`, `public/sw.js`; `core/services/pwa.service.ts`.
- Tests: **21 Jest/Karma specs**; framework contradiction (docs say Angular 18; reality 20)
  recorded for T7.1.
- **Drafted 2026-10-10** in `docs/ARCHITECTURE.md` §4.6; verified in T8.1 (2026-10-10).

---

## Phase 4 — PROJECT_STATE

### T4.1  Snapshot + first session entry
Status: [x] done
Blocked by: P1–P3
Files: `docs/PROJECT_STATE.md`
Verify: snapshot statements agree with ARCHITECTURE; dated entry matches this session
Notes: **Drafted 2026-10-10.** Captures the "stable build vs. documented reality" status: the app
       runs via compose; it has **no backend tests, no migrations, no auth**; the frontend has 21
       specs; the entry-point docs were stale. Verified in T8.1 (2026-10-10).

---

## Phase 5 — DECISIONS

### T5.1  Backfill the decision log
Status: [x] done
Blocked by: T1.1
Files: `docs/DECISIONS.md` (seed grown into a real log)
Verify: each decision cites its evidence (file/line or observed behavior)
Notes: **Done 2026-10-10.** Beyond the D1–D6 seed, added D7–D14, each with `file:line` evidence
       and cross-references to the relevant PRODUCTION_CHECKLIST rows: per-request
       `X-Connection-String` resolution (D7/B1); untyped-JSON content with **no** polymorphic
       converters (D8); `EnsureCreated()` + never-wired `DbInitializer` instead of migrations
       (D9/B2); `LayerMetrics` persisted but computed client-side (D10, with D6); hardcoded
       frontend API URL (D11/F1); empty router / dead outlet (D12); open CORS + no auth
       (D13/B4); Jasmine **and** Jest coexistence (D14).

---

## Phase 6 — PRODUCTION_CHECKLIST

### T6.1  Dev-seam registry
Status: [x] done
Blocked by: T2.4, T3.2
Files: `docs/PRODUCTION_CHECKLIST.md`
Verify: every known dev-only seam has a row with a production action + verification
Notes: **Drafted 2026-10-10.** Backend B1–B6 (connection seam, `EnsureCreated`/unwired seeding,
       LocalDB fallback, `debug-connection` + open CORS + no auth, unwired OpenAPI,
       `ASPNETCORE_ENVIRONMENT=Development`); frontend F1–F3 (hardcoded API URL, SW cache
       version, committed build logs); infra (default `MSSQL_SA_PASSWORD`, `backups/` bind,
       frontend port mapping, unpinned `:latest`, `exported-plan.json`). Verified in T8.1 (2026-10-10).

---

## Phase 7 — Root docs reconciliation

### T7.1  Correct `README.md` + `DOCUMENTATION.md`
Status: [x] done
Blocked by: P1–P6
Files: `README.md`, `DOCUMENTATION.md` (root `ere-infra/`; file removed later in D15)
Verify: frameworks, ports, endpoints, naming, and graph-logic location all match the code;
        the "custom polymorphic converters" claim is gone; the endpoint lists match T2.2
Notes: **Done 2026-10-10.** .NET 8 → **9**; Angular 18 → **20**; `purgatory-ui` package name
       noted; "custom polymorphic converters" claim removed (content is untyped JSON);
       `counterthesis` (with `antithesis` alias) documented; graph logic clarified as
       frontend; frontend dev port corrected to **4250**; both docs now point at
       `docs/ARCHITECTURE.md`.

---

## Phase 8 — Consistency audit

### T8.1  Full documentation-vs-code audit
Status: [x] done
Blocked by: P1–P7
Files: all `docs/*`
Verify: every `file:line` citation resolves; every endpoint/model/port appears once and
        matches code; no doc claims intent over reality
Notes: **Done 2026-10-10.** Re-read `ARCHITECTURE.md`, `PROJECT_STATE.md`, and
       `PRODUCTION_CHECKLIST.md` against the tree and fixed the drift found:
       - `ARCHITECTURE.md` §3.3 seed counts were wrong → corrected to **17 thesis nodes** and
         **17 thesis edges** (8 counterthesis nodes/edges were already right).
       - `ARCHITECTURE.md` §4.6 said `pwa.service.ts` registers the service worker → the SW is
         registered inline in `src/index.html:24-30`; `PwaService` only handles the install prompt.
       - `ARCHITECTURE.md` §6 item 1 described the entry-point docs as still stale → reworded now
         that T7.1 has corrected them.
       All backend/frontend/infra `file:line` citations in `ARCHITECTURE.md` were spot-checked and
       resolve; `PRODUCTION_CHECKLIST.md` rows (B1–B6, F1–F3, infra artifacts) all verified.
       Flipped P1–P4 and P6 tickets to `done`. Outstanding: `PROJECT_STATE.md` still carries a
       pre-T7.1 contradictions table and "unfinished" list → resolved in T8.2.

### T8.2  Final state
Status: [x] done
Blocked by: T8.1
Files: `docs/PROJECT_STATE.md`, `docs/CURRENT_TASK.md`, `docs/ROADMAP.md`
Verify: `PROJECT_STATE.md` is the final snapshot; `CURRENT_TASK.md` names the next action;
        the progress table matches the ticket statuses
Notes: **Done 2026-10-10.** `PROJECT_STATE.md` rewritten to the final snapshot (with the P7
       corrections table instead of the obsolete "contradictions to fix" one); `CURRENT_TASK.md`
       reset to "no open ticket — buildout complete"; the progress table below matches the ticket
       statuses. What remains is product work in `PRODUCTION_CHECKLIST.md`, not docs work.

---

# Part II — Full ARCHITECTURE coverage (P9–P14)

**Purpose.** Part I documented *what the system is*; Part II documents *how every part of it
works*, to the depth where a new engineer can navigate, extend, and operate any module from the
documentation alone. The output is the numbered folder `docs/architecture/` (§1–§7 grown, plus new
sections), keeping every load-bearing claim cited by `file:line` — see **D16** (which superseded
decision 7's "one file, deepened in place").

**Part II is in progress (P12).** Tickets are taken one at a time `[ ] todo → [x] done` (next
ticket is T12.4); this section remains the plan of record (decision 8). (Phase **P10.5/T10.5** —
the T10.5 split — sits between P10 and P11 and is done.)
When a ticket is taken, it follows the same one-at-a-time workflow as Part I.

**Scope inventory (what "full coverage" must eventually touch).**

- **Backend — 11 C# files:** `Program.cs`; `Services/{IConnectionProvider, HttpConnectionProvider,
  ApplicationDbContext}.cs`; `Controllers/{HtnController, HtnCategoriesController}.cs`;
  `Models/{HtnNode, HtnEdge, HtnCategoryDoc, TestContext}.cs`; `Data/DbInitializer.cs`. Plus config
  `appsettings*.json`, `Properties/launchSettings.json`, and artifacts `cleanup_weight_column.sql`,
  `ResolutionEngine.http`, `build_log.txt`/`build_output.txt`.
- **Frontend — 86 non-spec `.ts` files** across `core/{config,domain,repository,services}`;
  `features/{window-system, htn-plan, htn-explorer, htn-editor, htn-categories, graph-lib, console,
  connection-string-manager}`; `shared/{suggestion-input, utils}`. **11 console handlers** exposing
  **~40 commands**. Plus PWA (`public/{manifest.json, sw.js}`), `nginx.conf`,
  `tools/build-script-index.mjs`, Dockerfiles, tsconfigs, karma/jest.
- **Infra:** `docker-compose.yml` (1 network `ere-network`, 4 services, 2 profiles, 1 volume).
- **Depth bar:** `LilithsTest/docs/ARCHITECTURE.md` (~829 lines) vs the current ~400.

**Out of scope for Part II:** application code, tests, and any behaviour change (D3, D8). Findings
that look like bugs become `PRODUCTION_CHECKLIST.md` rows or §6 notes — never source edits (D2).

## Phase 9 — Full ARCHITECTURE: foundations & schemas

### T9.1  Node-content JSON schema (`content`) reference
Status: [x] done
Blocked by: —
Files: `docs/ARCHITECTURE.md` (new §3.5 "Node content schema")
Verify: every field verified against `Data/DbInitializer.cs` (seed content),
        `src/app/core/domain/types.ts` (`NodeContentRoot*`), `core/domain/constants.ts`
        (`REQUIRED_NON_FALSY_KEYS`, `GLOBAL_STANDARD_KEYS`), and
        `features/htn-editor/htn-content.service.ts`
Notes: **Done 2026-10-10.** Added `ARCHITECTURE.md` §3.5: storage/transport, common +
       thesis-only + counterthesis-only field tables (with required/default), defaults &
       normalization, validation rules, `LayerMetrics`, seed-reality mismatches, and two
       worked examples (`2bb33b4d`, `l0asd142`). Recorded that `logicalConnector`/`description`/
       `informal` are seed-only (not in `types.ts`). Also removed the redundant
       `DOCUMENTATION.md` (D15) after capturing its content.

### T9.2  Request/response lifecycle & sequence diagrams
Status: [x] done
Blocked by: T9.1
Files: `docs/ARCHITECTURE.md` (new §2.1–§2.5 "Lifecycle & sequences")
Verify: each step maps to real call sites (`file:line`)
Notes:
- **Done 2026-10-10.** Added `ARCHITECTURE.md` §2.1–§2.5, each with a Mermaid `sequenceDiagram`
  plus `file:line` anchors: §2.1 SPA bootstrap & shell; §2.2 refresh pipeline; §2.3 write path
  (`createNode`, `updateNodeContent`); §2.4 per-request `X-Connection-String` + `ping`/
  `EnsureCreated`; §2.5 popup spawn lifecycle. Cross-links added from §3.4 and §4.1–§4.3.
  Recorded two write-path observations as §6 items 9–10 (flow-`condition` default inconsistency;
  `createNode` forwards `parentGraph` to `addEdge`).
- Original scope: (a) SPA bootstrap (`main.ts` → `appConfig` → shell); (b) the refresh
  pipeline (`HtnService.refresh` → `HttpHtnRepository` `getThesisNodes`/`getCounterthesisNodes`/
  `get*Graph` → `HtnStateService` → `graph.utils` `computeTopology`/`populateCrossReferences`);
  (c) a write (`createNode`/`updateNodeContent` → `HtnGraphService.syncEdges` → `refreshAndSettle`);
  (d) the per-request `X-Connection-String` flow (interceptor → `HttpConnectionProvider` →
  `ApplicationDbContext`). Include the `ping`/`EnsureCreated` path and popup spawn.

### T9.3  Configuration, environment & ports matrix
Status: [x] done
Blocked by: —
Files: `docs/ARCHITECTURE.md` (new §5.2 "Configuration & ports matrix"; §5 split into §5.1/§5.2)
Verify: matches `appsettings*.json`, `Properties/launchSettings.json`, `docker-compose.yml`,
        `angular.json`, `package.json`
Notes: **Done 2026-10-10.** Added §5.2 with a settings matrix and a ports matrix, every cell
       citing its source line; split §5 into §5.1 (containers/images/topology) and §5.2. Corrected
       a §3.1 drift: `appsettings.json` holds a **placeholder** `DefaultConnection`,
       `appsettings.Development.json` has none, and LocalDB is only the in-code empty-string
       fallback (`Program.cs:34-37`).
Notes: one table: setting → dev value → container value → prod value → source file. Cover
       `DefaultConnection`, `ASPNETCORE_ENVIRONMENT`, `ASPNETCORE_URLS`, `MSSQL_SA_PASSWORD`, the
       CORS policy, every port (5250/7150/8080/4200/4250/1433), profile names, and volumes.

### T9.4  Glossary & domain vocabulary → code map
Status: [x] done
Blocked by: —
Files: `docs/ARCHITECTURE.md` (new §2.6 "Vocabulary & domain code map")
Verify: each term maps to a real type/value/route/file in code
Notes: Done — §2.6 table maps ERE, HTN, GraphType, thesis, counterthesis/antithesis (alias, D4),
       graph, adjacency, node, edge, layer/`LayerMetrics`, flow, trigger, effect, referencer,
       category, node content, plan/`PlanStep`, window, dock, and the `X-Connection-String`
       seam to their defining type/column/route/file. Cross-links added at §3.3, §4.4, §4.6.

## Phase 10 — Full ARCHITECTURE: backend reference

### T10.1  Per-file / per-class backend reference
Status: [x] done
Blocked by: —
Files: `docs/ARCHITECTURE.md` (new §3.6 "Source file & class reference")
Verify: one subsection per file; every public member listed; citations resolve
Notes: Done — §3.6 gives each of the 11 `.cs` files its own subsection (purpose + public members
       with signatures and `file:line`); `IConnectionProvider` and the unused `TestContext` have
       their own entries; a closing "Non-source files" table lists the csproj/sln, launchSettings,
       appsettings×2, Dockerfile/ignore files, `cleanup_weight_column.sql`, `ResolutionEngine.http`
       and the historical build logs. Values are cross-linked to §3.1–§3.5 and §5, not duplicated.

### T10.2  Endpoint reference — request/response schemas & status codes
Status: [x] done
Blocked by: T10.1
Files: `docs/ARCHITECTURE.md` (§3.2 grown)
Verify: each body/response shape matches the controller code + model serialization
Notes: Done — §3.2 now has a route index for both controllers plus a per-endpoint reference (15
       endpoints): route params/query, request body, response JSON, and every status code
       (200/204/400/404/409/500) with the exact message strings. Notes the node/edge serialized
       shapes, the PascalCase `layer` keys, the null-`graph` filter behaviour, and `ping`'s
       always-200 contract.

### T10.3  Persistence & schema reference (+ full seed dataset)
Status: [x] done
Blocked by: T10.1
Files: `docs/ARCHITECTURE.md` (§3.3 grown)
Verify: EF column/table facts match the model annotations; seed listings match `DbInitializer.cs`
Notes: Done — §3.3 now has a "Tables & columns" reference (`HtnNodes`/`HtnEdges`/`HtnCategoryDoc`
       with CLR + SQL Server types, PKs, no FKs/indexes, no DB defaults, controller-side cascade,
       and the `HtnCategoryDoc` table-name override), a "Seed dataset" section enumerating the
       full 17 thesis + 8 counterthesis nodes and 17 + 8 edges as id/label/edge tables, and the
       seed's two schema-drift keys (`logicalConnector`, `description`).

### T10.4  Cross-cutting backend behaviors
Status: [x] done
Blocked by: T10.1
Files: `docs/ARCHITECTURE.md` (§3.4 grown)
Verify: matches `HttpConnectionProvider`, `Program.cs`, and the controller try/catch blocks
Notes: Done — §3.4 now has four subsections: the connection `resolve()` pseudocode + a
       header/config/LocalDB fallback matrix; JSON round-trip rules for `ContentJson`/`LayerJson`
       and global case-insensitivity; an exception→HTTP mapping grouped by rule (CRUD 500,
       `migrate-graph`, the unguarded `UpdateNodeContent`, automatic 400 ProblemDetails, no global
       handler, `ping` always-200); and diagnostics (`ping` schema-creation side effect,
       `debug-connection` masking).

## Phase 10.5 — Documentation file convention & ARCHITECTURE split

### T10.5  Split `ARCHITECTURE.md` into `docs/architecture/` (record D16)
Status: [x] done
Blocked by: —
Files: `docs/architecture/*` (new), `docs/ARCHITECTURE.md` (deleted), `docs/DECISIONS.md` (D16),
       `docs/ROADMAP.md`, `docs/PROJECT_STATE.md`, `docs/CURRENT_TASK.md`,
       `docs/PRODUCTION_CHECKLIST.md`, `AGENTS.md`, `README.md`
Verify: concatenating the parts (minus their headers) reproduces the old body exactly; every part
        ≤600 lines; `00_index.md` maps every `§`; all pointers resolve
Notes: Done — a single 1477-line file was split into `docs/architecture/`: `00_index.md` (the §→file
       map) plus `01_overview` (§1–§2), `02_backend` (§3.1–§3.4), `03_backend_reference` (§3.5–§3.6),
       `04_frontend` (§4.1–§4.5), `05_frontend_core` (§4.6–§4.7) and `06_infrastructure` (§5–§7),
       each byte-faithful with a `Part N of M · owns §a–§b` header. **D16** records the convention
       (naming, the 150–500 / 600 budget, stable append-only `§` IDs, `00_index.md`, plan/state-doc
       exemptions) and **supersedes locked decision #7**. Entry points repointed (`AGENTS.md`,
       `README.md`, `PROJECT_STATE.md`, `CURRENT_TASK.md`, `PRODUCTION_CHECKLIST.md` F3); all
       existing `§` citations stay valid.

## Phase 11 — Full ARCHITECTURE: frontend core reference

### T11.1  Domain layer reference
Status: [x] done
Blocked by: —
Files: `docs/ARCHITECTURE.md` (§4.7 "Core domain")
Verify: matches `core/domain/{types, models, constants, htn}.ts`
Notes: Done — §4.7 documents every exported type/interface/constant with its meaning (flagging the
       module-local `Edge`/`Adjacency`/`NodeId`), the `Thesis`/`Counterthesis` construction +
       normalization rules, the `constants.ts` validation key-sets (`RuntimeRequiredKeys` /
       `NODE_ROOT_STANDARD_KEYS` are the same array), and the `htn.ts` barrel lines (with
       `graph.utils` re-exports pointing to §4.6).

### T11.2  Graph algorithms deep-dive
Status: [x] done
Blocked by: T11.1
Files: `docs/ARCHITECTURE.md` (§4.6 grown)
Verify: algorithm behavior matches `core/domain/graph.utils.ts`
Notes: Done — §4.6 now documents `rebuildAdjacency`, `computeTopology` (two phases, the cycle guard,
       unreached sentinels, `avg` always-0 and the trigger/effect overwrite realities),
       `refreshGraph`, `populateCrossReferences` (three passes, additive-only, shared id map),
       `addEdge`/`removeEdge` and `navigationRequest$`, each with `:line` cites; a worked example
       over the seed thesis graph (including its one merge node, `634e76d4` → longest 3 / shortest 1)
       and a minimal diamond.

### T11.3  Services reference
Status: [x] done
Blocked by: T11.1
Files: `docs/architecture/04_frontend.md` (§4.3 grown)
Verify: matches `core/services/*.ts`
Notes: Done — §4.3 gained a `Services reference` covering all eight `core/services/*.ts` entries
       with a public-surface table + `:line` per service: `HtnService` (façade, `settled`/
       `refreshAndSettle` contract, `createNode`/`updateNodeContent`/`importNodes`), `HtnStateService`
       (`HtnState` shape, BehaviorSubject + `shareReplay` streams, the `refresh()` normalization
       pipeline), `HtnGraphService` (`syncEdges`/`connectNodes`/`disconnectNodes`/`addCrossReference`/
       `ensureFlowEntries`/`performComplexRemoval`), `HtnValidationService` (rules + fixed messages),
       `ConnectionService` (`buildConnectionString` exact output), `connection.interceptor`,
       `StorageService` (session-vs-local + inheritance keys) and `PwaService`. Four inline realities
       recorded: `detachNode` bypasses `settled`; `performComplexRemoval`'s `'cascade'` ≡ `'recursive'`;
       `PwaService` is unwired (**new §6 item 11**); the two `condition` defaults (§6 item 9).

### T11.4  Repository layer reference
Status: [ ] todo  [ ] in_progress  [x] done
Blocked by: T11.1
Files: `docs/architecture/04_frontend.md` (§4.3 grown)
Verify: each method maps to a backend endpoint and a domain class
Notes: **Done 2026-10-10.** §4.3 gained a `Repository layer reference`: a port→impl→HTTP→
        JSON→domain table for all 11 `HtnRepository` methods plus the two class-only category
        methods (13 rows, each with a resolving `:line`); the `getGraph` shape and the
        `Thesis`/`Counterthesis` constructor mapping (`models.ts`); and an error-behaviour summary
        — only the four graph/node reads rethrow (the sole `connectionStatus$ → offline` drivers),
        all writes swallow. Two realities recorded: `HtnRepository` is never injected (the three
        consumers bind the concrete `HttpHtnRepository`) and omits the category methods (**new
        §6 item 12**); `updateNodeContent` ignores its `graphType` argument. This completes **P11**.

## Phase 12 — Full ARCHITECTURE: frontend feature reference

### T12.1  Window system reference
Status: [ ] todo  [ ] in_progress  [x] done
Blocked by: T11.1
Files: `docs/architecture/04_frontend.md` (§4.2 grown)
Verify: matches `features/window-system/**`
Notes: **Done 2026-10-10.** §4.2 grown from a bullet list into a full reference: `WindowService`
        (signals, the `addWindow`/`activateWindow`/`bringToFront`/z-index table, `shiny_window_list`
        auto-persist, the 600 z floor), `WindowManagerService` (`shiny_session_id`, `spawn`), 
        `WindowComponent` (inputs, `Ctx` geometry model, docked/focus effects, `HostBinding`,
        close-≠-remove, reposition/resize math, the 8 handle configs, dock registry lifecycle),
        `ResizeService`/`ResizeComponent` (`ResizeConfig` semantics, 3 outputs), `RepositionComponent`
        (the 1200 ms dock offer + stop detection), and `DockablePanelsService`/component + 
        `DockResizeComponent` (5 zones, request queues, DOM reparenting, mobile rules). A persistence
        & inheritance table (3 keys, all popup-excluded). One inline reality: docking reparents the
        window element and flips `docked` via the `setDocked` backdoor. **New §6 item 13**: mobile
        dock enforcement is partial (no systematic reflow; `checkMobileMode` console logs).

### T12.2  htn-plan reference
Status: [ ] todo  [ ] in_progress  [x] done
Blocked by: T11.1
Files: `docs/architecture/04_frontend.md` (§4.4 grown)
Verify: matches `features/htn-plan/**`
Notes: **Done 2026-10-10.** §4.4 gained a full `htn-plan reference`: the `'plan'` window shell +
        `WINDOW_REGISTRY` mapping (`window-registry.ts:11`), the `PlanStateService` table
        (signals `:27-33`, per-window `htn_plan_*` keys `:65-71`, bootstrap via
        `planSearchRequest$` from the explorer/categories `[Open in Plan]`, `generatePlan`
        pipeline, progress writes with `"Cycle N"` strings, analysis stage/register,
        `resetPlan`, JSON expansion round-trip), the `PlanStep`/`PendingAnalysis` model table,
        the `buildTree` loop cuts (recursion / priority-inversion / reference-loop) with
        `markLoopTargets` + `getCustomProperties` filtering, the `HtnPlanComponent` behaviours
        (effects, ≤450 px compact breakpoint, ctrl-click relative nav, set-order-only Expand
        Children, editor delegation + Referencer↔Target picker, `exportQueue` serialization,
        analysis toggling), the `wire-utils.ts` bezier overlay (ancestor/sibling resolution,
        `[data-view-id]` DOM lookups, hover highlight), and the `PlanNodeCardComponent`
        (inputs/outputs + rendering). Two realities recorded inline: the root-singleton
        `PlanStateService` makes all plan windows share one signal set, and loop progress is
        stored as `"Cycle N"` display strings (+ a `[LoopDetect]` console.log at
        `plan-utils.ts:142`).

### T12.3  htn-explorer reference
Status: [ ] todo  [ ] in_progress  [x] done
Blocked by: T11.1
Files: `docs/architecture/07_frontend_features.md` (new §4.4 owner part) +
       `docs/architecture/04_frontend.md` (§4.4 moved out), `00_index.md` (+ 07), `DECISIONS.md` (D16)
Verify: matches `features/htn-explorer/**`
Notes: **Done 2026-10-10.** Split §4.4 (feature deep dives) out of `04_frontend.md` into a new
       owning part `07_frontend_features.md` (D16 amended into a scalability protocol: owner/ref
       files, one map row per §, bold chapter bands) and removed §4.4 from 04 (04 now owns
       §4.1–§4.3, §4.5). 07 carries the moved feature-inventory table + `htn-plan reference`
       verbatim plus a full `htn-explorer reference`: the `'explorer'` window shell
       (`window-registry.ts:12`) and companion `'explorer-menu'` menu (`:17`), the per-window
       `PaneState` + name-prefixed `htn_explorer_*` keys (`htn-explorer.constants.ts:2-5`,
       `htn-explorer.component.ts:46-53`), `restoreState` + its 3 legacy-key deletions (`:334-336`),
       the data bootstrap + `htn-config-changed` skip-recursion listener (`:263-298`), `tree-utils.ts`
       (`computeMinDepths` BFS `maxDepth+1` lookahead, `buildTree` minDepth==depth+1 dedup +
       `maxSiblings` `+N more` truncation), click routing with ctrl-inverted `effectiveClickAction`
       and the referencer choice overlay, the three exclusive modes (add-child → `requestEditorSearch`
       `'create'`; rewire → `connectNodes`/`disconnectNodes`; prune → `window.confirm` +
       `pruneNodes`), the operations panel (Open in Editor/Plan, Detach, Remove Current/Subtree),
       the `activeExplorerTrees` signal → metadata menu → `navigationRequest$` path, the `<app-graph>`
       embed, and `io-utils.ts` import/export (subtree via `collectSubtreeIds` over `ady`; filenames
       `htn_thesis`/`htn_counterthesis`/`htn_graph`; import id-fill/`nodes` bucketing). Three realities
       recorded inline: explorer state is **per-window** (vs plan's root singleton), the legacy-key
       cleanup is deletion-not-migration, and import is fire-and-forget.

### T12.4  htn-editor & htn-categories reference
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T11.1
Files: `docs/architecture/07_frontend_features.md` (§4.4 grown)
Verify: matches `features/htn-editor/**`, `features/htn-categories/**`
Notes: `htn-content.service.ts` (sanitize + property CRUD) and the editor; categories CRUD and the
       `CategoryList` tree model.

### T12.5  graph-lib reference
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T11.1
Files: `docs/architecture/07_frontend_features.md` (§4.4 grown)
Verify: matches `features/graph-lib/**`
Notes: the `@swimlane/ngx-graph` wrapper (`graph.ts`, `config.ts`) and the single-node prototype
       patch.

### T12.6  connection-string-manager reference
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T11.3
Files: `docs/architecture/07_frontend_features.md` (§4.4 grown)
Verify: matches `features/connection-string-manager/**` and `ConnectionService`
Notes: the CRUD UI, the "test connection" call, and the exact connection-string builder output.

### T12.7  Console command reference (per-command table)
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T11.3
Files: `docs/architecture/04_frontend.md` (§4.5 grown)
Verify: the command list matches the `Map` keys registered by all 11 handlers; grammar matches
        `console.parser.ts`
Notes: document the parser grammar, dispatch/fallback, logger levels, and the `handler-context`
       contract; then a table of **every command** (~40) with usage string, args/flags, and effect —
       sourced from `handlers/{node-crud, graph, navigation, referencer, category, integrity, view,
       config-utility, bulk-data, script}.handler.ts`. Reference, don't duplicate,
       `console_script_syntax.md`.

### T12.8  Shared components & styling reference
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T11.1
Files: `docs/architecture/05_frontend_core.md` (§4.6 grown)
Verify: matches `shared/**` and `src/styles.scss`
Notes: `shared/suggestion-input`, `shared/utils/units-conversion`, global styling/theming, and the
       window-chrome conventions.

## Phase 13 — Full ARCHITECTURE: infra & operations reference

### T13.1  Container / image reference
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: —
Files: `docs/architecture/06_infrastructure.md` (§5 grown)
Verify: matches the Dockerfiles + `nginx.conf`
Notes: each build stage of `resolution-engine/Dockerfile` and `shiny-computing-machine/Dockerfile`
       (+ `Dockerfile.dev`), the nginx SPA/caching rules, `EXPOSE`/non-root/entrypoints, and the
       `(localdb)`-in-container warning.

### T13.2  Compose topology & container diagram
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T13.1
Files: `docs/architecture/06_infrastructure.md` (§5 grown)
Verify: matches `docker-compose.yml`
Notes: services, profiles (`dev`/`prod`), the `ere-network` bridge, `mssql_data` + `./backups`, env
       wiring, `depends_on` order, and a container-level diagram.

### T13.3  Build tooling & PWA reference
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T12.7
Files: `docs/architecture/05_frontend_core.md` (§4.6 grown)
Verify: matches `tools/build-script-index.mjs`, `package.json` scripts, tsconfigs, karma/jest,
        `public/{manifest.json, sw.js}`
Notes: the script-index generation (`npm run scripts:index`); the test setup (Karma/Jasmine + Jest
       coexistence, tsconfigs); `.eslintrc`; the PWA lifecycle (manifest + service-worker caching
       strategies + inline registration). Reference `pwa_testing_guide.md`.

## Phase 14 — Full ARCHITECTURE: assurance & consistency

### T14.1  Gaps, assumptions & unknowns register
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: P9–P13
Files: `docs/architecture/06_infrastructure.md` (§6 grown)
Verify: each item is a real observation, not speculation
Notes: fold the deep-dive findings into §6; mark anything not verifiable from code as an explicit
       assumption/unknown; route production-relevant items to `PRODUCTION_CHECKLIST.md`.

### T14.2  Full ARCHITECTURE-vs-code audit
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T14.1
Files: all `docs/*`
Verify: every `file:line` citation resolves; every inventory file appears; no intent-over-reality
Notes: re-run the T8.1 method across the expanded document (per-file, per-endpoint, per-command);
        fix drift and citations.

### T14.3  Entry-point doc symmetry
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T14.2
Files: `README.md`
Verify: it agrees with the expanded `docs/architecture/`; pointers correct
Notes: refresh the entry-point doc's summaries/pointers to the deeper sections (docs-only edit,
       consistent with D3/P7).

### T14.4  Final state refresh
Status: [ ] todo  [ ] in_progress  [ ] done
Blocked by: T14.3
Files: `docs/PROJECT_STATE.md`, `docs/CURRENT_TASK.md`, `docs/ROADMAP.md`
Verify: `PROJECT_STATE.md` is the final snapshot; `CURRENT_TASK.md` names the next action; the
        progress table matches statuses
Notes: close out Part II the same way T8.2 closed Part I.
