local GlobalAddonName, ExRT = ...

local GetTime, GetRaidTargetIndex, SetRaidTarget, UnitName, SetRaidTargetIcon = GetTime, GetRaidTargetIndex, SetRaidTarget, UnitName, SetRaidTargetIcon

local VExRT = nil

local module = ExRT.mod:New("MarksBar",ExRT.L.marksbar)
module.db.perma = {}
module.db.clearnum = -1
module.db.iconsList = {
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
}
module.db.worldMarksList = {
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
	"Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
	"Interface\\AddOns\\ExRT\\media\\flare_del.blp",
}
module.db.wm_color ={
	{ r = 4/255, g = 149/255, b = 255/255},
	{ r = 15/255, g = 155/255 , b = 12/255},
	{ r = 168/255, g = 14/255, b = 192/255},
	{ r = 167/255, g = 20/255 , b = 13/255},
	{ r = 222/255, g = 218/255, b = 50/255},
	{ r = 0.7, g = 0.7, b = 0.7 },
}

module.db.wm_color_hover ={
	{ r = 100/255, g = 189/255, b = 255/255},
	{ r = 15/255, g = 215/255 , b = 12/255},
	{ r = 220/255, g = 67/255, b = 241/255},
	{ r = 240/255, g = 77/255 , b = 68/255},
	{ r = 243/255, g = 242/255, b = 182/255},
	{ r = 1.0, g = 1.0, b = 1.0 },
}


module.frame = CreateFrame("Frame",nil,UIParent)
module.frame:SetSize(370,34)
module.frame:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
module.frame:SetFrameStrata("HIGH")
module.frame:EnableMouse(true)
module.frame:SetMovable(true)
module.frame:SetClampedToScreen(true)
module.frame:RegisterForDrag("LeftButton")
module.frame:SetScript("OnDragStart", function(self) 
	if self:IsMovable() then 
		self:StartMoving() 
	end 
end)
module.frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	VExRT.MarksBar.Left = self:GetLeft()
	VExRT.MarksBar.Top = self:GetTop()
end)
module.frame:SetBackdrop({bgFile = ExRT.mds.barImg})
module.frame:SetBackdropColor(0,0,0,0.8)
module.frame:Hide()
module:RegisterHideOnPetBattle(module.frame)

module.frame.edge = CreateFrame("Frame",nil,module.frame)
module.frame.edge:SetSize(368,32)
module.frame.edge:SetPoint("TOPLEFT", 1, -1)
module.frame.edge:SetBackdrop({bgFile = ExRT.mds.barImg,edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 6})
module.frame.edge:SetBackdropColor(0,0,0,0)
module.frame.edge:SetBackdropBorderColor(0.6,0.6,0.6,1)

module.frame.markbuts = {}
for i=1,8 do
	module.frame.markbuts[i] = CreateFrame("Frame",nil,module.frame)
	module.frame.markbuts[i]:SetSize(26,26)
	module.frame.markbuts[i]:SetPoint("TOPLEFT", 4+(i-1)*28, -4)
	module.frame.markbuts[i]:SetBackdrop({bgFile = ExRT.mds.barImg,edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 8})
	module.frame.markbuts[i]:SetBackdropColor(0,0,0,0)
	module.frame.markbuts[i]:SetBackdropBorderColor(0.4,0.4,0.4,1)

	module.frame.markbuts[i].but = CreateFrame("Button",nil,module.frame.markbuts[i])
	module.frame.markbuts[i].but:SetSize(20,20)
	module.frame.markbuts[i].but:SetPoint("TOPLEFT",  3, -3)
	module.frame.markbuts[i].but.t = module.frame.markbuts[i].but:CreateTexture(nil, "BACKGROUND")
	module.frame.markbuts[i].but.t:SetTexture(module.db.iconsList[i])
	module.frame.markbuts[i].but.t:SetAllPoints()

	module.frame.markbuts[i].but:SetScript("OnEnter",function(self) 
		if not module.db.perma[i] then
			module.frame.markbuts[i]:SetBackdropBorderColor(0.7,0.7,0.7,1)
		end
	end)
		
	module.frame.markbuts[i].but:SetScript("OnLeave", function(self)    
		if not module.db.perma[i] then
			module.frame.markbuts[i]:SetBackdropBorderColor(0.4,0.4,0.4,1)
		end
	end)

	module.frame.markbuts[i].but:RegisterForClicks("RightButtonDown","LeftButtonDown")
	module.frame.markbuts[i].but:SetScript("OnClick", function(self , button)
		if button == "RightButton" then
			if not module.db.perma[i] then
				module.frame.markbuts[i]:SetBackdropBorderColor(0.2,0.8,0.2,1)
				module.db.perma[i] = UnitName("target")
				SetRaidTargetIcon("target", i)
			else
				module.frame.markbuts[i]:SetBackdropBorderColor(0.7,0.7,0.7,1)
				module.db.perma[i] = nil
			end
		else
			SetRaidTargetIcon("target", i)
		end
	end)
end

module.frame.start = CreateFrame("Button",nil,module.frame)
module.frame.start:SetSize(50,12)
module.frame.start:SetPoint("TOPLEFT", 228, -4)
module.frame.start:SetBackdrop({bgFile = ExRT.mds.barImg,edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 6})
module.frame.start:SetBackdropColor(0,0,0,0)
module.frame.start:SetBackdropBorderColor(0.4,0.4,0.4,1)
module.frame.start:SetScript("OnEnter",function(self) 
	self:SetBackdropBorderColor(0.7,0.7,0.7,1)
end)	
module.frame.start:SetScript("OnLeave", function(self)    
	self:SetBackdropBorderColor(0.4,0.4,0.4,1)
end)
module.frame.start:SetScript("OnClick", function(self)    
	module.db.clearnum = GetTime()
	for i=1,8 do
		SetRaidTarget("player", i) 
	end
end)

module.frame.start.html = module.frame.start:CreateFontString(nil,"ARTWORK")
module.frame.start.html:SetFont(ExRT.mds.defFont, 10)
module.frame.start.html:SetAllPoints()
module.frame.start.html:SetJustifyH("CENTER")
module.frame.start.html:SetText(ExRT.L.marksbarstart)
module.frame.start.html:SetShadowOffset(1,-1)

module.frame.del = CreateFrame("Button",nil,module.frame)
module.frame.del:SetSize(50,12)
module.frame.del:SetPoint("TOPLEFT", 228, -18)
module.frame.del:SetBackdrop({bgFile = ExRT.mds.barImg,edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 6})
module.frame.del:SetBackdropColor(0,0,0,0)
module.frame.del:SetBackdropBorderColor(0.4,0.4,0.4,1)
module.frame.del:SetScript("OnEnter",function(self) 
	self:SetBackdropBorderColor(0.7,0.7,0.7,1)
end)	
module.frame.del:SetScript("OnLeave", function(self)    
	self:SetBackdropBorderColor(0.4,0.4,0.4,1)
end)
module.frame.del:SetScript("OnClick", function(self)    
	for i=1,8 do
		if module.db.perma[i] and UnitName(module.db.perma[i]) then
			SetRaidTargetIcon(module.db.perma[i], 0)
		end
		module.db.perma[i] = nil
		module.frame.markbuts[i]:SetBackdropBorderColor(0.4,0.4,0.4,1)
	end
end)

module.frame.del.html = module.frame.del:CreateFontString(nil,"ARTWORK")
module.frame.del.html:SetFont(ExRT.mds.defFont, 10)
module.frame.del.html:SetAllPoints()
module.frame.del.html:SetJustifyH("CENTER")
module.frame.del.html:SetText(ExRT.L.marksbardel)
module.frame.del.html:SetShadowOffset(1,-1)

module.frame.wmarksbuts = CreateFrame("Frame",nil,module.frame)
module.frame.wmarksbuts:SetSize(42,26)
module.frame.wmarksbuts:SetPoint("TOPLEFT", 383, -4)
for i=1,6 do
	module.frame.wmarksbuts[i] = CreateFrame("Button",nil,module.frame.wmarksbuts,"SecureActionButtonTemplate")
	module.frame.wmarksbuts[i]:SetSize(14,13)
	module.frame.wmarksbuts[i]:SetPoint("TOPLEFT", ((i-1)%3)*14, -math.floor((i-1)/3)*13)
	module.frame.wmarksbuts[i]:SetBackdrop({bgFile = "",edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 6})
	module.frame.wmarksbuts[i]:SetBackdropColor(0,0,0,0)
	module.frame.wmarksbuts[i]:SetBackdropBorderColor(0.4,0.4,0.4,0)
	module.frame.wmarksbuts[i]:SetScript("OnEnter",function(self) 
		self:SetBackdropBorderColor(0.7,0.7,0.7,1)
	end)	
	module.frame.wmarksbuts[i]:SetScript("OnLeave", function(self)    
		self:SetBackdropBorderColor(0.4,0.4,0.4,0)
	end)
	
	if i < 6 then
		module.frame.wmarksbuts[i]:RegisterForClicks("AnyDown")
		module.frame.wmarksbuts[i]:SetAttribute("type", "macro")
		module.frame.wmarksbuts[i]:SetAttribute("macrotext1", format("/wm %d", i))
		module.frame.wmarksbuts[i]:SetAttribute("macrotext2", format("/cwm %d", i))
		module.frame.wmarksbuts[i]:SetScript('OnEvent', function(self, event, ...) self[event](self, event, ...) end)
	else
		module.frame.wmarksbuts[i]:SetScript("OnClick", ClearRaidMarker)
	end

	module.frame.wmarksbuts[i].t = module.frame.wmarksbuts[i]:CreateTexture(nil, "BACKGROUND")
	module.frame.wmarksbuts[i].t:SetTexture(module.db.worldMarksList[i])
	module.frame.wmarksbuts[i].t:SetSize(10,10)
	module.frame.wmarksbuts[i].t:SetPoint("CENTER",module.frame.wmarksbuts[i], "CENTER", 0,0)
end


module.frame.wmarksbuts.b = CreateFrame("Frame",nil,module.frame)
module.frame.wmarksbuts.b:SetSize(123,32)
module.frame.wmarksbuts.b:SetPoint("TOPLEFT", 30, -25)
module.frame.wmarksbuts.b:SetFrameLevel(0)
module.frame.wmarksbuts.b.t = module.frame.wmarksbuts.b:CreateTexture(nil, "BACKGROUND")
module.frame.wmarksbuts.b.t:SetTexture("Interface\\AddOns\\ExRT\\media\\MarksBarBot.tga")
module.frame.wmarksbuts.b.t:SetAllPoints()
module.frame.wmarksbuts.b.t:SetVertexColor(0.5,0.5,0.5,0.8)
module.frame.wmarksbuts.b.t:SetTexCoord(0, 123/128, 0, 0.5)

for i=1,6 do
	module.frame.wmarksbuts.b[i] = CreateFrame("Button",nil,module.frame.wmarksbuts.b,"SecureActionButtonTemplate")
	module.frame.wmarksbuts.b[i]:SetSize(18,18)
	module.frame.wmarksbuts.b[i]:SetPoint("TOPLEFT", 19*(i-1)+6, -12)
	module.frame.wmarksbuts.b[i].t = module.frame.wmarksbuts.b[i]:CreateTexture(nil, "BACKGROUND")
	if i == 6 then
		module.frame.wmarksbuts.b[i].t:SetTexture(module.db.worldMarksList[i])
	else
		module.frame.wmarksbuts.b[i].t:SetTexture("Interface\\AddOns\\ExRT\\media\\blip")
	end
	module.frame.wmarksbuts.b[i].t:SetSize(16,16)
	module.frame.wmarksbuts.b[i].t:SetPoint("TOPLEFT", 1, 0)
	module.frame.wmarksbuts.b[i].t:SetVertexColor(module.db.wm_color[i].r,module.db.wm_color[i].g,module.db.wm_color[i].b,1)
	
	module.frame.wmarksbuts.b[i]:SetScript("OnEnter",function(self) 
		self.t:SetVertexColor(module.db.wm_color_hover[i].r,module.db.wm_color_hover[i].g,module.db.wm_color_hover[i].b,1)
	end)	
	module.frame.wmarksbuts.b[i]:SetScript("OnLeave", function(self)    
		self.t:SetVertexColor(module.db.wm_color[i].r,module.db.wm_color[i].g,module.db.wm_color[i].b,1)
	end)

	if i < 6 then
		module.frame.wmarksbuts.b[i]:RegisterForClicks("AnyDown")
		module.frame.wmarksbuts.b[i]:SetAttribute("type", "macro")
		module.frame.wmarksbuts.b[i]:SetAttribute("macrotext1", format("/wm %d", i))
		module.frame.wmarksbuts.b[i]:SetAttribute("macrotext2", format("/cwm %d", i))
		module.frame.wmarksbuts.b[i]:SetScript('OnEvent', function(self, event, ...) self[event](self, event, ...) end)
	else
		module.frame.wmarksbuts.b[i]:SetScript("OnClick", ClearRaidMarker)
	end
end

module.frame.readyCheck = CreateFrame("Button",nil,module.frame)
module.frame.readyCheck:SetSize(40,12)
module.frame.readyCheck:SetPoint("TOPLEFT",325,-4)
module.frame.readyCheck:SetBackdrop({bgFile = ExRT.mds.barImg,edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 6})
module.frame.readyCheck:SetBackdropColor(0,0,0,0)
module.frame.readyCheck:SetBackdropBorderColor(0.4,0.4,0.4,1)
module.frame.readyCheck:SetScript("OnEnter",function(self) 
	self:SetBackdropBorderColor(0.7,0.7,0.7,1)
end)	
module.frame.readyCheck:SetScript("OnLeave", function(self)    
	self:SetBackdropBorderColor(0.4,0.4,0.4,1)
end)
module.frame.readyCheck:SetScript("OnClick", function(self)    
	DoReadyCheck()
end)

module.frame.readyCheck.html = module.frame.readyCheck:CreateFontString(nil,"ARTWORK")
module.frame.readyCheck.html:SetFont(ExRT.mds.defFont, 10)
module.frame.readyCheck.html:SetAllPoints()
module.frame.readyCheck.html:SetJustifyH("CENTER")
module.frame.readyCheck.html:SetText(ExRT.L.marksbarrc)
module.frame.readyCheck.html:SetShadowOffset(1,-1)

module.frame.pull = CreateFrame("Button",nil,module.frame)
module.frame.pull:SetSize(40,12)
module.frame.pull:SetPoint("TOPLEFT",325, -18)
module.frame.pull:SetBackdrop({bgFile = ExRT.mds.barImg,edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 6})
module.frame.pull:SetBackdropColor(0,0,0,0)
module.frame.pull:SetBackdropBorderColor(0.4,0.4,0.4,1)
module.frame.pull:SetScript("OnEnter",function(self) 
	self:SetBackdropBorderColor(0.7,0.7,0.7,1)
end)	
module.frame.pull:SetScript("OnLeave", function(self)    
	self:SetBackdropBorderColor(0.4,0.4,0.4,1)
end)
module.frame.pull:SetScript("OnClick", function(self)    
	ExRT.mds:DoPull(VExRT.MarksBar.pulltimer)
end)

module.frame.pull.html = module.frame.pull:CreateFontString(nil,"ARTWORK")
module.frame.pull.html:SetFont(ExRT.mds.defFont, 10)
module.frame.pull.html:SetAllPoints()
module.frame.pull.html:SetJustifyH("CENTER")
module.frame.pull.html:SetText(ExRT.L.marksbarpull)
module.frame.pull.html:SetShadowOffset(1,-1)

local function modifymarkbars()
	local width_mb = 32*8+120-9
	local leftfix = 0
	if not VExRT.MarksBar.Show[1] then
		for i=1,8 do
			module.frame.markbuts[i]:Hide()
		end
		width_mb = width_mb - 8*28
		leftfix = leftfix - 8*28
	else
		for i=1,8 do
			module.frame.markbuts[i]:Show()
		end
	end
	module.frame.start:SetPoint("TOPLEFT",module.frame, "TOPLEFT", 4+8*28+leftfix, -4)
	module.frame.del:SetPoint("TOPLEFT",module.frame, "TOPLEFT", 4+8*28+leftfix, -18)
	if not VExRT.MarksBar.Show[2] then
		module.frame.start:Hide()
		module.frame.del:Hide()
		width_mb = width_mb - 52
		leftfix = leftfix - 52
	else
		module.frame.start:Show()
		module.frame.del:Show()
	end

	module.frame.wmarksbuts:SetPoint("TOPLEFT", 4+8*28+52+leftfix, -4)
	if not VExRT.MarksBar.Show[3] or not VExRT.MarksBar.wmKind then
		module.frame.wmarksbuts:Hide()
		width_mb = width_mb - 14*3 - 2
		leftfix = leftfix - 14*3 - 2
	elseif VExRT.MarksBar.Show[3] and VExRT.MarksBar.wmKind then
		module.frame.wmarksbuts:Show()
	end

	if not VExRT.MarksBar.wmKind and VExRT.MarksBar.Show[3] and VExRT.MarksBar.Show[1] then
		module.frame.wmarksbuts.b:Show()
	else
		module.frame.wmarksbuts.b:Hide()
	end

	module.frame.readyCheck:SetPoint("TOPLEFT",module.frame, "TOPLEFT", 4+8*28+54+42+leftfix,-4)
	module.frame.pull:SetPoint("TOPLEFT",module.frame, "TOPLEFT", 4+8*28+54+42+leftfix, -18)
	if not VExRT.MarksBar.Show[4] then
		module.frame.readyCheck:Hide()
		module.frame.pull:Hide()
		width_mb = width_mb - 40 - 3
		leftfix = leftfix - 40
	else
		module.frame.readyCheck:Show()
		module.frame.pull:Show()
	end
	if not (VExRT.MarksBar.Show[1] or VExRT.MarksBar.Show[2] or VExRT.MarksBar.Show[3] or VExRT.MarksBar.Show[4]) or not VExRT.MarksBar.enabled then
		module.frame:Hide()
	else
		module.frame:Show()
	end

	module.frame:SetWidth(width_mb+2)
	module.frame.edge:SetWidth(width_mb)
end

local function EnableMarksBar()
	VExRT.MarksBar.enabled = true
	module.frame:Show()
	module:RegisterEvents('RAID_TARGET_UPDATE')
	module:RegisterTimer()
end
local function DisableMarksBar()
	VExRT.MarksBar.enabled = nil
	module.frame:Hide()
	module:UnregisterEvents('RAID_TARGET_UPDATE')
	module:UnregisterTimer()
end

function module.options:Load()
	self.chkEnable = ExRT.lib.CreateCheckBox(nil,self,nil,10,-10,ExRT.L.senable)
	self.chkEnable.On = EnableMarksBar
	self.chkEnable.Off = DisableMarksBar
	
	self.html1 = ExRT.lib.CreateText(self,100,18,nil,120,-20,nil,"TOP",nil,11,"/rt mm")

	self.chkEnable1 = ExRT.lib.CreateCheckBox(nil,self,nil,10,-120,ExRT.L.marksbarshowmarks)
	self.chkEnable1:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.MarksBar.Show[1]=true
		else
			VExRT.MarksBar.Show[1]=nil
		end
		modifymarkbars()
	end)
	
	self.chkEnable2 = ExRT.lib.CreateCheckBox(nil,self,nil,10,-145,ExRT.L.marksbarshowpermarks)
	self.chkEnable2:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.MarksBar.Show[2]=true
		else
			VExRT.MarksBar.Show[2]=nil
		end
		modifymarkbars()
	end)
	
	self.chkEnable3 = ExRT.lib.CreateCheckBox(nil,self,nil,10,-170,ExRT.L.marksbarshowfloor)
	self.chkEnable3:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.MarksBar.Show[3]=true
		else
			VExRT.MarksBar.Show[3]=nil
		end
		modifymarkbars()
	end)
	
	self.chkEnable3kindhtml = ExRT.lib.CreateText(self,100,18,nil,300,-181,nil,"TOP",nil,11,ExRT.L.marksbarWMView)
	
	self.chkEnable3kind1 = CreateFrame("CheckButton",self:GetName().."ChkEnable3kind",self,"UIRadioButtonTemplate")  
	self.chkEnable3kind1:SetPoint("TOPLEFT", 380, -180)
	self.chkEnable3kind1.text:SetText("1")
	self.chkEnable3kind1:SetScript("OnClick", function(self,event) 
		module.options.chkEnable3kind2:SetChecked(not self:GetChecked())
		if self:GetChecked() then
			VExRT.MarksBar.wmKind = true
		else
			VExRT.MarksBar.wmKind = nil
		end
		modifymarkbars()
	end)
	
	self.chkEnable3kind2 = CreateFrame("CheckButton",self:GetName().."ChkEnable3kind",self,"UIRadioButtonTemplate")  
	self.chkEnable3kind2:SetPoint("TOPLEFT", 420, -180)
	self.chkEnable3kind2.text:SetText("2")
	self.chkEnable3kind2:SetScript("OnClick", function(self,event) 
		module.options.chkEnable3kind1:SetChecked(not self:GetChecked())
		if self:GetChecked() then
			VExRT.MarksBar.wmKind = nil
		else
			VExRT.MarksBar.wmKind = true
		end
		modifymarkbars()
	end)
	
	self.chkEnable4 = ExRT.lib.CreateCheckBox(nil,self,nil,10,-195,ExRT.L.marksbarshowrcpull)
	self.chkEnable4:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.MarksBar.Show[4]=true
		else
			VExRT.MarksBar.Show[4]=nil
		end
		modifymarkbars()
	end)
	
	self.SliderScale = ExRT.lib.CreateSlider(self:GetName().."SliderScale",self,550,15,0,-50,5,200,ExRT.L.marksbarscale,100,"TOP")
	self.SliderScale:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.MarksBar.Scale = event
		ExRT.mds.SetScaleFix(module.frame,event/100)
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	
	self.SliderAlpha = ExRT.lib.CreateSlider(self:GetName().."SliderAlpha",self,550,15,0,-85,0,100,ExRT.L.marksbaralpha,nil,"TOP")
	self.SliderAlpha:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.MarksBar.Alpha = event
		module.frame:SetAlpha(event/100)
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	
	
	self.htmlTimer = ExRT.lib.CreateText(self,150,18,nil,14,-231,nil,"TOP",nil,11,ExRT.L.marksbartmr)

	self.editBoxTimer = ExRT.lib.CreateEditBox(self:GetName().."EditBoxTimer",self,120,24,nil,143,-225,nil,6,1,"InputBoxTemplate","10")
	self.editBoxTimer:SetScript("OnTextChanged",function(self)
		VExRT.MarksBar.pulltimer = tonumber(self:GetText()) or 10
	end)  
	
	self.chkFix = ExRT.lib.CreateCheckBox(nil,self,nil,10,-251,ExRT.L.messagebutfix)
	self.chkFix:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.MarksBar.Fix = true
			ExRT.mds.LockMove(module.frame,nil,nil,1)
		else
			VExRT.MarksBar.Fix = nil
			ExRT.mds.LockMove(module.frame,true,nil,1)
		end
	end)
	
	self.ButtonToCenter = ExRT.lib.CreateButton(nil,self,255,24,nil,10,-285,ExRT.L.MarksBarResetPos,nil,ExRT.L.MarksBarResetPosTooltip)
	self.ButtonToCenter:SetScript("OnClick",function()
		VExRT.MarksBar.Left = nil
		VExRT.MarksBar.Top = nil

		module.frame:ClearAllPoints()
		module.frame:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
	end) 

	self.chkEnable:SetChecked(VExRT.MarksBar.enabled)

	self.chkEnable1:SetChecked(VExRT.MarksBar.Show[1])
	self.chkEnable2:SetChecked(VExRT.MarksBar.Show[2])
	self.chkEnable3:SetChecked(VExRT.MarksBar.Show[3])
	self.chkEnable4:SetChecked(VExRT.MarksBar.Show[4])
	self.chkEnable3kind1:SetChecked(VExRT.MarksBar.wmKind)
	self.chkEnable3kind2:SetChecked(not VExRT.MarksBar.wmKind)

	self.editBoxTimer:SetText(VExRT.MarksBar.pulltimer)
	self.editBoxTimer:SetCursorPosition(0)

	self.chkFix:SetChecked(VExRT.MarksBar.Fix)

	if VExRT.MarksBar.Alpha then self.SliderAlpha:SetValue(VExRT.MarksBar.Alpha) end
	if VExRT.MarksBar.Scale then self.SliderScale:SetValue(VExRT.MarksBar.Scale) end
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.MarksBar = VExRT.MarksBar or {}

	if VExRT.MarksBar.Left and VExRT.MarksBar.Top then
		module.frame:ClearAllPoints()
		module.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.MarksBar.Left,VExRT.MarksBar.Top)
	end

	VExRT.MarksBar.Show = VExRT.MarksBar.Show or {true,true,true,true}

	modifymarkbars()

	if VExRT.MarksBar.enabled then
		EnableMarksBar()
	end

	VExRT.MarksBar.pulltimer = VExRT.MarksBar.pulltimer or 10

	if VExRT.MarksBar.Fix then ExRT.mds.LockMove(module.frame,nil,nil,1) end

	if VExRT.MarksBar.Alpha then module.frame:SetAlpha(VExRT.MarksBar.Alpha/100) end
	if VExRT.MarksBar.Scale then module.frame:SetScale(VExRT.MarksBar.Scale/100) end
	
	module:RegisterSlash()
end

function module.main:RAID_TARGET_UPDATE()
	if GetTime()-module.db.clearnum<5 and GetRaidTargetIndex("player") == 8 then
		SetRaidTarget("player", 0)
		module.db.clearnum = -1
	end
end

function module:timer(elapsed)
	for i=1,8 do
		if module.db.perma[i] and UnitName(module.db.perma[i]) and GetRaidTargetIndex(module.db.perma[i])~=i then
			SetRaidTargetIcon(module.db.perma[i], i)
		end
	end
end
function module:slash(arg)
	if arg == "mm" then
		if not VExRT.MarksBar.enabled then
			EnableMarksBar()
		else
			DisableMarksBar()
		end
		if module.options.chkEnable then
			module.options.chkEnable:SetChecked(VExRT.MarksBar.enabled)
		end
	end
end