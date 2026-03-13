# TODO.md - SUF Open Backlog

**Last Updated:** 2026-03-12
**Current Phase:** Post-v1.33.1 Follow-Up
**Status:** Completed roadmap items were pruned from this file and archived in [TODO_BACKUP.md](TODO_BACKUP.md). This file now tracks only remaining open work.

---

## IMMEDIATE FOLLOW-UP

### Non-Unit Coalescer Expansion

**Status:** 🟡 PENDING

**Objective:** Expand coalescer coverage only to the next safest non-unit event buckets.

**Open Work:**
- Identify the next low-risk non-unit buckets after `SPELL_UPDATE_COOLDOWN`/`SPELL_UPDATE_CHARGES` and `BAG_UPDATE`
- Add rollout metrics comparable to `/suf coalescer`
- Validate each new bucket in live gameplay before broadening scope further

---

## VALIDATION DEBT

### Safe Value Helpers In-Game Verification

**Status:** 🟡 PENDING

**Open Checks:**
- [ ] `/reload` and verify no errors
- [ ] Check helper behavior in debug console (`SafeCompare`, `SafeArithmetic`, `SafeToNumber`, `SafeToString`)

### Profile Import Validation In-Game Verification

**Status:** 🟡 PENDING

**Open Checks:**
- [ ] `/reload` and test normal profile import
- [ ] Try importing a corrupted profile string and verify a clear error
- [ ] Verify malformed import handling is user-friendly and non-fatal

### Modular Options Page Builders Full In-Game Validation

**Status:** 🟡 PENDING

**Open Checks:**
- [ ] Verify all extracted OptionsV2 pages render correctly
- [ ] Verify settings apply and persist across reload
- [ ] Verify Custom Trackers page is fully functional (bar CRUD, entry management, all sections)
- [ ] Verify search navigation still works across extracted pages
- [ ] Verify no visual regressions or Lua errors on `/reload`

---

## OPTIONAL ENHANCEMENTS

### Shaman Totems Quality-of-Life Enhancements

**Status:** 🟡 OPTIONAL

**Notes:** Core Totem integration is validated. Remaining work is optional polish only.

**Potential Enhancements:**
- Configurable Totem size
- Configurable Totem positioning
- Right-click dismiss support

### Backwards Compatibility Profile Migrations

**Status:** 🟡 OPTIONAL

**Notes:** Needed only when future schema changes require compatibility helpers.

### Sidebar Tab UI Overhaul

**Status:** 🟡 OPTIONAL

**Objective:** Explore a fuller vertical sidebar/tab overhaul beyond the current validated OptionsV2 sidebar.

---

## DEFERRED FEATURES

### High-Risk Features

**Status:** 🔴 DEFERRED

- Modular Cooldown System
- Advanced Aura Filtering
- Frame Preview Mode

---

## NOTES

- Full historical roadmap content is preserved in [TODO_BACKUP.md](TODO_BACKUP.md).
- Validated DataText, Totems, and release-prep work were intentionally removed from this file to keep the active backlog small and actionable.
