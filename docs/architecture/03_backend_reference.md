# ERE Architecture — 03 Backend Reference

> Part 3 of 7 · owns §3.5–§3.6 · index: `00_index.md`

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

### 3.6 Source file & class reference

A file-by-file map of `resolution-engine`. Each entry lists the file's purpose and its public
members with signatures and `file:line`; behaviour is documented in the cross-linked subsections
(endpoints §3.2, models & persistence §3.3, cross-cutting §3.4, content schema §3.5, config &
deployment §5.1/§5.2, vocabulary §2.6) rather than duplicated here.

#### `Program.cs` — application entry point

Top-level statements (no class): builds and runs the host (`Program.cs:1-67`).

| Member / step | Signature | Where |
| --- | --- | --- |
| Host builder | `var builder = WebApplication.CreateBuilder(args)` | `Program.cs:5` |
| CORS policy `"AllowAngularDev"` | `AddCors(o => o.AddPolicy(…, SetIsOriginAllowed(_ => true) + AllowAnyHeader/AllowAnyMethod))` | `Program.cs:7-16` |
| Controllers + JSON | `AddControllers().AddJsonOptions(o => o.JsonSerializerOptions.PropertyNameCaseInsensitive = true)` | `Program.cs:18-22` |
| HTTP context + provider | `AddHttpContextAccessor()`, `AddScoped<IConnectionProvider, HttpConnectionProvider>()` | `Program.cs:24-25` |
| DbContext (per scope) | `AddDbContext<ApplicationDbContext>(…)` reading `IConnectionProvider`, LocalDB when empty | `Program.cs:28-40` |
| Pipeline | dev `Console.WriteLine` → `UseCors` → `UseHttpsRedirection` (non-Development only) → `MapControllers()` → `Run()` | `Program.cs:42-68` |

No endpoints are mapped here (a `MapGet("/test")` block is commented out, `Program.cs:60-66`).

#### `Controllers/HtnController.cs`

`public class HtnController : ControllerBase` — `[ApiController]` + `[Route("api/[controller]")]`
(`HtnController.cs:7-9`); the main graph API. Bodies and status codes are in §3.2.

| Member | Signature | Where |
| --- | --- | --- |
| Constructor | `HtnController(ApplicationDbContext context)` | `:13-16` |
| `GetThesisNodes` | `ActionResult<IEnumerable<HtnNodeModel>> GetThesisNodes()` | `:18-23` |
| `GetCounterthesisNodes` | `ActionResult<IEnumerable<HtnNodeModel>> GetCounterthesisNodes()` | `:25-30` |
| `GetEdges` | `ActionResult<IEnumerable<HtnEdgeModel>> GetEdges([FromQuery] string graph)` | `:32-37` |
| `UpdateNodeContent` | `IActionResult UpdateNodeContent(string id, [FromBody] object content)` | `:39-53` |
| `Ping` | `ActionResult Ping()` | `:55-87` |
| `DebugConnection` | `ActionResult<object> DebugConnection()` | `:89-98` |
| `GetNode` | `ActionResult<HtnNodeModel> GetNode(string id, [FromQuery] string graph)` | `:100-109` |
| `CreateNode` | `IActionResult CreateNode([FromBody] HtnNodeModel node)` | `:111-134` |
| `DeleteNode` | `IActionResult DeleteNode(string id, [FromQuery] string graph)` | `:136-159` |
| `BatchDeleteNodes` | `IActionResult BatchDeleteNodes([FromBody] List<string> ids, [FromQuery] string graph)` | `:161-192` |
| `AddEdge` | `IActionResult AddEdge([FromBody] HtnEdgeModel edge)` | `:194-220` |
| `RemoveEdge` | `IActionResult RemoveEdge([FromQuery] string from, string to, string graph)` | `:222-241` |
| `MigrateGraph` | `IActionResult MigrateGraph()` | `:243-273` |

#### `Controllers/HtnCategoriesController.cs`

`public class HtnCategoriesController : ControllerBase` — `[ApiController]` +
`[Route("api/[controller]")]` (`HtnCategoriesController.cs:7-9`); the single category document.

| Member | Signature | Where |
| --- | --- | --- |
| Constructor | `HtnCategoriesController(ApplicationDbContext context)` | `:13-16` |
| `GetMain` | `ActionResult GetMain()` | `:18-27` |
| `SaveMain` | `IActionResult SaveMain([FromBody] object jsonContent)` | `:29-59` |

#### `Data/DbInitializer.cs`

`public static class DbInitializer` (`DbInitializer.cs:6`); schema creation + optional seeding
(never invoked from `Program.cs`, §3.3). The seed dataset itself is enumerated in T10.3.

| Member | Signature | Where |
| --- | --- | --- |
| `Initialize` | `static void Initialize(ApplicationDbContext context)` — `EnsureCreated()`, orphan-edge cleanup, thesis/counterthesis/edge seeding | `:8-148` |
| `CreateEdge` | `static HtnEdgeModel CreateEdge(string from, string to, string graph)` (private) | `:150-153` |
| `CreateThesis` | `static HtnNodeModel CreateThesis(string id, string label, string description, int layer, string[]? countertheses = null, Dictionary<string, object>? flow = null)` (private) | `:155-173` |
| `CreateCounterthesis` | `static HtnNodeModel CreateCounterthesis(string id, string label, string description, int layer, string[]? theses = null, Dictionary<string, object>? flow = null, string? informal = null)` (private) | `:175-195` |

#### `Models/HtnNode.cs`

Node entity + its layer metrics (persistence details in §3.3).

| Member | Signature / shape | Where |
| --- | --- | --- |
| `HtnNodeModel` | `public class` | `:5-43` |
| `Id` | `string` (`[Key]`, JSON `"id"`) | `:9-11` |
| `Graph` | `string` (JSON `"graph"`) | `:13-14` |
| `ContentJson` | `string` = `"{}"` (`[JsonIgnore]`) | `:17-18` |
| `Content` | `object?` (`[NotMapped]`, JSON `"content"`; setter serializes) | `:20-28` |
| `LayerJson` | `string` = `"{}"` (`[JsonIgnore]`) | `:31-32` |
| `Layer` | `LayerMetrics?` (`[NotMapped]`, JSON `"layer"`) | `:34-40` |
| `LayerMetrics` | `public class { int LongestPath; int ShortestPath; double Avg }` | `:45-50` |

#### `Models/HtnEdge.cs`

`public class HtnEdgeModel` (graph edge; no FK to nodes, §3.3).

| Member | Signature / shape | Where |
| --- | --- | --- |
| `Id` | `int` (`[Key]`, JSON `"id"`) | `:7-9` |
| `FromId` | `string` (JSON `"fromId"`) | `:11-12` |
| `ToId` | `string` (JSON `"toId"`) | `:14-15` |
| `Graph` | `string` — `'thesis'` or `'counterthesis'` (JSON `"graph"`) | `:17-18` |

#### `Models/HtnCategoryDoc.cs`

`public class HtnCategoryDoc` — `[Table("HtnCategoryDoc")]` singleton category document.

| Member | Signature / shape | Where |
| --- | --- | --- |
| `Id` | `string` = `"main"` (`[Key]`) | `:9-10` |
| `JsonData` | `string` = `"[]"` | `:11` |

#### `Models/TestContext.cs` — unused scaffold

`public partial class TestContext : DbContext` (`Models/TestContext.cs:7`). Not registered or
referenced anywhere in the runtime (no `Program.cs`/controller/config use).

| Member | Signature | Where |
| --- | --- | --- |
| Constructor | `TestContext()` | `:9-11` |
| Constructor | `TestContext(DbContextOptions<TestContext> options)` | `:13-16` |
| `OnConfiguring` | `protected override void OnConfiguring(DbContextOptionsBuilder)` → `UseSqlServer("Name=DefaultConnection")` | `:18-19` |
| `OnModelCreating` | `protected override void OnModelCreating(ModelBuilder)` → `OnModelCreatingPartial` | `:21-24` |
| `OnModelCreatingPartial` | `partial void OnModelCreatingPartial(ModelBuilder)` | `:26` |

#### `Services/ApplicationDbContext.cs`

`public class ApplicationDbContext : DbContext` (`ApplicationDbContext.cs:7`); no
`OnModelCreating`, so there are no relationships/indexes (§3.3).

| Member | Signature | Where |
| --- | --- | --- |
| Constructor | `ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)` | `:8-10` |
| `HtnNodes` | `DbSet<HtnNodeModel>` | `:12` |
| `HtnEdges` | `DbSet<HtnEdgeModel>` | `:13` |
| `HtnCategories` | `DbSet<HtnCategoryDoc>` | `:14` |

#### `Services/HttpConnectionProvider.cs`

`public class HttpConnectionProvider : IConnectionProvider` (`HttpConnectionProvider.cs:7`); the
per-request connection seam (algorithm in §3.4, full matrix §5.2).

| Member | Signature | Where |
| --- | --- | --- |
| Constructor | `HttpConnectionProvider(IHttpContextAccessor httpContextAccessor, IConfiguration configuration)` — caches config `"DefaultConnection"` | `:12-16` |
| `GetConnectionString` | `string GetConnectionString()` — header `X-Connection-String` (base64 → UTF-8, raw fallback) → config `DefaultConnection` | `:18-42` |

#### `Services/IConnectionProvider.cs`

`public interface IConnectionProvider` (`IConnectionProvider.cs:3`); the seam implemented by
`HttpConnectionProvider` and consumed by the per-scope `DbContext` delegate (`Program.cs:34-37`).

| Member | Signature | Where |
| --- | --- | --- |
| `GetConnectionString` | `string GetConnectionString()` | `:5` |

#### Non-source files

| File | Role |
| --- | --- |
| `ResolutionEngine.csproj` | Project file: `Microsoft.NET.Sdk.Web`, `net9.0`, Nullable/ImplicitUsings; 4 packages (`:9-16`). |
| `ResolutionEngine.sln` | Solution wrapper (single project). |
| `Properties/launchSettings.json` | Dev profiles; http `:5250` / https `:7150` (§5.2). |
| `appsettings.json` | Logging, `AllowedHosts`, **placeholder** `DefaultConnection` (§3.1, §5.2). |
| `appsettings.Development.json` | Logging only — no connection string (§3.1). |
| `Dockerfile` / `.dockerignore` / `.gitignore` | Container build + ignore rules (§5.1). |
| `cleanup_weight_column.sql` | Legacy manual `ALTER` evidence — a dropped `Weight` column (§3.3). |
| `ResolutionEngine.http` | HTTP scratch file with a stale `weatherforecast` sample — not runtime (§3.4). |
| `build_log.txt` / `build_output.txt` | Historical `MSB3026` file-lock build failures — not runtime (§3.4). |

