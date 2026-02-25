# Work Summary

## 2026-02-24 — Completed

- Added Action Bars tab navigation and search metadata for options indexing. ([Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L240-L323))
- Implemented Action Bars UI controls for enable, skinning, fade, and per-bar visibility. ([Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L1934-L2020))
- Removed Smooth Bars controls from the Library Enhancements panel. ([Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L1847-L1863))
- Dropped Smoothie defaults from enhancements profile settings. ([SimpleUnitFrames.lua](SimpleUnitFrames.lua#L186-L206))
- Removed the Smoothie module from addon load order. ([SimpleUnitFrames.toc](SimpleUnitFrames.toc#L15-L21))
- Removed Smoothie module file (entire file deleted). (Modules/System/Smoothie.lua)

- Performance impact: Slight improvement when Smoothie was enabled (removes per-frame smoothing ticker work).
- Risk level: Low to Medium (new Action Bars UI wiring; Smoothie removal).
- Validation: Not run (manual in-game options check recommended).
- Status: Action Bars options available; Smoothie removed.

## 2026-02-25 — In Progress

- Hardened health color updates to avoid secret values when selecting class/threat/reaction colors and resolving RGB values. ([SimpleUnitFrames.lua](SimpleUnitFrames.lua#L6636-L6716))
- Added per-frame Blizzard unit frame hide defaults and applied them in the Edit Mode visibility toggle. ([SimpleUnitFrames.lua](SimpleUnitFrames.lua#L211-L218), [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L7776-L7812))
- Exposed per-frame Blizzard unit frame hide toggles in the Global options UI. ([Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L1919-L1928))
- Removed the Hide Blizzard Default Bars setting from action bar defaults and options UI. ([Modules/ActionBars/Core.lua](Modules/ActionBars/Core.lua#L128-L166), [Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L1954-L1966))
- Fixed Bar1 artwork hiding by targeting MainActionBar art frames (BorderArt/EndCaps/QuickKeybind glows). ([Modules/ActionBars/Core.lua](Modules/ActionBars/Core.lua#L503-L523))
- Added dedicated XP bar fade controls and behavior for Data Bars. ([SimpleUnitFrames.lua](SimpleUnitFrames.lua#L222-L238), [Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L1888-L1908), [Modules/UI/DataSystems.lua](Modules/UI/DataSystems.lua#L67-L116), [Modules/UI/DataSystems.lua](Modules/UI/DataSystems.lua#L1166-L1308))
- Restricted DataText/DataBars drag handles to show only on Shift+left-click hover. ([Modules/UI/DataSystems.lua](Modules/UI/DataSystems.lua#L67-L108), [Modules/UI/DataSystems.lua](Modules/UI/DataSystems.lua#L862-L1004), [Modules/UI/DataSystems.lua](Modules/UI/DataSystems.lua#L1114-L1469))
- Added `ApplySUFBackdropColors` helper for safe theming fallback and reused it in theme styling helpers. ([Modules/UI/Theme.lua](Modules/UI/Theme.lua#L123-L440))
- Refactored options window and data systems backdrops to use safe theming helper calls. ([Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L138-L3459), [Modules/UI/DataSystems.lua](Modules/UI/DataSystems.lua#L845-L1499))
- Added Action Bars settings to fade Blizzard XP/Reputation bars using shared fade logic. ([Modules/ActionBars/Core.lua](Modules/ActionBars/Core.lua#L179-L275), [Modules/ActionBars/Fade.lua](Modules/ActionBars/Fade.lua#L24-L586))
- Added Action Bars UI controls for Blizzard XP/Reputation bar fade tuning. ([Modules/UI/OptionsWindow.lua](Modules/UI/OptionsWindow.lua#L2070-L2103))
- Synced unit frame portrait alpha to the frame for fader-driven fades. ([SimpleUnitFrames.lua](SimpleUnitFrames.lua#L5655-L5669))

- Performance impact: Neutral (UI theming helper adds minimal overhead; Blizzard XP bar fading reuses ActionBars fade loop; portrait alpha sync is a lightweight hook).
- Risk level: Medium (new fade paths for Blizzard bars and portrait alpha hook; verify no conflicts with Edit Mode/StatusTrackingBar animations).
- Validation: Not run (manual in-game Edit Mode + party frame update check recommended).
- Status: Blizzard XP/Reputation fade controls added; portraits now follow fader alpha.
