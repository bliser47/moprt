local GlobalAddonName, ExRT = ...

local GetTime, UnitIsFriendlyByUnitFlag, UnitInRaid, UnitName, UnitGUID, UnitIsPlayerOrPet, string_sub, table_wipe, GetUnitInfoByUnitFlag, GetUnitTypeByGUID, AntiSpam, GUIDtoID = GetTime, ExRT.mds.UnitIsFriendlyByUnitFlag, UnitInRaid, UnitName, UnitGUID, ExRT.mds.UnitIsPlayerOrPet, string.sub, ExRT.mds.table_wipe, ExRT.mds.GetUnitInfoByUnitFlag, ExRT.mds.GetUnitTypeByGUID, ExRT.mds.AntiSpam, ExRT.mds.GUIDtoID
local wipe, pairs, tonumber = table.wipe, pairs, tonumber

local VExRT = nil

local module = ExRT.mod:New("BossWatcher",ExRT.L.BossWatcher)
module.db.guidsList = {}

module.db.globalFights = {}

module.db.encounterName = nil
module.db.encounterStart = 0
module.db.encounterStartGlobal = 0
module.db.encounterEnd = 0

module.db.fightData = {}
module.db.fightData.damage = {}
module.db.fightData.heal = {}
module.db.fightData.switch = {}
module.db.fightData.npc_cast = {}
module.db.fightData.players_cast = {}
module.db.fightData.interrupts = {}
module.db.fightData.dispels = {}
module.db.fightData.buffs = {}
module.db.fightData.dies = {}
module.db.fightData.overkill = {}
module.db.fightData.chat = {}
module.db.fightData.energy = {}
module.db.lastFightID = 0
module.db.timeFix = nil
local fightUV = nil

local heal_shields = {}

module.db.buffsFilters = {
[1] = {[-1]=ExRT.L.BossWatcherFilterOnlyBuffs,}, --> Only buffs
[2] = {[-1]=ExRT.L.BossWatcherFilterOnlyDebuffs,}, --> Only debuffs
[3] = {[-1]=ExRT.L.BossWatcherFilterBySpellID,}, --> By spellID
[4] = {[-1]=ExRT.L.BossWatcherFilterBySpellName,}, --> By spellName
[5] = {
	[-1]=ExRT.L.BossWatcherFilterTaunts,
	[-2]={62124,130793,17735,97827,56222,51399,49560,6795,355,115546,116189},
},
[6] = {
	[-1]=ExRT.L.BossWatcherFilterStun,
	[-2]={853,105593,91797,408,119381,89766,118345,46968,107570,5211,44572,119392,122057,113656,108200,108194,30283,118905,20549,119072,115750},
},
[7] = {
	[-1]=ExRT.L.BossWatcherFilterPersonal,
	[-2]={148467,31224,110788,55694,47585,31850,115610,122783,642,5277,118038,104773,115176,48707,1966,61336,120954,871,106922,30823,6229,22812,498},
},
[8] = {
	[-1]=ExRT.L.BossWatcherFilterRaidSaves,
	[-2]={145629,114192,114198,81782,108281,97463,31821,15286,115213,44203,64843,76577},
},
[9] = {
	[-1]=ExRT.L.BossWatcherFilterPotions,
	[-2]={105702,105697,105706,105701,105707,105698,125282},
},
[10] = {
	[-1]=ExRT.L.BossWatcherFilterPandaria,
	[-2]={148010,146194,146198,146200,137593,137596,137590,137288,137323,137326,137247,137331},
},
[11] = {
	[-1]=ExRT.L.BossWatcherFilterTier16,
	[-2]={143524,143460,143459,143198,143434,143023,143840,143564,143959,146022,144452,144351,144358,146594,144359,144364,145215,144574,144683,144684,144636,146822,147029,147068,146899,
		144467,144459,146325,144330,144089,143494,143638,143480,143882,143589,143594,143593,143536,142990,143919,142913,143385,144236,143856,144466,145987,145747,143442,143411,143445,
		143791,146589,142534,142532,142533,142671,142948,143337,143701,143735,145213,147235,147209,144762,148994,148983,144817,145171,145065,147324},
},
}
module.db.buffsFilterStatus = {}

module.db.raidIDs = {
	[604]=true, 	--wotlk
	[543]=true, 	--wotlk
	[535]=true, 	--wotlk
	[529]=true, 	--wotlk
	[527]=true, 	--wotlk
	[532]=true, 	--wotlk
	[531]=true, 	--wotlk
	[609]=true, 	--wotlk
	[718]=true,	--wotlk

	[752]=true,	--BH
	[754]=true,	--BD
	[758]=true,	--BoT
	[774]=true,	--TotFW
	[800]=true,	--FL

	[824]=true,	--DS
	[896]=true,	--MV
	[897]=true,	--HoF
	[886]=true,	--ToES
	[930]=true,	--ToT
	[953]=true,	--SoO
}

module.db.autoSegmentEvents = {"UNIT_SPELLCAST_SUCCEEDED","SPELL_AURA_REMOVED","SPELL_AURA_APPLIED","UNIT_DIED","CHAT_MSG_RAID_BOSS_EMOTE"}
module.db.autoSegmentEventsL = {
	["UNIT_SPELLCAST_SUCCEEDED"] = ExRT.L.BossWatcherSegmentEventsUSS,
	["SPELL_AURA_REMOVED"] = ExRT.L.BossWatcherSegmentEventsSAR,
	["SPELL_AURA_APPLIED"] = ExRT.L.BossWatcherSegmentEventsSAA,
	["UNIT_DIED"] = ExRT.L.BossWatcherSegmentEventsUD,
	["CHAT_MSG_RAID_BOSS_EMOTE"] = ExRT.L.BossWatcherSegmentEventsCMRBE,
}
module.db.autoSegments = {
	["UNIT_DIED"] = {},
	["SPELL_AURA_APPLIED"] = {},
	["SPELL_AURA_REMOVED"] = {},
	["UNIT_SPELLCAST_SUCCEEDED"] = {},
	["CHAT_MSG_RAID_BOSS_EMOTE"] = {},
}
module.db.segmentsLNames = {
	["UNIT_SPELLCAST_SUCCEEDED"] = ExRT.L.BossWatcherSegmentNamesUSS,
	["SPELL_AURA_REMOVED"] = ExRT.L.BossWatcherSegmentNamesSAR,
	["SPELL_AURA_APPLIED"] = ExRT.L.BossWatcherSegmentNamesSAA,
	["UNIT_DIED"] = ExRT.L.BossWatcherSegmentNamesUD,
	['ENCOUNTER_START'] = ExRT.L.BossWatcherSegmentNamesES,
	["SLASH"] = ExRT.L.BossWatcherSegmentNamesSC,
	["CHAT_MSG_RAID_BOSS_EMOTE"] = ExRT.L.BossWatcherSegmentNamesCMRBE,
}
module.db.registerOtherEvents = {}

module.db.guidsListFix = setmetatable({}, {__index = function (t, k)
	if k and module.db.guidsList[k] then
		return module.db.guidsList[k]
	else
		return ExRT.L.BossWatcherUnknown
	end
end})

module.db.raidTargets = {0x1,0x2,0x4,0x8,0x10,0x20,0x40,0x80}
module.db.energyLocale = {
	[0] = "|cff69ccf0"..ExRT.L.BossWatcherEnergyType0,
	[1] = "|cffedc294"..ExRT.L.BossWatcherEnergyType1,
	[2] = "|cffd1fa99"..ExRT.L.BossWatcherEnergyType2,
	[3] = "|cffffff8f"..ExRT.L.BossWatcherEnergyType3,
	[5] = "|cffeb4561"..ExRT.L.BossWatcherEnergyType5,
	[6] = "|cffeb4561"..ExRT.L.BossWatcherEnergyType6,
	[7] = "|cff9482c9"..ExRT.L.BossWatcherEnergyType7,
	[8] = "|cffffa330"..ExRT.L.BossWatcherEnergyType8,
	[9] = "|cffffb3e0"..ExRT.L.BossWatcherEnergyType9,
	[10] = "|cffffffff"..ExRT.L.BossWatcherEnergyType10,
	[12] = "|cff4DbB98"..ExRT.L.BossWatcherEnergyType12,
	[13] = "|cffd9d9d9"..ExRT.L.BossWatcherEnergyType13,
	[14] = "|cffeb4561"..ExRT.L.BossWatcherEnergyType14,
	[15] = "|cff9482c9"..ExRT.L.BossWatcherEnergyType15,
}

local function UpdateNewSegmentEvents()
	table.wipe(module.db.autoSegments.UNIT_DIED)
	table.wipe(module.db.autoSegments.SPELL_AURA_APPLIED)
	table.wipe(module.db.autoSegments.SPELL_AURA_REMOVED)
	table.wipe(module.db.autoSegments.UNIT_SPELLCAST_SUCCEEDED)
	table.wipe(module.db.autoSegments.CHAT_MSG_RAID_BOSS_EMOTE)
	table.wipe(module.db.registerOtherEvents)
	for i=1,10 do
		if VExRT.BossWatcher.autoSegments[i] and VExRT.BossWatcher.autoSegments[i][1] and VExRT.BossWatcher.autoSegments[i][2] then
			module.db.autoSegments[ VExRT.BossWatcher.autoSegments[i][2] ][ VExRT.BossWatcher.autoSegments[i][1] ] = true
			if VExRT.BossWatcher.autoSegments[i][2] == 'UNIT_SPELLCAST_SUCCEEDED' then
				module.db.registerOtherEvents['UNIT_SPELLCAST_SUCCEEDED'] = true
			end
			if VExRT.BossWatcher.autoSegments[i][2] == 'CHAT_MSG_RAID_BOSS_EMOTE' then
				module.db.registerOtherEvents['CHAT_MSG_RAID_BOSS_EMOTE'] = true
			end
		end
	end
end

local NewSegment,AddSegmentToData = nil
local NewFight,LoadFight,ChangeMaxFights = nil

function module:Enable()
	VExRT.BossWatcher.enabled = true
	
	module:RegisterEvents('ZONE_CHANGED_NEW_AREA')
	module.main:ZONE_CHANGED_NEW_AREA()
	module:RegisterSlash()
	
	UpdateNewSegmentEvents()
end

function module:Disable()
	VExRT.BossWatcher.enabled = nil
	
	--module:UnregisterEvents('UNIT_TARGET','ZONE_CHANGED_NEW_AREA','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','ENCOUNTER_START','ENCOUNTER_END','UNIT_SPELLCAST_SUCCEEDED')
	module.main:UnregisterAllEvents()
	module:UnregisterSlash()
end

function module.options:Load()
	module.options.timeLinePieces = 40
	
	for i=5,#module.db.buffsFilters do
		for _,sID in ipairs(module.db.buffsFilters[i][-2]) do
			module.db.buffsFilters[i][sID] = true
		end
	end
	
	--> General Func

	local UpdatePage, UpdatePageNewFight, UpdateBuffPageDB
	
	local function GUIDtoText(patt,GUID)
		if VExRT.BossWatcher.GUIDs and GUID and GUID ~= "" then
			patt = patt or "%s"
			return format(patt,GUID)
		else
			return ""
		end
	end
	
	--> Options
	
	self.checkEnabled = ExRT.lib.CreateCheckBox(nil,self,nil,10,-7,ExRT.L.senable,VExRT.BossWatcher.enabled)
	self.checkEnabled:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			module:Enable()
		else
			module:Disable()
		end
	end)
	
	self.checkShowGUIDs = ExRT.lib.CreateCheckBox(nil,self,nil,211,-7,ExRT.L.BossWatcherChkShowGUIDs,VExRT.BossWatcher.GUIDs)
	self.checkShowGUIDs:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.BossWatcher.GUIDs = true
		else
			VExRT.BossWatcher.GUIDs = nil
		end
		if module.options.targetsList.selected then
			module.options.targetsList:SetListValue(module.options.targetsList.selected)
		end
		UpdatePage()
	end)
	
		
	self.frameSettings = ExRT.lib.CreatePopupFrame(self:GetName().."FrameSettings",350,170,ExRT.L.BossWatcherOptions)

	self.frameSettings.checkSpellID = ExRT.lib.CreateCheckBox(nil,self.frameSettings,nil,15,-30,ExRT.L.BossWatcherOptionSpellID,VExRT.BossWatcher.timeLineSpellID)
	self.frameSettings.checkSpellID:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.BossWatcher.timeLineSpellID = true
		else
			VExRT.BossWatcher.timeLineSpellID = nil
		end
		UpdatePage()
	end)

	self.frameSettings.checkDoNotReset = ExRT.lib.CreateCheckBox(nil,self.frameSettings,nil,15,-55,ExRT.L.BossWatcherDoNotReset,VExRT.BossWatcher.notReset,ExRT.L.BossWatcherDoNotResetTooltip)
	self.frameSettings.checkDoNotReset:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.BossWatcher.notReset = true
		else
			VExRT.BossWatcher.notReset = nil
		end
	end)
	
	self.frameSettings.sliderNum = ExRT.lib.CreateSlider(self:GetName().."FrameSettingsSliderNum",self.frameSettings,300,15,0,-100,1,10,ExRT.L.BossWatcherOptionsFightsSave,VExRT.BossWatcher.fightsNum or 1,"TOP")
	self.frameSettings.sliderNum:SetScript("OnValueChanged", function(self,event) 
		event = ExRT.mds.Round(event)
		ChangeMaxFights(event)
		VExRT.BossWatcher.fightsNum = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	self.frameSettings.warningText = ExRT.lib.CreateText(self.frameSettings,330,25,nil,15,-135,"LEFT","TOP",nil,11,ExRT.L.BossWatcherOptionsFightsWarning,nil,1,1,1,1)

	
	self.buttonSettings = ExRT.lib.CreateButton(nil,self,170,22,nil,422,-8,ExRT.L.BossWatcherOptions)
	self.buttonSettings:SetScript("OnClick", function(self) 
		module.options.frameSettings.ShowClick(module.options.frameSettings,"TOPRIGHT")
	end)
	
	local function timestampToFightTime(time)
		if not module.db.timeFix then
			return 0
		end
		local res = time - (module.db.timeFix[2] - module.db.timeFix[1] + module.db.encounterStart) 
		return max(res,0)
	end
	
	--> Clear All Data
	self.clearButton = CreateFrame("Button",self:GetName().."ButtonRemove",self,"UIPanelCloseButton") 
	self.clearButton:SetSize(24,24) 
	self.clearButton:SetPoint("TOPRIGHT",-8,-7) 
	self.clearButton.tooltipText = ExRT.L.BossWatcherClear
	self.clearButton:SetScript("OnClick", function() 
		if fightUV then
			module.main:ENCOUNTER_END()
		end
		table.wipe(module.db.guidsList)
		table.wipe(module.db.fightData)
		table.wipe(module.db.globalFights)
		
		table.wipe(heal_shields)
		
		collectgarbage("collect")
		NewSegment(nil,nil,true)
		
		module.db.encounterName = ""
		module.db.encounterStart = 0
		module.db.encounterEnd = 0
		module.db.encounterStartGlobal = 0
		
		module.db.lastFightID = module.db.lastFightID + 1
		
		UpdatePageNewFight()
		UpdateBuffPageDB()
		UpdatePage()
	end) 
	self.clearButton:SetScript("OnEnter",ExRT.lib.OnEnterTooltip)
	self.clearButton:SetScript("OnLeave",ExRT.lib.OnLeaveTooltip)
	
	--> Time Line
	
	local function TimeLinePieceOnEnter(self)
		if self.tooltip and #self.tooltip > 0 then
			ExRT.lib.TooltipShow(self,"ANCHOR_RIGHT",ExRT.L.BossWatcherTimeLineTooltipTitle..":",unpack(self.tooltip))
		end
	end
	
	self.timeLine = CreateFrame("Frame",nil,self)
	self.timeLine:SetSize(600,30)
	self.timeLine:SetPoint("TOP",0,-50)
	for i=1,module.options.timeLinePieces do
		local tlWidth = 600/module.options.timeLinePieces
		self.timeLine[i] = CreateFrame("Frame",nil,self.timeLine)
		self.timeLine[i]:SetSize(tlWidth,30)
		self.timeLine[i]:SetPoint("TOPLEFT",(i-1)*tlWidth,0)
		self.timeLine[i]:SetScript("OnEnter",TimeLinePieceOnEnter)
		self.timeLine[i]:SetScript("OnLeave",ExRT.lib.TooltipHide)	
	end
	self.timeLine.texture = self.timeLine:CreateTexture(nil, "BACKGROUND",nil,0)
	self.timeLine.texture:SetTexture("Interface\\AddOns\\ExRT\\media\\bar9.tga")
	self.timeLine.texture:SetVertexColor(0.3, 1, 0.3, 1)
	self.timeLine.texture:SetAllPoints()
	
	self.timeLine.textLeft = ExRT.lib.CreateText(self.timeLine,200,16,nil,0,0,"LEFT","TOP",nil,12,"",nil,1,1,1,1)
	self.timeLine.textLeft:ClearAllPoints()
	self.timeLine.textLeft:SetPoint("BOTTOMLEFT",self.timeLine,"BOTTOMLEFT", 2, 2)

	self.timeLine.textCenter = ExRT.lib.CreateText(self.timeLine,200,16,nil,0,0,"CENTER","TOP",nil,12,"",nil,1,1,1,1)
	self.timeLine.textCenter:ClearAllPoints()
	self.timeLine.textCenter:SetPoint("BOTTOM",self.timeLine,"BOTTOM", 0, 2)

	self.timeLine.textRight = ExRT.lib.CreateText(self.timeLine,200,16,nil,0,0,"RIGHT","TOP",nil,12,"",nil,1,1,1,1)
	self.timeLine.textRight:ClearAllPoints()
	self.timeLine.textRight:SetPoint("BOTTOMRIGHT",self.timeLine,"BOTTOMRIGHT", -2, 2)
	
	self.timeLine.bossName = ExRT.lib.CreateText(self.timeLine,400,16,nil,0,0,"RIGHT","BOTTOM",nil,16,"",nil,1,1,1,1)
	self.timeLine.bossName:ClearAllPoints()
	self.timeLine.bossName:SetPoint("BOTTOMRIGHT",self.timeLine,"TOPRIGHT", -20, 2)
	
	self.timeLine.lifeUnderLine = self.timeLine:CreateTexture(nil, "BACKGROUND")
	self.timeLine.lifeUnderLine:SetTexture(1,1,1,1)
	self.timeLine.lifeUnderLine:SetGradientAlpha("VERTICAL", 1,0.2,0.2, 0, 1,0.2,0.2, 0.7)
	self.timeLine.lifeUnderLine._SetPoint = self.timeLine.lifeUnderLine.SetPoint
	self.timeLine.lifeUnderLine.SetPoint = function(self,_start,_end)
		self:ClearAllPoints()
		self:_SetPoint("TOPLEFT",self:GetParent(),"BOTTOMLEFT",_start*600,0)
		self:SetSize((_end-_start)*600,16)
		self:Show()
	end
	
	self.timeLine.arrow = self.timeLine:CreateTexture(nil, "BACKGROUND")
	self.timeLine.arrow:SetTexture("Interface\\CURSOR\\Quest")
	self.timeLine.arrow:Hide()

	self.timeLine.arrowNow = self.timeLine:CreateTexture(nil, "BACKGROUND")
	self.timeLine.arrowNow:SetTexture("Interface\\CURSOR\\Inspect")	
	self.timeLine.arrowNow:Hide()
	
	self.timeLine.redLine = {}
	local function CreateRedLine(i)
		module.options.timeLine.redLine[i] = module.options.timeLine:CreateTexture(nil, "BACKGROUND",nil,5)
		module.options.timeLine.redLine[i]:SetTexture(0.7, 0.1, 0.1, 0.5)
		module.options.timeLine.redLine[i]:SetSize(2,30)
	end
	
	self.timeLine.blueLine = {}
	local function CreateBlueLine(i)
		module.options.timeLine.blueLine[i] = module.options.timeLine:CreateTexture(nil, "BACKGROUND",nil,6)
		module.options.timeLine.blueLine[i]:SetTexture(0.1, 0.1, 0.7, 0.5)
		module.options.timeLine.blueLine[i]:SetSize(3,30)
	end
	
	self.fightSelectDropDown = CreateFrame("Frame", self:GetName().."FightSelectDropDown", nil, "UIDropDownMenuTemplate")
	self.fightSelect = CreateFrame("Button",self:GetName().."FightSelect",self,"ExRTUIChatDownButtonTemplate")
	self.fightSelect:SetPoint("BOTTOMRIGHT",self.timeLine,"TOPRIGHT", 3, -1)
	self.fightSelect:SetScript("OnClick",function (self)
		if fightUV then
			return
		end
		local fightsList = {
			{
				text = ExRT.L.BossWatcherSelectFight, 
				isTitle = true, 
				notCheckable = true, 
				notClickable = true 
			},
		}
		for i=1,#module.db.globalFights do
			local colorCode = ""
			if module.db.globalFights[i].encounterStartGlobal == module.db.encounterStartGlobal then
				colorCode = "|cff00ff00"
			end
			fightsList[#fightsList + 1] = {
				text = i..". "..colorCode..(module.db.globalFights[i].encounterName or ExRT.L.BossWatcherLastFight)..date(": %H:%M - ", module.db.globalFights[i].encounterStartGlobal )..date("%H:%M", module.db.globalFights[i].encounterStartGlobal + (module.db.globalFights[i].encounterEnd - module.db.globalFights[i].encounterStart) ),
				notCheckable = true,
				func = function() 
					LoadFight(i) 
					
					UpdatePageNewFight()
					UpdateBuffPageDB()
					UpdatePage()
				end,
			}
		end
		fightsList[#fightsList + 1] = {
			text = ExRT.L.BossWatcherSelectFightClose,
			notCheckable = true,
			func = function() 
				CloseDropDownMenus() 
			end,
		}
		EasyMenu(fightsList, module.options.fightSelectDropDown, "cursor", 10 , -15, "MENU")
	end)
	self.fightSelect:SetScript("OnEnter",function(self)
		ExRT.lib.TooltipShow(self,nil,ExRT.L.BossWatcherSelectFight)
	end)
	self.fightSelect:SetScript("OnLeave",function(self)
		ExRT.lib.TooltipHide()
	end)
	self.fightSelect:SetScript("OnHide",function(self)
		CloseDropDownMenus() 
	end)
	
	--> Tabs
	
	self.tab = ExRT.lib.CreateTabFrame(self:GetName().."Tab",self,614,424,10,-140,8,1,ExRT.L.BossWatcherTabMobs,ExRT.L.BossWatcherTabHeal,ExRT.L.BossWatcherTabBuffsAndDebuffsTooltip,ExRT.L.BossWatcherTabPlayersSpells,ExRT.L.BossWatcherTabEnergy,ExRT.L.BossWatcherSegments,ExRT.L.BossWatcherTabInterruptAndDispel,ExRT.L.BossWatcherOverkills)
	ExRT.lib.SetPoint(self.tab,"TOP",self,0,-140)
	
	--self.tab.tabs[3].button.tooltip = ExRT.L.BossWatcherTabBuffsAndDebuffsTooltip
	self.tab.tabs[4].button.tooltip = ExRT.L.BossWatcherTabPlayersSpellsTooltip
	
	--> Tab Damage
	
	self.targetsList = ExRT.lib.CreateScrollList(self:GetName().."TargetsList",self.tab.tabs[1],"LEFT",5,0,290,25)
	
	function self.targetsList:SetListValue(index)
		local destGUID = module.options.targetsIndex[index]
		
		local _time = timestampToFightTime(module.db.fightData.damage[module.options.targetsIndex[index]].id)
		local fight_dur = module.db.encounterEnd - module.db.encounterStart
		
		module.options.damgeSwitchTab.text:SetText(module.db.guidsListFix[destGUID].." "..date("%M:%S", _time )..GUIDtoText(" (%s)",destGUID))
		
		_time = _time / fight_dur
		module.options.timeLine.arrowNow:SetPoint("TOPLEFT",module.options.timeLine,"BOTTOMLEFT",600*_time,0)
		
		module.options.timeLine.arrowNow:Show()

		
		-->
		local damageTable = {}
		local total = 0
		local textResult = ""
		local petBase = {}
		if ExRT.mds.Pets then
			for sourceGUID,sourceDamage in pairs(module.db.fightData.damage[destGUID].d) do
				local owner = ExRT.mds.Pets:getOwnerGUID(sourceGUID)
				if owner then
					petBase[sourceGUID] = owner
					module.db.fightData.damage[destGUID].d[owner] = module.db.fightData.damage[destGUID].d[owner] or {}
					module.db.fightData.damage[destGUID].d[owner].pets = module.db.fightData.damage[destGUID].d[owner].pets or {}
					
					local alreadyHasOwner = nil
					for i=1,#module.db.fightData.damage[destGUID].d[owner].pets do
						if module.db.fightData.damage[destGUID].d[owner].pets[i][2] == sourceGUID then
							alreadyHasOwner = true
							break
						end
					end
					
					if not alreadyHasOwner then
						module.db.fightData.damage[destGUID].d[owner].pets[ #module.db.fightData.damage[destGUID].d[owner].pets + 1 ] = {sourceDamage,sourceGUID}
					end
					
					module.db.fightData.damage[destGUID].d[sourceGUID].isPet = true
				end
				
				-- Hunter trap fix. Viper and Snake haven't SUMMON data and owner
				local isNPC = ExRT.mds.GetUnitTypeByGUID(sourceGUID) == 3
				if isNPC then
					local npcID = tonumber(string_sub(sourceGUID, -13, -9), 16) or 0
					if npcID == 19833 or npcID == 19921 then
						module.db.fightData.damage[destGUID].d[sourceGUID].isPet = true
					end
				end
			end
		end
		for sourceGUID,sourceData in pairs(module.db.fightData.damage[destGUID].d) do
			if not sourceData.isPet then
				local inDamageTable = #damageTable + 1
				damageTable[inDamageTable] = {module.db.guidsListFix[sourceGUID],0,sourceGUID}
				for spellID,amount in pairs(sourceData) do
					if type(amount) == "number" then
						damageTable[inDamageTable][2] = damageTable[inDamageTable][2] + amount
					end
				end
				if sourceData.pets then
					for i=1,#sourceData.pets do
						for spellID,amount in pairs(sourceData.pets[i][1]) do
							if type(amount) == "number" then
								damageTable[inDamageTable][2] = damageTable[inDamageTable][2] + amount
							end
						end
					end
				end
				total = total + damageTable[inDamageTable][2]
			end
		end
		
		table.sort(damageTable,function(a,b) return a[2] > b[2] end)
		textResult = ExRT.L.BossWatcherReportTotal..": " .. ExRT.mds.shortNumber(total) .. "\n\n"
		module.options.damgeBox.EditBox.destGUID = destGUID
		for i=1,#damageTable do
			textResult = textResult ..i.. ". |c".. ExRT.mds.classColorByGUID(damageTable[i][3]) .. "|HExRT:BW:damageBox:"..damageTable[i][3].."|h" .. damageTable[i][1] .. GUIDtoText(" <%s>",damageTable[i][3]) .. "|h|r " .. ExRT.mds.shortNumber(damageTable[i][2]) .. " (" .. format("%.1f%%",damageTable[i][2]/total*100) .. ")\n"
		end
		module.options.damgeBox.EditBox:SetText(textResult)
		
		-->
		textResult = ""
		if module.db.fightData.switch[destGUID] then
			local switchTable = {}

			for sourceGUID,sourceData in pairs(module.db.fightData.switch[destGUID][1]) do
				table.insert(switchTable,{module.db.guidsListFix[sourceGUID],timestampToFightTime(sourceData[1]),sourceGUID,sourceData[2]})
			end
			table.sort(switchTable,function(a,b) return a[2] < b[2] end)
			if #switchTable > 0 then
				textResult = ExRT.L.BossWatcherReportCast.." [" .. date("%M:%S", switchTable[1][2] ) .."]: "
				for i=1,#switchTable do
					local spellName = GetSpellInfo(switchTable[i][4] or 0)
					textResult = textResult .."|c".. ExRT.mds.classColorByGUID(switchTable[i][3]).. switchTable[i][1] .. GUIDtoText(" <%s>",switchTable[i][3]) .. "|r (".. format("%.3f",switchTable[i][2]-switchTable[1][2])..", |Hspell:"..(switchTable[i][4] or 0).."|h"..(spellName or "?").."|h)"
					if i ~= #switchTable then
						textResult = textResult .. ", "
					end
				end
				textResult = textResult .. "\n\n"
			end
			
			table_wipe(switchTable)
			for sourceGUID,sourceData in pairs(module.db.fightData.switch[destGUID][2]) do
				table.insert(switchTable,{module.db.guidsListFix[sourceGUID],sourceData[1] - module.db.encounterStart,sourceGUID,sourceData[2]})
			end
			table.sort(switchTable,function(a,b) return a[2] < b[2] end)
			if #switchTable > 0 then
				textResult = textResult .. ExRT.L.BossWatcherReportSwitch.." [" .. date("%M:%S", switchTable[1][2] ) .."]: "
				for i=1,#switchTable do
					textResult = textResult .. "|c".. ExRT.mds.classColorByGUID(switchTable[i][3]).. switchTable[i][1] .. GUIDtoText(" <%s>",switchTable[i][3]) .. "|r (".. format("%.3f",switchTable[i][2]-switchTable[1][2])..")"
					if i ~= #switchTable then
						textResult = textResult .. ", "
					end
				end
			end
		end		
		module.options.switchBox.EditBox:SetText(textResult)
		
		--> Other Info
		textResult = ""
		for i=1,#module.db.fightData.dies do
			if module.db.fightData.dies[i][1]==destGUID then
				textResult = textResult .. ExRT.L.BossWatcherDamageSwitchTabInfoRIP..": ".. date("%M:%S", timestampToFightTime(module.db.fightData.dies[i][3]) ) .. date(" (%H:%M:%S)", module.db.fightData.dies[i][3] ) .. "\n"
				for j=1,#module.db.raidTargets do
					if module.db.raidTargets[j] == module.db.fightData.dies[i][4] then
						textResult = textResult .. ExRT.L.BossWatcherMarkOnDeath..": |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_".. j  ..":0|t ".. string.gsub( ExRT.L["raidtargeticon"..j] , "[{}]", "" ) .."\n"
						break
					end
				end
			end
		end
		local mobID = tonumber(destGUID:sub(-13, -9), 16) or 0
		local mobSpawnID = tonumber(destGUID:sub(-8), 16) or 0
		textResult = textResult .. "Mob ID: ".. mobID .. "\n"
		textResult = textResult .. "Spawn ID: ".. mobSpawnID .. "\n"
		textResult = textResult .. "GUID: ".. destGUID .. "\n"
		module.options.infoBoxText:SetText(textResult)
	end
	
	function self.targetsList:HoverListValue(isHover,index)
		if not isHover then
			module.options.timeLine.arrow:Hide()
			module.options.timeLine.lifeUnderLine:Hide()
			if VExRT.BossWatcher.GUIDs then
				
			end
			GameTooltip_Hide()
		else
			local mobGUID = module.options.targetsIndex[index]
			local _time = timestampToFightTime( module.db.fightData.damage[mobGUID].id )
			local fight_dur = module.db.encounterEnd - module.db.encounterStart
			
			_time = _time / fight_dur
			module.options.timeLine.arrow:SetPoint("TOPLEFT",module.options.timeLine,"BOTTOMLEFT",600*_time,0)
			
			module.options.timeLine.arrow:Show()
			
			local dieTime = 1
			for i=1,#module.db.fightData.dies do
				if module.db.fightData.dies[i][1]==mobGUID then
					dieTime = timestampToFightTime(module.db.fightData.dies[i][3]) / fight_dur
					break
				end
			end
			module.options.timeLine.lifeUnderLine:SetPoint(_time,dieTime)
			
			GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
			if VExRT.BossWatcher.GUIDs then
				GameTooltip:AddLine(mobGUID or "")
			end
			local scrollPos = ExRT.mds.Round(module.options.targetsList.ScrollBar:GetValue())
			if module.options.targetsList.List[index - scrollPos + 1].text:GetStringWidth() > 250 then
				GameTooltip:AddLine(module.db.guidsListFix[mobGUID] .. date(" %M:%S", timestampToFightTime(module.db.fightData.damage[mobGUID].id)) )
			end
			GameTooltip:Show()
		end
	end
	
	self.targetsList.dataIndex = nil
	self.targetsIndex = {}
	
	self.damgeSwitchTab = ExRT.lib.CreateTabFrame(self:GetName().."DamgeSwitchTab",self.tab.tabs[1],314,360,295,-30,3,1,ExRT.L.BossWatcherDamageSwitchTabDamage,ExRT.L.BossWatcherDamageSwitchTabSwitch,ExRT.L.BossWatcherDamageSwitchTabInfo)
	self.damgeSwitchTab.text = ExRT.lib.CreateText(self.damgeSwitchTab,292,12,"TOP",0,-8,"LEFT","TOP",nil,11,"",nil,1,1,1)
	self.damgeSwitchTab.textFrame = ExRT.lib.CreateHiddenFrame(nil,self.damgeSwitchTab,"TOP",0,-8,292,12)
	self.damgeSwitchTab.textFrame:SetScript("OnEnter",function (self)
		ExRT.lib.TooltipShow(self,"ANCHOR_LEFT",module.options.damgeSwitchTab.text:GetText())
	end)
	self.damgeSwitchTab.textFrame:SetScript("OnLeave",function ()
		ExRT.lib.TooltipHide()
	end)
		
	self.damgeBox = ExRT.lib.CreateMultiEditBox(self:GetName().."DamgeBox",self.damgeSwitchTab.tabs[1],292,324,"TOP",0,-25)
	self.switchBox = ExRT.lib.CreateMultiEditBox(self:GetName().."SwitchBox",self.damgeSwitchTab.tabs[2],292,324,"TOP",0,-25)
	self.infoBoxText = ExRT.lib.CreateText(self.damgeSwitchTab.tabs[3],292,310,"TOP",0,-25,"LEFT","TOP",nil,12,ExRT.L.BossWatcherDamageSwitchTabInfoNoInfo,nil,1,1,1)
	
	self.switchBox.EditBox:SetHyperlinksEnabled(true)
	self.switchBox.EditBox:SetScript("OnHyperlinkEnter",ExRT.lib.EditBoxOnEnterHyperLinkTooltip)
	self.switchBox.EditBox:SetScript("OnHyperlinkLeave",ExRT.lib.EditBoxOnLeaveHyperLinkTooltip)
	
	local function ShowDamageBySpellFrame(guid)
		local destGUID = self.damgeBox.EditBox.destGUID
		if not guid or not module.db.fightData.damage[destGUID].d[guid] then
			return
		end
		
		local textResult = "|c" .. ExRT.mds.classColorByGUID(guid) .. module.db.guidsListFix[guid].. GUIDtoText(" <%s>",guid) .."|r\n"..ExRT.L.BossWatcherReportTotal..": " 
		local damageTable = {}
		local total = 0
		
		for spellID,amount in pairs(module.db.fightData.damage[destGUID].d[guid]) do
			if type(amount) == "number" then
				local spellName,_,spellTexture = GetSpellInfo(spellID)
				damageTable[#damageTable + 1] = {spellName,amount,spellTexture,spellID}
				total = total + amount
			elseif spellID == "pets" then
				for i=1,#amount do
					for petSpellID,petAmount in pairs(amount[i][1]) do
						if type(petAmount) == "number" then
							local spellName,_,spellTexture = GetSpellInfo(petSpellID)
							damageTable[#damageTable + 1] = {(module.db.guidsListFix[ amount[i][2] ] or "").."("..ExRT.L.BossWatcherPetText..")".. GUIDtoText("<%s>",amount[i][2]) ..": "..spellName,petAmount,spellTexture,petSpellID}
							total = total + petAmount
						end
					end
				end
			end
		end
		textResult = textResult .. ExRT.mds.shortNumber(total) .. "\n\n"
		table.sort(damageTable,function(a,b) return a[2] > b[2] end)
		for i=1,#damageTable do
			textResult = textResult .. "|T".. damageTable[i][3] ..":0|t |Hspell:" .. damageTable[i][4] .."|h".. damageTable[i][1] .. "|h - " .. ExRT.mds.shortNumber(damageTable[i][2]) .. " (" .. format("%.1f%%",damageTable[i][2]/total*100) .. ")\n"
		end
		
		module.options.damgeBoxNewFrame.MEditBox.EditBox:SetText(textResult)
		module.options.damgeBoxNewFrame:ShowClick("TOPRIGHT",true)
	end

	self.damgeBox.EditBox:SetHyperlinksEnabled(true)
	self.damgeBox.EditBox:SetScript("OnHyperlinkClick",function (self,link)
		local Ltype,Lmodule,Lsub,Lguid = link:match("([^:]+):([^:]+):([^:]+):(.+)")
		if Ltype == "ExRT" and Lmodule == "BW" and Lsub == "damageBox" then
			ShowDamageBySpellFrame(Lguid)
		end
	end)
	self.damgeBox.EditBox:SetScript("OnHyperlinkEnter",function (self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetText(ExRT.L.BossWatcherDamageBoxPlayerTooltip)
		GameTooltip:Show()
	end)
	self.damgeBox.EditBox:SetScript("OnHyperlinkLeave",GameTooltip_Hide)
	
	self.damgeBoxNewFrame = ExRT.lib.CreatePopupFrame(self:GetName().."DamgeBoxBySpellFrame",430,385,"")
	self.damgeBoxNewFrame.MEditBox = ExRT.lib.CreateMultiEditBox(self:GetName().."DamgeBoxBySpellFrameEditBox",self.damgeBoxNewFrame,405,310,"TOP",0,-35)
	self.damgeBoxNewFrame.MEditBox:SetFrameStrata( self.damgeBoxNewFrame:GetFrameStrata() )
	self.damgeBoxNewFrame.MEditBox:SetFrameLevel( self.damgeBoxNewFrame:GetFrameLevel() + 2 )
	self.damgeBoxNewFrame.MEditBox.EditBox:SetHyperlinksEnabled(true)
	self.damgeBoxNewFrame.MEditBox.EditBox:SetScript("OnHyperlinkEnter",ExRT.lib.EditBoxOnEnterHyperLinkTooltip)
	self.damgeBoxNewFrame.MEditBox.EditBox:SetScript("OnHyperlinkLeave",ExRT.lib.EditBoxOnLeaveHyperLinkTooltip)
	
	self.damgeBoxNewFrame.buttonToChat = ExRT.lib.CreateButton(nil,self.damgeBoxNewFrame,415,23,"TOP",0,-351,ExRT.L.BossWatcherToChat)
	self.damgeBoxNewFrame.buttonToChat:SetScript("OnClick",function ()
		local textResult = self.damgeBoxNewFrame.MEditBox.EditBox:GetText()
		local strings = {strsplit("\n", textResult)}
		local chat_type = ExRT.mds.chatType(true)
		if #strings > 1 then
			SendChatMessage(self.damgeSwitchTab.text:GetText(),chat_type)
		end
		for i=1,#strings do
			if strings[i] ~= "" then
				local splitLine = {ExRT.mds.splitLongLine(ExRT.mds.clearTextTag(strings[i],true),250,true)}
				for j=1,#splitLine do
					SendChatMessage(splitLine[j],chat_type)
				end
			end
		end
	end)
	
	self.buttonToChat = ExRT.lib.CreateButton(nil,self.tab.tabs[1],314,22,nil,295,-392,ExRT.L.BossWatcherToChat)
	self.buttonToChat:SetScript("OnClick",function ()
		local textResult = ""
		if self.damgeSwitchTab.selected == 1 then
			textResult = self.damgeBox.EditBox:GetText()
		elseif self.damgeSwitchTab.selected == 2 then
			textResult = self.switchBox.EditBox:GetText()
		end
		local strings = {strsplit("\n", textResult)}
		local chat_type = ExRT.mds.chatType(true)
		if #strings > 1 then
			SendChatMessage(self.damgeSwitchTab.text:GetText(),chat_type)
		end
		for i=1,#strings do
			if strings[i] ~= "" then
				local splitLine = {ExRT.mds.splitLongLine(ExRT.mds.clearTextTag(strings[i],true),250,true)}
				for j=1,#splitLine do
					SendChatMessage(splitLine[j],chat_type)
				end
			end
		end
	end)
	
	--> Tab Heal
	
	local function UpdateHealList(byTarget)
		table.wipe(self.heal.targetsList.L)
		table.wipe(self.heal.targetsList.Lguids)
		self.heal.targetsList.selected = nil

		local sourceList = {}
		if byTarget then
			for sourceGUID,sourceData in pairs(module.db.fightData.heal) do
				for destGUID,destData in pairs(sourceData) do
					local destInTable = nil
					for i=1,#sourceList do
						if sourceList[i][2] == destGUID then
							destInTable = sourceList[i]
							break
						end
					end
					if not destInTable then
						destInTable = {module.db.guidsListFix[destGUID],destGUID,ExRT.mds.classColorByGUID(destGUID),0}
						sourceList[#sourceList + 1] = destInTable
					end
					for _,spellData in pairs(destData) do
						destInTable[4] = destInTable[4] + spellData[1] - spellData[2] + spellData[3]
					end
				end
			end
		else
			for sourceGUID,sourceData in pairs(module.db.fightData.heal) do
				local ownerGUID,GUID = nil
				if ExRT.mds.Pets then
					ownerGUID = ExRT.mds.Pets:getOwnerGUID(sourceGUID)
				end
				GUID = ownerGUID or sourceGUID
				local i = ExRT.mds.table_find(sourceList,GUID,2)
				if not i then
					i = #sourceList + 1
					sourceList[i] = {module.db.guidsListFix[GUID],GUID,ExRT.mds.classColorByGUID(GUID),0}
				end
				for _,destData in pairs(sourceData) do
					for _,spellData in pairs(destData) do
						sourceList[i][4] = sourceList[i][4] + spellData[1] - spellData[2] + spellData[3]
					end
				end
			end
		end

		table.sort(sourceList,function(a,b) return a[4] > b[4] end)
		
		for i=1,#sourceList do
			self.heal.targetsList.L[i] =  "|c"..sourceList[i][3]..sourceList[i][1].."|r - "..ExRT.mds.shortNumber(sourceList[i][4])
			self.heal.targetsList.Lguids[i] = sourceList[i][2]
		end
		
		module.options.heal.targetsList.Update()
		module.options.heal.healBox.EditBox:SetText("")
	end
	
	self.heal = {}
	
	self.heal.targetsList = ExRT.lib.CreateScrollList(self:GetName().."HealTargetsList",self.tab.tabs[2],"TOPLEFT",5,-26,290,24)
	self.heal.targetsList.Lguids = {}
	
	self.heal.healBox = ExRT.lib.CreateMultiEditBox(self:GetName().."HealBox",self.tab.tabs[2],295,396-22,"TOPLEFT",305,-15)
	
	self.heal.bySource = ExRT.lib.CreateButton(nil,self.tab.tabs[2],143,16,nil,6,-8,ExRT.L.BossWatcherHealBySource)
	self.heal.bySource:SetScript("OnClick",function (self)
		self:SetEnabled(false)
		module.options.heal.byDest:SetEnabled(true)
		module.options.heal.byTarget = nil
		UpdateHealList(nil)
	end)
	self.heal.byDest = ExRT.lib.CreateButton(nil,self.tab.tabs[2],143,16,nil,153,-8,ExRT.L.BossWatcherHealByTarget)
	self.heal.byDest:SetScript("OnClick",function (self)
		self:SetEnabled(false)
		module.options.heal.bySource:SetEnabled(true)
		module.options.heal.byTarget = true
		UpdateHealList(true)
	end)
	
	function self.heal.targetsList:HoverListValue(isHover,index)
		if not isHover then
			GameTooltip_Hide()
		else
			local sourceGUID = module.options.heal.targetsList.Lguids[index]
			
			GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
			if VExRT.BossWatcher.GUIDs then
				GameTooltip:AddLine(sourceGUID or "")
			end
			local scrollPos = ExRT.mds.Round(module.options.heal.targetsList.ScrollBar:GetValue())
			if module.options.heal.targetsList.List[index - scrollPos + 1].text:GetStringWidth() > 250 then
				GameTooltip:AddLine( module.options.heal.targetsList.List[index - scrollPos + 1].text:GetText() )
			end
			GameTooltip:Show()
		end
	end
	
	function self.heal.targetsList:SetListValue(index)
		local sourceGUID = module.options.heal.targetsList.Lguids[index]

		local destList = {}
		local total = 0
		if module.options.heal.byTarget then
			for _sourceGUID,sourceData in pairs(module.db.fightData.heal) do
				if sourceData[sourceGUID] then
					local ownerGUID,GUID = nil
					if ExRT.mds.Pets then
						ownerGUID = ExRT.mds.Pets:getOwnerGUID(_sourceGUID)
					end
					GUID = ownerGUID or _sourceGUID
					local i = ExRT.mds.table_find(destList,GUID,2)
					if not i then
						i = #destList + 1
						destList[i] = {module.db.guidsListFix[GUID],GUID,0}
					end
					for _,spellData in pairs(sourceData[sourceGUID]) do
						destList[i][3] = destList[i][3] + spellData[1] - spellData[2] + spellData[3]
						total = total + spellData[1] - spellData[2] + spellData[3]
					end
				end
			end
		else
			for sGUID,sData in pairs(module.db.fightData.heal) do
				local ownerGUID = nil
				if ExRT.mds.Pets then
					ownerGUID = ExRT.mds.Pets:getOwnerGUID(sGUID)
				end
				if sourceGUID == sGUID or sourceGUID == ownerGUID then
					for destGUID,destData in pairs(sData) do
						local i = ExRT.mds.table_find(destList,destGUID,2)
						if not i then
							i = #destList + 1
							destList[i] = {module.db.guidsListFix[destGUID],destGUID,0}
						end
						for _,spellData in pairs(destData) do
							destList[i][3] = destList[i][3] + spellData[1] - spellData[2] + spellData[3]
							total = total + spellData[1] - spellData[2] + spellData[3]
						end
					end
				end
			end
		end
		table.sort(destList,function(a,b) return a[3] > b[3] end)
		
		textResult = "|HExRT:BW:healAll:0|h"..ExRT.L.BossWatcherReportTotal.."|h: " .. ExRT.mds.shortNumber(total) .. "\n\n"
		module.options.heal.healBox.EditBox.sourceGUID = sourceGUID
		total = max(total,1)
		for i=1,#destList do
			textResult = textResult ..i.. ". |c".. ExRT.mds.classColorByGUID(destList[i][2]) .. "|HExRT:BW:healBox:"..destList[i][2].."|h" .. destList[i][1] .. GUIDtoText(" <%s>",destList[i][2]) .. "|h|r " .. ExRT.mds.shortNumber(destList[i][3]) .. " (" .. format("%.1f%%",destList[i][3]/total*100) .. ")\n"
		end
		module.options.heal.healBox.EditBox:SetText(textResult)
	end
	
	local function HealNumOrNil(patt,num)
		if num == 0 then
			return ""
		else
			return format(patt,ExRT.mds.shortNumber(num))
		end
	end
	
	local function ShowHealBySpellFrame(guid)
		local sourceGUID = self.heal.healBox.EditBox.sourceGUID
		
		if module.options.heal.byTarget then
			local tmp = sourceGUID
			sourceGUID = guid
			guid = tmp
		end
		
		if not guid or not module.db.fightData.heal[sourceGUID] or not module.db.fightData.heal[sourceGUID][guid] then
			return
		end
		
		local textResult = "|c" .. ExRT.mds.classColorByGUID(sourceGUID) .. module.db.guidsListFix[sourceGUID].. GUIDtoText(" <%s>",sourceGUID) .."|r > |c" .. ExRT.mds.classColorByGUID(guid) .. module.db.guidsListFix[guid].. GUIDtoText(" <%s>",guid) .."|r\n"..ExRT.L.BossWatcherReportTotal..": " 
		local healTable = {}
		local total = 0
		
		for sGUID,sData in pairs(module.db.fightData.heal) do
			if sData[guid] then
				local ownerGUID = nil
				if ExRT.mds.Pets then
					ownerGUID = ExRT.mds.Pets:getOwnerGUID(sGUID)
				end
				
				if sGUID == sourceGUID or ownerGUID == sourceGUID then
					for spellID,amountData in pairs(sData[guid]) do
						local spellName,_,spellTexture = GetSpellInfo(spellID)
						local i = ExRT.mds.table_find(healTable,spellID,6)
						if not i then
							healTable[#healTable + 1] = {spellName,amountData[1]-amountData[2],amountData[2],amountData[3],spellTexture,spellID,ownerGUID and sGUID}
						else
							healTable[i][2] = healTable[i][2] + amountData[1]-amountData[2]+amountData[3]
							healTable[i][3] = healTable[i][3] + amountData[2]
							healTable[i][4] = healTable[i][4] + amountData[3]
						end
						total = total + amountData[1] - amountData[2] + amountData[3]
					end
				end
			end
		end

		textResult = textResult .. ExRT.mds.shortNumber(total) .. "\n\n"
		table.sort(healTable,function(a,b) return a[2] > b[2] end)
		total = max(total,1)
		for i=1,#healTable do
			textResult = textResult .. "|T".. healTable[i][5] ..":0|t ".. (healTable[i][7] and ExRT.L.BossWatcherPetText.." ("..module.db.guidsListFix[ healTable[i][7] ]..") " or "") .."|Hspell:" .. healTable[i][6] .."|h".. healTable[i][1] .. "|h - " .. ExRT.mds.shortNumber(healTable[i][2]) .. HealNumOrNil(", O:%s",healTable[i][3]) .. HealNumOrNil(", A:%s",healTable[i][4])  .. " (" .. format("%.1f%%",healTable[i][2]/total*100) .. ")\n"
		end
		
		module.options.heal.spellFrame.MEditBox.EditBox:SetText(textResult)
		module.options.heal.spellFrame:ShowClick("TOPRIGHT",true)
	end
	local function ShowHealAllBySpellFrame()
		local sourceGUID = self.heal.healBox.EditBox.sourceGUID
		local destGUID = nil
		if module.options.heal.byTarget then
			destGUID = sourceGUID
			sourceGUID = nil
		end
		
		local textResult = ""
		if sourceGUID then
			textResult = textResult .. "|c" .. ExRT.mds.classColorByGUID(sourceGUID) .. module.db.guidsListFix[sourceGUID].. GUIDtoText(" <%s>",sourceGUID) .."|r > "
		else
			textResult = textResult .. ExRT.L.BossWatcherHealAllSourceText .. " > "
		end
		
		if destGUID then
			textResult = textResult .. "|c" .. ExRT.mds.classColorByGUID(destGUID) .. module.db.guidsListFix[destGUID].. GUIDtoText(" <%s>",destGUID) .."|r"
		else
			textResult = textResult .. ExRT.L.BossWatcherHealAllTargetText
		end
		textResult = textResult .. "\n"..ExRT.L.BossWatcherReportTotal..": " 
		local healTable = {}
		local total = 0
		
		for sGUID,sData in pairs(module.db.fightData.heal) do
			local ownerGUID = nil
			if ExRT.mds.Pets then
				ownerGUID = ExRT.mds.Pets:getOwnerGUID(sGUID)
			end
			if not sourceGUID or (sGUID == sourceGUID or ownerGUID == sourceGUID) then
				for dGUID,dData in pairs(sData) do
					if not destGUID or destGUID == dGUID then
						for spellID,amountData in pairs(dData) do
							local spellName,_,spellTexture = GetSpellInfo(spellID)
							local i = ExRT.mds.table_find(healTable,spellID,6)
							if not i then
								healTable[#healTable + 1] = {spellName,amountData[1]-amountData[2],amountData[2],amountData[3],spellTexture,spellID}
							else
								healTable[i][2] = healTable[i][2] + amountData[1]-amountData[2]+amountData[3]
								healTable[i][3] = healTable[i][3] + amountData[2]
								healTable[i][4] = healTable[i][4] + amountData[3]
							end
							total = total + amountData[1] - amountData[2] + amountData[3]
						end
					end
				end
			end
		end

		textResult = textResult .. ExRT.mds.shortNumber(total) .. "\n\n"
		table.sort(healTable,function(a,b) return a[2] > b[2] end)
		total = max(total,1)
		for i=1,#healTable do
			textResult = textResult .. "|T".. healTable[i][5] ..":0|t |Hspell:" .. healTable[i][6] .."|h".. healTable[i][1] .. "|h - " .. ExRT.mds.shortNumber(healTable[i][2]) .. HealNumOrNil(", O:%s",healTable[i][3]) .. HealNumOrNil(", A:%s",healTable[i][4])  .. " (" .. format("%.1f%%",healTable[i][2]/total*100) .. ")\n"
		end
		
		module.options.heal.spellFrame.MEditBox.EditBox:SetText(textResult)
		module.options.heal.spellFrame:ShowClick("TOPRIGHT",true)
	end
	
	self.heal.healBox.EditBox:SetHyperlinksEnabled(true)
	self.heal.healBox.EditBox:SetScript("OnHyperlinkClick",function (self,link)
		local Ltype,Lmodule,Lsub,Lguid = link:match("([^:]+):([^:]+):([^:]+):(.+)")
		if Ltype == "ExRT" and Lmodule == "BW" then
			if Lsub == "healBox" then
				ShowHealBySpellFrame(Lguid)
			elseif Lsub == "healAll" then
				ShowHealAllBySpellFrame()
			end
		end
	end)
	self.heal.healBox.EditBox:SetScript("OnHyperlinkEnter",function (self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetText(ExRT.L.BossWatcherDamageBoxPlayerTooltip)
		GameTooltip:Show()
	end)
	self.heal.healBox.EditBox:SetScript("OnHyperlinkLeave",GameTooltip_Hide)
	
	self.heal.spellFrame = ExRT.lib.CreatePopupFrame(self:GetName().."HealBoxBySpellFrame",430,385,"")
	self.heal.spellFrame.MEditBox = ExRT.lib.CreateMultiEditBox(self:GetName().."HealBoxBySpellFrameEditBox",self.heal.spellFrame,405,310,"TOP",0,-35)
	self.heal.spellFrame.MEditBox:SetFrameStrata( self.heal.spellFrame:GetFrameStrata() )
	self.heal.spellFrame.MEditBox:SetFrameLevel( self.heal.spellFrame:GetFrameLevel() + 2 )
	self.heal.spellFrame.MEditBox.EditBox:SetHyperlinksEnabled(true)
	self.heal.spellFrame.MEditBox.EditBox:SetScript("OnHyperlinkEnter",ExRT.lib.EditBoxOnEnterHyperLinkTooltip)
	self.heal.spellFrame.MEditBox.EditBox:SetScript("OnHyperlinkLeave",ExRT.lib.EditBoxOnLeaveHyperLinkTooltip)
	
	self.heal.spellFrame.buttonToChat = ExRT.lib.CreateButton(nil,self.heal.spellFrame,415,23,"TOP",0,-351,ExRT.L.BossWatcherToChat)
	self.heal.spellFrame.buttonToChat:SetScript("OnClick",function ()
		local textResult = self.heal.spellFrame.MEditBox.EditBox:GetText()
		local strings = {strsplit("\n", textResult)}
		local chat_type = ExRT.mds.chatType(true)
		for i=1,#strings do
			if strings[i] ~= "" then
				local splitLine = {ExRT.mds.splitLongLine(ExRT.mds.clearTextTag(strings[i],true),250,true)}
				for j=1,#splitLine do
					SendChatMessage(splitLine[j],chat_type)
				end
			end
		end
	end)
	
	self.heal.buttonToChat = ExRT.lib.CreateButton(nil,self.tab.tabs[2],308,22,nil,0,0,ExRT.L.BossWatcherToChat)
	ExRT.lib.SetPoint(self.heal.buttonToChat,"TOP",self.heal.healBox,"BOTTOM",0,-6)
	self.heal.buttonToChat:SetScript("OnClick",function ()
		local textResult = self.heal.damgeBox.healBox:GetText()
		local strings = {strsplit("\n", textResult)}
		local chat_type = ExRT.mds.chatType(true)
		for i=1,#strings do
			if strings[i] ~= "" then
				local splitLine = {ExRT.mds.splitLongLine(ExRT.mds.clearTextTag(strings[i],true),250,true)}
				for j=1,#splitLine do
					SendChatMessage(splitLine[j],chat_type)
				end
			end
		end
	end)

	
	--> Tab Interrupts & Dispels
	
	self.interruptBox = ExRT.lib.CreateMultiEditBox(self:GetName().."InterruptBox",self.tab.tabs[7],590,180,"TOP",0,-25)
	self.interruptBox.text = ExRT.lib.CreateText(self.tab.tabs[7],575,12,"TOP",0,-8,"LEFT","TOP",nil,12,ExRT.L.BossWatcherInterrupts,nil,1,1,1)

	self.dispelBox = ExRT.lib.CreateMultiEditBox(self:GetName().."DispelBox",self.tab.tabs[7],590,180,"TOP",0,-233)
	self.dispelBox.text = ExRT.lib.CreateText(self.tab.tabs[7],575,12,"TOP",0,-216,"LEFT","TOP",nil,12,ExRT.L.BossWatcherDispels,nil,1,1,1)
	
	self.interruptBox.EditBox:SetHyperlinksEnabled(true)
	self.interruptBox.EditBox:SetScript("OnHyperlinkEnter",ExRT.lib.EditBoxOnEnterHyperLinkTooltip)
	self.interruptBox.EditBox:SetScript("OnHyperlinkLeave",ExRT.lib.EditBoxOnLeaveHyperLinkTooltip)

	self.dispelBox.EditBox:SetHyperlinksEnabled(true)
	self.dispelBox.EditBox:SetScript("OnHyperlinkEnter",ExRT.lib.EditBoxOnEnterHyperLinkTooltip)
	self.dispelBox.EditBox:SetScript("OnHyperlinkLeave",ExRT.lib.EditBoxOnLeaveHyperLinkTooltip)
	
	--> Tab Buffs & Debuffs
	
	self.buffs = {}
	self.buffs.timeLine = {}
	
	local buffsNameWidth = 120
	local buffsTotalWidth = buffsNameWidth + 470
	for i=1,11 do
		self.buffs.timeLine[i] = CreateFrame("Frame",nil,self.tab.tabs[3])
		self.buffs.timeLine[i]:SetPoint("TOPLEFT",buffsNameWidth+(i-1)*47-1,-42)
		self.buffs.timeLine[i]:SetSize(2,374)
		
		self.buffs.timeLine[i].texture = self.buffs.timeLine[i]:CreateTexture(nil, "BACKGROUND")
		self.buffs.timeLine[i].texture:SetTexture(1, 1, 1, 0.3)
		self.buffs.timeLine[i].texture:SetAllPoints()		
		
		self.buffs.timeLine[i].timeText = ExRT.lib.CreateText(self.buffs.timeLine[i],200,12,"TOPLEFT",4,-2,"RIGHT","TOP",nil,11,"",nil,1,1,1)
		ExRT.lib.SetPoint(self.buffs.timeLine[i].timeText,"TOPRIGHT",self.buffs.timeLine[i],"TOPLEFT",-1,-1)
	end
	
	self.buffs.redDeathLine = {}
	local function CreateRedDeathLine(i)
		if not self.buffs.redDeathLine[i] then
			self.buffs.redDeathLine[i] = self.tab.tabs[3]:CreateTexture(nil, "BACKGROUND",0,-4)
			self.buffs.redDeathLine[i]:SetTexture(1, 0.3, 0.3, 1)
			self.buffs.redDeathLine[i]:SetSize(2,374)
			self.buffs.redDeathLine[i]:Hide()
		end
	end
	
	self.buffs.linesRightClickMenu = {
		{ text = "Spell", isTitle = true, notCheckable = true, notClickable = true },
		{ text = ExRT.L.BossWatcherSendToChat, func = function() 
			if module.options.buffs.linesRightClickMenuData then
				local chat_type = ExRT.mds.chatType(true)
				SendChatMessage(module.options.buffs.linesRightClickMenuData[1],chat_type)
				for i=2,#module.options.buffs.linesRightClickMenuData do
					SendChatMessage(ExRT.mds.clearTextTag(module.options.buffs.linesRightClickMenuData[i]),chat_type)
				end
			end
		end, notCheckable = true },
		{ text = ExRT.L.minimapmenuclose, func = function() CloseDropDownMenus() end, notCheckable = true },
	}
	self.buffs.linesRightClickMenuDropDown = CreateFrame("Frame", self:GetName().."LinesRightClickMenuDropDown", nil, "UIDropDownMenuTemplate")
	
	local function BuffsLinesOnUpdate(self)
		local x,y = ExRT.mds.GetCursorPos(self)
		if x > 0 and x < buffsTotalWidth and y > 0 and y < 18 and not module.options.buffs.filterFrame:IsShown() then
			for j=1,20 do
				if module.options.buffs.lines[j] ~= self then
					module.options.buffs.lines[j].hl:Hide()
				end
			end
			self.hl:Show()
			if x <= buffsNameWidth then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				GameTooltip:SetHyperlink(self.spellLink)
				
				local uptime = 0
				local minLimit = 0
				local maxLimit = 0
				for j = 1,#self.greenTooltips do
					maxLimit = max(maxLimit,self.greenTooltips[j][2])
				end
				while true do
					local _min,_max = buffsTotalWidth,buffsNameWidth
					local bool = true
					for j = 1,#self.greenTooltips do
						if self.greenTooltips[j][1] < _min and self.greenTooltips[j][1] > minLimit then
							_min = min(_min,self.greenTooltips[j][1])
						end
					end
					for j = 1,#self.greenTooltips do
						if self.greenTooltips[j][1] <= _min then
							_max = max(_max,self.greenTooltips[j][2])
						end	
					end
					while bool == true do
						bool = false
						for j = 1,#self.greenTooltips do
							if self.greenTooltips[j][1] <= _max and _max < self.greenTooltips[j][2] then
								_max = max(_max,self.greenTooltips[j][2])
								bool = true
							end	
						end
					end
					uptime = uptime + (_max - _min)/470
					minLimit = _max
					if _max == maxLimit or _max <= buffsNameWidth then
						break
					end
				end
				
				GameTooltip:AddLine(ExRT.L.BossWatcherBuffsAndDebuffsTooltipUptimeText..": "..format("%.2f%%",uptime*100))
				GameTooltip:AddLine(ExRT.L.BossWatcherBuffsAndDebuffsTooltipCountText..": "..(self.greenCount or 0))
				GameTooltip:Show()
			else
				if not self.tooltip then
					self.tooltip = {}
				end
				table.wipe(self.tooltip)
				local owner = nil
				for j = 1,#self.greenTooltips do
					local rightPos = self.greenTooltips[j][2]
					local leftPos = self.greenTooltips[j][1]
					if rightPos - leftPos < 2 then
						rightPos = leftPos + 2
					end
					if x >= leftPos and x <= rightPos then
						local sourceClass = ExRT.mds.classColorByGUID(self.greenTooltips[j][5])
						local destClass = ExRT.mds.classColorByGUID(self.greenTooltips[j][6])
						local duration = (self.greenTooltips[j][4] - self.greenTooltips[j][3])
						table.insert(self.tooltip, date("[%M:%S", self.greenTooltips[j][3] ) .. format(".%03d",(self.greenTooltips[j][3]*1000)%1000).. "] " .. "|c" .. sourceClass .. module.db.guidsListFix[self.greenTooltips[j][5]]..GUIDtoText(" (%s)",self.greenTooltips[j][5]).."|r "..ExRT.L.BossWatcherBuffsAndDebuffsTextOn.." |c".. destClass .. module.db.guidsListFix[self.greenTooltips[j][6]]..GUIDtoText(" (%s)",self.greenTooltips[j][6]).."|r")
						if self.greenTooltips[j][7] and self.greenTooltips[j][7] ~= 1 then
							self.tooltip[#self.tooltip] = self.tooltip[#self.tooltip] .. " (".. self.greenTooltips[j][7] ..")"
						end
						self.tooltip[#self.tooltip] = self.tooltip[#self.tooltip] .. format(" <%.1fs>",duration)
						owner = self.greenTooltips[j][1]
					end
				end
				if #self.tooltip > 0 then
					table.sort(self.tooltip,function(a,b) return a < b end)
					ExRT.lib.TooltipShow(self,{"ANCHOR_LEFT",owner or 0,0},ExRT.L.BossWatcherBuffsAndDebuffsTooltipTitle..":",unpack(self.tooltip))
				else
					GameTooltip_Hide()
				end
			end
		end
	end
	local function BuffsLinesOnLeave(self)
		GameTooltip_Hide()
		self.hl:Hide()
	end
	local function BuffsLinesOnClick(self,button)
		local x,y = ExRT.mds.GetCursorPos(self)
		if x > 0 and x < buffsTotalWidth and y > 0 and y < 18 then
			if x <= buffsNameWidth then
				ExRT.mds.LinkSpell(nil,self.spellLink)
			elseif button == "RightButton" and GameTooltip:IsShown() then
				if module.options.buffs.linesRightClickMenuData then
					table_wipe(module.options.buffs.linesRightClickMenuData)
				else
					module.options.buffs.linesRightClickMenuData = {}
				end
				table.insert(module.options.buffs.linesRightClickMenuData , self.spellLink)
				for j=2, GameTooltip:NumLines() do
					table.insert(module.options.buffs.linesRightClickMenuData , _G["GameTooltipTextLeft"..j]:GetText())
				end
				module.options.buffs.linesRightClickMenu[1].text = self.spellName
				EasyMenu(module.options.buffs.linesRightClickMenu, module.options.buffs.linesRightClickMenuDropDown, "cursor", 10 , -15, "MENU")
			end
		end
	end
			
	self.buffs.lines = {}
	for i=1,20 do
		self.buffs.lines[i] = CreateFrame("Button",nil,self.tab.tabs[3])
		self.buffs.lines[i]:SetSize(buffsTotalWidth,18)
		self.buffs.lines[i]:SetPoint("TOPLEFT", 0, -18*(i-1)-54)
		
		self.buffs.lines[i].spellIcon = self.buffs.lines[i]:CreateTexture(nil, "BACKGROUND")
		self.buffs.lines[i].spellIcon:SetSize(16,16)
		self.buffs.lines[i].spellIcon:SetPoint("TOPLEFT", 5, -1)
		
		self.buffs.lines[i].spellText = ExRT.lib.CreateText(self.buffs.lines[i],(buffsNameWidth-23),18,"TOPLEFT",23,0,"LEFT","MIDDLE",nil,11,"",nil,1,1,1)
		
		self.buffs.lines[i].green = {}
		self.buffs.lines[i].greenFrame = {}
		self.buffs.lines[i].greenCount = 0
		
		self.buffs.lines[i].greenTooltips = {}
		
		ExRT.lib.CreateHoverHighlight(self.buffs.lines[i])
		self.buffs.lines[i].hl:SetAlpha(.5)
		
		self.buffs.lines[i]:SetScript("OnUpdate", BuffsLinesOnUpdate) 
		self.buffs.lines[i]:SetScript("OnLeave", BuffsLinesOnLeave)
		self.buffs.lines[i]:RegisterForClicks("RightButtonUp","LeftButtonUp")
		self.buffs.lines[i]:SetScript("OnClick", BuffsLinesOnClick)
	end
	
	self.buffs.scrollBar = ExRT.lib.CreateScrollBar2(self:GetName().."BuffsScrollBar",self.tab.tabs[3],16,360,-4,-54,1,2,"TOPRIGHT")
	
	local function CreateBuffGreen(i,j)
		module.options.buffs.lines[i].green[j] = module.options.buffs.lines[i]:CreateTexture(nil, "BACKGROUND",nil,5)
		module.options.buffs.lines[i].green[j]:SetTexture(0.1, 0.7, 0.1, 0.7)
		module.options.buffs.lines[i].greenFrame[j] = CreateFrame("Frame",nil,module.options.buffs.lines[i])
	end
	
	local function CreateFilterText()
		local result = ExRT.L.BossWatcherBuffsAndDebuffsFilterSource..": "
		if not module.options.buffs.filterS then
			result = result .. ExRT.L.BossWatcherBuffsAndDebuffsFilterAll
		elseif module.options.buffs.filterS == 1 then
			result = result .. ExRT.L.BossWatcherBuffsAndDebuffsFilterFriendly
		elseif module.options.buffs.filterS == 2 then
			result = result .. ExRT.L.BossWatcherBuffsAndDebuffsFilterHostile
		else 
			result = result .. (module.db.guidsListFix[module.options.buffs.filterS])
		end
		result = result .. "; "..ExRT.L.BossWatcherBuffsAndDebuffsFilterTarget..": "
		if not module.options.buffs.filterD then
			result = result .. ExRT.L.BossWatcherBuffsAndDebuffsFilterAll
		elseif module.options.buffs.filterD == 1 then
			result = result .. ExRT.L.BossWatcherBuffsAndDebuffsFilterFriendly
		elseif module.options.buffs.filterD == 2 then
			result = result .. ExRT.L.BossWatcherBuffsAndDebuffsFilterHostile
		else 
			result = result .. (module.db.guidsListFix[module.options.buffs.filterD])
		end			
		result = result .. ";"
		
		local isSpecial = nil
		for i=1,#module.db.buffsFilters do
			if module.db.buffsFilterStatus[i] then
				isSpecial = true
				break
			end
		end
		if isSpecial then
			result = result .. " "..ExRT.L.BossWatcherBuffsAndDebuffsFilterSpecial..":"
			for i=1,#module.db.buffsFilters do
				if module.db.buffsFilterStatus[i] then
					result = result .. " " .. strlower(module.db.buffsFilters[i][-1]) .. ";"
				end
			end
		end
		module.options.buffs.filterText:SetText(result)
	end
	
	function UpdateBuffPageDB()
		for i=1,10 do
			self.buffs.timeLine[i+1].timeText:SetText( date("%M:%S", (module.db.encounterEnd - module.db.encounterStart)*(i/10) ) )
		end
		
		if not module.db.fightData.buffs then
			module.db.fightData.buffs = {}
		end
		
		local fightDuration = (module.db.encounterEnd - module.db.encounterStart)
		local buffTable = {}
		for i,sourceData in ipairs(module.db.fightData.buffs) do 
			local spellID = sourceData[6]
			local spellName,_,spellTexture = GetSpellInfo(spellID)
			if (not module.options.buffs.filterS or (module.options.buffs.filterS == 1 and sourceData[4]) or (module.options.buffs.filterS == 2 and not sourceData[4]) or module.options.buffs.filterS == sourceData[2]) and 
				(not module.options.buffs.filterD or (module.options.buffs.filterD == 1 and sourceData[5]) or (module.options.buffs.filterD == 2 and not sourceData[5]) or module.options.buffs.filterD == sourceData[3]) and 
				(not module.db.buffsFilterStatus[1] or sourceData[7] == 'BUFF') and
				(not module.db.buffsFilterStatus[2] or sourceData[7] == 'DEBUFF') and
				(not module.db.buffsFilterStatus[3] or module.db.buffsFilters[3][spellID]) and
				(not module.db.buffsFilterStatus[4] or not module.db.buffsFilters[4].name or strlower(module.db.buffsFilters[4].name) == strlower(spellName)) and
				(not module.db.buffsFilterStatus[5] or module.db.buffsFilters[5][spellID]) and 
				(not module.db.buffsFilterStatus[6] or module.db.buffsFilters[6][spellID]) and
				(not module.db.buffsFilterStatus[7] or module.db.buffsFilters[7][spellID]) and
				(not module.db.buffsFilterStatus[8] or module.db.buffsFilters[8][spellID]) and
				(not module.db.buffsFilterStatus[9] or module.db.buffsFilters[9][spellID]) and
				(not module.db.buffsFilterStatus[10] or module.db.buffsFilters[10][spellID]) and
				(not module.db.buffsFilterStatus[11] or module.db.buffsFilters[11][spellID]) then
				
				local time_ = timestampToFightTime( sourceData[1] )
				local time_postion = time_ / fightDuration
				local type_ = sourceData[8]
				
				local buffTablePos
				for j=1,#buffTable do
					if buffTable[j][1] == spellID then
						buffTablePos = j
						break
					end
				end
				if not buffTablePos then
					buffTablePos = #buffTable + 1
					buffTable[buffTablePos] = {spellID,spellName,spellTexture,{},{}}
				end
				
				local sourceGUID = sourceData[2] or 0
				local destGUID = sourceData[3] or 0
				local sourceDest = sourceGUID .. destGUID
				local buffTableBuffPos
				for j=1,#buffTable[buffTablePos][4] do
					if buffTable[buffTablePos][4][j][1] == sourceDest then
						buffTableBuffPos = j
						break
					end
				end
				if not buffTableBuffPos then
					buffTableBuffPos = #buffTable[buffTablePos][4] + 1
					buffTable[buffTablePos][4][buffTableBuffPos] = {sourceDest,sourceGUID,destGUID,{}}
				end
				
				local eventPos = #buffTable[buffTablePos][4][buffTableBuffPos][4] + 1
				
				if type_ == 3 or type_ == 4 then
					buffTable[buffTablePos][4][buffTableBuffPos][4][eventPos] = {0,time_,time_postion,sourceData[9] or 1}
					type_ = 1
					eventPos = eventPos + 1
				end
				buffTable[buffTablePos][4][buffTableBuffPos][4][eventPos] = {type_ % 2,time_,time_postion,sourceData[9] or 1}
			end
		end
		
		table.sort(buffTable,function(a,b) return a[2] < b[2] end)
		
		for i=1,#buffTable do 
			for j=1,#buffTable[i][4] do
				local maxEvents = #buffTable[i][4][j][4]
				if maxEvents > 0 and buffTable[i][4][j][4][1][1] == 0 then
					local newLine = #buffTable[i][5] + 1
					buffTable[i][5][newLine] = {
						buffsNameWidth,
						buffsNameWidth+470*buffTable[i][4][j][4][1][3],
						0,
						buffTable[i][4][j][4][1][2],
						buffTable[i][4][j][2],
						buffTable[i][4][j][3],
						1,
					}
				end
				for k=1,maxEvents do
					if buffTable[i][4][j][4][k][1] == 1 then
						local endOfTime = nil
						for n=(k+1),maxEvents do
							if buffTable[i][4][j][4][n][1] == 0 and not endOfTime then
								endOfTime = n
								--break
							end
						end
						local newLine = #buffTable[i][5] + 1
						buffTable[i][5][newLine] = {
							buffsNameWidth+470*buffTable[i][4][j][4][k][3],
							buffsNameWidth+470*(endOfTime and buffTable[i][4][j][4][endOfTime][3] or 1),
							buffTable[i][4][j][4][k][2],
							endOfTime and buffTable[i][4][j][4][endOfTime][2] or fightDuration,
							buffTable[i][4][j][2],
							buffTable[i][4][j][3],
							buffTable[i][4][j][4][k][4],
						}
						--startPos,endPos,startTime,endTime,sourceGUID,destGUID,stacks
					end
				end
			end
		end
		
		--> Death Line
		for i=1,#module.options.buffs.redDeathLine do
			module.options.buffs.redDeathLine[i]:Hide()
		end
		if type(module.options.buffs.filterD) == "string" and module.options.buffs.filterD ~= "" then
			local j = 0
			for i=1,#module.db.fightData.dies do
				if module.db.fightData.dies[i][1] == module.options.buffs.filterD then
					j = j + 1
					CreateRedDeathLine(j)
					local time_ = timestampToFightTime( module.db.fightData.dies[i][3] )
					local pos = buffsNameWidth + time_/fightDuration*470 - 1
					module.options.buffs.redDeathLine[j]:SetPoint("TOPLEFT",pos,-42)
					module.options.buffs.redDeathLine[j]:Show()
				end
			end
		end
		
		module.options.buffs.scrollBar:SetValue(1)
		module.options.buffs.scrollBar:SetMinMaxValues(1,max(#buffTable-20,1))
		if module.options.buffs.db then
			table_wipe(module.options.buffs.db)
		end
		
		module.options.buffs.db = buffTable
		
		ExRT.mds.ScheduleTimer(collectgarbage, 1, "collect")
	end
	
	local function UpdateBuffsPage()
		CreateFilterText()
		if not module.options.buffs.db then
			return
		end
		
		local minVal = ExRT.mds.Round(module.options.buffs.scrollBar:GetValue())
		local buffTable2 = module.options.buffs.db
		
		local linesCount = 0
		for i=1,20 do
			for j=1,module.options.buffs.lines[i].greenCount do
				module.options.buffs.lines[i].green[j]:Hide()
			end
			module.options.buffs.lines[i].greenCount = 0
			table.wipe(module.options.buffs.lines[i].greenTooltips)
		end
		for i=minVal,#buffTable2 do
			linesCount = linesCount + 1
			local Line = module.options.buffs.lines[linesCount]
			Line.spellIcon:SetTexture(buffTable2[i][3])
			Line.spellText:SetText(buffTable2[i][2] or "???")
			Line.spellLink = GetSpellLink(buffTable2[i][1])
			Line.spellName = buffTable2[i][2] or "Spell"
			
			for j=1,#buffTable2[i][5] do
				Line.greenCount = Line.greenCount + 1
				local n = Line.greenCount

				if not Line.green[n] then
					CreateBuffGreen(linesCount,n)
				end
				
				Line.green[n]:SetPoint("TOPLEFT",buffTable2[i][5][j][1],0)
				Line.green[n]:SetSize(max(buffTable2[i][5][j][2]-buffTable2[i][5][j][1],0.1),18)
				Line.green[n]:Show()
				
				Line.greenTooltips[#Line.greenTooltips+1] = buffTable2[i][5][j]
			end

			Line:Show()
			if linesCount >= 20 then
				break
			end
		end
		for i=(linesCount+1),20 do
			module.options.buffs.lines[i]:Hide()
		end
		module.options.buffs.scrollBar.reButtonsState(module.options.buffs.scrollBar)
	end
	
	self.tab.tabs[3]:SetScript("OnShow",function (self)
		if self.lastFightID ~= module.db.lastFightID then
			UpdateBuffPageDB()
			self.lastFightID = module.db.lastFightID
		end
		UpdateBuffsPage()
	end)

	self.buffs.scrollBar:SetScript("OnValueChanged",UpdateBuffsPage)
	self.tab.tabs[3]:SetScript("OnMouseWheel",function (self,delta)
		if delta > 0 then
			module.options.buffs.scrollBar.buttonUP:Click("LeftButton")
		else
			module.options.buffs.scrollBar.buttonDown:Click("LeftButton")
		end
	end)

	self.buffs.filterFrame = ExRT.lib.CreatePopupFrame(self:GetName().."BuffsFilterFrame",570,400,ExRT.L.BossWatcherBuffsAndDebuffsFilterFilter)
	
	local function UpdateTargetsList(self,isSourceFrame,friendly,hostile)
		table.wipe(self.L)
		table.wipe(self.LGUID)
		if isSourceFrame then
			isSourceFrame = 4
		else
			isSourceFrame = 5
		end
		local list = {}
		for i=1,#module.db.fightData.buffs do
			local sourceData = module.db.fightData.buffs[i]
			local sourceGUID
			if isSourceFrame == 4 then
				sourceGUID = (friendly and sourceData[isSourceFrame] and sourceData[2]) or (hostile and not sourceData[isSourceFrame] and sourceData[2])
			elseif isSourceFrame == 5 then
				sourceGUID = (friendly and sourceData[isSourceFrame] and sourceData[3]) or (hostile and not sourceData[isSourceFrame] and sourceData[3])
			end
			if sourceGUID then
				local inList = nil
				for j=1,#list do
					if list[j][1] == sourceGUID then
						inList = true
						break
					end
				end
				if not inList then
					list[#list+1] = {sourceGUID,module.db.guidsListFix[sourceGUID],"|c"..ExRT.mds.classColorByGUID(sourceGUID)}
				end
			end
		end

		table.sort(list,function(a,b) 
			if a[2] == b[2] then
				return a[1] < b[1]
			else
				return a[2] < b[2] 
			end
		end)
		
		for i=1,#list do
			self.L[i] = list[i][3] .. list[i][2] 
			self.LGUID[i] = list[i][1]
		end
		self.Update()
	end
	
	self.buffs.filterFrame:SetScript("OnShow",function()
		UpdateTargetsList(self.buffs.filterFrame.sourceScroll,true,self.buffs.filterFrame.sourceFriendly:GetChecked(),self.buffs.filterFrame.sourceHostile:GetChecked())
		UpdateTargetsList(self.buffs.filterFrame.targetScroll,nil,self.buffs.filterFrame.targetFriendly:GetChecked(),self.buffs.filterFrame.targetHostile:GetChecked())
	end)
	
	self.buffs.filterFrame.sourceScroll = ExRT.lib.CreateScrollList(self:GetName().."BuffsFilterFrameSourceScroll",self.buffs.filterFrame,nil,10,-62,190,17)
	self.buffs.filterFrame.sourceScroll.LGUID = {}
	self.buffs.filterFrame.sourceScroll.dontDisable = true
	
	self.buffs.filterFrame.sourceClear = ExRT.lib.CreateButton(nil,self.buffs.filterFrame,190,16,nil,10,-30,ExRT.L.BossWatcherBuffsAndDebuffsFilterClear)
	self.buffs.filterFrame.sourceClear:SetScript("OnClick",function ()
		module.options.buffs.filterS = nil
		module.options.buffs.filterFrame.sourceFriendly:SetChecked(true)
		module.options.buffs.filterFrame.sourceFriendly:SetChecked(true)
		UpdateTargetsList(module.options.buffs.filterFrame.sourceScroll,true,module.options.buffs.filterFrame.sourceFriendly:GetChecked(),module.options.buffs.filterFrame.sourceHostile:GetChecked())
		module.options.buffs.filterFrame.sourceText:SetText(ExRT.L.BossWatcherBuffsAndDebuffsFilterNone)
		UpdateBuffPageDB()
		UpdateBuffsPage()
	end)
	self.buffs.filterFrame.sourceText = ExRT.lib.CreateText(self.buffs.filterFrame,180,16,nil,15,-46,"LEFT","MIDDLE",nil,11,ExRT.L.BossWatcherBuffsAndDebuffsFilterNone,nil,1,1,1)
	
	self.buffs.filterFrame.sourceFriendly = ExRT.lib.CreateCheckBox(self:GetName().."BuffsFilterFrameSourceCheckFriendly",self.buffs.filterFrame,nil,10,-338,ExRT.L.BossWatcherBuffsAndDebuffsFilterFriendly,true)
	self.buffs.filterFrame.sourceHostile = ExRT.lib.CreateCheckBox(self:GetName().."BuffsFilterFrameSourceCheckHostile",self.buffs.filterFrame,nil,10,-363,ExRT.L.BossWatcherBuffsAndDebuffsFilterHostile,true)
	self.buffs.filterFrame.sourceFriendly:SetScript("OnClick",function ()
		UpdateTargetsList(self.buffs.filterFrame.sourceScroll,true,self.buffs.filterFrame.sourceFriendly:GetChecked(),self.buffs.filterFrame.sourceHostile:GetChecked())
		if self.buffs.filterFrame.sourceFriendly:GetChecked() then
			module.options.buffs.filterS = 1
		end
		if self.buffs.filterFrame.sourceHostile:GetChecked() then
			if module.options.buffs.filterS == 1 then
				module.options.buffs.filterS = nil
			else
				module.options.buffs.filterS = 2
			end
		end
		UpdateBuffPageDB()
		UpdateBuffsPage()
	end)
	self.buffs.filterFrame.sourceHostile:SetScript("OnClick",self.buffs.filterFrame.sourceFriendly:GetScript("OnClick"))
	
	function self.buffs.filterFrame.sourceScroll:SetListValue(index)
		module.options.buffs.filterS = module.options.buffs.filterFrame.sourceScroll.LGUID[index]
		module.options.buffs.filterFrame.sourceText:SetText(module.options.buffs.filterFrame.sourceScroll.L[index])
		UpdateBuffPageDB()
		UpdateBuffsPage()
	end
	
	function self.buffs.filterFrame.sourceScroll:HoverListValue(isHover,index)
		if not isHover then
			GameTooltip_Hide()
		else
			local owner,ownerGUID,thisGUID
			if ExRT.mds.Pets then
				owner = ExRT.mds.Pets:getOwnerNameByGUID(self.LGUID[index])
			end		
			if VExRT.BossWatcher.GUIDs then
				thisGUID = self.LGUID[index]
				if ExRT.mds.Pets then
					ownerGUID = ExRT.mds.Pets:getOwnerGUID(self.LGUID[index])
				end
			end
			if owner or thisGUID then
				GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
				if thisGUID then
					GameTooltip:AddLine(thisGUID)
				end
				if owner then
					GameTooltip:AddLine( format(ExRT.L.BossWatcherPetOwner,owner) .. GUIDtoText(" (%s)",ownerGUID) )
				end
				GameTooltip:Show()
			end
		end
	end

	self.buffs.filterFrame.targetScroll = ExRT.lib.CreateScrollList(self:GetName().."BuffsFilterFrameTargetScroll",self.buffs.filterFrame,nil,210,-62,190,17)
	self.buffs.filterFrame.targetScroll.LGUID = {}
	self.buffs.filterFrame.targetScroll.dontDisable = true
	
	self.buffs.filterFrame.targetClear = ExRT.lib.CreateButton(nil,self.buffs.filterFrame,190,16,nil,210,-30,ExRT.L.BossWatcherBuffsAndDebuffsFilterClear)
	self.buffs.filterFrame.targetClear:SetScript("OnClick",function ()
		module.options.buffs.filterD = nil
		module.options.buffs.filterFrame.targetFriendly:SetChecked(true)
		module.options.buffs.filterFrame.targetFriendly:SetChecked(true)
		UpdateTargetsList(module.options.buffs.filterFrame.targetScroll,nil,module.options.buffs.filterFrame.targetFriendly:GetChecked(),module.options.buffs.filterFrame.targetHostile:GetChecked())
		module.options.buffs.filterFrame.targetText:SetText(ExRT.L.BossWatcherBuffsAndDebuffsFilterNone)
		UpdateBuffPageDB()
		UpdateBuffsPage()
	end)
	self.buffs.filterFrame.targetText = ExRT.lib.CreateText(self.buffs.filterFrame,180,16,nil,215,-46,"LEFT","MIDDLE",nil,11,ExRT.L.BossWatcherBuffsAndDebuffsFilterNone,nil,1,1,1)

	self.buffs.filterFrame.targetFriendly = ExRT.lib.CreateCheckBox(self:GetName().."BuffsFilterFrameTargetCheckFriendly",self.buffs.filterFrame,nil,210,-338,ExRT.L.BossWatcherBuffsAndDebuffsFilterFriendly,true)
	self.buffs.filterFrame.targetHostile = ExRT.lib.CreateCheckBox(self:GetName().."BuffsFilterFrameTargetCheckHostile",self.buffs.filterFrame,nil,210,-363,ExRT.L.BossWatcherBuffsAndDebuffsFilterHostile,true)
	self.buffs.filterFrame.targetFriendly:SetScript("OnClick",function ()
		UpdateTargetsList(self.buffs.filterFrame.targetScroll,nil,self.buffs.filterFrame.targetFriendly:GetChecked(),self.buffs.filterFrame.targetHostile:GetChecked())
		if self.buffs.filterFrame.targetFriendly:GetChecked() then
			module.options.buffs.filterD = 1
		end
		if self.buffs.filterFrame.targetHostile:GetChecked() then
			if module.options.buffs.filterD == 1 then
				module.options.buffs.filterD = nil
			else
				module.options.buffs.filterD = 2
			end
		end
		UpdateBuffPageDB()
		UpdateBuffsPage()
	end)
	self.buffs.filterFrame.targetHostile:SetScript("OnClick",self.buffs.filterFrame.targetFriendly:GetScript("OnClick"))

	function self.buffs.filterFrame.targetScroll:SetListValue(index)
		module.options.buffs.filterD = module.options.buffs.filterFrame.targetScroll.LGUID[index]
		module.options.buffs.filterFrame.targetText:SetText(module.options.buffs.filterFrame.targetScroll.L[index])
		UpdateBuffPageDB()
		UpdateBuffsPage()
	end
	
 	self.buffs.filterFrame.targetScroll.HoverListValue = self.buffs.filterFrame.sourceScroll.HoverListValue
	
	local function BuffsFilterFrameChkHover(self)
		local i = self.frameNum
		if i == 4 then
			return
		end
		local sList = module.db.buffsFilters[i][-2]
		if not sList then
			sList = {}
			for sid,_ in pairs(module.db.buffsFilters[i]) do
				if sid > 0 then
					sList[#sList + 1] = sid
				end
			end
		end
		if #sList == 0 then
			return
		end
		local sList2 = {}
		if #sList <= 35 then
			for j=1,#sList do
				local sID,_,sT=GetSpellInfo(sList[j])
				if sID then
					sList2[#sList2 + 1] = "|T"..sT..":0|t |cffffffff"..sID.."|r"
				end
			end
		else
			local count = 1
			for j=1,#sList do
				local sID,_,sT=GetSpellInfo(sList[j])
				if sID then
					if not sList2[count] then
						sList2[count] = {"|T"..sT..":0|t |cffffffff"..sID.."|r"}
					elseif not sList2[count].right then
						sList2[count].right = "|cffffffff"..sID.."|r |T"..sT..":0|t"
						count = count + 1
					end
				end
			end
		end
		ExRT.lib.TooltipShow(self,"ANCHOR_LEFT",ExRT.L.BossWatcherFilterTooltip..":",unpack(sList2))
	end
	local function BuffsFilterFrameResetEditBoxBuff(i)
		local resetTable = {}
		for sID,_ in pairs(module.db.buffsFilters[i]) do
			if sID > 0 then
				resetTable[#resetTable + 1] = sID
			end
		end
		for _,sID in ipairs(resetTable) do
			module.db.buffsFilters[i][sID] = nil
		end
	end
	
	local function BuffsFilterFrameChkSpecialClick(self)
		if self:GetChecked() then
			module.db.buffsFilterStatus[self._i] = true
		else
			module.db.buffsFilterStatus[self._i] = nil
		end
		UpdateBuffPageDB()
		UpdateBuffsPage()
	end
	
	self.buffs.filterFrame.chkSpecial = {}
	for i=1,#module.db.buffsFilters do
		self.buffs.filterFrame.chkSpecial[i] = ExRT.lib.CreateCheckBox(nil,self.buffs.filterFrame,nil,400,-30-(i-1)*25,module.db.buffsFilters[i][-1])
		self.buffs.filterFrame.chkSpecial[i]._i = i
		self.buffs.filterFrame.chkSpecial[i]:SetScript("OnClick",BuffsFilterFrameChkSpecialClick)
		self.buffs.filterFrame.chkSpecial[i].hover = CreateFrame("Frame",nil,self.buffs.filterFrame)
		self.buffs.filterFrame.chkSpecial[i].hover:SetPoint("TOPLEFT",430,-35-(i-1)*25)
		self.buffs.filterFrame.chkSpecial[i].hover:SetSize(125,25)
		self.buffs.filterFrame.chkSpecial[i].hover:SetScript("OnEnter",BuffsFilterFrameChkHover)
		self.buffs.filterFrame.chkSpecial[i].hover:SetScript("OnLeave",GameTooltip_Hide)
		self.buffs.filterFrame.chkSpecial[i].hover.frameNum = i
	end
	self.buffs.filterFrame.chkSpecial[3].ebox = ExRT.lib.CreateEditBox(self:GetName().."BuffsFilterFrameCheckSpecial3eBox",self.buffs.filterFrame.chkSpecial[3],80,24,nil,78,-2,nil,6,true,"InputBoxTemplate","0")
	self.buffs.filterFrame.chkSpecial[3].ebox:SetScript("OnTextChanged",function (self)
		local t = tonumber(self:GetText() or 0)
		BuffsFilterFrameResetEditBoxBuff(3)
		if t then
			module.db.buffsFilters[3][t] = true
			if module.options.buffs.filterFrame.chkSpecial[3]:GetChecked() then
				UpdateBuffPageDB()
				UpdateBuffsPage()
			end
		end
	end)
	
	self.buffs.filterFrame.chkSpecial[4].ebox = ExRT.lib.CreateEditBox(self:GetName().."BuffsFilterFrameCheckSpecial4eBox",self.buffs.filterFrame.chkSpecial[4],65,24,nil,93,-2,nil,nil,nil,"InputBoxTemplate","")
	self.buffs.filterFrame.chkSpecial[4].ebox:SetScript("OnTextChanged",function (self)
		local t = self:GetText()
		if t and t ~= "" then
			module.db.buffsFilters[4].name = t
		else
			module.db.buffsFilters[4].name = nil
		end
		if module.options.buffs.filterFrame.chkSpecial[4]:GetChecked() then
			UpdateBuffPageDB()
			UpdateBuffsPage()
		end
	end)
	
	self.buffs.filterButton = ExRT.lib.CreateButton(nil,self.tab.tabs[3],100,22,nil,5,-10,ExRT.L.BossWatcherBuffsAndDebuffsFilterFilter)
	self.buffs.filterButton:SetScript("OnClick",function ()
		module.options.buffs.filterFrame:Show()
	end)
	
	self.buffs.filterText = ExRT.lib.CreateText(self.tab.tabs[3],500,22,nil,110,-10,"LEFT","CENTER",nil,nil,"",nil,1,1,1,1)
	CreateFilterText()
	
	--> Tab Spells
	
	self.playersList = ExRT.lib.CreateScrollList(self:GetName().."PlayersList",self.tab.tabs[4],"LEFT",5,0,180,25)
	self.playersCastsList = ExRT.lib.CreateScrollList(self:GetName().."PlayersCastsList",self.tab.tabs[4],"LEFT",185,0,423,25)
	self.playersList.IndexToGUID = {}
	self.playersCastsList.IndexToGUID = {}
	
	function self.playersList:HoverListValue(isHover,index)
		if not isHover then
			GameTooltip_Hide()
		else
			GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
			if VExRT.BossWatcher.GUIDs then
				GameTooltip:AddLine(module.options.playersList.IndexToGUID[index])
			end
			GameTooltip:Show()
		end
	end
	function self.playersCastsList:HoverListValue(isHover,index)
		if not isHover then
			GameTooltip_Hide()
			ExRT.lib.HideAdditionalTooltips()
			
			module.options.timeLine.arrow:Hide()
		else
			local scrollPos = ExRT.mds.Round(module.options.playersCastsList.ScrollBar:GetValue())
			local this = module.options.playersCastsList.List[index - scrollPos + 1]
			
			GameTooltip:SetOwner(this or self,"ANCHOR_BOTTOMLEFT")
			GameTooltip:SetHyperlink(module.options.playersCastsList.IndexToGUID[index][1])
			GameTooltip:Show()
			
			if this.text:GetStringWidth() > 380 then
				ExRT.lib.AdditionalTooltip(nil,{this.text:GetText()})
			end
			
			module.options.timeLine.arrow:SetPoint("TOPLEFT",module.options.timeLine,"BOTTOMLEFT",600*module.options.playersCastsList.IndexToGUID[index][2],0)
			module.options.timeLine.arrow:Show()
		end
	end
	
	function self.playersList:SetListValue(index)
		table.wipe(module.options.playersCastsList.L)
		table.wipe(module.options.playersCastsList.IndexToGUID)
		
		local selfGUID = module.options.playersList.IndexToGUID[index]
		local fight_dur = module.db.encounterEnd - module.db.encounterStart
		
		for i,PlayerCastData in ipairs(module.db.fightData.players_cast) do
			if selfGUID == PlayerCastData[1] then
				local spellName,_,spellTexture = GetSpellInfo(PlayerCastData[3])
				local time_ = timestampToFightTime(PlayerCastData[4])
				module.options.playersCastsList.L[#module.options.playersCastsList.L + 1] = format("[%02d:%06.3f] ",time_ / 60,time_ % 60)..format("%s%s",spellTexture and "|T"..spellTexture..":0|t " or "",spellName or "???")
				module.options.playersCastsList.IndexToGUID[#module.options.playersCastsList.IndexToGUID + 1] = {"spell:"..PlayerCastData[3],time_ / fight_dur,PlayerCastData[3]}
				
				if PlayerCastData[2] and PlayerCastData[2] ~= "" then
					module.options.playersCastsList.L[#module.options.playersCastsList.L] = module.options.playersCastsList.L[#module.options.playersCastsList.L] .. " > |c"..ExRT.mds.classColorByGUID(PlayerCastData[2])..module.db.guidsListFix[ PlayerCastData[2] ]..GUIDtoText(" <%s>",PlayerCastData[2]).."|r"
				end
			end
		end
		
		module.options.playersCastsList.Update()		
	end
	function self.playersCastsList:SetListValue(index)
		for j=1,self.linesNum do
			self.List[j]:SetEnabled(true)
		end
		self.selected = nil
		
		local sID = self.IndexToGUID[index][3]
		if self.redSpell == sID then
			self.redSpell = nil
		else
			self.redSpell = sID
		end
		self.Update()
	end
	function self.playersCastsList:UpdateAdditional(scrollPos)
		for j=1,self.linesNum do
			local index = self.List[j].index
			if self.redSpell and index and self.IndexToGUID[index] and self.IndexToGUID[index][3] == self.redSpell then
				self.List[j].text:SetTextColor(1,0.2,0.2,1)
			else
				self.List[j].text:SetTextColor(1,1,1,1)
			end
		end
	end	
	--> Tab Energy
	
	self.energy = {}
	self.energy.sourceList = ExRT.lib.CreateScrollList(self:GetName().."EnergySourceList",self.tab.tabs[5],"TOPLEFT",5,-10,180,18)
	self.energy.sourceList.IndexToGUID = {}
	self.energy.powerTypeList = ExRT.lib.CreateScrollList(self:GetName().."EnergyPowerTypeList",self.tab.tabs[5],"TOPLEFT",5,-310,180,6)
	self.energy.powerTypeList.IndexToGUID = {}
	
	local function EnergyLineOnEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetHyperlink("spell:"..self.spellID)
		GameTooltip:Show()
	end
	
	self.energy.text = ExRT.lib.CreateText(self.tab.tabs[5],420,self.tab.tabs[5]:GetHeight()-10,nil,185,-5,"LEFT","TOP",nil,11,nil,nil,1,1,1,1)
	self.energy.spells = {}
	for i=1,14 do
		self.energy.spells[i] = CreateFrame("Frame",nil,self.tab.tabs[5])
		self.energy.spells[i]:SetPoint("TOPLEFT",190,-10-28*(i-1))
		self.energy.spells[i]:SetSize(420,28)
		
		self.energy.spells[i].texture = self.energy.spells[i]:CreateTexture(nil,"BACKGROUND")
		self.energy.spells[i].texture:SetSize(24,24)
		self.energy.spells[i].texture:SetPoint("TOPLEFT",0,-2)
		
		self.energy.spells[i].spellName = ExRT.lib.CreateText(self.energy.spells[i],225,28,nil,26,0,"LEFT","MIDDLE",nil,13,nil,nil,1,1,1,1)
		self.energy.spells[i].amount = ExRT.lib.CreateText(self.energy.spells[i],90,28,nil,250,0,"LEFT","MIDDLE",nil,12,nil,nil,1,1,1,1)
		self.energy.spells[i].count = ExRT.lib.CreateText(self.energy.spells[i],80,28,nil,340,0,"LEFT","MIDDLE",nil,12,nil,nil,1,1,1,1)
		
		self.energy.spells[i]:SetScript("OnEnter",EnergyLineOnEnter)
		self.energy.spells[i]:SetScript("OnLeave",GameTooltip_Hide)
	end
	
	local function EnergyClearLines()
		for i=1,#self.energy.spells do
			self.energy.spells[i]:Hide()
		end
	end
	
	function self.energy.sourceList:SetListValue(index)
		table.wipe(module.options.energy.powerTypeList.L)
		table.wipe(module.options.energy.powerTypeList.IndexToGUID)

		local sourceGUID = module.options.energy.sourceList.IndexToGUID[index]
		module.options.energy.sourceGUID = sourceGUID
		local powerList = {}
		for powerType,powerData in pairs(module.db.fightData.energy[sourceGUID]) do
			powerList[#powerList + 1] = {powerType,module.db.energyLocale[ powerType ] or ExRT.L.BossWatcherEnergyTypeUnknown..powerType}
		end
		table.sort(powerList,function (a,b) return a[1] < b[1] end)
		for i,powerData in ipairs(powerList) do
			module.options.energy.powerTypeList.L[i] = powerData[2]
			module.options.energy.powerTypeList.IndexToGUID[i] = powerData[1]
		end
		
		module.options.energy.powerTypeList.selected = nil
		module.options.energy.powerTypeList.Update()
		EnergyClearLines()
	end
	function self.energy.powerTypeList:SetListValue(index)
		local powerType = module.options.energy.powerTypeList.IndexToGUID[index]
		local sourceGUID = module.options.energy.sourceGUID
		
		local spellList = {}
		for spellID,spellData in pairs(module.db.fightData.energy[sourceGUID][powerType]) do
			local spellName,_,spellTexture = GetSpellInfo(spellID)
			spellList[#spellList + 1] = {spellID,spellName,spellTexture,spellData[1],spellData[2]}
		end
		table.sort(spellList,function (a,b) return a[4] > b[4] end)
		EnergyClearLines()
		for i,spellData in ipairs(spellList) do
			local line = module.options.energy.spells[i]
			if line then
				line.texture:SetTexture(spellData[3])
				line.spellName:SetText(spellData[2])
				line.amount:SetText(spellData[4])
				line.count:SetText(spellData[5].." |4"..ExRT.L.BossWatcherEnergyOnce1..":"..ExRT.L.BossWatcherEnergyOnce2..":"..ExRT.L.BossWatcherEnergyOnce1)
				line.spellID = spellData[1]
				line:Show()
			end
		end
	end

	local function EnergyPageUpdate()
		table.wipe(module.options.energy.sourceList.L)
		table.wipe(module.options.energy.sourceList.IndexToGUID)
		table.wipe(module.options.energy.powerTypeList.L)
		table.wipe(module.options.energy.powerTypeList.IndexToGUID)
		local sourceListTable = {}
		for sourceGUID,sourceData in pairs(module.db.fightData.energy) do
			sourceListTable[#sourceListTable + 1] = {sourceGUID,module.db.guidsListFix[ sourceGUID ],"|c"..ExRT.mds.classColorByGUID(sourceGUID)}
		end
		table.sort(sourceListTable,function (a,b) return a[2] < b[2] end)
		for i,sourceData in ipairs(sourceListTable) do
			module.options.energy.sourceList.L[i] = sourceData[3]..sourceData[2]
			module.options.energy.sourceList.IndexToGUID[i] = sourceData[1]
		end
		
		module.options.energy.sourceList.selected = nil
		module.options.energy.powerTypeList.selected = nil
		
		module.options.energy.sourceList.Update()
		module.options.energy.powerTypeList.Update()
		EnergyClearLines()
	end
	
	--> Tab Overkills
	self.overkillData = {}
	local function ReloadOverkillBox(val)
		table_wipe(self.overkillData)
		for i=val,#module.db.fightData.overkill do
			local spellName,_,spellTexture = GetSpellInfo(module.db.fightData.overkill[i][5])
			local sourceName = module.db.guidsListFix[ module.db.fightData.overkill[i][1] ]
			local destName = module.db.guidsListFix[ module.db.fightData.overkill[i][2] ]
			self.overkillData [#self.overkillData + 1] = "[".. date("%M:%S", timestampToFightTime(module.db.fightData.overkill[i][4])).."] |c" ..ExRT.mds.classColorByGUID(module.db.fightData.overkill[i][1]) .. sourceName .. GUIDtoText(" (%s)",module.db.fightData.overkill[i][1]) .. "|r "..ExRT.L.BossWatcherOverkillText.." |c"..ExRT.mds.classColorByGUID(module.db.fightData.overkill[i][2]) .. destName .. GUIDtoText(" (%s)",module.db.fightData.overkill[i][2]) .. "|r " .. ExRT.L.BossWatcherOverkillWithText .. "|Hspell:".. (module.db.fightData.overkill[i][5] or 0) .. "|h" ..  format(" %s%s",spellTexture and "|T"..spellTexture..":0|t " or "",spellName or "???") .."|h ".. ExRT.L.BossWatcherOverkillOnText .. " |cffff0000" .. (module.db.fightData.overkill[i][3] or 0) .. "|r"
			if #self.overkillData > 32 then
				break
			end
		end
		self.overkillBox.EditBox:SetText(strjoin("\n",unpack(self.overkillData)))
	end
	
	self.overkillBox = ExRT.lib.CreateMultiEditBox2(self:GetName().."OverkillBox",self.tab.tabs[8],590,402,"TOP",0,-11)
	self.overkillBox:SetScript("OnShow",function (self)
		ReloadOverkillBox(ExRT.mds.Round(self.ScrollBar:GetValue()))
	end)
	
	self.overkillBox.ScrollBar:SetScript("OnValueChanged",function (self,val)
		val = ExRT.mds.Round(val)
		ReloadOverkillBox(val)
	end)
	self.overkillBox.EditBox:SetHyperlinksEnabled(true)
	self.overkillBox.EditBox:SetScript("OnHyperlinkEnter",ExRT.lib.EditBoxOnEnterHyperLinkTooltip)
	self.overkillBox.EditBox:SetScript("OnHyperlinkLeave",ExRT.lib.EditBoxOnLeaveHyperLinkTooltip)
	
	--> Tab Segments
	
	self.buffs.timeSegments = {}
	self.timeLine.timeSegments = {}
	local function CreateBuffSegmentBack(i)
		if not self.buffs.timeSegments[i] then
		  	self.buffs.timeSegments[i] = CreateFrame("Frame",nil,self.tab.tabs[3])
			
			self.buffs.timeSegments[i].texture = self.buffs.timeSegments[i]:CreateTexture(nil, "BACKGROUND",0,-5)
			self.buffs.timeSegments[i].texture:SetTexture(1, 1, 0.5, 0.2)
			self.buffs.timeSegments[i].texture:SetAllPoints()
		end
		if not self.timeLine.timeSegments[i] then
			self.timeLine.timeSegments[i] = self.timeLine:CreateTexture(nil, "BACKGROUND",nil,1)
			self.timeLine.timeSegments[i]:SetTexture("Interface\\AddOns\\ExRT\\media\\bar9.tga")
			self.timeLine.timeSegments[i]:SetVertexColor(0.8, 0.8, 0.8, 1)
		end
	end
	
	self.segmentsText = ExRT.lib.CreateText(self.tab.tabs[6],180,15,nil,17,-10,"LEFT",nil,nil,11,ExRT.L.BossWatcherSegments..":",nil,1,1,1,1)
	self.segmentsList = ExRT.lib.CreateScrollCheckList(self:GetName().."SegmentsList",self.tab.tabs[6],nil,7,-25,280,8)
	self.segmentsList.Update()
	function self.segmentsList:ValueChanged()
		table.wipe(module.db.fightData.damage)
		table.wipe(module.db.fightData.heal)
		table.wipe(module.db.fightData.switch)
		table.wipe(module.db.fightData.npc_cast)
		table.wipe(module.db.fightData.players_cast)
		table.wipe(module.db.fightData.interrupts)
		table.wipe(module.db.fightData.dispels)
		table.wipe(module.db.fightData.buffs)
		table.wipe(module.db.fightData.dies)
		table.wipe(module.db.fightData.overkill)
		table.wipe(module.db.fightData.chat)
		table.wipe(module.db.fightData.energy)
		--collectgarbage("collect")
		local count = 0
		for i=1,#self.L do
			if self.C[i] then
				AddSegmentToData(i)
				count = count + 1
			end
		end
		UpdateBuffPageDB()
		UpdatePage()
		if count == #self.L then
			for i=1,#module.options.buffs.timeSegments do
				module.options.buffs.timeSegments[i]:Hide()
			end
			for i=1,#module.options.timeLine.timeSegments do
				module.options.timeLine.timeSegments[i]:Hide()
			end
		else
			local fightDuration = (module.db.encounterEnd - module.db.encounterStart)
			for i=1,#self.L do
				CreateBuffSegmentBack(i)
				if self.C[i] then
					local timeStart = max(module.db.fightData[i].timeEx - module.db.encounterStart,0)
					local timeEnd = max(module.db.fightData[i+1] and (module.db.fightData[i+1].timeEx - module.db.encounterStart) or fightDuration,0)
					local startPos = buffsNameWidth+timeStart/fightDuration*470
					local endPos = buffsNameWidth+timeEnd/fightDuration*470
					module.options.buffs.timeSegments[i]:SetPoint("TOPLEFT",startPos,-42)
					module.options.buffs.timeSegments[i]:SetSize(max(endPos-startPos,0.5),374)
					module.options.buffs.timeSegments[i]:Show()
					
					module.options.timeLine.timeSegments[i]:Hide()
				else
					module.options.buffs.timeSegments[i]:Hide()
					
					local timeStart = max(module.db.fightData[i].timeEx - module.db.encounterStart,0)
					local timeEnd = max(module.db.fightData[i+1] and (module.db.fightData[i+1].timeEx - module.db.encounterStart) or fightDuration,0)
					local tlWidth = module.options.timeLine:GetWidth()
					local startPos = timeStart/fightDuration*tlWidth
					local endPos = timeEnd/fightDuration*tlWidth
					module.options.timeLine.timeSegments[i]:SetPoint("TOPLEFT",startPos,0)
					module.options.timeLine.timeSegments[i]:SetSize(max(endPos-startPos,0.5),module.options.timeLine:GetHeight())
					module.options.timeLine.timeSegments[i]:Show()
				end
			end
			for i=(#self.L + 1),#module.options.buffs.timeSegments do
				module.options.buffs.timeSegments[i]:Hide()
			end
			for i=(#self.L + 1),#module.options.timeLine.timeSegments do
				module.options.timeLine.timeSegments[i]:Hide()
			end
		end
	end
	function self.segmentsList:HoverListValue(isHover,index)
		if not isHover then
			GameTooltip_Hide()
		else
			local scrollPos = ExRT.mds.Round(module.options.segmentsList.ScrollBar:GetValue())
			local textObj = module.options.segmentsList.List[index - scrollPos + 1].text
			if textObj:GetStringWidth() > 220 then
				GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
				GameTooltip:AddLine( textObj:GetText() )
				GameTooltip:Show()
			end
		end
	end	
	
	self.segmentsButtonAll = ExRT.lib.CreateButton(nil,self.tab.tabs[6],100,15,nil,80,-8,ExRT.L.BossWatcherSegmentSelectAll)
	self.segmentsButtonAll:SetScript("OnClick",function ()
		for i=1,#module.options.segmentsList.L do
			module.options.segmentsList.C[i] = true
		end
		module.options.segmentsList.Update()
		module.options.segmentsList.ValueChanged(module.options.segmentsList)
	end)
	self.segmentsButtonNone = ExRT.lib.CreateButton(nil,self.tab.tabs[6],100,15,nil,185,-8,ExRT.L.BossWatcherSegmentSelectNothing)
	self.segmentsButtonNone:SetScript("OnClick",function ()
		for i=1,#module.options.segmentsList.L do
			module.options.segmentsList.C[i] = nil
		end
		module.options.segmentsList.Update()
		module.options.segmentsList.ValueChanged(module.options.segmentsList)
	end)
	
	self.segmentsTooltip = ExRT.lib.CreateText(self.tab.tabs[6],295,250,nil,297,-10,"LEFT","TOP",nil,12,ExRT.L.BossWatcherSegmentsTooltip,nil,nil,nil,nil,1)
	
	self.segmentsPreSetList = {
		{ExRT.L.BossWatcherSegmentClear,},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss1,143469,"CHAT_MSG_RAID_BOSS_EMOTE"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss2,143546,"SPELL_AURA_APPLIED",143546,"SPELL_AURA_REMOVED",143812,"SPELL_AURA_APPLIED",143812,"SPELL_AURA_REMOVED",143955,"SPELL_AURA_APPLIED",143955,"SPELL_AURA_REMOVED"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss4,144832,"UNIT_SPELLCAST_SUCCEEDED"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss6,144483,"SPELL_AURA_APPLIED",144483,"SPELL_AURA_REMOVED"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss7,144302,"UNIT_SPELLCAST_SUCCEEDED",},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss8,143593,"SPELL_AURA_APPLIED",143589,"SPELL_AURA_APPLIED",143594,"SPELL_AURA_APPLIED"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss9,142842,"UNIT_SPELLCAST_SUCCEEDED",142879,"SPELL_AURA_APPLIED",142879,"SPELL_AURA_REMOVED"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss11,143440,"SPELL_AURA_APPLIED",143440,"SPELL_AURA_REMOVED"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss13,71161,"UNIT_DIED",71157,"UNIT_DIED",71156,"UNIT_DIED",71155,"UNIT_DIED",71160,"UNIT_DIED",71154,"UNIT_DIED",71152,"UNIT_DIED",71158,"UNIT_DIED",71153,"UNIT_DIED"},
		{ExRT.L.sooitemst16.." - "..ExRT.L.sooitemssooboss14,145235,"UNIT_SPELLCAST_SUCCEEDED",144956,"UNIT_SPELLCAST_SUCCEEDED",146984,"UNIT_SPELLCAST_SUCCEEDED"},
	}
	local function SegmentsSetPreSet(self)
		local id = self.id
		for i=2,21,2 do
			local j = i / 2
			VExRT.BossWatcher.autoSegments[j] = VExRT.BossWatcher.autoSegments[j] or {}
		
			module.options.autoSegments[j]:SetText( module.options.segmentsPreSetList[id][i] or "" )
			VExRT.BossWatcher.autoSegments[j][1] = tonumber( module.options.segmentsPreSetList[id][i] or "" )
			
			local event = module.options.segmentsPreSetList[id][i+1]
			VExRT.BossWatcher.autoSegments[j][2] = event
			event = event or "UNIT_SPELLCAST_SUCCEEDED"
			module.options.autoSegments[j].t.t:SetText( module.db.autoSegmentEventsL[event] )
			module.options.autoSegments[j].t.tooltipText = event
			for k=1,#module.db.autoSegmentEvents do
				if event == module.db.autoSegmentEvents[k] then
					module.options.autoSegments[j].t.selected = k
					break
				end
			end
			
		end
		UpdateNewSegmentEvents()
		module.options.segmentsPreSet.HideByTimer(module.options.segmentsPreSet)
	end
	self.segmentsPreSet = ExRT.lib.CreateListFrame(self:GetName().."SegmentsPreSet",self.tab.tabs[6],350,#self.segmentsPreSetList,"RIGHT",nil,590,-145,ExRT.L.BossWatcherSegmentPreSet..":",SegmentsSetPreSet)
	local function SegmentsPreSetButtonEnter(self)
		local id = self.id
		local sList = {}
		for i=2,21,2 do
			local spellID = module.options.segmentsPreSetList[id][i]
			local event = module.options.segmentsPreSetList[id][i+1]
			if spellID and event then
				local sID,_,sT=GetSpellInfo(spellID)
				if sID and event ~= "UNIT_DIED" then
					table.insert(sList,"|cffffffff"..module.db.autoSegmentEventsL[event].." |T"..sT..":0|t"..sID.."|r")
				elseif event == "UNIT_DIED" then
					table.insert(sList,"|cffffffff"..module.db.autoSegmentEventsL[event].." "..spellID.."|r")
				end
			end
		end
		if #sList > 0 then
			ExRT.lib.TooltipShow(self,"ANCHOR_LEFT",ExRT.L.cd2fastSetupTooltip..":",unpack(sList))
		end
	end
	local function SegmentsPreSetButtonLeave(self)
		ExRT.lib.TooltipHide()
	end
	for i=1,#self.segmentsPreSetList do
		self.segmentsPreSet.buttons[i].text:SetText(self.segmentsPreSetList[i][1])
		self.segmentsPreSet.buttons[i]:SetScript("OnEnter", SegmentsPreSetButtonEnter)
		self.segmentsPreSet.buttons[i]:SetScript("OnLeave", SegmentsPreSetButtonLeave)
	end

	local function EditSliderBoxFunc(_self)
		local self = _self.parent
		local i = _self.diff
		self.selected = self.selected + i
		if self.selected < 1 then 
			self.selected = #module.db.autoSegmentEvents
		elseif self.selected > #module.db.autoSegmentEvents then
			self.selected = 1
		end
		self.t:SetText(module.db.autoSegmentEventsL[module.db.autoSegmentEvents[self.selected]])
		self.tooltipText = module.db.autoSegmentEvents[self.selected]
		VExRT.BossWatcher.autoSegments[self.id] = VExRT.BossWatcher.autoSegments[self.id] or {}
		VExRT.BossWatcher.autoSegments[self.id][2] = module.db.autoSegmentEvents[self.selected]	
		UpdateNewSegmentEvents()  
	end
	
	local function EditSliderBoxOnEnterEditBox(self)
		local i = self.i_num
		local sID = self:GetText()
		sID = tonumber(sID)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(ExRT.L.BossWatcherSegmentsSpellTooltip)
		if VExRT.BossWatcher.autoSegments[i] and VExRT.BossWatcher.autoSegments[i][2] ~= "UNIT_DIED" and sID and GetSpellInfo(sID) then
			GameTooltip:AddLine(ExRT.L.BossWatcherSegmentNowTooltip)
			GameTooltip:AddSpellByID(sID)
		end			
		GameTooltip:Show()
	end
	
	local function AutoSegmentsEditBoxOnTextChanged(self,isUser)
		if not isUser then
			return
		end
		VExRT.BossWatcher.autoSegments[self._i] = VExRT.BossWatcher.autoSegments[self._i] or {}
		VExRT.BossWatcher.autoSegments[self._i][1] = tonumber(self:GetText())
		VExRT.BossWatcher.autoSegments[self._i][2] = VExRT.BossWatcher.autoSegments[self._i][2] or "UNIT_SPELLCAST_SUCCEEDED" 
		UpdateNewSegmentEvents()
	end

	self.autoSegments = {}
	for i=1,10 do
		self.autoSegments[i] = ExRT.lib.CreateEditBox(nil,self.tab.tabs[6],235,24,nil,10,-172-(i-1)*24,ExRT.L.BossWatcherSegmentsSpellTooltip,6,true,nil,VExRT.BossWatcher.autoSegments[i] and VExRT.BossWatcher.autoSegments[i][1] or "")
		self.autoSegments[i]:SetScript("OnTextChanged",AutoSegmentsEditBoxOnTextChanged)
		self.autoSegments[i]._i = i

		self.autoSegments[i].t = ExRT.lib.CreateEditSliderBox(self.tab.tabs[6],343,24,256,-172-(i-1)*24,VExRT.BossWatcher.autoSegments[i] and VExRT.BossWatcher.autoSegments[i][2] and module.db.autoSegmentEventsL[VExRT.BossWatcher.autoSegments[i][2]] or module.db.autoSegmentEventsL[module.db.autoSegmentEvents[1]])
		self.autoSegments[i].t.l[1]:SetScript("OnClick",EditSliderBoxFunc)
		self.autoSegments[i].t.l[2]:SetScript("OnClick",EditSliderBoxFunc)
		self.autoSegments[i].t.id = i
		self.autoSegments[i].t.tooltipText = VExRT.BossWatcher.autoSegments[i] and VExRT.BossWatcher.autoSegments[i][2] or module.db.autoSegmentEvents[1]
		
		self.autoSegments[i].i_num = i
		self.autoSegments[i]:SetScript("OnEnter",EditSliderBoxOnEnterEditBox)
	end
	
	--> Page Update
	
	local function TimeLineShowSpellID(spellid)
		if VExRT.BossWatcher.timeLineSpellID then
			return " ["..spellid.."]"
		else
			return ""
		end
	end
	
	function UpdatePage()
		table.wipe(self.targetsList.L)
		table.wipe(module.options.targetsIndex)
		local mobsList = {}
		for mobGUID,mobData in pairs(module.db.fightData.damage) do
			table.insert(mobsList,{module.db.guidsListFix[mobGUID],mobData.id,mobGUID})
		end
		table.sort(mobsList,function(a,b) return a[2] < b[2] end)
		for i=1,#mobsList do
			self.targetsList.L[i] =  date("%M:%S ", timestampToFightTime(mobsList[i][2]))..mobsList[i][1]
			module.options.targetsIndex[i] = mobsList[i][3]
		end
		
		if self.targetsList.dataIndex ~= module.db.encounterStart then
			self.targetsList.selected = nil
			module.options.damgeBox.EditBox:SetText("")
			module.options.switchBox.EditBox:SetText("")
			module.options.damgeSwitchTab.text:SetText("")
			module.options.infoBoxText:SetText(ExRT.L.BossWatcherDamageSwitchTabInfoNoInfo)
		end
		self.targetsList.dataIndex = module.db.encounterStart
		
		-->
		self.timeLine.textLeft:SetText( date("%H:%M:%S", module.db.encounterStartGlobal) )
		self.timeLine.textRight:SetText( date("%M:%S", module.db.encounterEnd - module.db.encounterStart) )
		self.timeLine.textCenter:SetText( date("%M:%S", (module.db.encounterEnd - module.db.encounterStart) / 2) )
		
		local fight_dur = module.db.encounterEnd - module.db.encounterStart
		self.timeLine.bossName:SetText( (module.db.encounterName or ExRT.L.BossWatcherLastFight)..date(" %M:%S", fight_dur ) )

		
		-->
		local redLineNum = 0
		for i=1,module.options.timeLinePieces do
			if not self.timeLine[i].tooltip then
				self.timeLine[i].tooltip = {}
			end
			table_wipe(self.timeLine[i].tooltip)
		end
		local addToToolipTable = {}
		for mobGUID,mobData in pairs(module.db.fightData.npc_cast) do
			for i=1,#mobData do
				local _time = timestampToFightTime(mobData[i][1])
				
				local tooltipIndex = _time / fight_dur
				
				redLineNum = redLineNum + 1
				if not self.timeLine.redLine[redLineNum] then
					CreateRedLine(redLineNum)
				end
				self.timeLine.redLine[redLineNum]:SetPoint("TOPLEFT",self.timeLine,"TOPLEFT",600*tooltipIndex,0)
				self.timeLine.redLine[redLineNum]:Show()
				
				tooltipIndex = min( floor( (module.options.timeLinePieces - 0.01)*tooltipIndex + 1 ) , module.options.timeLinePieces)
				
				local spellName,_,spellTexture = GetSpellInfo(mobData[i][2])
				
				local targetInfo = ""
				if mobData[i][4] and module.db.guidsListFix[mobData[i][4]] and mobData[i][4] ~= "" then
					targetInfo = " "..ExRT.L.BossWatcherTimeLineOnText.." |c"..ExRT.mds.classColorByGUID(mobData[i][4])..module.db.guidsListFix[mobData[i][4]].."|r"
				end
				
				addToToolipTable[#addToToolipTable + 1] = {tooltipIndex,_time,"[" .. date("%M:%S", _time )  .. "] |c"..ExRT.mds.classColorByGUID(mobGUID) .. module.db.guidsListFix[mobGUID] .."|r" .. GUIDtoText("(%s)",mobGUID) .. ( mobData[i][3] == 2 and " "..ExRT.L.BossWatcherTimeLineCast.." " or " "..ExRT.L.BossWatcherTimeLineCastStart.." " ) .. format("%s%s%s",spellTexture and "|T"..spellTexture..":0|t " or "",spellName or "???",TimeLineShowSpellID(mobData[i][2])) .. targetInfo }
			end
		end
		for _,chatData in ipairs(module.db.fightData.chat) do
			local _time = min( max(chatData[4] - module.db.encounterStart,0) , module.db.encounterEnd)
			
			local tooltipIndex = _time / fight_dur
			redLineNum = redLineNum + 1
			if not self.timeLine.redLine[redLineNum] then
				CreateRedLine(redLineNum)
			end
			self.timeLine.redLine[redLineNum]:SetPoint("TOPLEFT",self.timeLine,"TOPLEFT",600*tooltipIndex,0)
			self.timeLine.redLine[redLineNum]:Show()
			
			tooltipIndex = min( floor( (module.options.timeLinePieces - 0.01)*tooltipIndex + 1 ) , module.options.timeLinePieces)
			
			local spellName,_,spellTexture = GetSpellInfo(chatData[3])
						
			addToToolipTable[#addToToolipTable + 1] = {tooltipIndex,_time,"[" .. date("%M:%S", _time )  .. "] "..  ExRT.L.BossWatcherChatSpellMsg .. " " .. format("%s%s%s",spellTexture and "|T"..spellTexture..":0|t " or "",spellName or "???",TimeLineShowSpellID(chatData[3])) }
		end		
		for i=(redLineNum+1),#self.timeLine.redLine do
			self.timeLine.redLine[i]:Hide()
		end
		
		local blueLineNum = 0
		for i=1,#module.db.fightData.dies do
			if ExRT.mds.GetUnitInfoByUnitFlag(module.db.fightData.dies[i][2],1) == 1024 then
				local _time = timestampToFightTime(module.db.fightData.dies[i][3])
				
				local tooltipIndex = _time / fight_dur
				
				blueLineNum = blueLineNum + 1
				if not self.timeLine.blueLine[blueLineNum] then
					CreateBlueLine(blueLineNum)
				end
				self.timeLine.blueLine[blueLineNum]:SetPoint("TOPLEFT",self.timeLine,"TOPLEFT",600*tooltipIndex,0)
				self.timeLine.blueLine[blueLineNum]:Show()
				
				tooltipIndex = min ( floor( (module.options.timeLinePieces - 0.01)*tooltipIndex + 1 ) , module.options.timeLinePieces)
				
				addToToolipTable[#addToToolipTable + 1] = {tooltipIndex,_time,"[" .. date("%M:%S", _time )  .. "] |cffee5555" .. module.db.guidsListFix[module.db.fightData.dies[i][1]] .. GUIDtoText("(%s)",module.db.fightData.dies[i][1])  .. " "..ExRT.L.BossWatcherTimeLineDies.."|r"}
			end
		end
		for i=(blueLineNum+1),#self.timeLine.blueLine do
			self.timeLine.blueLine[i]:Hide()
		end
		
		table.sort(addToToolipTable,function (a,b) return a[2] < b[2] end)
		for i=1,#addToToolipTable do
			table.insert(self.timeLine[ addToToolipTable[i][1] ].tooltip,{addToToolipTable[i][3],1,1,1})
		end
		
		local textResult = ""
		for i=1,#module.db.fightData.interrupts do
			local spellSourceName,_,spellSourceTexture = GetSpellInfo(module.db.fightData.interrupts[i][3])
			local spellDestName,_,spellDestTexture = GetSpellInfo(module.db.fightData.interrupts[i][4])
			textResult = textResult.."[".. date("%M:%S", timestampToFightTime(module.db.fightData.interrupts[i][5])).."] |c".. ExRT.mds.classColorByGUID(module.db.fightData.interrupts[i][1]) .. module.db.guidsListFix[module.db.fightData.interrupts[i][1]] .. GUIDtoText(" (%s)",module.db.fightData.interrupts[i][1]) .. "|r "..ExRT.L.BossWatcherInterruptText.." |c" ..  ExRT.mds.classColorByGUID(module.db.fightData.interrupts[i][2]).. module.db.guidsListFix[module.db.fightData.interrupts[i][2]] .. "'s" .. GUIDtoText(" (%s)",module.db.fightData.interrupts[i][2]) .. "|r |Hspell:" .. (module.db.fightData.interrupts[i][4] or 0) .. "|h" .. format("%s%s",spellDestTexture and "|T"..spellDestTexture..":0|t " or "",spellDestName or "???") .. "|h "..ExRT.L.BossWatcherByText.." |Hspell:" .. (module.db.fightData.interrupts[i][3] or 0) .. "|h" .. format("%s%s",spellSourceTexture and "|T"..spellSourceTexture..":0|t " or "",spellSourceName or "???") .. "|h\n"
		end
		module.options.interruptBox.EditBox:SetText(textResult)
		
		textResult = ""
		for i=1,#module.db.fightData.dispels do
			local spellSourceName,_,spellSourceTexture = GetSpellInfo(module.db.fightData.dispels[i][3])
			local spellDestName,_,spellDestTexture = GetSpellInfo(module.db.fightData.dispels[i][4])
			textResult = textResult.."[".. date("%M:%S", timestampToFightTime(module.db.fightData.dispels[i][5])).."] |c" ..ExRT.mds.classColorByGUID(module.db.fightData.dispels[i][1]) .. module.db.guidsListFix[module.db.fightData.dispels[i][1]] .. GUIDtoText(" (%s)",module.db.fightData.dispels[i][1]) .. "|r "..ExRT.L.BossWatcherDispelText.." |c"..ExRT.mds.classColorByGUID(module.db.fightData.dispels[i][2]) .. module.db.guidsListFix[module.db.fightData.dispels[i][2]] .. "'s" .. GUIDtoText(" (%s)",module.db.fightData.dispels[i][2]) .. "|r |Hspell:" .. (module.db.fightData.dispels[i][4] or 0) .. "|h" ..  format("%s%s",spellDestTexture and "|T"..spellDestTexture..":0|t " or "",spellDestName or "???") .. "|h "..ExRT.L.BossWatcherByText.." |Hspell:" .. (module.db.fightData.dispels[i][3] or 0) .. "|h" .. format("%s%s",spellSourceTexture and "|T"..spellSourceTexture..":0|t " or "",spellSourceName or "???") .. "|h\n"
		end
		module.options.dispelBox.EditBox:SetText(textResult)
		
		local overkillVal = module.options.overkillBox.ScrollBar:GetValue()
		if overkillVal == 1 then
			ReloadOverkillBox(1)
		else
			module.options.overkillBox.ScrollBar:SetValue(1)
		end
		module.options.overkillBox.ScrollBar:SetMinMaxValues(1,max(#module.db.fightData.overkill-10,1))

		
		self.targetsList.Update()

		-->
		table.wipe(module.options.playersList.L)
		table.wipe(module.options.playersList.IndexToGUID)
		table.wipe(module.options.playersCastsList.L)
		table.wipe(module.options.playersCastsList.IndexToGUID)
		local playersListTable = {}
		for i,PlayerCastData in ipairs(module.db.fightData.players_cast) do
			local b = nil
			for j,playersListTableData in ipairs(playersListTable) do
				if playersListTableData[1] == PlayerCastData[1] then
					b = true
					break
				end
			end
			if not b then
				playersListTable[#playersListTable + 1] = {PlayerCastData[1],module.db.guidsListFix[ PlayerCastData[1] ],"|c"..ExRT.mds.classColorByGUID(PlayerCastData[1])}
			end
		end
		table.sort(playersListTable,function (a,b) return a[2] < b[2] end)
		for i,playersListTableData in ipairs(playersListTable) do
			module.options.playersList.L[i] = playersListTableData[3]..playersListTableData[2]
			module.options.playersList.IndexToGUID[i] = playersListTableData[1]
		end
		
		module.options.playersList.selected = nil
		
		module.options.playersList.Update()
		module.options.playersCastsList.Update()
		
		-->
		if module.options.tab.tabs[3]:IsShown() then
			UpdateBuffsPage()
		end
		
		-->
		EnergyPageUpdate()
		
		-->
		UpdateHealList()
		module.options.heal.byTarget = nil
		module.options.heal.bySource:SetEnabled(false)
		module.options.heal.byDest:SetEnabled(true)
	end
	
	self.lastFightIDPage = 0
	
	function UpdatePageNewFight()
		if self.lastFightIDPage ~= module.db.lastFightID then
			self.lastFightIDPage = module.db.lastFightID
			
			self.timeLine.arrowNow:Hide()
			self.targetsList.selected = nil
			
			-->
			table_wipe(self.segmentsList.L)
			table_wipe(self.segmentsList.C)
			if module.db.encounterStart ~= 0 then
				for i=1,module.db.fightData.segments or 0 do
					local time = module.db.fightData[i].time - module.db.encounterStartGlobal
					local name = module.db.fightData[i].name
					local subEvent = module.db.fightData[i].subEvent
					if name then
						local event = name
						name = " "..(module.db.segmentsLNames[name] or name)
						if subEvent then
							name = name.." <"..subEvent..">"
							if (event == "UNIT_SPELLCAST_SUCCEEDED" or event == "SPELL_AURA_REMOVED" or event == "SPELL_AURA_APPLIED") and tonumber(subEvent) then
								local spellName = GetSpellInfo( tonumber(subEvent) )
								if spellName then
									name = name .. ": " ..spellName
								end
							elseif event == "UNIT_DIED" and tonumber(subEvent) then
								local mobID = tonumber(subEvent)
								for guid,mobName in pairs(module.db.guidsList) do
									if string.len(guid) > 3 then
										local thisID = tonumber(guid:sub(-13, -9), 16) or 0
										if thisID == mobID and mobName then
											name = name .. ": " ..mobName
											break
										end
									end
								end
							end
						end
					end
					self.segmentsList.L[i] = date("%M:%S", max(time,0)) .. (name or "")
				end
				if module.db.fightData.segments then
					self.segmentsList.C[module.db.fightData.segments] = true
				end
			end
			self.segmentsList.Update()
			self.segmentsList.ValueChanged(self.segmentsList)			
		end
	end
	
	local WaitUntilCombatEnds = nil
	do
		local tmr = 0
		function WaitUntilCombatEnds(self,elapsed)
			tmr = tmr + elapsed
			if tmr > 1 then
				tmr = 0
				if InCombatLockdown() then
					return
				else
					module.options:afterCombatLockdown()
					UpdatePageNewFight()
					UpdatePage()
				end
			end
		end
	end
	
	function self:inCombatLockdown()
		module.options.tab.selected = nil
		for i=1,#module.options.tab.tabs do
			module.options.tab.tabs[i].disabled = true
		end
		module.options.tab.disabled = true
		module.options.tab.UpdateTabs(module.options.tab)
		
		module.options.timeLine:SetScript("OnUpdate",WaitUntilCombatEnds)
	end
	function self:afterCombatLockdown()
		if not module.options.tab.selected then
			module.options.tab.selected = 1
		end
		for i=1,#module.options.tab.tabs do
			module.options.tab.tabs[i].disabled = nil
		end
		module.options.tab.disabled = nil
		module.options.tab.UpdateTabs(module.options.tab)

		module.options.timeLine:SetScript("OnUpdate",nil)
	end
	
	self.timeLine:SetScript("OnShow",function (this)
		if InCombatLockdown() then
			print(ExRT.L.BossWatcherErrorInCombat)
			self:inCombatLockdown()
			return
		else
			self:afterCombatLockdown()
		end
		if fightUV then
			module.db.encounterEnd = GetTime()
			local randomID = math.random(module.db.lastFightID+10,99999)
			self.lastFightIDPage = randomID
			self.tab.tabs[3].lastFightID = randomID
		end
	
		UpdatePageNewFight()
		UpdatePage()
	end)
	
	UpdatePageNewFight()
	UpdatePage()
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.BossWatcher = VExRT.BossWatcher or {}
	VExRT.BossWatcher.autoSegments = VExRT.BossWatcher.autoSegments or {}
	
	if VExRT.BossWatcher.enabled then
		module:Enable(true)
	end
	if VExRT.BossWatcher.fightsNum then
		ChangeMaxFights(VExRT.BossWatcher.fightsNum)
	end
end

local function addDamage(sourceGUID,destGUID,amount,timestamp,spellID)
	local destTable = fightUV.damage[destGUID]
	if not destTable then
		destTable = {
			['_time']=timestamp,
		}
		fightUV.damage[destGUID] = destTable
	end
	local sourceTable = destTable[sourceGUID]
	if not sourceTable then
		sourceTable = {}
		destTable[sourceGUID] = sourceTable
	end
	if not sourceTable[spellID] then
		sourceTable[spellID] = 0
	end
	sourceTable[spellID] = sourceTable[spellID] + amount
end

local function addOverKill(sourceGUID,destGUID,overkill,timestamp,spellID)
	fightUV.overkill[ #fightUV.overkill + 1 ] = {sourceGUID,destGUID,overkill,timestamp,spellID}
end

local function addHeal(sourceGUID,destGUID,spellId,amount,overhealing,absorbed)
	local sourceTable = fightUV.heal[sourceGUID]
	if not sourceTable then
		sourceTable = {}
		fightUV.heal[sourceGUID] = sourceTable
	end
	local destTable = sourceTable[destGUID]
	if not destTable then
		destTable = {}
		sourceTable[destGUID] = destTable
	end
	local spellTable = destTable[spellId]
	if not spellTable then
		spellTable = {0,0,0}
		destTable[spellId] = spellTable
	end
	spellTable[1] = spellTable[1] + amount
	spellTable[2] = spellTable[2] + overhealing
	spellTable[3] = spellTable[3] + absorbed
end

local function addShield(sourceGUID,destGUID,spellId,amount)
	local sourceTable = heal_shields[sourceGUID]
	if not sourceTable then
		sourceTable = {}
		heal_shields[sourceGUID] = sourceTable
	end
	local spellTable = sourceTable[spellId]
	if not spellTable then
		spellTable = {}
		sourceTable[spellId] = spellTable
	end
	spellTable[destGUID] = amount
end
local function refreshShield(sourceGUID,destGUID,spellId,amount)
	local sourceTable = heal_shields[sourceGUID]
	if not sourceTable then
		return
	end
	local spellTable = sourceTable[spellId]
	if not spellTable then
		return
	end
	local prev = spellTable[destGUID]
	if prev and prev > amount then
		addHeal(sourceGUID,destGUID,spellId,prev-amount,0,0)
	end
	spellTable[destGUID] = amount
end
local function removeShield(sourceGUID,destGUID,spellId,amount)
	local sourceTable = heal_shields[sourceGUID]
	if not sourceTable then
		return
	end
	local spellTable = sourceTable[spellId]
	if not spellTable then
		return
	end
	local prev = spellTable[destGUID]
	if prev and prev > amount then
		addHeal(sourceGUID,destGUID,spellId,prev,amount,0)
	end
	spellTable[destGUID] = amount
end

local function addSwitch(sourceGUID,targetGUID,timestamp,_type,spellId)
	local targetTable = fightUV.switch[targetGUID]
	if not targetTable then
		targetTable = {
			[1]={},	--cast
			[2]={},	--target
		}
		fightUV.switch[targetGUID] = targetTable
	end
	if not targetTable[_type][sourceGUID] then
		targetTable[_type][sourceGUID] = {timestamp,spellId}
	end
end

local function addNPCCast(sourceGUID,destGUID,spellID,_type,timestamp)
	local sourceTable = fightUV.npc_cast[sourceGUID]
	if not sourceTable then
		sourceTable = {}
		fightUV.npc_cast[sourceGUID] = sourceTable
	end
	sourceTable[ #sourceTable + 1 ] = {timestamp,spellID,_type,destGUID}
end

local function addPlayersCast(sourceGUID,destGUID,spellID,timestamp)
	fightUV.players_cast[#fightUV.players_cast + 1] = {sourceGUID,destGUID,spellID,timestamp}
end

local module_db_guidsList
local function addGUID(GUID,name)
	if not module_db_guidsList[GUID] and name then
		module_db_guidsList[GUID] = name
	end
end

local function addBuff(timestamp,sourceGUID,destGUID,sourceFriendly,destFriendly,spellID,type_1,subeventID,stack)
	fightUV.buffs[ #fightUV.buffs + 1 ] = {timestamp,sourceGUID,destGUID,sourceFriendly,destFriendly,spellID,type_1,subeventID,stack}
end

local function addChatMessage(sender,msg,spellID,time)
	fightUV.chat[ #fightUV.chat + 1 ] = {sender,msg,spellID,time}
end

local function addEnergy(sourceGUID,spellId,powerType,amount)
	local sourceData = fightUV.energy[sourceGUID]
	if not sourceData then
		sourceData = {}
		fightUV.energy[sourceGUID] = sourceData
	end
	local powerData = sourceData[powerType]
	if not powerData then
		powerData = {}
		sourceData[powerType] = powerData
	end
	local spellData = powerData[spellId]
	if not spellData then
		spellData = {0,0}
		powerData[spellId] = spellData
	end
	spellData[1] = spellData[1] + amount
	spellData[2] = spellData[2] + 1
end

function AddSegmentToData(seg)
	for destGUID,destData in pairs(module.db.fightData[seg].damage) do
		if not module.db.fightData.damage[destGUID] then
			module.db.fightData.damage[destGUID] = {
				['id']=destData._time,
				['d']={},
			}
		end
		for sourceGUID,sourceData in pairs(destData) do
			if sourceGUID ~= "_time" then
				if not module.db.fightData.damage[destGUID]['d'][sourceGUID] then
					module.db.fightData.damage[destGUID]['d'][sourceGUID] = {}
				end
				for spellID,amount in pairs(sourceData) do
					if not module.db.fightData.damage[destGUID]['d'][sourceGUID][spellID] then
						module.db.fightData.damage[destGUID]['d'][sourceGUID][spellID] = 0
					end
					module.db.fightData.damage[destGUID]['d'][sourceGUID][spellID] = module.db.fightData.damage[destGUID]['d'][sourceGUID][spellID] + amount
				end
			end
		end
	end
	for sourceGUID,sourceData in pairs(module.db.fightData[seg].heal) do
		if not module.db.fightData.heal[sourceGUID] then
			module.db.fightData.heal[sourceGUID] = {}
		end
		for destGUID,destData in pairs(sourceData) do
			if not module.db.fightData.heal[sourceGUID][destGUID] then
				module.db.fightData.heal[sourceGUID][destGUID] = {}
			end
			for spellID,amountData in pairs(destData) do
				if not module.db.fightData.heal[sourceGUID][destGUID][spellID] then
					module.db.fightData.heal[sourceGUID][destGUID][spellID] = {0,0,0}
				end
				module.db.fightData.heal[sourceGUID][destGUID][spellID][1] = module.db.fightData.heal[sourceGUID][destGUID][spellID][1] + amountData[1]
				module.db.fightData.heal[sourceGUID][destGUID][spellID][2] = module.db.fightData.heal[sourceGUID][destGUID][spellID][2] + amountData[2]
				module.db.fightData.heal[sourceGUID][destGUID][spellID][3] = module.db.fightData.heal[sourceGUID][destGUID][spellID][3] + amountData[3]
			end
		end
	end
	for targetGUID,destData in pairs(module.db.fightData[seg].switch) do
		if not module.db.fightData.switch[targetGUID] then
			module.db.fightData.switch[targetGUID] = {
				[1]={},	--cast
				[2]={},	--target
			}
		end
		for _type=1,2 do
			for unitN,t in pairs(destData[_type]) do
				if not module.db.fightData.switch[targetGUID][_type][unitN] then
					module.db.fightData.switch[targetGUID][_type][unitN] = {t[1],t[2]}
				end
				if t[1] < module.db.fightData.switch[targetGUID][_type][unitN][1] then
					module.db.fightData.switch[targetGUID][_type][unitN][1] = t[1]
					module.db.fightData.switch[targetGUID][_type][unitN][2] = t[2]
				end
			end
		end
	end
	for sourceGUID,destData in pairs(module.db.fightData[seg].npc_cast) do
		if not module.db.fightData.npc_cast[sourceGUID] then
			module.db.fightData.npc_cast[sourceGUID] = {}
		end
		for i=1,#destData do
			local added_index = #module.db.fightData.npc_cast[sourceGUID] + 1
			module.db.fightData.npc_cast[sourceGUID][added_index] = {}
			for j=1,#destData[i] do
				module.db.fightData.npc_cast[sourceGUID][added_index][j] = destData[i][j]
			end
		end
	end
	for i=1,#module.db.fightData[seg].buffs do
		local added_index = #module.db.fightData.buffs + 1
		module.db.fightData.buffs[added_index] = {}
		for j=1,#module.db.fightData[seg].buffs[i] do
			module.db.fightData.buffs[added_index][j] = module.db.fightData[seg].buffs[i][j]
		end
	end
	for i=1,#module.db.fightData[seg].dies do
		local added_index = #module.db.fightData.dies + 1
		module.db.fightData.dies[added_index] = {}
		for j=1,#module.db.fightData[seg].dies[i] do
			module.db.fightData.dies[added_index][j] = module.db.fightData[seg].dies[i][j]
		end
	end
	for i=1,#module.db.fightData[seg].dispels do
		local added_index = #module.db.fightData.dispels + 1
		module.db.fightData.dispels[added_index] = {}
		for j=1,#module.db.fightData[seg].dispels[i] do
			module.db.fightData.dispels[added_index][j] = module.db.fightData[seg].dispels[i][j]
		end
	end
	for i=1,#module.db.fightData[seg].interrupts do
		local added_index = #module.db.fightData.interrupts + 1
		module.db.fightData.interrupts[added_index] = {}
		for j=1,#module.db.fightData[seg].interrupts[i] do
			module.db.fightData.interrupts[added_index][j] = module.db.fightData[seg].interrupts[i][j]
		end
	end
	for i=1,#module.db.fightData[seg].overkill do
		local added_index = #module.db.fightData.overkill + 1
		module.db.fightData.overkill[added_index] = {}
		for j=1,#module.db.fightData[seg].overkill[i] do
			module.db.fightData.overkill[added_index][j] = module.db.fightData[seg].overkill[i][j]
		end
	end
	for i=1,#module.db.fightData[seg].chat do
		local added_index = #module.db.fightData.chat + 1
		module.db.fightData.chat[added_index] = {}
		for j=1,#module.db.fightData[seg].chat[i] do
			module.db.fightData.chat[added_index][j] = module.db.fightData[seg].chat[i][j]
		end
	end
	for i=1,#module.db.fightData[seg].players_cast do
		local added_index = #module.db.fightData.players_cast + 1
		module.db.fightData.players_cast[added_index] = {}
		for j=1,#module.db.fightData[seg].players_cast[i] do
			module.db.fightData.players_cast[added_index][j] = module.db.fightData[seg].players_cast[i][j]
		end
	end
	for sourceGUID,sourceData in pairs(module.db.fightData[seg].energy) do
		local _sourceGUID = module.db.fightData.energy[sourceGUID]
		if not _sourceGUID then
			_sourceGUID = {}
			module.db.fightData.energy[sourceGUID] = _sourceGUID
		end
		for powerType,powerData in pairs(sourceData) do
			local _powerType = _sourceGUID[powerType]
			if not _powerType then
				_powerType = {}
				_sourceGUID[powerType] = _powerType
			end
			for spellID,spellData in pairs(powerData) do
				local _spellData = _powerType[spellID]
				if not _spellData then
					_spellData = {0,0}
					_powerType[spellID] = _spellData
				end
				_spellData[1] = _spellData[1] + spellData[1]
				_spellData[2] = _spellData[2] + spellData[2]
			end			
		end
	end
end

function NewSegment(name,subEvent,afterClear)
	if not fightUV and not afterClear then
		return
	end
	
	if afterClear then
		module.db.fightData.segments = 0
	
		module.db.fightData.damage = {}
		module.db.fightData.heal = {}
		module.db.fightData.switch = {}
		module.db.fightData.npc_cast = {}
		module.db.fightData.players_cast = {}
		module.db.fightData.interrupts ={}
		module.db.fightData.dispels = {}
		module.db.fightData.buffs = {}
		module.db.fightData.dies = {}
		module.db.fightData.overkill = {}
		module.db.fightData.chat = {}
		module.db.fightData.energy = {}
	end

	module.db.fightData.segments = module.db.fightData.segments and module.db.fightData.segments + 1 or 1
	local seg = module.db.fightData.segments
	module.db.fightData[seg] = {}
	
	module.db.fightData[seg].damage = {}
	module.db.fightData[seg].heal = {}
	module.db.fightData[seg].switch = {}
	module.db.fightData[seg].npc_cast = {}
	module.db.fightData[seg].players_cast = {}
	module.db.fightData[seg].interrupts = {}
	module.db.fightData[seg].dispels = {}
	module.db.fightData[seg].buffs = {}
	module.db.fightData[seg].dies = {}
	module.db.fightData[seg].overkill = {}
	module.db.fightData[seg].chat = {}
	module.db.fightData[seg].energy = {}
	module.db.fightData[seg].time = time()
	module.db.fightData[seg].timeEx = GetTime()
	module.db.fightData[seg].name = name
	module.db.fightData[seg].subEvent = subEvent
		
	if afterClear and not name then
		return
	end
	fightUV = module.db.fightData[seg]
end

do
	local maxFights = 1
	function ChangeMaxFights(newValue)
		maxFights = newValue
	end
	function NewFight()
		for i=maxFights,2,-1 do
			module.db.globalFights[i] = module.db.globalFights[i-1]
		end
		module.db.globalFights[1] = {
			guidsList = {},
			fightData = {},
			encounterName = nil,
			encounterStartGlobal = 0,
			encounterStart = 0,
			encounterEnd = 0,
		}
		
		return module.db.globalFights[1]
	end
	function LoadFight(num)
		local data = module.db.globalFights[num]
		if not data then
			return
		end
	
		module.db.guidsList = data.guidsList
		module.db.fightData = data.fightData
		
		module.db.encounterName = data.encounterName
		module.db.encounterStart = data.encounterStart
		module.db.encounterStartGlobal = data.encounterStartGlobal
		module.db.encounterEnd = data.encounterEnd
		
		module.db.lastFightID = module.db.lastFightID + 1
	end
end

function module.main:ENCOUNTER_START(encounterID,encounterName)
	local doReset = (not VExRT.BossWatcher.notReset) or module.db.encounterStart == 0
	
	table.wipe(heal_shields)
	
	if doReset then
		local data = NewFight()
	
		--wipe(module.db.guidsList)
		module.db.guidsList = data.guidsList
		module.db.fightData = data.fightData
		--wipe(module.db.fightData)
		collectgarbage("collect")
		
		module.db.timeFix = nil
		
		module.db.encounterName = encounterName
		module.db.encounterStart = GetTime()
		module.db.encounterStartGlobal = time()
		
		data.encounterName = module.db.encounterName
		data.encounterStart = module.db.encounterStart
		data.encounterStartGlobal = module.db.encounterStartGlobal
	end
	
	module_db_guidsList = module.db.guidsList
	
	module.db.encounterEnd = module.db.encounterStart
	
	module.db.lastFightID = module.db.lastFightID + 1
	
	addGUID("",ExRT.L.BossWatcherUnknown)
	addGUID(0,ExRT.L.BossWatcherUnknown)
	
	if not doReset then
		fightUV = module.db.fightData[ module.db.fightData.segments ]
	end
	
	NewSegment("ENCOUNTER_START",nil,doReset)
	
	for event,_ in pairs(module.db.registerOtherEvents) do
		module:RegisterEvents(event)
	end
	module:RegisterEvents('COMBAT_LOG_EVENT_UNFILTERED','UNIT_TARGET','RAID_BOSS_EMOTE','RAID_BOSS_WHISPER')
end
module.main.PLAYER_REGEN_DISABLED = module.main.ENCOUNTER_START

function module.main:ENCOUNTER_END()
	module.db.encounterEnd = GetTime()
	
	if module.db.globalFights[1] then
		module.db.globalFights[1].encounterEnd = module.db.encounterEnd
	end

	module:UnregisterEvents('COMBAT_LOG_EVENT_UNFILTERED','UNIT_TARGET','RAID_BOSS_EMOTE','RAID_BOSS_WHISPER')
	for event,_ in pairs(module.db.registerOtherEvents) do
		module:UnregisterEvents(event)
	end
	fightUV = nil	
end
module.main.PLAYER_REGEN_ENABLED = module.main.ENCOUNTER_END

function module.main:ZONE_CHANGED_NEW_AREA()
	ExRT.mds.dprint('ZONE_CHANGED_NEW_AREA')
	local zoneID = GetCurrentMapAreaID()
	if fightUV then
		module.main:ENCOUNTER_END()
	end

	module:UnregisterEvents('PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','ENCOUNTER_START','ENCOUNTER_END')
	if module.db.raidIDs[zoneID] then
		module:RegisterEvents('ENCOUNTER_START','ENCOUNTER_END')
	else
		module:RegisterEvents('PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED')
	end
end

local autoSegmentsUPValue = module.db.autoSegments
function module.main:UNIT_SPELLCAST_SUCCEEDED(unitID,_,_,_,spellID)
	if autoSegmentsUPValue.UNIT_SPELLCAST_SUCCEEDED[spellID] then
		local guid = UnitGUID(unitID)
		if AntiSpam("BossWatcherUSS"..(guid or "0x0")..(spellID or "0"),0.5) then
			NewSegment("UNIT_SPELLCAST_SUCCEEDED",spellID)
		end
	end
end

function module.main:CHAT_MSG_RAID_BOSS_EMOTE(msg,sender)
	for emote,_ in pairs(autoSegmentsUPValue.CHAT_MSG_RAID_BOSS_EMOTE) do
		if msg:find(emote, nil, true) or msg:find(emote) then
			NewSegment("CHAT_MSG_RAID_BOSS_EMOTE",emote)
		end
	end
end

function module.main:RAID_BOSS_EMOTE(msg,sender)
	local spellID = msg:match("spell:(%d+)")
	if spellID then
		addChatMessage(sender,msg,spellID,GetTime())
	end
end
module.main.RAID_BOSS_WHISPER = module.main.RAID_BOSS_EMOTE

function module.main:SPELL_DAMAGE(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,amount,overkill)
	if not UnitIsFriendlyByUnitFlag(destFlags) then
		--amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand, multistrike
		addDamage(sourceGUID,destGUID,amount,timestamp,spellId)
		
		--> switch
		if GetUnitInfoByUnitFlag(sourceFlags,1) == 1024 then
			addSwitch(sourceGUID,destGUID,timestamp,1,spellId)
		end
	end
	if overkill > 0 then
		addOverKill(sourceGUID,destGUID,overkill,timestamp,spellId)
	end
end
module.main.SPELL_PERIODIC_DAMAGE = module.main.SPELL_DAMAGE
module.main.RANGE_DAMAGE = module.main.SPELL_DAMAGE

function module.main:SPELL_HEAL(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,amount,overhealing,absorbed)
	addHeal(sourceGUID,destGUID,spellId,amount,overhealing,absorbed)
end
module.main.SPELL_PERIODIC_HEAL = module.main.SPELL_HEAL

function module.main:SWING_DAMAGE(timestamp,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,amount,overkill)
	if not UnitIsFriendlyByUnitFlag(destFlags) then
		--amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand, multistrike
		addDamage(sourceGUID,destGUID,amount,timestamp,6603)
		
		--> switch
		if GetUnitInfoByUnitFlag(sourceFlags,1) == 1024 then
			addSwitch(sourceGUID,destGUID,timestamp,1,6603)
		end
	end
	if overkill > 0 then
		addOverKill(sourceGUID,destGUID,overkill,timestamp,6603)
	end
end

function module.main:SPELL_AURA_APPLIED(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,_type,amount)
	addBuff(timestamp,sourceGUID,destGUID,UnitIsFriendlyByUnitFlag(sourceFlags),UnitIsFriendlyByUnitFlag(destFlags),spellId,_type,1,1)
	
	if autoSegmentsUPValue.SPELL_AURA_APPLIED[spellId] then
		NewSegment("SPELL_AURA_APPLIED",spellId)
	end
	
	if amount then
		addShield(sourceGUID,destGUID,spellId,amount)
	end
end

function module.main:SPELL_AURA_REMOVED(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,_type,amount)
	addBuff(timestamp,sourceGUID,destGUID,UnitIsFriendlyByUnitFlag(sourceFlags),UnitIsFriendlyByUnitFlag(destFlags),spellId,_type,2,1)
	
	if autoSegmentsUPValue.SPELL_AURA_REMOVED[spellId] then
		NewSegment("SPELL_AURA_REMOVED",spellId)
	end
	
	if amount then
		removeShield(sourceGUID,destGUID,spellId,amount)
	end
end

function module.main:SPELL_AURA_REFRESH(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,_type,amount)
	if amount then
		refreshShield(sourceGUID,destGUID,spellId,amount)
	end
end

function module.main:SPELL_AURA_APPLIED_DOSE(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,_type,stack)
	addBuff(timestamp,sourceGUID,destGUID,UnitIsFriendlyByUnitFlag(sourceFlags),UnitIsFriendlyByUnitFlag(destFlags),spellId,_type,3,stack)
end

function module.main:SPELL_AURA_REMOVED_DOSE(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,_type,stack)
	addBuff(timestamp,sourceGUID,destGUID,UnitIsFriendlyByUnitFlag(sourceFlags),UnitIsFriendlyByUnitFlag(destFlags),spellId,_type,4,stack)
end

function module.main:SPELL_CAST_SUCCESS(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId)
	local isPlayer = (GetUnitInfoByUnitFlag(sourceFlags,1) == 1024)
	--> switch
	if not not UnitIsFriendlyByUnitFlag(destFlags) and isPlayer then
		addSwitch(sourceGUID,destGUID,timestamp,1,spellId)
	end
	
	if isPlayer then
		addPlayersCast(sourceGUID,destGUID,spellId,timestamp)
	end
	
	--> npc cast
	if not UnitIsFriendlyByUnitFlag(sourceFlags) then
		addNPCCast(sourceGUID,destGUID,spellId,2,timestamp)
	end
	--addNPCCast(sourceGUID,destGUID,spellId,2,timestamp)
end

function module.main:SPELL_CAST_START(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId)
	--> npc cast
	if not UnitIsFriendlyByUnitFlag(sourceFlags) then
		addNPCCast(sourceGUID,destGUID,spellId,1,timestamp)
	end
	
	--> switch
	if sourceName and GetUnitInfoByUnitFlag(sourceFlags,1) == 1024 then
		local unitID = UnitInRaid(sourceName)
		if unitID then
			unitID = "raid"..unitID
			local targetGUID = UnitGUID(unitID.."target")
			if targetGUID and not UnitIsPlayerOrPet(targetGUID) then
				addSwitch(sourceGUID,targetGUID,timestamp,1,spellId)
			end
		end
	end
end

function module.main:UNIT_DIED(timestamp,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellId)
	fightUV.dies[#fightUV.dies+1] = {destGUID,destFlags,timestamp,destFlags2}
	
	local uID = GUIDtoID(destGUID)
	if autoSegmentsUPValue.UNIT_DIED[ uID ] then
		NewSegment("UNIT_DIED",uID)
	end
end

function module.main:SPELL_INTERRUPT(timestamp,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellId,_,_,destSpell)
	fightUV.interrupts[#fightUV.interrupts+1]={sourceGUID,destGUID,spellId,destSpell,timestamp}
end

function module.main:SPELL_DISPEL(timestamp,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellId,_,_,destSpell)
	fightUV.dispels[#fightUV.dispels+1]={sourceGUID,destGUID,spellId,destSpell,timestamp}
end
module.main.SPELL_STOLEN = module.main.SPELL_DISPEL

function module.main:SPELL_RESURRECT(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId)
	addNPCCast(sourceGUID,destGUID,spellId,2,timestamp)
end

function module.main:SPELL_ENERGIZE(timestamp,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags,_,spellId,_,_,amount,powerType)
	addEnergy(destGUID,spellId,powerType,amount)
end

function module.main:UNIT_TARGET(unitID)
	local targetGUID = UnitGUID(unitID.."target")
	if targetGUID and not UnitIsPlayerOrPet(targetGUID) then
		local sourceGUID = UnitGUID(unitID)
		if GetUnitTypeByGUID(sourceGUID) == 0 then
			addSwitch(sourceGUID,targetGUID,GetTime(),2)
		end
	end
end

local CLEUEvents = {
	SPELL_HEAL = module.main.SPELL_HEAL,
	SPELL_PERIODIC_HEAL = module.main.SPELL_PERIODIC_HEAL,
	SPELL_PERIODIC_DAMAGE = module.main.SPELL_PERIODIC_DAMAGE,
	RANGE_DAMAGE = module.main.RANGE_DAMAGE,
	SPELL_DAMAGE = module.main.SPELL_DAMAGE,
	SWING_DAMAGE = module.main.SWING_DAMAGE,
	SPELL_AURA_APPLIED = module.main.SPELL_AURA_APPLIED,
	SPELL_AURA_REMOVED = module.main.SPELL_AURA_REMOVED,
	SPELL_AURA_REFRESH = module.main.SPELL_AURA_REFRESH,
	SPELL_AURA_APPLIED_DOSE = module.main.SPELL_AURA_APPLIED_DOSE,
	SPELL_AURA_REMOVED_DOSE = module.main.SPELL_AURA_REMOVED_DOSE,
	SPELL_CAST_SUCCESS = module.main.SPELL_CAST_SUCCESS,
	SPELL_CAST_START = module.main.SPELL_CAST_START,
	UNIT_DIED = module.main.UNIT_DIED,
	SPELL_INTERRUPT = module.main.SPELL_INTERRUPT,
	SPELL_DISPEL = module.main.SPELL_DISPEL,
	SPELL_STOLEN = module.main.SPELL_STOLEN,
	SPELL_RESURRECT = module.main.SPELL_RESURRECT,
	SPELL_ENERGIZE = module.main.SPELL_ENERGIZE,
	SPELL_PERIODIC_ENERGIZE = module.main.SPELL_ENERGIZE,
}

--/run Q=CreateFrame'Frame'Q:RegisterEvent'COMBAT_LOG_EVENT_UNFILTERED'Q:SetScript('OnEvent',function(_,_,_,e,...)if e=='SPELL_ENERGIZE' then for i=1,select('#',...) do local q=select(i,...)print(i+2,q)end end end)

function module.main:COMBAT_LOG_EVENT_UNFILTERED(timestamp,event,hideCaster,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellId,...)
	local eventFunc = CLEUEvents[event]
	if eventFunc then
		eventFunc(self,timestamp,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellId,...)
	end
	
	if not module.db.timeFix then
		module.db.timeFix = {GetTime(),timestamp}
	end
	
	addGUID(sourceGUID,sourceName)
	addGUID(destGUID,destName)
end

local function GlobalRecordStart()
	if not VExRT.BossWatcher.enabled then
		return
	end
	module:UnregisterEvents('ENCOUNTER_START','ENCOUNTER_END','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED')
	module.main.ENCOUNTER_START()
	
	print("Запись включена")
end

local function GlobalRecordEnd()
	if not VExRT.BossWatcher.enabled then
		return
	end
	module.main.ENCOUNTER_END()
	module.main.ZONE_CHANGED_NEW_AREA()
	
	print("Запись отключена")
end

function module:slash(arg)
	if arg == "seg" then
		NewSegment("SLASH")
	elseif arg == "bw s" or arg == "bw start" then
		GlobalRecordStart()
		print( ExRT.mds.CreateChatLink("BWGlobalRecordEnd",GlobalRecordEnd,"Остановить запись"), "или /rt bw end" )
	elseif arg == "bw e" or arg == "bw end" then
		GlobalRecordEnd()
	end
end
ExRT.mds.BWNS = NewSegment