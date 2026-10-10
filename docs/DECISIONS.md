# Decisions

Chronological record of significant decisions made with the user. This file is **seeded by
P0** and progressively backfilled (P5) as the documentation buildout records the decisions
that are only implicit in the code today.

## 2026-10-10 — Session: documentation buildout kickoff

### D1 — Documentation lives in the root `ere-infra` repo
- The `ere-infra` root is its own git repository and integrates two submodules
  (`resolution-engine`, `shiny-computing-machine` via `.gitmodules`). The documentation set
  (`docs/ARCHITECTURE.md`, `PROJECT_STATE.md`, `ROADMAP.md`, `DECISIONS.md`,
  `CURRENT_TASK.md`, `PRODUCTION_CHECKLIST.md`) lives at the root so it can describe the
  system as a whole (compose topology, cross-component seams) without duplicating itself in
  each submodule.
- Rationale: the two halves are independently versioned; only the root sees the whole system.

### D2 — `ARCHITECTURE.md` reflects reality, not intent
- Every load-bearing claim is verified against the code and, where it matters, cited by
  `file:line`. Where the entry-point docs (`README.md`, and `DOCUMENTATION.md` until D15)
  contradicted the code, the code is authoritative; the contradiction is recorded and then
  corrected in P7.
- This is the same rule as `LilithsTest/docs`: "The documentation must reflect reality, not
  the intended state."

### D3 — No application code changes (docs only)
- This workstream changes only files under `docs/`, plus the P7 corrections to the entry-point
  documents and the D15 removal of `DOCUMENTATION.md`. No source, config, or Docker file is
  touched.

### D4 — Document code terms verbatim; do not rename
- The canonical graph value in the backend is `"counterthesis"`, with `"antithesis"` retained
  as a compatibility alias in the API layer (`Controllers/HtnController.cs`). Documentation
  records both and does not propose a rename as part of this workstream.

### D5 — Backend currently has no tests, migrations, or auth (recorded, not fixed)
- The backend uses `EnsureCreated()` rather than EF migrations, has no test project, and
  exposes unauthenticated endpoints. These are documented as the current reality (and become
  PRODUCTION_CHECKLIST rows / future tickets), not changed here.

### D6 — Frontend owns the graph algorithms
- Topological layering and thesis/counterthesis cross-reference population are implemented in
  the frontend (`src/app/core/domain/graph.utils.ts`), not the backend. `LayerMetrics` are
  persisted on nodes but computed client-side. This corrects the entry-point docs, which
  imply the backend performs this analysis.

## 2026-10-10 — Backfill (P5 / T5.1)

These record behaviours that are only implicit in the code today. Each is a decision to
**document the current reality as-is** (per D2/D3) rather than to change it; where it is a
production risk it is also a `PRODUCTION_CHECKLIST.md` row.

### D7 — The DB connection is resolved per request from the `X-Connection-String` header
- `Services/HttpConnectionProvider.cs:18-42` reads the `X-Connection-String` header (base64 →
  UTF-8, raw-string fallback), else config `DefaultConnection`; `Program.cs:28-40` builds the
  `ApplicationDbContext` per scope and substitutes a LocalDB string when the result is empty.
  The SPA attaches the header on every call (`core/services/connection.interceptor.ts:5-25`).
- This is the defining multi-database seam (a client can target any reachable SQL Server) and is
  recorded as production row **B1**; it is not removed or gated in this workstream.

### D8 — Node content is untyped JSON; there are no polymorphic converters
- `HtnNodeModel.ContentJson` (a `string` column) is exposed via the `[NotMapped] object? Content`
  property (`Models/HtnNode.cs:16-28`); writes re-serialize with `JsonSerializer`. There is no
  `JsonConverter`, discriminator, or type registry anywhere.
- This corrects the entry-point docs' "custom polymorphic converters" claim (removed in T7.1).

### D9 — Schema is created by `EnsureCreated()`; seeding is never wired
- There is no `Migrations/`. `Data/DbInitializer.Initialize` (`DbInitializer.cs:8-10`) seeds 17
  thesis nodes, 8 counterthesis nodes, and their edges, but it is **never called from
  `Program.cs`** — only `ping` calls `EnsureCreated()` (`HtnController.cs:68`), so a fresh DB starts
  empty. `EnsureCreated()` cannot evolve an existing schema (`cleanup_weight_column.sql` is
  evidence a manual `ALTER` was needed). Complements D5; production row **B2**.

### D10 — `LayerMetrics` are persisted on nodes but computed client-side
- `HtnNodeModel.LayerJson` / `Layer` (`Models/HtnNode.cs:30-40`) persist
  `{ LongestPath, ShortestPath, Avg }`, but the algorithms that produce them run in the frontend
  (`core/domain/graph.utils.ts`). D6 records the ownership; this records the storage half.

### D11 — The frontend API base URL is hardcoded
- `core/config/app-config.ts:2` is `http://localhost:5250/api`, consumed at
  `core/repository/http.repository.ts:14`; there are no Angular `environment.*` files. Recorded as
  production row **F1**; not changed here.

### D12 — The router is unused; the app is one shell
- `src/app/app.routes.ts:3` exports an empty `Routes` array and `<router-outlet />`
  (`app.component.html:17`) renders nothing; `AppComponent` hosts the whole UI. Documented as-is.

### D13 — CORS is fully open and there is no authentication
- `Program.cs:7-16` registers `"AllowAngularDev"` with `SetIsOriginAllowed(_ => true)` on any
  header/method, and there is no authentication/authorization middleware. Complements D5 (no auth);
  recorded as production row **B4**.

### D14 — Jasmine/Karma and Jest are both configured
- `package.json:17-48` lists both toolchains; `angular.json:82-89` selects the
  `@angular-devkit/build-angular:jest` builder for `ng test`, while Karma/Jasmine specs remain.
  Documented as reality; no consolidation is proposed in this workstream.

## 2026-10-10 — Part II (full ARCHITECTURE coverage)

### D15 — `DOCUMENTATION.md` is removed; `README.md` + `docs/` are the entry points
- The former root `DOCUMENTATION.md` duplicated `README.md` + `docs/ARCHITECTURE.md` while
  carrying stale detail (see `PROJECT_STATE.md`'s corrections table) and a third copy of the
  node-content / endpoint / feature lists to keep in sync. It is **deleted outright** (no
  redirect stub), superseded as follows:
  - models / node content → `ARCHITECTURE.md` §3.3 + §3.5 (T9.1);
  - API endpoints → §3.2; features → §4; deployment → §5; overview/quick-start → `README.md`.
- Consequences: `README.md` drops its `DOCUMENTATION.md` bullet; `ARCHITECTURE.md` §1/§6 and the
  `ROADMAP.md` / `PROJECT_STATE.md` / `CURRENT_TASK.md` references are reworded to past tense;
  T14.3 ("entry-point doc symmetry") now covers `README.md` only. This is the only non-`docs/`
  edit in Part II and extends D3.

### D16 — The architecture reference is a numbered folder with stable `§` IDs
- A single `docs/ARCHITECTURE.md` had reached **1477 lines** (over 2× the quality-bar doc), making
  it slow to navigate and edit. It is **split into `docs/architecture/`** — a folder of parts entered
  via **`00_index.md`**. **Amended (T12.3)** into a *scalability protocol*: the §→file map must
  never degrade into a flat, duplicated pile of rows as content grows, so the rules below define an
  explicit hierarchy and a growth path. The convention now applies to all `docs/` files:
  - **File naming:** `NN_<descriptive_snake_case>.md`, `NN` zero-padded, ordered by reading sequence.
  - **Size budget:** 150–500 lines typical, **hard cap 600** per file (150 is a soft floor;
    `00_index.md` may be shorter). A part that would exceed the cap gains a **new numbered sibling**
    rather than growing.
  - **Index:** a folder's `00_index.md` states its purpose and holds the **§→file map**, reading
    order, and navigation rules.
  - **Stable IDs:** **`§x.y` is the canonical, append-only citation** used by every doc; section
    numbers never change when files are added/split. One chapter may span more than one file, so a
    `§` is resolved through the index, not the file name.
  - **Per-file header:** each part starts with `# … — <title>` + `> Part N of M · owns §a–§b ·
    index: 00_index.md`. A part that only hosts delegated subsections of another part's `§` states
    `owns §c (ref: <owner part>)` instead, so owner and ref files are distinguishable at a glance.
  - **Scope & exemptions:** applies to documentation (`docs/*.md` + root entry `.md`) **only** —
    application source is exempt from the naming rule. Plan/state docs (`ROADMAP.md`,
    `PROJECT_STATE.md`, `CURRENT_TASK.md`, `DECISIONS.md`, `PRODUCTION_CHECKLIST.md`) are **exempt
    from the 600-line cap** (they are append-only logs, not reference parts).

**Scalability protocol (added T12.3):**

- **Ownership.** Each `§x.y` has exactly **one owner file** — the part that holds the §'s
  canonical intro (the overview table / opening paragraph). The owner is listed first in the map.
- **Spanning.** A § may **delegate subsections** to a *ref file* only when the owner would exceed
  the 600-line cap. A ref file must **not** restate the § header or intro; it holds only the moved
  `####` subsections picked up from the owner (or added new), and its header records the owner part.
- **Split procedure.** When a file nears the cap: (1) compress in place (prose→tables, reality
  notes→§6/§7); (2) if still over, move a **contiguous block of subsections of one §** to a new
  `NN` part (never split a `####` in half); (3) the owner keeps the § header, the canonical intro,
  and a short subsection index (`#### … → 07_frontend_features.md`); (4) update the map row and
  increment `M` in every `Part N of M` header.
- **Index discipline.** The §→file map holds **one row per §**; a § that spans files keeps a single
  row whose file cell lists the **owner first**, then ref files (e.g. `04 (owner), 08 (ref: §4.4
  htn-editor)`). Rows are grouped under **bold chapter-band headers** (e.g. `## Frontend — §4`) so
  the map stays scannable as parts multiply.
- **Enforcement.** Part headers must state owner-vs-ref; the map row must match; each ticket's
  done-step re-checks line counts (< 600) and that every `§` still resolves through exactly one row.
- **Consequences:** `docs/ARCHITECTURE.md` is deleted; the folder holds `00_index.md` (map) plus
  `01_overview` (§1–§2), `02_backend` (§3.1–§3.4), `03_backend_reference` (§3.5–§3.6),
  `04_frontend` (§4.1–§4.3, §4.5), `05_frontend_core` (§4.6–§4.7), `06_infrastructure` (§5–§7),
  `07_frontend_features` (§4.4 — owner of the feature references; added T12.3). Existing `§`
  citations throughout `docs/` remain valid unchanged. `README.md`, `AGENTS.md`,
  `PROJECT_STATE.md` and `PRODUCTION_CHECKLIST.md` entry points now point at `00_index.md`. This
  **supersedes ROADMAP locked decision #7** ("one `ARCHITECTURE.md` deepened in place"); heavy
  tickets (T11.3 onward) re-point their `Files:` at the owning part. It extends D3/D15 (docs only).
