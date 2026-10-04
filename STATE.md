# STATE

## Build version

0.3.1 — ticket 11 (scenario tuning independence) complete locally on 2026-10-04, verified on Windows with Godot 4.7.2. Save schema remains 1.
Current branch: codex/ticket-11-scenario-tuning, based on clean fetched main at 81787c342c368fb7066d45a4465d26e3e8c96029. On 2026-10-04 the designer requested commit, PR creation and merge. Publication is in progress; the HUD capture limitation below remains recorded.
Earlier ticket 10 delivery: implementation b30a1252b237f5f90018941dce5b0068642dcbb5 was pushed and merged through [PR #3](https://github.com/darthreckoner/Godot-Agent-Kit/pull/3) at 114e7fedf002cb8e4c6f33a4c17adf9f5b4e0270. The designer's passing 0.3.0 playtest and delivery authorization are retained below.

## Ticket 11 implementation and verification (2026-10-04)

- Publication rerun after the designer requested commit, PR and merge: tools/kit.ps1 test exited 0 with 12/12 sim and 4/4 play scenarios, all repeat/save-reload checks passing. Sim reports span 20261004-180505* through 180528*. Play reports: reports/play_controls/20261004-180530-2013170, reports/play_flight_and_dock/20261004-180533-5186492, reports/play_overlay_defaults/20261004-180544-15946601 and reports/play_targeting/20261004-180545-17352660. Inspected controls_conflict.png (readable controls/refusal) and heavy_same_damage.png (target/hints readable, but title and parts of energy/cargo labels missing again). The capture limitation remains open. git diff --check passes, and player rules/views/tuning/feel/data match origin/main.
- KitScenario.pin_tuning(values) and KitTuningRegistry.pin(values) validate a full list before changing anything, preserve resource identity and project files, and establish the in-memory baseline used by Discard. Full knob names and values appear in each scenario report as tuning_pins; setup_message explains a refusal. scenario_tuning_pins checks baseline/trial/Discard, resource identity, file preservation and atomic refusal of unknown, out-of-range, non-finite and fractional-integer values.
- MiningSetup accepts a scenario setup callback after registration but before world creation. All ten existing sim scenarios and four play scenarios inherit 23 explicit fixture values: all 12 mining knobs, five ship knobs, five economy knobs and kit.tick_rate. Initial health, hardness, yields, capacities and energy therefore come from the fixture. Fixtures use range 2.5 and cooldown 0.3; project defaults remain the designer's range 4 and cooldown 0.299997. Rule handlers, views, controls, game tuning and feel resources are unchanged.
- shipped_default_balance separately reads real project defaults against scenarios/fixtures/default_balance.json. Differences print DEFAULT BALANCE CHANGED with expected/shipped values and appear in report numbers; balance edits are notices. A change to the reference requires an intentional balance acceptance. The current project defaults match that reference.
- wait_for_feel waits for Kit.feel.is_playing() to become false, with an explicit timeout and no rule-tick advancement. Idle F3, rendered compare cleanup and UI cleanup use actual completion. Fixed waits that test turn animation or capture a particular moment remain. UI verification now sets up the same explicit fixture before building its view.
- VERSION, addon VERSION, plugin and save-wrapper kit_version are 0.3.1 for the added public helper/API and report fields. CHANGELOG, README and KIT_RULES.md explain the fixture workflow. Save schema remains 1; existing migration/save tests pass. GAME_MAP includes the two new scenarios.
- tools/kit.ps1 test: exit 0, 12/12 sim and 4/4 play scenarios with repeat and midpoint save/reload. Final sim reports span 20261004-175206* through 175228*. Final play reports: reports/play_controls/20261004-175231-1951550, reports/play_flight_and_dock/20261004-175234-5078878, reports/play_overlay_defaults/20261004-175245-15834784, reports/play_targeting/20261004-175246-17252767. The targeting scenario explicitly checks that effect waiting preserves rule state and ticks. Logs remain reports/engine-profile/test.log and play.log.
- tools/kit.ps1 compare feel_change_is_scoped mine_hit mine_hit_heavy -Render: exit 0; final report reports/feel_change_is_scoped/20261004-175334-1975683/report.json. The earlier passed report 20261004-172529-1940938 also proves identical constraints, world/continuation hashes and action ticks [0, 9], energy spent 8 and iron yielded 3. UI verification: exit 0, 27/27 checks, reports/ticket11-ui-complete.log and reports/ui-verification/20261004T172911-1349329/report.json. Installer: exit 0, reports/install-smoke/99dcc5679864463381828e568967e994/verification.json. Final map, lint and git diff --check pass.
- tools/verify_scenario_tuning.ps1: exit 0 on the final frozen-source run. reports/scenario-tuning/76c93a1589704b99990d5d7b8ca6d852/verification.json records all 24 applied min/max cases for the 12 mining knobs. Each case passes all 11 rule scenarios with the same continuation hashes as baseline (264 case/scenario combinations, plus 11 baseline runs). Default-balance notices match the applied values, including an unchanged notice when applying the existing default. The wrapper's before/after SHA-256 guard confirms that all original addon, game, scenario and tool files stayed unchanged. Earlier passed matrix cd9c64f34408402e828000b596ed0bd3 remains; render ablations later ran in that disposable copy and its runner was restored from current source.
- Preserved diagnostics: the first rendered compare passed assertions but returned 1 for shutdown resource errors (reports/ticket11-compare-shutdown-failure.log and reports/feel_change_is_scoped/20261004-172348-1986217). Waiting for actual effect completion passed on rerun. The first UI attempt retained a removed testbed helper call (reports/ticket11-ui.log); it was corrected to fixture setup before view creation. Matrix attempts b18c4b7ded6a4fe794f189be85478db1 and 22348b8513594ccf9481e644e563400b under reports/scenario-tuning were rejected by the source-file guard because I continued editing KIT_RULES.md / verify_ui.gd while they ran; the first also incorrectly required a change notice for the already-default charge value 0. The notice expectation is fixed, and the final run passes both rule checks and the source guard.
- Images inspected: final Controls conflict image, final targeting heavy_same_damage.png, default_tuning.png from 20261004-173144-15829805, UI tuning_trial.png, and both A/B impact.png images from 20261004-172529-1940938. Controls/default panels, UI trials and A/B impacts are readable. Remaining capture issue: portions of HUD text disappear in some captures, including final heavy_same_damage.png. Targeting rerun 20261004-175000-1931123 has a fully readable HUD, but the full-suite capture still omits it. Earlier targeting captures 173146*, 173513* and 174500* retain partial/missing text. Input/rule assertions pass, so they do not detect this visual anomaly.
- Render investigation was bounded to disposable copies: baseline main at 81787c3 rendered a readable targeting HUD in reports/ticket11-baseline/d8794e31df2c42a19c21d910bb43280a/reports/play_targeting/20261004-173851-2790230. A baseline-runner ablation in the first passed matrix copy also rendered readable text (174327*) but deliberately lacked the wait command and failed idle F3. The new runner's effect wait is dispatched before the existing match and lives in a separate helper; an isolated rerun then rendered correctly, but recurrence in the full suite means the renderer/capture cause remains unconfirmed. Player view/feel resources were not changed to address it. Future capture investigation should preserve these comparisons.

Sim audit (fixtures are established through the common setup before records exist):

| Scenario | Assertion inputs accounted for |
|---|---|
| mine_basic, feel_change_is_scoped | Damage, health, yields, energy cost/capacity, cooldown and tick rate |
| mine_full_cargo | The above plus shared capacity and the existing-cargo fixture |
| mine_hard_rock, charge_policy_binding | Cost, cooldown, health, power, success-policy baseline; hard-rock fixture is explicitly harder than the tool |
| mine_out_of_range, economy_round_trip | Mining fixture, flight speed/acceleration/tick rate, dock range and sale/refill prices |
| kit_integrity | Explicit range and energy-cost baseline before trials, Discard and save tests |
| large_terrain_records, rng_two_streams | Explicit ship starting state; probe record sizes/counts, rules and RNG ordering are scenario fixtures |
| scenario_tuning_pins | Explicit cost/policy values; registry contract checks compare captured baselines |
| shipped_default_balance | Deliberately reads project defaults; differences are reported separately |

## Kit-adoption branch merged with 0.3.0 (2026-10-04)

- claude/v0-1-review-issues-1ntmju (kit rules, starter files, installer fixes, ticket 11) was merged with main after PR #3. Conflicts were only CHANGELOG.md (the kit-adoption entries now sit under Unreleased above 0.3.0) and the generated GAME_MAP.md (regenerated).
- Tuning decision: main carried tool power 3 / gold hardness 3, which the 0.3.0 note below records as playtested. Asked again during this merge, the designer chose to revert to tool power 2 / hard threshold 4. Gold is unminable again with project tuning; mining range 4.0, energy_max 60 and the 2.5 s debris stage stay. The 0.3.0 test fixtures already pass under either tuning.
- KIT_RULES.md now covers 0.3.0 controls (declare named controls, read actions not key codes, live hints) and scenario independence from live tuning, bindings and effect durations.

## Ticket 10 delivery and verification (2026-10-04)

- Added KitControlAction / KitControlSet declarations and Kit.controls. Each action has an ID, plain-English description, group and up to two physical keyboard or mouse slots. Boot registration validates the whole declaration before changing InputMap. Kit F1/F2/F3 shortcuts share the same conflict checks as the game.
- F2 starts with a collapsed Controls group. Slot capture, conflict refusal, Trial highlighting, Apply, Discard, Reset to defaults, clearing slots and capture cancellation are available. Apply writes the game's project controls resource, including kit overrides, without editing addon defaults. Save payloads and rule hashes exclude bindings.
- The lab declares all flight, camera, targeting, drill, dock, trial and session inputs in game/data/controls.tres. Enter and Numpad Enter are two slots of one action. Views read named actions; hints and instructions read live bindings. Five hint lines fit the window, with toasts above them. The Controls list scrolls inside F2. New-run status explains trials instead of retaining an earlier Apply message.
- Play scenarios resolve named actions to real input events and begin with declared reset bindings. play_controls proves K flies after rebinding, W stops, hints update, Space conflicts refuse with the drill action named, Discard restores W, a second slot accepts a mouse button, kit shortcuts can be rebound, Reset/Discard work after Apply, and a fresh registration reads saved bindings. Apply tests write only report copies.
- Committed designer tuning is preserved: mining range 4 m, tool power 3, gold hardness 3, and the 2.5 s rock-break debris stage. The hard-rock sim fixture explicitly exceeds tool power; play/UI fixtures use original mining values. The idle-effect probe waits for declared durations. These repair test assumptions exposed by the current checkout without altering gameplay resources or rule handlers. Gold is minable with the current project tuning; older notes below describe original defaults.
- VERSION, addon VERSION, plugin version and save wrapper kit_version are 0.3.0. CHANGELOG and README document the new API/file format, reset-versus-applied defaults and unchanged schema 1. GAME_MAP includes all 21 controls and source files.
- tools/kit.ps1 test: exit 0, 10/10 sim scenarios and 4/4 windowed play scenarios, each with repeat and midpoint save/reload. Logs: reports/engine-profile/test.log and play.log. Final sim reports: reports/<scenario>/20261004-164104* through 164126*. Final play reports: reports/play_controls/20261004-164128-1960945, reports/play_flight_and_dock/20261004-164131-5105600, reports/play_overlay_defaults/20261004-164142-15828152, reports/play_targeting/20261004-164144-17262170.
- tools/verify_ui.tscn: exit 0, 27/27 checks. Evidence: reports/ticket10-ui-complete.log and reports/ui-verification/20261004T164235-1306978/report.json. tools/kit.ps1 compare feel_change_is_scoped mine_hit mine_hit_heavy -Render: exit 0, identical world/rule hashes, constraints, energy/cargo and action ticks [0, 9]; report: reports/feel_change_is_scoped/20261004-163909-1852555/report.json. tools/kit.ps1 map and lint: exit 0; git diff --check passes.
- tools/verify_install.ps1: exit 0 on fresh retry; reports/install-smoke/9f7f478aa6934a4d9a2d8fedd644c274/verification.json and boot.log prove clean/unchanged/forced installation, local-edit refusal, import, all ten services/default kit controls and manual clock. First import exited 1 without script/resource errors; its log remains in reports/install-smoke/5c005c19c7244bbd88566625c8f8b45f/import.log. Cause is unconfirmed.
- Screenshots inspected: final play_controls controls_group.png, controls_conflict.png and rebound_flight_hints.png; controls_trial.png from reports/play_controls/20261004-163720-1935148; final default_tuning/world/why/log/events images; final targeting heavy_same_damage.png and broken_target_cleared.png; final flight/dock numpad_enter_docks.png; final UI tuning_trial.png; both rendered compare impact.png images. Labels, slots, scrolling, default state, hints, toasts and cosmetic differences are readable at 1280x720. No remaining ticket-specific visual blocker was found. Earlier failed play-control/targeting reports and diagnostic logs remain under reports/.
- Designer acceptance: on 2026-10-04 the designer reported "play test passes" and requested commit, push and merge. This records human acceptance of the current 0.3.0 lab; individual manual steps were not enumerated. Existing model overlap and the offline certificate warning remain.
- Pre-publication rerun after acceptance: tools/kit.ps1 test exited 0 with 10/10 sim and 4/4 play scenarios, all repeat/save-reload checks passing. Sim reports span 20261004-165430* through 165452*. Play reports: reports/play_controls/20261004-165455-1974302, reports/play_flight_and_dock/20261004-165458-5188175, reports/play_overlay_defaults/20261004-165509-15938340, reports/play_targeting/20261004-165510-17371570. Inspected this rerun's controls_group.png, controls_conflict.png, rebound_flight_hints.png and default_tuning.png; labels, controls, hints and panel bounds remain readable with no ticket-specific visual blocker.

## Playtest patch (2026-10-04)

The designer's first playtest found three testbed problems. All three are fixed in game/ and the kit is untouched.

- Flight followed fixed world axes: W moved the ship toward its port side and the ship never turned. Now WASD follows the camera (W flies away from it, A/D go to its left/right, Q/E down/up). The ship model turns to face where it flies, and the camera starts behind and to one side of the ship (presentation.camera_start_yaw, -45°). The move_ship rule and its world-direction input are unchanged.
- Mining worked from far away. mining.range was 8 m, measured centre to centre, and the ship started within reach of most rocks. Reach is now 2.5 m, about the drill touching the rock face, and the launch point (4.5 m from the nearest rock) is out of reach. The target label shows "in drill reach" or "fly X m closer", and the selection ring is gold in reach and red out of reach. A short beam runs from the drill tip to the struck rock on every committed hit. Parked within reach, the ship model turns its nose to the selected rock. The rejection now reads "Fly closer: the drill must reach the rock."
- "Choose a rock that has not already broken" came from a stale target. A broken rock stayed selected, and clicking empty space or pressing Space still mined it. Now a broken target hands over to the nearest live rock, and Space must be released before mining continues on that new rock. A click that hits no rock does nothing. With no live rocks left, Space shows "No rock selected."
- New tuning knobs: presentation.ship_turn_rate and presentation.camera_start_yaw.
- F2 tuning panel (kit UI, see CHANGELOG Unreleased): it opened blank, because an empty search matched nothing, and the search box was nearly invisible. It now lists every group collapsed, with game and kit settings above feel stages. Search matches every typed word and opens matching groups. The search box is visible and takes the cursor when F2 opens.
- Scenarios: mining scenarios now start parked 2 m from rock:000 (scenarios/mining_scenario.gd). economy_round_trip flies 50 ticks to the dock instead of 28. The kit_integrity 2D range probe uses a 2 m distance. A new mine_out_of_range scenario proves a launch-point hit rejects on mining.in_range with no cost, and that flying in and stopping makes the rock minable. tools/verify_ui.gd parks the ship within reach before its Space press.

## Delivery

- The earlier nine-ticket work was delivered on codex/open-tickets-2026-10-04 at version 0.2.0. Current ticket 10 delivery is recorded above at 0.3.0.
- Build commit d2bac79 was pushed to origin/main on 2026-10-03 at the designer's request.
- Before pushing, tools/kit.ps1 test returned exit 0: all six scenarios passed repeat and save/reload again. Evidence: reports/push-test.log and reports/<scenario>/20261003-1103*/report.json.

## What exists

- Reusable typed addon under addons/agent_kit, with one Kit autoload and an EditorPlugin that registers it.
- Stable typed records, canonical hashes, atomic declared actions, resource/set/add/remove changes, named rejection checks, both charge/overflow policies, queued actions, bounded play logs and unbounded scenario evidence.
- Declared events emitted after outcome recording; editable staged feel, native sound markers, replay, slow motion, skip, view targets and light/heavy variants.
- Small tuning groups with units/ranges/help; F2 live trial, Apply, Discard, variants and restart labels. F1 World, Why, Log, Events and Feel tabs.
- Named RNG streams with draw auditing, separate cosmetic RNG, fixed/manual clock, checked JSON saves, backup recovery, rejected-primary preservation and ordered migrations.
- Playable mining lab: 30 hardness-tier blocks, flight/orbit camera, mining, docking, ore sale/refill, resource HUD and rejection/clipping feedback. Both charge policies and impact variants can be switched in play.
- Five requested scenarios plus kit_integrity; the runner uses real game rules in sim and render, and emits JSON/Markdown reports with operation excerpts and linked screenshots.
- Windows CLI, manifest-protected installer, generated GAME_MAP.md, VERSION/CHANGELOG, plain-English README and UI/install verification helpers.
- Main checkout and origin remain the original repository: https://github.com/darthreckoner/Godot-Agent-Kit.git. Generated reports/cache and kit.local.json stay ignored.

## Assumptions

- Canonical JSON sorts keys, rounds finite floats to six decimal places, and treats whole-valued floats and integers identically.
- Records use numeric arrays for coordinates. The reusable range condition supports any matching dimension; the mining view uses three dimensions.
- Resource limits are record-type metadata, including shared capacity across cargo entries. Transactions lock the authoritative world, plan through a read-only view, and validate/canonicalize only touched records before committing them together.
- Flight is an additional declared testbed action. Authoritative position and velocity stay in records; views read them. Physics determinism remains outside scope.
- The manual clock advances one tick per turn; real-time play uses a tunable fixed tick rate. Cooldowns use simulation seconds. Held-input repetition uses that clock and cooldown, independently of feel duration.
- Hard rock rejects without payment under ON_SUCCESS; ON_ATTEMPT commits energy and cooldown with zero yield. A damaging hit counts as yield before a rock breaks. Damage is tool power minus hardness plus one when power meets hardness.
- Cargo CLIP trims new ore and preserves previously owned ore. Dock sale and full refuelling are one transaction; insufficient projected credits reject the entire trade.
- Rule RNG auditing replays raw native draws between captured states, preserving RandomNumberGenerator without unsupported native-method overrides. Rule code must not reseed streams inside actions.
- Saves include records, clock, pending actions/policies, all RNG states, live tuning, active feel resources, logs and events. Rule comparison hashes omit cosmetic RNG and feel presentation.
- The committed schema-0 save is a synthetic fixture to exercise v0_to_v1; no public kit save schema preceded schema 1.
- Placeholder sounds are locally generated tones. Stage numbers and feedback fades are tunable resources; primitive meshes, colors and particle assets are authored Godot presentation resources.
- Stage variants are standalone .tres resources assigned to FeelSequences in Godot. F1 A/B supports registered sequence variants; the testbed registers light/heavy mining sequences.

## Playtest round 2 (2026-10-04)

- Flight: A/D turned the nose and S spun the ship 180°. Now the nose points away from the camera, so A/D strafe and S backs up. Once stopped within reach, the nose turns to the selected rock.
- Enter fired a yellow "shot". The drill beam reused the tool glow that dock feedback also raises. It now has its own glow, raised only by mine_hit.
- "Why can't I mine the yellow rocks?" F1 could not answer it (see CHANGELOG Unreleased): the Log tab was always empty, and Why on a rock never showed refusals. Both are fixed. The game also says it directly: the target line warns "too hard: tool power 2.0 is below hardness 4.0", and the refusal message names tuning/mining.tool_power. Messages now wrap and centre, so long ones fit on screen.
- Design note for the designer: with default tuning (tool_power 2, hard_threshold 4), gold can never be mined. The lab has no tool upgrade, so gold only becomes minable by raising mining.tool_power in F2.
- F2: Apply/Discard moved to the top of each open group; tooltips removed (see CHANGELOG).

## Playtest round 3 (2026-10-04)

- Nose: it followed camera panning, which was not wanted. Now it only turns while W is held, toward where the camera looks, and finishes that turn smoothly after W is released. It eases in and out (presentation.ship_turn_rate 240°/s top speed, new presentation.ship_turn_ease 0.3 s). Orbiting, A/D and S never turn it. When stopped within reach with no flight key held, it still noses toward the selected rock.
- F1/F2 were hard to read: buttons looked like plain text. The overlay now has a shared theme (see CHANGELOG).
- F1 Why still didn't answer "why can't I mine gold?", because it showed whatever the World tab had selected (dock:home). Why now has its own pickers, plus a notice that always explains the newest refusal. The Log tab collapses flight repeats.
- Light vs heavy impact: the designer found the difference clearly visible, but expected heavy to do more damage. It doesn't, by design: feel variants never change rule outcomes, and the compare run proves it. This is a labelling problem. "B: impact A/B", "Heavy impact." and "Impact: mine hit" read like a stronger tool, not a presentation-only A/B. Open ticket: label it as looks-only in the HUD, toast and hints.

- F1 Why's Thing dropdown covered the whole screen and listed rocks out of order (rock:000, then 029 down to 001). Godot's StringName sort is not alphabetical, so KitWorld.ids() broke its documented sorted order. Fixed (see CHANGELOG). The picker is now a short scrolling list under its button, grouped Dock/Rock/Ship.

## Windows test-command fix (2026-10-04)

- The designer's tools/kit.ps1 test on Windows died at the import step, before any scenario ran. Godot warned "Detected another project.godot at res://reports/install-smoke/…" on stderr, and Windows PowerShell 5.1 makes stderr lines terminating under 'Stop'. Fixed in kit.ps1 and verify_install.ps1 (see CHANGELOG); reports/.gdignore removes the warning itself.
- Verified on Linux with PowerShell 7.4. The 5.1 failure could not be reproduced here: 7.x no longer applies 'Stop' to native stderr. The helper captured the real Godot warning as text, exit 0. kit.ps1 test passed 7/7 with an install-smoke project under reports/ and no warning in import.log. verify_install.ps1 passed end to end, and verify_ui still passes 24/24 with reports/.gdignore. Confirmed on 2026-10-04: the designer reports tools/kit.ps1 test passes on Windows.

## Kit adoption in games (2026-10-04)

- The designer asked how the kit gets applied to real games and to the game dev template, and whether game work flows back into the kit. Neither direction is automatic, so the rules and process are now shipped with the kit.
- addons/agent_kit/KIT_RULES.md holds the agent rules for games: where code goes, how gameplay is built, feel, evidence, kit requests and updating. It travels with the kit and updates on reinstall. The kit repo's AGENTS.md says to keep it in step with kit changes.
- templates/game/AGENTS.md and KIT_REQUESTS.md are starter files. install_kit.ps1 copies them only when missing and warns if an existing AGENTS.md lacks the KIT_RULES.md pointer. The manifest records the kit repo path. An installed game's kit.ps1 prints a notice when that repo's VERSION differs from the installed one.
- install_kit.ps1 used [System.IO.Path]::GetRelativePath, which Windows PowerShell 5.1 does not have; it is replaced by a helper. Manifest paths keep their format (checked: 76 entries, same keys).
- Verified on Linux with Godot 4.7.2 and PowerShell 7.4. verify_install.ps1 passes, with new checks: starter files on a clean install, KIT_RULES.md inside the kit, manifest source, an existing AGENTS.md preserved with a warning, and the newer-kit notice. With the notice deliberately broken, verify_install fails on that check. tools/kit.ps1 test and lint pass. Not run on Windows PowerShell 5.1.
- Full tools/kit.ps1 test under Xvfb: 10/10 sim scenarios pass. Play scenarios: play_flight_and_dock and play_overlay_defaults pass, play_targeting fails. The failing assertion is "Idle F3 explains that it finishes a current effect". It fails identically on untouched main (86c46ae), so it is pre-existing and not caused by this change. Confirmed cause: the designer's "First True Test" commit on main (1703354, after Codex's verification) set feel stage rock_break_1 (debris) to 2.5 s. The test waits a fixed 0.8 s and expects no effect playing, so F3 is not idle. With the duration temporarily set back to 0.35 s, play_targeting passes. The designer's 2.5 s is kept; the test fix belongs to ticket 11. Separately, in this container windowed runs make kit.ps1 exit 1 even when every scenario passes: Godot logs an audio-driver "ERROR:" line because there is no sound device. Windows is unaffected.
- Not done here: the game dev template repo itself. To adopt, install the kit into the template project, which brings the starter files with it.

## Open tickets

None. Ticket 11 is complete locally; its scope and evidence are retained in this file.

## Completed ticket 10 scope

10. Editable controls (implemented 2026-10-04; designer chose option A: Apply saves the game's default controls into the project, like tuning).
    - Problem: every key is hard-wired.
      - game/views/mining_lab.gd checks KEY_W, KEY_SPACE, etc. directly, and Numpad Enter is a second hard-coded case (KEY_ENTER, KEY_KP_ENTER).
      - The key-hint line is typed by hand and has gone stale more than once.
      - The overlay's F1/F2 keys are fixed in addons/agent_kit/ui/overlay.gd.
      - scenarios/support/play_scenario.gd presses physical keycodes, so any rebind would make play scenarios press the wrong key.
    - Kit (addons/agent_kit/):
      - A controls declaration resource. Each action has an id, a plain-English description, a group and up to two keys (keyboard keys and mouse buttons). Register it into Godot's InputMap at boot.
      - The kit's own F1/F2/F3 keys become kit actions in the same list, so conflicts are checked across kit and game.
      - A Controls group at the top of F2: each action shows its description and key slots. Click a slot, then press a key to rebind. Same Trial / Apply / Discard flow as tuning, plus Reset to defaults.
      - Conflicts are refused with a plain-English message ("Space is already drill selected target").
      - Apply writes the game's default controls resource in the project (option A). Personal per-machine bindings are out of scope.
      - map.gd adds a Controls section to GAME_MAP.md listing every action with its keys and description.
    - Testbed (game/):
      - Declare the lab's actions: fly forward/back/left/right/up/down, drill selected target, sell and refuel, hit look A/B, charge policy, save, load, restart trials and exit. Enter and Numpad Enter become one action with two keys.
      - mining_lab.gd reads named actions instead of key codes.
      - Generate the hint line from the current bindings.
      - Keep the input-to-world-direction mapping and every rule outcome unchanged.
    - Tests:
      - Play scenarios press the key currently bound to a named action, and every scenario starts from default bindings, so a designer's rebind cannot break tests.
      - New play scenario: rebind fly forward to another key, check that the new key flies, W no longer flies, and the hint line shows the new key. Also check a conflicting rebind is refused and Discard restores W.
      - Default-state check for the new F2 Controls group.
      - Inspected screenshots of the Controls group and the updated hints.
    - Done means:
      - VERSION 0.3.0 with CHANGELOG and README entries (new kit API and file format; save schema unchanged unless bindings enter saves, which they should not).
      - tools/kit.ps1 test, compare, map and lint pass; verify_ui passes; STATE updated.
      - Out of scope: gamepad, per-player bindings and in-game rebinding for shipped games.

## Completed ticket 11 scope

11. Rule tests must not depend on the designer's live tuning (found 2026-10-04).
    - Problem: an F2 Apply saved mining.tool_power 3.0 and mining.hard_threshold 3.0 to game/tuning/mining.tres (reverted at the designer's request; main keeps the designer's range 4.0, energy_max 60 and 2.5 s debris effect). Gold became minable, and mine_hard_rock and charge_policy_binding failed, because scenarios load the live tuning files. Any balancing pass can break rule tests that are not about balance. The designer chose to revert to tool power 2 / hard threshold 4 for now.
    - Change: scenarios set every tuning value their assertions depend on, through the existing "tune" command or setup, instead of inheriting it. For example, mine_hard_rock sets a hardness above tool power itself. Keep a separate, clearly named scenario, or a check in kit.ps1 test, that reports when the shipped defaults change, so balance changes stay visible without failing unrelated tests.
    - Same for feel: play_targeting's idle-F3 step waits a fixed 0.8 s and fails since the designer set rock_break_1 to 2.5 s. Play scenarios should wait until no effect is playing (Kit.feel.is_playing() is false, with a timeout), or pin the stage durations they rely on.
    - Kit side: add a scenario helper that pins a list of knobs, and say in KIT_RULES.md that scenarios pin the tuning they assert on.
    - Done means: changing any single mining tuning knob in F2 and applying it leaves every rule scenario green except ones that are explicitly about default balance; kit.ps1 test passes; STATE updated.

## Completed review/playtest tickets (2026-10-04)

All nine tickets below are implemented. The designer reported a passing playtest of the current 0.3.0 lab on 2026-10-04.

1. Hit-look labels in hints, HUD, toasts and Feel pickers explicitly say light/heavy have the same damage. Damage remains controlled by mining.tool_power.
2. Clicks select and capture a smooth, one-time nose goal; Space alone drills. W retains its eased camera-forward turn. There is no stopped-ship tracking, automatic target or Space-release latch. Broken targets clear and no-target Space explains how to select. Selection has immediate FeelSequence feedback. README, hints, verify_ui and play_targeting match these controls.
3. Enter and Numpad Enter invoke the same dock action. play_flight_and_dock drives both keys and verifies trade/refill without a mining beam.
4. Designer choice confirmed: keep the lab focused. F3 and the Feel button say "Finish current effect". Active F3 leaves rule state/timing unchanged; idle F3 explains that there is no effect and points to F1 replay.
5. Designer choice confirmed: gold intentionally demonstrates a harder rock. Its HUD instruction directs the player to Mining / tool power in F2. No upgrade system is added.
6. ActionDef.charge_policy_key binds mining to mining.charge_on_attempt. Execution, queued actions, Discard and restored tuning use that single live policy. Legacy schema-1 charge fields are ignored for bound actions; unbound actions retain the old behavior. charge_policy_binding exercises conflicts and missing bindings. GAME_MAP names the binding. VERSION/CHANGELOG are updated; the save shape remains schema 1 and existing fixtures pass.
7. Transactions copy only touched records and validate/commit their changes together. large_terrain_records exercises 2,000 records with 128 numbers each; every action copies exactly two records. Its final baseline measured 310.7 microseconds per action and 840,050 microseconds for a five-full-copy reference workload on this machine. These are measurements, not a portable threshold or whole-action speedup claim. Rejection, RNG rollback, nested read ownership, invalid additions, existing add/remove and clipping tests pass.
8. RNG audit sorts stream names as text. rng_two_streams creates/draws zeta before alpha and verifies alpha/zeta audit order with repeat and save/reload.
9. First-class play scenarios use engine input events with physical keycodes, mouse motion/buttons and manual rule ticks. test runs both suites; -Play selects windowed input scenarios. They cover camera flight, targeting, docking, all five default F1 tabs, empty-search F2 and an input-driven refusal. AGENTS.md requires screenshot inspection for player-visible tasks. New-run overlay state resets, and empty Log/Events explain their state. Hardware input and human feel remain outside the verification claim.

Implementation assumptions: selection is view state and emits a declared presentation event, without a rule action or world mutation. Only touched records are canonicalized during an action. Whole-valued float representations retain their declared float resource behavior. Overlapping feel stages caption the sequence actually emitting them.

## Original ticket scope (implemented above)

Testbed (game/):
1. Light/heavy hit wording. The designer saw a clear difference but expected heavy hits to do more damage. Label the variant as looks-only in the hint line ("B: hit look, light/heavy"), the B toast ("same damage, bigger shake and flash") and the target line ("Hit look: heavy"). Damage stays with mining.tool_power.
2. Targeting and nose (designer direction):
   - Clicking a rock only selects it; it never mines. Space is the only mining input.
   - The nose turns to face a rock once, smoothly, when the player clicks it. Remove the automatic noses-to-target when stopped within reach. W keeps its current eased turn toward the camera's forward direction.
   - No auto-targeting: when the target breaks, the target clears. Space with no target shows "No rock selected. Click a rock to target it." The Space release latch can go once nothing auto-selects.
   - Update hints, tools/verify_ui.gd and the windowed probe evidence to match.
3. Numpad Enter (KEY_KP_ENTER) should also sell and refuel, like Enter.
4. F3 "skip feel" looks broken. Kit.feel.skip() jumps the feel sequence playing now to its last stage, but mining sequences last about 0.5 s, so a press almost always finds nothing playing. Decide between relabelling it (e.g. "F3: jump to end of current effect"), making it a toggle that turns presentation off while testing rules, or removing it from the lab's hints. The F1 Feel tab has the same "Skip to final stage" button.
5. Gold is unminable with default tuning (tool_power 2 < hardness 4) and the lab has no tool upgrade. Decide whether that is intended, or add a way to raise drill power in play.

Kit (addons/agent_kit/):
6. Charge policy has two sources of truth: the action definition and the mining.charge_on_attempt knob, bridged by game/setup.gd. GAME_MAP always shows ON_SUCCESS, and saves store both. Let an action definition point its policy at a tuning knob. This changes the public API, so it needs a CHANGELOG entry and VERSION bump.
7. Every action copies the whole world about five times (action_runner.gd). Stage only the records an action touches, and add a large-terrain-record scenario that measures speed. Must land before porting Rust Bucket.
8. KitRng.end_action sorts stream names with Array.sort() on StringNames, which is not alphabetical, so rng_draws order in records may vary between runs or builds. Use a text sort, and add a two-stream scenario.
9. Testing gap. Scenarios call rules directly, and verify_ui only checked pre-filled panels, so unplayable flight, empty F2, empty Log and an unanswerable refusal all shipped green. Add play scenarios that drive physical input and the camera and take screenshots. Add default-state checks for every overlay panel and tab. Make "inspected screenshots" part of done for any task that changes what the player sees or does.

## Verification

Ticket implementation (2026-10-04, Windows, Godot 4.7.2 official build, Compatibility renderer):
- tools/kit.ps1 test: exit 0, 10/10 sim scenarios and 3/3 windowed play scenarios; all repeat and midpoint save/reload checks pass. Logs: reports/engine-profile/test.log and play.log. Final sim reports are under reports/<scenario>/20261004-14073* through 140757*.
- Final play reports: reports/play_flight_and_dock/20261004-140759-1769160, reports/play_overlay_defaults/20261004-140810-12669842, and reports/play_targeting/20261004-140811-14095341. Baseline screenshots cover flight/docking, all default tabs/F2, refusal, click-only selection, cleared target, gold power wording and heavy same-damage wording.
- tools/verify_ui.tscn: exit 0, 25/25 checks including an actual select-only click before Space; latest inspected evidence: reports/ui-verification/20261004T141839-1275902. The previous click/camera synchronization failure is retained in reports/ui-reruns/20261004-click-camera-failure; the helper now waits for the drawn frame before projecting a click. Future UI runs have unique evidence directories.
- tools/kit.ps1 compare feel_change_is_scoped mine_hit mine_hit_heavy -Render: exit 0; identical constraints, world hashes, energy/cargo and action timing, with four screenshots under reports/feel_change_is_scoped/20261004-140423-1795501.
- tools/verify_install.ps1: exit 0; clean/unchanged/forced install, local-edit refusal, import and empty-project boot pass. Evidence: reports/install-smoke/6175169e70ff407b8613199855260b81/verification.json and boot.log.
- tools/kit.ps1 map and lint: exit 0. git diff --check passes. Screenshots named above were inspected for readable HUD/toasts, target clearing, panel defaults, refusal explanations, tuning controls and cosmetic A/B differences. Final runs have no script/resource/shutdown errors; the known offline certificate-store warning remains.
- Earlier failures are preserved: the initial staging constructor leaked script resources at shutdown, a play-mode declaration was missing on concrete scenarios, and an occluded gold fixture selected a nearer stone. These were corrected and the final repeat/save-reload runs pass.
- One final map process stalled after printing "Game map generated"; it was stopped and an immediate rerun exited 0. The stalled output is retained in reports/ticket-map-stalled.log. The cause of that isolated stall is unconfirmed.

Playtest patch (2026-10-04, Linux sandbox, Godot 4.7.2 official build, PowerShell 7.4.6):
- tools/kit.ps1 test: exit 0; all seven scenarios passed with repeat and midpoint save/reload.
- tools/kit.ps1 compare feel_change_is_scoped mine_hit mine_hit_heavy: exit 0; A/B constraints identical.
- tools/kit.ps1 lint and map: exit 0. GAME_MAP.md regenerated.
- After the Thing-picker fix: tools/kit.ps1 test (7/7), compare and lint pass. tools/verify_ui.tscn passes 24/24, with new checks that the list is alphabetical, grouped and fits under its button, and that picking closes it and selects the thing. Screenshot inspected.
- After round 3: tools/kit.ps1 test (7/7), compare and lint pass. tools/verify_ui.tscn passes 21/21, with new checks that the refusal notice answers while dock:home is selected and that its Show button selects the rock. The harness now waits for feel sounds before quitting: round 2's run had reported a clunk.wav "resource still in use" at shutdown, an artifact of the harness quitting mid-sound. A windowed probe confirmed: orbiting 120° left the nose at 0°, W eased the nose 1→5→10→19→…→142→146→165°, and A/S left it alone. F1/F2 screenshots inspected.
- After round 2: tools/kit.ps1 test (7/7), compare and lint pass; tools/verify_ui.tscn passes 19/19. New checks: Why on a rock explains a refused hit, the Log tab lists refusals with no filter typed, plus a refusal screenshot. A windowed probe showed the nose staying at 45° during A-strafe and S-reverse, no beam on Enter, and the gold refusal message wrapping on screen.
- tools/verify_ui.tscn under Xvfb (round 1): all 16 UI checks passed, including 5 new ones: F2 lists every group, the cursor is in search, clicking a group opens it, a no-match search says so, and the empty panel is screenshotted. Against the old overlay.gd the four new behaviour checks fail; the screenshot check passes either way. Screenshots were inspected.
- A throwaway windowed probe (not committed) drove the real lab with physical keys. Results:
  - W+D flew nose-first toward the rocks.
  - A launch-point hit was rejected with "Fly closer".
  - Two hits within reach broke rock:000, and the target moved to rock:005.
  - Holding Space did not start mining rock:005.
  - The screenshots were inspected.
- Gaps: none of this was run on Windows, and nobody has played it by hand yet.

Original build (2026-10-03):

- tools/kit.ps1 test: exit 0; all six scenarios passed in sim with repeat and midpoint save/reload. Final run is recorded in reports/final-test.log and reports/<scenario>/20261003-1038*/report.json.
- Required scenario outcomes: soft rock costs 8 energy and yields 3 iron; full cargo clips to exact capacity while preserving prior gold; hard rock rejects without cost vs attempted_no_yield with one cost; mining/docking returns full energy and 31 credits.
- Windowed tools/kit.ps1 scenario feel_change_is_scoped -Render: exit 0. Four 1280×720 PNGs, both variants, at impact and after rock break. Report: reports/feel_change_is_scoped/20261003-103643-1457611/report.md.
- A/B compare: exit 0; energy spent 8, ore yield 3, action ticks [0, 9], energy cost 4 and cooldown 0.3 identical, including the complete world hash. Report: reports/feel_change_is_scoped/20261003-103649-779878/report.md.
- kit_integrity covers atomic rejection, read-only planning, record add/remove, integer fields, 2D range checks, canonical JSON, ring ownership/capacity, queued RNG draw auditing/order, corrupt-save fallback, malformed payload rejection, migration fixtures, tuning trials/discard/ranges, Apply and variant reload.
- Actual physical-key/clock callbacks and overlay controls passed 10 UI checks. F1 Why names tuning/mining.energy_cost and the input source; F2 Apply/Discard/variant callbacks write only report-local verification copies. Report and inspected screenshots: reports/ui-verification/.
- tools/verify_install.ps1 passed clean installation, unchanged reinstalls, edited-file refusal, forced replacement, import and boot of an empty Godot 4.7 project with all nine services and a manual clock. Evidence: reports/install-smoke/2de44f8cfda44fa18019a50c7e95d9f2/verification.json and boot.log.
- tools/kit.ps1 map, lint and dump mine_basic: exit 0. Map regenerated from resources; heuristic lint found no violations. git diff --check passed.
- Earlier failed scenario reports are preserved alongside passing reruns. A physical-input UI harness synchronization failure is preserved under reports/ui-reruns/20261003-physical-input-failure; waiting for the input frame corrected the harness and the rerun passed.

## Known issues / designer acceptance

- Automated HUD captures sometimes omit text; ticket 11's section records failed and readable comparisons. Functional scenario checks pass, and the cause is unconfirmed. Recheck capture reliability before using those images as visual acceptance evidence.
- The designer's 0.3.0 playtest passes. W changes its movement direction when the camera orbits; that is intended. Broken targets clear and require a fresh click.
- An F5 save written before the playtest patch also stores live tuning. Loading it brings back mining.range 8 as a live trial; Discard in F2 restores 2.5.
- At 2 m or less from a rock, the ship model visibly overlaps it. The lab has no collision; that was out of scope.

- Human acceptance is recorded from the designer's passing playtest, separately from automation and screenshot inspection.
- Sandboxed Godot starts report an inaccessible Windows certificate store. All offline checks complete; no network capability is required. There are no remaining script, resource-load or shutdown-leak errors in final runs.
- Repeatability covers declared records, controlled RNG and clock on the tested engine version. Native physics and cross-version RNG equivalence are not claimed.
- Lint is intentionally heuristic.
- A single post-generation map-process stall occurred; its immediate rerun passed. Investigate if it recurs.

## Next steps

0. Publish ticket 11 through a PR as requested, then record the actual merge and sync main. Future scenarios pin assertion inputs before world creation, press named controls and use actual effect completion for idle checks.

1. Optional designer smoke check: change a mining knob in F2, Apply, then run tools/kit.ps1 test. Rule fixtures should stay green and shipped_default_balance should show the balance change. Update its reference only when accepting the new shipped defaults. Current player feel and the earlier overlap issue are outside ticket 11's changes.
2. Record the preferred charge policy and feel direction; patch through scoped tickets after review against DESIGN.md.
3. Continue the merged Rust Bucket design work before porting it.
4. Prove broader reuse with a Railroad Wars slice before adding the kit to the game template.
