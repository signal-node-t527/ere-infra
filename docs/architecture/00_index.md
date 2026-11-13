# ERE Architecture — Index

> **Entry point for the architecture reference — read this file first.** The former single
> `docs/ARCHITECTURE.md` was split into this folder; see `docs/DECISIONS.md` **D16/D17** for the
> naming/size convention.

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

## Parts (reading order = sorted file order)

Each file name is `<start>-<end>_<description>`: the **`§` range it owns**, then a topic. The list
below is in reading order; ranges are contiguous and non-overlapping, so it is the whole map.

| Part | Topic |
| --- | --- |
| [`1.0-2.6_overview.md`](./1.0-2.6_overview.md) | Repository layout & system context — bootstrap, data-flow lifecycles, connection, vocab map |
| [`3.0-3.4_backend.md`](./3.0-3.4_backend.md) | Backend — solution/config, API surface, domain & persistence, cross-cutting |
| [`3.5-3.6_backend_reference.md`](./3.5-3.6_backend_reference.md) | Backend — node-content schema, source file & class reference |
| [`4.0-4.3_frontend_shell.md`](./4.0-4.3_frontend_shell.md) | Frontend — stack/shell, window system, repository & state layer |
| [`4.4-4.4_frontend_features.md`](./4.4-4.4_frontend_features.md) | Frontend — feature inventory & per-feature deep dives |
| [`4.5-4.7_frontend_core.md`](./4.5-4.7_frontend_core.md) | Frontend — console, graph algorithms/shared components/PWA/tests, core domain model |
| [`5.0-5.3_infrastructure.md`](./5.0-5.3_infrastructure.md) | Infrastructure, containers & deployment; configuration & ports; Dockerfiles & nginx |
| [`6.0-7.0_register.md`](./6.0-7.0_register.md) | Known gaps / assumptions / unknowns register; pointers |

## Navigation rules (for humans and agents)

- **`§x.y` is the canonical, stable reference** used by every doc in `docs/`. Section numbers never
  change; resolve a `§` to its file by the part whose range contains it (the ranges above are
  contiguous, so the list is complete).
- **The file name states the `§` range it owns** (`<start>-<end>_<description>`), so reading order
  is just the sorted file order — there is no separate numbering to keep in sync. A part whose
  owned range changes is **renamed** to match (D17); a part that grows gains a numbered sibling
  covering a sub-range rather than exceeding the cap.
- **Size budget:** 150–500 lines typical, **hard cap 600** per file (`00_index.md` may be shorter).
  See `docs/DECISIONS.md` D16 (scalability protocol) and D17 (range naming).
- **Ownership.** Each `§` has one owner file holding its canonical intro; a `§` may delegate
  `####` subsections to a ref file only when the owner would otherwise exceed the cap (no ref files
  exist today). Extend the owning part to add a section; add a new `<range>_<desc>.md` part (and a
  row above) to add a chapter.

## Pointers

- Decisions behind these facts: [`../DECISIONS.md`](../DECISIONS.md) (D1–D17).
- Dev-only seams to swap/verify before production: `docs/PRODUCTION_CHECKLIST.md` (§7 / §5).
- Current snapshot + next action: `docs/PROJECT_STATE.md`, `docs/CURRENT_TASK.md`.
- Build-out plan for this documentation: `docs/ROADMAP.md`.
