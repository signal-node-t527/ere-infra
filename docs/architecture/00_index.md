# ERE Architecture — Index

> **Entry point for the split architecture reference — read this file first.** The former single
> `docs/ARCHITECTURE.md` was split into this folder; see `docs/DECISIONS.md` **D16** for the
> file-naming/size convention.

> **Status: audited (2026-10-10, ROADMAP T8.1).** Written against the code as it exists today;
> every load-bearing claim cites `file:line`, and the T8.1 audit re-read each claim against the
> tree. This document is the record of **reality**, not intent; where the entry-point docs
> disagreed with the code, the code won (recorded in §6 and fixed in T7.1; the redundant
> `DOCUMENTATION.md` was then removed — D15).

> ERE (Explicit Resolution Engine) models and resolves complex problems as a **dialectic
> graph**: **Thesis** nodes (structures/regularities) and **Counterthesis** nodes
> (processes/flows). It is an infra monorepo whose two halves are independent git submodules:
> `resolution-engine` (.NET 9 ASP.NET Core API over SQL Server via EF Core) and
> `shiny-computing-machine` (package name **`purgatory-ui`** — an Angular 20 signal-heavy SPA
> with a custom window system). The graph algorithms live in the **frontend**.

## How this folder is organized

The file name prefix (`NN`) is the **reading order**; the `§` number is the **stable citation**.
They are related but not identical — one chapter may span more than one file. Always resolve a
`§x.y` citation through the map below, not through the file name.

| Section | Topic | File |
| --- | --- | --- |
| §1 | Repository Layout | [`01_overview.md`](./01_overview.md) |
| §2 (2.1–2.6) | System Context / Data Flow — lifecycles, connection, vocab map | [`01_overview.md`](./01_overview.md) |
| §3.1–§3.4 | Backend — solution/config, API surface, domain & persistence, cross-cutting | [`02_backend.md`](./02_backend.md) |
| §3.5–§3.6 | Backend — node-content schema, source file & class reference | [`03_backend_reference.md`](./03_backend_reference.md) |
| §4.1–§4.5 | Frontend — stack/shell, window system, repository/state, features, console | [`04_frontend.md`](./04_frontend.md) |
| §4.6–§4.7 | Frontend — graph algorithms/PWA/tests, core domain model | [`05_frontend_core.md`](./05_frontend_core.md) |
| §5–§7 | Infrastructure & deployment, known limits/gaps, pointers | [`06_infrastructure.md`](./06_infrastructure.md) |

Each part file begins with a one-line header stating the `§` range it owns. Part boundaries:
`01` §1–§2 · `02` §3.1–§3.4 · `03` §3.5–§3.6 · `04` §4.1–§4.5 · `05` §4.6–§4.7 · `06` §5–§7.

## Navigation rules (for humans and agents)

- **`§x.y` is the canonical, stable reference** used by every doc in `docs/`. Section numbers never
  change; the map above is the single source of truth for which file holds a section.
- **Files are append-only and never renumbered.** A part that would exceed the size limit gains a
  new numbered sibling (and a new map row), rather than being split mid-file.
- **Size budget:** 150–500 lines typical, **hard cap 600** per file (`00_index.md` may be shorter).
  See `DECISIONS.md` D16.
- When adding a section, extend the owning file; when adding a whole chapter, append the next `NN`
  and update the map here.

## Pointers

- Decisions behind these facts: [`../DECISIONS.md`](../DECISIONS.md) (D1–D16).
- Dev-only seams to swap/verify before production: `docs/PRODUCTION_CHECKLIST.md` (§7 / §5).
- Current snapshot + next action: `docs/PROJECT_STATE.md`, `docs/CURRENT_TASK.md`.
- Build-out plan for this documentation: `docs/ROADMAP.md`.
