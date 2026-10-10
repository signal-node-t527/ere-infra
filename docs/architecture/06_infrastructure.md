# ERE Architecture — 06 Infrastructure & Gaps

> Part 6 of 6 · owns §5–§7 · index: `00_index.md`

## 5. Infrastructure, containers & deployment topology

### 5.1 Containers, images & topology

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

### 5.2 Configuration & ports matrix

Every runtime setting and port, with where each value comes from. Unless noted, values are read
from the backend's `appsettings*.json` / `launchSettings.json` / `docker-compose.yml` or the
frontend's `angular.json` / `package.json` / `core/config/app-config.ts`.

**Settings**

| Setting | Dev (local) | Container / prod | Source |
|---|---|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Development` (both launch profiles) | `Development` | `launchSettings.json:10,19`; `docker-compose.yml:22` |
| `applicationUrl` (launch profile) | http `http://0.0.0.0:5250`; https `https://0.0.0.0:7150;http://0.0.0.0:5250` | — (uses `ASPNETCORE_URLS`) | `launchSettings.json:8,17` |
| `ASPNETCORE_URLS` | — | `http://+:8080` | `docker-compose.yml:23` |
| `ConnectionStrings:DefaultConnection` | placeholder `Server=YOUR_SERVER;Database=YOUR_DATABASE;Trusted_Connection=True;TrustServerCertificate=True` | `Server=db;Database=ResolutionEngineDb;User Id=sa;Password=${MSSQL_SA_PASSWORD};TrustServerCertificate=True` | `appsettings.json:10`; `docker-compose.yml:24` |
| LocalDB fallback | in-code, only when the resolved string is **empty**: `Server=(localdb)\mssqllocaldb;Database=ResolutionEngineDb;Trusted_Connection=True;MultipleActiveResultSets=true` | same | `Program.cs:36` |
| `MSSQL_SA_PASSWORD` | — (consumed by `db` + the compose override) | `${MSSQL_SA_PASSWORD:-Password123!}` | `docker-compose.yml:7,24` |
| `AllowedHosts` | `*` | `*` | `appsettings.json:8` |
| `Logging:LogLevel` | `Default=Information`, `Microsoft.AspNetCore=Warning` | same | `appsettings.json:2-7`; `appsettings.Development.json:2-7` |
| CORS policy `AllowAngularDev` | any origin, any header, any method | same | `Program.cs:7-16` |
| `APP_CONFIG.apiUrl` | `http://localhost:5250/api` | same — **hardcoded, no env replacement** | `app-config.ts:2` |
| Angular build/serve config | serve default `development`; build default `production` (`outputHashing: all`, budgets) | same | `angular.json:53,61,73` |
| npm script hooks | `prestart`/`prebuild`/`prewatch` run `scripts:index` first | same | `package.json:6-13` |

**Ports**

| Port | Process / service | Dev (host) | Container | Source |
|---|---|---|---|---|
| `5250` | backend HTTP | API on `0.0.0.0:5250` | host `5250` → container `8080` | `launchSettings.json:8`; `docker-compose.yml:26` |
| `7150` | backend HTTPS | https launch profile only (unused by the SPA) | — | `launchSettings.json:17` |
| `8080` | backend in-container | — | `ASPNETCORE_URLS=http://+:8080` | `docker-compose.yml:23`; `Dockerfile:17` |
| `8081` | backend (declared only) | — | `EXPOSE`d with no bound URL | `Dockerfile:18` |
| `1433` | SQL Server 2022 | `1433:1433` | `1433:1433` | `docker-compose.yml:9` |
| `4250` | Angular dev server | `ng serve` (`npm start`) | `frontend-dev` `4250:4250` | `package.json:8`; `angular.json:75`; `docker-compose.yml:54` |
| `4200` | frontend prod (host) | — | `4200` → nginx `80` | `docker-compose.yml:40` |
| `80` | nginx (`frontend-prod`) | — | in-container web root | `Dockerfile:28`; `nginx.conf:2` |

- **Profiles & volumes** (defined in §5.1): `db`/`backend` are always on; `frontend-prod` is the
  `prod` profile, `frontend-dev` the `dev` profile; data persists in the `mssql_data` volume with
  `./backups` bind-mounted.
- **No committed `.env`.** `MSSQL_SA_PASSWORD` is supplied by the environment and falls back to
  `Password123!`; the root `.gitignore` ignores only `backups/`.
- **Host vs container ports.** The API is `:5250` on the host in both modes (dev binds it
  directly; compose maps host `5250 → 8080`). The SPA's hardcoded `http://localhost:5250/api`
  therefore resolves from a host browser even against the prod frontend container (§6 item 6).
- **HTTPS is dev-host only.** The `:7150` https profile is unused by the SPA, and the container
  sets `ASPNETCORE_ENVIRONMENT=Development`, so `UseHttpsRedirection()` stays off
  (`Program.cs:53-56`); `EXPOSE 8081` in the image has no matching URL.
- **`ConnectionStrings__DefaultConnection` is the container seam**; on the host the committed
  placeholder is what the API would use absent an `X-Connection-String` header, so LocalDB is
  reached only when the resolved string is empty (§5.2 settings table, `Program.cs:34-37`).

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
9. **Flow `condition` defaulting is inconsistent.** `HtnService.updateNodeContent` seeds a
   missing parent flow entry with `condition: ''` for **both** graphs
   (`htn.service.ts:109,122`), whereas `HtnGraphService.ensureFlowEntries` and
   `HtnValidationService.getDefaultContent` default counterthesis entries to `'next'`
   (`htn-graph.service.ts:275`; `htn-validation.service.ts:73`). A flow entry's initial
   `condition` therefore depends on which code path created it.
10. **`createNode` passes `parentGraph`, not the node's own graph, to the edge call.**
    When `newNodeGraph` differs from `parentGraph`, the same-graph branch still compares against
    `parentType` but forwards `parentGraph` to `addEdge` (`htn.service.ts:158-168`); the intent
    is correct, but the argument is easy to misread.
11. **`PwaService` is dead code.** `core/services/pwa.service.ts` implements the install-prompt
    lifecycle (`beforeinstallprompt`/`promptInstall`, `pwa.service.ts:11-46`) but is injected
    nowhere — no component or service references it (only its own file does), so the PWA install
    UI it backs is unreachable. The service worker itself is registered separately in
    `src/index.html:24-30` (§4.6), so the app is still a PWA; only the in-app prompt is dead.

## 7. Pointers

- Decisions behind these facts: `docs/DECISIONS.md` (D1–D16).
- Dev-only seams that must be swapped/verified before production: `docs/PRODUCTION_CHECKLIST.md`.
- Current snapshot + next action: `docs/PROJECT_STATE.md`, `docs/CURRENT_TASK.md`.
- Build-out plan for this documentation: `docs/ROADMAP.md`.
- Shipped frontend references (do not duplicate): `shiny-computing-machine/docs/console_script_syntax.md`,
  `shiny-computing-machine/docs/pwa_testing_guide.md`.
