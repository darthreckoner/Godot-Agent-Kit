# One-shot build prompt — Godot Agent Kit v0.1

You are building the first complete version of the Godot Agent Kit: a Godot 4.7 addon plus a
small 3D mining testbed that proves it. Read this whole prompt before writing code.
Everything you need is here.

## Vision
The kit is not an engine. Godot still renders, plays audio, runs physics and exports. The kit
adds conventions and tools so an AI agent can change a game safely and a non-programmer
designer can understand it. Gameplay is a set of declared actions applied all-or-nothing and
logged. Tuning lives in small readable resources behind one in-game panel. Juice reacts to
events instead of being wired into rules. Repeatable scenarios produce evidence. The designer
can click a value and ask "why did this change?", answered from recorded operations.

## Pillars — every decision must serve these
1. **Readable.** A non-programmer can see what's in the game and why things happen.
2. **Safe to change.** Rules are declared, changes are scoped, and evidence beats explanations.
3. **Fast to feel.** Tuning and feel changes are instant, comparable and reversible.

## Anti-goals — do not drift into these
- An engine, or anything that replaces what Godot already does.
- Dictating genre, camera, movement, art or 2D/3D. Rust Bucket (3D real-time mining) and
  Railroad Wars (turn-based strategy) must both fit.
- One giant config file; "hot reload everything".
- Machinery that makes a simple tweak slower than editing a number.
- Any dependency on AI, network access or a specific model.

## Repo layout
```
C:\Dev\Godot_Agent_Kit\
  project.godot            the testbed project (Godot 4.7, Compatibility renderer)
  addons/agent_kit/        THE KIT (everything reusable lives here)
  game/                    testbed game, using the folder convention below
  scenarios/               testbed scenarios
  tools/kit.ps1            CLI wrapper
  tools/install_kit.ps1    copies the kit into another project
  VERSION                  0.1.0
  CHANGELOG.md
  README.md                plain-English guide for the designer
  AGENTS.md, DESIGN.md, STATE.md
  kit.local.example.json   { "godot_bin": "C:/path/to/Godot_v4.7.2-stable_win64_console.exe" }
```
Game folder convention (document it in README; the testbed follows it):
`game/rules` (handlers, conditions; no presentation), `game/data` (.tres definitions),
`game/tuning` (one TuningSet per system), `game/feel` (FeelSequences, presentation
scripts), `game/views` (scenes), `scenarios/`, `reports/` (gitignored), `GAME_MAP.md` (generated).

## Kit components (intent first, then rules)
Use typed GDScript everywhere in the kit. Register ONE autoload, `Kit`, exposing
sub-objects: `Kit.world`, `Kit.actions`, `Kit.events`, `Kit.log`, `Kit.rng`, `Kit.clock`,
`Kit.tuning`, `Kit.feel`, `Kit.save`. Add an `EditorPlugin` only to register that autoload.

### 1. World state — `Kit.world`
- Intent: one true version of every game object, however it's displayed.
- Rules: records keyed by stable `StringName` IDs (`ship:player`, `rock:014`). A record has a
  type and typed fields; games register record types. Iteration is always in sorted ID order.
  `dump() -> Dictionary` (readable JSON), `snapshot()/restore()`, and `state_hash()` = SHA-256
  of canonical JSON (sorted keys; floats rounded to a documented precision). Only the action
  runner mutates records during play; scenario setup and save load may set state directly.
- Views read the world and subscribe to events; they never hold a competing copy.

### 2. Declared actions — `Kit.actions`
- Intent: an action happens completely or not at all, and you can see which and why.
- `ActionDef` (Resource, .tres): `id`, `description` (plain English), `handler` (script),
  `requires` (array of `Condition` resources: e.g. has_resource, in_range, cooldown_ready,
  plus custom), `tuning_set`, `events_on_success`, `events_on_reject`,
  `charge_policy` (`ON_SUCCESS` | `ON_ATTEMPT`), `overflow_policy` (`REJECT` | `CLIP`).
- `ActionHandler` (RefCounted): `check(ctx) -> Array[CheckResult]` for extra checks and
  `plan(ctx) -> ChangeSet`, which must NOT mutate anything.
- `ChangeSet` holds `Change` objects. Built-ins: resource delta, set field, add/remove record.
  Custom changes (e.g. carving terrain) subclass `Change` with `apply(world)`, `to_dict()`,
  and `describe()`. Every change carries a `reason` naming the tuning knob or rule behind it,
  e.g. `"tuning/mining.energy_cost"`.
- Runner `run(action_id, actor_id, params) -> ActionResult`: evaluate requires and check;
  if any fail, record a rejection with each failed check's rule ID and emit reject events.
  Otherwise plan, validate (no negative resources, capacity rules via overflow policy;
  a clipped result is flagged), apply charge policy (`ON_ATTEMPT` with zero yield commits
  the cost and records outcome `attempted_no_yield`), commit all changes, record, emit events.
  `queue(...)` defers to the next tick; queued actions resolve in (tick, sequence) order.
- `Kit.log`: append-only `ActionRecord`s (tick, seq, action, actor, params, checks, outcome
  {success, rejected, clipped, attempted_no_yield}, deltas with reasons, events, RNG draws,
  input source). `changes_for(entity_id, field)` returns the records that touched it.
  The log is a bounded ring buffer in play (size is a tuning knob) and unbounded in scenarios.

### 3. Events — `Kit.events`
- Events are declared in a registry resource (name, payload field names, description).
  Emitting an undeclared event is an error in debug builds. Events fire only after commit.
- Rules code never calls audio, particles, camera, tweens or UI. Presentation subscribes.

### 4. Feel sequences — `Kit.feel`
- Intent: make it feel heavier without touching rules.
- `FeelSequence` (Resource): `trigger_event`, `stages: Array[FeelStage]`. A `FeelStage` has
  name, duration, optional sound, optional `sound_marker_sec` (stage aligns its hit to
  that point in the audio), camera shake (amplitude, frequency), screen flash, optional
  particle scene, and target (the event's entity, resolved through the game's view registry).
- The player plays stages in order, `skip()` jumps to the final stage, and `time_scale`
  allows slow motion. Results are already committed, so skipping never changes outcomes.
- Feel can't change rule timing. Action cooldowns live in tuning, not in sequences.

### 5. Tuning — `Kit.tuning` and the panel (F2)
- `TuningSet` (Resource): games subclass it with `@export_range(..., "suffix:unit")` vars
  and a `KNOBS` const dictionary giving each knob `help` text. Lookup key format:
  `"<set>.<knob>"` e.g. `mining.energy_cost`.
- Panel: searchable list of every knob across sets, grouped by set, with unit, range, help,
  current value and slider. Moving a slider is a **trial** (live, not saved, highlighted).
  **Apply** writes the .tres with ResourceSaver; **Discard** reverts. **Save as variant** writes
  `<set>.<name>.tres` for A/B. Show "restart needed" for knobs flagged `restart: true`.

### 6. RNG and clock — `Kit.rng`, `Kit.clock`
- `Kit.rng.stream(name) -> RandomNumberGenerator` derived deterministically from run seed +
  name. `Kit.rng.cosmetic` is separate and never used by rules. All stream states are
  included in `snapshot()`. Every draw a rule makes during an action is logged.
- `Kit.clock`: fixed-tick mode (tick rate in tuning) or manual-turn mode (`advance()`).
  Rules read time only from `Kit.clock`.

### 7. Saves — `Kit.save`
- JSON wrapper: `{kit_version, schema_version, created, checksum_sha256, payload}`; payload
  is the world snapshot (bulk float arrays may be base64 inside it). Write to temp, verify,
  rename; keep the previous valid save as `.bak`; load falls back to `.bak` if the primary
  fails validation; preserve an unreadable primary as `.rejected`. A migration chain runs
  `migrations/vN_to_vN+1.gd` scripts in order. Check every file operation's result.

### 8. Inspector overlay (F1)
- Tabs: **World** (sorted entity list → selected record's fields, recently changed values
  highlighted), **Why** (pick a field → its change history from `Kit.log`, with action,
  delta, reason/tuning knob, tick, input source; rejected attempts show the failed check),
  **Log** (action timeline, filter by action/outcome), **Events**, **Feel** (replay last
  sequence, 0.25×/1× speed, A/B between two sequence resources).
- Plain-English labels. Built with Control nodes on a CanvasLayer; works at 1280×720 and up.

### 9. Scenario runner
- A scenario is a GDScript file extending `KitScenario` with `setup()` (initial state, seed,
  tuning variant), `steps()` (a list of commands: run/queue action, advance ticks, save,
  reload, screenshot), `expect()` (assertions), and `constraints()` (values that must be
  identical to a baseline run, e.g. `mining.energy_cost`, total ore yielded, action cooldown).
- Modes: `sim` (run headless, no rendering, no screenshots) and `render` (windowed; screenshot
  commands write PNGs). Same rules code in both. Never build a simplified "test game".
- Built-in checks for any scenario: `--repeat` (run twice, hashes must match) and
  `--save-reload` (continuous vs save-at-midpoint-reload-continue, final hashes must match).
- `compare A B` runs a scenario under two tuning or feel variants and writes a diff report;
  constraint violations fail the compare.
- Output: `reports/<scenario>/<YYYYMMDD-HHMMSS>/report.json`, `report.md` (plain English:
  passed/failed, key numbers, failed checks with record excerpts), `shots/*.png`.
- Entry: `res://addons/agent_kit/runner/run.tscn` with user args after `--`. Exit code 0/1.

### 10. Tools
- `tools/kit.ps1` subcommands: `test` (all scenarios in sim + repeat + save-reload),
  `scenario <name> [-Render]`, `compare <scenario> <variantA> <variantB>`, `dump`
  (run setup and print world JSON), `map` (regenerate GAME_MAP.md), `lint`. Reads
  `godot_bin` from `kit.local.json` (gitignored) or `$env:GODOT_BIN`; clear error if missing.
- `kit map` writes `GAME_MAP.md`: actions (description, requires, policies, tuning), events,
  tuning knobs (unit, range, value, help), record types, feel sequences, scenarios. Each
  entry links to its file path.
- `kit lint` (heuristic regex scan; say so in its output): in `game/rules/` flag global
  `randf/randi/randomize`, references to audio, particles, Camera, Tween or UI, and untyped
  `var x =` declarations; anywhere in `game/`, flag edits to files under `addons/agent_kit/`.
- `tools/install_kit.ps1 -Target <project> [-Force]`: copies `addons/agent_kit/` and
  `tools/kit.ps1`, writes `addons/agent_kit/VERSION` and a file-hash manifest; refuses to
  overwrite a target whose kit files differ from their manifest unless `-Force`.

## Testbed: mining slice (in `game/`)
Modelled on Rust Bucket's loop. Placeholder art (primitive meshes) and placeholder audio are fine.
- **Scene:** a small ship in 3D space next to an asteroid made of ~30 rock blocks with hardness
  tiers (soft, medium, hard). Simple orbit camera around the ship; WASD/QE moves the ship.
  A dock marker nearby.
- **Records:** `ship:player` (energy, energy_max, cargo by ore type, cargo_capacity, credits),
  `rock:NNN` (hardness, health, ore_type, ore_amount).
- **Actions:**
  - `mine`: requires target in range, cooldown ready, energy ≥ cost. Damages the rock by
    tool power vs hardness. A rock that's too hard yields nothing. On break, adds ore to cargo
    with overflow `CLIP`. Default `charge_policy` = `ON_SUCCESS`. Provide a tuning variant
    `mining.charge_on_attempt.tres` that switches the action to `ON_ATTEMPT`, so the
    designer can feel both demos' behaviour.
  - `sell_and_refuel`: requires being within dock range; sells all cargo at per-ore prices
    and refills energy at a cost per unit.
- **Tuning sets:** `mining` (energy_cost, range, cooldown, tool_power, yield per ore, hardness
  thresholds), `ship` (speed, accel, energy_max, cargo_capacity), `economy` (ore prices,
  refuel price).
- **Feel:** `mine_hit` sequence: windup → contact → impact (shake, flash, sound with marker)
  → debris particles; `rock_break` sequence; `mine_rejected` (dull clunk, small shake);
  `cargo_clipped` (warning blip). Provide `mine_hit_heavy.tres` as an alternate variant.
- **HUD:** energy, cargo/capacity, credits, and a toast for rejected or clipped actions.
- **Scenarios** (`scenarios/`):
  1. `mine_basic`: mine soft rocks until one breaks; expect ore gained and energy spent as tuned.
  2. `mine_full_cargo`: near-full cargo; expect a clipped record and exact capacity.
  3. `mine_hard_rock`: under each charge policy, expect `rejected` vs `attempted_no_yield`
     with the correct energy outcome.
  4. `economy_round_trip`: mine, dock, sell, refuel; expect credits and energy as tuned.
  5. `feel_change_is_scoped`: compare `mine_hit` vs `mine_hit_heavy`; constraints:
     energy spent, ore yielded and action timing are identical.
  All scenarios must pass `--repeat` and `--save-reload`. Scenario 5 must also run in
  `render` mode and produce screenshots of both variants.

## Skip in this build
Editor dock plugins (beyond registering the autoload), rewind or time travel, physics
determinism, procedural generation tools, dialogue tooling, networking, C#, an in-game AI
chat, real art, and porting Rust Bucket itself.

## Before coding
Restate in 3 lines what the designer should feel when using the kit. Then list decisions
you're unsure about, make your best call, and record each in STATE.md under "Assumptions".

## Done when
- `tools/kit.ps1 test` passes: every scenario in sim mode, with repeat and save-reload checks.
- `tools/kit.ps1 scenario feel_change_is_scoped -Render` produces screenshots and passes constraints.
- The testbed is playable: fly, mine, see feel sequences, dock, sell. F1 inspector answers
  "why did energy change?"; F2 tuning panel supports trial, apply, discard and variants.
- `tools/kit.ps1 map` and `lint` run, and GAME_MAP.md is committed.
- `install_kit.ps1` installs into an empty Godot 4.7 project, and that project boots with `Kit`.
- README.md explains, in plain English, how to play the testbed, use F1 and F2, run tests,
  and install the kit into a game.
- STATE.md is updated: what exists, assumptions, known issues, next steps.
