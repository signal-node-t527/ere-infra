# Project State

> **Status: Part I final + Part II in progress (2026-10-10).** Part I
> (P0–P8) is complete and audited: every load-bearing claim lives in `docs/architecture/` with
> `file:line` evidence. The former single `docs/ARCHITECTURE.md` has been **split into
> `docs/architecture/`** (numbered parts, entered via `00_index.md`; D16), and Part II now deepens
> those files in place. This file is the running snapshot and session log.

> **Note (D16).** The architecture reference is a **folder** of ≤600-line files with a stable `§`
> numbering; `docs/architecture/00_index.md` maps every `§` to its file. The split (**T10.5**) is
> done, as are **T11.3** (services reference → §4.3), **T11.4** (repository layer reference → §4.3),
> **T12.1** (window system reference → §4.2), **T12.2** (htn-plan reference → §4.4) and **T12.3**
> (htn-explorer reference → §4.4, in the new owning part `07_frontend_features.md`; D16 amended into
> a scalability protocol); the next work item is **T12.4**.

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
- **P1–P3** `architecture/` (infra, backend, frontend) — done, audited in T8.1.
- **P4** `PROJECT_STATE.md` — done (this file).
- **P5** `DECISIONS.md` backfill — done (D1–D16).
- **P6** `PRODUCTION_CHECKLIST.md` — done (B1–B6, F1–F3, infra, smoke tests).
- **P7** root-doc reconciliation — done.
- **P8** consistency audit + final state — done (T8.1 audit; T8.2 this file).
- **P9** ARCHITECTURE (full) — foundations & schemas — **done (4/4)**: T9.1 (node-content
  schema → `architecture/` §3.5), T9.2 (lifecycle & sequence diagrams → §2.1–§2.5), T9.3
  (configuration & ports matrix → §5.2) and T9.4 (vocabulary & domain code map → §2.6).
- **P10** ARCHITECTURE (full) — backend reference — **done (4/4)**: T10.1 (per-file / per-class
  reference → §3.6), T10.2 (endpoint reference → §3.2), T10.3 (persistence & seed dataset → §3.3)
  and T10.4 (cross-cutting behaviours → §3.4).
- **P10.5** documentation file convention & split — **done (1/1)**: **T10.5** split
  `ARCHITECTURE.md` → `docs/architecture/` (`00_index.md` + `01`–`06`) and recorded the file
  convention as **D16** (which superseded locked decision #7), repointing all entry-point docs.
  D16 was later **amended (T12.3)** into a scalability protocol (owner/ref files, one map row per §,
  bold chapter bands); T12.3 added part `07_frontend_features.md` as the §4.4 owner.
- **P11** ARCHITECTURE (full) — frontend core reference — **done (4/4)**: T11.1 (domain-layer
  reference → §4.7), T11.2 (graph algorithms → §4.6), T11.3 (services reference → §4.3) and T11.4
  (repository layer reference → §4.3).
- **P12** ARCHITECTURE (full) — frontend feature reference — **in progress (3/8)**: T12.1 (window
  system reference → §4.2), T12.2 (htn-plan reference → §4.4) and T12.3 (htn-explorer reference →
  §4.4, in `07_frontend_features.md`); T12.4 (htn-editor & htn-categories reference → §4.4) is next.

The T8.1 audit fixed three drifts: backend seed counts (17 thesis nodes / 17 thesis edges),
the service-worker registration location (`src/index.html:24-30`, not `pwa.service.ts`), and the
now-obsolete "entry-point docs are stale" note in `architecture/` §6.

## What remains / next logical action

Part I (P0–P8) is **complete**. **Part II (P9–P14, full ARCHITECTURE coverage) is in progress**:
P9 is done, and **P10 (backend reference) is complete — T10.1 (per-file / per-class reference →
§3.6), T10.2 (endpoint reference → §3.2), T10.3 (persistence & seed dataset → §3.3) and T10.4
(cross-cutting behaviours → §3.4)**. **The T10.5 split is done** (the reference now lives in the
numbered `docs/architecture/` folder; D16). **Phase 11 is complete (4/4): T11.1 (domain-layer
reference → §4.7), T11.2 (graph algorithms deep-dive → §4.6), T11.3 (services reference → §4.3) and
T11.4 (repository layer reference → §4.3) are done.** **Phase 12 (frontend feature reference) is
in progress (3/8): T12.1 (window system reference → §4.2), T12.2 (htn-plan reference → §4.4) and
T12.3 (htn-explorer reference → §4.4, in the new owning part `07_frontend_features.md`) are done.**
The next documentation ticket
is **T12.4 (htn-editor & htn-categories reference → §4.4)**, in `ROADMAP.md`.

Separately, *product* work surfaced by the docs remains:

- Close the production seams in `PRODUCTION_CHECKLIST.md` (connection-string seam B1, migrations
  B2, auth/CORS B4, hardcoded frontend API URL F1, …).
- Optionally add a backend test project (currently none).

Resume documentation via the one-ticket-at-a-time workflow in `ROADMAP.md`.
