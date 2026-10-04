# Godot Agent Kit 0.2

A reusable Godot 4.7 addon and a small mining lab. The kit records what your game did, explains why values changed, and lets you try tuning and feel changes safely. It works offline.

## Start playing

Open this folder's project.godot in Godot 4.7 and press F6 on game/views/mining_lab.tscn, or press F5 to run the project. Use the Compatibility renderer.

You start next to a 30-block asteroid, outside drill reach, with no target selected. Orange iron blocks are soft, blue stone blocks are medium, and yellow gold blocks are hard. Clicking selects a block and smoothly faces it once. Fly close enough, then hold Space to drill it. When it breaks, the target clears; click another rock to continue. A successful hit costs 4 energy by default. Two hits break a soft block and collect 3 iron. If cargo fills, only the ore that fits is collected.

Fly left toward the dock. Within 3 metres, Enter sells every ore type and buys a full energy refill. The trade happens completely or is rejected if you cannot afford it.

| Control | What it does |
|---|---|
| WASD | Camera-relative flight; W eases the nose toward camera forward, A/D strafe and S backs up |
| Q / E | Fly down / up |
| Right mouse drag / mouse wheel | Orbit / zoom |
| Click a rock / Space | Select and face once / drill the selected rock |
| Enter / Numpad Enter | Sell cargo and refuel at the dock |
| F1 / F2 | Open the inspector / tuning panel |
| B | Switch light/heavy hit looks; same damage, different shake and flash |
| V | Trial success-only or on-attempt energy charging |
| F3 | Finish the current effect; an idle press explains replay in F1 Feel |
| F5 / F9 | Save / load, including rule continuation and live tuning |
| R | Restart from the saved tuning resources; unsaved trials are discarded |
| Esc | Exit |

The default tool cannot mine hard gold blocks. Under **charge on success**, those hits reject and spend no energy. Under **charge on attempt**, those hits spend energy and start the rule cooldown, but yield nothing. Increase Tool Power in F2 to mine harder rocks.

## Ask why with F1

The World tab lists stable entity IDs in order. Select ship:player, then click Energy. The Why tab shows each recorded operation: the action, tick, input source, old and new values, and the rule or tuning knob responsible. Rejected attempts show their failed checks.

Recently changed fields are highlighted. The Log tab filters the timeline by action or outcome. Events shows the declared event trail. Feel lets you replay the last sequence, slow it to 0.25×, skip to its final stage, and select light/heavy A/B resources. Using A or B subscribes that sequence to its event.

These controls replay presentation after the action has committed. They cannot alter energy, ore, action order, or cooldowns.

## Try tuning with F2

Search any name, group, or help text. Every numeric knob has a unit, range, help and slider. Moving it starts a highlighted **Trial** immediately.

- **Apply** writes that group's resource to disk. This becomes the new value Discard returns to.
- **Discard** restores the last registered or applied values.
- **Save as variant** writes a separate resource named set.name.tres. It refuses an existing name.
- **Restart needed** marks setup values such as ship capacities, rock health, and tick rate. Apply, then restart to rebuild those records.

Stage timing, sound markers, shake, flash and presentation fades are tuning resources too. Art meshes, colors, and particle scene assets remain normal Godot resources. Saving a stage variant creates a standalone stage resource; assign it to a sequence in Godot to use it.

B changes only mining presentation. V changes a live mining policy trial. Neither writes a file automatically.

## Run checks

Copy kit.local.example.json to kit.local.json and set godot_bin to your Godot 4.7 console executable. Alternatively set the GODOT_BIN environment variable. The tools print a clear error when the executable is unavailable.

From PowerShell in this folder:

~~~powershell
.\tools\kit.ps1 test
.\tools\kit.ps1 scenario mine_basic
.\tools\kit.ps1 scenario play_targeting -Play
.\tools\kit.ps1 test -Play
.\tools\kit.ps1 scenario feel_change_is_scoped -Render
.\tools\kit.ps1 compare feel_change_is_scoped mine_hit mine_hit_heavy
.\tools\kit.ps1 compare mine_basic mining mining.charge_on_attempt
.\tools\kit.ps1 dump mine_basic
.\tools\kit.ps1 map
.\tools\kit.ps1 lint
~~~

Test discovers every declared scenario, runs the rule suite headlessly and then runs the input scenarios windowed. Both suites repeat each run and compare continuous play with a midpoint save/reload continuation. Save/reload verification clears the live world, clock, pending queue and RNG before restoring the file. The feel scenario also compares its two variants automatically. Render uses the same rules and the actual mining view, and writes PNGs at marked presentation stages.

Play scenarios set `requires_play = true`, supply a render scene and send engine `InputEventKey` events with physical keycodes, mouse button/motion events, and `input_ticks` commands. The real scene handles input and polls physical keys while rules advance only through the manual clock. `wait_presentation` lets cosmetic turns/effects settle without advancing rules. This verifies engine input handling, camera behavior and UI defaults; it does not simulate hardware drivers or establish human feel acceptance. Screenshots are baseline evidence and must be inspected for any player-visible task.

Reports are saved under reports/scenario/date-time/. Open report.md for the plain-English result or report.json for the complete checks, operation records, repeated/reloaded evidence, numbers and comparisons. Render reports link their screenshots. Failed reports remain available beside reruns.

Lint is a **heuristic regex scan**, not a guarantee. It flags untyped variables, global or cosmetic randomness in game rules, presentation references in rules, and obvious game code that writes kit files. Installed projects also compare kit files against the installer manifest.

Additional verification:

~~~powershell
.\tools\verify_install.ps1
~~~

This creates an empty Godot project under reports, checks clean and forced installs, unchanged reinstalls and edited-file refusal, imports it, and proves Kit boots with all nine services and a manual clock.

tools/verify_ui.tscn exercises the actual overlay input and control callbacks. Run that scene windowed for screenshots in reports/ui-verification. It checks Why, trials, Apply, Discard, variants, and feel replay/skip. These checks do not establish whether the game feels good.

## Install into your game

Create an empty Godot 4.7 project, then run:

~~~powershell
.\tools\install_kit.ps1 -Target 'C:\Dev\YourGame'
~~~

The installer copies addons/agent_kit and tools/kit.ps1, writes the installed VERSION and SHA-256 manifest, and registers the one Kit autoload while preserving existing project settings. It rejects a conflicting autoload or a kit whose files have changed. Use -Force only when you intend to overwrite those installed files.

Open the target project in Godot to import its scripts. Kit boots without the mining lab. Your game registers its own record types, tuning, actions, events and feel resources. Kit does not supply a genre, movement model, camera, dimensionality, or rule content.

Installed kit code should be changed in this source repository and reinstalled. The installer preserves unrelated target files. An extra untracked file inside the installed kit is reported before an ordinary reinstall.

## Where things belong

| Folder | Contents |
|---|---|
| addons/agent_kit | Reusable kit code and resources |
| game/rules | Mining, flight and dock handlers; no presentation |
| game/data | Action, event and record-type declarations |
| game/tuning | Small tuning groups and policy variants |
| game/feel | Feel sequences, stages, placeholder sounds and particles |
| game/views | The scene and views that read records |
| scenarios | Repeatable commands, expectations and comparison constraints |
| reports | Generated evidence; ignored by Git |
| tools | Command wrapper, installer and verification helpers |
| GAME_MAP.md | Generated source-linked inventory |

[GAME_MAP.md](GAME_MAP.md) lists actions, requirements, policies, declared events, tuning units/ranges/help, record types, feel stages and scenarios. Regenerate it after changing declarations.

## How an action stays safe

A handler checks requirements and plans changes against a read-only world view. The authoritative world is locked during the transaction. The runner copies only touched records into private staging and validates their types, minimums, capacities, reasons and event declarations. Any failure discards every staged change and restores rule RNG. On success, the runner commits all changed records, appends the operation record, then emits declared events. Views and feel playback react to those events. No full-world snapshot is needed for an action; saves and hashes still include the complete world.

~~~mermaid
flowchart TD
    A[Declared action request] --> B[Checks and read-only plan]
    B --> C[Private staging world]
    C --> D{Valid changes?}
    D -->|No| E[Reject and log failed checks]
    D -->|Yes| F[Commit all changes]
    F --> G[Append operation record]
    G --> H[Emit declared events]
    E --> I[Rejection feedback]
    H --> J[Views and feel sequences]
~~~

World records use StringName IDs, registered field types, optional array lengths and resource-limit metadata. Reads return copies; after setup, direct put/set/remove calls refuse writes. The action runner owns changes during play. Setup and verified save load may restore records directly. Custom changes extend KitChange and implement apply(world) -> bool, to_dict() and describe(), with an entity, field and reason. Changes involved in a zero-yield cost use cost_only.

A successful damaging mining hit counts as yield even before a block breaks. Damage is tool power minus hardness plus one, provided tool power meets hardness. Under ON_SUCCESS a zero-yield plan rejects; under ON_ATTEMPT only its marked cost/cooldown changes commit. Overflow CLIP trims the new positive resource delta and preserves resources already owned.

An ActionDef can set `charge_policy_key = "mining.charge_on_attempt"` to bind policy to a tuning knob. That knob must be an integer with value 0 (success) or 1 (attempt). Trial, Apply, Discard and save restoration all use this same live source; queued actions resolve it when executed. Leave the key empty to use the definition's `charge_policy`. Schema-1 saves retain their existing policy shape; for a bound action the stored charge is a fallback default, and legacy duplicated live charges are ignored on restore. GAME_MAP documents the binding instead of a misleading fixed policy.

Queued requests resolve at the next tick in tick/sequence order. The clock supports fixed ticks or manual turns; rules read only this clock. Named rule RNG streams derive from the run seed and name. The action audit records each raw native generator draw by replaying between its start/end states, preserving the native RandomNumberGenerator interface. Do not reseed a stream inside an action. Cosmetic randomness is independent.

Canonical JSON sorts keys, rounds finite floats to six decimal places, and treats whole-valued floats and integers identically. World hashes cover records. Scenario continuation hashes also cover clock, pending actions/policies/sequence and rule RNG; cosmetic RNG and feel presentation are excluded from these rule hashes. Saves include cosmetic RNG, live tuning, active feel resources, logs and events as well as rule continuation.

The save wrapper contains kit_version, schema_version, created, checksum_sha256 and payload. Save writes a temporary file, validates it, preserves the prior valid save as .bak, then renames the verified file. Load preserves an unreadable primary as .rejected and tries .bak. Both checksum and payload shape/types are checked. Ordered migrations live in addons/agent_kit/migrations; the integrity scenario exercises the schema-0 fixture and v0_to_v1 migration. This first public save schema is 1.

## Designer playtest

Try docking with a nearly empty battery, filling cargo, switching both charge policies on a hard rock, changing energy cost and discarding it, and comparing light/heavy impacts at normal and slow speed. Decide whether flight feels responsive, rejection feedback is clear, and the heavy sequence is more satisfying. Automated checks establish the accounting and scope; your playtest establishes feel.

See [STATE.md](STATE.md) for verified delivery, bounded assumptions, evidence paths and remaining designer decisions.
