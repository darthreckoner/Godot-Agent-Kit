# Continuity

- Ticket 10 is implemented on codex/ticket-10-editable-controls, based on clean b1c81d8e10df5e9782eed783cc3c59f4c6efe641. The designer reported "play test passes" and authorized commit, push and merge on 2026-10-04.
- Kit 0.3.0 adds declared keyboard/mouse controls, Kit.controls, shared kit/game conflict checks and the top F2 Controls group with Trial/Apply/Discard/Reset. Apply writes game/data/controls.tres. Bindings stay outside schema-1 saves and rule hashes. Lab input and hints use named controls.
- Final tools/kit.ps1 test passes 10 sim + 4 play scenarios with repeat/save-reload. UI verification passes 27 checks; rendered feel compare, map, lint and installer retry pass. STATE.md records exact reports, inspected screenshots and the preserved unexplained first installer-import failure.
- Designer gameplay tuning/feel files are unchanged. Test fixtures explicitly establish hard-rock/refusal conditions; the idle probe waits for declared effect durations. Play scenarios reset declared controls independently of saved rebinds.
- Human acceptance is recorded from that passing 0.3.0 playtest; individual manual steps were not enumerated. Ticket 11 and distribution work on origin/claude/v0-1-review-issues-1ntmju at bc43b44 remain outside this merge. STATE.md is authoritative for current status.
