# ERE — Architecture

> **Status: audited (2026-10-10, ROADMAP T8.1).** Written against the code as it exists today;
> every load-bearing claim cites `file:line`, and the T8.1 audit re-read each claim against the
> tree. This document is the record of **reality**, not intent; where the entry-point docs
> disagreed with the code, the code won (recorded in §6 and fixed in T7.1; the redundant
> `DOCUMENTATION.md` was then removed — D15).

> ERE (Explicit Resolution Engine) models and resolves complex problems as a **dialectic
> graph**: **Thesis** nodes (structures/regularities) and **Counterthesis** nodes
> (processes/flows). It is an infra monorepo whose two halves are independent git submodules:
> `resolution-engine` (.NET 9 ASP.NET Core API over SQL Server via EF Core) and
> `shiny-computing-machine` (package name **`purgatory-ui`** — an Angular 20 signal-heavy SPA
> with a custom window system). The graph algorithms live in the **frontend**.

## 1. Repository Layout

```
ere-infra/                         # integration/infra root — itself a git repo
├── AGENTS.md                      # workflow / context-management rules
├── README.md                      # entry-point doc (corrected in T7.1)
├── docker-compose.yml             # the whole stack (db / backend / frontend-prod|dev)
├── .gitmodules                    # declares the two submodules
├── backups/                       # bind-mounted into the db container
├── exported-plan.json             # sample data export (nested thesis/process plan)
├── resolution-engine/             # submodule — .NET 9 backend (own .git/)
├── shiny-computing-machine/       # submodule — Angular 20 frontend (own .git/)
└── docs/                          # THIS documentation set
    ├── ARCHITECTURE.md            # this file
    ├── PROJECT_STATE.md
    ├── ROADMAP.md
    ├── DECISIONS.md
    ├── CURRENT_TASK.md
    └── PRODUCTION_CHECKLIST.md
```

The two halves are independently versioned: each submodule has its own `.git/` and is wired in
via `.gitmodules`; the root repo is the only place that sees the whole system (D1).

- **`resolution-engine`** — REST API; dev host `http://localhost:5250`, in-container `:8080`.
- **`shiny-computing-machine`** — browser SPA (project/package `purgatory-ui`); dev server
  `:4250` (`npm start`, `package.json:8`), production served by nginx on `:4200→80`.
- **SQL Server 2022** — container `:1433`, named volume `mssql_data`.

## 2. System Context / Data Flow

```
                         ┌──────────────────────────────────────────────┐
                         │        browser SPA: purgatory-ui             │
                         │  Angular 20 · signals · window system        │
                         │  graph algorithms (core/domain/graph.utils)  │
                         └───────────────┬──────────────────────────────┘
                                         │ HTTP/JSON
                                         │ X-Connection-String: <base64 or raw conn string>
                                         ▼
                         ┌──────────────────────────────────────────────┐
                         │        resolution-engine (.NET 9)            │
                         │  Controllers → EF Core (ApplicationDbContext)│
                         │  connection resolved PER REQUEST             │
                         └───────────────┬──────────────────────────────┘
                                         │ SQL (Microsoft.Data.SqlClient)
                                         ▼
                         ┌──────────────────────────────────────────────┐
                         │   SQL Server 2022 (Docker :1433)             │
                         │   HtnNodes · HtnEdges · HtnCategoryDoc       │
                         └──────────────────────────────────────────────┘
```

Load-bearing facts:

- **The DB connection is resolved per request.** The SPA may attach an `X-Connection-String`
  header (base64 or raw) on every call; the backend prefers it, then falls back to config
  `DefaultConnection`, then to LocalDB. This is the distinctive multi-tenant / multi-database
  seam and the reason a DbContext is built per scope (`resolution-engine/Program.cs:28-40`,
  `resolution-engine/Services/HttpConnectionProvider.cs:18-42`). See §3.4.
- **The graph algorithms live in the SPA, not the backend.** Topological layering and
  thesis/counterthesis cross-reference population are in
  `shiny-computing-machine/src/app/core/domain/graph.utils.ts` (D6). The backend only stores
  nodes/edges and an opaque `layer` blob.
- **No authentication anywhere.** There are no identity, token, or CORS-restriction seams; the
  API is open (see §6).
- `exported-plan.json` at the root is a sample data export (a nested thesis/process plan), not
  source.

## 3. Backend — `resolution-engine`

### 3.1 Solution, entry point & configuration

Single project, `Microsoft.NET.Sdk.Web`, target **`net9.0`**, Nullable + ImplicitUsings enabled
(`resolution-engine/ResolutionEngine.csproj:1-7`). Packages: `Microsoft.AspNetCore.OpenApi`
9.0.9, `Microsoft.EntityFrameworkCore` / `.SqlServer` / `.Tools` 9.0.9
(`ResolutionEngine.csproj:10-16`).

`Program.cs` (top-level statements) registers:

- **CORS** policy `"AllowAngularDev"` — `SetIsOriginAllowed(_ => true)` + any header/any method
  (`Program.cs:7-16`). Effectively wide open in every environment.
- `AddControllers()` with `PropertyNameCaseInsensitive = true` on the JSON options
  (`Program.cs:18-22`).
- `AddHttpContextAccessor()` and a **scoped** `IConnectionProvider → HttpConnectionProvider`
  (`Program.cs:24-25`).
- `AddDbContext<ApplicationDbContext>` whose options delegate runs **per scope** and reads the
  connection string from `IConnectionProvider`, substituting a **LocalDB** string when the
  provider yields empty (`Program.cs:28-40`).

Pipeline (`Program.cs:42-58`): dev-only `Console.WriteLine` → **`UseCors("AllowAngularDev")`**
→ `UseHttpsRedirection()` **only when not Development** → `MapControllers()`. There is
**no** authentication, **no** OpenAPI mapping (`AddOpenApi`/`MapOpenApi` are never called even
though the package is referenced), and **no** static-file serving.

`launchSettings.json` exposes http `:5250` and https `:7150`. `appsettings*.json` hold the
`DefaultConnection`; the dev value points at LocalDB, the container overrides it via the
`ConnectionStrings__DefaultConnection` env var (see §5).

### 3.2 API surface

Two controllers, both `[ApiController]`, controller-routed. All endpoints are unauthenticated.

**`HtnController` — base `api/htn`** (`resolution-engine/Controllers/HtnController.cs`):

| Method | Route | Purpose | Evidence |
|---|---|---|---|
| GET | `thesis-nodes` | All nodes where `Graph == "thesis"` | `HtnController.cs:18-23` |
| GET | `counterthesis-nodes` | All nodes where `Graph == "counterthesis"` **or** `"antithesis"` (alias) | `HtnController.cs:25-30` |
| GET | `edges?graph=` | Edges for a graph; `graph=counterthesis` also returns `"antithesis"` rows | `HtnController.cs:32-37` |
| GET | `nodes/{id}?graph=` | Single node, same alias rule | `HtnController.cs:100-109` |
| POST | `nodes` | Create node; generates a GUID id when blank; 409 when the id exists | `HtnController.cs:111-134` |
| POST | `nodes/{id}/content` | Replace a node's `content` (setter re-serializes to `ContentJson`) | `HtnController.cs:39-53` |
| DELETE | `nodes/{id}?graph=` | Delete node **+ cascade its edges** (both directions) | `HtnController.cs:136-159` |
| POST | `nodes/batch-delete?graph=` | Delete many nodes + their edges | `HtnController.cs:161-192` |
| POST | `edges` | Create edge; 409 if duplicate; 400 if either endpoint is missing in the graph | `HtnController.cs:194-220` |
| DELETE | `edges?from=&to=&graph=` | Delete one edge | `HtnController.cs:222-241` |
| POST | `migrate-graph` | `ExecuteUpdate` rewrite `antithesis → counterthesis` on nodes + edges; returns counts | `HtnController.cs:243-273` |
| GET | `ping` | Health probe; calls `EnsureCreated()` then `CanConnect()` | `HtnController.cs:55-87` |
| GET | `debug-connection` | Returns the connection string (password regex-masked) + all request headers | `HtnController.cs:89-98` |

**`HtnCategoriesController` — base `api/htn-categories`**
(`resolution-engine/Controllers/HtnCategoriesController.cs`): `GET /` returns the JSON blob for
`Id == "main"` (default `"[]"` when absent, `:18-27`); `POST /` upserts that single row,
re-serializing the bound body to a string (`:29-59`). There is exactly one category document
keyed `"main"` (`Models/HtnCategoryDoc.cs:10`).

Cross-cutting endpoint behaviour:

- **Cascade deletes** are manual (`RemoveRange` on matching edges before removing nodes), not
  DB FKs — the model has no relationships (§3.3).
- **Alias kept only in the API layer.** `"counterthesis"` is canonical; the `"antithesis"`
  alias is accepted and matched on read paths and `migrate-graph` rewrites persisted rows
  (D4).
- **No resource-level validation** beyond edge endpoint existence; node `content` is accepted
  as-is.
- **No plan/role gates, no pagination, no filtering** beyond the `graph` query parameter.

### 3.3 Domain model & persistence

`Models/HtnNode.cs`:

- `HtnNodeModel.Id` — `string` PK, JSON name `id` (`HtnNode.cs:9-11`).
- `Graph` — `string` (`"thesis"` / `"counterthesis"`) (`HtnNode.cs:13-14`).
- **`ContentJson`** — persisted `string` (default `"{}"`), `[JsonIgnore]` (`HtnNode.cs:17-18`),
  exposed as a `[NotMapped] object? Content` that (de)serializes with `System.Text.Json`
  (`HtnNode.cs:20-28`). Content is **untyped JSON** — there are **no custom polymorphic
  converters** (the former `DOCUMENTATION.md` claimed these; see §6).
- **`LayerJson`** — persisted `string`, exposed as `[NotMapped] LayerMetrics? Layer`
  (`HtnNode.cs:30-40`). `LayerMetrics { LongestPath:int, ShortestPath:int, Avg:double }`
  (`HtnNode.cs:45-50`). Layers are **persisted**, but computed by the **frontend** (D6).

`Models/HtnEdge.cs`: `HtnEdgeModel.Id` (int PK), `FromId`, `ToId`, `Graph`
(`HtnEdge.cs:5-19`).

`Models/HtnCategoryDoc.cs`: `[Table("HtnCategoryDoc")]`, `Id` default `"main"`, `JsonData`
default `"[]"` (`HtnCategoryDoc.cs:6-12`).

`Services/ApplicationDbContext.cs`: `DbSet`s `HtnNodes`, `HtnEdges`, `HtnCategories`
(`ApplicationDbContext.cs:12-14`). There is **no `OnModelCreating`**, so keys come from data
annotations, there are **no relationships / FKs / indexes**, and cascade behaviour is entirely
in the controllers.

**Schema creation = `EnsureCreated()`, not migrations.** There is **no `Migrations/` folder**.
`Data/DbInitializer.Initialize` calls `EnsureCreated()` then seeds
(`DbInitializer.cs:8-10`), and the `ping` endpoint also calls `EnsureCreated()`
(`HtnController.cs:68`). Critically, **`DbInitializer.Initialize` is never called from
`Program.cs`** — seeding only runs if something invokes it. In practice a fresh container DB
is created empty by `ping`, and **no demo data appears unless `Initialize` is run manually**
(verified in T8.1). The seed itself defines **17 thesis nodes**,
**8 counterthesis nodes**, and **17 thesis edges + 8 counterthesis edges**
(`DbInitializer.cs:26-147`); thesis content carries `label`/`logicalConnector`/`description`/
`flow`/`countertheses`, counterthesis content adds `theses` and optional `informal`
(`DbInitializer.cs:155-195`). The full field-by-field schema is §3.5.

`Models/TestContext.cs` is an **unused** scaffold `DbContext` bound to
`Name=DefaultConnection` (`TestContext.cs:18-19`).

Because `EnsureCreated()` never alters an existing schema, the repo carries
`cleanup_weight_column.sql` — evidence that a legacy `Weight` column had to be dropped by hand.

### 3.4 Cross-cutting (backend)

- **Per-request connection resolution** (`Services/HttpConnectionProvider.cs`):
  `GetConnectionString()` returns the config `DefaultConnection` when there is no HTTP context
  (`:20-21`); otherwise it reads header `X-Connection-String`, tries base64-decode → UTF-8 and
  falls back to the raw header text on failure (`:23-39`); finally falls back to
  `DefaultConnection` (`:41`). The DbContext delegate substitutes LocalDB when this is empty
  (`Program.cs:34-37`). This is what lets the SPA point the API at an arbitrary SQL Server.
- **Serialization**: global `PropertyNameCaseInsensitive` (`Program.cs:21`); content
  round-trips as a JSON DOM (`JsonElement` on read, re-serialized on write); no discriminators.
- **Diagnostics / security**: `debug-connection` masks `Password=…` but still returns the
  connection string and echoes **every request header** (`HtnController.cs:89-98`) — a
  production-checklist item (B4).
- **No tests** exist in this project (contrast the frontend's 21 specs) — a gap (§6).
- Non-runtime artifacts at the backend root: `build_log.txt` / `build_output.txt` (historical
  `MSB3026` file-lock build failures from a running `ResolutionEngine.exe`), and
   `ResolutionEngine.http` (a template with a stale `weatherforecast` sample). None are runtime.

### 3.5 Node content schema (`content`)

(ROADMAP T9.1.) Node payloads are **untyped JSON** (D8). The persisted `HtnNodeModel.ContentJson`
string (`Models/HtnNode.cs:17-18`) is exposed as `[NotMapped] object? Content`
(`HtnNode.cs:20-28`): reads yield a `JsonElement` DOM, writes re-serialize with
`System.Text.Json`, and property names deserialize case-insensitively (`Program.cs:21`). There is
**no** discriminator, type registry, or `JsonConverter`. The schema below is the de-facto contract
shared by the seed (`Data/DbInitializer.cs:155-195`), the SPA types
(`core/domain/types.ts:42-105`), its templates/defaults
(`core/domain/constants.ts:3-57`, `core/domain/models.ts:9-46`), the editor cleanup
(`features/htn-editor/htn-content.service.ts:117-165`), and the validator
(`core/services/htn-validation.service.ts:8-82`).

Conventions: keys are camelCase; `flow` is an object **keyed by the parent node id**; list fields
hold **node ids** (same graph unless noted).

**Common fields** (`NodeContentRoot`, `types.ts:44-50`)

| Key | Type | Required | Default | Notes |
|---|---|---|---|---|
| `label` | string | yes | `''` | must be non-empty (`htn-validation.service.ts:28`); in `REQUIRED_NON_FALSY_KEYS` (`constants.ts:54-57`) |
| `triggers` | string[] | no | `[]` | node refs; integrity-checked (`integrity.handler.ts:74-83`) |
| `effects` | string[] | no | `[]` | node refs; integrity-checked (`integrity.handler.ts:76-86`) |
| `refId` | string | no | `''` | meaningful only when `type == "referencer"`; cleared otherwise (`htn-content.service.ts:66-72,157-162`) |
| `referencers` | string[] | no | `[]` | **computed** by `populateCrossReferences` (`graph.utils.ts:94-140`); not authored |

**Thesis-only** (`NodeContentRootThesis`, `types.ts:80-85`; template `constants.ts:3-13`)

| Key | Type | Required | Default | Notes |
|---|---|---|---|---|
| `flow` | `Record<parentId, FlowStateThesis>` | yes | `{}` | one entry per parent edge (`htn-validation.service.ts:14-23`) |
| `countertheses` | string[] | no | `[]` | cross-graph refs to counterthesis ids |
| `type` | `"data"/"process"/"referencer"` | no | `"process"` | `NODE_TYPES` (`types.ts:9`) |
| `justification` | string | yes | `''` | non-falsy (`REQUIRED_NON_FALSY_KEYS`) |

`FlowStateThesis` (`types.ts:78`) = `{ condition: string, priority: number }`; `priority` must be
a non-negative integer (`htn-validation.service.ts:44-48`).

**Counterthesis-only** (`NodeContentRootCounterthesis`, `types.ts:69-76`; template `constants.ts:15-26`)

| Key | Type | Required | Default | Notes |
|---|---|---|---|---|
| `flow` | `Record<parentId, FlowStateCounterthesis>` | yes | `{}` | as above |
| `theses` | string[] | no | `[]` | cross-graph refs to thesis ids |
| `state` | `"W"/"B"/"A"/"S"` | no | `"W"` | `STATE_OPTIONS` (`types.ts:17`) |
| `executionOrder` | `"unit"/"set"` | no | `"unit"` | `EXECUTION_ORDER_OPTIONS` (`types.ts:20`) |
| `type` | `"data"/"process"/"referencer"` | no | `"process"` | as thesis |

`FlowStateCounterthesis` (`types.ts:61-67`) adds to `FlowStateThesis`: `completed: boolean` and
`completedCondition: string` (both required — `htn-validation.service.ts:50-57`), plus optional
`cycles?: string[]` and `analyzes?: { timestamp, analysis }[]`.

**Defaults & normalization**

- `Thesis`/`Counterthesis` constructors (`models.ts:9-46`) fill `triggers`/`effects` and the
  cross-ref list from constructor args when content is empty, normalize `layer` (number →
  `{longestPath,shortestPath,avg}`), and default `state`/`executionOrder`/`type`.
- `HtnContentService.cleanupContent` (`htn-content.service.ts:117-165`): coerces a blank
  `priority` to `0`, defaults `condition` to `"next"` for counterthesis (else `""`), fills
  `completed`/`completedCondition` for counterthesis, strips counterthesis-exclusive keys from a
  thesis node, and clears `refId` when `type != "referencer"`.
- `getDefaultContent` (`htn-validation.service.ts:64-82`) seeds a new child's `flow[parentId]`
  with `{ priority: 1, condition }` (+ `completed`/`completedCondition` for counterthesis).

**`LayerMetrics`** are stored separately, not inside `content`: `LayerJson` → `[NotMapped]
LayerMetrics { LongestPath, ShortestPath, Avg }` (`HtnNode.cs:30-50`); the SPA type uses
camelCase `longestPath`/`shortestPath`/`avg` (`types.ts:87-91`). Computed client-side (D6/D10).

**Seed reality.** Thesis content (`DbInitializer.cs:155-173`) writes `label`, `logicalConnector`
(`"AND"`), `description`, `flow`, `countertheses`. Counterthesis content (`:175-195`) writes
`label`, `logicalConnector`, `description`, `flow`, `theses`, and optional `informal`. The seed
therefore **omits** `triggers`, `effects`, `refId`, `referencers`, `type`, `justification`
(thesis) and `type`, `refId` (counterthesis); the SPA tolerates the gaps by normalizing on read.
Conversely `logicalConnector`, `description`, and `informal` appear in the seed (and in entries
the SPA round-trips) but are **not** modelled in `types.ts` — `logicalConnector` survives only in
the console `purge-prop` example (`config-utility.handler.ts:38`). These mismatches are recorded,
not fixed (§6).

**Worked examples** (verbatim seed, compacted):

- Thesis `2bb33b4d` (`DbInitializer.cs:31`):
  ```json
  {"label":"Agent Resolution","logicalConnector":"AND","description":"The root state...",
   "flow":{},"countertheses":["7ef4e6da"]}
  ```
- Counterthesis `l0asd142` (`DbInitializer.cs:78-79`):
  ```json
  {"label":"Functional Iteration HTN/Chain Triggered Loops (CTL)","logicalConnector":"AND",
   "description":"Migrated from connection\n\n T_MIGRATED",
   "flow":{"7ef4e6da":{"priority":5,"condition":"","completed":false}},
   "theses":["if1s1g4","asd9aj294"]}
  ```

## 4. Frontend — `shiny-computing-machine` (`purgatory-ui`)

### 4.1 Stack, bootstrap & shell

- **Angular `^20.2.2`**, TypeScript `~5.9.2`, RxJS `~7.8.2`, `@swimlane/ngx-graph ^11.0.0`,
  `zone.js ~0.15.1`; dev tooling includes **both** Jasmine/Karma and Jest (`package.json:17-48`).
  The Angular project (and build output `dist/purgatory-ui`) is named **`purgatory-ui`**
  (`angular.json:6,20`); `npm start` serves on **`:4250`** (`package.json:8`, `angular.json:75`).
- `main.ts` → `bootstrapApplication(AppComponent, appConfig)` (zone-based, **not** zoneless).
  `app.config.ts` providers (`app.config.ts:10-16`): `provideZoneChangeDetection({ eventCoalescing: true })`,
  `provideRouter(routes)`, `provideNoopAnimations()`,
  `provideHttpClient(withInterceptors([connectionInterceptor]))`.
- **Routing is effectively unused**: `app.routes.ts` exports an **empty** array
  (`app.routes.ts:3`), so the `<router-outlet />` in `app.component.html:17` is inert.
- `AppComponent` (`src/app/app.component.ts`) is the shell: it reads `WINDOW_REGISTRY`,
  renders each open window via `ngComponentOutlet` with inputs `windowName`/`windowType`
  (`app.component.html:11-14`), hosts the dockable panels, the console button, and the
  connection-status warning line (`.warning`, `app.component.html:5-6`). It also detects
  **popup windows** via `/popup` or a `spawnType` query param
  (`app.component.ts:36-61`).
- The `WINDOW_REGISTRY` maps a window type → standalone component
  (`core/config/window-registry.ts:10-18`): `plan`, `explorer`, `categories`, `editor`,
  `console`, `connection-manager`, `explorer-menu`.

### 4.2 Window system

The window system (`features/window-system/**`) is the core UI abstraction:

- `window.service.ts` — the open-window list (a `signal`, persisted under `shiny_window_list`),
  z-order/activation, `addWindow`/`activateWindow`/`bringToFront`.
- `window-manager.service.ts` — **real browser popups** (`?spawnType=&spawnName=`), session id
  `shiny_session_id`, and window inheritance.
- `window.component.ts` — 8-handle resize + reposition drag + close.
- `resize/resize.service.ts` — px/percent sizing; `reposition/reposition.component.ts` — a drag
  longer than ~1.2 s offers docking.
- `dockable-panels/dockable-panels.service.ts` — dock zones (left/right/top/bottom/center) and
  a mobile dock mode.
- `core/services/storage.service.ts` — **sessionStorage** in popups (detected via the `/popup`
  path, `window.opener`, or `spawnType`), otherwise **localStorage**, with an inheritance
  fallback that excludes internal keys.

### 4.3 Repository, connection & state layer

- **Repository port + HTTP impl**: `core/repository/htn.repository.ts` defines `HtnRepository`
  with node/graph/edge CRUD (`htn.repository.ts:4-23`); `core/repository/http.repository.ts`
  implements `HttpHtnRepository` against `${apiUrl}/htn/...` and `${apiUrl}/htn-categories`
  (`http.repository.ts:20,45,77,105,117,130,140,149,159,171,182,191`) and maps raw JSON into the
  `Thesis`/`Counterthesis` domain classes (`core/domain/models.ts`).
- **Base URL is hardcoded**: `APP_CONFIG.apiUrl = 'http://localhost:5250/api'`
  (`core/config/app-config.ts:1-3`). There are **no environment files** — a production seam
  (F1).
- **Connection interceptor**: `core/services/connection.interceptor.ts` injects a base64
  `X-Connection-String` header on every request unless one is already present
  (`connection.interceptor.ts:5-25`) — the client half of §3.4.
- **Connection management**: `core/services/connection.service.ts` holds connection configs in a
  signal, persisted under `shiny_connections` / `shiny_active_connection_id`
  (`connection.service.ts:21-22`), and builds the connection string
  (`connection.service.ts:95-109`).
- **State**: `core/services/htn-state.service.ts` holds thesis/counterthesis node maps + graphs
  and categories (BehaviorSubject + signals); `core/services/htn.service.ts` is the facade
  (`HtnService`) exposing `state$`, `connectionStatus$`, `refresh()`, `createNode`,
  `updateNodeContent`, `removeNode`/`removeRecursive`/`removeSubtree`, `connectNodes`,
  `importNodes`, etc. (`htn.service.ts:19-345`). `htn-graph.service.ts` handles edge syncing
  (`syncEdges`) and cross-reference creation. `htn-validation.service.ts`
  (`validateNodeContent`) enforces flow-parent and label rules via
  `core/domain/constants.ts` (`REQUIRED_NON_FALSY_KEYS`, `GLOBAL_STANDARD_KEYS`).

### 4.4 Feature inventory

| Feature (`src/app/features/…`) | Role |
|---|---|
| `graph-lib` | `@swimlane/ngx-graph` wrapper + a single-node prototype patch (`graph.ts`, `config.ts`). |
| `htn-explorer` | Hierarchical tree view (`tree-utils.ts` `computeMinDepths`/`buildTree`), import/export (`io-utils.ts`), metadata menu. |
| `htn-editor` | Form editor for node content (`htn-content.service.ts` sanitize + property CRUD). |
| `htn-plan` | The "plan" view: `plan-state.service.ts`, `plan.types.ts` (`PlanStep`/`PendingAnalysis`), `plan-utils.ts` (`getCustomProperties`), `wire-utils.ts` (bezier), `plan-node-card` (presentational). |
| `htn-categories` | Category-tree CRUD (`CategoryList`, `core/domain/types.ts:107-116`). |
| `connection-string-manager` | UI to CRUD connection configs + test the active connection. |
| `window-system` | The window/dock/resize/reposition system (§4.2). |
| `console` | The scripting shell (§4.5). |

Domain types live in `core/domain/types.ts` — `GraphType`, `NODE_TYPES` (`data`/`process`/
`referencer`), `STATE_OPTIONS` (`W`/`B`/`A`/`S`), `EXECUTION_ORDER_OPTIONS` (`unit`/`set`),
`LayerMetrics`, `CategoryList`, etc. (`types.ts:7-153`); the barrel is `core/domain/htn.ts`.

### 4.5 Console & scripting subsystem

- **Parser** (`features/console/console.parser.ts`): quoted sections, `--flags`, `key=value`,
  positionals → `ParsedCommand`.
- **Dispatch** (`features/console/console.handler.ts`): a `Map<string, CommandAction>` built
  from handler factories (`console.handler.ts:121-136`): node-crud, navigation, graph,
  bulk-data, category, integrity, view, config-utility, referencer, **script**
  (`console.handler.ts:13-22`). Unknown commands that match a window type open a window;
  otherwise they activate an existing window or log an error (`console.handler.ts:183-209`).
  The handler context exposes the services + live state mirrors + log helpers
  (`console.handler.ts:139-172`).
- **Logger** (`features/console/console-logger.service.ts`): level-tagged output
  (info/success/warn/error/header/usage), HTML escaping, id formatting.
- **Script engine** (`features/console/handlers/script.handler.ts`): runs
  `{ name, description, vars, steps[] }` (or bare steps); guards `online|offline|exists:<id>|
  missing:<id>`; `${var}` interpolation; options `--confirm`/`--dry-run`/`--continue-on-error`/
  `--settle=<ms>`. A manifest (`public/scripts/index.json`, cache-busted) is generated at build
  by `tools/build-script-index.mjs` and wired through the `scripts:index` npm script
  (`package.json:6-13`). The shipped reference is
  `shiny-computing-machine/docs/console_script_syntax.md` — this doc does not duplicate it.

### 4.6 Domain graph algorithms, PWA, styling & tests

**Graph algorithms live here** (D6): `core/domain/graph.utils.ts` implements `rebuildAdjacency`
(`:6-17`), `computeTopology` — longest/shortest-path layering + trigger/effect synthesis
(`:19-85`), `refreshGraph` (`:87-92`), `populateCrossReferences` — bidirectional
thesis↔counterthesis linking (`:94-140`), `addEdge`/`removeEdge` (`:142-153`), and the
`navigationRequest$` subject (`:4`). `core/domain/models.ts` `Thesis`/`Counterthesis` normalize
`layer` and default content fields (`models.ts:3-46`).

- **PWA**: `public/manifest.json` (name "ResolutionEngine", standalone, `#111` background);
  `public/sw.js` with cache `resolution-engine-v3` — cache-first static, network-first
  navigations (fallback `/index.html`), network-only `/api/`, and a bypass for Vite/HMR paths
  (`sw.js:1,38-76`). The service worker is registered inline in `src/index.html:24-30`;
  `core/services/pwa.service.ts` only handles the `beforeinstallprompt`/`appinstalled` install
  prompt. Reference: `shiny-computing-machine/docs/pwa_testing_guide.md`.
- **Styling**: global Quicksand in `src/styles.scss`, per-component SCSS, black full-viewport
  workspace.
- **Tests**: **21 spec files** (Jasmine/Karma + Jest coexistence) —
  window.service, window.component, resize.service, resize.component, reposition.component,
  dockable-panels, dockable-panels.service, console, console.parser, console-btn,
  view.handler, script.handler, connection-string-manager, htn-plan, htn-validation.service,
  htn-graph.service, htn-explorer, htn-editor, htn-categories, graph, app.component.
- **Dead scaffolding to record**: `verify_graph.ts` (+ `tsconfig.verify.json`), top-level
  `build_error*.log` / `pure.txt` artifacts, and a stray marker in `.eslintrc.js`.

## 5. Infrastructure, containers & deployment topology

`docker-compose.yml` (root) defines one network `ere-network` (bridge) and four services:

| Service | Image / build | Ports | Profile | Notes |
|---|---|---|---|---|
| `db` | `mcr.microsoft.com/mssql/server:2022-latest` | `1433:1433` | — | `MSSQL_SA_PASSWORD` defaults to `Password123!` (`:7`); volume `mssql_data` + bind `./backups` (`:13-14`). |
| `backend` | build `./resolution-engine` | `5250:8080` | — | `ASPNETCORE_ENVIRONMENT=Development`, `ASPNETCORE_URLS=http://+:8080`, `ConnectionStrings__DefaultConnection=Server=db;…;Password=${MSSQL_SA_PASSWORD}` (`:21-24`). |
| `frontend-prod` | build `./shiny-computing-machine` (Dockerfile) | `4200:80` | `prod` | Angular build → nginx. |
| `frontend-dev` | build `./shiny-computing-machine` (Dockerfile.dev) | `4250:4250` | `dev` | bind-mount source + anonymous `/app/node_modules`; `--poll 2000` (`Dockerfile.dev:17`). |

**Backend `Dockerfile`** (`resolution-engine/Dockerfile`): multi-stage, `mcr.microsoft.com/dotnet/sdk:9.0`
build → `aspnet:9.0` runtime, `EXPOSE 8080 8081`, runs as the non-root `$APP_UID` (`:21`). Its
header comment warns that `(localdb)` strings do not work in-container.

**Frontend `Dockerfile`** (`shiny-computing-machine/Dockerfile`): `node:20-alpine` build
(`npm ci` + `npm run build -- --configuration production`) → `nginx:stable-alpine`, copying
`/app/dist/purgatory-ui/browser` to the web root (`:26`). `nginx.conf` is an SPA config:
`try_files … /index.html`, 6-month caching for static assets, and an exact-match
`location = /scripts/index.json` with `no-store` so the regenerated script manifest is never
cached (`nginx.conf:7-23`).

## 6. Known limits / gaps (current behaviour, not intent)

These are documented as reality; most become PRODUCTION_CHECKLIST rows or future tickets. The
subset that contradicts the entry-point docs is corrected in T7.1.

1. **The entry-point docs *were* stale (fixed in T7.1, 2026-10-10).** Before that, `README.md`
   and the now-removed `DOCUMENTATION.md` (D15) claimed .NET **8** and Angular **18**; the code
   is .NET **9** (`ResolutionEngine.csproj:4`) and Angular **20** (`package.json:18`). The former
   file also claimed "custom polymorphic converters" (**none exist** — content is untyped JSON,
   §3.3/§3.5), named the endpoint `antithesis-nodes` (it is `counterthesis-nodes`, with
   `antithesis` as an alias, §3.2), and placed topological analysis in the backend (it is in the
   frontend, §4.6). All of these are corrected, and the redundant file is gone.
2. **No authentication / authorization** on any backend endpoint, and CORS is fully open
   (`Program.cs:12`). Combine with `debug-connection` exposing masked connection strings and all
   request headers (`HtnController.cs:89-98`).
3. **No migrations and unwired seeding.** Schema comes from `EnsureCreated()`; there is no
   `Migrations/`, and `DbInitializer.Initialize` is never called from `Program.cs`, so a fresh
   container DB starts empty. `EnsureCreated` cannot evolve an existing schema (hence
   `cleanup_weight_column.sql`).
4. **No backend tests.** The frontend has 21 specs; the backend has none.
5. **Reference data is stringly-typed.** Graph kind, `type`, `state`, etc. are untyped JSON
   strings in the DB; there are no enum columns, FKs, or indexes.
6. **Hardcoded frontend API URL** (`core/config/app-config.ts:2`) with no environment
   replacement — the prod build still targets `localhost:5250`.
7. **Empty router / dead outlet.** `app.routes.ts` is empty and `<router-outlet />` renders
   nothing; the whole app is one shell.
8. **Two test frameworks coexist** (Jasmine/Karma and Jest) — see `package.json:36-46` and the
   Jest builder in `angular.json:82-89`.

## 7. Pointers

- Decisions behind these facts: `docs/DECISIONS.md` (D1–D15).
- Dev-only seams that must be swapped/verified before production: `docs/PRODUCTION_CHECKLIST.md`.
- Current snapshot + next action: `docs/PROJECT_STATE.md`, `docs/CURRENT_TASK.md`.
- Build-out plan for this documentation: `docs/ROADMAP.md`.
- Shipped frontend references (do not duplicate): `shiny-computing-machine/docs/console_script_syntax.md`,
  `shiny-computing-machine/docs/pwa_testing_guide.md`.
