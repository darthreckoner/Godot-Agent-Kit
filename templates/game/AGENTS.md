# AGENTS.md: [Game name]

## Read first, every session
1. DESIGN.md: the vision and pillars. It overrides your defaults.
2. STATE.md: what exists and what's next.
3. addons/agent_kit/KIT_RULES.md: how gameplay is built on Godot Agent Kit. Follow it.

## What this repo is
[One paragraph: the game, its genre, its camera and controls, and anything an agent must
never change without asking.]

## Game-specific rules
- [Add rules that apply only to this game, e.g. "the ship's physics stays in Godot physics;
  energy, cargo and terrain are kit records".]

## Scope discipline
- Change only what the task asks. If a fix needs a wider change, stop and describe it first.
- Never edit addons/agent_kit/. Kit needs go in KIT_REQUESTS.md (see KIT_RULES.md).
- Save format changes need a migration and a fixture.
- If a request conflicts with a pillar or anti-goal in DESIGN.md, flag it.
