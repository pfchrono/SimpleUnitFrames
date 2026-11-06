# SUF patches on embedded oUF

Base: upstream oUF `14.2.1` (oUF-wow/oUF `c5ff6e4`, 2026-10-31). Every local change is marked
`-- SUF:` in the source. To sync upstream again, copy the new upstream files over this folder,
then re-apply the patches below. Grep for `SUF:` in the old copy to find them.

| File | Patch | Why |
|------|-------|-----|
| `elements/castbar.lua` | `Castbar:GetCastState()` read-only accessor | oUF 14 made cast state internal; SUF styles bars from casting/channeling/delay/spellID |
| `elements/castbar.lua` | Enable for `*target` units | SUF shows castbars on ToT-style frames. These are OnUpdate polled with no events, so each poll re-runs `CastStart` (restarting `PostCastStart`) and stop/fail colours never show; the bar just hides when the cast ends |
| `elements/health.lua`, `elements/power.lua` | `PartyMemberPath` unitless wrapper | `PARTY_MEMBER_{ENABLE,DISABLE}` can fire without a unit (solo party frames) |
| `elements/range.lua` | `PARTY_MEMBER_*` registered unitless | same as above |
| `elements/threatindicator.lua` | `feedbackUnit` listens to both units, plus target/combat changes; no fallback threat when the feedback unit is missing | party frames tracking `target` |
| `elements/classpower.lua` | Forever target-bound combo points (`GetComboPoints(unit, 'target')`, `PLAYER_TARGET_CHANGED`, `COMBO_TARGET_CHANGED`) | not handled upstream as of 14.2.1 |

Things SUF does *outside* oUF (don't re-add them here):

- Indicator glows/highlights: `addon:AttachIndicatorEffects` (SimpleUnitFrames.lua), via element `PostUpdate`.
- Auras: `Modules/UI/UnitAuras.lua`, built on `frame:CreateAuras()` (AuraContainer).
- `TargetIndicator.Override` delegates to `addon:UpdateUnitFrameStatusIndicators`.

Removed with 14.x: `SmartRegisterUnitEvent`. oUF's `RegisterEvent` already registers unit events
through `RegisterUnitEvent`, including vehicle `realUnit` and header unit changes.
