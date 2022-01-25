local GlobalAddonName, ExRT = ...

local localization = ExRT.L
local func_noexist = setmetatable({}, {__index = function (t, k)
	return k or "???"
end})
local func_noexist_debug = setmetatable({}, {__index = function (t, k)
	print("No "..(k or "???").." in locale")
	return k or "???"
end})

local main_localization

if ExRT.T ~= "D" then
	main_localization = setmetatable(localization, {__index=func_noexist})
else
	main_localization = setmetatable(localization, {__index=func_noexist_debug})
end

ExRT.L = setmetatable({}, {__index=main_localization})

--deDE
--enGB
--enUS
--esES
--esMX
--frFR
--itIT
--koKR
--ptBR
--ruRU
--zhCN
--zhTW