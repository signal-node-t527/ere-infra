# ERE Architecture — 05 Frontend Core

> Part 5 of 7 · owns §4.6–§4.7 · index: `00_index.md`

### 4.6 Domain graph algorithms, PWA, styling & tests

Vocabulary for the terms used here (graph, adjacency, layer, trigger, effect, referencer) is
mapped to code in §2.6.

#### Graph algorithms (`graph.utils.ts`)

All graph computation runs in the **frontend** (D6); the backend stores only nodes and the edge list
(§3.3). `core/domain/graph.utils.ts` exports the six symbols below. Types are in §4.7, vocabulary in
§2.6, and the load/save pipeline that calls these is §2.2/§4.3.

**`rebuildAdjacency(g)` (`:6-17`).** Clears the two Maps on `g`, then walks `g.edges` (`[from, to]`
pairs) appending to `ady[from]` (forward) and `inv[to]` (inverse):

```text
ady.clear(); inv.clear()
for (from, to) in g.edges:
    ady[from].push(to); inv[to].push(from)
```

Edges are **not** deduplicated, and isolated nodes never appear as keys — hence the pervasive
`g.ady.get(id) || []` / `g.inv.get(id) || []` idiom. O(E).

**`computeTopology(g)` (`:19-85`).** Returns immediately when `g.nodes` is undefined (`:20`);
otherwise two phases.

*Phase A — layer seeding + trigger/effect synthesis (`:24-53`).* `parents`/`children` come from
`inv`/`ady`:

```text
parents = inv.get(id) or []; children = ady.get(id) or []
if parents is empty:  layer = {longestPath:0, shortestPath:0, avg:0}; enqueue(id)  # root
else:                 layer = {longestPath:-1, shortestPath:Infinity, avg:0}      # sentinels
# rewrite content from adjacency (externalTrigger = stored trigger whose id is NOT a node here, :43,:49):
thesis:        effects = externalTriggers + parents;  triggers = children
counterthesis: triggers = externalTriggers + parents; effects  = children
```

*Phase B — longest/shortest worklist (`:55-84`).* A BFS-like loop (`totalNodes = g.nodes.size`):

```text
while queue not empty:
    current = dequeue(); for child in ady[current]:
        if current.longestPath+1 <= totalNodes and > child.longestPath:
            child.longestPath = current.longestPath+1; changed
        if current.shortestPath+1 < child.shortestPath:
            child.shortestPath = current.shortestPath+1; changed
        if changed: enqueue(child)
```

`proposedLongest <= totalNodes` is the **cycle guard**: in a DAG the longest path can never exceed
`V-1`, so the bound only bites when a cycle would otherwise grow unbounded (capping it at `V`);
`shortestPath` converges from above. Roots are enqueued first, so a node in a cycle with **no inbound
root is never visited** and keeps its sentinels (`longestPath:-1`, `shortestPath:Infinity`).

> **Reality.** `avg` is seeded to `0` (`:28`,`:31`) but **never assigned** by this algorithm, so every
> node's `avg` stays `0` unless it was loaded as a number (the model constructors, §4.7) — yet it is
> rendered (`features/graph/graph.ts:261`, `htn-explorer.html:281,312`).
>
> **Reality.** Phase A **overwrites** `content.triggers`/`content.effects` on every refresh. A stored
> out-of-graph trigger is moved into `effects` (thesis) or kept in `triggers` (counterthesis) on the
> first refresh, but since the stored array it was read from is itself replaced by the in-graph
> children, it is **dropped on the second refresh**.

**`refreshGraph(g)` (`:87-92`).** The single recompute entry point:

```text
rebuildAdjacency(g); computeTopology(g); g.update$?.next(true)
```

`update$?.next(true)` broadcasts to subscribers (a no-op when the graph carries no subject). Called by
`addEdge`/`removeEdge` below and by the state-service refresh pipeline (`htn-state.service.ts:142-144`,
§2.2/§4.3).

**`populateCrossReferences(thesisGraph, counterthesisGraph)` (`:94-140`).** Reconciles both graphs in
three passes plus a dedup helper `addRef` (`:95-99`):

1. **Reset** — set `content.referencers = []` for **every** node in both graphs (`:101-102`).
2. **Counterthesis → thesis** — for each counterthesis, every `content.theses` id that exists in
   `thesisGraph` gets the counterthesis id appended to its `content.countertheses` (`:104-115`).
3. **Thesis → counterthesis** — the mirror pass; every `content.countertheses` id that exists gets the
   thesis id appended to `content.theses` (`:117-128`).
4. **Referencers** — the two graphs are merged into one `Map` (`:130`; the ids share a **single
   namespace**, so a duplicate id across graphs would overwrite), then every node with `type:
   'referencer'` and a resolving `refId` appends its id to the target's `content.referencers`
   (`:132-139`).

Passes 2–3 make the thesis↔counterthesis links consistent from *either* stored side (a union); they
are **additive only** and never prune a stale link (removal is `performComplexRemoval`, §4.3/T11.3).

**`addEdge` / `removeEdge` (`:142-153`).** `addEdge` pushes `[from, to]` (no validation or dedup) then
`refreshGraph`; `removeEdge` splices the first matching pair (no-op if absent) — also followed by
`refreshGraph` when something was removed.

**`navigationRequest$` (`:4`).** `Subject<{view: GraphType; id: string}>`, the cross-component
"navigate to node" bus. Emitters: `htn-categories.component.ts:268`,
`htn-metadata-menu.component.ts:29`, `console/handlers/navigation.handler.ts:36`. Consumer:
`htn-explorer.component.ts:247` (also §4.5).

##### Worked example over the seed graph

Induced adjacency for a slice of the 17 seed thesis edges (§3.3, `DbInitializer.cs`):

| Node | `ady` (children) | `inv` (parents) |
| --- | --- | --- |
| `2bb33b4d` | `59d75979`, `634e76d4`, `aeae87c3`, `if1s1g4` | — (root) |
| `59d75979` | `36fa5286`, `d6e789ae`, `f5bd70be` | `2bb33b4d` |
| `36fa5286` | `634e76d4` | `59d75979` |
| `634e76d4` | — | `2bb33b4d`, `36fa5286` |

`634e76d4` is the seed's only **merge** node (two parents), so Phase B gives it
`longestPath = max(0,2)+1 = 3` but `shortestPath = min(0,2)+1 = 1`. The full computed layering
(`avg` = 0 throughout):

| Nodes | Longest | Shortest |
| --- | --- | --- |
| `2bb33b4d` | 0 | 0 |
| `aeae87c3`, `if1s1g4`, `59d75979` | 1 | 1 |
| `bba04a1d`, `3fa6c3b2`, `35ea1337`, `d6e789ae`, `f5bd70be`, `36fa5286` | 2 | 2 |
| `634e76d4` | 3 | **1** |
| `ar12kal23`, `0as99jj11`, `asd9aj294`, `b8f59c02`, `a403d17a`, `30711547` | 3 | 3 |

Synthesis for the leaf `634e76d4` (thesis): `parents = [2bb33b4d, 36fa5286]`, `children = []`, so
`effects = [...external, 2bb33b4d, 36fa5286]` and `triggers = []`. The root `2bb33b4d` gets
`effects = []` and `triggers = [59d75979, 634e76d4, aeae87c3, if1s1g4]` (its children). A minimal
diamond makes the longest/shortest split explicit:

```text
A ──▶ X        A=(0,0)  B=(1,1)  C=(2,2)  X=(3,1)
│     ▲        X's parents: A (depth 0) and C (depth 2)
▼     │        longest(X) = max(0,2)+1 = 3   (A→B→C→X)
B ──▶ C        shortest(X)= min(0,2)+1 = 1   (A→X)
```

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

### 4.7 Core domain model (`core/domain`)

The lowest frontend layer: plain TypeScript (no Angular, no DI, no HTTP). Four files —
`types.ts`, `models.ts`, `constants.ts` and the `htn.ts` barrel — plus `graph.utils.ts` (the graph
algorithms, covered in §4.6). The server-side counterpart of the node-content shape is §3.5, and
the term glossary is §2.6.

#### Exported types & constants (`types.ts`)

| Export | Kind | Meaning |
| --- | --- | --- |
| `GraphType` | type | Which graph a node belongs to: `'thesis'` or `'counterthesis'` (`:7`). |
| `NODE_TYPES` | const | `['data','process','referencer'] as const` (`:9`); runtime source of `NodeType`. |
| `NodeType` | type | `typeof NODE_TYPES[number]` (`:10`). |
| `THESIS_TYPES` / `COUNTERTHESIS_TYPES` | const | both alias `NODE_TYPES` (`:12-13`); no per-graph subsets exist. |
| `ThesisType` / `CounterthesisType` | type | both alias `NodeType` (`:14-15`). |
| `STATE_OPTIONS` | const | `['W','B','A','S'] as const` (`:17`) — counterthesis execution states. |
| `StateOption` | type | `typeof STATE_OPTIONS[number]` (`:18`). |
| `EXECUTION_ORDER_OPTIONS` | const | `['unit','set'] as const` (`:20`). |
| `ExecutionOrderOption` | type | `typeof EXECUTION_ORDER_OPTIONS[number]` (`:21`). |
| `HtnNode` | type | union of `IThesis` and `ICounterthesis` — the canonical node (`:23`). |
| `Graph` | interface | runtime graph: `edges`, `ady`/`inv` adjacency maps, optional `type`/`nodes`, and an `update$` subject (`:25-32`). |
| `JSONValue` | type | recursive JSON union (`:34`). |
| `JSONArray` | interface | `Array<JSONValue>` (`:36`). |
| `JSONObject` | interface | string-indexed `JSONValue` map (`:38-40`). |
| `NodeContentBase` | interface | alias base for any node-content object (`:42`). |
| `NodeContentRoot` | interface | shared node-content root: `label`, `triggers`, `effects`, `refId`, `referencers` (`:44-50`). |
| `FlowStateBase` | interface | per-flow-entry base: `condition`, numeric `priority` (`:52-55`). |
| `AnalysisEntry` | interface | `timestamp` + `analysis` pair (`:57-60`). |
| `FlowStateCounterthesis` | interface | `FlowStateBase` + `completed`, `completedCondition`, optional `cycles`/`analyzes` (`:62-67`). |
| `NodeContentRootCounterthesis` | interface | counterthesis content: `flow` (of `FlowStateCounterthesis`), `theses`, `state`, `executionOrder`, `type` (`:69-76`). |
| `FlowStateThesis` | interface | empty extension of `FlowStateBase` (`:78`). |
| `NodeContentRootThesis` | interface | thesis content: `flow` (of `FlowStateThesis`), `countertheses`, `type`, `justification` (`:80-85`). |
| `LayerMetrics` | interface | `longestPath`, `shortestPath`, `avg` (`:87-91`). |
| `IThesis` | interface | thesis node: `id`, `graph:'thesis'`, `content`, `layer` (`:93-98`). |
| `ICounterthesis` | interface | counterthesis node: `id`, `graph:'counterthesis'`, `layer`, `content` (`:100-105`). |
| `CategoryList` | interface | explorer category: `id`, `name`, `nodeIds`, nested `children`, `expanded`, optional `isAddingNode`/`isRemoving`/`isRenaming` (`:107-116`). |
| `ParsedCommand` | interface | console command: `command`, `positional`, `keyValues`, `flags` (`:118-123`). |
| `DockRequest` | interface | `windowName` + target `zone` (`:125-128`). |
| `ActiveExplorerTree` | interface | explorer's active node: `triggers`, `effects`, `mode` (`'triggers'`/`'effects'`/`null`), `instanceName` (`:130-135`). |
| `EditorSearchRequest` | interface | editor open intents: `id`, `mode` (`'edit'`/`'create'`), optional `parentId`/`parentGraph`/`newNodeGraph`/`targetWindow`/`originWindow` (`:137-145`). |
| `WindowHandle` | interface | duck-typed panel contract: `windowName()`, `setDocked()`, `docked()`, `initDefaultValues()`, `normalizeValues()` (`:147-153`). |

`Edge`, `Adjacency` and `NodeId` (`:3-5`) are **module-local** — not `export`ed, absent from the
barrel and from `Graph`'s public shape by name.

#### `Thesis` / `Counterthesis` construction (`models.ts`)

Two lightweight factory classes implementing `IThesis`/`ICounterthesis`; each pins `graph` and
normalizes content and layer:

| Behavior | `Thesis` | `Counterthesis` |
| --- | --- | --- |
| `graph` | fixed `'thesis'` (`:11`) | fixed `'counterthesis'` (`:33`) |
| content fallback | `content ?? { label:'', flow:{} }` (`:12`) | same (`:34`) |
| array fallback | `triggers`/`effects`/`countertheses` use the content value when non-empty, else the top-level arg, else `[]` (`:15-17`) | `triggers`/`effects`/`theses`, same rule (`:37-39`) |
| counterthesis-only defaults | — | `state:'W'`, `executionOrder:'unit'`, `type:'process'` (`:40-42`) |
| numeric `layer` | `{longestPath:l, shortestPath:l, avg:l}` for a number, else passed through (`:20`) | same (`:44`) |

These classes are the constructor-level source of truth for normalization (restated from the
`graph.utils.ts` angle in §4.6). The server does **not** mirror this logic — it stores whatever JSON
it receives (§3.3/§3.5).

#### Validation key-sets (`constants.ts`)

| Export | Value (`:line`) |
| --- | --- |
| `NodeContentRootThesisTemplate` | a thesis content object with empty arrays/strings and `type:'process'` (`:3-13`) |
| `NodeContentRootCounterthesisTemplate` | a counterthesis content object with `state:'W'`, `executionOrder:'unit'`, `type:'process'` (`:15-26`) |
| `RuntimeRequiredKeys` | union of the two templates' keys (`:28-31`) |
| `NODE_ROOT_STANDARD_KEYS` | the same union of template keys (`:33-35`) — currently identical to `RuntimeRequiredKeys` |
| `FLOW_STATE_STANDARD_KEYS` | keys of the `FlowStateCounterthesis` shape: `condition`, `priority`, `completed`, `completedCondition`, `cycles`, `analyzes` (`:47`) |
| `GLOBAL_STANDARD_KEYS` | `NODE_ROOT_STANDARD_KEYS` concatenated with `FLOW_STATE_STANDARD_KEYS` (`:49-52`) |
| `REQUIRED_NON_FALSY_KEYS` | `['label','justification']` (`:54-57`) — the keys validation refuses to see empty |

`RuntimeRequiredKeys` and `NODE_ROOT_STANDARD_KEYS` are two names for the same array (the
distinction is historical). These key-sets feed `htn-validation.service.ts` (T11.3).

#### Barrel (`htn.ts`)

`core/domain/htn.ts` (`:1-5`) is a pure re-export module — the single import surface for the layer:

| Line | Re-exports |
| --- | --- |
| `:1` | every type/interface from `types.ts` (the table above) |
| `:2` | the option constants `THESIS_TYPES`, `COUNTERTHESIS_TYPES`, `NODE_TYPES`, `STATE_OPTIONS`, `EXECUTION_ORDER_OPTIONS` |
| `:3` | the `Thesis` / `Counterthesis` classes |
| `:4` | the seven `constants.ts` exports |
| `:5` | `navigationRequest$`, `refreshGraph`, `populateCrossReferences`, `addEdge`, `removeEdge` from `graph.utils.ts` — documented in §4.6 |

