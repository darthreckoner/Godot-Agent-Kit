# STATE

## Build version

0.1.0 — complete first implementation, verified on Godot 4.7.2 on 2026-10-03.
Testbed playtest patch on 2026-10-04 (branch claude/v0-1-review-issues-1ntmju). The kit is unchanged, so VERSION and CHANGELOG are unchanged.

## Playtest patch (2026-10-04)

The designer's first playtest found three testbed problems. All three are fixed in game/ and the kit is untouched.

- Flight followed fixed world axes: W moved the ship toward its port side and the ship never turned. Now WASD follows the camera (W flies away from it, A/D go to its left/right, Q/E down/up). The ship model turns to face where it flies, and the camera starts behind and to one side of the ship (presentation.camera_start_yaw, -45°). The move_ship rule and its world-direction input are unchanged.
- Mining worked from far away. mining.range was 8 m, measured centre to centre, and the ship started within reach of most rocks. Reach is now 2.5 m, about the drill touching the rock face, and the launch point (4.5 m from the nearest rock) is out of reach. The target label shows "in drill reach" or "fly X m closer", and the selection ring is gold in reach and red out of reach. A short beam runs from the drill tip to the struck rock on every committed hit. Parked within reach, the ship model turns its nose to the selected rock. The rejection now reads "Fly closer: the drill must reach the rock."
- "Choose a rock that has not already broken" came from a stale target. A broken rock stayed selected, and clicking empty space or pressing Space still mined it. Now a broken target hands over to the nearest live rock, and Space must be released before mining continues on that new rock. A click that hits no rock does nothing. With no live rocks left, Space shows "No rock selected."
- New tuning knobs: presentation.ship_turn_rate and presentation.camera_start_yaw.
- F2 tuning panel (kit UI, see CHANGELOG Unreleased): it opened blank, because an empty search matched nothing, and the search box was nearly invisible. It now lists every group collapsed, with game and kit settings above feel stages. Search matches every typed word and opens matching groups. The search box is visible and takes the cursor when F2 opens.
- Scenarios: mining scenarios now start parked 2 m from rock:000 (scenarios/mining_scenario.gd). economy_round_trip flies 50 ticks to the dock instead of 28. The kit_integrity 2D range probe uses a 2 m distance. A new mine_out_of_range scenario proves a launch-point hit rejects on mining.in_range with no cost, and that flying in and stopping makes the rock minable. tools/verify_ui.gd parks the ship within reach before its Space press.

## Delivery

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
- Resource limits are record-type metadata, including shared capacity across cargo entries. Transactions validate a private world before committing.
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

## Verification

Playtest patch (2026-10-04, Linux sandbox, Godot 4.7.2 official build, PowerShell 7.4.6):
- tools/kit.ps1 test: exit 0; all seven scenarios passed with repeat and midpoint save/reload.
- tools/kit.ps1 compare feel_change_is_scoped mine_hit mine_hit_heavy: exit 0; A/B constraints identical.
- tools/kit.ps1 lint and map: exit 0. GAME_MAP.md regenerated.
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

- Test gap behind both playtest rounds: scenarios call rules directly, and verify_ui typed a search before looking at F1/F2. So "unplayable flight", "empty F2", "empty Log" and "no answer for a refusal" all shipped green. Proposed kit work: input-driven play scenarios (physical keys, camera, screenshots) as a first-class scenario mode, plus default-state checks for every overlay panel and tab. Until then, every view change gets a windowed probe and inspected screenshots.
- F1 Log is flooded by move_ship records while flying (one per tick); use the action filter, e.g. "mine".

- Playtest patch: the Space latch and the auto-retarget choice (nearest live rock, measured from the ship) are untested by a human. Camera-relative flight means W changes direction when the camera orbits; that is intended, but needs feel acceptance.
- An F5 save written before the playtest patch also stores live tuning. Loading it brings back mining.range 8 as a live trial; Discard in F2 restores 2.5.
- At 2 m or less from a rock, the ship model visibly overlaps it. The lab has no collision; that was out of scope.
- The review raised two kit tickets that are still open. Charge policy has two sources of truth (action definition and tuning knob, bridged by game/setup.gd; GAME_MAP always shows ON_SUCCESS). Each action makes about five full world copies, which must be fixed before porting Rust Bucket.

- Human feel acceptance is pending. Automation and screenshot inspection establish function/accounting/scope, not satisfying flight or mining feel.
- Sandboxed Godot starts report an inaccessible Windows certificate store. All offline checks complete; no network capability is required. There are no remaining script, resource-load or shutdown-leak errors in final runs.
- Repeatability covers declared records, controlled RNG and clock on the tested engine version. Native physics and cross-version RNG equivalence are not claimed.
- Lint is intentionally heuristic.

## Next steps

1. Designer replays the lab with the playtest patch: flight, drill reach, the target hand-over after a break, docking, F1 Why, F2 trial/apply/discard, both charge policies, light/heavy impacts at normal and slow speed, and the invented damage formula (power − hardness + 1).
2. Record the preferred charge policy and feel direction; patch through scoped tickets after review against DESIGN.md.
3. Continue the merged Rust Bucket design work before porting it.
4. Prove broader reuse with a Railroad Wars slice before adding the kit to the game template.
