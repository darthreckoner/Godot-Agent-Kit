# STATE

## Build version

0.1.0 — complete first implementation, verified on Godot 4.7.2 on 2026-10-03.

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

## Verification

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

- Human feel acceptance is pending. Automation and screenshot inspection establish function/accounting/scope, not satisfying flight or mining feel.
- Sandboxed Godot starts report an inaccessible Windows certificate store. All offline checks complete; no network capability is required. There are no remaining script, resource-load or shutdown-leak errors in final runs.
- Repeatability covers declared records, controlled RNG and clock on the tested engine version. Native physics and cross-version RNG equivalence are not claimed.
- Lint is intentionally heuristic.

## Next steps

1. Designer playtests flight, docking, F1 Why, F2 trial/apply/discard, both charge policies, and light/heavy impacts at normal and slow speed.
2. Record the preferred charge policy and feel direction; patch through scoped tickets after review against DESIGN.md.
3. Continue the merged Rust Bucket design work before porting it.
4. Prove broader reuse with a Railroad Wars slice before adding the kit to the game template.
