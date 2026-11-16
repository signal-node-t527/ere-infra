# Project State

> **Status: Part I + Part II + Part III final (2026-10-10).** Part I
> (P0–P8) is complete and audited: every load-bearing claim lives in `docs/architecture/` with
> `file:line` evidence. The former single `docs/ARCHITECTURE.md` has been **split into
> `docs/architecture/`** (parts named `<start>-<end>_<description>.md`, entered via `00_index.md`;
> D16/D17), and Part II (P9–P14) deepened those files in place — it is complete. **Part III
> (P15, reference organization & navigation)** renamed and reordered the parts without changing any
> `§` content; **T15.1 (adopt `§`-range filenames + reorder)**, **T15.2 (simplify the index)** and
> **T15.3 (normalize historical references)** are done. This file is the running snapshot and
> session log.

> **Note (D16).** The architecture reference is a **folder** of ≤600-line files with a stable `§`
> numbering; `docs/architecture/00_index.md` maps every `§` to its file. The split (**T10.5**) is
> done, as are **T11.3** (services reference → §4.3), **T11.4** (repository layer reference → §4.3),
> **T12.1** (window system reference → §4.2), **T12.2** (htn-plan reference → §4.4), **T12.3**
> (htn-explorer reference → §4.4, in the new owning part `07_frontend_features.md`, now
> `4.4-4.4_frontend_features.md`; D16 amended into
> a scalability protocol), **T12.4** (htn-editor & htn-categories reference → §4.4), **T12.5**
> (graph-lib reference → §4.4), **T12.6** (connection-string-manager reference → §4.4), **T12.7**
> (console command reference → §4.5) and **T12.8** (shared components & styling reference → §4.6);
> P13 (infra & operations reference) closed with **T13.1** (container / image reference → §5.3),
> **T13.2** (compose topology & container diagram → §5.1) and **T13.3** (build tooling & PWA
> reference → §4.6); **P14 (assurance & consistency) closed with T14.1 (gaps, assumptions &
> unknowns register → §6), T14.2 (full ARCHITECTURE-vs-code audit), T14.3 (entry-point doc
> symmetry → `README.md`) and T14.4 (final state refresh) done** — **all of P0–P14 is done**.

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
  custom window system; **23 spec files** (Jasmine/Karma + Jest coexist). The router is empty
  and the outlet is dead — the app is a single shell. The API base URL is **hardcoded** to
  `localhost:5250`. **The graph algorithms (topological layering, cross-references) live here,
  not in the backend** (D6).
- **Infra.** `docker-compose.yml` wires `db` (SQL Server 2022, `:1433`), `backend` (`:5250→8080`,
  `ASPNETCORE_ENVIRONMENT=Development`), `frontend-dev` (`:4250`, profile `dev`) and
  `frontend-prod` (`:4200→80`, profile `prod`) on the `ere-network` bridge.

### Entry-point doc corrections (made in P7 / T7.1)

Both `README.md` and `DOCUMENTATION.md` were stale on arrival and were corrected in T7.1.
`DOCUMENTATION.md` was later **removed** (D15) as redundant; the table below is kept as history
of the corrections (the pre-correction line numbers are omitted — they no longer exist in the
corrected docs):

| Was claimed before T7.1 | Reality (now documented) |
|---|---|
| .NET **8** (claimed by both entry-point docs) | **.NET 9** (`ResolutionEngine.csproj:4`) |
| Angular **18** (claimed by `README.md`) | **Angular 20** (`package.json:18`) |
| "custom polymorphic converters" in node content (claimed by `DOCUMENTATION.md`) | **None** — untyped JSON `ContentJson` (D8) |
| `GET /api/Htn/antithesis-nodes` (claimed by `DOCUMENTATION.md`) | `counterthesis-nodes` (with `antithesis` alias) (D4) |
| Topological analysis in the backend (claimed by `DOCUMENTATION.md`) | In the frontend (`core/domain/graph.utils.ts`) (D6) |
| Frontend dev on `:4200` (claimed by `README.md`) | Dev server `:4250`; `:4200` is the prod nginx port |

## Buildout status (P0–P15 done)

- **P0** scaffolding — done.
- **P1–P3** `architecture/` (infra, backend, frontend) — done, audited in T8.1.
- **P4** `PROJECT_STATE.md` — done (this file).
- **P5** `DECISIONS.md` backfill — done (D1–D16).
- **P6** `PRODUCTION_CHECKLIST.md` — done (B1–B6, F1–F5, infra, smoke tests).
- **P7** root-doc reconciliation — done.
- **P8** consistency audit + final state — done (T8.1 audit; T8.2 this file).
- **P9** ARCHITECTURE (full) — foundations & schemas — **done (4/4)**: T9.1 (node-content
  schema → `architecture/` §3.5), T9.2 (lifecycle & sequence diagrams → §2.1–§2.5), T9.3
  (configuration & ports matrix → §5.2) and T9.4 (vocabulary & domain code map → §2.6).
- **P10** ARCHITECTURE (full) — backend reference — **done (4/4)**: T10.1 (per-file / per-class
  reference → §3.6), T10.2 (endpoint reference → §3.2), T10.3 (persistence & seed dataset → §3.3)
  and T10.4 (cross-cutting behaviours → §3.4).
- **P10.5** documentation file convention & split — **done (1/1)**: **T10.5** split
  `ARCHITECTURE.md` → `docs/architecture/` (`00_index.md` + `01`–`06`, now `1.0-2.6_overview.md`…
  `6.0-7.0_register.md`) and recorded the file
  convention as **D16** (which superseded locked decision #7), repointing all entry-point docs.
  D16 was later **amended (T12.3)** into a scalability protocol (owner/ref files, one map row per §,
  bold chapter bands); T12.3 added part `07_frontend_features.md` (now `4.4-4.4_frontend_features.md`) as the §4.4 owner.
- **P11** ARCHITECTURE (full) — frontend core reference — **done (4/4)**: T11.1 (domain-layer
  reference → §4.7), T11.2 (graph algorithms → §4.6), T11.3 (services reference → §4.3) and T11.4
  (repository layer reference → §4.3).
- **P12** ARCHITECTURE (full) — frontend feature reference — **done (8/8)**: T12.1 (window
  system reference → §4.2), T12.2 (htn-plan reference → §4.4), T12.3 (htn-explorer reference →
  §4.4, in `07_frontend_features.md` (now `4.4-4.4_frontend_features.md`)), T12.4 (htn-editor & htn-categories reference → §4.4),
  T12.5 (graph-lib reference → §4.4), T12.6 (connection-string-manager reference → §4.4),
  T12.7 (console command reference → §4.5) and T12.8 (shared components & styling reference → §4.6).
- **P13** ARCHITECTURE (full) — infra & operations reference — **done (3/3)**: T13.1
  (container / image reference → §5.3), T13.2 (compose topology & container diagram → §5.1) and
  T13.3 (build tooling & PWA reference → §4.6, incl. §6 item 14) done.
- **P14** ARCHITECTURE (full) — assurance & consistency — **done (4/4)**: T14.1 (gaps,
  assumptions & unknowns register → §6 recast + seven new `[GAP]` items; PRODUCTION_CHECKLIST rows
  F4/F5 added), **T14.2 (full ARCHITECTURE-vs-code audit)** — 666 citations, 0 out-of-bounds, 0
  missing after fixes; inventories match disk; fixed the §5.3 `ENTRYPOINT` citation and the stale
  corrections-table cites — **T14.3 (entry-point doc symmetry)** — `README.md` uses the canonical
  Counterthesis term, gained the prod `:4200` access line, and two blank-line cite slips in
  `06_infrastructure.md` (now `5.0-5.3_infrastructure.md`; §5.1 run-command table) were fixed — and **T14.4 (final state refresh)**.
- **P15** Reference organization & navigation — **done (3/3)**: **T15.1 (adopt `§`-range part
  filenames + reorder + register split)**, **T15.2 (simplify `00_index.md`)** and **T15.3 (normalize
  historical part-name references)**. Docs-only; amends D16 (recorded as **D17**). No `§` content
  changes.

**ROADMAP maintenance (2026-10-10).** `docs/ROADMAP.md` was pruned to be **forward-looking only**:
the completed P0–P14 ticket bodies (and the kickoff-session note) were removed — their record is git
history and this file. The repo-wide `file:line` citation audit now reports **628** tokens (was 666
at T14.2, which counted the now-removed ROADMAP history; 38 of them lived there); `docs/architecture/`
content and all `§` citations are unchanged (0 missing, 0 out-of-bounds).

**Part III (2026-10-10).** **T15.1** renamed every part to `<start>-<end>_<description>.md`
(so ascending file sort = `§` reading order with contiguous chapters), moved `§4.5` into the core
part, split `§6–§7` into `6.0-7.0_register.md`, dropped `Part N of M` from the headers, recorded
**D17** (superseding D16's `NN_<…>` naming, the `Part N of M` header, and the "increment `M`" step),
and updated the live cross-links; **T15.2** rewrote `00_index.md` as a one-row-per-file list;
**T15.3** appended inline `` (now `X.md`) `` markers to the historical log references (the Part III
findings and D17 rationale still quote the old names by design, and the D16 body is kept verbatim
under a single pointer). `§` citations are unchanged.

The T8.1 audit fixed three drifts: backend seed counts (17 thesis nodes / 17 thesis edges),
the service-worker registration location (`src/index.html:24-30`, not `pwa.service.ts`), and the
now-obsolete "entry-point docs are stale" note in `architecture/` §6.

## Product work (post-P15)

### 2026-11-13 — `search-content` console command

New read-only console verb that finds nodes by free text in their content:
`search-content <text> [--type=thesis|counterthesis] [--field=propKey] [--case] [--ids] [--limit=n]`
(`features/console/handlers/search.handler.ts`). Each invocation fetches
`/htn/thesis-nodes` + `/htn/counterthesis-nodes` (with the usual `X-Connection-String` header) and
deep-scans every string value in `content` — `label`, `justification`, `flow.<id>.condition`,
`analyzes[]`, triggers/effects arrays — case-insensitively by default (D19).

Output is a `help-table` with one row per matched node: **Graph | ID | Field | Match**. The ID cell
is `formatNodeId(id, label)`, so hovering shows the label as a tooltip and the existing copy button
puts the ID on the clipboard; the snippet is HTML-escaped and the matched text is wrapped in
`.search-hit`. A node with several matching fields shows its first hit plus `(+N)`. The default
`--limit` is 100 rows and a truncation warning is logged past it.

Supporting changes: `formatNodeId` (`console-logger.service.ts:28-32`) gained an optional label and
now escapes the id and tooltip; `HandlerContext.formatNodeId` widened to `(id, label?)`; the
referencer handler's local `idWithTitle` was deleted in favour of it; `createSearchCommands` joined
the eleven factory modules (`console.handler.ts:128`), and the `help` table row feeds
`KNOWN_COMMAND_NAMES` (now **45 verbs / 46 registrations**). New
`handlers/search.handler.spec.ts` (15 tests) brings the frontend to **23 spec files**.

`npm run build` passes (pre-existing 1 MB budget warning). `npm test`: the new suite passes; the
same 9 pre-existing suites fail (jsdom `window.matchMedia` / missing `HttpClient` providers),
13 failed / 156 passed (169 total).

### 2026-11-03 — referencer state `D` (Disabled)

`STATE_OPTIONS` gained `'D'` (`core/domain/types.ts:17`), so the htn-editor `state` dropdown offers it
automatically. The plan's presentational card applies a new `state-d` class to referencer steps
(`plan-node-card.component.html:39`) and renders them dark grey — grey left border/label and a grey
badge (`plan-node-card.component.scss:121-130`); `state-s` gained an explicit rule mirroring its
previous inherited referencer colours (`:108-119`). The change is **visual only**: no planner,
validation, integrity or backend code reads `state`, and existing nodes need no migration (the
backend stores `content` as untyped JSON). New spec `plan-node-card.component.spec.ts` covers the
class bindings; the frontend is now 22 spec files. `npm run build` passes; `npm test` still reports
the 9 pre-existing failing suites (jsdom `window.matchMedia` / missing `HttpClient` providers) with
141 passing tests (154 total).

## What remains / next logical action

**All documentation phases are complete — P0–P15 is done.** Part I (P0–P8)
produced the verified overview; Part II (P9–P14, full ARCHITECTURE coverage) deepened it into the
numbered reference `docs/architecture/` (D16). **P14 (assurance & consistency)** closed with T14.1
(gaps/assumptions/unknowns register → §6 + PRODUCTION_CHECKLIST rows F4/F5), T14.2 (the full
ARCHITECTURE-vs-code audit — 666 citations, 0 out-of-bounds, 0 missing after two docs-only fixes),
T14.3 (entry-point doc symmetry → `README.md`) and T14.4 (final state refresh). **Part III (P15,
reference organization & navigation)** closed with T15.1 (adopt `§`-range part filenames + reorder),
T15.2 (simplify the index) and T15.3 (normalize historical references): the parts are named
`<start>-<end>_<description>.md` by the `§` range they own (reading order = sorted file order;
**D17**), `§4` is contiguous, the `§6–§7` register is its own part, headers drop the `Part N of M`
tax, and `00_index.md` is a one-row-per-file list. Docs-only and `§`-preserving.

*Product* work surfaced by the docs remains:

- Close the production seams in `PRODUCTION_CHECKLIST.md` (connection-string seam B1, migrations
  B2, auth/CORS B4, hardcoded frontend API URL F1, …).
- Optionally add a backend test project (currently none).

**No open documentation ticket remains** — `docs/ROADMAP.md` (`P0–P15`) is fully `done`. Resume any
documentation work via the one-ticket-at-a-time workflow by adding a new ticket to `ROADMAP.md`
first.
