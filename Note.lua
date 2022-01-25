local GlobalAddonName, ExRT = ...

local VExRT = nil

local module = ExRT.mod:New("Note",ExRT.L.message)
module.db.iconsList = {
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
}
module.db.otherIconsList = {
	{"{"..ExRT.L.classLocalizate["WARRIOR"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:0:64|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0,0.25,0,0.25},
	{"{"..ExRT.L.classLocalizate["PALADIN"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:128:192|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0,0.25,0.5,0.75},
	{"{"..ExRT.L.classLocalizate["HUNTER"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:64:128|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0,0.25,0.25,0.5},
	{"{"..ExRT.L.classLocalizate["ROGUE"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:0:64|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.49609375,0.7421875,0,0.25},
	{"{"..ExRT.L.classLocalizate["PRIEST"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:127:190:64:128|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.49609375,0.7421875,0.25,0.5},
	{"{"..ExRT.L.classLocalizate["DEATHKNIGHT"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:128:128:192|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.25,0.5,0.5,0.75},
	{"{"..ExRT.L.classLocalizate["SHAMAN"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:64:128|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.25,0.49609375,0.25,0.5},
	{"{"..ExRT.L.classLocalizate["MAGE"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:64:127:0:64|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.25,0.49609375,0,0.25},
	{"{"..ExRT.L.classLocalizate["WARLOCK"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:64:128|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.7421875,0.98828125,0.25,0.5},
	{"{"..ExRT.L.classLocalizate["MONK"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:128:189:128:192|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.5,0.73828125,0.5,0.75},
	{"{"..ExRT.L.classLocalizate["DRUID"] .."}","|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:190:253:0:64|t","Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",0.7421875,0.98828125,0,0.25},
	{"{wow}","|TInterface\\FriendsFrame\\Battlenet-WoWicon:16|t","Interface\\FriendsFrame\\Battlenet-WoWicon"},
	{"{d3}","|TInterface\\FriendsFrame\\Battlenet-D3icon:16|t","Interface\\FriendsFrame\\Battlenet-D3icon"},
	{"{sc2}","|TInterface\\FriendsFrame\\Battlenet-Sc2icon:16|t","Interface\\FriendsFrame\\Battlenet-Sc2icon"},
	--{"{bnet}","|TInterface\\FriendsFrame\\Battlenet-Portrait:16|t","Interface\\FriendsFrame\\Battlenet-Portrait"},
	{"{wow}","|TInterface\\FriendsFrame\\Battlenet-WoWicon:16|t","Interface\\FriendsFrame\\Battlenet-WoWicon"},
	{"{alliance}","|TInterface\\FriendsFrame\\PlusManz-Alliance:16|t","Interface\\FriendsFrame\\PlusManz-Alliance"},
	{"{horde}","|TInterface\\FriendsFrame\\PlusManz-Horde:16|t","Interface\\FriendsFrame\\PlusManz-Horde"},
}
module.db.iconsLocalizatedNames = {
	ExRT.L.raidtargeticon1,ExRT.L.raidtargeticon2,ExRT.L.raidtargeticon3,ExRT.L.raidtargeticon4,ExRT.L.raidtargeticon5,ExRT.L.raidtargeticon6,ExRT.L.raidtargeticon7,ExRT.L.raidtargeticon8
}
module.db.msgindex = -1
module.db.lasttext = ""

local function txtWithIcons(t)
	t = t or ""
	t = string.gsub(t,"||T","|T")
	t = string.gsub(t,"||t","|t")
	for i=1,8 do
		t = string.gsub(t,module.db.iconsLocalizatedNames[i],module.db.iconsList[i])
		t = string.gsub(t,"{rt"..i.."}",module.db.iconsList[i])
	end
	t = string.gsub(t,"||c","|c")
	t = string.gsub(t,"||r","|r")
	for i=1,#module.db.otherIconsList do
		t = string.gsub(t,module.db.otherIconsList[i][1],module.db.otherIconsList[i][2])
	end
	
	t = string.gsub(t,"{[^}]*}","")
	return t
end


function module.options:Load()
	self.tabs = ExRT.lib.CreateTabFrame(self:GetName().."Tab",self,614,330,15,-150,7,1,ExRT.L.messageTab1,ExRT.L.messageTab2.." 1",ExRT.L.messageTab2.." 2",ExRT.L.messageTab2.." 3",ExRT.L.messageTab2.." 4",ExRT.L.messageTab2.." 5",ExRT.L.messageTab2.." 6")
	ExRT.lib.SetPoint(self.tabs,"TOP",self,0,-150)
	for i=1,7 do
		self.tabs.tabs[i].button:SetScript("OnClick", function(s)
			module.options.tabs.selected = i
			module.options.tabs:UpdateTabs()
			
			ExRT.lib.ShowOrHide(module.options.buttonsend,i == 1)
			ExRT.lib.ShowOrHide(module.options.buttonclear,i == 1)
			ExRT.lib.ShowOrHide(module.options.buttoncopy,i ~= 1)
			
			if i == 1 then
				module.options.editbox.EditBox:SetText(VExRT.Note.Text1 or "")
			else
				module.options.editbox.EditBox:SetText(VExRT.Note.Black[i] or "")
			end
		end)
	end

	self.editbox = ExRT.lib.CreateMultiEditBox(self:GetName().."Frame",self.tabs,596,314,"TOP",0,-8)
	self.editbox.EditBox:SetScript("OnTextChanged",function(self)
		if module.options.tabs.selected > 1 then
			VExRT.Note.Black[module.options.tabs.selected] = self:GetText()
		end
	end)

	self.buttonsend = ExRT.lib.CreateButton(nil,self,300,22,nil,10,-10,ExRT.L.messagebutsend,nil,ExRT.L.messagebutsendtooltip)
	self.buttonsend:SetScript("OnClick",function() 
		module.frame:Save() 
	end) 

	self.buttonclear = ExRT.lib.CreateButton(nil,self,300,22,"TOPRIGHT",-10,-10,ExRT.L.messagebutclear)
	self.buttonclear:SetScript("OnClick",function() 
		module.frame:Clear() 
	end) 

	self.buttoncopy = ExRT.lib.CreateButton(nil,self,600,22,"TOP",0,-10,ExRT.L.messageButCopy)
	self.buttoncopy:SetScript("OnClick",function() 
		local h = module.options.tabs.tabs[1].button:GetScript("OnClick")
		VExRT.Note.Text1 = VExRT.Note.Black[module.options.tabs.selected] or ""
		h(module.options.tabs.tabs[1].button)
		module.frame:Save() 
	end) 
	self.buttoncopy:Hide()
	
	local function AddTextToEditBox(self,text,mypos)
		local addedText = nil
		if not self then
			addedText = text
		else
			addedText = self.iconText
		end
		local txt = module.options.editbox.EditBox:GetText()
		local pos = module.options.editbox.EditBox:GetCursorPosition()
		if not self and mypos then
			pos = mypos
		end
		txt = string.sub (txt, 1 , pos) .. addedText .. string.sub (txt, pos+1)
		module.options.editbox.EditBox:SetText(txt)
		module.options.editbox.EditBox:SetCursorPosition(pos+string.len(addedText))
	end

	self.buttonicons = {}
	for i=1,8 do
		self.buttonicons[i] = CreateFrame("Button", nil,self)
		self.buttonicons[i]:SetSize(18,18)
		self.buttonicons[i]:SetPoint("TOPLEFT", 16+(i-1)*20,-34)
		self.buttonicons[i].back = self.buttonicons[i]:CreateTexture(nil, "BACKGROUND")
		self.buttonicons[i].back:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..i)
		self.buttonicons[i].back:SetAllPoints()
		self.buttonicons[i]:RegisterForClicks("LeftButtonDown")
		self.buttonicons[i].iconText = module.db.iconsLocalizatedNames[i]
		self.buttonicons[i]:SetScript("OnClick", AddTextToEditBox)
	end
	for i=1,#module.db.otherIconsList do
		self.buttonicons[i] = CreateFrame("Button", nil,self)
		self.buttonicons[i]:SetSize(18,18)
		self.buttonicons[i]:SetPoint("TOPLEFT", 176+(i-1)*20,-34)
		self.buttonicons[i].back = self.buttonicons[i]:CreateTexture(nil, "BACKGROUND")
		self.buttonicons[i].back:SetTexture(module.db.otherIconsList[i][3])
		if module.db.otherIconsList[i][4] then
			self.buttonicons[i].back:SetTexCoord(unpack(module.db.otherIconsList[i],4,7))
		end
		self.buttonicons[i].back:SetAllPoints()
		self.buttonicons[i]:RegisterForClicks("LeftButtonDown")
		self.buttonicons[i].iconText = module.db.otherIconsList[i][1]
		self.buttonicons[i]:SetScript("OnClick", AddTextToEditBox)
	end
	
	self.dropDownColor = CreateFrame("Frame", self:GetName().."DropDownColor", self, "UIDropDownMenuTemplate")
	self.dropDownColor:SetPoint("TOPRIGHT",self,"TOPLEFT",627,-30)
	self.dropDownColor:SetWidth(70)
	self.dropDownColor.list = {
		{ExRT.L.NoteColorRed,"|cffff0000"},
		{ExRT.L.NoteColorGreen,"|cff00ff00"},
		{ExRT.L.NoteColorBlue,"|cff0000ff"},
		{ExRT.L.NoteColorYellow,"|cffffff00"},
		{ExRT.L.NoteColorPurple,"|cffff00ff"},
		{ExRT.L.NoteColorAzure,"|cff00ffff"},
		{ExRT.L.NoteColorBlack,"|cff000000"},
		{ExRT.L.NoteColorGrey,"|cff808080"},
		{ExRT.L.NoteColorRedSoft,"|cffee5555"},
		{ExRT.L.NoteColorGreenSoft,"|cff55ee55"},
		{ExRT.L.NoteColorBlueSoft,"|cff5555ee"},
	}
	local classNames = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","MONK","DRUID"}
	for i,class in ipairs(classNames) do
		local colorTable = RAID_CLASS_COLORS[class]
		if colorTable then
			self.dropDownColor.list[#self.dropDownColor.list + 1] = {ExRT.L.classLocalizate[class],"|c"..colorTable.colorStr}
		end
	end
	self.dropDownColor:SetScript("OnEnter",function (self)
		ExRT.lib.TooltipShow(self,"ANCHOR_LEFT",ExRT.L.NoteColor,{ExRT.L.NoteColorTooltip1,1,1,1,true},{ExRT.L.NoteColorTooltip2,1,1,1,true})
	end)
	self.dropDownColor:SetScript("OnLeave",function ()
		ExRT.lib.TooltipHide()
	end)	
	UIDropDownMenu_SetText(self.dropDownColor, ExRT.L.NoteColor)
	UIDropDownMenu_SetWidth(self.dropDownColor, 70)
	UIDropDownMenu_Initialize(self.dropDownColor, function(self, level, menuList)
		ExRT.mds.FixDropDown(180)
		local info = UIDropDownMenu_CreateInfo()
		for i,colorData in ipairs(self.list) do
			info.text,info.notCheckable,info.minWidth,info.justifyH = colorData[1],1,180,"CENTER"
			info.menuList, info.hasArrow, info.arg1 = i, false, colorData[2]
			info.func = self.SetValue
			info.colorCode = colorData[2]
			UIDropDownMenu_AddButton(info)
		end
	end)
	function self.dropDownColor:SetValue(colorCode)
		CloseDropDownMenus()

		local selectedStart,selectedEnd = module.options.editbox.EditBox.GetTextHighlight(module.options.editbox.EditBox)
		colorCode = string.gsub(colorCode,"|","||")
		if selectedStart == selectedEnd then
			AddTextToEditBox(nil,colorCode.."||r")
		else
			AddTextToEditBox(nil,"||r",selectedEnd)
			AddTextToEditBox(nil,colorCode,selectedStart)
		end
	end

	self.raidnames = {}
	for i=1,25 do
		self.raidnames[i] = CreateFrame("Button", nil,self)
		self.raidnames[i]:SetSize(115,14)
		self.raidnames[i]:SetPoint("TOPLEFT", 16+math.floor((i-1)/5)*117,-55-14*((i-1)%5))

		self.raidnames[i].html = ExRT.lib.CreateText(self.raidnames[i],115,14,nil,0,0,nil,nil,nil,12,"",nil,1,1,1)
		self.raidnames[i].txt = ""
		self.raidnames[i]:RegisterForClicks("LeftButtonDown")
		self.raidnames[i].iconText = ""
		self.raidnames[i]:SetScript("OnClick", AddTextToEditBox)

		self.raidnames[i]:SetScript("OnEnter", function(self)
			self.html:SetShadowColor(0.2, 0.2, 0.2, 1)
		end)
		self.raidnames[i]:SetScript("OnLeave", function(self)
			self.html:SetShadowColor(0, 0, 0, 1)
		end)
	end

	self.chkEnable = ExRT.lib.CreateCheckBox(nil,self,nil,10,-480,ExRT.L.senable)
	self.chkEnable:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Note.enabled = true
			module.frame:Show()
		else
			VExRT.Note.enabled = nil
			module.frame:Hide()
		end
	end)  
	
	self.chkFix = ExRT.lib.CreateCheckBox(nil,self,nil,161,-480,ExRT.L.messagebutfix,nil,ExRT.L.messagebutfixtooltip)  
	self.chkFix:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Note.Fix = true
			module.frame:SetMovable(false)
			module.frame:EnableMouse(false)
			module.frame.buttonResize:Hide()
			ExRT.lib.AddShadowComment(module.frame,1)
		else
			VExRT.Note.Fix = nil
			module.frame:SetMovable(true)
			module.frame:EnableMouse(true)
			module.frame.buttonResize:Show()
			ExRT.lib.AddShadowComment(module.frame,nil,ExRT.L.message)
		end
	end) 

	self.chkOutline = ExRT.lib.CreateCheckBox(nil,self,nil,311,-480,ExRT.L.messageOutline)  
	self.chkOutline:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Note.Outline = true
			module.frame.text:SetFont(ExRT.mds.defFont, 12,"OUTLINE")
		else
			VExRT.Note.Outline = nil
			module.frame.text:SetFont(ExRT.mds.defFont, 12)
		end
	end) 
	 
	self.slideralpha = ExRT.lib.CreateSlider(self:GetName().."SliderAlpha",self,180,15,20,-530,0,100,ExRT.L.messagebutalpha)
	self.slideralpha:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.Note.Alpha = event
		module.frame:SetAlpha(event/100)
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	
	self.sliderscale = ExRT.lib.CreateSlider(self:GetName().."SliderScale",self,180,15,220,-530,5,200,ExRT.L.messagebutscale,100)
	self.sliderscale:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.Note.Scale = event
		ExRT.mds.SetScaleFix(module.frame,event/100)
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.slideralphaback = ExRT.lib.CreateSlider(self:GetName().."SliderAlphaBack",self,180,15,420,-530,0,100,ExRT.L.messageBackAlpha)
	self.slideralphaback:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.Note.ScaleBack = event
		module.frame.background:SetTexture(0, 0, 0, event/100)
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	
	self.ButtonToCenter = ExRT.lib.CreateButton(nil,self,161,24,nil,452,-483,ExRT.L.MarksBarResetPos,nil,ExRT.L.MarksBarResetPosTooltip)
	self.ButtonToCenter:SetScript("OnClick",function()
		VExRT.Note.Left = nil
		VExRT.Note.Top = nil

		module.frame:ClearAllPoints()
		module.frame:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
	end) 


	self.chkEnable:SetChecked(VExRT.Note.enabled)

	if VExRT.Note.Text1 then 
		self.editbox.EditBox:SetText(VExRT.Note.Text1) 
	end
	if VExRT.Note.Alpha then 
		self.slideralpha:SetValue(VExRT.Note.Alpha)
	end
	if VExRT.Note.Scale then 
		self.sliderscale:SetValue(VExRT.Note.Scale) 
	end
	if VExRT.Note.ScaleBack then 
		self.slideralphaback:SetValue(VExRT.Note.ScaleBack) 
	end
	self.chkFix:SetChecked(VExRT.Note.Fix)
	self.chkOutline:SetChecked(VExRT.Note.Outline)

	module:RegisterEvents("GROUP_ROSTER_UPDATE")
	module.main:GROUP_ROSTER_UPDATE()
end


module.frame = CreateFrame("Frame",nil,UIParent)
module.frame:SetSize(200,100)
module.frame:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
module.frame:EnableMouse(true)
module.frame:SetMovable(true)
module.frame:RegisterForDrag("LeftButton")
module.frame:SetScript("OnDragStart", function(self)
	if self:IsMovable() then
		self:StartMoving()
	end
end)
module.frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	VExRT.Note.Left = self:GetLeft()
	VExRT.Note.Top = self:GetTop()
end)
module.frame:SetFrameStrata("TOOLTIP")
module.frame:SetResizable(true)
module.frame:SetMinResize(30, 30)
module.frame:SetScript("OnSizeChanged", function (self, width, height)
	local width_, height_ = self:GetSize()
	VExRT.Note.Width = width
	VExRT.Note.Height = height
	module.frame.text:SetText(txtWithIcons(VExRT.Note.Text1)) 
end)
module.frame:Hide() 

module.frame.background = module.frame:CreateTexture(nil, "BACKGROUND")
module.frame.background:SetTexture(0, 0, 0, 1)
module.frame.background:SetAllPoints()

module.frame.text = module.frame:CreateFontString(nil,"ARTWORK")
module.frame.text:SetFont(ExRT.mds.defFont, 12)
module.frame.text:SetPoint("TOPLEFT",5,-5)
module.frame.text:SetPoint("BOTTOMRIGHT",-5,5)
module.frame.text:SetJustifyH("LEFT")
module.frame.text:SetJustifyV("TOP")
module.frame.text:SetText(" ")

module.frame.buttonResize = CreateFrame("Frame",nil,module.frame)
module.frame.buttonResize:SetSize(15,15)
module.frame.buttonResize:SetPoint("BOTTOMRIGHT", 0, 0)
module.frame.buttonResize.back = module.frame.buttonResize:CreateTexture(nil, "BACKGROUND")
module.frame.buttonResize.back:SetTexture("Interface\\AddOns\\ExRT\\media\\Resize.tga")
module.frame.buttonResize.back:SetAllPoints()
module.frame.buttonResize:SetScript("OnMouseDown", function(self)
	module.frame:StartSizing()
end)
module.frame.buttonResize:SetScript("OnMouseUp", function(self)
	module.frame:StopMovingOrSizing()
end)


function module.frame:Save()
	VExRT.Note.Text1 = module.options.editbox.EditBox:GetText() 
	local txttosand = VExRT.Note.Text1
	local arrtosand = {}
	local j = 1
	local indextosnd = tostring(GetTime())..tostring(math.random(1000,9999))
	for i=1,#txttosand do
		if i%220 == 0 then
			arrtosand[j]=string.sub (txttosand, (j-1)*220+1, j*220)
			j = j + 1
		elseif i == #txttosand then
			arrtosand[j]=string.sub (txttosand, (j-1)*220+1)
			j = j + 1
		end
	end
	for i=1,#arrtosand do
		ExRT.mds.SendExMsg("multiline",indextosnd.."\t"..arrtosand[i])
	end
end 

function module.frame:Clear() 
	module.options.editbox.EditBox:SetText("") 
end 

function module:addonMessage(sender, prefix, ...)
	if prefix == "multiline" then
		local msgnowindex,lastnowtext = ...
		if tostring(msgnowindex) == tostring(module.db.msgindex) then
			module.db.lasttext = module.db.lasttext .. lastnowtext
		else
			module.db.lasttext = lastnowtext
		end
		module.db.msgindex = msgnowindex
		VExRT.Note.Text1 = module.db.lasttext
		module.frame.text:SetText(txtWithIcons(VExRT.Note.Text1))
		if module.options.editbox then
			module.options.editbox.EditBox:SetText(VExRT.Note.Text1)
		end
	end 
end 

local gruevent = {}

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.Note = VExRT.Note or {}
	VExRT.Note.Black = VExRT.Note.Black or {}

	if VExRT.Note.Left and VExRT.Note.Top then 
		module.frame:ClearAllPoints()
		module.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Note.Left,VExRT.Note.Top)
	end

	if VExRT.Note.Width then 
		module.frame:SetWidth(VExRT.Note.Width) 
	end
	if VExRT.Note.Height then 
		module.frame:SetHeight(VExRT.Note.Height) 
	end

	if VExRT.Note.enabled then 
		module.frame:Show() 
	end

	if VExRT.Note.Text1 then 
		module.frame.text:SetText(txtWithIcons(VExRT.Note.Text1))
	end
	if VExRT.Note.Alpha then 
		module.frame:SetAlpha(VExRT.Note.Alpha/100) 
	end
	if VExRT.Note.Scale then 
		module.frame:SetScale(VExRT.Note.Scale/100) 
	end
	if VExRT.Note.ScaleBack then
		module.frame.background:SetTexture(0, 0, 0, VExRT.Note.ScaleBack/100)
	end
	if VExRT.Note.Outline then
		module.frame.text:SetFont(ExRT.mds.defFont, 12,"OUTLINE")
	end
	if VExRT.Note.Fix then
		module.frame:SetMovable(false)
		module.frame:EnableMouse(false)
		module.frame.buttonResize:Hide()
	else
		ExRT.lib.AddShadowComment(module.frame,nil,ExRT.L.message)
	end
	
	module:RegisterAddonMessage()
end

function module.main:GROUP_ROSTER_UPDATE()
	local n = GetNumGroupMembers() or 0
	local gMax = ExRT.mds.GetRaidDiffMaxGroup()
	for i=1,6 do gruevent[i] = 0 end
	for i=1,n do
		local name,_,subgroup,_,_,class = GetRaidRosterInfo(i)
		if name and subgroup <= gMax then
			gruevent[subgroup] = gruevent[subgroup] + 1
			local cR,cG,cB = ExRT.mds.classColorNum(class)

			local obj = module.options.raidnames[gruevent[subgroup]+(subgroup-1)*5]
			if obj then
				obj.iconText = name and name.." " or ""
				obj.html:SetText(obj.txt)
				obj.html:SetTextColor(cR, cG, cB, 1)
			end
		end
	end
	for i=1,5 do
		for j=(gruevent[i]+1),5 do
			module.options.raidnames[(i-1)*5+j].iconText = ""
			module.options.raidnames[(i-1)*5+j].html:SetText("")
		end
	end
end 