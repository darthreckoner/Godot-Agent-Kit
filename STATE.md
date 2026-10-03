# STATE

## Build version
v0.1 one-shot (not started)

## What exists
- DESIGN.md, BUILD_PROMPT.md, AGENTS.md. No code yet.
- Git repository initialized on `main`; `origin` is `https://github.com/darthreckoner/Godot-Agent-Kit.git`.
- `.gitignore` excludes Godot cache, generated reports/builds/exports and machine-specific `kit.local.json`.

## Assumptions made (need designer review)
- (coder fills in during the one-shot build)

## Open design questions
- Which charge policy Rust Bucket uses for mining (on success vs on attempt). The testbed
  ships both so the designer can feel the difference.

## Known issues / flat spots
- `tools/kit.ps1 test` is unavailable until the kit is built; repository setup was verified with Git checks.

## Next steps
1. One-shot build v0.1 from BUILD_PROMPT.md.
2. Designer playtests the testbed: F1 "why" panel, F2 tuning, both charge policies, both mine_hit variants.
3. Review the build against DESIGN.md pillars; patch via tickets.
4. Finish the Claude Demo vs Codex Demo comparison → merged Rust Bucket DESIGN.md.
5. One-shot the merged Rust Bucket on the kit.
6. Prove reuse with a small Railroad Wars scenario, then add the kit to the game template.
