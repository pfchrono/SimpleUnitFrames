--- ProfileMigrator.lua
-- Handles profile schema migrations and backwards compatibility
-- Ensures user profiles remain valid across addon updates with schema changes

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon:GetAddon("SimpleUnitFrames", true)

-- Ensure addon is available; fail gracefully if load order is early.
if not addon then
	return
end

-- Migration registry: maps from version → migration function
-- Each migration function receives (addon, profile, fromVersion) and modifies profile in-place
local migrations = {}

-- Current profile schema version - increment when making breaking changes
local CURRENT_SCHEMA_VERSION = 3

--- Register a profile migration for a specific schema change
-- @param fromVersion number - Migrate from this version
-- @param toVersion number - Migrate to this version
-- @param migrationFunc function(addon, profile, fromVersion) - Performs the migration
function addon:RegisterProfileMigration(fromVersion, toVersion, migrationFunc)
	if not migrations[fromVersion] then
		migrations[fromVersion] = {}
	end
	migrations[fromVersion][toVersion] = migrationFunc
	-- Note: Can't log here because db doesn't exist yet during module load
end

--- Run all necessary migrations to bring profile from old version to current
-- @param profile table - Profile to migrate
-- @param fromVersion number - Starting version
-- @return boolean - True if migration successful, false if rolled back to defaults
function addon:RunProfileMigrations(profile, fromVersion)
	if not fromVersion then
		fromVersion = 0
	end

	if fromVersion == CURRENT_SCHEMA_VERSION then
		-- Already current, no migration needed
		return true
	end

	if fromVersion > CURRENT_SCHEMA_VERSION then
		-- Profile is from a newer version - might be downgrading
		self:DebugLog("ProfileMigration", string.format(
			"Profile version %d is newer than addon schema %d (possible downgrade)",
			fromVersion, CURRENT_SCHEMA_VERSION
		), 1)
		-- Safe approach: reset to current, user can re-configure
		return false
	end

	-- Run migration chain from fromVersion to CURRENT_SCHEMA_VERSION
	local currentVersion = fromVersion
	while currentVersion < CURRENT_SCHEMA_VERSION do
		local nextVersion = currentVersion + 1
		if not migrations[currentVersion] or not migrations[currentVersion][nextVersion] then
			-- No migration path defined - skip this step
			self:DebugLog("ProfileMigration", string.format(
				"No migration path from v%d to v%d, skipping",
				currentVersion, nextVersion
			), 2)
			currentVersion = nextVersion
		else
			-- Execute migration
			local migrationFunc = migrations[currentVersion][nextVersion]
			local success, err = pcall(migrationFunc, self, profile, currentVersion)
			if not success then
				self:DebugLog("ProfileMigration", string.format(
					"Migration v%d -> v%d failed: %s",
					currentVersion, nextVersion, tostring(err)
				), 1)
				-- Migration failed - rollback to defaults
				return false
			end
			self:DebugLog("ProfileMigration", string.format(
				"Migrated profile from v%d to v%d",
				currentVersion, nextVersion
			), 2)
			currentVersion = nextVersion
		end
	end

	-- Set final schema version
	profile._schemaVersion = CURRENT_SCHEMA_VERSION
	self:DebugLog("ProfileMigration", string.format(
		"Profile migration complete: now at schema v%d",
		CURRENT_SCHEMA_VERSION
	), 2)
	return true
end

--- Ensure profile has all required top-level tables
-- Safely adds missing tables without overwriting existing data
-- @param profile table - Profile to validate
-- @param defaults table - Defaults table to reference
function addon:EnsureProfileDefaults(profile, defaults)
	if not profile then
		return false
	end

	-- Ensure units table and all unit types exist
	if not profile.units then
		profile.units = {}
	end
	for unitType, unitDefaults in pairs(defaults.profile.units or {}) do
		if not profile.units[unitType] then
			profile.units[unitType] = CopyTableDeep(unitDefaults)
		end
	end

	-- Ensure media table exists
	if not profile.media then
		profile.media = {}
	end
	for key, value in pairs(defaults.profile.media or {}) do
		if profile.media[key] == nil then
			profile.media[key] = value
		end
	end

	-- Ensure optionsUI table exists
	if not profile.optionsUI then
		profile.optionsUI = {}
	end
	for key, value in pairs(defaults.profile.optionsUI or {}) do
		if profile.optionsUI[key] == nil then
			profile.optionsUI[key] = value
		end
	end

	-- Ensure other tables exist
	if not profile.sizes then
		profile.sizes = {}
	end
	if not profile.movers then
		profile.movers = {}
	end
	if not profile.castbar then
		profile.castbar = {}
	end
	if not profile.plugins then
		profile.plugins = {}
	end
	if not profile.performance then
		profile.performance = {}
	end
	if not profile.indicators then
		profile.indicators = {}
	end
	if not profile.minimap then
		profile.minimap = {}
	end
	if not profile.enhancements then
		profile.enhancements = {}
	end
	if not profile.debug then
		profile.debug = {}
	end
	if not profile.customTrackers then
		profile.customTrackers = {}
	end
	if not profile.party then
		profile.party = {}
	end

	return true
end

--- Check profile integrity and repair if necessary
-- @param profile table - Profile to validate
-- @param defaults table - Defaults to validate against
-- @return boolean - True if profile valid/repaired, false if rollback needed
function addon:ValidateProfileIntegrity(profile, defaults)
	if not profile then
		return false
	end

	local issues = {}

	-- Check for obvious data corruption
	if type(profile.units) ~= "table" then
		table.insert(issues, "units table corrupted")
		profile.units = {}
	end

	if type(profile.media) ~= "table" then
		table.insert(issues, "media table corrupted")
		profile.media = {}
	end

	if type(profile.movers) ~= "table" then
		table.insert(issues, "movers table corrupted")
		profile.movers = {}
	end

	-- Check that each unit type has required structure
	for unitType, unitConfig in pairs(profile.units or {}) do
		if type(unitConfig) ~= "table" then
			table.insert(issues, string.format("unit config for %s corrupted", unitType))
			profile.units[unitType] = CopyTableDeep(defaults.profile.units[unitType] or {})
		end
	end

	-- Log any issues found
	if #issues > 0 then
		self:DebugLog("ProfileMigration", string.format(
			"Profile integrity issues detected: %s (auto-repaired)",
			table.concat(issues, ", ")
		), 2)
	end

	return true
end

--- Initialize profile migration system and check for needed migrations
-- Called during OnInitialize after profile is loaded
function addon:InitializeProfileMigration()
	-- Get current profile's schema version (default to 0 for legacy profiles)
	local schemaVersion = self.db.profile._schemaVersion or 0

	-- Run migrations if needed
	if schemaVersion < CURRENT_SCHEMA_VERSION then
		self:DebugLog("ProfileMigration", string.format(
			"Profile schema out of date (v%d, expected v%d), running migrations...",
			schemaVersion, CURRENT_SCHEMA_VERSION
		), 2)

		-- Attempt migration
		local migrationSuccess = self:RunProfileMigrations(self.db.profile, schemaVersion)

		if not migrationSuccess then
			self:DebugLog("ProfileMigration", 
				"Profile migration failed or profile too old. Restoring defaults while preserving movers.",
				1)
			-- Preserve movers from old profile (user's window positions)
			local savedMovers = CopyTableDeep(self.db.profile.movers or {})

			-- Reset to defaults
			self.db:ResetProfile()

			-- Restore movers if they existed
			if next(savedMovers) then
				self.db.profile.movers = savedMovers
				self:DebugLog("ProfileMigration", "Restored saved window positions.", 2)
			end
		end
	end

	-- Ensure all required fields exist
	self:EnsureProfileDefaults(self.db.profile, self.defaults)

	-- Validate profile integrity
	self:ValidateProfileIntegrity(self.db.profile, self.defaults)

	-- Set schema version to current
	self.db.profile._schemaVersion = CURRENT_SCHEMA_VERSION
end

-- Example migration from v0 to v1 (to be used when first schema change is made)
-- Uncomment and customize when needed:
--[[
addon:RegisterProfileMigration(0, 1, function(addon, profile, fromVersion)
	-- Example: profile.newField = profile.newField or defaultValue
	addon:DebugLog("ProfileMigration", "Applied v0->v1 migration: added new fields", 2)
end)
--]]

-- Migration v1 -> v2: Add castbar configuration for all units that support castbars
addon:RegisterProfileMigration(1, 2, function(addon, profile, fromVersion)
	local updated = false
	
	-- Add player castbar config if missing (uses BELOW_CLASSPOWER anchor)
	if profile.units and profile.units.player then
		if not profile.units.player.castbar then
			profile.units.player.castbar = {
				enabled = true,
				anchor = "BELOW_CLASSPOWER",
				gap = 8,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	-- Add target castbar config if missing
	if profile.units and profile.units.target then
		if not profile.units.target.castbar then
			profile.units.target.castbar = {
				enabled = true,
				anchor = "BELOW_FRAME",
				gap = 2,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	-- Add party castbar config if missing
	if profile.units and profile.units.party then
		if not profile.units.party.castbar then
			profile.units.party.castbar = {
				enabled = true,
				anchor = "ABOVE_FRAME",
				gap = 2,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	-- Add raid castbar config if missing
	if profile.units and profile.units.raid then
		if not profile.units.raid.castbar then
			profile.units.raid.castbar = {
				enabled = true,
				anchor = "ABOVE_FRAME",
				gap = 2,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	-- Add tot castbar config if missing
	if profile.units and profile.units.tot then
		if not profile.units.tot.castbar then
			profile.units.tot.castbar = {
				enabled = true,
				anchor = "BELOW_FRAME",
				gap = 2,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	-- Add focustarget castbar config if missing
	if profile.units and profile.units.focustarget then
		if not profile.units.focustarget.castbar then
			profile.units.focustarget.castbar = {
				enabled = true,
				anchor = "BELOW_FRAME",
				gap = 2,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	if updated then
		addon:DebugLog("ProfileMigration", "Applied v1->v2 migration: added castbar configuration for all castbar-capable units", 2)
	end
end)

-- Migration v2 -> v3: Add player and target castbar configuration (for profiles that already had v2 from earlier party/raid migration)
addon:RegisterProfileMigration(2, 3, function(addon, profile, fromVersion)
	local updated = false
	
	-- Add player castbar config if missing (uses BELOW_CLASSPOWER anchor)
	if profile.units and profile.units.player then
		if not profile.units.player.castbar then
			profile.units.player.castbar = {
				enabled = true,
				anchor = "BELOW_CLASSPOWER",
				gap = 8,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	-- Add target castbar config if missing
	if profile.units and profile.units.target then
		if not profile.units.target.castbar then
			profile.units.target.castbar = {
				enabled = true,
				anchor = "BELOW_FRAME",
				gap = 2,
				offsetY = 0,
			}
			updated = true
		end
	end
	
	if updated then
		addon:DebugLog("ProfileMigration", "Applied v2->v3 migration: added player/target castbar configuration", 2)
	end
end)

-- Export for testing
addon.ProfileMigrator = {
	GetSchemaVersion = function() return CURRENT_SCHEMA_VERSION end,
	GetRegisteredMigrations = function() return migrations end,
}
