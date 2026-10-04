# AGENTS.md — Godot Agent Kit

## Read first, every session
1. DESIGN.md: the vision and pillars. It overrides your defaults.
2. STATE.md: what exists and what's next.

## What this repo is
A reusable Godot 4.7 addon (`addons/agent_kit/`) plus a mining testbed (`game/`) that proves
it. Everything reusable goes in the addon. Anything specific to mining, Rust Bucket or any
other game goes in `game/`. If you're unsure which side something belongs on, it belongs in `game/`.

## Rules for kit code
- Typed GDScript only. No untyped `var x =` in kit code.
- The kit must not assume genre, camera, movement, 2D/3D, real-time vs turns, or Rust Bucket's design.
- Only the action runner mutates world records during play.
- Rules never call audio, particles, camera, tweens or UI. They emit declared events after commit.
- Rules use `Kit.rng` streams and `Kit.clock` only. Never global `randf()`/`randi()`, never wall-clock time.
- Every tunable number lives in a TuningSet with a unit, range and help text. Never hardcode.
- Check the result of every file operation. Never fail silently.
- Write plain-English labels and messages: the designer is not a traditional programmer.

## Game feel rules (testbed)
- Before any gameplay change, state in 2 lines what the player should feel.
- Every player action gets immediate feedback through a FeelSequence.
- Feel changes must not change rule outcomes or timing. Prove it with a compare run.
- Each task ends in a playable state.

## Evidence
- Run `tools/kit.ps1 test` before finishing any task. Report actual results, not expectations.
- For changes to player-visible behavior or controls, run input-driven play scenarios and
  inspect their screenshots. Record reports, images inspected, and remaining visual issues
  in STATE.md before marking the task done.
- A passing test does not mean it feels good. Say what the designer should playtest.
- If you can't run something, say so plainly.

## Scope discipline
- Change only what the task asks. If a fix needs a wider change, stop and describe it first.
- Changing a public kit API, file format or save schema requires a CHANGELOG entry and a
  VERSION bump. Save schema changes require a migration script and a fixture.
- If a request conflicts with a pillar or anti-goal in DESIGN.md, flag it.

## End of every session
Update STATE.md: what changed, assumptions made, known issues, next steps.
Regenerate GAME_MAP.md if actions, events, tuning or scenarios changed.
