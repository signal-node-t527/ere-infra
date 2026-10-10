# Production Checklist

> **Status: audited (2026-10-10, ROADMAP T8.1).** The registry of every seam that must be
> configured, swapped, or verified before a production deployment of `ere-infra`.

**Maintenance rule** (also in `AGENTS.md`): any new feature or seam that only exists in
development MUST be added here with its production action and verification. Docs reflect
reality.

## 1. Operating invariants

A production deployment must satisfy, at all times:

1. The database is a **fixed, configured** SQL Server instance — a client cannot point the API
   at an arbitrary database (the `X-Connection-String` seam is closed or gated).
2. The schema and any seeding are applied by a **repeatable, controlled** process (migrations or
   a release script), never silently by `EnsureCreated()` on first request.
3. The API surface is **not** an open graph editor with unrestricted CORS and unauthenticated
   reads/writes; diagnostics are removed or gated.
4. No default database password, no committed build logs, and no `Development` environment
   behaviour in production.

## 2. Backend seams — `resolution-engine`

| # | Seam | Where | What enables it in dev | Production action | Verify + risk if missed |
|---|---|---|---|---|---|
| B1 | **Per-request connection string** | `Services/HttpConnectionProvider.cs:18-42` reads `X-Connection-String` (base64 → UTF-8, raw fallback) before config | the SPA attaches the header on every request (`connection.interceptor.ts:5-25`), so any SQL Server can be targeted | Decide the production contract: (a) remove the header path and bind to `ConnectionStrings:DefaultConnection`, or (b) keep it behind auth/allow-listing. Do **not** ship an unauthenticated "connect to any DB" seam | With the header path open and no auth, any caller can read/write any database the API host can reach. Verify by sending a foreign `X-Connection-String` and confirming the intended behaviour |
| B2 | **Schema via `EnsureCreated()` + unwired seeding** | `Data/DbInitializer.cs:8-10`; `HtnController.cs:68` (`ping`); `DbInitializer.Initialize` never called from `Program.cs` | first `ping` creates an empty schema in whatever DB is connected | Replace with EF migrations (a `Migrations/` set) or an explicit release script; decide and document the seed policy (dev seed vs. empty prod) | A fresh prod DB has tables but **no data** (seeding is unwired). `EnsureCreated` cannot evolve an existing schema — `cleanup_weight_column.sql` is proof a manual `ALTER` was needed. Risk: schema drift, silent empty DBs |
| B3 | **LocalDB fallback** | `Program.cs:34-37` substitutes `(localdb)\mssqllocaldb` when the connection string is empty | local dev without config | Ensure a real connection string is always supplied via config/env; the Dockerfile notes `(localdb)` cannot work in-container (`Dockerfile:25-27`) | If config is missing in prod, the API silently targets a non-existent LocalDB and every query fails/creates a phantom DB. Verify boot fails fast when the connection string is blank |
| B4 | **Diagnostics + open CORS + no auth** | `HtnController.cs:89-98` (`debug-connection`); `Program.cs:7-16` (`SetIsOriginAllowed(_ => true)`); no auth middleware anywhere | dev convenience | Remove or gate `debug-connection` (it echoes masked connection strings **and all request headers**); restrict the CORS policy to real origins; add authentication/authorization to write endpoints | Unauthenticated `POST /api/htn/edges`, `DELETE /api/htn/nodes/{id}`, etc. mutate the graph; `debug-connection` leaks infrastructure detail. Verify anonymous writes are rejected and `debug-connection` is gone/401 |
| B5 | **OpenAPI package unwired** | `ResolutionEngine.csproj:10` references `Microsoft.AspNetCore.OpenApi`; `Program.cs` never calls `AddOpenApi`/`MapOpenApi` | — | Either wire OpenAPI (dev-only, gated) or drop the reference | No functional risk; dead dependency. Verify the package's intent is decided |
| B6 | **`ASPNETCORE_ENVIRONMENT=Development`** | `docker-compose.yml:22` on the `backend` service | keeps HTTPS redirection off and logs "development environment" (`Program.cs:44-47,53-56`) | Set the environment to `Production` for the deployed backend and terminate TLS at the edge; control it via deployment config, not the committed compose file | With `Development`, `UseHttpsRedirection()` never runs and dev-only behaviour stays on. Verify the deployed process reports Production |

## 3. Frontend seams — `shiny-computing-machine` (`purgatory-ui`)

| # | Seam | Where | What enables it in dev | Production action | Verify + risk if missed |
|---|---|---|---|---|---|
| F1 | **Hardcoded API base URL** | `core/config/app-config.ts:1-3` (`apiUrl: 'http://localhost:5250/api'`); consumed at `http.repository.ts:14` | dev points at the local backend | Introduce environment files or a runtime-config seam and replace with the production API origin (also review CORS in B4) | The prod build (`npm run build`) still calls `localhost:5250`; every request fails off the developer machine. Verify the built bundle's API origin equals the deployed API |
| F2 | **Service worker cache version** | `public/sw.js:1` (`CACHE_NAME = 'resolution-engine-v3'`) | cache-first static assets; network-first navigations | Confirm the cache-busting/version story for releases so clients pick up new bundles; the nginx `location = /scripts/index.json` no-store rule keeps the script manifest fresh (`nginx.conf:20-23`) | A stale `CACHE_NAME` serves old hashed bundles after deploy. Verify a redeploy is observed without manual cache clearing |
| F3 | **Committed build logs / dead scaffolding** | backend `build_log.txt` / `build_output.txt`; frontend `build_error*.log`, `pure.txt`, `verify_graph.ts` + `tsconfig.verify.json` (see `ARCHITECTURE.md` §4.6) | historical artifacts kept in-tree | Confirm none are referenced by the build/runtime and remove or gitignore them | Non-functional; risk is confusion and accidental inclusion. Verify the production build does not depend on them |

## 4. Infra & topology open items — verify before go-live

- **Default DB password.** `docker-compose.yml:7` defaults `MSSQL_SA_PASSWORD` to
  `Password123!`. Production must supply a real secret and never rely on the default.
- **`backups/` bind mount.** `docker-compose.yml:14` bind-mounts `./backups` into the db
  container; confirm the production backup strategy (not a host bind of a dev folder).
- **Frontend port mapping.** `frontend-prod` maps `4200:80` (`docker-compose.yml:40`); the
  README's "access at :4200" only holds for the prod profile (dev is `:4250`).
- **TLS.** TLS is expected at the edge; the backend skips HTTPS redirection under
  `Development` (`Program.cs:53-56`).
- **SQL Server image.** `mcr.microsoft.com/mssql/server:2022-latest` (`docker-compose.yml:3`) —
  `:latest` is unpinned; production should pin a version.
- **Sample data artifact.** `exported-plan.json` at the root is a data export, not source;
  exclude it from any production image.

## 5. Keys, secrets & config checklist

- [ ] SQL Server: real `MSSQL_SA_PASSWORD` (or a dedicated app account) provisioned via secrets;
      `ConnectionStrings__DefaultConnection` set to the managed instance; the `X-Connection-String`
      seam closed or gated (B1/B3).
- [ ] `ASPNETCORE_ENVIRONMENT=Production` for the API (B6).
- [ ] CORS restricted to real origin(s); `debug-connection` removed or gated; auth decision made
      for write endpoints (B4).
- [ ] Schema/seed policy decided and automated (migrations or release script) (B2).
- [ ] Frontend API origin configured for the production build (F1).
- [ ] No committed dev secrets, build logs, or sample exports in the deployed artifacts.

## 6. Pre-flight smoke tests

Run against the deployed environment (not Development):

- [ ] `GET /api/htn/ping` → `{ Backend: "Online", Database: "Online", … }` (schema + connectivity).
- [ ] `GET /api/htn/thesis-nodes` → 200 (list shape); `GET /api/htn/counterthesis-nodes` → 200.
- [ ] Anonymous **write** (`POST /api/htn/edges`, `DELETE /api/htn/nodes/{id}`) → rejected if
      auth is required, or confirmed intentional if the surface is deliberately open.
- [ ] A foreign `X-Connection-String` header → confirmed ignored (B1) if the seam is closed.
- [ ] `debug-connection` → gone or gated (B4).
- [ ] `GET /api/htn-categories` returns `"[]"` or the stored document; `POST` round-trips it.
- [ ] Frontend prod bundle loads from nginx and its API calls hit the production origin, not
      `localhost:5250` (F1).
- [ ] A redeploy is picked up by an existing client (service-worker cache, F2).

## 7. When you add a development-only seam

Add a row to the relevant table (B / F / infra), note the enabling condition, the production
action, and the verification. Do not leave this document behind your change.
