# Changelog

## Unreleased

UI fix only; no public API, file format or save schema change, so VERSION stays 0.1.0.

- F2 tuning panel: an empty search listed nothing, because Godot's `contains("")` is false. F2 now opens with every tuning group listed and collapsed: game and kit settings first, then feel stages, each alphabetical. Clicking a group opens it. A search matches every typed word against group, knob name and help text, and opens each matching group. A search with no match says so.
- F2 search box: it now has a visible border and background, a Search label, example hint text and a Clear button, and it takes the cursor when F2 opens.
- F2: Apply, Discard and Save as variant now sit at the top of each open group instead of below its last knob, where long groups hid them. Slider tooltips are removed: they repeated the help line already shown under each slider, over a hard-to-read translucent background.
- F1 Log tab: it was always empty for the same `contains("")` reason. Empty filters now show every action. Each line names the action's inputs (e.g. its target), and refused actions list the failed rule and its message underneath.
- Overlay look: one shared theme. Buttons are outlined; the main action (Apply) is filled; tuning group headers are banded rows with an accent bar; help text is quieter and smaller; section labels use the accent colour; inputs, lists and tabs are boxed.
- F1 Why tab: it has its own Thing and Value pickers, so it no longer depends on the World tab's selection. A notice at its top always explains the newest refused action, whatever is selected, with a button to show the thing it was aimed at.
- tools/kit.ps1 and tools/verify_install.ps1 no longer die under Windows PowerShell 5.1 when Godot prints a warning. With $ErrorActionPreference 'Stop', 5.1 turns each stderr line of a native program into a terminating error; Godot runs are now captured as text under 'Continue', and the scripts' own checks decide what fails. Both scripts also create reports/.gdignore, so Godot no longer scans install-smoke projects or report screenshots ("Detected another project.godot").
- `KitWorld.ids()` now really returns IDs in alphabetical order, as DESIGN.md promises. Sorting StringNames directly in Godot is not alphabetical. Only the overlay and the testbed view call it; no rule outcome changes.
- F1 Why: the Thing picker is a short scrolling list opening under its button, grouped by record type (Dock, Rock, Ship), instead of a popup that covered the screen.
- F1 Log tab: consecutive repeats of the same action, actor and outcome with nothing refused collapse to one "×N" line, so flight no longer buries refusals.
- F1 Why tab: refused actions change nothing, so they were only listed under the actor. Why now also lists the 10 newest actions aimed at the selected entity, with their refusal reasons. Selecting a rock answers "why can't I mine this?".

## 0.1.0 — 2026-10-03

First complete public kit and save schema 1.

- Typed, genre-independent record store with stable IDs, schema validation, canonical hashes and six-decimal JSON.
- Declared actions, named checks, atomic changes, charge/overflow policies, deterministic queue ordering and traceable operation records.
- Declared event registry and post-commit presentation; staged feel resources, sound markers, replay, slow motion, skip and A/B selection.
- Named rule RNG streams with native-draw auditing, separate cosmetic RNG, fixed/manual clock and complete save continuation.
- Checked temporary-file saves, backups, rejected-primary preservation and ordered migration support, with an exercised legacy fixture.
- F1 World/Why/Log/Events/Feel inspector and F2 searchable live trial/Apply/Discard/variant tuning.
- Mining testbed with 30 primitive rock blocks, authoritative flight, docking, trading, clipping, both charge policies and light/heavy feel variants.
- Required five scenarios plus integrity checks; repeat, midpoint reload, compare and rendered screenshots.
- Windows CLI, source-linked game map, manifest-protected installer and empty-project/UI verification.

The public API and JSON schema are introduced here; no prior public kit or save schema is being replaced.
