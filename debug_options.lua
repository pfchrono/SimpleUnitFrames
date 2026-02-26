-- Temporary debug file to diagnose Options GUI issue
-- Run in-game with: /run LoadAddOn("SimpleUnitFrames"); dofile("d:\\Games\\World of Warcraft\\_retail_\\Interface\\_Working\\SimpleUnitFrames\\debug_options.lua")

local SUF = LibStub("AceAddon-3.0"):GetAddon("SimpleUnitFrames")

print("=== Debugging SUF Options ===")
print("optionsFrame exists:", SUF.optionsFrame ~= nil)

if SUF.optionsFrame then
    print("Destroying cached frame...")
    SUF.optionsFrame:Hide()
    SUF.optionsFrame = nil
end

print("Opening fresh options...")
SUF:ShowOptions()

print("=== After ShowOptions ===")
print("optionsFrame exists:", SUF.optionsFrame ~= nil)
if SUF.optionsFrame then
    print("BuildTab function exists:", type(SUF.optionsFrame.BuildTab))
    print("currentTab:", SUF.optionsFrame.currentTab)
    print("RebuildSidebar exists:", type(SUF.optionsFrame.RebuildSidebar))
end
