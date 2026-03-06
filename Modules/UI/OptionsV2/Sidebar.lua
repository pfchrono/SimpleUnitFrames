-- OptionsV2 Sidebar UI Component
-- Vertical sidebar navigation for tab/subtab hierarchies
-- Based on QUI pattern: expand/collapse tabs, sticky bottom items

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

local OptionsV2 = addon.OptionsV2 or {}
addon.OptionsV2 = OptionsV2

-- Sidebar constants
OptionsV2.SIDEBAR_WIDTH = 200
OptionsV2.ROW_HEIGHT = 26
OptionsV2.SUBTAB_HEIGHT = 22
OptionsV2.SECTION_HEIGHT = 20
OptionsV2.ANIM_DURATION = 0.16

-- Create vertical sidebar frame
function OptionsV2:CreateSidebar(parent)
    if not parent then return nil end
    
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetWidth(self.SIDEBAR_WIDTH)
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -30)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 10)
    sidebar:EnableMouse(false)  -- Allow clicks to pass to children
    
    local style = addon:GetOptionsV2Style()
    if addon.ApplySUFBackdropColors then
        addon:ApplySUFBackdropColors(sidebar, style.panelBg, style.panelBorder, true)
    end
    
    -- Scroll frame for tabs
    local scroll = CreateFrame("ScrollFrame", nil, sidebar, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -8)
    scroll:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -28, -8)
    scroll:SetPoint("BOTTOM", sidebar, "BOTTOM", 0, 42)  -- Reserve space for bottom items
    scroll:EnableMouseWheel(true)
    scroll:EnableMouse(false)  -- Allow clicks to pass to scroll child
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(self.SIDEBAR_WIDTH - 40, 1)  -- Width must fit buttons
    content:EnableMouse(false)  -- Allow clicks to pass through to children
    scroll:SetScrollChild(content)
    
    sidebar.scroll = scroll
    sidebar.content = content
    sidebar.tabButtons = {}
    sidebar.expandedTabs = {}
    
    -- Apply scroll bar styling
    if scroll.ScrollBar then
        local thumb = scroll.ScrollBar:GetThumbTexture()
        if thumb and addon.ApplySUFBackdropColors then
            addon:ApplySUFBackdropColors(scroll.ScrollBar, style.navDefault, style.navDefaultBorder, true)
        end
    end
    
    return sidebar
end

-- Add tab button to sidebar
function OptionsV2:AddSidebarTab(sidebar, tabIndex, tabName, onSelect, onCaretClick)
    if not sidebar or not tabIndex or not tabName then return nil end
    
    local style = addon:GetOptionsV2Style()
    local button = CreateFrame("Button", nil, sidebar.content, "BackdropTemplate")
    button:SetSize(self.SIDEBAR_WIDTH - 20, self.ROW_HEIGHT)
    button._tabIndex = tabIndex
    button._tabName = tabName
    button._isExpanded = false
    button._isSelected = false
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    
    -- Button styling
    if addon.ApplySUFBackdropColors then
        addon:ApplySUFBackdropColors(button, style.navDefault, style.navDefaultBorder, true)
    end
    
    -- Button text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
    button.text:SetPoint("LEFT", 12, 0)
    button.text:SetText(tabName)
    
    -- Expand indicator (caret) - FontString for display only
    button.caret = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.caret:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    button.caret:SetText(">")
    button.caret:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
    
    -- Click handler - just call the callback, don't manipulate expansion state here
    -- The callback determines the behavior (expand/collapse for headers, navigate for pages)
    button:SetScript("OnClick", function(self)
        -- Check if caret click (right side of button)
        local mouseX = GetCursorPosition() / self:GetEffectiveScale()
        local buttonRight = self:GetRight()
        if onCaretClick and mouseX > (buttonRight - 20) then
            onCaretClick()
        elseif onSelect then
            onSelect()
        end
    end)
    
    -- Hover effects
    button:SetScript("OnEnter", function(self)
        if not addon.ApplySUFBackdropColors then
            return
        end
        local currentStyle = addon:GetOptionsV2Style()
        if self._isSelected then
            addon:ApplySUFBackdropColors(self, currentStyle.navSelected, currentStyle.navSelectedBorder, true)
        else
            addon:ApplySUFBackdropColors(self, currentStyle.navHover, currentStyle.navHoverBorder, true)
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        if not addon.ApplySUFBackdropColors then
            return
        end
        local currentStyle = addon:GetOptionsV2Style()
        if self._isSelected then
            addon:ApplySUFBackdropColors(self, currentStyle.navSelected, currentStyle.navSelectedBorder, true)
        else
            addon:ApplySUFBackdropColors(self, currentStyle.navDefault, currentStyle.navDefaultBorder, true)
        end
    end)
    
    table.insert(sidebar.tabButtons, button)
    return button
end

-- Update sidebar layout (reposition all tabs/subtabs)
function OptionsV2:UpdateSidebarLayout(sidebar)
    if not sidebar or not sidebar.content then return end
    
    local y = -4
    for i, tabButton in ipairs(sidebar.tabButtons) do
        -- Show all buttons for now (visibility controlled by creation in RebuildNav)
        tabButton:Show()
        tabButton:ClearAllPoints()
        tabButton:SetPoint("TOPLEFT", sidebar.content, "TOPLEFT", 0, y)
        tabButton:SetPoint("TOPRIGHT", sidebar.content, "TOPRIGHT", -1, y)
        tabButton:SetFrameLevel(sidebar.content:GetFrameLevel() + 1)
        y = y - self.ROW_HEIGHT - 2
    end
    
    local contentHeight = math.abs(y) + 8
    sidebar.content:SetSize(self.SIDEBAR_WIDTH - 40, contentHeight)
end

-- Set active tab (highlight it)
function OptionsV2:SetActiveSidebarTab(sidebar, tabIndex)
    if not sidebar then return end
    
    local style = addon:GetOptionsV2Style()
    for _, button in ipairs(sidebar.tabButtons) do
        if button._tabIndex == tabIndex then
            sidebar._currentTabButton = button
            button._isSelected = true
            button.text:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
            if addon.ApplySUFBackdropColors then
                addon:ApplySUFBackdropColors(button, style.navSelected, style.navSelectedBorder, true)
            end
        else
            button._isSelected = false
            button.text:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
            if addon.ApplySUFBackdropColors then
                addon:ApplySUFBackdropColors(button, style.navDefault, style.navDefaultBorder, true)
            end
        end
    end
end

return OptionsV2
