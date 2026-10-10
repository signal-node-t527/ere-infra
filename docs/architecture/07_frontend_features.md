# ERE Architecture — 07 Frontend Features

> Part 7 of 7 · owns §4.4 (owner) · index: `00_index.md`

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

**Graph embed** (`htn-explorer.html:210-217`) — `<app-graph>` (graph-lib, reference pending
§4.4) receives `graphData` (the current type's `Graph`), `nodesData` (its `Map`),
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