# KIT_RULES.md: building a game on Godot Agent Kit

These rules ship inside `addons/agent_kit/` and update whenever the kit is reinstalled. Your
game's AGENTS.md points here. Game-specific rules belong in the game's own AGENTS.md, never in
this file.

## Read first, every session
1. The game's DESIGN.md and STATE.md.
2. GAME_MAP.md (regenerate it with `tools/kit.ps1 map` if it is missing or stale).
3. This file.

## Where code goes
```
addons/agent_kit/   the kit: never edit it inside a game (see "When the kit is not enough")
game/rules/         action handlers and conditions, with no presentation
game/data/          ActionDefs, record types, event declarations (.tres)
game/tuning/        one TuningSet per system
game/feel/          FeelSequences and presentation scripts
game/views/         scenes that show the world and turn input into actions
scenarios/          scenario and play-scenario scripts
reports/            generated, gitignored
```

## How gameplay is built
- **State** lives in `Kit.world` records with stable IDs (`ship:player`, `rock:014`). Scenes
  read records; they never keep a competing copy of game state.
- **Every player verb is a declared action** (an ActionDef plus a handler). Handlers check and
  plan; only the action runner changes records. A rejected action names the rule that refused
  it in plain English.
- **Every number lives in a TuningSet** with a unit, range and help text. No numbers in rules
  or views.
- **Rules never call audio, particles, camera, tweens or UI.** They emit declared events;
  FeelSequences and views react after the action commits.
- **Randomness and time** come from `Kit.rng` streams and `Kit.clock` only. Never `randf()`,
  `randi()` or wall-clock time in rules.
- Typed GDScript. Plain-English labels and messages: the designer is not a traditional
  programmer.

## Game feel
- Before any gameplay change, state in 2 lines what the player should feel.
- Every player action gets immediate feedback through a FeelSequence.
- Feel changes must not change rule outcomes or timing. Prove it with `tools/kit.ps1 compare`.
- Each task ends in a playable state.

## Evidence
- Run `tools/kit.ps1 test` before finishing any task. Report actual results.
- New rules get a scenario. Changes to what the player sees or does get an input-driven play
  scenario, and someone inspects its screenshots before the task is called done.
- A passing test does not mean it feels good. Say what the designer should playtest.
- If you cannot run something, say so plainly.

## When the kit is not enough
Never edit `addons/agent_kit/`. The installer's manifest detects local edits, and the next
reinstall will refuse or overwrite them. Instead:
1. Add an entry to the game's `KIT_REQUESTS.md`: the problem, what the game needed, the change
   you propose, and why every game (not just this one) would want it.
2. Work around it in `game/` if a clean workaround exists. Otherwise stop and tell the designer.

Kit changes are made in the kit repo, released with a VERSION bump and CHANGELOG entry, and
then reinstalled. If you are unsure whether something is reusable, it belongs in `game/`.

## Updating the kit
Only update when the designer asks. `tools/kit.ps1` prints a notice when the kit repo this game
was installed from has a newer version. To update:
1. Read the kit's CHANGELOG between the installed version and the new one.
2. Reinstall from the kit repo: `tools/install_kit.ps1 -Target <this game>`.
3. Run `tools/kit.ps1 test` and fix what the changelog says changed.
4. If the save schema changed, confirm that old saves migrate before shipping.

## End of every session
Update STATE.md: what changed, assumptions, known issues, next steps. Regenerate GAME_MAP.md if
actions, events, tuning or scenarios changed.
