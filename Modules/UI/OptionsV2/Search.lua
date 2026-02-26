local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

function addon:BuildOptionsV2SearchIndex()
	local pages = self:GetOptionsV2Pages() or {}
	local index = {}
	for i = 1, #pages do
		local page = pages[i]
		local pageTokens = {
			tostring(page.label or ""),
			tostring(page.group or ""),
			tostring(page.desc or ""),
			tostring(page.key or ""),
		}
		local spec = self.GetOptionsV2PageSpec and self:GetOptionsV2PageSpec(page.key) or nil
		local sections = nil
		if type(spec) == "table" then
			local tabs = spec.sectionTabs
			if type(tabs) == "table" then
				for ti = 1, #tabs do
					local tab = tabs[ti]
					if type(tab) == "table" then
						pageTokens[#pageTokens + 1] = tostring(tab.label or "")
						pageTokens[#pageTokens + 1] = tostring(tab.key or "")
					end
				end
			end
			sections = spec.sections
			if type(sections) == "table" then
				for si = 1, #sections do
					local section = sections[si]
					if type(section) == "table" then
						pageTokens[#pageTokens + 1] = tostring(section.title or "")
						pageTokens[#pageTokens + 1] = tostring(section.desc or "")
						local controls = section.controls
						if type(controls) == "table" then
							for ci = 1, #controls do
								local control = controls[ci]
								if type(control) == "table" then
									pageTokens[#pageTokens + 1] = tostring(control.label or "")
									pageTokens[#pageTokens + 1] = tostring(control.help or "")
									pageTokens[#pageTokens + 1] = tostring(control.text or "")
									if type(control.getText) == "function" then
										local ok, dynamicText = pcall(control.getText)
										if ok and dynamicText then
											pageTokens[#pageTokens + 1] = tostring(dynamicText)
										end
									end
								end
							end
						end
					end
				end
			end
		end
		local haystack = string.lower(table.concat(pageTokens, " "))
		index[#index + 1] = {
			pageKey = page.key,
			sectionKey = nil,
			label = tostring(page.label or page.key),
			haystack = haystack,
		}

		if type(sections) == "table" then
			for si = 1, #sections do
				local section = sections[si]
				if type(section) == "table" then
					local sectionKey = tostring(section.tab or "all")
					local sectionTokens = {
						tostring(page.label or ""),
						tostring(page.group or ""),
						tostring(page.key or ""),
						tostring(section.title or ""),
						tostring(section.desc or ""),
						tostring(section.tab or ""),
					}
					local controls = section.controls
					if type(controls) == "table" then
						for ci = 1, #controls do
							local control = controls[ci]
							if type(control) == "table" then
								sectionTokens[#sectionTokens + 1] = tostring(control.label or "")
								sectionTokens[#sectionTokens + 1] = tostring(control.help or "")
								sectionTokens[#sectionTokens + 1] = tostring(control.text or "")
								if type(control.getText) == "function" then
									local ok, dynamicText = pcall(control.getText)
									if ok and dynamicText then
										sectionTokens[#sectionTokens + 1] = tostring(dynamicText)
									end
								end
							end
						end
					end
					index[#index + 1] = {
						pageKey = page.key,
						sectionKey = sectionKey,
						label = ("%s / %s"):format(tostring(page.label or page.key), tostring(section.title or sectionKey)),
						haystack = string.lower(table.concat(sectionTokens, " ")),
					}
				end
			end
		end
	end

	local dedup = {}
	local compact = {}
	for i = 1, #index do
		local row = index[i]
		local key = tostring(row.pageKey or "") .. "||" .. tostring(row.sectionKey or "")
		if not dedup[key] then
			dedup[key] = true
			compact[#compact + 1] = row
		end
	end
	self._optionsV2SearchIndex = compact
	return compact
end

function addon:SearchOptionsV2(text)
	local query = string.lower((text or ""):match("^%s*(.-)%s*$"))
	if query == "" then
		return {}
	end
	local index = self:BuildOptionsV2SearchIndex()
	local results = {}
	for i = 1, #index do
		local row = index[i]
		if row.haystack and row.haystack:find(query, 1, true) then
			local label = string.lower(tostring(row.label or ""))
			local pageKey = string.lower(tostring(row.pageKey or ""))
			local sectionKey = string.lower(tostring(row.sectionKey or ""))
			local rank = 50
			if label == query or pageKey == query or sectionKey == query then
				rank = 1
			elseif label:sub(1, #query) == query then
				rank = 2
			elseif pageKey:sub(1, #query) == query or sectionKey:sub(1, #query) == query then
				rank = 3
			elseif label:find(query, 1, true) then
				rank = 4
			else
				rank = 5
			end
			results[#results + 1] = {
				pageKey = row.pageKey,
				sectionKey = row.sectionKey,
				label = row.label,
				haystack = row.haystack,
				_rank = rank,
			}
		end
	end
	table.sort(results, function(a, b)
		if a._rank ~= b._rank then
			return a._rank < b._rank
		end
		local al = string.lower(tostring(a.label or ""))
		local bl = string.lower(tostring(b.label or ""))
		if al ~= bl then
			return al < bl
		end
		local ak = tostring(a.pageKey or "") .. "|" .. tostring(a.sectionKey or "")
		local bk = tostring(b.pageKey or "") .. "|" .. tostring(b.sectionKey or "")
		return ak < bk
	end)
	for i = 1, #results do
		results[i]._rank = nil
	end
	return results
end
