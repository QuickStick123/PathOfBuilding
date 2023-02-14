if not table.containsId then
	dofile("Scripts/mods.lua")
end

LoadModule("../Data/Global.lua")

local t_insert = table.insert

local function extractRanges(modText)
	local modValues = { }
	modText = modText:gsub("([%-%+]?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", function(plus, min, max)
		min = (plus..min):gsub("%-%-", ""):gsub("%+", "")
		max = (plus..max):gsub("%-%-", ""):gsub("%+", "")
		local a = tonumber(min)
		local b = tonumber(max)
		if a < b then
			min = a
			max = b
		else
			min = b
			max = a
		end
		table.insert(modValues, {min, max})
		return "#"
	end)
	return modText, modValues
end

local function equalRanges(range1, range2)
	if range1 and range2 and #range1 == #range2 then
		for i, pair1 in ipairs(range1) do
			if range2[i][1] ~= pair1[1] or range2[i][2] ~= pair1[2] then
				return false
			end
		end
		return true
	end
	return false
end

local uniqueModData = LoadModule("../Data/Uniques/Special/Uniques.lua")
local modTextMap = LoadModule("../Data/Uniques/Special/ModTextMap.lua")

for _, name in pairs(ItemTypes) do
	local uniques = LoadModule("../Data/Uniques/"..name..".lua")
	local out = io.open("../Data/Uniques/Special/"..name..".lua", "w")
	for _, unique in ipairs(uniques) do
		local _, numVariants = string.gsub(unique, "Variant: ", "")
		local implicits = tonumber(string.match(unique, "Implicits: (%d+)")) or 0
		local implicitModLines = { }
		local explicitModLines = { }
		-- mods start after fields and or requirements / implicits:
		local lineNum = 1
		local lines = {}
		for line in unique:gmatch("[^\r\n]+") do
			lines[lineNum] = line
			lineNum = lineNum + 1
		end
		local modStartLineNum
		for i = #lines, 1, -1 do -- Find start of item mods
			local line = lines[i]
			if line:match(".+ Item") or line:match("Requires Level .+") or line:match("^[%a ]+: .+$") or i <= 2 then
				modStartLineNum = i + 1
				break
			end
		end
		for j = modStartLineNum, #lines do
			if implicits > 0 then
				t_insert(implicitModLines, lines[j])
				implicits = implicits - 1
			else
				t_insert(explicitModLines, lines[j])
			end
		end
		local variants = {}
		for i = 1, numVariants do
			variants[i] = { implicitModLines = { }, explicitModLines = { } }
			for i, line in ipairs(implicitModLines) do
				local variantLineNumbers = line:match("{variants:(.+)}")
				if not variantLineNumbers or variantLineNumbers:match(tostring(i)) then
					t_insert(variants[i].implicitModLines, line:gsub("{variants:.+}", ""))
				end
			end
			for i, line in ipairs(explicitModLines) do
				local variantLineNumbers = line:match("{variants:(.+)}")
				if not variantLineNumbers or variantLineNumbers:match(tostring(i)) then
					t_insert(variants[i].explicitModLines, line:gsub("{variants:.+}", ""))
				end
			end
		end

		ConPrintTable(variants)
		-- self.requirements.level = m_max(self.requirements.level or 0, m_floor(mod.level * 0.8))



		-- if line ~= "]],[[" then
		-- 	local specName, specVal = line:match("^([%a ]+): (.+)$")
		-- 	if line == "]],[[" then
		-- 		uniqueLines = nil
		-- 		implicits = 0
		-- 	end
		-- 	elseif uniqueLines == nil then
		-- 		uniqueLines = { name = line }
		-- 	else
		-- 		local variants = line:match("{[vV]ariant:([%d,.]+)}")
		-- 		local fractured = line:match("({fractured})") or ""
		-- 		local modText = line:gsub("{.+}", ""):gsub("{.+}", ""):gsub("[–᠆‐‑‒–﹘﹣－]", "-") -- Cleanup various hyphens.
		-- 		local rangedRemovedLine, ranges = extractRanges(modText)
		-- 		local uniqueLines
		-- 		local possibleRangeMods = modTextMap[rangedRemovedLine]
		-- 		local possibleMods
		-- 		for possibleModText, mod in pairs(possibleRangeMods) do
		-- 			if equalRanges(ranges, mod.ranges) then
		-- 				possibleMods = mod.modNames
		-- 				modText = possibleModText
		-- 			end
		-- 		end
		-- 		local gggMod
		-- 		if possibleMods then
		-- 			gggMod = possibleMods[1]
		-- 			for _, modName in ipairs(possibleMods) do
		-- 				if modName:lower():match(name) then
		-- 					gggMod = modName
		-- 				end
		-- 			end
		-- 			out:write(fractured)
		-- 			if variants then
		-- 				out:write("{variant:" .. variants:gsub("%.", ",") .. "}")
		-- 			end
		-- 			out:write(gggMod, "\n")
		-- 		else
		-- 			out:write(line, "\n")
		-- 		end
		-- 	end
		-- else
		-- 	out:write(line, "\n")
	end
	out:close()
end

print("Unique mods exported.")
