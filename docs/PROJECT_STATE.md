# Project State

> **Status: Part I final + Part II in progress (2026-10-10).** Part I (P0–P8) is complete and
> audited: every load-bearing claim lives in `ARCHITECTURE.md` with `file:line` evidence. Part II
> (P9–P14) deepens `ARCHITECTURE.md` in place; this file is the running snapshot and session log.

## Snapshot — stable build vs. documented reality

The stack is a working three-container dev environment (`db` + `backend` + a `dev`/`prod`
frontend profile) run through the root `docker-compose.yml`. Reality, honestly stated:

- **Backend (`resolution-engine`, .NET 9).** Single-project ASP.NET Core API over SQL Server via
  EF Core 9.0.9. Schema is created by `EnsureCreated()` (**no migrations**); `DbInitializer`
  seeding is **never invoked from `Program.cs`**, so a fresh DB starts empty. **No tests, no
  auth**, open CORS, and a `debug-connection` endpoint that echoes masked connection strings and
  request headers. The DB connection is resolved **per request** from an
  `X-Connection-String` header (base64 or raw) with config/LocalDB fallbacks — the defining
  multi-database seam.
- **Frontend (`shiny-computing-machine` / `purgatory-ui`, Angular 20).** Signal-heavy SPA with a
  custom window system; **21 spec files** (Jasmine/Karma + Jest coexist). The router is empty
  and the outlet is dead — the app is a single shell. The API base URL is **hardcoded** to
  `localhost:5250`. **The graph algorithms (topological layering, cross-references) live here,
  not in the backend** (D6).
- **Infra.** `docker-compose.yml` wires `db` (SQL Server 2022, `:1433`), `backend` (`:5250→8080`,
  `ASPNETCORE_ENVIRONMENT=Development`), `frontend-dev` (`:4250`, profile `dev`) and
  `frontend-prod` (`:4200→80`, profile `prod`) on the `ere-network` bridge.

### Entry-point doc corrections (made in P7 / T7.1)

Both `README.md` and `DOCUMENTATION.md` were stale on arrival and were corrected in T7.1.
`DOCUMENTATION.md` was later **removed** (D15) as redundant; the table below is kept as history
of the corrections:

| Was claimed before T7.1 | Reality (now documented) |
|---|---|
| .NET 8 (`README.md:9,32`; `DOCUMENTATION.md:26`) | **.NET 9** (`ResolutionEngine.csproj:4`) |
| Angular 18 (`README.md:10`; `DOCUMENTATION.md:63`) | **Angular 20** (`package.json:18`) |
| "custom polymorphic converters" (`DOCUMENTATION.md:29`) | **None** — untyped JSON `ContentJson` (D8) |
| `GET /api/Htn/antithesis-nodes` (`DOCUMENTATION.md:49`) | `counterthesis-nodes` (with `antithesis` alias) (D4) |
| Topological analysis in the backend (`DOCUMENTATION.md:83-84`) | In the frontend (`core/domain/graph.utils.ts`) (D6) |
| Frontend dev on `:4200` (`README.md:46,65`) | Dev server `:4250`; `:4200` is the prod nginx port |

## Buildout status (P0–P8 done; P9–P14 in progress)

- **P0** scaffolding — done.
- **P1–P3** `ARCHITECTURE.md` (infra, backend, frontend) — done, audited in T8.1.
- **P4** `PROJECT_STATE.md` — done (this file).
- **P5** `DECISIONS.md` backfill — done (D1–D15).
- **P6** `PRODUCTION_CHECKLIST.md` — done (B1–B6, F1–F3, infra, smoke tests).
- **P7** root-doc reconciliation — done.
- **P8** consistency audit + final state — done (T8.1 audit; T8.2 this file).
- **P9** ARCHITECTURE (full) — foundations & schemas — **in progress (2/4)**: T9.1 (node-content
  schema → `ARCHITECTURE.md` §3.5) and T9.2 (lifecycle & sequence diagrams → §2.1–§2.5) done;
  T9.3–T9.4 todo.

The T8.1 audit fixed three drifts: backend seed counts (17 thesis nodes / 17 thesis edges),
the service-worker registration location (`src/index.html:24-30`, not `pwa.service.ts`), and the
now-obsolete "entry-point docs are stale" note in `ARCHITECTURE.md` §6.

## What remains / next logical action

Part I (P0–P8) is **complete**. **Part II (P9–P14, full ARCHITECTURE coverage) is in progress**:
T9.1 (node-content schema) and T9.2 (lifecycle & sequence diagrams) are done, so the next
documentation ticket is **T9.3 (configuration, environment & ports matrix)** in `ROADMAP.md`.

Separately, *product* work surfaced by the docs remains:

- Close the production seams in `PRODUCTION_CHECKLIST.md` (connection-string seam B1, migrations
  B2, auth/CORS B4, hardcoded frontend API URL F1, …).
- Optionally add a backend test project (currently none).

Resume documentation via the one-ticket-at-a-time workflow in `ROADMAP.md`.
