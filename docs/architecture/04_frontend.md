# ERE Architecture — 04 Frontend

> Part 4 of 6 · owns §4.1–§4.5 · index: `00_index.md`

## 4. Frontend — `shiny-computing-machine` (`purgatory-ui`)

### 4.1 Stack, bootstrap & shell

- **Angular `^20.2.2`**, TypeScript `~5.9.2`, RxJS `~7.8.2`, `@swimlane/ngx-graph ^11.0.0`,
  `zone.js ~0.15.1`; dev tooling includes **both** Jasmine/Karma and Jest (`package.json:17-48`).
  The Angular project (and build output `dist/purgatory-ui`) is named **`purgatory-ui`**
  (`angular.json:6,20`); `npm start` serves on **`:4250`** (`package.json:8`, `angular.json:75`).
- `main.ts` → `bootstrapApplication(AppComponent, appConfig)` (zone-based, **not** zoneless) —
  the startup order is traced in §2.1.
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
  `shiny_session_id`, and window inheritance (popup spawn lifecycle in §2.5).
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
  (`connection.interceptor.ts:5-25`) — the client half of §3.4 (full exchange in §2.4).
- **Connection management**: `core/services/connection.service.ts` holds connection configs in a
  signal, persisted under `shiny_connections` / `shiny_active_connection_id`
  (`connection.service.ts:21-22`), and builds the connection string
  (`connection.service.ts:95-109`).
- **State**: `core/services/htn-state.service.ts` holds thesis/counterthesis node maps + graphs
  and categories (BehaviorSubject + signals); `core/services/htn.service.ts` is the facade
  (`HtnService`) exposing `state$`, `connectionStatus$`, `refresh()`, `createNode`,
  `updateNodeContent`, `removeNode`/`removeRecursive`/`removeSubtree`, `connectNodes`,
  `importNodes`, etc. (`htn.service.ts:19-346`). `htn-graph.service.ts` handles edge syncing
  (`syncEdges`) and cross-reference creation. `htn-validation.service.ts`
  (`validateNodeContent`) enforces flow-parent and label rules via
  `core/domain/constants.ts` (`REQUIRED_NON_FALSY_KEYS`, `GLOBAL_STANDARD_KEYS`).

#### Services reference (`core/services/*.ts`)

All are `@Injectable({ providedIn: 'root' })` singletons. Cross-links: graph algorithms §4.6,
domain types §4.7, endpoints §3.2, the connection seam §2.4/§3.4 (**B1**), storage/window §4.2.

**`HtnService`** (`htn.service.ts:19-346`) — the façade every feature and console handler calls.
It owns no state: it injects the four services below (`:12-15`), re-exposes their streams
(`:26-42`) and calls `refresh()` once on construction (`:44-46`).

| Member | `:line` | Behaviour |
|---|---|---|
| `refresh` / `saveCategories` / `getData` | `:55-59` | delegate to `HtnStateService` |
| `updateNodeContent` | `:94-139` | ensures one `flow` entry per parent (`effects` for thesis, `triggers` for counterthesis), removes/creates the `root` entry, then `syncEdges` → repository write |
| `createNode` | `:141-181` | builds `Thesis`/`Counterthesis` with `getDefaultContent`; same-graph parent → `addEdge`, cross-graph → `addCrossReference`; emits `nodeCreated` |
| `addAnalysis` | `:61-92` | appends an `analyzes` entry to `content.flow[<context>]` on a counterthesis (no-op if the context is missing) |
| `removeNode` / `removeRecursive` / `removeSubtree` | `:214-224` | single delete, or `performComplexRemoval('recursive'\|'subtree')` |
| `detachNode` | `:226-239` | deletes every edge touching the node, then `refresh()` |
| `pruneNodes` / `connectNodes` / `disconnectNodes` / `importNodes` | `:241-345` | bulk delete; edge connect/disconnect (via `HtnGraphService`); upsert import that rewrites a `type:'reference'` to `'referencer'` (`:319-321`) |
| `validateNodeContent` / `getDefaultContent` / `ensureFlowEntries` | `:204-308` | thin delegates to `HtnValidationService`/`HtnGraphService` |
| `generateId` | `:183-202` | 8-char id, retried up to 10× against both node maps, then suffixed with `Date.now().toString(36)` |
| `settled` / `refreshAndSettle` | `:271-304` | mutation wrapper: resolves after the next `state$` value (or a 5 s timeout), **never rejects**, and `handleError` flips status offline |

> **Reality:** `detachNode` is the one mutator that bypasses `settled` and calls `refresh()`
> directly (`:232-238`), so it does not wait for the post-refresh state the way the others do.

**`HtnStateService`** (`htn-state.service.ts:22-176`) — the single source of truth.
- `HtnState` shape (`:10-17`): `thesisNodes`/`counterthesisNodes` (`Map<string,…>`),
  `thesisGraph`/`counterthesisGraph` (`Graph`), `categories`, `loaded`.
- One `BehaviorSubject<HtnState>` (`:27-34`) with derived `shareReplay(1)` streams
  (`:42-52`); `activeExplorerTrees` (`:25`) is the only **signal** carrying state.
- Event channels (`:54-71`): `planSearchRequest$` (`Subject`), `editorSearchRequest$`
  (`ReplaySubject(1)` — replays the last request to a late window), `refNodeCreated$`,
  `connectionStatus$` (`BehaviorSubject<'online'|'offline'>`), `nodeCreated$`.
- `refresh()` (`:105-162`): `forkJoin`s the five repository reads, then normalizes in place —
  rewrite `type:'reference'` → `'referencer'` (`:117-127`), delete a vestigial `dimension` key
  (`:123-125`), drop empty `flow[*].cycles` (`:131-140`), attach the node maps to the graphs, run
  `populateCrossReferences` then `refreshGraph` on **both** graphs (`:142-144`, §4.6), set status
  `online`; on error logs and sets `offline`.
- `saveCategories` (`:164-175`): persists, then patches `state.categories`.

**`HtnGraphService`** (`htn-graph.service.ts:11-341`) — all edge/flow maintenance.

| Method | `:line` | Behaviour |
|---|---|---|
| `syncEdges` | `:15-127` | diffs `triggers`/`effects` (edge direction depends on graph; a missing target is skipped) and, for cross-graph references, adds/removes the id on the *other* node's `theses`/`countertheses`; returns a `forkJoin` of writes |
| `connectNodes` / `disconnectNodes` | `:129-237` | after `addEdge`/`removeEdge`, maintain the counterpart node's `flow`, `triggers`/`effects`, and seed/remove the `root` entry |
| `addCrossReference` | `:239-261` | push `childId` into the parent's `countertheses`/`theses` if absent (unit-tested in `htn-graph.service.spec.ts`) |
| `ensureFlowEntries` | `:263-299` | seed `flow` from the graph's `inv` (`condition` defaults to `'next'` for counterthesis) |
| `performComplexRemoval` | `:301-340` | BFS-collects descendants (and, for `subtree`, ancestors via `inv`) into a delete set |

> **Reality:** `performComplexRemoval`'s signature also accepts `'cascade'`, but the ancestors set
> is filled only for `'subtree'`, so `'cascade'` is indistinguishable from `'recursive'`; the
> façade only ever passes `'recursive'`/`'subtree'` (`htn.service.ts:219,223`).

**`HtnValidationService`** (`htn-validation.service.ts:7-111`) — `validateNodeContent`
(`:8-62`) returns `{ valid, errors }`, checking: missing `flow` entries for any graph parent
(`:14-23`), `REQUIRED_NON_FALSY_KEYS` (`:25`), a non-empty `label` (`:28`), and per flow entry a
string `condition` + non-negative integer `priority`, plus counterthesis-only `completed`
(boolean) and `completedCondition` (string) (`:36-58`). Error strings are fixed, at
`:11,21,29,33,41,46,52,55`. `getDefaultContent` (`:64-82`) templates from `constants.ts`;
`checkNonFalsyPaths` (`:84-110`) handles single-key and `parent.*.child` paths.

**`ConnectionService`** (`connection.service.ts:19-110`) — `ConnectionConfig` (`:4-14`),
two signals `connections`/`activeConnectionId` (`:24-25`), keys `shiny_connections` /
`shiny_active_connection_id` (`:21-22`); load/save/delete/setActive/persist (`:31-83`).
`getActiveConnectionString` (`:85-93`) → `buildConnectionString` (`:95-109`) emits exactly
`Data Source=<server>;Initial Catalog=<database>;(Integrated Security=True|User ID=<u>;Password=<p>);Encrypt=<True|False>;TrustServerCertificate=<True|False>;MultipleActiveResultSets=true;`.

**`connection.interceptor.ts`** (`:5-25`) — attaches a base64 `X-Connection-String` on every
request **only if** the request has no such header and an active connection exists; otherwise it
passes the request through untouched (the client half of §3.4, full exchange in §2.4).

**`StorageService`** (`storage.service.ts:6-46`) — picks `sessionStorage` in a popup (path
`/popup`, `window.opener`, or a `spawnType` param) and `localStorage` otherwise (`:15-21`);
`getItem` falls back to `localStorage` for a popup unless the key is one of
`shiny_session_id`/`shiny_window_registry`/`shiny_window_list`/`shiny_dock_config` (`:8-13,23-33`).

**`PwaService`** (`pwa.service.ts:11-46`) — captures `beforeinstallprompt` into `deferredPrompt`
(`:16-22`), exposes an `installPromptAvailable` signal (`:13`) and `promptInstall()` (`:32-45`).

> **Reality:** `PwaService` is **injected nowhere** (no consumer outside its own file), so the
> install prompt is currently unreachable UI — recorded as §6 item 11.

> **Reality (flow defaults):** a fresh `flow` entry is seeded in several places with **two different**
> `condition` defaults — `''` in `HtnService.updateNodeContent` (`:109,122`) but `'next'` for
> counterthesis in `HtnGraphService.ensureFlowEntries` (`:275`) and
> `HtnValidationService.getDefaultContent` (`:73`); which one a new entry gets depends on the code
> path that created it (§6 item 9).

### 4.4 Feature inventory

The window, dock, and plan terms used below are mapped to code in §2.6.

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

