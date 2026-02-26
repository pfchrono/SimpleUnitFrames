# SUF General Integration TODO

## Current Priorities
- [ ] Validate all code changes against current WoW API/runtime constraints before shipping.
- [ ] Keep Lua 5.1 compatibility and avoid unsupported language features.
- [ ] Maintain combat-lockdown-safe frame updates via protected operation queues.
- [ ] Add/update regression checks for unit frames, castbar, auras, and options UI after major refactors.

## In-Game Regression Checklist
- [ ] `/reload` cleanly with no Lua errors.
- [ ] Unit frames update correctly for player/target/party/raid/boss during combat.
- [ ] Aura add/update/remove flows do not leave stale icons or nil-index errors.
- [ ] Castbar text, timing, and interrupts render correctly for all enabled unit types.
- [ ] Options changes apply immediately and persist after relog.
