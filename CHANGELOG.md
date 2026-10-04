# Changelog

## Unreleased

UI fix only; no public API, file format or save schema change, so VERSION stays 0.1.0.

- F2 tuning panel: an empty search listed nothing, because Godot's `contains("")` is false. F2 now opens with every tuning group listed and collapsed: game and kit settings first, then feel stages, each alphabetical. Clicking a group opens it. A search matches every typed word against group, knob name and help text, and opens each matching group. A search with no match says so.
- F2 search box: it now has a visible border and background, a Search label, example hint text and a Clear button, and it takes the cursor when F2 opens.
- F2: Apply, Discard and Save as variant now sit at the top of each open group instead of below its last knob, where long groups hid them. Slider tooltips are removed: they repeated the help line already shown under each slider, over a hard-to-read translucent background.
- F1 Log tab: it was always empty for the same `contains("")` reason. Empty filters now show every action. Each line names the action's inputs (e.g. its target), and refused actions list the failed rule and its message underneath.
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
