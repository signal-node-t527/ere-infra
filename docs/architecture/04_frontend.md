# ERE Architecture — 04 Frontend

> Part 4 of 7 · owns §4.1–§4.3, §4.5 · index: `00_index.md`

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

The window system (`features/window-system/**`) is the core UI abstraction. Four collaborators
share the work: `WindowService` owns the open-window list and z-order, `WindowManagerService`
owns real browser popups, `WindowComponent` is the window frame (resize / drag / close / dock),
and `DockablePanelsService` + `DockablePanelsComponent` own the dock regions. Every feature
window renders through an `<app-window>` wrapper (`console.html:1`, `htn-plan.html:1`,
`htn-explorer.html:1`, `htn-editor.html:1`, `htn-categories.html:1`,
`connection-string-manager.html:1`, `htn-metadata-menu.html:1`), instantiated by `AppComponent`
from `WINDOW_REGISTRY` via `ngComponentOutlet` (§4.1). `WindowComponent` implements the
duck-typed `WindowHandle` contract (`types.ts:147-152`, §4.7).

**`WindowService`** (`window.service.ts:14-113`) — the open-window list & z-order.

State signals: `windows: signal<Window[]>` with `Window { name, type, active, zIndex }`
(`:4-9,16`); `ZIndexflag` (`:15`) — an integer bumped **only to re-trigger** the floating-window
z-index `effect`; `container: signal<{width,height}>` (`:17`) — the dashboard's px size, updated
by `AppComponent.updateContainer` on resize (`app.component.ts:101-110`).

Persistence: the constructor loads `shiny_window_list` (`:22-24,31-47`) and an `effect`
auto-persists `JSON.stringify(this.windows())` on **every** change (`:26-28`); both via
`StorageService` (§4.3 — the key is excluded from popup inheritance).

| Method | `:line` | Behaviour |
|---|---|---|
| `addWindow(type, name?)` | `:52-68` | `name` given & exists → `activateWindow` and return the existing window; otherwise `name = name \| \`${type}-${Date.now().toString(36)}\``, `zIndex = max(600, maxZindex()+10)` (`:62-63`), appended `active:true` |
| `activateWindow(name)` | `:70-78` | set `active:true`, then `bringToFront` |
| `removeWindow(name)` | `:80-83` | filter the name out of the list |
| `bringToFront(name)` | `:85-93` | `zIndex = maxZindex()+1`, bump `ZIndexflag` |
| `maxZindex()` | `:95-101` | floors at **600** |
| `getZIndex(name)` | `:103-106` | z-index, or `0` if unknown |
| `findWindow(name)` | `:108-112` | the window, or a default empty `Window` |

**`WindowManagerService`** (`window-manager.service.ts:7-34`) — **real browser popups**.

- Session id: `getOrInitSessionId()` reads or creates `shiny_session_id` (`:11-20`); when no name
  is given, the id seeds the auto-generated instance name (`:24-25`).
- `spawn(type?, name?)` (`:23-33`): `window.open('/?spawnType=…&spawnName=…' | '/', '_blank',
  'width=1000,height=800')`, throwing `'Pop-up blocked'` when the browser denies it. The popup
  re-adds its own window on the other side — full lifecycle in §2.5, detection in
  `app.component.ts:36-61`.

**`WindowComponent`** (`window.component.ts:39-306`) — a feature window's frame.

- Inputs: `windowName` / `windowType` (`:81-82`); `docked` (input alias `:85`, OR'd with an
  internal signal `:86-87`); `windowStyle` / `headerStyle` / `coreStyle` (`:93-95`);
  `windowDefault: [left, top, width, height]` in **%** (`:96`).
- Geometry model `Ctx` (`:16-30`): `elementPositionPct.{default,discrepancy}` (%), 
  `elementPositionPx.delta`, `elementSizePct.default`. `defaultCtx` seeds from
  `windowDefaultComputedPosition`, which derives `right`/`bottom` from the left/top/width/height
  defaults (`:97-104;151-165`).
- Effects: an `effect` re-reads `ZIndexflag()` then syncs `zindex` and sets `hostFocus` when the
  window is topmost (`:42-49`). A dock-transition `effect` saves `lastFloatingCtx` on dock and
  restores (or resets + normalizes) it on undock (`:51-75,167-168`).
- `HostBinding` (`:106-133`): docked → relative `100%×100%` inside the panel; mobile mode →
  `display:none`; floating → `z-index` from the service and `display:flex` **only while active**.
- `mousedown` anywhere → `bringToFront` (`:135-140`). The header **X** (`handleCloseOnClickOutput`,
  `:142-149`) sets `active:false` but **keeps the window in the list** — closing ≠ removing; a
  console/plan button can re-activate it (`app.component.ts:92-99`).
- Reposition math (`:200-224`): live drag converts px→% and subtracts `discrepancy` (left/top set
  via `calc()`); on release the four % positions are committed unless docked.
- Resize math (`:226-268`): mousedown pins the opposite edge; move writes width/height as %; mouseup
  recomputes all four positions + size from `offsetLeft/Top/Width/Height`, zeroes the discrepancy,
  and commits `ctx` + `lastFloatingCtx`.
- The **8 resize handles** are `app-resize` instances (`window.component.html:1-16,18-24,43-48,51-66`)
  fed by `configRow1Col1 … configRow3Col3` (`:184-191`) — each maps a 3×3 border cell to which of
  y/x is active and whether it grows **backward** (NW / N / NE / E / SE / S / SW / W).
- Lifecycle: `ngOnInit` → `dockService.registerWindow(name, el, this)` + `initDefaultValues`
  (`:270-273`); `ngOnDestroy` removes the element (docking may have reparented it) and unregisters
  (`:275-282`); `ngAfterViewInit` normalizes the floating geometry (`:302-305`).

**`ResizeService` / `ResizeComponent`** (`resize.service.ts:6-9`, `resize.component.ts:72-190`)

- `ResizeService` holds a single `isResizing` boolean; the heavy lifting is in the component.
- `ResizeConfig` (`:13-28`): per-axis `{ active, backward }` + `elementSizePx.current` accessors —
  the 8 variants are built in `WindowComponent`.
- The component emits `onMouseDownOutput` / `onMouseMoveOutput` / `onMouseUpOutput` (`:78-80`). On
  mousedown it pins the opposite edge, adds `body.no-select`, and registers global
  `mousemove`/`mouseup` (`:107-149`); on move it emits the new width/height in **px** (`:153-170`);
  on mouseup it clears state and removes the global listeners (`:174-183`).

**`RepositionComponent`** (`reposition.component.ts:34-148`)

- Drags in px from `elementPositionPxDefaultInput` (fed by `WindowComponent.repositionInput`, which
  pre-computes right/bottom so the far edge stays put — `window.component.ts:193-198`), emitting
  `elementPositionPxDefaultOutput` live and `repositionEnd` in px on release (`:124;129-147`).
- **Dock offer:** once a single drag exceeds **1200 ms** it flips `dockablePanelsService.showHelper`
  (the dock helper) (`:101-104`); a 500 ms idle-stop timer clears it (`:76-88`). On mouseup,
  `lastDroppedZone` (set by dragging over a zone) triggers `dockWindow` (`:129-135`).

**`DockablePanelsService` + `DockablePanelsComponent`** (`dockable-panels.service.ts:8-227`,
`dockable-panels.component.ts:15-238`, `resize/dock-resize.component.ts:10-71`)

- Zones: left / right / top / bottom / center, each an `active*` signal; left/right width `200` and
  top/bottom height `150` (`:11-20`).
- Registry: `Map<name, { el, component: WindowHandle }>` (`:24`). `registerWindow` force-docks
  `console` to bottom in mobile and otherwise **auto-docks from the saved dock config** (`:124-139`);
  `unregisterWindow` (`:145-147`).
- `dockWindow` / `undockWindow` (`:149-180`): mobile rules — `console` → bottom at **40% of viewport
  height** and cannot be undocked (`:150-155,175-178`); any other window → center, undocking any
  previous center occupant (`:156-166`). Requests are queued in `dockRequests` / `undockRequests`
  signals and consumed by the component's `effect`s (`dockable-panels.component.ts:25-43`).
- The component **reparents** the window's DOM `el` into the zone `@ViewChild` panel, calls
  `component.setDocked(true/false)`, and persists via `updateDockState` / `removeDockState`
  (`dockable-panels.component.ts:78-150`). A `MutationObserver` refreshes the `active*` signals from
  panel children, ignoring `APP-DOCK-RESIZE` (`:58-76,156-179`).
- Layout: `getLayoutStyles` (`:187-201`) — active zones are flex, inactive collapse (`display:none`),
  minimum `20px`. `DockResizeComponent` (`dock-resize.component.ts:10-71`) emits the raw drag `delta`
  with `orientation` `vertical|horizontal`; the parent clamps sizes to ≥20px (`:203-233`).
- Mobile mode (`:31-122`): auto-detected as **not a desktop OS** AND (mobile UA **or** coarse
  pointer) AND (portrait **or** ≤900px) (`:67-88`), with `setManualMobileMode` as an override.
  `enforceMobileLayout` (`:99-122`) raises `bottomHeight` and docks the console.

> **Reality:** docking **reparents the window element** in the DOM (`dockable-panels.component.ts:96-97`).
> Because `docked` is a read-only input signal, the component reaches into the window instance's
> `setDocked` method (the `WindowHandle` backdoor, `:118-123` / `window.component.ts:88-90`); Angular
> bindings keep working after the move because the data context stays with `AppComponent`.

**Persistence & inheritance.** Three keys are involved; **all are excluded** from popup inheritance
(§4.3), so a spawned popup gets its own values rather than the opener's:

| Key | Writer / reader | Contents |
|---|---|---|
| `shiny_window_list` | `WindowService` (`:20,27,32`) | open windows (name/type/active/zIndex) |
| `shiny_session_id` | `WindowManagerService` (`:14-17`) | spawn session id, created if absent |
| `shiny_dock_config` | `DockablePanelsService` (`:197-226`) | `{ layout, sizes }` — docked per window + zone sizes |

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

#### Repository layer reference (`core/repository/*.ts`)

Two files: the **port** `HtnRepository` (`htn.repository.ts:4-23`, an `interface` of `Observable`
methods) and the **HTTP implementation** `HttpHtnRepository` (`http.repository.ts:12-198`,
`@Injectable({ providedIn: 'root' })`, injecting `HttpClient`, `apiUrl = APP_CONFIG.apiUrl`
`:13-14`). Every method maps a repository call to one backend route (§3.2) and a JSON→domain
conversion (§4.7).

| Port method (`htn.repository.ts`) | Impl `:line` | HTTP (against `${apiUrl}`) | JSON → domain / result |
|---|---|---|---|
| `getThesisNodes(): Observable<Map<string, HtnNode>>` | `:18-41` | `GET /htn/thesis-nodes` (`:20`) | each row → `new Thesis({…})` (`:25-32`); error **rethrows** (`:38`) |
| `getCounterthesisNodes()` | `:43-66` | `GET /htn/counterthesis-nodes` (`:45`) | each row → `new Counterthesis({…})` (`:50-57`); **rethrows** (`:63`) |
| `getThesisGraph(): Observable<Graph>` | `:68-70` | `GET /htn/edges?graph=thesis` (via `getGraph` `:77`) | `Graph` built `:79-93`; **rethrows** (`:99`) |
| `getCounterthesisGraph(): Observable<Graph>` | `:72-74` | `GET /htn/edges?graph=counterthesis` (`:77`) | same `getGraph` shape; **rethrows** (`:99`) |
| `getNode(id, graphType)` | `:104-112` | `GET /htn/nodes/{id}?graph=` (`:105`) | raw `HtnNode`; error **swallowed → `of(undefined)`** (`:109`) |
| `createNode(node)` | `:116-123` | `POST /htn/nodes` body=`node` (`:117`) | error **swallowed → `of(node)`** (`:120`) |
| `updateNodeContent(id, graphType, content)` | `:125-137` | `POST /htn/nodes/{id}/content` body=`content` (`:130`) | `graphType` **unused**; error **swallowed → `of(void 0)`** (`:134`) |
| `removeNode(id, graphType)` | `:139-146` | `DELETE /htn/nodes/{id}?graph=` (`:140`) | error **swallowed → `of(void 0)`** (`:143`) |
| `removeNodes(ids, graphType)` | `:148-155` | `POST /htn/nodes/batch-delete?graph=` body=`ids` (`:149`) | error **swallowed → `of(void 0)`** (`:152`) |
| `addEdge(sourceId, targetId, graphType)` | `:157-168` | `POST /htn/edges` body=`{fromId,toId,graph}` (`:158-159`) | 409 ignored, others logged (`:161-164`); **swallowed** (`:165`) |
| `removeEdge(sourceId, targetId, graphType)` | `:170-177` | `DELETE /htn/edges?from=&to=&graph=` (`:171`) | error **swallowed → `of(void 0)`** (`:174`) |
| *(not on the port)* `getCategoryTree()` | `:181-188` | `GET /htn-categories` (`:182`) | error **swallowed → `of([])`** (`:185`) |
| *(not on the port)* `saveCategoryTree(tree)` | `:190-197` | `POST /htn-categories` body=`tree` (`:191`) | error **swallowed → `of(void 0)`** (`:194`) |

**JSON→domain mapping.** `getThesisNodes`/`getCounterthesisNodes` run each row through the domain
class constructors (`models.ts:9-21`, `:31-45`, §4.7): `graph` is forced by the class (`'thesis'` /
`'counterthesis'`); the wire's integer `layer` (always sent as `n.layer || 0`) is expanded to a
`LayerMetrics` `{longestPath, shortestPath, avg}` (`models.ts:20`, `:44`); the flat response fields
`triggers`/`effects`/`countertheses`/`theses` fill the matching content arrays only when the
content array is absent or empty (`models.ts:15-17`, `:37-39`); `Counterthesis` further defaults
`state:'W'`, `executionOrder:'unit'`, `type:'process'` (`models.ts:40-42`). `getGraph` builds
`Graph{ edges: [[fromId,toId]], ady, inv, type, nodes: new Map(), update$: new Subject<boolean>() }`
and pre-fills `ady`/`inv` from `edges` (`http.repository.ts:79-93`); the `nodes` map is left empty
here and attached later by `HtnStateService.refresh` (`htn-state.service.ts:114-115`, §2.2).

**Error behaviour & connection status.** Only the four graph/node **reads** rethrow — these are
exactly the four `forkJoin` inputs in `HtnStateService.refresh` (`htn-state.service.ts:106-112`) that
can drive `connectionStatus$` to `'offline'` (`:157-159`). Every other method swallows its error and
returns a benign value (`undefined` / the input `node` / `[]` / `void 0`), so a failed write is
silent and does **not** flip the status; the UI proceeds on the optimistic assumption (§2.3).

> **Reality:** `HtnRepository` is **never used as an injection token**. All three consumers inject
> the concrete `HttpHtnRepository` (`htn.service.ts:20`, `htn-graph.service.ts:12`,
> `htn-state.service.ts:23`), so the port is a documented contract only — and it **omits**
> `getCategoryTree`/`saveCategoryTree`, which exist solely on the class (recorded as §6 item 12).

> **Reality:** `updateNodeContent` ignores its `graphType` parameter — the route path and body carry
> only `{id}` + `content` (`http.repository.ts:125,130`), matching the backend endpoint (§3.2).

### 4.5 Console & scripting subsystem

The console is a terminal window (`features/console/*`): input is parsed to a `ParsedCommand`,
dispatched against a command map (with a window-type fallback), and output is appended to a
line buffer rendered as trusted HTML.

**Parser** (`features/console/console.parser.ts`). `parseCommand(input)` (`:5-54`) tokenizes with
`/(?:[^\s"']+|"[^"]*"|'[^']*')+/g` (`:9`), which keeps `key="value with spaces"` a single token;
quoted sections (`QUOTED_SECTION`, `:3`) are stripped inside each token (`:14`) so quotes are
syntactic, not data. The first token is `shift`ed as `command` (`:17`); the rest classify as
`--flags` (bare → `true`; `--k=v` → string, `:25-37`), `key=value` pairs (split on the first `=`,
remainder rejoined, `:40-47`), or `positional[]` (`:50`) — yielding
`ParsedCommand { command, positional[], keyValues{}, flags{} }`. Covered by
`console.parser.spec.ts:1-51`.

**Dispatch** (`features/console/console.handler.ts`). At construction the handler builds `ctx`
(`createContext`, `:139-172`) and merges **ten** handler factories into one
`Map<string, CommandAction>` (`:122-136`; imports `:13-22`). `handleCommand(parsed)` (`:183-209`)
resolves the verb: a map hit invokes the action (sync or `Promise`); else if the verb names a
**window type** (`Object.keys(WINDOW_REGISTRY)`, `:190`) it opens a new window — `--open` first
activates an existing instance of that type (`:193-200`); else it tries
`handleWindowActivation` by window **name** (`:211-239`, which docks to `center` in mobile mode
`:212-218`, bumps zIndex, and re-inits the console's defaults `:228-234`) and finally logs
`Unknown command` (`:206`).

**Handler contract** (`features/console/handlers/handler-context.ts`). `HandlerContext`
(`:3-32`) supplies log helpers, `escapeHtml`/`formatNodeId`/`print`, the injected services, the
**live state mirrors** (`currentThesisNodes`/`currentCounterthesisNodes`/`current*Graph`/
`currentCategories`, getters over the latest `HtnState`) and the `checkConfig`/`cleanConfig`/
`explorerConfig`/`editorConfig` records. `CommandAction` is
`(parsed) => void | Promise<void>` (`:34`).

**Logger** (`features/console/console-logger.service.ts`). A `Subject<string[]>` carries HTML
fragments (`:8-9`); the level helpers wrap a message in a
`log-info|success|warn|error|header` span (`:32-50`), `clear()` emits the sentinel `__CLEAR__`
(`:15-17`), and `logUsage` HTML-escapes then re-emits as an error (`:52-54`). `escapeHtml`
(`:19-26`) and `formatNodeId` (id + copy button, `:28-30`) are the shared output helpers.

**Commands** — **44 verbs / 45 registrations** across ten factory modules (the `nav` verb is
also registered as `navigate`; `navigation.handler.ts:8-9`):

| Group | Command | Effect |
| --- | --- | --- |
| node-crud | `mknode <type> [parentId] [key=value]…` | Create a node (orphan if `parentId` omitted); pairs seed content. |
| | `rmnode <type> <id>` | Delete one node. |
| | `rmnodes <type> <id…>` / `rmnodes <id…>` | Delete many; type auto-detected when omitted. |
| | `modnode <type> <id> [key=value]…` | Patch node content. |
| | `rmsubtree <type> <rootId>` | Delete a node and its whole subtree. |
| navigation | `nav <id>` (alias `navigate`) | Focus `htn-explorer` and emit `navigationRequest$`. |
| | `shownode <id>` | Log the node's raw JSON. |
| | `list-nodes [type]` | List nodes, optionally filtered by type. |
| | `list-orphans` | List nodes with no parent. |
| graph | `list-edges <thesis\|counterthesis>` | List a graph's edges. |
| | `mkedge <thesis\|counterthesis> <from> <to>` | Add an edge. |
| | `rmedge <thesis\|counterthesis> <from> <to>` | Remove an edge. |
| | `migrate-graph --confirm` | Rewrite `graph="antithesis"` → `"counterthesis"` on nodes/edges. |
| | `test-backend` | Ping the backend API. |
| bulk-data | `purge-prop <prop> --confirm` | Delete a property from every node (schema keys rejected). |
| | `replace-value <propKey> <cur> <new> --confirm` | Replace matching property values across nodes. |
| | `find-value <propKey> <value>` | Read-only; list nodes whose property matches. |
| | `migrate-prop <from> <to> --confirm` | Copy a property to a new key (source kept). |
| category | `list-cats` | Print the category tree. |
| | `mkcat <name> [parent]` | Create a category. |
| | `rmcat <name>` | Delete a category. |
| | `cat <cat> <nodeId>` | Add a node to a category. |
| | `uncat <cat> <nodeId>` | Remove a node from a category. |
| integrity | `check-integrity [key]` | Report dangling edges / refs / flow issues (per `checkConfig`). |
| | `clean-integrity [key]` | Delete the issues found (per `cleanConfig`). |
| | `config-check-integrity <key> <bool> [--list]` | Read/write the check-key toggles. |
| | `config-clean-integrity <key> <bool> [--list]` | Read/write the clean-key toggles. |
| view | `dock <name\|type> <zone> [--open] [--force]` | Dock a window to `left/right/top/bottom/center`. |
| | `undock <windowName>` | Undock a window. |
| | `mobile-mode <on\|off\|auto>` | Force/release mobile layout. |
| | `list-windows` | List windows and their dock zone. |
| | `rmwindow <windowId>` | Close a window instance. |
| | `spawn [type] [name]` | Open an independent pop-up session. |
| config-utility | `cls` | Clear the console buffer. |
| | `help` | Print the hand-maintained command table. |
| | `config-explorer <key> <bool> [--list]` | Read/write explorer toggles. |
| | `config-editor <key> <value>` / `toggle-enter-behavior` … | Read/write editor config. |
| | `clean-workspace` | Wipe all storage and reload the app. |
| | `refresh` | Reload all data from the backend. |
| referencer | `list-referencers [rootId] [--save-default]` | Walk a plan tree and list referencer nodes in priority order. |
| script | `script-run <path\|name> [--confirm] [--dry-run] [--continue-on-error] [--settle=<ms>] [key=value]…` | Execute a JSON script. |
| | `script-open [--confirm]` | File-pick and run a local `.json` script. |
| | `script-validate <path\|name>` | Schema-check a script without running it. |
| | `script-list [--validate]` | List manifest scripts (optionally validate each). |

> **Reality:** the `help` table (`config-utility.handler.ts:5-51`, printed by `handleHelp`
> `:58-67`) is a **hand-maintained duplicate** of the command map and has drifted: it advertises
> `connection-manager` (`:43`), which has no dedicated registration and is served only by the
> window-type fallback, and it omits the `navigate` alias (`navigation.handler.ts:9`) and the
> `config-check-integrity`/`config-clean-integrity` verbs (`integrity.handler.ts:8-9`).
> `KNOWN_COMMAND_NAMES` (`:54-56`) derives from the same list and is used to validate scripts.

> **Reality:** offline gating is **advisory only**. `connectionStatus$` toggles the private
> `isOnline` flag and logs `Console: System is OFFLINE. Modification commands are disabled.`
> (`console.handler.ts:114-119`), but `isOnline` (`:39`) is never read, so no command is actually
> blocked; only the script engine's `online|offline` guards consult connection state
> (`script.handler.ts:69,88-89,384-387`).

> **Reality:** output is rendered as **trusted HTML** — `SafeHtmlPipe` calls
> `bypassSecurityTrustHtml` (`console.component.ts:12-13`) and the template binds `[innerHTML]`
> (`console.html:3`); the entry handler appends the raw input line and any async rejection
> (`console.component.ts:53-72`), and clicks are delegated to copy buttons (`:74-107`). Handlers
> must therefore escape dynamic text themselves via `ctx.escapeHtml`; only the referencer, script
> and view handlers do, while most node/category output interpolates DB strings verbatim.

**Script engine** (`features/console/handlers/script.handler.ts`): runs
`{ name, description, vars, steps[] }` (or bare steps); guards `online|offline|exists:<id>|missing:<id>`;
`${var}` interpolation; options `--confirm`/`--dry-run`/`--continue-on-error`/`--settle=<ms>`.
A manifest (`public/scripts/index.json`, cache-busted) is generated at build by
`tools/build-script-index.mjs` and wired through the `scripts:index` npm script
(`package.json:6-13`). The shipped reference is
`shiny-computing-machine/docs/console_script_syntax.md` — this doc does not duplicate it.

