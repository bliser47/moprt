local GlobalAddonName, ExRT = ...

local VExRT = nil

local parentModule = _G.GExRTExCD2Global
if not parentModule then
	return
end
local module = ExRT.mod:New("InspectViewer",ExRT.L.InspectViewer)
module.db.inspectDB = parentModule.db.inspectDB
module.db.inspectQuery = parentModule.db.inspectQuery
module.db.specIcons = parentModule.db.specIcons
module.db.itemsSlotTable = parentModule.db.itemsSlotTable
module.db.classIDs = {WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,SHAMAN=7,MAGE=8,WARLOCK=9,MONK=10,DRUID=11}
module.db.glyphsIDs = {9,11,13,10,8,12}

module.db.statsList = {'intellect','agility','strength','spirit','haste','mastery','crit','spellpower'}
module.db.statsListName = {ExRT.L.InspectViewerInt,ExRT.L.InspectViewerAgi,ExRT.L.InspectViewerStr,ExRT.L.InspectViewerSpirit,ExRT.L.InspectViewerHaste,ExRT.L.InspectViewerMastery,ExRT.L.InspectViewerCrit,ExRT.L.InspectViewerSpd}

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.InspectViewer = VExRT.InspectViewer or {}
	if VExRT.InspectViewer.enabled and (not VExRT.ExCD2 or not VExRT.ExCD2.enabled) then
		module:Enable()
	end
end

function module.main:INSPECT_READY()
	module.options.showPage()
end

function module:Enable()
	parentModule:RegisterTimer()
	parentModule:RegisterEvents('GROUP_ROSTER_UPDATE','INSPECT_READY','UNIT_INVENTORY_CHANGED','PLAYER_EQUIPMENT_CHANGED')
	parentModule.main:GROUP_ROSTER_UPDATE()
end

function module:Disable()
	if not VExRT or not VExRT.ExCD2 or not VExRT.ExCD2.enabled then
		parentModule:UnregisterTimer()
		parentModule:UnregisterEvents('GROUP_ROSTER_UPDATE','INSPECT_READY','UNIT_INVENTORY_CHANGED','PLAYER_EQUIPMENT_CHANGED')
	end
end

module.db.perPage = 17
module.db.page = 1

function module.options:Load()
	self.chkEnable = ExRT.lib.CreateCheckBox(nil,self,nil,480,-5,ExRT.L.senable)
	self.chkEnable:SetScript("OnClick", function(self,event) 
		VExRT.InspectViewer.enabled = self:GetChecked()
		if self:GetChecked() then
			module:Enable()
		else
			module:Disable()
		end
	end)
	self.chkEnable:SetScript("OnUpdate", function (self)
		local x, y = GetCursorPosition()
		local s = self:GetEffectiveScale()
		x, y = x/s, y/s
		local t,l,b,r = self:GetTop(),self:GetLeft(),self:GetBottom(),self:GetRight()
		if x >= l and x <= r and y <= t and y >= b then
			self.tooltip = true
			ExRT.lib.TooltipShow(self,"ANCHOR_RIGHT",ExRT.L.InspectViewerEnabledTooltip)
		elseif self.tooltip then
			self.tooltip = nil
			GameTooltip_Hide()
		end
	end)
	local function chkEnableShow(self)
		if VExRT and VExRT.ExCD2 and VExRT.ExCD2.enabled then
			self:SetChecked(true)
			self:SetEnabled(false)
		else
			self:SetChecked(VExRT.InspectViewer.enabled)
			self:SetEnabled(true)
		end
	end
	self.chkEnable:SetScript("OnShow",chkEnableShow)
	chkEnableShow(self.chkEnable)
	
	local function reloadChks(self)
		local clickID = self.id
		self:SetChecked(true)
		if clickID == 1 then
			module.options.chkTalents:SetChecked(false)
			module.options.chkInfo:SetChecked(false)
		elseif clickID == 2 then
			module.options.chkItems:SetChecked(false)
			module.options.chkInfo:SetChecked(false)	
		elseif clickID == 3 then
			module.options.chkItems:SetChecked(false)
			module.options.chkTalents:SetChecked(false)	
		end
		module.db.page = clickID
		module.options.showPage()
	end
	
	self.chkTalents = CreateFrame("CheckButton",nil,self,"UIRadioButtonTemplate")  
	self.chkTalents:SetPoint("TOPLEFT", 160, -11)
	self.chkTalents.text:SetText(ExRT.L.InspectViewerTalents)
	self.chkTalents:SetScript("OnClick", reloadChks)
	self.chkTalents.id = 2

	self.chkInfo = CreateFrame("CheckButton",nil,self,"UIRadioButtonTemplate")  
	self.chkInfo:SetPoint("TOPLEFT", 310, -11)
	self.chkInfo.text:SetText(ExRT.L.InspectViewerInfo)
	self.chkInfo:SetScript("OnClick", reloadChks)
	self.chkInfo.id = 3
	
	self.chkItems = CreateFrame("CheckButton",nil,self,"UIRadioButtonTemplate")  
	self.chkItems:SetPoint("TOPLEFT", 10, -11)
	self.chkItems.text:SetText(ExRT.L.InspectViewerItems)
	self.chkItems:SetScript("OnClick", reloadChks)
	self.chkItems.id = 1
	self.chkItems:SetChecked(true)
	
	self.borderList = CreateFrame("Frame",nil,self)
	self.borderList:SetSize(610,module.db.perPage*30+2)
	self.borderList:SetPoint("TOP", 0, -35)
	self.borderList:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 8})
	self.borderList:SetBackdropColor(0,0,0,0.3)
	self.borderList:SetBackdropBorderColor(0.6,0.6,0.6,0.9)
	
	self.borderList:SetScript("OnMouseWheel",function (self,delta)
		if delta > 0 then
			module.options.ScrollBar.buttonUP:Click("LeftButton")
		else
			module.options.ScrollBar.buttonDown:Click("LeftButton")
		end
	end)
	
	self.ScrollBar = ExRT.lib.CreateScrollBar2(self:GetName().."ScrollBar",self.borderList,18,module.db.perPage*30-5,-1,-3,1,20,"TOPRIGHT")
	self.ScrollBar:SetScript("OnUpdate",self.ScrollBar.reButtonsState)

	function module.options.ReloadPage()
		local nowDB = {}
		for name,data in pairs(module.db.inspectDB) do
			table.insert(nowDB,{name,data})
		end
		for name,_ in pairs(module.db.inspectQuery) do
			if not module.db.inspectDB[name] then
				table.insert(nowDB,{name})
			end
		end
		table.sort(nowDB,function(a,b) return a[1] < b[1] end)

		local scrollNow = ExRT.mds.Round(module.options.ScrollBar:GetValue())
		local counter = 0
		for i=scrollNow,#nowDB do
			counter = counter + 1
			
			module.options.lines[counter].name:SetText(nowDB[i][1])
			if nowDB[i][2] then
				local class = nowDB[i][2].class
				local classIconCoords = CLASS_ICON_TCOORDS[class]
				if classIconCoords then
					module.options.lines[counter].class.texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
					module.options.lines[counter].class.texture:SetTexCoord(unpack(classIconCoords))
				else
					module.options.lines[counter].class.texture:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
				end
				
				local spec = nowDB[i][2].spec
				local specIcon = module.db.specIcons[spec]
				if not specIcon and VExRT and VExRT.ExCD2 and VExRT.ExCD2.gnGUIDs and VExRT.ExCD2.gnGUIDs[ nowDB[i][1] ] then
					spec = VExRT.ExCD2.gnGUIDs[ nowDB[i][1] ]
					specIcon = module.db.specIcons[spec]
				end
				
				if specIcon then
					module.options.lines[counter].spec.texture:SetTexture(specIcon)
					module.options.lines[counter].spec.id = spec
				else
					module.options.lines[counter].spec.texture:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
					module.options.lines[counter].spec.id = nil
				end
				
				module.options.lines[counter].ilvl:SetText(format("%.2f",nowDB[i][2].ilvl or 0))
				
				if module.db.page == 1 then
					for j=1,16 do
						module.options.lines[counter].items[j]:Show()
					end
					module.options.lines[counter].time:Hide()
					module.options.lines[counter].otherInfo:Hide()
				
					local items = nowDB[i][2].items
					if items then
						for j=1,#module.db.itemsSlotTable do
							local item = items[module.db.itemsSlotTable[j]]
							if item then
								local itemID = string.match(item,"item:(%d+):")
								itemID = itemID and tonumber(itemID) or 0
								local itemTexture = GetItemIcon(itemID)
								module.options.lines[counter].items[j].texture:SetTexture(itemTexture)
								module.options.lines[counter].items[j].link = item
								module.options.lines[counter].items[j]:Show()		
							else
								module.options.lines[counter].items[j]:Hide()
							end
						end
					else
						for j=1,16 do
							module.options.lines[counter].items[j]:Hide()
						end
					end
				elseif module.db.page == 2 then
					for j=1,16 do
						ExRT.lib.ShowOrHide(module.options.lines[counter].items[j],j<=14)
					end
					module.options.lines[counter].time:Hide()
					module.options.lines[counter].otherInfo:Hide()
				
					for j=1,7 do
						local t = nowDB[i][2][j]
						if t and t ~= 0 then
							t = (j-1)*3+t
							local spellTexture = select(2,GetTalentInfo(t,1,nil,nil,module.db.classIDs[class]))
							module.options.lines[counter].items[j].texture:SetTexture(spellTexture)
							module.options.lines[counter].items[j].link = GetTalentLink(t,1,module.db.classIDs[class])
							module.options.lines[counter].items[j].sid = nil
							module.options.lines[counter].items[j]:Show()
						else
							module.options.lines[counter].items[j]:Hide()
						end
					end
					module.options.lines[counter].items[8]:Hide()
					for j=9,14 do
						local t = nowDB[i][2][module.db.glyphsIDs[j-8]]
						if t then
							local spellTexture = GetSpellTexture(t)
							module.options.lines[counter].items[j].texture:SetTexture(spellTexture)
							module.options.lines[counter].items[j].link = "|cffffffff|Hspell:"..t.."|h[name]|h|r"
							module.options.lines[counter].items[j].sid = t
							module.options.lines[counter].items[j]:Show()
						else
							module.options.lines[counter].items[j]:Hide()
						end
					end
				elseif module.db.page == 3 then
					for j=1,16 do
						module.options.lines[counter].items[j]:Hide()
					end
					module.options.lines[counter].time:Show()
					module.options.lines[counter].time:SetText(date("%H:%M:%S",nowDB[i][2].time))
					
					local result = ""
					for k,statName in ipairs(module.db.statsList) do
						local statValue = nowDB[i][2][statName]
						if statValue and statValue > 200 then
							if k <= 3 then
								statValue = floor(statValue * 1.05)
							elseif k <= 7 and nowDB[i][2].amplify and nowDB[i][2].amplify ~= 0 then
								statValue = floor(statValue * (1 + nowDB[i][2].amplify/100))
							end
							result = result .. module.db.statsListName[k] .. ": " ..statValue..", "
						end
					end
					if nowDB[i][2].radiness and nowDB[i][2].radiness ~= 0 then
						result = result..ExRT.L.InspectViewerRadiness..": "..format("%.2f%%",(nowDB[i][2].radiness or 0) * 100)
					else
						if string.len(result) > 0 then
							result = string.sub(result,1,-3)
						end
					end
					module.options.lines[counter].otherInfo:SetText(result)
					module.options.lines[counter].otherInfo:Show()
				end
				
				local cR,cG,cB = ExRT.mds.classColorNum(class)
				module.options.lines[counter].back:SetGradientAlpha("HORIZONTAL", cR,cG,cB, 0.5, cR,cG,cB, 0)
			else
				for j=1,16 do
					module.options.lines[counter].items[j]:Hide()
				end
				module.options.lines[counter].time:Show()
				module.options.lines[counter].time:SetText(ExRT.L.InspectViewerNoData)
				
				module.options.lines[counter].otherInfo:Hide()
				
				module.options.lines[counter].class.texture:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
				module.options.lines[counter].class.texture:SetTexCoord(0,1,0,1)
				module.options.lines[counter].spec.texture:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
				module.options.lines[counter].spec.id = nil
				module.options.lines[counter].ilvl:SetText("")
				
				module.options.lines[counter].back:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.5, 0, 0, 0, 0)
			end
			
			module.options.lines[counter]:Show()
			if counter >= module.db.perPage then
				break
			end
		end
		for i=(counter+1),module.db.perPage do
			module.options.lines[i]:Hide()
		end
	end
	self.ScrollBar:SetScript("OnValueChanged", module.options.ReloadPage)
	
	local function NoIlvl()
		self.raidItemLevel:SetText("")
	end
	
	function module.options.RaidIlvl()
		if not IsInRaid() then
			NoIlvl()
			return
		end
		local n = GetNumGroupMembers() or 0
		local gMax = ExRT.mds.GetRaidDiffMaxGroup()
		local ilvl = 0
		local countPeople = 0
		for i=1,n do
			local name,_,subgroup = GetRaidRosterInfo(i)
			if name and subgroup <= gMax then
				if module.db.inspectDB[name] and module.db.inspectDB[name].ilvl and module.db.inspectDB[name].ilvl >= 1 then
					countPeople = countPeople + 1
					ilvl = ilvl + module.db.inspectDB[name].ilvl
				end
			end
		end
		if countPeople == 0 then
			NoIlvl()
			return
		end
		ilvl = ilvl / countPeople
		self.raidItemLevel:SetText(ExRT.L.InspectViewerRaidIlvl..": "..format("%.02f",ilvl).." ("..format(ExRT.L.InspectViewerRaidIlvlData,countPeople)..")")
	end
	
	self.lines = {}
	for i=1,module.db.perPage do
		self.lines[i] = CreateFrame("Frame",nil,self.borderList)
		self.lines[i]:SetSize(592,30)
		self.lines[i]:SetPoint("TOPLEFT",0,-(i-1)*30-1)
		
		self.lines[i].name = ExRT.lib.CreateText(self.lines[i],94,30,nil,5,0,"LEFT",nil,nil,11,"Name",nil,1,1,1,1)
		
		self.lines[i].class = ExRT.lib.CreateIcon(nil,self.lines[i],24,nil,100,-3)
		
		self.lines[i].spec = ExRT.lib.CreateIcon(nil,self.lines[i],24,nil,130,-3)
		self.lines[i].spec:SetScript("OnEnter",function (self)
			if self.id then
				local _,name,descr = GetSpecializationInfoByID(self.id)
				ExRT.lib.TooltipShow(self,"ANCHOR_LEFT",name,{descr,1,1,1,true})
			end
		end)
		self.lines[i].spec:SetScript("OnLeave",function (self)
			GameTooltip_Hide()
		end)
		
		self.lines[i].ilvl = ExRT.lib.CreateText(self.lines[i],50,30,nil,160,0,"LEFT",nil,nil,11,"630.52",nil,1,1,1,1)
		
		self.lines[i].items = {}
		for j=1,16 do
			self.lines[i].items[j] = ExRT.lib.CreateIcon(nil,self.lines[i],22,nil,210+(24*(j-1)),-4,nil,true)
			self.lines[i].items[j]:SetScript("OnEnter",function (self)
				if self.link then
					GameTooltip:SetOwner(self, "ANCHOR_LEFT")
					GameTooltip:SetHyperlink(self.link)
					GameTooltip:Show()
				end
			end)
			self.lines[i].items[j]:SetScript("OnLeave",function (self)
				GameTooltip_Hide()
			end)
			self.lines[i].items[j]:SetScript("OnClick",function (self)
				if self.link then
					if module.db.page == 1 then
						ExRT.mds.LinkItem(nil, self.link)
					elseif module.db.page == 2 then
						if self.sid then
							ExRT.mds.LinkSpell(self.sid)
						else
							ExRT.mds.LinkSpell(nil,self.link)
						end
					end
				end
			end)
		end
		
		self.lines[i].time = ExRT.lib.CreateText(self.lines[i],80,30,nil,205,0,"CENTER",nil,nil,11,date("%H:%M:%S",time()),nil,1,1,1,1)
		self.lines[i].otherInfo = ExRT.lib.CreateText(self.lines[i],305,30,nil,285,0,"LEFT",nil,nil,10,"",nil,1,1,1,1)
		
		self.lines[i].back = self.lines[i]:CreateTexture(nil, "BACKGROUND")
		self.lines[i].back:SetPoint("TOPLEFT",2,-1)
		self.lines[i].back:SetPoint("BOTTOMRIGHT",0,0)
		self.lines[i].back:SetTexture( 1, 1, 1, 1)
		self.lines[i].back:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 1, 0, 0, 0, 0)
	end
	self.raidItemLevel = ExRT.lib.CreateText(self,500,20,nil,10,-549,nil,"TOP",nil,12,"",nil,1,1,1,1)
	
	function module.options.showPage()
		local count = 0
		for _ in pairs(module.db.inspectDB) do
			count = count + 1
		end
		for name,_ in pairs(module.db.inspectQuery) do
			if not module.db.inspectDB[name] then
				count = count + 1
			end
		end
		self.ScrollBar:SetMinMaxValues(1,max(count-module.db.perPage+1,1))
		module.options.ReloadPage()
		
		module.options.RaidIlvl()
	end
	
	self.borderList:SetScript("OnShow",module.options.showPage)
	module:RegisterEvents("INSPECT_READY")
	module.options.showPage()
end