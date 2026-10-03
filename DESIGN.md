# DESIGN — Godot Agent Kit

## Vision (one paragraph)
A Godot 4 addon that makes a game easy for an AI agent to change safely and easy for a
non-traditional developer to understand. It is not an engine. Godot still renders, plays
audio, runs physics and exports. The kit adds a small set of conventions and tools on top:
gameplay is a set of declared actions applied all-or-nothing and logged, tuning lives in
small readable resources behind one panel, juice reacts to events instead of being wired
into rules, and every change can be checked with repeatable scenarios. The designer can
click a value in-game and ask "why did this change?", and the answer comes from recorded
operations, not from a guess.

## Developer fantasy
"I play my game, say 'that's not quite right', and within minutes I can see the cause,
change the right thing, and feel the difference, without worrying that something else broke."

## Pillars (max 3 — every feature serves one)
1. **Readable.** A non-programmer can see what is in the game and why things happen.
2. **Safe to change.** Rules are declared, changes are scoped, and evidence beats explanations.
3. **Fast to feel.** Tuning and feel changes are instant, comparable and reversible.

## Core loop (the development loop the kit serves)
- Every 10 seconds: move a tuning slider in-game and feel the result.
- Every minute: select something, ask "why?", and read the action trail.
- Every session: an agent makes a scoped change, runs scenarios, and the designer compares
  A/B variants in-game, then applies or discards.

## Features

### World state with stable IDs
- Developer should feel: "There is one true version of my ship, however I'm looking at it."
- Serves pillar: 1, 2
- Rules: game state lives in plain data records in `Kit.world`, keyed by stable string IDs
  (`ship:player`, `rock:014`). Scenes are views: they read state and react to events, and
  never own a competing copy. Iteration order is always sorted by ID. Games define their
  own record types; the kit doesn't dictate cameras, movement or genre.
- Feedback: `Kit.world.dump()` gives readable JSON; `state_hash()` gives a canonical hash.
- Tuning knobs: none.

### Declared actions
- Developer should feel: "An action either happened completely or not at all, and I can see which."
- Serves pillar: 2
- Rules: every gameplay action (mine, buy, dock, repair) has an `ActionDef` resource listing
  its requirements, costs, effects, events and policies. A handler script *plans* a change
  set without mutating anything; the runner validates and commits it atomically, or rejects
  it with named reasons. Two explicit policies per action:
  - `charge`: `ON_SUCCESS` (pay only if the action yields) or `ON_ATTEMPT` (pay even when it
    yields nothing, recorded as such).
  - `overflow`: `REJECT` or `CLIP` (e.g. cargo fills partially; the record marks it clipped).
- Feedback: each run writes an `ActionRecord` (tick, sequence number, actor, inputs, checks
  passed/failed with rule IDs, deltas with the tuning knob behind each, events, RNG draws).
- Tuning knobs: per-action values live in tuning sets, never in handlers.

### "Why is this happening?" inspector
- Developer should feel: "I can interrogate my game instead of guessing."
- Serves pillar: 1
- Rules: in-game overlay (F1). Entity list, selected entity's state, and a Why panel:
  pick a field and see every recorded change to it, e.g.
  `energy 18 → 8 · mine −4 (tuning/mining.energy_cost) · requested by input at tick 312`.
  Rejected actions show which check failed. Also shows the event log and action timeline.
- Feedback: values that changed this second briefly highlight.

### Tuning panel
- Developer should feel: "Every feel number is one search away, and experiments are safe."
- Serves pillar: 3
- Rules: one in-game panel (F2) over many small `TuningSet` resources (one per system:
  `tuning/mining.tres`, `tuning/flight.tres`). Every knob has a unit, range and one-line help.
  Moving a slider is a **trial**; nothing is saved until **Apply**. **Discard** reverts.
  Changed knobs are highlighted. Structural changes say when a restart is needed rather than
  pretending to hot-reload.

### Events and feel sequences
- Developer should feel: "I can make it feel heavier without touching the rules."
- Serves pillar: 3
- Rules: rules emit events after commit; presentation subscribes. Rules never call audio,
  particles, camera or tweens. A `FeelSequence` resource turns an event into staged
  presentation (e.g. windup → contact → impact → debris → collect), with sounds, an
  optional audio marker for the hit, shake, flash and particles per stage. Results are
  decided before presentation, so skipping a sequence reveals the same result.
- Feedback: the inspector can replay the last sequence, slow it to 0.25×, and A/B two variants.

### Controlled randomness and clock
- Developer should feel: "The same test gives the same answer."
- Serves pillar: 2
- Rules: named RNG streams (`Kit.rng.stream(&"loot")`) derived from one run seed;
  cosmetic randomness uses a separate stream that can never affect gameplay. Stream state
  is saved. A sim clock supports fixed ticks or manual turns. Queued actions resolve in
  (tick, sequence) order. Physics is outside the repeatability guarantee unless a scenario
  proves otherwise.

### Saves
- Developer should feel: "Saves don't silently break when the game changes."
- Serves pillar: 2
- Rules: modelled on Rust Bucket's root save store: readable JSON wrapper with schema
  version and SHA-256 checksum, temp write then rename, previous-valid backup and fallback
  on load, and a migration chain (`migrations/v1_to_v2.gd`). Old saves are kept as test fixtures.

### Scenario runner (two modes)
- Developer should feel: "I get evidence, not promises."
- Serves pillar: 2
- Rules: a scenario sets initial state, a seed and a list of commands, then asserts results
  and **constraints** (values that must not change). One interface, two modes:
  - **sim** (headless): state, rules, accounting, traces. No screenshots.
  - **render** (windowed): screenshots at marked ticks, layout and animation checks.
  Both run the real game rules. Built-in checks: repeatability (two runs, same hash) and
  save/reload equivalence (continuous run vs save-reload-continue, same hash).
  A/B compare runs one scenario under two tuning or feel variants and diffs the reports.
- Feedback: `reports/<scenario>/<time>/report.json`, `report.md`, `shots/*.png`.

### Agent tooling
- Developer should feel: "Agents work through the same tools I use."
- Serves pillar: 1, 2
- Rules: `tools/kit.ps1` wraps everything: `test`, `scenario`, `compare`, `dump`, `map`,
  `lint`. The Godot executable path comes from `kit.local.json` or `GODOT_BIN`, never hardcoded.
  `kit map` generates `GAME_MAP.md`: actions, events, tuning knobs with units, entity types
  and scenarios, each linked to its file, with intent text taken from each resource's
  `description`. `kit lint` (heuristic) flags global `randf()`/`randi()` in rules, presentation
  calls inside rules, and untyped variables in rules. Nothing requires AI to work.

## Folder convention for games using the kit
```
addons/agent_kit/   kit code (never edited inside a game)
game/rules/         action handlers and conditions (no presentation)
game/data/          ActionDefs, item and entity definitions (.tres)
game/tuning/        one TuningSet .tres per system
game/feel/          FeelSequences and presentation scripts
game/views/         scenes that show the world
scenarios/          scenario scripts
reports/            generated, gitignored
GAME_MAP.md         generated
```

## Distribution
The kit lives in its own repo (`C:\Dev\Godot_Agent_Kit`) with a VERSION file and
CHANGELOG. `tools/install_kit.ps1 -Target <project>` copies a version into a game's
`addons/agent_kit/` with a file-hash manifest, and refuses to overwrite local edits unless
`-Force` is passed. Kit changes happen in the kit repo only. The game template receives the
kit once the merged Rust Bucket runs on it and a small Railroad Wars scenario has worked.

## References (what exactly to borrow)
- Rust Bucket root game: save store design (versioning, checksum, backup, migrations).
- Rust Bucket demos: the mining loop shape (energy → mine → cargo → port), and the open
  question of when mining charges (Codex Demo: on success; Claude Demo: on attempt).
- Unreal Rewind Debugger: the idea of interrogating recorded gameplay (records only, no rewind in v1).
- Factorio: repeatability needs defined ordering and controlled randomness, not just a seed.

## Anti-goals (must NOT become)
- A game engine or a Godot replacement.
- A framework that dictates genre, camera, movement, art or a 2D/3D choice.
- One giant config file, or "hot reload everything" that sometimes corrupts a session.
- Verification machinery that makes a 5-minute feel tweak take longer than it does today.
- Dependent on AI, a network connection or any specific model.

## Scope
- Platform / stack: Godot 4.7, typed GDScript, Windows-first tooling (PowerShell),
  renderer-agnostic (Rust Bucket uses Compatibility).
- First version includes: everything above plus a small 3D mining testbed proving it.
- Explicitly deferred: editor dock plugin (in-game overlay only), rewind/time travel,
  physics determinism, procedural generation tools, dialogue tooling, networking, C#.
