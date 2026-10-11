# ERE Architecture — 07 Frontend Features

> Part 7 of 7 · owns §4.4 (owner) · index: `00_index.md`

### 4.4 Feature inventory

The window, dock, and plan terms used below are mapped to code in §2.6.

| Feature (`src/app/features/…`) | Role |
|---|---|
| `graph-lib` | `@swimlane/ngx-graph` wrapper + a single-node prototype patch (`graph.ts`; `config.ts` is commented-out scratch). |
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

#### htn-plan reference (`features/htn-plan/*.ts`)

**Window & shell** — the plan opens as a `'plan'`-type window: `WINDOW_REGISTRY`
(`core/config/window-registry.ts:11`) maps it to `HtnPlanComponent`, which wraps
`<app-window … [windowDefault]="[5, 5, 80, 80]">` (`htn-plan.html:1`). The component
(`htn-plan.component.ts:19-27`, `ChangeDetectionStrategy.OnPush`) takes `windowName`/
`windowType` inputs defaulting to `'plan'` (`:37-38`) and resolves them from the host
`WindowComponent` once present (`:40-46`, §4.2). It holds no copy of the plan data — every
signal lives in the injected `PlanStateService` (`:32`).

> **Reality:** `PlanStateService` is `providedIn: 'root'`, so **all plan windows share one
> live signal set**; only the persistence keys are per-window name (see below).

**`PlanStateService`** (`plan-state.service.ts:19-20`) — the plan's state store.

| Area | `:line` | Behaviour |
|---|---|---|
| Signals | `:27-33` | `planTree` (root `PlanStep[]`), `searchId`, `navHistory`, `visibleNavHistory`, `stage` (`PendingAnalysis[]`), `counterthesisNodes`, `counterthesisOptions` |
| Storage keys | `:37-38,65-71` | per-window `htn_plan_active_root_<windowName>` + `htn_plan_expanded_state_<windowName>` (`plan.constants.ts:3`); `setWindowName` re-keys and reloads expansion state if a tree exists (`:68-70`) |
| Bootstrap | `:40-63` | on `htnService.getData()` builds the node map + suggestion options (`:44-46`) and restores the saved root if it still exists (`:51-55`); `planSearchRequest$` → `initiateNewPath` (`:58-62`) |
| Navigation | `:73-99` | `initiateNewPath` (search box), `navRelative` (ctrl-click), `navToHistoryIndex` (breadcrumb); history capped at `NAV_HISTORY_LIMIT = 5` (`:35`), `visibleNavHistory` = tail slice with `realIndex` for breadcrumb navigation (`:299-308`) |
| `generatePlan` | `:101-125` | snapshot expansion state (`collectExpandedState`), persist root id (`:106`), `buildTree` → restore expansion → `markLoopTargets` → set tree; unknown id → `[]` (`:108-111`) |
| Progress writes | `:127-178` | `toggleCompletion` / `incrementLoop` / `resetLoop` mutate `content.flow[parentId]`, then persist via `htnService.updateNodeContent`; loop cycles are `"Cycle N"` display strings (`:152`) |
| Analysis stage | `:180-215` | `submitAnalysis` appends a `PendingAnalysis`; `register` uploads each via `htnService.addAnalysis`, clears the stage and logs a console summary (`:209-214`) |
| `resetPlan` | `:217-256` | clears the stage, resets `completed`/`cycles` on every counterthesis (`:224-245`), regenerates the tree and its state |
| Expansion persistence | `:258-282` | round-trips the per-step `expanded`/`childrenCollapsed` map as JSON (keys `parentId:id`, `plan-utils.ts:23-25`); a failed parse is a `console.warn` (`:278-280`) |

`planSearchRequest$` is a `Subject<string>` on `HtnStateService` (`:54-55`, publish `:73-75`),
re-exposed by `HtnService` (`:37,48`, §2.2) and consumed only by `PlanStateService` (`:58-62`).
It is emitted by the explorer's and categories' `openInPlan` actions
(`htn-explorer.component.ts:697-698`, `htn-categories.component.ts:271-273`; the explorer's
"Open in Plan" menu label at `htn-explorer.html:229`) — the only inbound channel into a new
plan (the plan window can also be opened/spawned directly via `windowService.addWindow('plan')`,
§4.2).

**`PlanStep` / `PendingAnalysis`** (`plan.types.ts:3-27`) — the tree node model.

| Field | Meaning |
|---|---|
| `id` / `parentId?` / `viewId?` | domain node id, parent id (absent for roots), and a render-scoped `'v_'` id (`generateViewId`, `plan-utils.ts:5-7`) used for DOM wire targeting |
| `activeFlow` | the parent context the step renders under — `'Root'` for roots, an id for flows, `'Loop Ref'` for loop stubs |
| `content` | resolved `JSONObject` (node content merged with `flow[parentId]`, §3.5/§4.3) |
| `type` | `'step' \| 'loop'` |
| `expanded` / `childrenCollapsed` | details panel / children-visibility flags (persisted per step) |
| `analyzing` | analysis textarea open |
| loop fields | `loopTargetId?`, `isLoopTarget?`, `iterations?`; referencer fields `isReferencer?`, `referencerId?`, `targetStep?` |
| `children` | the resolved child steps |

`PendingAnalysis` (`:3-8`) = `{ nodeId, contextId, timestamp, analysis }`.

**Tree construction** (`plan-utils.ts`) — `buildTree` (`:108-281`) walks depth-first from a
root id and cuts three loop shapes:

1. **recursion** — the id is already on the current path (`:115-117`);
2. **priority-inversion** — an ancestor `effects` the id and the id's flow priority is
   *lower* than the ancestor's current child (`:119-136`, priorities from `getPriority`
   `:9-21`, default `DEFAULT_PRIORITY = 9999`, `plan.constants.ts:1`);
3. **reference-loop** — a `'referencer'`'s `refId` is already on the path (`:140-145`).

Each cut yields a `type:'loop'` stub (`:188-221`) with `loopTargetId`, `iterations` =
resting `cycles.length + 1`, and `content` = label + merged flow state. `markLoopTargets`
(`:66-106`) then flags the matched ancestor (or an ancestor's sibling/child)
`isLoopTarget` for UI highlighting. Children sort by (flow `priority`, then id) (`:250-259`);
a `'referencer'` node resolves its `refId` subtree into `targetStep` and keeps its own
`effects` children (`:146-182`). Every step's `content` merges `flow[parentId]` (incl. resting
`cycles`) and sets `activeFlow` (`:229-244`); a step whose `executionOrder === 'set'` starts
`childrenCollapsed: true` (`:276`). `getCustomProperties` (`:283-305`) filters out
`NODE_ROOT_STANDARD_KEYS` + `FLOW_STATE_STANDARD_KEYS` (and `cycles` on non-loop steps, §4.7)
so the card details pane shows only user-defined properties.

**`HtnPlanComponent`** (`htn-plan.component.ts:27-451`) — the window behaviour.

- **Effects** (`:54-63`): `_wiresEffect` redraws the wire overlay after any tree change;
  `_expansionFlagsEffect` recomputes the "Expand All / Expand Children" toggle labels.
- **Responsive** (`:96-118`): a `ResizeObserver` sets `isCompact` below `COMPACT_BREAKPOINT =
  450` (`plan.constants.ts:2`) and re-measures wires on resize.
- **Toolbar** (`htn-plan.html:11-22`) — desktop shows Expand/Contract All, Expand Children,
  Register, Export Queue, Reset; compact (`:25-44`) folds these behind a `☰` menu that on
  mobile adds an "HTN Editor" shortcut (→ `switchToEditor`).
- **Search & click** (`:169-181`): the `suggestion-input` (over `counterthesisOptions`) →
  `initiateNewPath`; a plain card click toggles completion, **ctrl-click** navigates relative.
- **Expand toggles** (`:133-167`): "Expand Children" flips `childrenCollapsed` only on
  `executionOrder==='set'` steps (roots stay open); each change persists expansion state and
  redraws wires.
- **Editor delegation** (`:197-274`): `[E]` routes the id via
  `htnService.requestEditorSearch(…, 'edit', …)`; with > 1 editor window an inline chooser
  lists them (`:197-211`); referencer/loop nodes get a *Referencer↔Target* picker
  (`:213-237`); missing editors are spawned with `addWindow('editor')` (`:258-274`, docked
  center on mobile).
- **`exportQueue`** (`:276-334`): serializes the tree to a JSON array — loop stubs become
  `type:'referencer'`, `set`-order steps nest under `children`, unit-order steps flatten;
  custom props survive via `getCustomProperties`; downloads `htn-plan-dump-<ISO>.json`.
- **Analysis** (`:336-342`): `[A]` toggles an inline textarea on referencer steps; OK pushes
  a `PendingAnalysis` into the stage.

**Wire overlay** (`wire-utils.ts`) — loop-back arrows in an `<svg>` pinned over the scrolling
`.sequence-view` (`htn-plan.html:60-72`). `drawWires` (`htn-plan.component.ts:373-413`)
measures the container via `[data-view-id]` lookups (set in `plan-node-card.component.html:30`)
and builds cubic beziers from `computeBezierPath` (`wire-utils.ts:26-37`): bulge =
`min(WIRE_BULGE_MAX, |Δy| · factor) + offset`, control points clamped ≥ 2 px. 
`traverseAndComputeWires` (`:74-137`) walks the tree with a stack, resolving each loop to its
ancestor (or, failing that, a sibling) target; color `WIRE_COLOR = '#fff'` + arrowhead marker
(`plan.constants.ts:4-7`). Hovering a wire (`onLoopHover` `:344-346`) highlights it and its
target via `activeTargetViewId` (computed `:80-84`).

**`PlanNodeCardComponent`** (`plan-node-card.component.ts:13`, `selector: 'plan-node-card'`) —
the presentational leaf. Inputs: `step`, `hoveredWireSourceId`, `activeTargetViewId`,
`editorSelectionMenu`, `referencerChoice`, `referencerChoicePos` (`:14-16,30-32`); outputs
mirror the parent's actions (`:18-28`). Rendering (`plan-node-card.component.html:24-132`):
type/state/completion CSS classes (`:24-41`), a `⟳ REPEAT:` prefix + `[loopTargetId]` suffix
for loop stubs (`:50-58`), `[E]`/`[A]`/`[±]`/`[^v]` buttons, priority/condition badges
(`:104-111`), and a recursive custom-properties tree from `getCustomProperties` when expanded
(`:120-132`). Unit coverage in `htn-plan.spec.ts`.

> **Reality:** loop progress is persisted as `"Cycle N"` display strings in `flow[*].cycles`
> (`plan-state.service.ts:152`), which is exactly what `iterations` and `exportQueue` build
> on; a `[LoopDetect]` debug `console.log` remains at `plan-utils.ts:142` whenever a
> reference-loop is cut.

#### htn-explorer reference (`features/htn-explorer/*.ts`)

**Window & shell** — the explorer opens as a `'explorer'`-type window: `WINDOW_REGISTRY`
(`core/config/window-registry.ts:12`) maps it to `HtnExplorerComponent`, which wraps
`<app-window … [windowDefault]="[5, 5, 80, 80]">` (`htn-explorer.html:1-2`). The component
(`htn-explorer.component.ts:34`, `ChangeDetectionStrategy` default) takes `windowName`/
`windowType` inputs defaulting to `'explorer'` (`:39-40`) and resolves them from the host
`WindowComponent` once present (`:42-44`, §4.2). A companion metadata window opens as
`'explorer-menu'` (`window-registry.ts:17` → `HtnMetadataMenuComponent`,
`htn-metadata-menu.component.ts:14`, default `windowDefault` `[2, 50, 25, 45]` at
`htn-metadata-menu.html:1`).

> **Reality:** unlike the plan (whose `PlanStateService` is a root singleton shared by all plan
> windows), the explorer keeps its working state **per window instance** — each explorer window
> owns a `PaneState`, its own `Map`s, and its own per-instance storage keys (below). The only
> cross-window surface is the `activeExplorerTrees` signal it publishes (§4.3).

**Pane state** (`htn-explorer.component.ts:19-25`) — `PaneState` holds the focused node
(`id`, `type`, `entity`) plus its resolved `triggersTree`/`effectsTree` (`TreeNode[]`).
`pane` (`:65`) is the single source of the current view; `refreshPane` (`:100-117`)
recomputes both trees for a node and persists the selection to `ACTIVE_ID`/`ACTIVE_TYPE`.

**Per-window storage keys** — `STORAGE_KEYS` (`:46-53`) prefixes the four constants from
`htn-explorer.constants.ts:2-5` (`htn_explorer_click_action`, `_skip_recursion`, `_active_id`,
`_active_type`) with the **instance name**, so each explorer window persists its own
`<instance>_htn_explorer_*` keys. `restoreState` (`:317-337`) reads them back on first init and
**deletes three legacy keys** (`htn_explorer_state_filter`, `htn_explorer_thesis_state`,
`htn_explorer_counterthesis_state`, `:334-336`) — an existing saved `ACTIVE_ID` re-roots the
pane (`:328-332`).

> **Reality:** the legacy-key cleanup is **deletion, not migration** — a user who relied on the
> pre-restore `thesis_state`/`counterthesis_state` keys loses that view continuity.

**Bootstrap** (`ngOnInit`, `:263-298`) — subscribes `htnService.getData()`; once
`data.loaded`, it caches the thesis/counterthesis `Map`s + `Graph`s (`:270-274`), builds
`allOptions` for the suggestion input (`:276-278`, thesis + counterthesis), then on the first
run calls `restoreState` (`:282-284`) and registers a `window`-level `htn-config-changed`
listener that updates `skipRecursionEdges` (`:287-291`); later reloads just re-`refreshPane`
the current node (`:293-296`). A `[HtnExplorer]` debug `console.log` runs on data receive and
state init (`:272,283`).

**Trees** (`tree-utils.ts`) — `computeMinDepths` (`:10-33`) BFS-walks triggers/effects from a
root, recording each reachable id's shallowest depth and **stopping at `maxDepth + 1`** for
lookahead (the "+1" lets siblings at the boundary resolve). `buildTree` (`:35-77`, params
default `maxDepth = 2`, `maxSiblings = 5`) keeps only ids whose `minDepth === depth + 1`
(`:51`, so a node appears at its shallowest position only), dedups globally via `shownIds`
(`:56`), and past `MAX_SIBLINGS` collapses the tail into a synthetic `truncated` node whose id
reads `"+N more"` (`:58-61`). Component constants `MAX_DEPTH = 5`, `MAX_SIBLINGS = 5`
(`htn-explorer.component.ts:94-95`).

**Search & selection** — the suggestion input (`htn-explorer.html:91-95`, placeholder "type
root id to render") → `loadEntityFromSuggest` (`htn-explorer.component.ts:300-312`): known id
→ `selectEntity`, unknown → `searchError`. `selectEntity` (`:457-465`) resolves the graph type
from the two maps and calls `refreshPane`.

**Click handling** (`onNodeClick`, `:404-441`) — routes by active mode first (prune/rewire/
add-child, below), then: a `'referencer'` node with `refId` opens the **reference-choice
overlay** unless `bypassChoice` (`:423-435`, overlay template `htn-explorer.html:408-424` with
"This Node (Ref)" / "Target Node" buttons); otherwise the click resolves to the **effective
click action** (`effectiveClickAction`, `:366-372`): the persisted `clickAction` signal
(`'edit'`/`'navigate'`, default `'edit'`, `:314`, toggled by the ✎/◉ toolbar button
`htn-explorer.html:71-74`), **inverted while Ctrl is held and the window is hovered**
(Ctrl tracked by `@HostListener('window:keydown/up.control')` `:356-364`, hover by
`onMouseEnter/Leave` `:348-354`). `navigateToRef` (`:447-455`) applies the chosen action to
either the referencer itself or its target. Ctrl-inversion means "hold Ctrl + click" behaves
as the opposite of the persistent setting.

**Operations panel** (`htn-explorer.html:221-250`) — per focused node:

- **Open in Editor** (`openInEditor`, `:467-483`) — targets the last `'editor'` window or
  spawns one, then `htnService.requestEditorSearch(id, 'edit', …, targetName)` + activate.
- **Open in Plan** (`openInPlan`, `:697-709`) — counterthesis only (template `*ngIf="type !==
  'thesis'"`, `:228`): emits `htnService.requestPlanSearch(id)` (the `planSearchRequest$`
  channel, §4.4/htn-plan) and activates or spawns a `'plan'` window.
- **Detach Current** (`detachNode`, `:711-718`) — `htnService.disconnectNodes(parentId, id, …)`
  (no confirm), cutting the parent→child edge (bypasses the flow `settled` rule, §4.3).
- **Remove Current** (`removeNode`, `:720-725`) — `window.confirm`-gated
  `htnService.pruneNodes([id], …)`.
- **Remove Subtree** (`removeSubtree`, `:727-732`) — `window.confirm`-gated
  `htnService.removeSubtree(id, …)` (cascade removal, §4.3).

**Complex-operation modes** (`:500-559`) — three exclusive toggles (`htn-explorer.html:79-89`)
reset the others via `resetModes` (`:551-559`) and are cancelled by **Escape** (`:392-394`):

- **Add Child** (`addChildMode`, `:507-509`) — pick thesis/counterthesis type, optional parent
  id (or enter it), then `createFromInput` (`:600-627`) resolves the parent's graph and calls
  `htnService.requestEditorSearch('', 'create', parentId, parentGraph, targetName, nodeType)`
  — the editor creates the node (`:622`). Relation hint text (`:519-532`) explains where the
  new node lands.
- **Rewire** (`rewireMode`, `:504-505`) — select exactly two same-graph nodes (`onRewireSelect`,
  `:646-662`); Enter or the +/− buttons call `connectSelected`/`disconnectSelected`
  (`:577-589`) → `htnService.connectNodes`/`disconnectNodes`. **+ Connect / − Disconnect**
  (`htn-explorer.html:121-124`).
- **Prune** (`pruneMode`, `:501-502`) — multi-select same-graph nodes (`onPruneSelect`,
  `:629-644`); `confirmPrune` (`:561-571`) shows a `window.confirm` with the "CRITICAL…
  IRREVERSIBLE" warning before `htnService.pruneNodes(ids, type)`.

The active-mode overlay (`htn-explorer.html:100-134`) renders mode-specific controls; Enter
confirms (connect when 2 rewires selected, else cancel; prune when ≥ 1, else cancel; add-child
cancels) and Escape resets (`htn-explorer.component.ts:374-395`).

**Graph embed** (`htn-explorer.html:210-217`) — `<app-graph>` (graph-lib; see the graph-lib
reference below) receives `graphData` (the current type's `Graph`), `nodesData` (its `Map`),
`referenceNodesData` (**the other graph's** `Map` — the cross-graph `referencers`/refIds
surface as the foreign nodes), `rootId`, `[selectedNodes]="activeSelection"` (the pane id, or
the mode's selection when pruning/rewiring, `:67-73`), and `skipRecursionEdges`; node/link
hover + click events feed the hover tooltips (`:378-406`: node custom properties via
`getCustomProperties`, link `priority`/`condition`) and `onNodeClick`.

**`activeExplorerTrees`** — an `effect` (`:235-245`) publishes `{ triggers, effects, mode,
instanceName }` into `htnService.activeExplorerTrees` (§4.3, signal `htn-state.service.ts:25`,
type `ActiveExplorerTree` `types.ts:130-135`) as the pane or `activeTreeMode` changes. The
metadata window renders one tree (`htn-metadata-menu.html:3-12`, shared recursive template
`htn-metadata-menu.html:19-32`) and its `onNodeClick` (`htn-metadata-menu.component.ts:24-30`)
emits `navigationRequest$` (`core/domain/graph.utils.ts:4`, re-exported `htn.ts`, §4.6/§4.5)
with the id and resolved graph type — the explorer consumes that bus itself at
`htn-explorer.component.ts:247-252` (and `nodeCreated$` at `:254-257` re-selects spawned
roots without a parent).

**Import / export** (`io-utils.ts`) — `exportGraph` (`:5-85`): with a focused `rootId` it
exports that node's **reachable subtree** (BFS over the source graph's `ady` map via
`collectSubtreeIds`, `:21-37,53-55`), otherwise **all nodes** of the current view (`:56-60`);
filename prefix `htn_thesis` / `htn_counterthesis`, or `htn_graph` when there is no root
(`:18,66-69`), plus an ISO timestamp; downloads `{ nodes: […] }` JSON
(`exportData`, `:73-82`). `handleImport` (`:87-111`) reads a chosen `.json` file via
`FileReader`, `processImport` (`:113-177`) then: assigns `crypto.randomUUID()` to id-less
nodes and default `content` (`label: 'Imported Node <4-hex>'`, `:131-139`), forces
`triggers`/`effects` arrays (`:141-142`), buckets by `graph`, unknown graphs → `counterthesis`
(`:144-152`), and per-type calls `htnService.importNodes` (`:155-157`).

> **Reality:** import is **fire-and-forget** — each `importNodes` subscription ignores `next`
> and only logs errors (`:165-174`); it immediately logs "Import started for N nodes"
> (`:176`) without waiting for the backend write to complete.

> **Reality:** the explorer's `getCustomProperties` (`htn-explorer.component.ts:173-195`) is a
> local, slightly divergent copy of the plan's filter — it additionally keeps a truthy
> `justification` key (`:181-182`), so the hover tooltip can show a justification the plan
> card's details pane would hide (plan copy: `plan-utils.ts:283-305`).

#### htn-editor reference (`features/htn-editor/*`)

**Window & shell** — the editor opens as an `'editor'`-type window: `WINDOW_REGISTRY`
(`core/config/window-registry.ts:14`) maps it to `HtnEditorComponent`, which wraps
`<app-window … [windowDefault]="[25, 2, 50, 95]">` (`htn-editor.html:1-2`). The component
(`htn-editor.component.ts:21`, `AfterViewInit`/`OnDestroy`) takes `windowName`/`windowType`
inputs defaulting to `'editor'` (`:22-23`) and resolves them from the host `WindowComponent`
once present (`:28-34`, §4.2).

**Data & request channels** — the constructor subscribes `htnService.getData()` (`:105-137`),
caching `thesisNodes`/`counterthesisNodes` and building the suggestion options (`:110-116`).
`editorSearchRequest$` (`:169-180`) filters on `request.targetWindow === this.windowName`
(`:170-172`) — the window addressed by the caller (§4.2; emitted from the plan/explorer) — and
dispatches `mode:'create'` → `setupCreation` or `mode:'edit'` → `loadEntity`. `refNodeCreated$`
(`:182-190`) sets the edited node's `refId` to the freshly created id, logs, and **auto-saves**
via `save(false)` before activating the window.

> **Reality:** the `getData()` subscription deliberately **does not** overwrite
> `editableContent` on a background refresh (`:131-135`, commented "CRITICAL FIX") — it swaps only
> the `localEntity` pointer, so an open form keeps the user's unsaved edits even if the
> underlying graph changes underneath it.

**Load vs. create** — `loadEntity` (`:231-264`) deep-clones `node.content` (`:248`), seeds
missing flow entries via `htnService.ensureFlowEntries` (`:252`, §4.3), and fills counterthesis
defaults `state:'W'`/`executionOrder:'unit'`/`type:'process'` when absent (`:256-260`).
`setupCreation` (`:208-229`) seeds `editableContent` from `htnService.getDefaultContent` (`:217`,
§4.3) and binds a mock `localEntity` with placeholder id `'New Node'`.

**`HtnContentService`** (`htn-content.service.ts`, `providedIn:'root'`) — the pure content
transformations:

| Method | `:line` | Behaviour |
|---|---|---|
| `sanitize` | `:9-21` | recursive deep-copy dropping empty keys |
| `isRefType` / `getNewValueForType` | `:23-36` | `type === 'referencer'`; typed empty (`''`/`0`/`false`/`{}`/`[]`/`null`) |
| `addProperty` / `removeProperty` / `addArrayItem` / `removeArrayItem` | `:38-61` | key/item CRUD with a has-own guard |
| `updateField` | `:63-73` | sets a field; clears `refId` when `type` changes away from `referencer` |
| `shouldShowRow` | `:75-81` | hides `refId` unless the row's `type` is `referencer` |
| `getSortedKeys` | `:83-115` | order by weight (non-required primitive < non-required object < required primitive < required object), then name; skips the integrity filter for nested (non-root) objects |
| `cleanupContent` | `:117-165` | drops root `priority`, normalizes `flow[*]` (`priority`→0, `condition`→`'next'` for counterthesis, `completed`/`completedCondition` defaults), strips counterthesis-exclusive keys on thesis, clears a stale `refId` |

**Save pipeline** — `save(shouldClose=true)` (`:270-328`): `sanitize` → `cleanupContent`
(`:283,291`) → `validateNodeContent` (`:295`, §4.3). On failure it opens the console and logs
each error without closing (`:298-303`). On success, creating calls `htnService.createNode` with
an `onCreated` callback that notifies the origin window (`notifyRefNodeCreated`) and closes
(`:305-320`); editing calls `htnService.updateNodeContent` (`:322`). `onEnter` (`:266-268`) saves
according to the persisted `enterBehavior`. `exportJson` (`:330-343`) downloads `<id>.json`;
`importJson` (`:345-381`) sanitizes a picked file into `editableContent` (replacing content only,
not the id). `cancel`/`close` (`:383-404`) remove the window; on mobile `switchToPlan`
(`:406-425`) docks/opens the plan window.

> **Reality:** `save()` writes raw `console.log` debug dumps of the graph type, before/after
> content, and validation result (`:288-296`), and `updateField` logs every keystroke update
> (`:476-478`) — these bypass the injected `ConsoleLoggerService`, which carries only the
> validation errors (`:300-301`).

**Rendering** (`htn-editor.html`) — the `☰` menu (`:17-78`) toggles Show Keys, Add Keys, Lock
Fields (`none`/`expanded`/`contracted`), Auto-Resize, and exposes Save / Confirm (Create when
creating) / Export / Import / Cancel; an empty-state menu offers Import only (`:72-77`). The body
is recursive: `jsonEditor` (`:94-234`) renders objects, `arrayEditor` (`:236-274`) arrays, and
`primitiveArrayTpl` (`:276-319`) primitive items, all path-tracked. Rows use `getSortedKeys`;
remove buttons hide via `isPropertyRemovable` (`htn-editor.component.ts:520-538`: root-level
standard keys are protected, and `AnalysisEntry` objects protect `timestamp`/`analysis`). Typed
widgets: `type` (`NODE_TYPES`), `state` (`STATE_OPTIONS`), `executionOrder`
(`EXECUTION_ORDER_OPTIONS`) dropdowns; id fields and `refId` get `suggestion-input` completion
(`getOptions` `:627-640` picks thesis/counterthesis options by path); `refId` also gets a
"+ New Ref" button (`createRefIdNode`, `:199-206`). An `ngOnInit` guard (`:140-144`) throws when
`integrityKeys` (`:82-85`) contains a key outside `NODE_ROOT_STANDARD_KEYS`
(`core/domain/constants.ts:33`).

> **Reality:** booleans persist **immediately** on toggle (`htn-editor.html:219,310`) and
> `refNodeCreated$` auto-saves (`htn-editor.component.ts:186-188`), whereas text/number fields
> save only on Enter — so save timing is field-type-dependent.

**Settings & auto-resize** — three `StorageService` keys are read on init
(`htn_editor_enter_behavior`, `htn_editor_lock_fields`, `htn_editor_auto_resize`, `:147-154`) and
a `htn-config-changed` window listener applies runtime toggles (`:157-167`); `setLockFields`
persists and re-broadcasts that event (`:431-438`). Multiline textareas auto-size through
`requestResize`/`applyAutoResize` (`:560-588`), skipped when the browser supports
`field-sizing: content` (`:72-75`) and when a textarea belongs to a hidden window (`:576-583`); a
`ResizeObserver` (`:590-597`) re-triggers on first paint/undock/resize, disconnected in
`ngOnDestroy` (`:599-606`). Unit coverage in `htn-editor.spec.ts` (auto-resize cases).

#### htn-categories reference (`features/htn-categories/*`)

**Window & shell** — opens as a `'categories'`-type window (`core/config/window-registry.ts:13` →
`HtnCategoriesComponent`), wrapping `<app-window … [windowDefault]="[5, 5, 80, 80]">`
(`htn-categories.html:1-2`). Inputs default to `'categories'` (`htn-categories.component.ts:18-19`)
and resolve from the host `WindowComponent` (`:22-28`, §4.2).

**State & orphans** — `ngOnInit` subscribes `htnService.state$` (`:47-107`): it builds the
counterthesis suggestion options + id→label map (`:55-63`), clones `state.categories` (`:69-71`),
and computes **orphans** — counterthesis nodes with no parents per `counterthesisGraph.inv`
(`:76-84`). A synthesized `default` list (id `'default'`, "Default (Orphans)") is unshifted to the
top if absent and the orphans are pushed into it (`:86-103`). `save()` (`:109-124`) recursively
strips the transient UI flags (`isAddingNode`/`isRemoving`/`isRenaming`) then calls
`htnService.saveCategories` (`:123`, §4.3).

**CRUD actions** — `toggleExpand` (`:128-131`); add-node/remove modes (`:133-150`); inline rename
(`:152-163`); add/remove node (`:165-177`); `addSiblingList` inserts after the target at the same
level (`:182-211`); `addChildList` appends a child (`:213-224`); `removeList` refuses the
`'default'` list (`:226-247`).

**Navigation** — `openInEditor` (`:250-264`) targets the last `'editor'` window or spawns one,
then `requestEditorSearch(id, 'edit', …, targetName)` + activate. `openInExplorer` (`:266-269`)
and `openInPlan` (`:271-274`) call the local `handleWindowActivation`, then emit
`navigationRequest$` / `requestPlanSearch` respectively.

> **Reality:** `handleWindowActivation` (`:276-292`) matches `w.name === command` and never
> spawns; it is called with the literals `'htn-explorer'`/`'htn-plan'`, but
> `WindowService.addWindow` names windows `${type}-<timestamp>` (`window.service.ts:62`), so
> unless a window is explicitly named `htn-explorer`/`htn-plan` the call is a no-op — the request
> channel still fires, so the target may update without being focused. (The console's `nav`
> reuses the same literal, `navigation.handler.ts:35`.)

> **Reality:** the component mutates the `CategoryList` objects in place and re-clones
> `state.categories` on **every** `state$` emit (`:69-71`), so a background refresh mid-edit can
> overwrite unsaved local changes; the synthesized `default` list re-collects orphans on each
> load, so a node removed from it is re-added while it remains parentless.

**Template & model** — `htn-categories.html` renders `categories()` through a recursive
`recursiveList` template (`:9-73`): a header with expand/rename/count and the action row
(`+` add-node, `L+` sub-list, `-` remove-mode, delete — hidden for `default`, `:22-30`); child
lists; a node list whose hover actions are editor/explorer/plan/remove (`:50-56`); the add-node
`suggestion-input` (`:61-65`); and a "shining line" drop-zone for sibling insertion (`:69-71`).
The model is `CategoryList` (`core/domain/types.ts:107-116`, §2.6): `id`, `name`, `nodeIds`,
`children`, `expanded`, plus optional transient `isAddingNode`/`isRemoving`/`isRenaming`. Unit
coverage in `htn-categories.spec.ts` (create only).

#### graph-lib reference (`features/graph-lib/*`)

**Component & shell** — `app-graph` is the standalone wrapper over `@swimlane/ngx-graph`
(§4.1) defined in `graph.ts` (`:20-27`, importing `CommonModule` + `NgxGraphModule`) with
`graph.html`/`graph.scss`. It is consumed **only** by the explorer (`htn-explorer.html:210-217`),
which binds the six inputs and subscribes to all five outputs (`graph.ts:34-44`): `graphData`
(required `Graph`), `nodesData` (required `Map<string, HtnNode>`), `referenceNodesData?`, `rootId`
(required), `selectedNodes` (`Set<string>`), `skipRecursionEdges`; outputs `nodeClick`,
`nodeHoverEvent`, `nodeLeaveEvent`, `linkHoverEvent`, `linkLeaveEvent`.

**Single-node patch** — at module load the file **monkey-patches** ngx-graph (`graph.ts:7-18`):
it captures `GraphComponent.prototype.ngOnChanges` and wraps it to call `update()` whenever
`nodes?.length > 0` but `initialized` is still false. ngx-graph's own `ngOnChanges` skips
`update()` when `links.length === 0`, which leaves `initialized = false` and would hide the graph
through the template's `*ngIf="initialized && graph"`.

> **Reality:** the patch rewrites `GraphComponent.prototype.ngOnChanges` for **every** ngx-graph
> instance app-wide, is applied once with no teardown, and must be removed if a future ngx-graph
> release fixes its zero-link guard.

**Identity & layout** — a static `instanceCounter` gives each instance an `instanceId`
(`graph.ts:145-147`) that namespaces its link ids and SVG marker ids. `layoutSettings` (`:51-58`)
sets the dagre orientation to `BT` for a `thesis` graph and `TB` otherwise, `ranker:
'network-simplex'`, paddings, and `curveDistance: '0'`. `viewDimensions` (default `[500, 500]`,
`:46`) plus the `panOffsetX`/`panOffsetY`/`zoomLevel` signals (`:120-131`) are bound two-way to
`<ngx-graph>` with `autoZoom`/`autoCenter` off and `minZoomLevel` 0.4 (`graph.html:1-5`).

**`loadGraph(graph, nodesMap, rootId)`** (`graph.ts:204-329`) — a BFS from `rootId` over the
graph's **forward `ady`** produces the ngx-graph `nodes`/`links`. Each node (`:252-272`): id
`n-<id>`, `label`, word-wrapped `labelLines` (≤20 chars/line), `graphType`, `executionOrder`
(counterthesis only) and `type`, `layerAvg` = `layer.avg.toFixed(1)`, a `references` array of
cross-graph ref labels resolved via `nodesData` then `referenceNodesData` (`:262-266`), and
`hasChildren`. Each link (`:313-322`): id `l-<instanceId>-<src>-<tgt>`, `isBackEdge`, and a
label built from the **target** node's `flow[source]` entry — `[P:<priority>]` and
` C:<condition>` when present (`:297-322`). Back edges (`neighborDepth < currentDepth`, `:283`)
are dropped entirely when `skipRecursionEdges` is set (`:286-288`).

> **Reality:** only nodes reachable from `rootId` by following `ady` render; a node's cross-graph
> references (`theses`/`countertheses`) appear **only** as label bullets and never as graph nodes —
> `referenceNodesData` is a label lookup, not a second node set.

> **Reality:** `layerAvg` always renders `L:0.0` — it reads `node.layer.avg`, which
> `computeTopology` never assigns (stays `0`, §4.6), so the node subtitle's layer figure is
> constant.

**Refresh & lifecycle** — the constructor (`:149-173`) runs an `effect` that reloads via
`loadGraph` whenever `graphData`/`nodesData`/`rootId` change, pushes `update$.next(true)`, and
re-subscribes to the graph's `update$` (unsubscribing the previous one first, `:159-170`).
`ngAfterViewInit` (`:175-193`) attaches a `ResizeObserver` that updates `viewDimensions` and fires
a one-time `zoomToFit$` (`{force, autoCenter}`) once `graphRef.hasDims()`; `ngOnDestroy`
(`:195-202`) disconnects the observer and subscription.

**Interactions** — `onNodeClick` (`:28-32`) emits `{ id: node.data.originalId, event }`.
`onNodeHover` (`:60-96`) builds `highlightedNodes` = the hovered id + its forward `refId` + every
id whose `refId` points back at it + its forward `ady` children, driving the `reference-highlight`
class; `onNodeLeave` clears it (`:98-102`). Link hover/leave emit `linkHoverEvent`/`linkLeaveEvent`
(`:104-118`).

**Template** (`graph.html`) — `nodeTemplate` (`:6-31`) renders an SVG rect whose classes encode
type (`data`/`process`/`referencer`), `selected`, `execution-set`/`execution-unit`, and
`reference-highlight`, plus the wrapped label, an `n-<id>`/`layerAvg` subtitle, and reference
bullets. `defsTemplate` (`:32-83`) defines the per-instance arrow markers (forward + reverse-start
for thesis, with OR/AND/back-edge colors). `linkTemplate` (`:84-106`) draws a wide transparent
hit-area, the line (back edges stroked `#b53c24`), and a `textPath` label. Type colors are in
`graph.scss:11-50` (data purple, process grey, referencer orange; execution-set dashed; selection
light-grey).

**Model / unit** — `config.ts` holds only commented-out sample `links`/`nodes` and is imported
nowhere. Unit coverage in `graph.spec.ts:1-23` (create only).

#### connection-string-manager reference (`features/connection-string-manager/*`)

**Window & shell** — `ConnectionStringManager` is registered under the window type
`'connection-manager'` (`window-registry.ts:16`) with selector `app-connection-string-manager`
(`connection-string-manager.ts:10-16`). Its template wraps everything in `<app-window>` with custom
header/core styles and default geometry `[30, 20, 40, 60]` (`connection-string-manager.html:1`).
The component takes `windowName`/`windowType` inputs defaulting to `'connection-manager'`
(`connection-string-manager.ts:17-18`) and resolves the effective values through the inner
`WindowComponent` (`:25-31`); `AppComponent` mounts every window instance through a generic
`ngComponentOutlet` loop that passes `{ windowName: win.name, windowType: win.type }`
(`app.component.html:12-13`).

**Opening** — the console `help` table advertises a `connection-manager` command
(`config-utility.handler.ts:43`), but **no factory registers it** (no
`map.set('connection-manager', …)` exists). It still opens the window: because
`connection-manager` is a `WINDOW_REGISTRY` key (`window-registry.ts:16`), the dispatcher's
window-type fallback opens a new instance (`console.handler.ts:190-202`), exactly like typing
`explorer`/`plan`/`console`. The generic paths `dock connection-manager <zone> --open`
(`view.handler.ts:188,220-235` → `WindowService.addWindow`) and `spawn connection-manager`
(`view.handler.ts:193`) reach the same window.

> **Reality:** `connection-manager` has no dedicated `CommandAction` registration, but it is not a
> dead command — the console dispatcher opens it through the window-type fallback
> (`console.handler.ts:190-202`) since it is a registered window type
> (`window-registry.ts:16`).

**Two views** (`connection-string-manager.html:3-88`). The **list view** iterates
`connectionService.connections()` (`:10`), highlights the row whose id equals
`activeConnectionId()` (`:11`), and offers Add / Switch (disabled on the active row) / Edit / Del,
with an empty-state message (`:25-27`). The **edit view** (`:30-87`) is a template-driven
`FormsModule` form (`:34`) with required `name`/`server`/`database` (`:37,42,47`), a conditional
User ID/Password pair shown only when `!integratedSecurity` (`:55-64`), `encrypt` and
`trustServerCertificate` checkboxes (`:67,72`), a success/error test banner (`:76-78`), and a
`Save` button disabled until `connForm.form.valid` (`:84`).

**Component actions** (`connection-string-manager.ts:39-78`) — `editConnection` either clones the
passed config or seeds a new one with `crypto.randomUUID()` and
`integratedSecurity`/`encrypt`/`trustServerCertificate` all `true` (`:39-54`); `cancelEdit` clears
the editor and test status (`:56-59`); `saveConnection` delegates to
`ConnectionService.saveConnection` (`:61-67`); `deleteConnection` is gated by a blocking
`confirm()` (`:69-73`); `activateConnection` calls `setActiveConnection(id)` **then
`htnService.refresh()`** so the graph reloads against the new target (`:75-78`).

**Test connection** (`connection-string-manager.ts:80-104`) — builds a string from the **in-editor**
config via `ConnectionService.buildConnectionString(config)`, base64-encodes it with `btoa` into a
manually constructed `X-Connection-String` header (`:86-87`), and GETs
`${APP_CONFIG.apiUrl}/htn/ping` with the raw `HttpClient` (not through the graph services,
`:89`). It maps the ping body: `database === 'Online'` → `'Connection Successful!'`, otherwise
`Database Offline: <message>`, and transport errors → `Backend Unreachable: <err.message>`
(`:90-102`). The ping wire keys are PascalCase `Backend`/`Database`/`Message`
(`HtnController.cs:60-84`); the component reads the camelCase form with a PascalCase fallback
(`:91-92`). Full ping contract in §3.2, exchange in §2.4.

> **Reality:** `testConnection()` tests the **unsaved** `editingConnection()` (not the persisted
> active connection) and hand-builds the `X-Connection-String` header itself, so it deliberately
> bypasses the `ConnectionService.getActiveConnectionString()` path used by
> `connection.interceptor.ts` — you can prove a database works before saving it.

**Builder** — `ConnectionService.buildConnectionString` (`connection.service.ts:95-109`) is
documented verbatim in §4.3 (`04_frontend.md:248-249`); its exact output is
`Data Source=<server>;Initial Catalog=<database>;` + (`Integrated Security=True;` |
`User ID=<user>;Password=<password>;`) + `Encrypt=<True|False>;` +
`TrustServerCertificate=<True|False>;` + `MultipleActiveResultSets=true;`. Example (integrated
security):
`Data Source=localhost\SQLEXPRESS;Initial Catalog=ResolutionEngineDb;Integrated Security=True;Encrypt=True;TrustServerCertificate=True;MultipleActiveResultSets=true;`.
MARS is appended **unconditionally**.

> **Reality:** connection credentials are stored in **cleartext** — `persist()`
> (`connection.service.ts:81-83`) writes the whole `connections` array (including any
> `user`/`password`) as JSON to `localStorage` under `shiny_connections`, and passwords travel
> `btoa`-encoded only (not encrypted) in `X-Connection-String`. This is the client half of the
> per-request connection seam (**B1**); see `PRODUCTION_CHECKLIST.md`.

**Persistence & active-selection** — `saveConnection` upserts by `id` and `persist()`s
(`connection.service.ts:51-61,81-83`); `deleteConnection` filters the list and, if the deleted id
was active, clears `activeConnectionId` and removes `shiny_active_connection_id` (`:63-70`);
`setActiveConnection` writes/removes that key (`:72-79`); the constructor auto-selects the first
config when the stored active id no longer exists (`:41-48`). Keys and the interceptor contract are
in §4.3.

**Styles / unit** — `connection-string-manager.scss:1-192` (list/edit views, buttons, and the
green/red test banner); unit coverage in `connection-string-manager.spec.ts:1-23` (create only).