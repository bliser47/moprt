local GlobalAddonName, ExRT = ...

local GetUnitInfoByUnitFlag = ExRT.mds.GetUnitInfoByUnitFlag

local VExRT = nil

local module = ExRT.mod:New("Encounter",ExRT.L.sencounter)
module.db.firstBlood = nil
module.db.isEncounter = nil
module.db.diff = nil
module.db.nowInTable = nil
module.db.afterCombatFix = nil
module.db.diffNames = {
	[0] = ExRT.L.sencounterUnknown,
	[1] = ExRT.L.sencounter5ppl,
	[2] = ExRT.L.sencounter5pplHC,
	[3] = ExRT.L.sencounter10ppl,
	[4] = ExRT.L.sencounter25ppl,
	[5] = ExRT.L.sencounter10pplHC,
	[6] = ExRT.L.sencounter25pplHC,
	[7] = ExRT.L.sencounterLfr,		--		PLAYER_DIFFICULTY3
	[8] = ExRT.L.sencounterChall,
	[9] = ExRT.L.sencounter40ppl,
	[11] = ExRT.L.sencounter3pplHC,
	[12] = ExRT.L.sencounter3ppl,
	[14] = ExRT.L.sencounterFlex,	-- Normal,	PLAYER_DIFFICULTY1
	[15] = ExRT.L.sencounterWODHeroic,	-- Heroic,	PLAYER_DIFFICULTY2
	[16] = ExRT.L.sencounterWODMythic,	-- Mythic,	PLAYER_DIFFICULTY6
	[17] = ExRT.L.sencounterLfr,	-- Lfr,	PLAYER_DIFFICULTY3
}
module.db.diffPos = {7,14,3,4,5,6}
module.db.dropDownNow = nil
module.db.onlyMy = nil
module.db.scrollPos = 1
module.db.playerName = nil
module.db.pullTime = 0

function module.options:Load()
	self.dropDown = CreateFrame("Frame", self:GetName().."DropDown", self, "UIDropDownMenuTemplate")
	self.dropDown:SetPoint("TOPLEFT",390,-5)
	self.dropDown:SetWidth(180)
	UIDropDownMenu_SetWidth(self.dropDown, 180)
	function self.dropDown:SetValue(newValue)
		if module.db.dropDownNow ~= newValue then
			module.db.scrollPos = 1
			module.options.ScrollBar:SetValue(1)
		end
		module.db.dropDownNow = newValue
		local newDiff = module.db.diffPos[newValue]
		UIDropDownMenu_SetText(module.options.dropDown, module.db.diffNames[newDiff])
		CloseDropDownMenus()
		local j,ddL = 0,{}
		local myName = UnitName("player")

		
		local totalTable = {}
		for playerName,playerData in pairs(VExRT.Encounter.list) do
			if not module.db.onlyMy or playerName == module.db.playerName then
				for i=1,#playerData do
					local data = playerData[i]
					local diffID = tonumber( string.sub(data,4,4),16 ) + 1
					if diffID == newDiff then
						local encounterID = tonumber( string.sub(data,1,3),16 )
						local pull = tonumber( string.sub(data,5,14) )
						local pullTime = tonumber( string.sub(data,15,17),16 )
						local isKill = string.sub(data,18,18) == "1"
						local groupSize = tonumber(string.sub(data,19,20))
						local firstBloodName = string.sub(data,21)
						if firstBloodName == "" then 
							firstBloodName = nil
						end
						table.insert(totalTable,{encounterID,pull,pullTime,isKill,groupSize,firstBloodName})
					end
				end			
			end
		end
		local encounters = {}
		for i=1,#totalTable do
			local encounterID = totalTable[i][1]
			encounters[encounterID] = encounters[encounterID] or {}
			encounters[encounterID].first = min( encounters[encounterID].first or time(), totalTable[i][2] )
			
			if totalTable[i][4] then
				encounters[encounterID].killTime = min( encounters[encounterID].killTime or 4095, totalTable[i][3] )
			else
				encounters[encounterID].wipeTime = max( encounters[encounterID].wipeTime or 0, totalTable[i][3] )
			end
			encounters[encounterID].firstBlood = encounters[encounterID].firstBlood or {}
			local firstBloodName = totalTable[i][6]
			if firstBloodName then
				encounters[encounterID].firstBlood[firstBloodName] = encounters[encounterID].firstBlood[firstBloodName] and encounters[encounterID].firstBlood[firstBloodName] + 1 or 1
			end
			encounters[encounterID].name = VExRT.Encounter.names[encounterID] or "Unknown"
			
			if not encounters[encounterID].pullTable then
				encounters[encounterID].pullTable = {}
			end
			table.insert(encounters[encounterID].pullTable,{totalTable[i][2],totalTable[i][3],totalTable[i][4],totalTable[i][5]})
		end
		local encountersSort = {}
		for encounterID,encounterData in pairs(encounters) do
			table.insert(encountersSort,{encounterID,encounterData.first})
			table.sort(encounterData.pullTable,function(a,b) return a[1] < b[1] end)
			encounterData.pulls = 0
			encounterData.kills = 0
			encounterData.firstKill = nil
			for i=1,#encounterData.pullTable do
				encounterData.pulls = encounterData.pulls + 1
				if encounterData.pullTable[i][3] then
					if not encounterData.firstKill then
						encounterData.firstKill = encounterData.pulls
					end
					encounterData.kills = encounterData.kills + 1
				end
			end
			
			local newFB = {}
			for fbName,fbCount in pairs(encounterData.firstBlood) do
				table.insert(newFB,{fbName,fbCount})
			end
			table.sort(newFB,function(a,b) return a[2] > b[2] end)
			encounterData.firstBlood = newFB
			
			if not encounterData.killTime or encounterData.killTime == 4095 then
				encounterData.killTime = 0
			end
			encounterData.wipeTime = encounterData.wipeTime or 0
		end
		table.sort(encountersSort,function(a,b) return a[2] > b[2] end)
			
		j = 0
		for i=module.db.scrollPos,#encountersSort do
			j = j + 1
			local encounterID = encountersSort[i][1]
		
			module.options.line[j].boss:SetText(encounters[encounterID].name)
			module.options.line[j].wipeBK:SetText(encounters[encounterID].firstKill or "-")
			module.options.line[j].wipe:SetText(encounters[encounterID].pulls)
			module.options.line[j].kill:SetText(encounters[encounterID].kills)
			module.options.line[j].firstBlood:SetText(encounters[encounterID].firstBlood[1] and encounters[encounterID].firstBlood[1][1] or "")
			module.options.line[j].longest:SetText(date("%M:%S",encounters[encounterID].wipeTime))
			module.options.line[j].fastest:SetText(date("%M:%S",encounters[encounterID].killTime))
			if encounters[encounterID].wipeTime == 0 then module.options.line[j].longest:SetText("-") end
			if encounters[encounterID].killTime == 0 then module.options.line[j].fastest:SetText("-") end
			
			module.options.line[j].firstBloodB.n = encounters[encounterID].firstBlood
			module.options.line[j].pullClick.n = encounters[encounterID].pullTable
			module.options.line[j].pullClick.bossName = encounters[encounterID].name or ""

			module.options.line[j]:Show()

			if j>=28 then break end
		end
		for i=(j+1),28 do
			module.options.line[i]:Hide()
		end
		module.options.ScrollBar:SetMinMaxValues(1,max(#ddL-27,1))
		module.options.FBframe:Hide()
		module.options.PullsFrame:Hide()
	end

	UIDropDownMenu_Initialize(self.dropDown, function(self, level, menuList)
		ExRT.mds.FixDropDown(180)
		local info = UIDropDownMenu_CreateInfo()
		for key,val in pairs(module.db.diffPos) do
			info.text,info.notCheckable,info.minWidth,info.justifyH = module.db.diffNames[val],1,180,"CENTER"
			info.menuList, info.hasArrow, info.arg1 = val, false, key
			info.func = self.SetValue
			UIDropDownMenu_AddButton(info)
		end
	end)

	self.line = {}
	for i=0,28 do
		self.line[i] = CreateFrame("Frame",nil,self)     
		self.line[i]:SetSize(590,18)        
		self.line[i]:SetPoint("TOPLEFT",self,10,-35-18*i) 

		self.line[i].boss = ExRT.lib.CreateText(self.line[i],300,18,"LEFT", 0,0,nil,nil,nil,11,nil,nil,1,1,1)
		self.line[i].wipeBK = ExRT.lib.CreateText(self.line[i],35,18,"LEFT", 250,0,nil,nil,nil,11,nil,nil,1,1,1)
		self.line[i].wipe = ExRT.lib.CreateText(self.line[i],35,18,"LEFT", 290,0,nil,nil,nil,11,nil,nil,1,1,1)
		self.line[i].kill = ExRT.lib.CreateText(self.line[i],35,18,"LEFT", 330,0,nil,nil,nil,11,nil,nil,1,1,1)
		self.line[i].firstBlood = ExRT.lib.CreateText(self.line[i],75,18,"LEFT", 370,0,nil,nil,nil,11,nil,nil,1,1,1)
		self.line[i].longest = ExRT.lib.CreateText(self.line[i],75,18,"LEFT", 450,0,nil,nil,nil,11,nil,nil,1,1,1)
		self.line[i].fastest = ExRT.lib.CreateText(self.line[i],75,18,"LEFT", 530,0,nil,nil,nil,11,nil,nil,1,1,1)
		
		if i>0 then
			ExRT.lib.CreateHoverHighlight(self.line[i])
			self.line[i].hl:SetVertexColor(0.3,0.3,0.7,0.7)
			self.line[i]:SetScript("OnEnter",function(self) 
				if self.pullClick.n then 
					self.hl:Show() 
				end 
			end)
			self.line[i]:SetScript("OnLeave",function(self) 
				self.hl:Hide() 
			end)		
		
			self.line[i].firstBloodB = CreateFrame("Button",nil,self.line[i])  
			self.line[i].firstBloodB:SetSize(75,18) 
			self.line[i].firstBloodB:SetPoint("TOPLEFT",370,0)
			self.line[i].firstBloodB:SetScript("OnClick",function(s) 
				if not s.n or #s.n == 0 then 
					return 
				end
				local x, y = GetCursorPosition()
				local Es = s:GetEffectiveScale()
				x, y = x/Es, y/Es
				module.options.FBframe:ClearAllPoints()
				module.options.FBframe:SetPoint("BOTTOMLEFT",UIParent,x,y)
				for i=1,5 do
					if s.n[i] then
						module.options.FBframe.txtL[i]:SetText(s.n[i][1])
						module.options.FBframe.txtR[i]:SetText(s.n[i][2])
						module.options.FBframe.txtR[i]:Show()
						module.options.FBframe.txtL[i]:Show()				
					else
						module.options.FBframe.txtR[i]:Hide()
						module.options.FBframe.txtL[i]:Hide()
					end
				end
				module.options.FBframe:Show() 
				module.options.PullsFrame:Hide()
			end)
			self.line[i].firstBloodB:SetScript("OnEnter",function(s) 
				module.options.line[i].firstBlood:SetTextColor(1,1,0.5,1)
			end)
			self.line[i].firstBloodB:SetScript("OnLeave",function(s) 
				module.options.line[i].firstBlood:SetTextColor(1,1,1,1)
			end)


			self.line[i].pullClick = CreateFrame("Button",nil,self.line[i])  
			self.line[i].pullClick:SetSize(35,18) 
			self.line[i].pullClick:SetPoint("TOPLEFT",290,0)
			self.line[i].pullClick:SetScript("OnClick",function(s) 
				local x, y = GetCursorPosition()
				local Es = s:GetEffectiveScale()
				x, y = x/Es, y/Es
				module.options.PullsFrame:ClearAllPoints()
				module.options.PullsFrame:SetPoint("BOTTOMLEFT",UIParent,x,y)
				module.options.PullsFrame.data = s.n
				module.options.PullsFrame.boss = s.bossName
				module.options.PullsFrame.ScrollBar:SetValue(1)
				module.options.PullsFrame:SetBoss()
			end)
			self.line[i].pullClick:SetScript("OnEnter",function(s) 
				module.options.line[i].wipe:SetTextColor(1,0.5,0.5,1)
			end)
			self.line[i].pullClick:SetScript("OnLeave",function(s) 
				module.options.line[i].wipe:SetTextColor(1,1,1,1)
			end)		
		end
	end
	self.line[0].wipe:SetSize(50,18)
	self.line[0].wipe:SetPoint("LEFT", 287,0)

	self.line[0].boss:SetText(ExRT.L.sencounterBossName)
	self.line[0].wipeBK:SetText(ExRT.L.sencounterFirstKill)
	self.line[0].wipe:SetText(ExRT.L.sencounterWipes)
	self.line[0].kill:SetText(ExRT.L.sencounterKills)
	self.line[0].firstBlood:SetText(ExRT.L.sencounterFirstBlood)
	self.line[0].longest:SetText(ExRT.L.sencounterWipeTime)
	self.line[0].fastest:SetText(ExRT.L.sencounterKillTime)
	
	self.FBframe = ExRT.lib.CreatePopupFrame(self:GetName().."FirstBloodFrame",150,116)
	
	self.FBframe.txtR = {}
	self.FBframe.txtL = {}
	for i=1,5 do
		self.FBframe.txtL[i] = ExRT.lib.CreateText(self.FBframe,100,14,nil,15,-16-14*i,nil,nil,nil,11,"nam1",nil,1,1,1)
		self.FBframe.txtR[i] = ExRT.lib.CreateText(self.FBframe,40,14,"TOPRIGHT",-15,-16-14*i,"RIGHT",nil,nil,11,"123",nil,1,1,1)	
	end	
	
	self.PullsFrame = ExRT.lib.CreatePopupFrame(self:GetName().."PullsFrame",270,252,"")
	
	self.PullsFrame.txtL = {}
	for i=1,15 do
		self.PullsFrame.txtL[i] = ExRT.lib.CreateText(self.PullsFrame,230,14,nil,15,-16-14*i,nil,nil,nil,11,"",nil,1,1,1)
	end	
	
	self.PullsFrame.ScrollBar = ExRT.lib.CreateScrollBar2(self:GetName().."PullsFrameScrollBar",self.PullsFrame,14,214,-6,-28,1,1,"TOPRIGHT")
	self.PullsFrame.ScrollBar:SetScript("OnValueChanged", function(self,event)
		event = event - event%1
		module.options.PullsFrame:SetBoss(event)
		self:reButtonsState()
	end)
	
	function self.PullsFrame:SetBoss(scrollVal)
		local data = module.options.PullsFrame.data
		if data and #data > 0 then
			local j = 0
			for i=(scrollVal or 1),#data do
				j = j + 1
				if j <= 15 then
					module.options.PullsFrame.txtL[j]:SetText(date("%d.%m.%Y %H:%M:%S",data[i][1])..(data[i][2] > 0 and " ["..date("%M:%S",data[i][2]).."]" or "")..(data[i][3] and " (kill) " or "")..(data[i][4] > 0 and " GS:"..data[i][4] or ""))
				else
					break
				end
			end
			for i=(j+1),15 do
				module.options.PullsFrame.txtL[i]:SetText("")
			end
			if not scrollVal then
				module.options.PullsFrame.ScrollBar:SetMinMaxValues(1,max(#data-14,1))
			end
			
			module.options.PullsFrame.title:SetText(module.options.PullsFrame.boss)
			module.options.PullsFrame:Show()
			module.options.PullsFrame.ScrollBar:reButtonsState()
			module.options.FBframe:Hide()
		end		
	end
	
	self.onlyThisChar = ExRT.lib.CreateCheckBox(nil,self,nil,20,-5,ExRT.L.sencounterOnlyThisChar)
	self.onlyThisChar:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			module.db.onlyMy = true
			module.options.ScrollBar:SetValue(1)
			module.options.dropDown:SetValue(module.db.dropDownNow)
		else
			module.db.onlyMy = nil
			module.options.ScrollBar:SetValue(1)
			module.options.dropDown:SetValue(module.db.dropDownNow)
		end
	end)	
	
	self.ScrollBar = ExRT.lib.CreateScrollBar(self:GetName().."ScrollBar",self,14,511,-5,-52,1,1,"TOPRIGHT")
	self.ScrollBar:SetScript("OnValueChanged", function(self,event)
		if event%1>0.01 then
			module.options.ScrollBar:SetValue(ExRT.mds.Round(event))
			return
		end
		event = ExRT.mds.Round(event)
		module.db.scrollPos = event
		module.options.dropDown:SetValue(module.db.dropDownNow)
	end)
	self.ScrollBar:SetScript("OnShow",function() 
		module.options.dropDown:SetValue(module.db.dropDownNow) 
	end)
	
	self.clearButton = CreateFrame("Button",self:GetName().."ButtonRemove",self,"UIPanelCloseButton") 
	self.clearButton:SetSize(22,22) 
	self.clearButton:SetPoint("TOP",40,-8) 
	self.clearButton.tooltipText = ExRT.L.EncounterClear
	self.clearButton:SetScript("OnClick", function() 
		StaticPopupDialogs["EXRT_ENCOUNTER_CLEAR"] = {
			text = ExRT.L.EncounterClearPopUp,
			button1 = ExRT.L.YesText,
			button2 = ExRT.L.NoText,
			OnAccept = function()
				table.wipe(VExRT.Encounter.list)
				table.wipe(VExRT.Encounter.names)
				if module.options.ScrollBar:GetValue() == 1 then
					local func = module.options.ScrollBar:GetScript("OnValueChanged")
					func(module.options.ScrollBar,1)
				else
					module.options.ScrollBar:SetValue(1)
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_ENCOUNTER_CLEAR")
	end) 
	self.clearButton:SetScript("OnEnter",ExRT.lib.OnEnterTooltip)
	self.clearButton:SetScript("OnLeave",ExRT.lib.OnLeaveTooltip)

	self.dropDown:SetValue(6)
end

local function DiffInArray(diff)
	for i=1,#module.db.diffPos do
		if module.db.diffPos[i] == diff then
			return true
		end
	end
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.Encounter = VExRT.Encounter or {}
	VExRT.Encounter.list = VExRT.Encounter.list or {}
	VExRT.Encounter.names = VExRT.Encounter.names or {}
	
	if VExRT.Addon.Version < 2022 then
		local newTable = {}
		local newTableNames = {}
		for encID,encData in pairs(VExRT.Encounter.list) do
			local encHex = ExRT.mds.tohex(encID,3)
			for diffID,diffData in pairs(encData) do
				if tonumber(diffID) then
					local diffHex = ExRT.mds.tohex(diffID - 1)
					for _,pullData in pairs(diffData) do
						local pull = pullData.pull
						local long = "000"
						local kill = "0"
						local gs = format("%02d",pullData.gs or 0)
						if pullData.wipe then
							long = ExRT.mds.tohex(pullData.wipe - pull,3)
						end
						if pullData.kill then
							long = ExRT.mds.tohex(pullData.kill - pull,3)
							kill = "1"
						end
						local name = pullData.player or 0
						newTable[name] = newTable[name] or {}
						table.insert(newTable[name],encHex..diffHex..format("%010d",pull)..long..kill..gs..(pullData.fb or ""))
					end
				end
			end
			newTableNames[tonumber(encHex,16)] = encData.name or "Unknown"
		end
		VExRT.Encounter.list = newTable
		VExRT.Encounter.names = newTableNames
	end
	
	module.db.playerName = UnitName("player") or 0
	VExRT.Encounter.list[module.db.playerName] = VExRT.Encounter.list[module.db.playerName] or {}
	
	module:RegisterEvents('ENCOUNTER_START','ENCOUNTER_END')
end

--AAABCCCCCCCCCCDDDEFF
--
--AAA = encounterID [hex]
--B = diffID - 1 [hex]
--CCCCCCCCCC = pull UNIX time
--DDD - pull time [hex]
--E - kill (1) or wipe (0)
--FF - groupSize

function module.main:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
	if not DiffInArray(difficultyID) or module.db.afterCombatFix then
		return
	end
	module.db.isEncounter = encounterID
	module.db.diff = difficultyID
	module.db.pullTime = time()
	module.db.nowInTable = #VExRT.Encounter.list[module.db.playerName] + 1
	VExRT.Encounter.list[module.db.playerName][module.db.nowInTable] = ExRT.mds.tohex(encounterID,3)..ExRT.mds.tohex(difficultyID-1)..format("%010d",module.db.pullTime).."0000"..format("%02d",groupSize or 0)
	VExRT.Encounter.names[encounterID] = encounterName
	module.db.firstBlood = nil
	module:RegisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
end

function module.main:ENCOUNTER_END(encounterID,_,_,_,success)
	if not module.db.isEncounter then
		return
	end
	if encounterID == module.db.isEncounter then
		local str = VExRT.Encounter.list[module.db.playerName][module.db.nowInTable]
		local time_ = min(time() - module.db.pullTime,4095)
		VExRT.Encounter.list[module.db.playerName][module.db.nowInTable] = string.sub(str,1,14) .. ExRT.mds.tohex(time_,3) .. (success == 1 and "1" or "0") .. string.sub(str,19)
	end
	module.db.isEncounter = nil
	module.db.diff = nil
	module.db.nowInTable = nil
	module.db.afterCombatFix = true
	ExRT.mds.ScheduleTimer(function() module.db.afterCombatFix = nil end, 5)
	module:UnregisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
end

function module.main:COMBAT_LOG_EVENT_UNFILTERED(_,event,_,_,_,_,_,destGUID,destName,destFlags)
	if event == "UNIT_DIED" and destName and GetUnitInfoByUnitFlag(destFlags,1) == 1024 then
		module.db.firstBlood = true
		VExRT.Encounter.list[module.db.playerName][module.db.nowInTable] = VExRT.Encounter.list[module.db.playerName][module.db.nowInTable] .. destName
		module:UnregisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
	end
end