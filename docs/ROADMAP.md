# Roadmap — Documentation Buildout

Master plan for producing the `ere-infra` documentation set to the **same depth and rigor as
`LilithsTest/docs`**. Documentation *is* the product of this workstream: there is **no application
code change** except correcting the entry-point docs and removing the redundant `DOCUMENTATION.md`
(D15).

This is a **forward-looking plan** — it defines what to document next and tracks progress. The
record of reality is `docs/architecture/`; `PROJECT_STATE.md` is the running snapshot, `DECISIONS.md`
the decision log, `PRODUCTION_CHECKLIST.md` the dev-seam registry, `CURRENT_TASK.md` the single
in-flight ticket. **Completed tickets are not kept here** — their detail lives in git history and
`PROJECT_STATE.md`; only the progress table below summarizes them.

The plan has three parts:

- **Part I — Initial buildout (P0–P8): DONE.** Produced the verified overview of the system in
  `docs/architecture/` with `file:line` evidence, plus `PROJECT_STATE.md`, `DECISIONS.md`,
  `PRODUCTION_CHECKLIST.md`, `CURRENT_TASK.md`, and corrected entry-point docs.
- **Part II — Full ARCHITECTURE coverage (P9–P14): DONE.** Deepened the reference into an
  exhaustive per-file / per-endpoint / per-service / per-component reference (§1–§7) with sequence
  diagrams, schemas, and a complete console-command reference.
- **Part III — Reference organization & navigation (P15): DONE.** Reorganized the physical
   layout of `docs/architecture/`: parts are now **named by the `§` range they own**
   (`<start>-<end>_<desc>.md`) so reading order = sorted file order, the `§4` parts are contiguous,
   the `§6–§7` register is its own part, headers drop the `Part N of M` tax, and the index is a
   one-row-per-file list — without changing any `§` content. Docs-only (extends D3/D15).

## Workflow (one ticket at a time)

Take the single top `todo` ticket, copy it into `docs/CURRENT_TASK.md`, write the documentation,
**verify every claim against the code** (`file:line` evidence where it matters), mark `done` (with
date), and bump the progress table. The `Status:` line stays `[ ] todo [ ] in_progress [ ] done`
until the ticket is actually finished — flipping `[x] done` *is* the mark of completion. Don't
pre-check a ticket when scaffolding it.

## How to add a ticket

Append tickets under their phase, in reading order, in this shape:

    ### T<phase>.<n>  <short imperative title>
    Status: [ ] todo  [ ] in_progress  [ ] done
    Blocked by: <T-id | phase | —>
    Files: <exact paths that will change>
    Verify: <the concrete, checkable condition that proves it is done>
    Notes: <the plan while open; replace it with a dated "Done" note when finished>

- One ticket = one focused change; take them one at a time (see Workflow).
- Number `T<phase>.<n>` by phase (`T15.1`, `T15.2`, …); never renumber shipped tickets.
- Open a `## Phase <n> — <title>` heading for a new phase and add its row to the Progress table.
- When a ticket is finished, its Notes are **discarded** (git + `PROJECT_STATE.md` are the record)
  and only its progress-table count is bumped.

## Locked decisions (recorded as D-series in DECISIONS.md)

1. **Docs live in the root `ere-infra` repo** (`docs/`), not in either submodule: the two halves
   (`resolution-engine`, `shiny-computing-machine`) are independent git submodules (`.gitmodules`),
   and the root repo is the integration/infra layer.
2. **The reference reflects reality, not intent**, backed by `file:line` evidence — where the code
   and the docs disagree, the code wins and the discrepancy is recorded (D2).
3. **Document code terms as they are** — do not rename anything as part of documentation (D4).
   Notably the graph value is `"counterthesis"` with `"antithesis"` kept as a compatibility alias
   in the API layer.
4. **No code changes.** The only permitted non-`docs/` edit is `README.md` (the entry doc);
   application source, config, and images are untouched (D3, D15).
5. **Quality bar = LilithsTest/docs**: per-endpoint tables, state machines where relevant,
   "known limits / gaps" sections, and a production checklist whose rows each carry a *production
   action* and a *verification*.
6. **Statuses reflect reality.** Do not pre-check tickets; do not claim a section is verified until
   it has been read against the code.
7. **The architecture reference is a folder of parts** `docs/architecture/` (`00_index.md` + parts
   named `<start>-<end>_<description>.md`) with **stable, append-only `§` IDs** — `§x.y` is the
   citation contract (D16). The file name states the `§` range a part owns and sorts into reading
   order, so a part is renamed when its range changes and file names are never relied on for
   stability (**D17**).
8. **Documentation stays docs-only and additive.** It preserves the realities above and adds no
   source, config, or image changes.

## Progress

| Phase | Scope | Done | Status |
|---|---|---|---|
| P0 | Documentation scaffolding | 1/1 | done |
| P1 | ARCHITECTURE — infrastructure & topology | 2/2 | done |
| P2 | ARCHITECTURE — backend (`resolution-engine`, .NET 9) | 4/4 | done |
| P3 | ARCHITECTURE — frontend (`shiny-computing-machine` / `purgatory-ui`, Angular 20) | 5/5 | done |
| P4 | PROJECT_STATE — snapshot + session log | 1/1 | done |
| P5 | DECISIONS — backfill the decision log | 1/1 | done |
| P6 | PRODUCTION_CHECKLIST — dev-seam registry | 1/1 | done |
| P7 | Root docs reconciliation (`README.md`) | 1/1 | done |
| P8 | Consistency audit + final state | 2/2 | done |
| P9 | ARCHITECTURE (full) — foundations & schemas | 4/4 | done |
| P10 | ARCHITECTURE (full) — backend reference | 4/4 | done |
| P10.5 | Documentation file convention & ARCHITECTURE split | 1/1 | done |
| P11 | ARCHITECTURE (full) — frontend core reference | 4/4 | done |
| P12 | ARCHITECTURE (full) — frontend feature reference | 8/8 | done |
| P13 | ARCHITECTURE (full) — infra & operations reference | 3/3 | done |
| P14 | ARCHITECTURE (full) — assurance & consistency | 4/4 | done |
| P15 | Reference organization & navigation (`docs/architecture/` naming & layout) | 3/3 | done |

Last updated: 2026-10-10

---

# Part III — Reference organization & navigation (P15)

**Purpose.** Parts I–II made the *content* of the reference complete; Part III improves the
**organization** of the `docs/architecture/` folder itself. A layout review (2026-10-10) found six
inefficiencies; the chosen fix is a single idea — **name each part by the `§` range it owns** — that
removes most of them at once, plus a register split. Part III changes **no documented fact** (no
`§` content), only file names, headers, the index, and the D16 convention.
Docs-only (extends D3/D15); no source, config, or image changes.

**The six findings (2026-10-10 review).**

1. **Reading order ≠ `§` order.** The `NN` prefix claimed to be the "reading order" but was actually
   *append order*: `§4.4` lived in part `07` (reached last), and `§4.5` was stranded in part `04`.
2. **Chapter files were interleaved.** `§4` spanned parts `04`, `05` and `07` with `06` (infra)
   between them, so a chapter could not be read by following `NN`.
3. **File names were vague.** `02_backend` vs `03_backend_reference`, and three "frontend" files
   (`04`, `05`, `07`) whose names did not reveal the `§` split.
4. **The cross-cutting register was misfiled.** `§6` (known gaps / assumptions / unknowns) is the
   app-wide register, yet it sat inside the *infrastructure* file.
5. **`Part N of M` was a maintenance tax.** Every header repeated `Part N of M`, so adding a part
   meant editing `M` in *all* headers.
6. **No inline table of contents.** The largest parts (`07` = 562 lines, `02` = 455) had no
   top-of-file subsection index. *(Dropped from the plan 2026-10-10 — no ticket.)*

**The decision (D17).** A part is named **`<start>-<end>_<description>.md`**, where `<start>`/`<end>`
are `§` positions `M.N` (`.0` = the chapter section itself). The name **states the `§` range it
owns** and **sorts into reading order**; ranges are contiguous and non-overlapping. `§x.y` stays the
stable citation, so renames never break a citation. This kills findings 1, 2, 3 and 5 in one move
(and lets `00_index.md` shrink to a one-row-per-file list). Finding 4 is the register split in
T15.1; finding 6 is not scheduled. Recorded as **D17**, superseding D16's `NN_<…>` naming, the
`Part N of M` header, and the "increment `M`" split step.

**Target layout (reached in T15.1).** Ascending file sort = ascending `§`; chapters contiguous:

| Part (file) | Owns |
|---|---|
| `1.0-2.6_overview.md` | §1–§2.6 |
| `3.0-3.4_backend.md` | §3.0–§3.4 |
| `3.5-3.6_backend_reference.md` | §3.5–§3.6 |
| `4.0-4.3_frontend_shell.md` | §4.0–§4.3 |
| `4.4-4.4_frontend_features.md` | §4.4 |
| `4.5-4.7_frontend_core.md` | §4.5–§4.7 |
| `5.0-5.3_infrastructure.md` | §5.0–§5.3 |
| `6.0-7.0_register.md` | §6.0–§7.0 |

## Phase 15 — Reference organization & navigation

### T15.1  Adopt `§`-range part filenames, reorder, and simplify the index
Status: [ ] todo  [ ] in_progress  [x] done
Blocked by: —
Files: `docs/architecture/*` (renames/splits), `docs/architecture/00_index.md`, `docs/DECISIONS.md`
       (D17), `docs/PRODUCTION_CHECKLIST.md`, and live references in the state/plan docs
Verify: file names are `<start>-<end>_<desc>.md` and sort = `§` order; chapters are contiguous;
        headers read `> owns §a–§b · index: …` (no `of M`); `§6–§7` is its own part; `00_index.md`
        is a one-row-per-file list; every `§x.y` citation still resolves; renames via `git mv`
Notes: **Findings #1–#5.** Done 2026-10-10 — renamed all parts (`1.0-2.6_overview`,
       `3.0-3.4_backend`, `3.5-3.6_backend_reference`, `4.0-4.3_frontend_shell`,
       `4.4-4.4_frontend_features`, `4.5-4.7_frontend_core`, `5.0-5.3_infrastructure`,
       `6.0-7.0_register`) via `git mv`; moved `§4.5` (console) into the core part; split `§6–§7`
       into `6.0-7.0_register.md`; dropped `Part N of M` from headers; recorded **D17**; updated the
       live cross-links (`01_overview` listing — now `1.0-2.6_overview.md`; core/register/features
       refs, `PRODUCTION_CHECKLIST` F3).

### T15.2  Simplify `00_index.md` to a one-row-per-file list
Status: [ ] todo  [ ] in_progress  [x] done
Blocked by: T15.1
Files: `docs/architecture/00_index.md`
Verify: no per-`§` map rows remain; the parts list uses the same range numbers as the file names;
        navigation rules state the range-naming/order contract
Notes: Done 2026-10-10 — dropped the "one row per §" table and the "Part boundaries" line for a
       single Parts list keyed by the file-name ranges; rewrote the navigation rules around D17.

### T15.3  Normalize historical part-name references in the state/decision logs
Status: [ ] todo  [ ] in_progress  [x] done
Blocked by: T15.1
Files: `docs/CURRENT_TASK.md`, `docs/PROJECT_STATE.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md`
Verify: no dated log entry names a part file that no longer exists without either the current name
        or a clear "(now …)" marker; live pointers all use the new names
Notes: Done 2026-10-10 — appended inline `` (now `X.md`) `` markers to every dated-log/live mention
       of a renamed part in `CURRENT_TASK.md` and `PROJECT_STATE.md` (and the T15.1 done-note here),
       plus a single historical pointer at the top of the D16 body; the D16 body itself is kept
       verbatim. The remaining old-name mentions are intentional: the Part III findings and D17
       rationale that describe the pre-D17 convention.

**Part III is complete:** all three tickets are `[x] done`, the folder on disk equals the target
layout, D16 is amended (D17), and the citation audit reports 0 out-of-bounds / 0 missing. **No open
documentation tickets remain** — the remaining work is product (`PRODUCTION_CHECKLIST.md`).
