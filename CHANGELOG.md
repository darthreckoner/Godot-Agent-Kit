# Changelog

## Unreleased

## 0.2.0 — 2026-10-04

- `KitActionDef.charge_policy_key` optionally binds charge policy to an integer tuning knob (0: ON_SUCCESS, 1: ON_ATTEMPT). The runner reads it at execution, including queued actions. Missing or invalid bindings reject by `action.charge_policy`; unbound definitions retain their existing policy. GAME_MAP names the binding. The mining setup bridge is removed.
- Save schema remains 1. Its existing policy fields store definition defaults for bound actions; restore ignores their legacy duplicated charge value and uses restored tuning. Schema-0 and schema-1 continuation remain covered by scenarios, so no schema migration is needed.
- Action transactions use a locked world, a permanently read-only planning view and copies of touched records. Only staged records are validated/canonicalized and committed. Atomic rejection, additions/removals, ownership of nested reads, clipping and RNG rollback are covered. `last_transaction_stats` exposes copied/changed/removed counts outside saves and rule hashes. Fractional deltas honor declared float fields even after canonicalization represents a whole value as an integer.
- RNG audit streams sort by text; `rng_two_streams` draws in reverse order and checks alphabetical audit ordering with repeat/save-reload.
- Scenarios can declare `requires_play` and use physical key, mouse button/motion, input tick and presentation-wait commands. `tools/kit.ps1 scenario <name> -Play` runs them windowed. `test` runs the sim suite followed by play scenarios, each repeated and save/reloaded; baseline runs capture screenshots. These exercise actual engine input callbacks and physical-key polling, rather than OS hardware input.
- New scenarios cover live policy binding, 2,000 terrain records, targeting, camera/flight/docking and the default state of every overlay panel/tab. The performance report measures staged action time and the removed five-copy workload, rather than imposing a machine-dependent time limit. Player-visible tasks require screenshot inspection in AGENTS.md.
- Overlay resets its selections/filters/groups on a new run. Default Log and Events explain their empty state. `KitFeelPlayer.is_playing()` supports clear idle/current-effect feedback. Stage captions identify their emitting sequence when effects overlap.
- Mining lab: clicks only select and smoothly face a rock once; Space alone mines; broken targets clear. Automatic selection/tracking and the Space-release latch are removed. Numpad Enter trades like Enter. Light/heavy labels explicitly say same damage. F3 and the Feel button say “Finish current effect”; idle F3 explains replay. Gold remains the harder-rock test, with a visible F2 drill-power instruction. Target selection acknowledges immediately through a presentation sequence.

Earlier UI and Windows tooling fixes included in this release:

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
