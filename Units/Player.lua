---Player unit frame spawner and initialization
---@class PlayerUnitBuilder
---Unit builder for player unit frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register player unit frame builder
---@param self SimpleUnitFrames Addon instance
---@return void
registry.player = function(self)
	local oUF = self.oUF
	---@type Frame Player unit frame reference
	local player = oUF:Spawn("player", "SUF_Player")
	self:HookAnchor(player, "PlayerFrame")

	-- Phase 3.4: Apply reusable mixins for fading, dragging, theming
	if player and self.GetUnitSettings then
		local unitSettings = self:GetUnitSettings("player")
		if unitSettings then
			Mixin(player, FrameFaderMixin, DraggableMixin, ThemeMixin)
			local db = self.db and self.db.profile and self.db.profile.positions or {}
			if player.InitFader and unitSettings.fader then
				player:InitFader(unitSettings.fader)
			end
			if player.InitDraggable and unitSettings.draggable then
				player:InitDraggable(db, "Frame_player", unitSettings.draggable)
			end
			if player.InitTheme and unitSettings.theme then
				player:InitTheme(unitSettings.theme)
			end
		end
	end
end
