local GlobalAddonName, ExRT = ...

ExRT.Options = {}
ExRT.Options.panel = CreateFrame( "Frame", "ExRTOptionsPanel" )
ExRT.Options.panel.name = "Exorsus Raid Tools"
InterfaceOptions_AddCategory(ExRT.Options.panel)
ExRT.Options.panel:Hide()

----> Minimap Icon

ExRT.MiniMapIcon = CreateFrame("Button", "ExRTMiniMapButton", Minimap)
ExRT.MiniMapIcon:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight") 
ExRT.MiniMapIcon:SetSize(32,32) 
ExRT.MiniMapIcon:SetFrameStrata("MEDIUM")
ExRT.MiniMapIcon:SetFrameLevel(8)
ExRT.MiniMapIcon:SetPoint("CENTER", -12, -80)
ExRT.MiniMapIcon:SetDontSavePosition(true)
ExRT.MiniMapIcon.icon = ExRT.MiniMapIcon:CreateTexture(nil, "BACKGROUND")
ExRT.MiniMapIcon.icon:SetTexture("Interface\\AddOns\\ExRT\\media\\MiniMap")
ExRT.MiniMapIcon.icon:SetSize(32,32)
ExRT.MiniMapIcon.icon:SetPoint("CENTER", 0, 0)
ExRT.MiniMapIcon.border = ExRT.MiniMapIcon:CreateTexture(nil, "ARTWORK")
ExRT.MiniMapIcon.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
ExRT.MiniMapIcon.border:SetTexCoord(0,0.6,0,0.6)
ExRT.MiniMapIcon.border:SetAllPoints()
ExRT.MiniMapIcon:RegisterForClicks("RightButtonDown","LeftButtonDown")
ExRT.MiniMapIcon:SetScript("OnEnter",function(self) 
	GameTooltip:SetOwner(self, "ANCHOR_LEFT") 
	GameTooltip:AddLine("Exorsus Raid Tools") 
	GameTooltip:AddLine(ExRT.L.minimaptooltiplmp,1,1,1) 
	GameTooltip:AddLine(ExRT.L.minimaptooltipfree,1,1,1) 
	GameTooltip:AddLine(ExRT.L.minimaptooltiprmp,1,1,1) 
	GameTooltip:Show() 
end)
ExRT.MiniMapIcon:SetScript("OnLeave", function(self)    
	GameTooltip:Hide()
end)

local function IconMoveButton(self)
	if self.dragMode == "free" then
		local centerX, centerY = Minimap:GetCenter()
		local x, y = GetCursorPosition()
		x, y = x / self:GetEffectiveScale() - centerX, y / self:GetEffectiveScale() - centerY
		self:ClearAllPoints()
		self:SetPoint("CENTER", x, y)
		VExRT.Addon.IconMiniMapLeft = x
		VExRT.Addon.IconMiniMapTop = y
	else
		local centerX, centerY = Minimap:GetCenter()
		local x, y = GetCursorPosition()

		local diff = ( (x-self.sX)^2 + (y-self.sY)^2 )^0.5
		if diff < 15 and self.lock then
			return
		elseif diff >= 15 then
			self.lock = nil
		end

		x, y = x / self:GetEffectiveScale() - centerX, y / self:GetEffectiveScale() - centerY
		centerX, centerY = math.abs(x), math.abs(y)
		centerX, centerY = (centerX / math.sqrt(centerX^2 + centerY^2)) * 80, (centerY / sqrt(centerX^2 + centerY^2)) * 80
		centerX = x < 0 and -centerX or centerX
		centerY = y < 0 and -centerY or centerY
		self:ClearAllPoints()
		self:SetPoint("CENTER", centerX, centerY)
		VExRT.Addon.IconMiniMapLeft = centerX
		VExRT.Addon.IconMiniMapTop = centerY
	end
end

ExRT.MiniMapIcon:SetScript("OnMouseDown", function(self, button)
	if IsShiftKeyDown() and IsAltKeyDown() then
		self.dragMode = "free"
		self:SetScript("OnUpdate", IconMoveButton)
	elseif IsShiftKeyDown() or button == "LeftButton" then
		self.dragMode = nil
		local x, y = GetCursorPosition()
		self.sX = x
		self.sY = y
		self.lock = 1
		self:SetScript("OnUpdate", IconMoveButton)
	elseif button == "RightButton" then
		self.lock = 1
	end
end)

ExRT.Options.panel.dropdown = CreateFrame("Frame", "ExRTMiniMapMenuFrame", nil, "UIDropDownMenuTemplate")

function ExRT.mds.MinimapMenuAdd(text_, func_)
	local k = #ExRT.mds.menuTable
	for i=1,k do
		if ExRT.mds.menuTable[i].text == text_ then return end
	end
	ExRT.mds.menuTable[k+1] = ExRT.mds.menuTable[k]
	ExRT.mds.menuTable[k] = { text = text_, func = func_, notCheckable = true, keepShownOnClick = true, }
end

function ExRT.mds.MinimapMenuRemove(text_)
	local k = #ExRT.mds.menuTable
	for i=1,k do
		if ExRT.mds.menuTable[i].text == text_ then 
			for j=i+1,k do
				ExRT.mds.menuTable[j-1] = ExRT.mds.menuTable[j]
			end
			ExRT.mds.menuTable[k] = nil
			return 
		end
	end
end

function ExRT.Options:Open()
	if InterfaceOptionsFrame:IsShown() then
		return
	end
	InterfaceOptionsFrame_OpenToCategory(ExRT.Options.panel)
	InterfaceOptionsFrame_OpenToCategory(ExRT.Options.panel)
	local toggleButton
	for _,button in pairs(InterfaceOptionsFrameAddOns.buttons) do
		if button.element then
			if button.element.name == ExRT.Options.panel.name then 
				toggleButton = button
				break
			end
		end
	end
	if toggleButton and toggleButton.element.collapsed then 
		OptionsListButtonToggle_OnClick(toggleButton.toggle) 
	end
end

ExRT.mds.menuTable = {
{ text = ExRT.L.minimapmenu, isTitle = true, notCheckable = true, notClickable = true },
{ text = ExRT.L.minimapmenuset, func = ExRT.Options.Open, notCheckable = true, keepShownOnClick = true, },
{ text = ExRT.L.minimapmenuclose, func = function() CloseDropDownMenus() end, notCheckable = true },
}

ExRT.MiniMapIcon:SetScript("OnMouseUp", function(self, button)
	self:SetScript("OnUpdate", nil)
	if not self.lock then 
		return 
	elseif button == "RightButton" then
		for i, val in pairs(ExRT.MiniMapMenu) do
			val:miniMapMenu()
		end
		EasyMenu(ExRT.mds.menuTable, ExRT.Options.panel.dropdown, "cursor", 10 , -15, "MENU")
	elseif button == "LeftButton" then
		ExRT.Options:Open()
	end
end)


----> Options

ExRT.Options.panel.title = ExRT.lib.CreateText(ExRT.Options.panel,500,22,nil,160,-52,nil,nil,nil,22,"Exorsus Raid Tools",nil,1,1,1)

ExRT.Options.panel.image = CreateFrame("FRAME",nil,ExRT.Options.panel)
ExRT.Options.panel.image:SetSize(256,256)
ExRT.Options.panel.image:SetBackdrop({bgFile = "Interface\\AddOns\\ExRT\\media\\OptionLogo"})
ExRT.Options.panel.image:SetPoint("TOPLEFT", -30,-4)	
ExRT.Options.panel.image:SetFrameLevel(5)

ExRT.Options.panel.chkIconMiniMap = ExRT.lib.CreateCheckBox(nil,ExRT.Options.panel,nil,25,-165,ExRT.L.setminimap1)
ExRT.Options.panel.chkIconMiniMap:SetScript("OnClick", function(self,event) 
	if self:GetChecked() then
		VExRT.Addon.IconMiniMapHide = true
		ExRT.MiniMapIcon:Hide()
	else
		VExRT.Addon.IconMiniMapHide = nil
		ExRT.MiniMapIcon:Show()
	end
end)
ExRT.Options.panel.chkIconMiniMap:SetScript("OnShow", function(self,event) 
	self:SetChecked(VExRT.Addon.IconMiniMapHide) 
end)

ExRT.Options.panel.timerSlider = ExRT.lib.CreateSlider("ExRTOptionsPanelTimerSlider",ExRT.Options.panel,550,15,0,-145,10,1000,ExRT.L.setEggTimerSlider,100,"TOP")
ExRT.Options.panel.timerSlider:Hide()
ExRT.Options.panel.timerSlider:SetScript("OnValueChanged", function(self,event) 
	event = event - event%1
	self.tooltipText = event
	self:tooltipReload(self)	
	event = event / 1000	
	VExRT.Addon.Timer = event
end)

ExRT.Options.panel.eventsCountTextLeft = ExRT.lib.CreateText(ExRT.Options.panel,590,300,"TOPLEFT",15,-300,"LEFT","TOP",nil,12,nil,nil,1,1,1,1)
ExRT.Options.panel.eventsCountTextRight = ExRT.lib.CreateText(ExRT.Options.panel,590,300,"TOPLEFT",85,-300,"LEFT","TOP",nil,12,nil,nil,1,1,1,1)
ExRT.Options.panel.eventsCountTextFrame = CreateFrame("Frame",nil,ExRT.Options.panel)
ExRT.Options.panel.eventsCountTextFrame:SetSize(1,1)
ExRT.Options.panel.eventsCountTextFrame:SetPoint("TOPLEFT")
ExRT.Options.panel.eventsCountTextFrame:Hide()
ExRT.Options.panel.eventsCountTextFrame:SetScript("OnShow",function()
	local tmp = {}
	for i=1,#ExRT.Modules do
		if ExRT.Modules[i].main.eventsCounter then
			for event,count in pairs(ExRT.Modules[i].main.eventsCounter) do
				if not tmp[event] then
					tmp[event] = count
				else
					tmp[event] = max(tmp[event],count)
				end
			end
		end
	end
	tmp["COMBAT_LOG_EVENT_UNFILTERED"] = ExRT.CLEUframe.eventsCounter or 0
	local tmp2 = {}
	local total = 0
	for event,count in pairs(tmp) do
		table.insert(tmp2,{event,count})
		total = total + count
	end
	table.sort(tmp2,function(a,b) return a[2] > b[2] end)
	local h = total.."\n"
	local n = "Total\n"
	for i=1,#tmp2 do
		h = h .. tmp2[i][2].."\n"
		n = n .. tmp2[i][1] .."\n"
	end
	ExRT.Options.panel.eventsCountTextLeft:SetText(h)
	ExRT.Options.panel.eventsCountTextRight:SetText(n)
end)

ExRT.Options.panel.eggBut = CreateFrame("Button",nil,ExRT.Options.panel)  
ExRT.Options.panel.eggBut:SetSize(12,12) 
ExRT.Options.panel.eggBut:SetPoint("TOPLEFT",89,-52)
ExRT.Options.panel.eggBut:SetFrameLevel(8)
ExRT.Options.panel.eggBut:SetScript("OnClick",function(s) 
	local superMode = nil
	ExRT.Options.panel.timerSlider:SetValue(VExRT.Addon.Timer*1000 or 100)
	ExRT.Options.panel.timerSlider:Show()
	ExRT.Options.panel.eventsCountTextFrame:Show()
	if IsShiftKeyDown() then
		return
	end
	if IsAltKeyDown() then
		superMode = true
	end
	for i, val in pairs(ExRT.Eggs) do
		val:egg(superMode)
	end
end)

ExRT.Options.panel.authorLeft = ExRT.lib.CreateText(ExRT.Options.panel,150,25,nil,25,-220,"LEFT","TOP",nil,12,ExRT.L.setauthor,nil,nil,nil,nil,1)
ExRT.Options.panel.authorRight = ExRT.lib.CreateText(ExRT.Options.panel,450,25,nil,135,-220,"LEFT","TOP",nil,12,"Afiya (Афиа) @ EU-Howling Fjord",nil,1,1,1,1)

ExRT.Options.panel.versionLeft = ExRT.lib.CreateText(ExRT.Options.panel,150,25,nil,25,-240,"LEFT","TOP",nil,12,ExRT.L.setver,nil,nil,nil,nil,1)
ExRT.Options.panel.versionRight = ExRT.lib.CreateText(ExRT.Options.panel,450,25,nil,135,-240,"LEFT","TOP",nil,12,ExRT.V..(ExRT.T == "R" and "" or " "..ExRT.T),nil,1,1,1,1)

ExRT.Options.panel.contactLeft = ExRT.lib.CreateText(ExRT.Options.panel,150,25,nil,25,-260,"LEFT","TOP",nil,12,ExRT.L.setcontact,nil,nil,nil,nil,1)
ExRT.Options.panel.contactRight = ExRT.lib.CreateText(ExRT.Options.panel,450,25,nil,135,-260,"LEFT","TOP",nil,12,"e-mail: ykiigor@gmail.com",nil,1,1,1,1)

ExRT.Options.panel.thanksLeft = ExRT.lib.CreateText(ExRT.Options.panel,150,25,nil,25,-280,"LEFT","TOP",nil,12,ExRT.L.SetThanks,nil,nil,nil,nil,1)
ExRT.Options.panel.thanksRight = ExRT.lib.CreateText(ExRT.Options.panel,450,25,nil,135,-280,"LEFT","TOP",nil,12,"Phanx, funkydude, Shurshik, Kemayo",nil,1,1,1,1)
