local GlobalAddonName, ExRT = ...

ExRT.V = 2567
ExRT.T = "R"

ExRT.OnUpdate = {}		--> таймеры, OnUpdate функции
ExRT.Slash = {}			--> функции вызова из коммандной строки
ExRT.OnAddonMessage = {}	--> внутренние сообщения аддона
ExRT.Eggs = {}			--> скрытые функции
ExRT.MiniMapMenu = {}		--> изменение меню кнопки на миникарте
ExRT.Modules = {}		--> список всех модулей
ExRT.ModulesLoaded = {}		--> список загруженных модулей [для Dev & Advanced]
ExRT.CLEU = {}			--> лист CLEU функций, для обработки

ExRT.msg_prefix = {
	["EXRTADD"] = true,
	["MHADD"] = true,	--> Malkorok Helper (Curse client)
}

ExRT.L = {}			--> локализация
ExRT.locale = GetLocale()

---------------> Modules <---------------

ExRT.mod = {}
ExRT.mod.__index = ExRT.mod

do
	local function mod_LoadOptions(this)
		if not InCombatLockdown() then
			this:Load()
			this:SetScript("OnShow",nil)
			ExRT.mds.dprint(this.moduleName.."'s options loaded")
		else
			print(ExRT.L.SetErrorInCombat)
		end
	end
	function ExRT.mod:New(moduleName,localizatedName,disableOptions)
		local self = {}
		setmetatable(self, ExRT.mod)
		
		if not disableOptions then
			self.options = CreateFrame("Frame", "ExRT"..moduleName.."Options", ExRT.Options.panel)
			self.options.name = localizatedName or moduleName
			self.options.parent = ExRT.Options.panel.name
			InterfaceOptions_AddCategory(self.options)
			self.options:Hide()
			self.options.moduleName = moduleName
			self.options:SetScript("OnShow",mod_LoadOptions)
		elseif disableOptions == 2 then
			function self:createOptions()
				self.options = CreateFrame("Frame", "ExRT"..moduleName.."Options", ExRT.Options.panel)
				self.options.name = localizatedName or moduleName
				self.options.parent = ExRT.Options.panel.name
				InterfaceOptions_AddCategory(self.options)
				self.options:Hide()
			end
		end
	
		self.main = CreateFrame("Frame", "ExRT"..moduleName)
		self.main.events = {}
		self.main:SetScript("OnEvent",ExRT.mod.Event)
		
		if ExRT.T == "D" then
			self.main.eventsCounter = {}
			self.main:HookScript("OnEvent",ExRT.mod.HookEvent)
		end
		
		self.db = {}
		
		self.name = moduleName
		table.insert(ExRT.Modules,self)
		_G["GExRT"..moduleName.."Global"] = self
		
		ExRT.mds.dprint("New module: "..moduleName)
		
		return self
	end
end

function ExRT.mod:Event(event,...)
	self[event](self,...)
end

function ExRT.mod:HookEvent(event)
	self.eventsCounter[event] = self.eventsCounter[event] and self.eventsCounter[event] + 1 or 1
end

function ExRT.mod:RegisterEvents(...)
	for i=1,select("#", ...) do
		local event = select(i,...)
		if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
			self.main:RegisterEvent(event)
		else
			ExRT.CLEU[ self.name ] = self.main.COMBAT_LOG_EVENT_UNFILTERED
		end
		self.main.events[event] = true
		ExRT.mds.dprint(self.name,'RegisterEvent',event)
	end
end

function ExRT.mod:UnregisterEvents(...)
	for i=1,select("#", ...) do
		local event = select(i,...)
		if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
			self.main:UnregisterEvent(event)
		else
			ExRT.CLEU[ self.name ] = nil
		end
		self.main.events[event] = nil
		ExRT.mds.dprint(self.name,'UnregisterEvent',event)
	end
end

function ExRT.mod:RegisterTimer()
	ExRT.OnUpdate[self.name] = self
end

function ExRT.mod:UnregisterTimer()
	ExRT.OnUpdate[self.name] = nil
end

function ExRT.mod:RegisterSlash()
	ExRT.Slash[self.name] = self
end

function ExRT.mod:UnregisterSlash()
	ExRT.Slash[self.name] = nil
end

function ExRT.mod:RegisterAddonMessage()
	ExRT.OnAddonMessage[self.name] = self
end

function ExRT.mod:UnregisterAddonMessage()
	ExRT.OnAddonMessage[self.name] = nil
end

function ExRT.mod:RegisterEgg()
	ExRT.Eggs[self.name] = self
end

function ExRT.mod:UnregisterEgg()
	ExRT.Eggs[self.name] = nil
end

function ExRT.mod:RegisterMiniMapMenu()
	ExRT.MiniMapMenu[self.name] = self
end

function ExRT.mod:UnregisterMiniMapMenu()
	ExRT.MiniMapMenu[self.name] = nil
end

do
	local hideOnPetBattle = {}
	local petBattleTracker = CreateFrame("Frame")
	petBattleTracker:SetScript("OnEvent",function (self, event)
		if event == "PET_BATTLE_OPENING_START" then
			for _,frame in pairs(hideOnPetBattle) do
				if frame:IsShown() then
					frame.petBattleHide = true
					frame:Hide()
				else
					frame.petBattleHide = nil
				end
			end
		else
			for _,frame in pairs(hideOnPetBattle) do
				if frame.petBattleHide then
					frame.petBattleHide = nil
					frame:Show()
				end
			end
		end
	end)
	petBattleTracker:RegisterEvent("PET_BATTLE_OPENING_START")
	petBattleTracker:RegisterEvent("PET_BATTLE_CLOSE")
	function ExRT.mod:RegisterHideOnPetBattle(frame)
		hideOnPetBattle[#hideOnPetBattle + 1] = frame
	end
end

-------------> upvalues <-------------

local GetTime, GetInstanceInfo, GetNumGroupMembers = GetTime, GetInstanceInfo, GetNumGroupMembers
local UnitName, UnitIsInMyGuild = UnitName, UnitIsInMyGuild
local IsEncounterInProgress = IsEncounterInProgress
local SendAddonMessage, pcall = SendAddonMessage, pcall
local select, floor, tonumber, tostring, string_sub, string_find, string_len, bit_band, print, type, unpack, pairs, format, strsplit = select, floor, tonumber, tostring, string.sub, string.find, string.len, bit.band, print, type, unpack, pairs, format, strsplit
local RAID_CLASS_COLORS, COMBATLOG_OBJECT_TYPE_MASK, COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_SPECIAL_MASK = RAID_CLASS_COLORS, COMBATLOG_OBJECT_TYPE_MASK, COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_SPECIAL_MASK

if ExRT.T == "D" then
	pcall = function(func,...)
		func(...)
	end
end

---------------> Mods <---------------

ExRT.mds = {}

do
	local antiSpamArr = {}
	function ExRT.mds.AntiSpam(numantispam,addtime)
		if not antiSpamArr[numantispam] or antiSpamArr[numantispam] < GetTime() then
			antiSpamArr[numantispam] = GetTime() + addtime
			return true
		else
			return false
		end
	end
	function ExRT.mds.ResetAntiSpam(numantispam)
		antiSpamArr[numantispam] = nil
	end
end

do
	local classColorArray = nil
	function ExRT.mds.classColor(class)
		classColorArray = RAID_CLASS_COLORS[class]
		if classColorArray and classColorArray.colorStr then
			return classColorArray.colorStr
		else
			return "ffbbbbbb"
		end
	end

	function ExRT.mds.classColorNum(class)
		classColorArray = RAID_CLASS_COLORS[class]
		if classColorArray then
			return classColorArray.r,classColorArray.g,classColorArray.b
		else
			return 0.8,0.8,0.8
		end
	end
	
	function ExRT.mds.classColorByGUID(guid)
		local class = ""
		if guid and guid ~= "" and guid ~= "0x0000000000000000" then
			class = select(2,GetPlayerInfoByGUID(guid))
		end
		return ExRT.mds.classColor(class)
	end
end

function ExRT.mds.clearTextTag(text,SpellLinksEnabled)
	if text then
		text = string.gsub(text,"|c........","")
		text = string.gsub(text,"|r","")
		text = string.gsub(text,"|T.-:0|t ","")
		text = string.gsub(text,"|HExRT:.-|h(.-)|h","%1")
		if SpellLinksEnabled then
			text = string.gsub(text,"|H(spell:.-)|h(.-)|h","|cff71d5ff|H%1|h[%2]|h|r")
		end
		return text
	end
end

function ExRT.mds.splitLongLine(text,maxLetters,SpellLinksEnabled)
	maxLetters = maxLetters or 250
	local result = {}
	repeat
		local lettersNow = maxLetters
		if SpellLinksEnabled then
			local lastC = 0
			local lastR = 0
			for i=1,(maxLetters-1) do
				local word = string.sub(text,i,i+1)
				if word == "|c" then
					lastC = i
				elseif word == "|r" then
					lastR = i
				end
			end
			if lastC > 0 and lastC > lastR then
				lettersNow = lastC - 1
			end
		end
		
		local utf8pos = 1
		local textLen = string.len(text)
		while true do
			local char = string.sub(text,utf8pos,utf8pos)
			local c = char:byte()
			
			local lastPos = utf8pos
			
			if c > 0 and c <= 127 then
				utf8pos = utf8pos + 1
			elseif c >= 194 and c <= 223 then
				utf8pos = utf8pos + 2
			elseif c >= 224 and c <= 239 then
				utf8pos = utf8pos + 3
			elseif c >= 240 and c <= 244 then
				utf8pos = utf8pos + 4
			else
				utf8pos = utf8pos + 1
			end
			
			if utf8pos > lettersNow then
				lettersNow = lastPos - 1
				break
			elseif utf8pos >= textLen then
				break
			end		
		end		
		result[#result + 1] = string.sub(text,1,lettersNow)
		text = string.sub(text,lettersNow+1)
	until string.len(text) < maxLetters
	if string.len(text) > 0 then
		result[#result + 1] = text
	end
	return unpack(result)
end

function ExRT.mds:SetScaleFix(scale)
	local l = self:GetLeft()
	local t = self:GetTop()
	local s = self:GetScale()
	if not l or not t or not s then return end

	s = scale / s

	self:SetScale(scale)
	local f = self:GetScript("OnDragStop")

	self:ClearAllPoints()
	self:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",l / s,t / s)

	if f then f(self) end
end

function ExRT.mds:GetCursorPos()
	local x_f,y_f = GetCursorPosition()
	local s = self:GetEffectiveScale()
	x_f, y_f = x_f/s, y_f/s
	local x,y = self:GetLeft(),self:GetTop()
	x = x_f-x
	y = (y_f-y)*(-1)
	return x,y
end

function ExRT.mds:LockMove(isLocked,touchTexture,dontTouchMouse)
	if isLocked then
		if touchTexture then touchTexture:SetTexture(0,0,0,0.3) end
		self:SetMovable(true)
		if not dontTouchMouse then self:EnableMouse(true) end
	else
		if touchTexture then touchTexture:SetTexture(0,0,0,0) end
		self:SetMovable(false)
		if not dontTouchMouse then self:EnableMouse(false) end
	end
end

do
	local function HiddenDropDown()
		if _G["DropDownList1"] and not _G["DropDownList1"]:IsShown() then 
			ExRT.mds.dropDownBlizzFix = nil 
		end 
	end
	function ExRT.mds.FixDropDown(width)
		ExRT.mds.dropDownBlizzFix = width
		ExRT.mds.ScheduleTimer(HiddenDropDown, 0.1)
	end
end

function ExRT.mds.GetRaidDiffMaxGroup()
	local _,_,difficulty = GetInstanceInfo()
	if difficulty == 8 or difficulty == 1 or difficulty == 2 then
		return 1
	elseif difficulty == 3 or difficulty == 5 then
		return 2
	elseif difficulty == 9 then
		return 8
	else
		return 5
	end	
end

function ExRT.mds.GetDifficultyForCooldownReset()
	local _,_,difficulty = GetInstanceInfo()
	if difficulty == 3 or difficulty == 4 or difficulty == 5 or difficulty == 6 or difficulty == 7 or difficulty == 14 or difficulty == 15 or difficulty == 16 then
		return true
	end
	return false
end

function ExRT.mds.Round(i)
	return floor(i+0.5)
end

function ExRT.mds.NumberInRange(i,mi,mx,incMi,incMx)
	if i and ((incMi and i >= mi) or (not incMi and i > mi)) and ((incMx and i <= mx) or (not incMx and i < mx)) then
		return true
	end
end

function ExRT.mds.delUnitNameServer(unitName)
	if string_find(unitName,"%-") then 
		unitName = string_sub(unitName,1,string_find(unitName,"%-")-1) 
	end
	return unitName
end

function ExRT.mds.UnitCombatlogname(unit)
	local name,server = UnitName(unit or "?")
	if name and server and server~="" then
		name = name .. "-" .. server
	end
	return name
end

function ExRT.mds.GetUnitTypeByGUID(guid)
	if guid then
		local b = tonumber(string_sub(guid,5,5), 16)
		if b then
			b = b % 8
			return b 
			--[0]="player", [3]="NPC", [4]="pet", [5]="vehicle"
		end
	end
end

function ExRT.mds.UnitIsPlayerOrPet(guid)
	local id = ExRT.mds.GetUnitTypeByGUID(guid)
	if id == 0 or id == 4 then
		return true
	end
end

function ExRT.mds.GetUnitInfoByUnitFlag(unitFlag,infoType)
	--> TYPE
	if infoType == 1 then
		return bit_band(unitFlag,COMBATLOG_OBJECT_TYPE_MASK)
		--[1024]="player", [2048]="NPC", [4096]="pet", [8192]="GUARDIAN", [16384]="OBJECT"
		
	--> CONTROL
	elseif infoType == 2 then
		return bit_band(unitFlag,COMBATLOG_OBJECT_CONTROL_MASK)
		--[256]="by players", [512]="by NPC",
		
	--> REACTION
	elseif infoType == 3 then
		return bit_band(unitFlag,COMBATLOG_OBJECT_REACTION_MASK)
		--[16]="FRIENDLY", [32]="NEUTRAL", [64]="HOSTILE"
		
	--> Controller affiliation
	elseif infoType == 4 then
		return bit_band(unitFlag,COMBATLOG_OBJECT_AFFILIATION_MASK)
		--[1]="player", [2]="PARTY", [4]="RAID", [8]="OUTSIDER"
		
	--> Special
	elseif infoType == 5 then
		return bit_band(unitFlag,COMBATLOG_OBJECT_SPECIAL_MASK)
		--Not all !  [65536]="TARGET", [131072]="FOCUS", [262144]="MAINTANK", [524288]="MAINASSIST"
	end
end

function ExRT.mds.UnitIsFriendlyByUnitFlag(unitFlag)
	if ExRT.mds.GetUnitInfoByUnitFlag(unitFlag,2) == 256 then
		return true
	end
end

function ExRT.mds.dprint(...)
	if ExRT.T == "D" then
		print(...)
	end
end

function ExRT.mds.LinkSpell(SpellID,SpellLink)
	if not SpellLink then
		SpellLink = GetSpellLink(SpellID)
	end
	if SpellLink then
		if ChatEdit_GetActiveWindow() then
			ChatEdit_InsertLink(SpellLink)
		else
			ChatFrame_OpenChat(SpellLink)
		end
	end
end

function ExRT.mds.LinkItem(itemID, itemLink)
	if not itemLink then
		if not itemID then 
			return 
		end
		itemLink = select(2,GetItemInfo(itemID))
	end
	if IsModifiedClick("DRESSUP") then
		if itemLink then
			return DressUpItemLink(itemLink)
		end
	else
		if itemLink then
			if ChatEdit_GetActiveWindow() then
				ChatEdit_InsertLink(itemLink)
			else
				ChatFrame_OpenChat(itemLink)
			end
		end
	end
end

function ExRT.mds.shortNumber(num)
	if num < 1000 then
		return tostring(num)
	elseif num < 1000000 then
		return format("%.1fk",num/1000)
	elseif num < 1000000000 then
		return format("%.2fm",num/1000000)
	else
		return format("%.3fM",num/1000000000)
	end
end

function ExRT.mds.classIconInText(class,size)
	if CLASS_ICON_TCOORDS[class] then
		size = size or 0
		return "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:"..size..":"..size..":0:0:256:256:".. floor(CLASS_ICON_TCOORDS[class][1]*256) ..":"..floor(CLASS_ICON_TCOORDS[class][2]*256) ..":"..floor(CLASS_ICON_TCOORDS[class][3]*256) ..":"..floor(CLASS_ICON_TCOORDS[class][4]*256) .."|t"
	end
end

function ExRT.mds.GUIDtoID(guid)
	if not guid then 
		return 0 
	else
		return tonumber(string_sub(guid, 6, 10), 16)
	end
end

function ExRT.mds.reverseInt(int,mx,doReverse)
	if doReverse then
		int = mx - int
	end
	return int
end

function ExRT.mds.table_copy(table1,table2)
	table.wipe(table2)
	for key,val in pairs(table1) do
		table2[key] = val
	end
end

function ExRT.mds.table_wipe(arr)
	if not arr or type(arr) ~= "table" then
		return
	end
	for key,val in pairs(arr) do
		if type(val) == "table" then
			ExRT.mds.table_wipe(val)
		end
		arr[key] = nil
	end
end

function ExRT.mds.table_find(arr,subj,pos)
	if pos then
		for j=1,#arr do
			if arr[j][pos] == subj then
				return j
			end
		end
	else
		for j=1,#arr do
			if arr[j] == subj then
				return j
			end
		end
	end
end

function ExRT.mds.table_len(arr)
	local len = 0
	for _ in pairs(arr) do
		len = len + 1
	end
	return len
end

do
	local hexData = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
	function ExRT.mds.tohex(num,size)
		num = tonumber(num)
		if not num then
			return
		end
		num = max(num,0)
		num = floor(num+0.5)
		local result = ""
		while num > 0 do
			local rest = num % 16
			result = hexData[rest + 1] .. result
			num = (num - rest) / 16
		end
		if size and string_len(result) < size then
			while string_len(result) < size do
				result = "0"..result
			end
		end
		return result
	end
end

function ExRT.mds.chatType(toSay)
	local isInInstance = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
	local isInParty = IsInGroup()
	local isInRaid = IsInRaid()
	local playerName = nil
	local chat_type = (isInInstance and "INSTANCE_CHAT") or (isInRaid and "RAID") or (isInParty and "PARTY")
	if not chat_type and not toSay then
		chat_type = "WHISPER"
		playerName = UnitName("player") 
	elseif not chat_type then
		chat_type = "SAY"
	end
	return chat_type, playerName
end

do
	local ScheduleFrame = CreateFrame("Frame")
	ScheduleFrame.timers = {}
	
	function ExRT.mds.ScheduleTimer(func, delay, ...)
		if type(func) ~= "function" or not tonumber(delay) then
			return nil
		end

		local tmr = #ScheduleFrame.timers+1
		ScheduleFrame.timers[tmr] = ScheduleFrame:CreateAnimationGroup()
		ScheduleFrame.timers[tmr].timer = ScheduleFrame.timers[tmr]:CreateAnimation()
		ScheduleFrame.timers[tmr].timer:SetScript("OnFinished",function (self)
			if type(self.func) == "function" then
				self.func(unpack(self.args, 1, self.argsCount))
			end
		end)
		if delay < 0 then
			ScheduleFrame.timers[tmr]:SetLooping("REPEAT")
			delay = delay * (-1)
		else
			ScheduleFrame.timers[tmr]:SetLooping("NONE")
		end

		if delay < 0.01 then
			delay = 0.01
		end

		ScheduleFrame.timers[tmr].timer.args = {...}
		ScheduleFrame.timers[tmr].timer.argsCount = select("#", ...)
		ScheduleFrame.timers[tmr].timer.func = func

		ScheduleFrame.timers[tmr].timer:SetDuration(delay)

		ScheduleFrame.timers[tmr]:Play()
		return tmr
	end

	function ExRT.mds.CancelTimer(tmr)
		if not tmr or not ScheduleFrame.timers[tmr] then
			return nil
		end
		ScheduleFrame.timers[tmr]:Stop()
		ScheduleFrame.timers[tmr].timer = nil
	end
end

---------------> Data <---------------

ExRT.mds.defFont = "Interface\\AddOns\\ExRT\\media\\skurri.ttf"
ExRT.mds.barImg = "Interface\\AddOns\\ExRT\\media\\bar17.tga"
ExRT.mds.defBorder = "Interface\\AddOns\\ExRT\\media\\border.tga"
ExRT.mds.textureList = {
	"Interface\\AddOns\\ExRT\\media\\bar1.tga",
	"Interface\\AddOns\\ExRT\\media\\bar2.tga",
	"Interface\\AddOns\\ExRT\\media\\bar3.tga",
	"Interface\\AddOns\\ExRT\\media\\bar4.tga",
	"Interface\\AddOns\\ExRT\\media\\bar5.tga",
	"Interface\\AddOns\\ExRT\\media\\bar6.tga",
	"Interface\\AddOns\\ExRT\\media\\bar7.tga",
	"Interface\\AddOns\\ExRT\\media\\bar8.tga",
	"Interface\\AddOns\\ExRT\\media\\bar9.tga",
	"Interface\\AddOns\\ExRT\\media\\bar10.tga",
	"Interface\\AddOns\\ExRT\\media\\bar11.tga",
	"Interface\\AddOns\\ExRT\\media\\bar12.tga",
	"Interface\\AddOns\\ExRT\\media\\bar13.tga",
	"Interface\\AddOns\\ExRT\\media\\bar14.tga",
	"Interface\\AddOns\\ExRT\\media\\bar15.tga",
	"Interface\\AddOns\\ExRT\\media\\bar16.tga",
	"Interface\\AddOns\\ExRT\\media\\bar17.tga",
	"Interface\\AddOns\\ExRT\\media\\bar18.tga",
	"Interface\\AddOns\\ExRT\\media\\bar19.tga",
	"Interface\\AddOns\\ExRT\\media\\bar20.tga",
	"Interface\\AddOns\\ExRT\\media\\bar21.tga",
	"Interface\\AddOns\\ExRT\\media\\bar22.tga",
	"Interface\\AddOns\\ExRT\\media\\bar23.tga",
	"Interface\\AddOns\\ExRT\\media\\bar24.tga",
	"Interface\\AddOns\\ExRT\\media\\bar25.tga",
	"Interface\\AddOns\\ExRT\\media\\bar26.tga",
	"Interface\\AddOns\\ExRT\\media\\bar27.tga",
	"Interface\\AddOns\\ExRT\\media\\bar28.tga",
	"Interface\\AddOns\\ExRT\\media\\bar29.tga",
	"Interface\\AddOns\\ExRT\\media\\bar30.tga",
	"Interface\\AddOns\\ExRT\\media\\bar31.tga",
	"Interface\\AddOns\\ExRT\\media\\bar32.tga",
	"Interface\\AddOns\\ExRT\\media\\bar33.tga",
	[[Interface\TargetingFrame\UI-StatusBar]],
	[[Interface\PaperDollInfoFrame\UI-Character-Skills-Bar]],
	[[Interface\RaidFrame\Raid-Bar-Hp-Fill]],
}
ExRT.mds.fontList = {
	"Interface\\AddOns\\ExRT\\media\\skurri.ttf",
	"Fonts\\ARIALN.TTF",
	"Fonts\\FRIZQT__.TTF",
	"Fonts\\MORPHEUS.TTF",
	"Fonts\\NIM_____.ttf",
	"Fonts\\SKURRI.TTF",
	"Fonts\\FRIZQT___CYR.TTF",
	"Interface\\AddOns\\ExRT\\media\\TaurusNormal.ttf",
	"Interface\\AddOns\\ExRT\\media\\UbuntuMedium.ttf",
	"Interface\\AddOns\\ExRT\\media\\TelluralAlt.ttf",
	"Interface\\AddOns\\ExRT\\media\\Glametrix.otf",
	"Interface\\AddOns\\ExRT\\media\\FiraSansMedium.ttf",
	"Interface\\AddOns\\ExRT\\media\\alphapixels.ttf",
}

---------------> Slash <---------------

SlashCmdList["exrtSlash"] = function (arg)
	local argL = strlower(arg)
	if argL == "icon" then
		VExRT.Addon.IconMiniMapHide = not VExRT.Addon.IconMiniMapHide
		if not VExRT.Addon.IconMiniMapHide then 
			ExRT.MiniMapIcon:Show()
		else
			ExRT.MiniMapIcon:Hide()
		end
	elseif argL == "getver" then
		ExRT.mds.SendExMsg("needversion","")
	elseif argL == "getverg" then
		ExRT.mds.SendExMsg("needversiong","","GUILD")
	elseif argL == "set" then
		ExRT.Options:Open()
	elseif string.len(argL) == 0 then
		ExRT.Options:Open()
	else
		for _,mod in pairs(ExRT.Slash) do
			mod:slash(argL,arg)
		end
	end
end
SLASH_exrtSlash1 = "/exrt"
SLASH_exrtSlash2 = "/rt"
SLASH_exrtSlash3 = "/raidtools"
SLASH_exrtSlash4 = "/exorsusraidtools"
SLASH_exrtSlash5 = "/ert"

---------------> Chat links hook <---------------

do
	local chatLinkFormat = "|HExRT:%s:0|h|cffffff00[ExRT: %s]|r|h"
	local funcTable = {}
	local function createChatHook()
		local SetHyperlink = ItemRefTooltip.SetHyperlink
		function ItemRefTooltip:SetHyperlink(link, ...)
			local funcName = link:match("^ExRT:([^:]+):")
			if funcName then
				local func = funcTable[funcName]
				if not func then
					return
				end
				func()
			else
				SetHyperlink(self, link, ...)
			end
		end
	end

	function ExRT.mds.CreateChatLink(funcName,func,stringName)
		if createChatHook then createChatHook() createChatHook = nil end
		if not funcName or not stringName or type(func) ~= "function" then
			return ""
		end
		funcTable[funcName] = func
		return chatLinkFormat:format(funcName,stringName)
	end
end

---------------> Global addon frame <---------------

local reloadTimer = 0.1

ExRT.frame = CreateFrame("Frame")

ExRT.frame:SetScript("OnEvent",function (self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		local prefix, message, channel, sender = ...
		if prefix and ExRT.msg_prefix[prefix] and (channel=="RAID" or channel=="GUILD" or channel=="INSTANCE_CHAT" or channel=="PARTY" or (channel=="WHISPER" and (UnitIsInMyGuild(ExRT.mds.delUnitNameServer(sender)) or ExRT.mds.delUnitNameServer(sender) == UnitName("player")))) then
			ExRT.mds.GetExMsg(sender, strsplit("\t", message))
		end
	elseif event == "ADDON_LOADED" and ... == GlobalAddonName then
		VExRT = VExRT or {}
		VExRT.Addon = VExRT.Addon or {}
		VExRT.Addon.Timer = VExRT.Addon.Timer or 0.1
		reloadTimer = VExRT.Addon.Timer

		if VExRT.Addon.IconMiniMapLeft and VExRT.Addon.IconMiniMapTop then
			ExRT.MiniMapIcon:ClearAllPoints()
			ExRT.MiniMapIcon:SetPoint("CENTER", VExRT.Addon.IconMiniMapLeft, VExRT.Addon.IconMiniMapTop)
		end
		
		if VExRT.Addon.IconMiniMapHide then 
			ExRT.MiniMapIcon:Hide() 
		end

		for prefix,_ in pairs(ExRT.msg_prefix) do
			RegisterAddonMessagePrefix(prefix)
		end
		
		VExRT.Addon.Version = tonumber(VExRT.Addon.Version or "0")
		VExRT.Addon.PreVersion = VExRT.Addon.Version
		
		if VExRT.Addon.Version < 1920 then
			VExRT.ExCD1 = nil
			VExRT.BuffsWatcher = nil
			VExRT.DamageWatcher = nil
			VExRT.RaidKicks = nil
			VExRT.SwitchTime = nil
		end
		
		ExRT.mds.dprint("ADDON_LOADED event")
		ExRT.mds.dprint("MODULES FIND",#ExRT.Modules)
		for i=1,#ExRT.Modules do
			pcall(ExRT.Modules[i].main.ADDON_LOADED,self) 	-- BE CARE ABOUT IT
			ExRT.ModulesLoaded[i] = true
			
			ExRT.mds.dprint("ADDON_LOADED",i,ExRT.Modules[i].name)
		end

		VExRT.Addon.Version = ExRT.V
		
		ExRT.mds.ScheduleTimer(function()
			ExRT.frame:SetScript("OnUpdate", ExRT.frame.OnUpdate)
			ExRT.CLEUframe:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end,1)
		self:UnregisterEvent("ADDON_LOADED")

		return true
	end
end)

ExRT.CLEUframe = CreateFrame("Frame")
do
	local CLEU = ExRT.CLEU
	ExRT.CLEUframe:SetScript("OnEvent",function (self, event, ...)
		for _,func in pairs(CLEU) do
			func(self,...)
		end
	end)
	
	if ExRT.T == "D" then
		ExRT.CLEUframe.eventsCounter = 0
		ExRT.CLEUframe:HookScript("OnEvent",function(self) self.eventsCounter = self.eventsCounter + 1 end)
	end
end

do
	local encounterTime,isEncounter = 0,nil
	
	local frameElapsed = 0
	function ExRT.frame:OnUpdate(elapsed)
		frameElapsed = frameElapsed + elapsed
		if frameElapsed > reloadTimer then
			if not isEncounter and IsEncounterInProgress() then
				isEncounter = true
				encounterTime = GetTime()
			elseif isEncounter and not IsEncounterInProgress() then
				isEncounter = nil
			end
			
			for _,mod in pairs(ExRT.OnUpdate) do
				--pcall(mod.timer,self,self.tmr)	-- BE CARE ABOUT IT
				mod:timer(frameElapsed)
			end
			frameElapsed = 0
		end
	end
	
	function ExRT.mds.RaidInCombat()
		return isEncounter
	end
	
	function ExRT.mds.GetEncounterTime()
		if isEncounter then
			return GetTime() - encounterTime
		end
	end
end

function ExRT.mds.SendExMsg(prefix, msg, tochat, touser, addonPrefix)
	addonPrefix = addonPrefix or "EXRTADD"
	msg = msg or ""
	if tochat and not touser then
		SendAddonMessage(addonPrefix, prefix .. "\t" .. msg, tochat)
	elseif tochat and touser then
		SendAddonMessage(addonPrefix, prefix .. "\t" .. msg, tochat,touser)
	else
		local chat_type, playerName = ExRT.mds.chatType()
		SendAddonMessage(addonPrefix, prefix .. "\t" .. msg, chat_type, playerName)
	end
end

function ExRT.mds.GetExMsg(sender, prefix, ...)
	if prefix == "needversion" then
		ExRT.mds.SendExMsg("version", ExRT.V,"WHISPER",sender)
	elseif prefix == "needversiong" then
		ExRT.mds.SendExMsg("version", ExRT.V,"WHISPER",sender)
	elseif prefix == "version" then
		local msgver = ...
		print(sender..": "..msgver)
	end
	for _,mod in pairs(ExRT.OnAddonMessage) do
		mod:addonMessage(sender, prefix, ...)
	end
end

_G["GExRT"] = ExRT
ExRT.frame:RegisterEvent("CHAT_MSG_ADDON")
ExRT.frame:RegisterEvent("ADDON_LOADED") 