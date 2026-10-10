# ERE Architecture — 02 Backend

> Part 2 of 6 · owns §3.1–§3.4 · index: `00_index.md`

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

`launchSettings.json` exposes http `:5250` and https `:7150`. `appsettings.json:10` holds a
**placeholder** `DefaultConnection` (`Server=YOUR_SERVER;Database=YOUR_DATABASE;…`), and
`appsettings.Development.json` holds **no** connection string (logging only). **LocalDB is only an
in-code fallback** used when the resolved string is empty (`Program.cs:34-37`) — never triggered
by the committed placeholder. The container overrides the value via
`ConnectionStrings__DefaultConnection` (`docker-compose.yml:24`); the full matrix is §5.2.

### 3.2 API surface

Two controllers, both `[ApiController]`, controller-routed (base `api/[controller]`). All endpoints
are unauthenticated (D5/D13). Each controller's source file and members are catalogued in §3.6;
this section documents the wire contract (params, bodies, status codes and exact message strings).

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
(`resolution-engine/Controllers/HtnCategoriesController.cs`):

| Method | Route | Purpose | Evidence |
|---|---|---|---|
| GET | `/` | The `"main"` category document's JSON string (default `"[]"`) | `HtnCategoriesController.cs:18-27` |
| POST | `/` | Upsert the single `"main"` row; re-serializes the body to a string | `HtnCategoriesController.cs:29-59` |

Cross-cutting endpoint behaviour:

- **Cascade deletes** are manual (`RemoveRange` on matching edges before removing nodes), not
  DB FKs — the model has no relationships (§3.3).
- **Alias kept only in the API layer.** `"counterthesis"` is canonical; the `"antithesis"`
  alias is accepted and matched on read paths and `migrate-graph` rewrites persisted rows
  (D4).
- **No resource-level validation** beyond edge endpoint existence; node `content` is accepted
  as-is.
- **No plan/role gates, no pagination, no filtering** beyond the `graph` query parameter.

#### Endpoint reference

Serialized shapes (JSON names come from the model attributes, §3.3):

- **Node** (`HtnNodeModel`) — `{ "id": string, "graph": "thesis"|"counterthesis", "content": <object|null>, "layer": <object|null> }`. `content` is the untyped payload (§3.5/T9.1); `layer` uses
  **PascalCase** keys `{"LongestPath": int, "ShortestPath": int, "Avg": number}` because
  `LayerMetrics` has no `JsonPropertyName` and no global camelCase policy is set (`Program.cs:18-22`).
- **Edge** (`HtnEdgeModel`) — `{ "id": number, "fromId": string, "toId": string, "graph": string }`.

All 500 responses below use the entity CRUD catch-all
`"Internal server error: {ex.Message}"` (`HtnController.cs:132` etc.); the two exceptions are
`ping` (never 500 — it catches internally) and `migrate-graph`
(`"Migration failed: {ex.Message}"`, `:271`).

**`GET api/htn/thesis-nodes`** (`:18-23`) — read all thesis nodes.
Params: none. Body: none. Response: **200** `HtnNodeModel[]` (may be `[]`).

**`GET api/htn/counterthesis-nodes`** (`:25-30`) — read all counterthesis nodes.
Params: none. Body: none. Response: **200** `HtnNodeModel[]` where
`Graph == "counterthesis" || Graph == "antithesis"`.

**`GET api/htn/edges?graph=`** (`:32-37`) — read edges.
Params: `graph` (query, `string`). Body: none. Response: **200** `HtnEdgeModel[]` where
`Graph == graph || (graph == "counterthesis" && Graph == "antithesis")`. If `graph` is omitted the
bound value is `null`, so the filter matches only `Graph == null` (effectively `[]`) — there is
**no 400** for a missing parameter.

**`GET api/htn/nodes/{id}?graph=`** (`:100-109`) — read one node.
Params: `id` (route), `graph` (query) — matched with the `counterthesis`/`antithesis` alias rule.
Response: **200** `HtnNodeModel`, or **404** with an **empty body** (`return NotFound();`).

**`POST api/htn/nodes`** (`:111-134`) — create a node.
Body: a `HtnNodeModel`; `content` may be omitted (`ContentJson` defaults `"{}"`). If `id` is null
or empty a GUID is generated.
- **200** — the created `HtnNodeModel` (with the final `id`).
- **409** — `Node with ID {id} already exists.`
- **500** — `Internal server error: {ex.Message}`.

**`POST api/htn/nodes/{id}/content`** (`:39-53`) — replace a node's `content`.
Params: `id` (route). Body: any JSON object; the `Content` setter serializes it into `ContentJson`.
- **200** — empty body (`Ok()`).
- **404** — **empty body** when the id is unknown.
- **500** — `Internal server error: {ex.Message}` (not wrapped in a try/catch here, so an EF
  failure surfaces as the framework 500; the setter can still throw on non-serializable input).

**`DELETE api/htn/nodes/{id}?graph=`** (`:136-159`) — delete a node + its edges.
Params: `id` (route), `graph` (query, alias rules apply).
- **204** — no content.
- **404** — `Node {id} not found in graph {graph}.`
- **500** — `Internal server error: {ex.Message}`.

**`POST api/htn/nodes/batch-delete?graph=`** (`:161-192`) — delete many nodes + their edges.
Params: `graph` (query). Body: `string[]` of node ids.
- **400** — `No IDs provided.` (null or empty list).
- **200** — `No matching nodes found to delete.` (no id matched the graph).
- **200** — `Deleted {n} nodes and associated edges.`
- **500** — `Internal server error: {ex.Message}`.

**`POST api/htn/edges`** (`:194-220`) — create an edge.
Body: a `HtnEdgeModel` (`fromId`, `toId`, `graph`).
- **200** — the created `HtnEdgeModel`.
- **409** — `Edge already exists.` (same `fromId`/`toId`/`graph`).
- **400** — `Source node {fromId} does not exist in graph {graph}.`
- **400** — `Target node {toId} does not exist in graph {graph}.`
- **500** — `Internal server error: {ex.Message}`.

**`DELETE api/htn/edges?from=&to=&graph=`** (`:222-241`) — delete one edge.
Params: `from`, `to`, `graph` (all query).
- **204** — no content.
- **404** — `Edge not found.`
- **500** — `Internal server error: {ex.Message}`.

**`POST api/htn/migrate-graph`** (`:243-273`) — rewrite `"antithesis"` → `"counterthesis"`.
Params: none. Body: none. Counts are read before the `ExecuteUpdate` calls, so
`*Updated` equals `*Scanned`.
- **200** — `{ "nodesScanned": n, "nodesUpdated": n, "edgesScanned": n, "edgesUpdated": n }`.
- **500** — `Migration failed: {ex.Message}`.

**`GET api/htn/ping`** (`:55-87`) — health probe; calls `EnsureCreated()` + `CanConnect()`.
Always **200** (exceptions are caught); the error case reports the message, not a 5xx.
- Connected: `{ "Backend": "Online", "Database": "Online", "Message": "System operational and schema verified." }`
- Reachable but refused: `{ "Backend": "Online", "Database": "Offline", "Message": "Database is reachable but connection was refused or failed." }`
- Exception: `{ "Backend": "Online", "Database": "Error", "Message": "Database initialization failed: {ex.Message}" }`
(The local `result` object with `Database = "Unknown"` is never returned — dead code, `:58-63`.)

**`GET api/htn/debug-connection`** (`:89-98`) — diagnostics.
Response: **200**
`{ "currentConnectionString": <string with "Password=****">, "headers": { <name>: <value>, … } }`.
`Password=…` is masked by regex `Password=[^;]*` → `Password=****`; **every** request header is
echoed (production risk B4).

**`GET api/htn-categories`** (`HtnCategoriesController.cs:18-27`) — read the category document.
Response: **200** — the `JsonData` string of the `"main"` row, or the literal `"[]"` when absent
(the body is a **JSON string**, so a client must parse it twice to reach the array).

**`POST api/htn-categories`** (`HtnCategoriesController.cs:29-59`) — upsert the category document.
Body: any JSON; re-serialized with `JsonSerializer.Serialize(jsonContent)` and stored on the
`"main"` row (insert or update).
- **200** — empty body (`Ok()`).
- **500** — `Internal server error: {ex.Message}`.

### 3.3 Domain model & persistence

Domain vocabulary (thesis, counterthesis, graph, node, edge, layer, flow) is mapped to code in
§2.6.

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

#### Tables & columns

With no `OnModelCreating`, EF uses the `DbSet` property name as the table name and the model's
data annotations for keys — except `HtnCategoryDoc`, whose `[Table(...)]` overrides it. Column
types are EF Core 9 SQL Server conventions for this `net9.0` project (`HtnNode.cs`,
`HtnEdge.cs`, `HtnCategoryDoc.cs`, `ApplicationDbContext.cs:12-14`).

`HtnNodes` — entity `HtnNodeModel`:

| Column | CLR / annotation | SQL Server | Notes |
| --- | --- | --- | --- |
| `Id` | `string` `[Key]` | `nvarchar(450)` | PK (the 450 = EF's max key width); JSON name `id`. |
| `Graph` | `string` | `nvarchar(max)` | NOT NULL by convention; `"thesis"` / `"counterthesis"` (never `"antithesis"` after migration). |
| `ContentJson` | `string` | `nvarchar(max)` | NOT NULL; the `"{}"` default is a CLR initializer, **not** a DB default. |
| `LayerJson` | `string` | `nvarchar(max)` | NOT NULL; CLR default `"{}"`. |

`Content` and `Layer` are `[NotMapped]` and are never columns. `LayerJson` stores `LayerMetrics`
as text with **PascalCase** keys (`{"LongestPath":0,"ShortestPath":0,"Avg":0}`, §3.2).

`HtnEdges` — entity `HtnEdgeModel`:

| Column | CLR / annotation | SQL Server | Notes |
| --- | --- | --- | --- |
| `Id` | `int` `[Key]` | `int IDENTITY` | PK. |
| `FromId` | `string` | `nvarchar(max)` | NOT NULL; no FK. |
| `ToId` | `string` | `nvarchar(max)` | NOT NULL; no FK. |
| `Graph` | `string` | `nvarchar(max)` | NOT NULL. |

`HtnCategoryDoc` — entity `HtnCategoryDoc` (note: the `DbSet` is named `HtnCategories` but the
explicit `[Table("HtnCategoryDoc")]` wins, so the physical table is **`HtnCategoryDoc`**):

| Column | CLR / annotation | SQL Server | Notes |
| --- | --- | --- | --- |
| `Id` | `string` `[Key]` | `nvarchar(450)` | PK; CLR default `"main"`. |
| `JsonData` | `string` | `nvarchar(max)` | NOT NULL; CLR default `"[]"`. |

Schema properties to note:

- **No foreign keys and no indexes** beyond the primary keys: there are no navigation
  properties and no fluent configuration, so `HtnEdges` is disconnected from `HtnNodes` despite
  `FromId`/`ToId` looking like references. Referential integrity is enforced only in the
  controller (§3.2) and by the seed's orphan-edge cleanup.
- **No DB-level defaults / computed columns**; the string defaults live only as C# initializers.
- **Controller-side cascade** only (manual `RemoveRange`, §3.2) — the DB has no `ON DELETE CASCADE`.

#### Seed dataset (`Data/DbInitializer.cs`)

Three idempotence gates (`if (!_context…Any(…))`, `:26`, `:71`, `:108`) guard thesis nodes,
counterthesis nodes, and edges respectively; the whole method still never runs unless `Initialize`
is invoked (§3.3 above). Every seeded node is created with `layer` = `{LongestPath:0,
ShortestPath:0,Avg:0}` (the `layer` argument is `0` throughout, `:31-101`) and content
`logicalConnector: "AND"` + `description`. The **full** dataset (17 + 8 nodes, 17 + 8 edges,
`DbInitializer.cs:26-147`):

**Thesis nodes (17)** — `id` / `label` / `description`:

| id | label | description |
| --- | --- | --- |
| `2bb33b4d` | Agent Resolution | The root state... |
| `aeae87c3` | Resolution Loops - variable | S0 |
| `if1s1g4` | Resolution Network - constant | Hive Mind |
| `35ea1337` | Core Resolution Loop | S0 |
| `bba04a1d` | stable resolution loop | S0 |
| `3fa6c3b2` | dynamic resolution loop | S0 |
| `ar12kal23` | Core Iteration | Slow iteration... |
| `asd9aj294` | Functional Iteration | Iteration Loops... |
| `0as99jj11` | Sensitive Iteration | Fast iteration... |
| `634e76d4` | Resolution Scheduler (HTN) | Funnel |
| `59d75979` | Resolution Engine - constant | Everything is a problem... |
| `d6e789ae` | Unknown Problems | S1 |
| `f5bd70be` | Known Problems | S1 |
| `36fa5286` | Bad Defined Problems | S1 |
| `b8f59c02` | Ontological Failure | I cannot name it... |
| `a403d17a` | Interpretation Failure | I explain it badly... |
| `30711547` | Causal Failure | I cannot explain it... |

`logicalConnector` is `"AND"` and no thesis seed uses the optional `informal` field here. Every
thesis also seeds `countertheses` (cross-graph ids) and a `flow` map, except the leaf failure nodes
(`b8f59c02`, `a403d17a`, `30711547`) which seed neither (`DbInitializer.cs:31-64`).

**Counterthesis nodes (8)**:

| id | label | `theses` (cross-graph) | `informal` |
| --- | --- | --- | --- |
| `7ef4e6da` | Agent Core Solving | `2bb33b4d` | `A queue is a line of people...` |
| `l0asd142` | Functional Iteration HTN/Chain Triggered Loops (CTL) | `if1s1g4`, `asd9aj294` | — |
| `8aj27askl` | Sensitive Iteration (CL/adaptable/implicit/AEP/VBA) | `if1s1g4`, `0as99jj11` | — |
| `de12vask0` | Core Iteration, (IL/Compounding) | `ar12kal23`, `35ea1337` | — |
| `4a24c84b` | System Incubation (Resolution Engine) IL-1.0 | `59d75979`, `634e76d4` | — |
| `2e5e5e1a` | System Analysis IL-0 (protocol) | `59d75979`, `d6e789ae` | — |
| `aaa81ccf` | System Evaluation IL-1.2 | `f5bd70be` | — |
| `fcb2f489` | System Synthesis IL-1.3 | `36fa5286` | — |

Counterthesis `flow` entries carry `completed: false` and integer `priority` values 1–5
(`DbInitializer.cs:78-101`).

**Thesis edges (17)** — `fromId → toId`:

| From | To |
| --- | --- |
| `2bb33b4d` | `aeae87c3` |
| `2bb33b4d` | `if1s1g4` |
| `aeae87c3` | `bba04a1d` |
| `aeae87c3` | `3fa6c3b2` |
| `aeae87c3` | `35ea1337` |
| `35ea1337` | `ar12kal23` |
| `3fa6c3b2` | `0as99jj11` |
| `bba04a1d` | `asd9aj294` |
| `2bb33b4d` | `634e76d4` |
| `2bb33b4d` | `59d75979` |
| `59d75979` | `d6e789ae` |
| `59d75979` | `f5bd70be` |
| `59d75979` | `36fa5286` |
| `36fa5286` | `634e76d4` |
| `d6e789ae` | `b8f59c02` |
| `d6e789ae` | `a403d17a` |
| `d6e789ae` | `30711547` |

**Counterthesis edges (8)**:

| From | To |
| --- | --- |
| `7ef4e6da` | `l0asd142` |
| `7ef4e6da` | `8aj27askl` |
| `7ef4e6da` | `de12vask0` |
| `de12vask0` | `4a24c84b` |
| `de12vask0` | `2e5e5e1a` |
| `de12vask0` | `aaa81ccf` |
| `de12vask0` | `fcb2f489` |
| `fcb2f489` | `4a24c84b` |

Two seed keys are **not** in the SPA content schema (§3.5): `logicalConnector` (`"AND"`) and
`description`; `informal` appears only on `7ef4e6da`. All seeded nodes carry `layer` 0, and an
orphan-edge cleanup pass runs before seeding (`DbInitializer.cs:12-23`). Seeding is **never
invoked from `Program.cs`** (§3.1), so none of this data exists in a fresh container DB unless
`DbInitializer.Initialize` is called by hand.

### 3.4 Cross-cutting (backend)

#### Per-request connection resolution

The defining multi-database seam: every request's `ApplicationDbContext` is built from a
connection string resolved per scope. `HttpConnectionProvider.GetConnectionString()`:

```text
resolve():                                   # HttpConnectionProvider.GetConnectionString()
  if no HttpContext:   return config["DefaultConnection"]     # :20-21
  raw = Headers["X-Connection-String"]
  if raw present and non-empty:
      try:  return UTF8( base64-decode(raw) )                 # :30-31
      catch: return raw                                       # :35-36  (not valid base64)
  return config["DefaultConnection"]                          # :41

# Program.cs AddDbContext delegate — evaluated per scope (per request) (:28-40):
s = resolve()
if s is empty: s = "<LocalDB connection string>"
UseSqlServer(s)
```

Fallback matrix (first match wins):

| Source | Condition | Result |
| --- | --- | --- |
| `X-Connection-String` header | present, non-empty, valid base64 | decoded UTF-8 string |
| `X-Connection-String` header | present, non-empty, **not** base64 | the raw header text |
| config `DefaultConnection` | header absent/empty (or no HTTP context) | the config value |
| in-code LocalDB | resolved string is empty | `Data Source=(localdb)\…` (`Program.cs:34-37`) |

Precedence is **header > config `DefaultConnection` > LocalDB**. The committed placeholder
(`appsettings.json:10`) is non-empty, so LocalDB only triggers when the config value is empty
(§3.1); the container supplies the config value via `ConnectionStrings__DefaultConnection` (§5.2).
The SPA attaches the header on every call (`connection.interceptor.ts:5-25`); the end-to-end
exchange is traced in §2.4. Because the context is **scoped**, the header is read once per request
and the whole request uses one connection string.

#### JSON round-trip

- **`ContentJson`** (untyped payload, D8). Read: `Content` getter runs
  `JsonSerializer.Deserialize<object>(ContentJson)` → a `JsonElement` DOM (`"{}"` → `{}`; empty
  string → `null`, `HtnNode.cs:24-26`). Write: the request body binds as `object` (an already-parsed
  `JsonElement`), and the setter `JsonSerializer.Serialize(value)` **replaces `ContentJson`
  wholesale** — there is no merge or field diff (`HtnNode.cs:27`). `content` keys are stored
  **verbatim** (case-sensitive), preserving whatever the client sent.
- **`LayerJson`** (`LayerMetrics`). Read: deserialized **case-insensitively**
  (`PropertyNameCaseInsensitive = true`, `HtnNode.cs:38`) so `longestPath`/`LongestPath` both bind;
  empty string → `null`. Write: serialized with the type's own property names, i.e. **PascalCase**
  (`{"LongestPath":…,"ShortestPath":…,"Avg":…}`) — see the §3.2 node shape.
- **Global setting**: `Program.cs:18-22` sets only `PropertyNameCaseInsensitive = true`; there is
  **no** naming policy, so *output* names are the attribute names (camelCase on the entity, via
  `[JsonPropertyName]`) while `LayerMetrics` stays PascalCase. There are **no** `JsonConverter`s,
  discriminators, or type registries anywhere (D8). The schema contract is §3.3/§3.5.

#### Exception → HTTP mapping

- **CRUD catch-all (500).** `CreateNode`, `DeleteNode`, `BatchDeleteNodes`, `AddEdge` and
  `RemoveEdge` each wrap their body in `try/catch (Exception ex)` and return
  `StatusCode(500, $"Internal server error: {ex.Message}")` (`HtnController.cs:130-133` etc.);
  `HtnCategoriesController.SaveMain` uses the same string (`:57`). `MigrateGraph` uses
  `"Migration failed: {ex.Message}"` (`:271`).
- **Unguarded action**: `UpdateNodeContent` has **no** try/catch (`:39-53`); an EF failure there
  escapes to the framework. There is **no** `UseExceptionHandler`/`UseDeveloperExceptionPage` in
  the pipeline (`Program.cs:42-58`), so in Development it surfaces as the default developer
  exception page (HTML stack trace) and in Production as a bare 500.
- **Automatic 400**: `[ApiController]` model validation returns **400 ProblemDetails** *before* the
  action runs, for a missing/unbindable `[FromBody]` (e.g. a malformed `nodes` or `edges` body).
  These bypass the messages above.
- **Explicit codes** (see §3.2 for exact strings): 404 / 400 / 409 are returned deliberately from
  inside the try blocks; nothing else maps to a status.
- **`ping` is special**: it catches its own exceptions and **always returns 200** (never 500).

#### Diagnostics

- **`GET api/htn/ping`** (`HtnController.cs:55-87`) calls `EnsureCreated()` then `CanConnect()`. The
  `EnsureCreated()` is a **side effect**: hitting `ping` on a new connection string creates the
  schema (§3.3). It always returns **200** with one of three bodies (connected / reachable-but-
  refused / error message) — no 5xx, so a monitoring probe cannot tell a DB failure from success by
  status alone (message strings in §3.2). The local `result` object with `Database = "Unknown"` is
  dead code.
- **`GET api/htn/debug-connection`** (`:89-98`) returns the **resolved** connection string
  (`_context.Database.GetConnectionString()`, i.e. the per-request value) with `Password=…` masked
  by regex `Password=[^;]*` → `Password=****`, plus **every** request header echoed verbatim. The
  masking is cosmetic (the string and headers still leak) — production row **B4**.

- **No tests** exist in this project (contrast the frontend's 21 specs) — a gap (§6).
- Non-runtime artifacts at the backend root: `build_log.txt` / `build_output.txt` (historical
  `MSB3026` file-lock build failures from a running `ResolutionEngine.exe`), and
   `ResolutionEngine.http` (a template with a stale `weatherforecast` sample). None are runtime.

