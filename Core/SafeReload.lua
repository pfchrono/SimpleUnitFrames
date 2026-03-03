---SafeReload System: Prevent "addon action forbidden" errors during combat
---When ReloadUI is called during combat, automatically defers until PLAYER_REGEN_ENABLED
---Provides user-friendly feedback via popup notification

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

---Safely reload UI, deferring if in combat lockdown
---If in combat: queues reload for PLAYER_REGEN_ENABLED event (no error)
---If not in combat: reloads immediately
---@return void
function addon:SafeReload()
	-- In combat lockdown? Queue for after combat
	if InCombatLockdown() then
		addon:QueueOrRun(function()
			ReloadUI()
		end, {
			key = "SafeReload",
			type = "UI_RELOAD",
			priority = "NORMAL",
		})
		
		-- Notify user that reload is queued
		addon:EnsurePopupDialog("SUF_SAFERELOAD_QUEUED", {
			text = "You are in combat. UI will reload when combat ends.",
			button1 = "OK",
			timeout = 0,
			whileDead = false,
			hideOnEscape = true,
			preferredIndex = 3,
		})
		addon:ShowPopup("SUF_SAFERELOAD_QUEUED")
		return
	end
	
	-- Safe to reload now
	ReloadUI()
end

---Hook OptionsV2 Layout reload button to use SafeReload
---This is called automatically during module initialization
local function IntegrateSafeReloadWithOptions()
	if not addon.IsOptionsV2Enabled or not addon:IsOptionsV2Enabled() then
		return
	end
	
	-- Note: OptionsV2/Layout.lua already checks for addon.SafeReload
	-- If it exists, calls addon:SafeReload() instead of ReloadUI()
	-- See: Modules/UI/OptionsV2/Layout.lua around line 163
end

if type(addon.RegisterModuleInitializer) == "function" then
	addon:RegisterModuleInitializer("SafeReload", IntegrateSafeReloadWithOptions)
else
	IntegrateSafeReloadWithOptions()
end
