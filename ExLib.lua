-- ExRT.lib.AddShadowComment(self,hide,moduleName,userComment,userFontSize,userOutline)
-- ExRT.lib.CreateSlider(name,parent,width,height,x,y,minVal,maxVal,text,defVal,relativePoint,isVertical)
-- ExRT.lib.CreateScrollBar(name,parent,width,height,x,y,minVal,maxVal,relativePoint,isHoriz)
-- ExRT.lib.CreateScrollBar2(name,parent,width,height,x,y,minVal,maxVal,relativePoint)
-- ExRT.lib.OnEnterTooltip(self,anchorUser)
-- ExRT.lib.OnLeaveTooltip(self)
-- ExRT.lib.TooltipShow(self,anchorUser,title,...)
-- ExRT.lib.TooltipHide()
-- ExRT.lib.OnEnterHyperLinkTooltip(self,data)
-- ExRT.lib.OnLeaveHyperLinkTooltip(self)
-- ExRT.lib.EditBoxOnEnterHyperLinkTooltip(self,linkData,link)
-- ExRT.lib.EditBoxOnLeaveHyperLinkTooltip(self)
-- ExRT.lib.AdditionalTooltip(link)
-- ExRT.lib.HideAdditionalTooltips()
-- ExRT.lib.ShowOrHide(self,bool)
-- ExRT.lib.SetAlphas(alpha,...)
-- ExRT.lib.CreateTabFrame(name,parent,width,height,x,y,tabNum,activeTabNum,...)
-- ExRT.lib.CreateText(parent,width,height,relativePoint,x,y,hor,ver,font,fontSize,text,tem,colR,colG,colB,shadow,outline,doNotUseTemplate)
-- ExRT.lib.CreateEditBox(name,parent,width,height,relativePoint,x,y,tooltip,maxLetters,onlyNum,template,defText)
-- ExRT.lib.CreateScrollFrame(name,parent,width,height,relativePoint,x,y,verticalHeight)
-- ExRT.lib.CreateMultiEditBox(name,parent,width,height,relativePoint,x,y)
-- ExRT.lib.CreateMultiEditBox2(name,parent,width,height,relativePoint,x,y)
-- ExRT.lib.CreateEditSliderBox(parent,width,height,x,y,txt)
-- ExRT.lib.CreateButton(name,parent,width,height,relativePoint,x,y,text,isDisabled,tooltip)
-- ExRT.lib.CreateIcon(name,parent,size,relativePoint,x,y,textureIcon,isButton)
-- ExRT.lib.CreateCheckBox(name,parent,relativePoint,x,y,text,checked,tooltip,textLeft)
-- ExRT.lib.CreateHoverHighlight(parent)
-- ExRT.lib.CreateBackTextureForDebug(parent)
-- ExRT.lib.CreateHelpButton(parent,helpPlateArray,isTab)
-- ExRT.lib.CreateScrollList(name,parent,relativePoint,x,y,width,linesNum)
-- ExRT.lib.CreateScrollCheckList(name,parent,relativePoint,x,y,width,linesNum)
-- ExRT.lib.CreatePopupFrame(name,width,height,title)
-- ExRT.lib.CreateOneTab(parent,width,height,relativePoint,x,y,name)
-- ExRT.lib.CreateColorPickButton(parent,width,height,relativePoint,x,y,cR,cG,cB,cA)
-- ExRT.lib.CreateScrollTabsFrame(name,parent,relativePoint,x,y,width,height,noSelfBorder,...)
-- ExRT.lib.CreateHiddenFrame(name,parent,relativePoint,x,y,width,height)
-- ExRT.lib.CreateDropDown(name,parent,relativePoint,x,y,width,tooltip)
-- ExRT.lib.CreateScrollDropDown(name,parent,relativePoint,x,y,width,dropDownWidth,lines,defText,tooltip)
-- ExRT.lib.CreateListFrame(name,parent,width,buttonsNum,buttonPos,relativePoint,x,y,buttonText,listClickFunc)
-- ExRT.lib.SetPoint(self,...)

local GlobalAddonName, ExRT = ...

ExRT.lib = {}

function ExRT.lib.AddShadowComment(self,hide,moduleName,userComment,userFontSize,userOutline)
	if self.moduleNameString then
		if hide then
			self.moduleNameString:Hide()
		else
			local selfWidth = self:GetWidth()
			local selfHeight = self:GetHeight()
			self.moduleNameString:SetSize(selfWidth,selfHeight)
			self.moduleNameString:Show()
		end
	elseif not hide and moduleName then
		local selfWidth = self:GetWidth()
		local selfHeight = self:GetHeight()
		self.moduleNameString = ExRT.lib.CreateText(self,selfWidth,selfHeight,"BOTTOMRIGHT", -5, 4,"RIGHT","BOTTOM",ExRT.mds.defFont, 18,moduleName or "",nil)
		self.moduleNameString:SetTextColor(1, 1, 1, 0.8)
	end

	if self.userCommentString then
		if hide then
			self.userCommentString:Hide()
		else
			local selfWidth = self:GetWidth()
			local selfHeight = self:GetHeight()
			self.userCommentString:SetSize(selfWidth,selfHeight)
			self.userCommentString:Show()
		end
	elseif not hide and userComment then
		local selfWidth = self:GetWidth()
		local selfHeight = self:GetHeight()
		self.userCommentString = ExRT.lib.CreateText(self,selfWidth,selfHeight,"BOTTOMRIGHT", -5, 20,"RIGHT","BOTTOM",ExRT.mds.defFont, userFontSize or 18,userComment or "",nil,0,0,0,nil,userOutline)
		self.userCommentString:SetTextColor(0, 0, 0, 0.7)
	end
end

do
	local function SliderOnMouseWheel(self,delta)
		if tonumber(self:GetValue()) == nil then 
			return 
		end
		self:SetValue(tonumber(self:GetValue())+delta)
	end
	local function SliderTooltipShow(self)
		local text = self.text:GetText()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltipText or "")
		GameTooltip:AddLine(text or "",1,1,1)
		GameTooltip:Show()
	end
	local function SliderTooltipReload(self)
		if GameTooltip:IsVisible() then
			self:tooltipHide()
			self:tooltipShow()
		end
	end
	function ExRT.lib.CreateSlider(name,parent,width,height,x,y,minVal,maxVal,text,defVal,relativePoint,isVertical)
		defVal = defVal or maxVal
	
		local self = CreateFrame("Slider",name,parent,"OptionsSliderTemplate")
		self:SetWidth(width)
		self:SetHeight(height)
		self:SetPoint(relativePoint or "TOPLEFT",parent, x, y)
		self.textLow = _G[name.."Low"]
		self.textHigh = _G[name.."High"]
		self.text = _G[name.."Text"]
		if isVertical then
			self.textLow:Hide()
			self.textHigh:Hide()
			self.text:Hide()
		end
		self:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
		self:SetMinMaxValues(minVal, maxVal)
		self.minValue, self.maxValue = self:GetMinMaxValues() 
		self.textLow:SetText(self.minValue)
		self.textHigh:SetText(self.maxValue)
		self.text:SetText(text)
		self.tooltipText = defVal
		self:SetValueStep(1)
		self:SetValue(defVal)
	
		self:SetScript("OnMouseWheel", SliderOnMouseWheel)

		self.tooltipShow = SliderTooltipShow
		self.tooltipHide = GameTooltip_Hide
		self.tooltipReload = SliderTooltipReload
		self:SetScript("OnEnter", self.tooltipShow)
		self:SetScript("OnLeave", self.tooltipHide)
	
		return self
	end
end

function ExRT.lib.CreateScrollBar(name,parent,width,height,x,y,minVal,maxVal,relativePoint,isHoriz)
	local self = CreateFrame("Slider", name, parent)
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAllPoints(true)
	self.bg:SetTexture(0, 0, 0, 0.5)
	self.thumb = self:CreateTexture(nil, "OVERLAY")
	self.thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	self.thumb:SetSize(25, 25)
	self:SetThumbTexture(self.thumb)
	self:SetOrientation(isHoriz and "HORIZONTAL" or "VERTICAL")
	self:SetSize(width, height)
	self:SetPoint(relativePoint or "TOPLEFT", parent, x, y)
	self:SetMinMaxValues(minVal, maxVal)
	self:SetValue(minVal)

	return self
end

do
	local function ScrollBarButtonUpClick(self)
		local scrollBar = self:GetParent()
		local min,max = scrollBar:GetMinMaxValues()
		local val = scrollBar:GetValue()
		if (val - 1) < min then
			scrollBar:SetValue(min)
		else
			scrollBar:SetValue(val - 1)
		end
	end
	local function ScrollBarButtonDownClick(self)
		local scrollBar = self:GetParent()
		local min,max = scrollBar:GetMinMaxValues()
		local val = scrollBar:GetValue()
		if (val + 1) > max then
			scrollBar:SetValue(max)
		else
			scrollBar:SetValue(val + 1)
		end
	end
	local function ScrollBarButtonsState(self,UP,DOWN)
		self.buttonUP:SetEnabled(UP)
		self.buttonDown:SetEnabled(DOWN)
	end
	local function ScrollBarButtonsReState(self)
		local value = ExRT.mds.Round(self:GetValue())
		local min,max = self:GetMinMaxValues()
		if max == min then
			self:buttonsState(nil,nil)
		elseif value == min then
			self:buttonsState(nil,true)
		elseif value == max then
			self:buttonsState(true,nil)
		else
			self:buttonsState(true,true)
		end
	end
	function ExRT.lib.CreateScrollBar2(name,parent,width,height,x,y,minVal,maxVal,relativePoint)
		local self = CreateFrame("Slider", name, parent)
		self.bg = self:CreateTexture(nil, "BACKGROUND")
		self.bg:SetAllPoints(true)
		self.bg:SetTexture(0, 0, 0, 0.5)
		self.thumb = self:CreateTexture(nil, "OVERLAY")
		self.thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
		self.thumb:SetSize(25, 25)
		self:SetThumbTexture(self.thumb)
		self:SetOrientation(isHoriz and "HORIZONTAL" or "VERTICAL")
		self:SetSize(width, height - 32)
		self:SetPoint(relativePoint or "TOPLEFT", parent, x, y - 16)
		self:SetMinMaxValues(minVal, maxVal)
		self:SetValue(minVal)
		
		self.buttonUP = CreateFrame("Button",nil,self,"UIPanelScrollUPButtonTemplate")
		self.buttonUP:SetSize(16,16)
		self.buttonUP:SetPoint("BOTTOM",self,"TOP",0,0) 
		self.buttonUP:SetScript("OnClick",ScrollBarButtonUpClick)
	
		self.buttonDown = CreateFrame("Button",nil,self,"UIPanelScrollDownButtonTemplate")
		self.buttonDown:SetPoint("TOP",self,"BOTTOM",0,0) 
		self.buttonDown:SetSize(16,16)
		self.buttonDown:SetScript("OnClick",ScrollBarButtonDownClick)
		
		self.buttonsState = ScrollBarButtonsState
		self.reButtonsState = ScrollBarButtonsReState
		
		return self
	end
end

function ExRT.lib.OnEnterTooltip(self,anchorUser)
	GameTooltip:SetOwner(self,anchorUser or "ANCHOR_RIGHT")
	GameTooltip:SetText(self.tooltipText or "", nil, nil, nil, nil, true)
	GameTooltip:Show()
end

function ExRT.lib.OnLeaveTooltip(self)
	GameTooltip_Hide()
end

function ExRT.lib.TooltipShow(self,anchorUser,title,...)
	if title then
		local x,y=0,0
		if type(anchorUser) == "table" then
			x = anchorUser[2]
			y = anchorUser[3]
			anchorUser = anchorUser[1] or "ANCHOR_RIGHT"
		elseif not anchorUser then
			anchorUser = "ANCHOR_RIGHT"
		end
		GameTooltip:SetOwner(self,anchorUser or "ANCHOR_RIGHT",x,y)
		GameTooltip:SetText(title)
		for i=1,select("#", ...) do
			local line = select(i, ...)
			if type(line) == "table" then
				if not line.right then
					GameTooltip:AddLine(unpack(line))
				else
					GameTooltip:AddDoubleLine(line[1], line.right, line[2],line[3],line[4], line[2],line[3],line[4])
				end
			else
				GameTooltip:AddLine(line)
			end
		end
		GameTooltip:Show()
	end
end

function ExRT.lib.TooltipHide()
	GameTooltip_Hide()
end

function ExRT.lib.OnEnterHyperLinkTooltip(self,data)
	if not data then 
		return 
	end
	local x = self:GetRight()
	if x >= ( GetScreenWidth() / 2 ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:SetHyperlink(data)
	GameTooltip:Show()
end

function ExRT.lib.OnLeaveHyperLinkTooltip(self)
	GameTooltip_Hide()
end

function ExRT.lib.EditBoxOnEnterHyperLinkTooltip(self,linkData,link)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:SetHyperlink(linkData)
	GameTooltip:Show()
end

function ExRT.lib.EditBoxOnLeaveHyperLinkTooltip(self)
	GameTooltip_Hide()
end

do
	local additionalTooltips = {}
	local function CreateAdditionalTooltip()
		local new = #additionalTooltips + 1
		additionalTooltips[new] = CreateFrame("GameTooltip", "ExRTlibAdditionalTooltip"..new, nil, "GameTooltipTemplate")
		additionalTooltips[new]:Hide()
		
		return new
	end
	function ExRT.lib.AdditionalTooltip(link,data)
		local tooltipID = nil
		for i=1,#additionalTooltips do
			if not additionalTooltips[i]:IsShown() then
				tooltipID = i
				break
			end
		end
		if not tooltipID then
			tooltipID = CreateAdditionalTooltip()
		end
		local tooltip = additionalTooltips[tooltipID]
		local owner = nil
		if tooltipID == 1 then
			owner = GameTooltip
		else
			owner = additionalTooltips[tooltipID - 1]
		end
		tooltip:SetOwner(owner, "ANCHOR_NONE")
		if link then
			tooltip:SetHyperlink(link)
		else
			for i=1,#data do
				tooltip:AddLine(data[i])
			end
		end
		tooltip:ClearAllPoints()
		tooltip:SetPoint("TOPRIGHT",owner,"BOTTOMRIGHT",0,0)
		tooltip:Show()
	end
	function ExRT.lib.HideAdditionalTooltips()
		for i=1,#additionalTooltips do
			additionalTooltips[i]:Hide()
			additionalTooltips[i]:ClearLines()
		end
	end
end

function ExRT.lib.ShowOrHide(self,bool)
	if not self then return end
	if bool then
		self:Show()
	else
		self:Hide()
	end
end

function ExRT.lib.SetAlphas(alpha,...)
	for i=1,select("#", ...) do
		local self = select(i, ...)
		self:SetAlpha(alpha)
	end
end

do
	local function TabFrameUpdateTabs(self)
		for i=1,self.tabCount do
			if i == self.selected then
				PanelTemplates_SelectTab(self.tabs[i].button)
				self.tabs[i]:Show()
			else
				PanelTemplates_DeselectTab(self.tabs[i].button)
				self.tabs[i]:Hide()
			end
			
			if self.tabs[i].disabled then
				PanelTemplates_SetDisabledTabState(self.tabs[i].button)
			end
		end
		if self.navigation then
			if self.disabled then
				self.navigation:SetEnabled(nil)
			else
				self.navigation:SetEnabled(true)
			end
		end
	end
	local function TabFrameButtonClick(self)
		local tabFrame = self.mainFrame
		tabFrame.selected = self.id
		tabFrame.UpdateTabs(tabFrame)
	end
	local function TabFrameButtonOnEnter(self)
		if self.tooltip and self.tooltip ~= "" then
			ExRT.lib.TooltipShow(self,nil,self:GetText(),{self.tooltip,1,1,1})
		end
	end
	local function TabFrameButtonOnLeave(self)
		GameTooltip_Hide()
	end
	local function TabFrameToggleNavigation(self)
		local parent = self.parent
		local dropDownList = {}
		for i=self.max + 1,#parent.tabs do
			dropDownList[#dropDownList+1] = {
				text = parent.tabs[i].button:GetText(),
				notCheckable = true,
				func = function ()
					TabFrameButtonClick(parent.tabs[i].button)
				end
			}
		end
		dropDownList[#dropDownList + 1] = {
			text = ExRT.L.BossWatcherSelectFightClose,
			notCheckable = true,
			func = function() 
				CloseDropDownMenus() 
			end,
		}
		EasyMenu(dropDownList, self.dropDown, "cursor", 10 , -15, "MENU")
	end	
	local function TabFrameCreateNavigation(self,maxButtons)
		if self.navigation then
			return
		end
		self.navigation = CreateFrame("Button", self:GetName().."Navigation", self, "ExRTUIChatDownButtonTemplate")
		self.navigation:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -15, -3)
		self.navigation:SetScript("OnClick",TabFrameToggleNavigation)
		self.navigation:SetScript("OnEnter",function (self)
			ExRT.lib.TooltipShow(self,nil,ExRT.L.SetAdditionalTabs)
		end)
		self.navigation:SetScript("OnLeave",GameTooltip_Hide)
		self.navigation.parent = self
		self.navigation.max = maxButtons
		self.navigation.dropDown = CreateFrame("Frame", self:GetName().."NavigationDropDown", nil, "UIDropDownMenuTemplate")
	end
	function ExRT.lib.CreateTabFrame(name,parent,width,height,x,y,tabNum,activeTabNum,...)
		local self = CreateFrame("Frame",name,parent)
		self:SetSize(width,height)
		self:SetBackdrop({bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		self:SetBackdropColor(0,0,0,0.5)
		self:SetPoint("TOPLEFT",x,y)
	
		self.tabs = {}
		for i=1,tabNum do
			self.tabs[i] = CreateFrame("Frame",nil,self)
			self.tabs[i]:SetSize(width,height)
			self.tabs[i]:SetPoint("TOPLEFT", 0,0)
	
			self.tabs[i].button = CreateFrame("Button", format("%sTab%d",name,i), self, "OptionsFrameTabButtonTemplate")
			self.tabs[i].button:SetText(select(i, ...))
			PanelTemplates_TabResize(self.tabs[i].button, 0, nil, nil, self.tabs[i].button:GetFontString():GetStringWidth(), self.tabs[i].button:GetFontString():GetStringWidth())
			self.tabs[i].button.id = i
			self.tabs[i].button.mainFrame = self
			self.tabs[i].button:SetScript("OnClick", TabFrameButtonClick)
			
			self.tabs[i].button:SetScript("OnEnter", TabFrameButtonOnEnter)
			self.tabs[i].button:SetScript("OnLeave", TabFrameButtonOnLeave)
	
			if i == 1 then
				self.tabs[i].button:SetPoint("TOPLEFT", 10, 24)
			else
				self.tabs[i].button:SetPoint("LEFT", self.tabs[i-1].button, "RIGHT", -16, 0)
				self.tabs[i]:Hide()
			end
			PanelTemplates_DeselectTab(self.tabs[i].button)
			
			if self:GetLeft()+self:GetWidth()-(i==tabNum and 0 or 24) < self.tabs[i].button:GetRight() then
				self.tabs[i].button:Hide()
				TabFrameCreateNavigation(self,i-1)
			end
		end
		PanelTemplates_SelectTab(self.tabs[activeTabNum or 1].button)
	
		self.tabCount = tabNum
		self.selected = activeTabNum or 1
		self.UpdateTabs = TabFrameUpdateTabs
	
		return self
	end
end

function ExRT.lib.CreateText(parent,width,height,relativePoint,x,y,hor,ver,font,fontSize,text,tem,colR,colG,colB,shadow,outline,doNotUseTemplate)
	if not tem and not font and not doNotUseTemplate then 
		tem = "ExRTFontNormal" 
	end
	if outline then 
		outline = "OUTLINE" 
	end
	local self = parent:CreateFontString(nil,"ARTWORK",tem)
	if not doNotUseTemplate then
		if not tem then
			self:SetFont(font, fontSize, outline)
		elseif fontSize then
			local filename = self:GetFont()
			self:SetFont(filename,fontSize, outline)
		end
	end
	self:SetSize(width,height)
	self:SetPoint(relativePoint or "TOPLEFT", x,y)
	self:SetJustifyH(hor or "LEFT")
	self:SetJustifyV(ver or "MIDDLE")
	if colR and colG and colB then
		self:SetTextColor(colR,colG,colB,1)
	end
	if shadow then
		self:SetShadowOffset(1,-1)
	end
	if text and not doNotUseTemplate then
		self:SetText(text)
	end
	return self
end

do
	local function EditBoxEscapePressed(self)
		self:ClearFocus()
	end
	function ExRT.lib.CreateEditBox(name,parent,width,height,relativePoint,x,y,tooltip,maxLetters,onlyNum,template,defText)
		local self = CreateFrame("EditBox",name,parent,template)
		self:SetSize(width,height)
		self:SetPoint(relativePoint or "TOPLEFT",x,y)
		if not template then
			local GameFontNormal_Font = GameFontNormal:GetFont()
			self:SetFont(GameFontNormal_Font,12)
			self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8",edgeFile = ExRT.mds.defBorder,edgeSize = 8,tileSize = 0,insets = {left = 2.5,right = 2.5,top = 2.5,bottom = 2.5}})
			self:SetBackdropColor(0, 0, 0, 0.8) 
			self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
			self:SetTextInsets(10,10,0,0)
		end
		if defText then
			self:SetText(defText)
			self:SetCursorPosition(0)
		end
		self:SetAutoFocus( false )
		if tooltip then
			self:SetScript("OnEnter",ExRT.lib.OnEnterTooltip)
			self:SetScript("OnLeave",ExRT.lib.OnLeaveTooltip)
			self.tooltipText = tooltip
		end
		if maxLetters then
			self:SetMaxLetters(maxLetters)
		end
		if onlyNum then
			self:SetNumeric(true)
		end
		self:SetScript("OnEscapePressed",EditBoxEscapePressed)
		return self
	end
end

do
	local function ScrollFrameMouseWheel(self,delta)
		delta = delta * 20
		local min,max = self.ScrollBar:GetMinMaxValues()
		local val = self.ScrollBar:GetValue()
		if (val - delta) < min then
			self.ScrollBar:SetValue(min)
		elseif (val - delta) > max then
			self.ScrollBar:SetValue(max)
		else
			self.ScrollBar:SetValue(val - delta)
		end
	end
	local function ScrollFrameScrollBarValueChanged(self,value)
		local parent = self:GetParent()
		parent:SetVerticalScroll(value) 
		self:reButtonsState()
	end
	local function ScrollFrameChangeHeight(self,newHeight)
		self.content:SetHeight(newHeight)
		self.ScrollBar:SetMinMaxValues(0,max(newHeight-self:GetHeight(),0))
		self.ScrollBar.reButtonsState(self.ScrollBar)
	end
	function ExRT.lib.CreateScrollFrame(name,parent,width,height,relativePoint,x,y,verticalHeight)
		local self = CreateFrame("ScrollFrame", name, parent)
		self:SetSize(width,height)
		self:SetPoint(relativePoint or "TOPLEFT",x,y)
		
		self.backdrop = CreateFrame("Frame", nil, self)
		self.backdrop:SetPoint("TOPLEFT",self,-5,5)
		self.backdrop:SetSize(width+10,height+10)
		self.backdrop:SetBackdrop({bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		self.backdrop:SetBackdropColor(0,0,0,0)
		
		self.content = CreateFrame("Frame", nil, self) 
		self.content:SetSize(width-16, verticalHeight) 
		self:SetScrollChild(self.content)
		
		self.C = self.content
		
		self.ScrollBar = ExRT.lib.CreateScrollBar2(name.."ScrollBar",self,16,height,0,0,0,max(verticalHeight-height,0),"TOPRIGHT")
		self.ScrollBar:SetScript("OnValueChanged", ScrollFrameScrollBarValueChanged)
		self.ScrollBar.reButtonsState(self.ScrollBar)
		
		self:SetScript("OnMouseWheel", ScrollFrameMouseWheel)
		
		self.SetNewHeight = ScrollFrameChangeHeight
		
		return self
	end
end

do
	local function MultiEditBoxGetTextHighlight(self)
		local text,cursor = self:GetText(),self:GetCursorPosition()
		self:Insert("")
		local textNew, cursorNew = self:GetText(), self:GetCursorPosition()
		self:SetText( text )
		self:SetCursorPosition( cursor )
		local Start, End = cursorNew, #text - ( #textNew - cursorNew )
		self:HighlightText( Start, End )
		return Start, End
	end
	function ExRT.lib.CreateMultiEditBox(name,parent,width,height,relativePoint,x,y)
		local self=CreateFrame("ScrollFrame", name, parent, "InputScrollFrameTemplate")
		self:SetSize(width,height)
		self:SetPoint(relativePoint or "TOPLEFT",x,y)
		self.EditBox:SetFontObject("ChatFontNormal")
		self.EditBox:SetMaxLetters(0)
		self.CharCount:Hide()
		self.EditBox:SetWidth(width - 30)
		
		local parentStrata = parent:GetFrameStrata()
		local parentLevel = parent:GetFrameLevel()
		self:SetFrameStrata(parentStrata)
		self:SetToplevel(true)
		self.FocusButton:SetFrameLevel(parentLevel + 101)
		self.EditBox:SetFrameLevel(parentLevel + 102)
		self.ScrollBar:SetFrameLevel(parentLevel + 103)
		
		self.EditBox.GetTextHighlight = MultiEditBoxGetTextHighlight
		
		return self
	end
end

do
	local function MultiEditBoxMouseWheel(self,delta)
		local v = self.ScrollBar:GetValue() - delta
		local v_min,v_max = self.ScrollBar:GetMinMaxValues()
		if v < v_min then 
			v = v_min 
		elseif v > v_max then
			v = v_max
		end
		self.ScrollBar:SetValue(v)
	end
	local function MultiEditBoxClearEditBox(self)
		self:SetText("")
	end
	function ExRT.lib.CreateMultiEditBox2(name,parent,width,height,relativePoint,x,y)
		local self=ExRT.lib.CreateMultiEditBox(name,parent,width,height,relativePoint,x,y)
		self.EditBox:SetScript("OnHide",MultiEditBoxClearEditBox)
		
		self:SetScript("OnVerticalScroll",nil)
		self:SetScript("OnScrollRangeChanged",nil)
		self:SetScript("OnMouseWheel",MultiEditBoxMouseWheel)
		self.EditBox:SetScript("OnUpdate",nil)
		self.EditBox:SetScript("OnTextChanged",nil)
		self.ScrollBar:Show()
		self.ScrollBar:SetMinMaxValues(0,0.01)
		self.ScrollBar:SetValue(0.01)
		
		return self
	end
end

function ExRT.lib.CreateEditSliderBox(parent,width,height,x,y,txt)
	if width <= height*2 then return end
	local self = CreateFrame("Frame",nil,parent)
	self:SetSize(width-height*2,height)
	self:SetPoint("TOPLEFT",x+height,y)
	self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8",edgeFile = ExRT.mds.defBorder,edgeSize = 8,tileSize = 0,insets = {left = 2.5,right = 2.5,top = 2.5,bottom = 2.5}})
	self:SetBackdropColor(0, 0, 0, 0.8) 
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	self:SetScript("OnEnter",ExRT.lib.OnEnterTooltip)
	self:SetScript("OnLeave",ExRT.lib.OnLeaveTooltip)

	self.selected = 1

	self.t = self:CreateFontString(nil,"ARTWORK")
	local GameFontNormal_Font = GameFontNormal:GetFont()
	self.t:SetFont(GameFontNormal_Font,12)
	self.t:SetAllPoints()
	self.t:SetJustifyH("CENTER")
	self.t:SetJustifyV("MIDDLE")
	self.t:SetText(txt or "")

	self.l = {}
	for i=1,2 do
		self.l[i] = CreateFrame("Button",nil,self)
		self.l[i]:SetSize(height,height)
		self.l[i]:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8",edgeFile = ExRT.mds.defBorder,edgeSize = 8,tileSize = 0,insets = {left = 2.5,right = 2.5,top = 2.5,bottom = 2.5}})
		self.l[i]:SetBackdropColor(0, 0, 0, 0.8) 
		self.l[i]:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

		self.l[i].t = self.l[i]:CreateFontString(nil,"ARTWORK")
		self.l[i].t:SetFont(GameFontNormal_Font,12)
		self.l[i].t:SetAllPoints()
		self.l[i].t:SetJustifyH("CENTER")
		self.l[i].t:SetJustifyV("MIDDLE")
	end
	self.l[1]:SetPoint("LEFT",-height,0)
	self.l[1].t:SetText("<")
	self.l[1].diff = -1
	self.l[1].parent = self

	self.l[2]:SetPoint("RIGHT",height,0)
	self.l[2].t:SetText(">")
	self.l[2].diff = 1
	self.l[2].parent = self

	return self
end

do
	local function ButtonOnEnter(self)
		ExRT.lib.TooltipShow(self,"ANCHOR_TOP",self.tooltip,{self.tooltipText,1,1,1,true}) 
	end
	function ExRT.lib.CreateButton(name,parent,width,height,relativePoint,x,y,text,isDisabled,tooltip)
		local self = CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
		self:SetSize(width,height)
		if x and y then
			self:SetPoint(relativePoint or "TOPLEFT",x,y) 
		end
		self:SetText(text) 
		if isDisabled then
			self:Disable()
		end
		if tooltip then
			self.tooltip = text
			if text == "" then
				self.tooltip = " "
			end
			self.tooltipText = tooltip
			self:SetScript("OnEnter",ButtonOnEnter)
			self:SetScript("OnLeave",ExRT.lib.TooltipHide)
		end
		return self
	end
end

function ExRT.lib.CreateIcon(name,parent,size,relativePoint,x,y,textureIcon,isButton)
	local self = CreateFrame(isButton and "Button" or "FRAME",name,parent)
	self:SetSize(size,size)
	self:SetPoint(relativePoint or "TOPLEFT", x,y)
	self.texture = self:CreateTexture(nil, "BACKGROUND")
	self.texture:SetTexture(textureIcon or "Interface\\Icons\\INV_MISC_QUESTIONMARK")
	self.texture:SetAllPoints()
	if isButton then
 		self:EnableMouse(true)
		self:RegisterForClicks("LeftButtonDown")
	end
	return self
end

do
	local function CheckBoxOnEnter(self)
		ExRT.lib.TooltipShow(self,"ANCHOR_TOP",self.tooltip,{self.tooltipText,1,1,1,true}) 
	end
	local function CheckBoxClick(self)
		if self:GetChecked() then
			self:On()
		else
			self:Off()
		end
	end
	function ExRT.lib.CreateCheckBox(name,parent,relativePoint,x,y,text,checked,tooltip,textLeft)
		local self = CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")  
		if x and y then
			self:SetPoint(relativePoint or "TOPLEFT",x,y)
		end
		self.text:SetText(text)
		self:SetChecked(checked)
		self.tooltip = text
		if tooltip then
			if text == "" then
				self.tooltip = tooltip
			else
				self.tooltipText = tooltip
			end
		end
		self:SetScript("OnEnter",CheckBoxOnEnter)
		self:SetScript("OnLeave",ExRT.lib.TooltipHide)
		self:SetScript("OnClick", CheckBoxClick)
		if textLeft then
			self.text:ClearAllPoints()
			self.text:SetPoint("RIGHT",self,"LEFT",-2,0)
		end
		
		return self
	end
end

function ExRT.lib.CreateHoverHighlight(parent)
	parent.hl = parent:CreateTexture(nil, "BACKGROUND")
	parent.hl:SetPoint("TOPLEFT", 0, 0)
	parent.hl:SetPoint("BOTTOMRIGHT", 0, 0)
	parent.hl:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	parent.hl:SetBlendMode("ADD")
	parent.hl:Hide()
end

function ExRT.lib.CreateBackTextureForDebug(parent)
	local self = parent:CreateTexture(nil, "BACKGROUND")
	self:SetTexture(1, 0, 0, 0.3)
	self:SetAllPoints()
end

function ExRT.lib.CreateHelpButton(parent,helpPlateArray,isTab)
	local self = CreateFrame("Button",nil,parent,"MainHelpPlateButton")	-- После использования кнопки не дает юзать спелл дизенчант. лень искать решение, не юзайте кнопку часто
	self:SetPoint("CENTER",parent,"TOPLEFT",0,0) 
	self:SetScale(0.8)
	self:SetScript("OnClick",function()
		local helpPlate
		if isTab then
			helpPlate = helpPlateArray[isTab.selected]
		else
			helpPlate = helpPlateArray
		end
		if helpPlate and not HelpPlate_IsShowing(helpPlate) then
			HelpPlate_Show(helpPlate, parent, self, true)
			self:SetFrameStrata( HelpPlate:GetFrameStrata() )
			self:SetFrameLevel( HelpPlate:GetFrameLevel() + 1 )
		else
			HelpPlate_Hide(true)
			self:SetFrameStrata(self.strata)
			self:SetFrameLevel(self.level)
		end
		if self.Click2 then
			self:Click2()
		end
	end)
	self:SetScript("OnHide",function()
		HelpPlate_Hide()
		self:SetFrameStrata(self.strata)
		self:SetFrameLevel(self.level)
	end)
	self.strata = self:GetFrameStrata()
	self.level = self:GetFrameLevel()
	
	return self
end

do
	local ScrollListFrameUpdate = nil
	local function ScrollListUpdate()
		local self = ScrollListFrameUpdate
		local val = ExRT.mds.Round(self.ScrollBar:GetValue())
		local j = 0
		for i=val,#self.L do
			j = j + 1
			self.List[j]:SetText(self.L[i])
			if not self.dontDisable then
				if i ~= self.selected then
					self.List[j]:SetEnabled(true)
				else
					self.List[j]:SetEnabled(nil)
				end
			end
			self.List[j]:Show()
			self.List[j].index = i
			if j >= self.linesNum then
				break
			end
		end
		for i=(j+1),self.linesNum do
			self.List[i]:Hide()
		end
		self.ScrollBar:SetMinMaxValues(1,max(#self.L-self.linesNum+1,1))
		self.ScrollBar:reButtonsState()
		
		if self.UpdateAdditional then
			self.UpdateAdditional(self,val)
		end
	end
	local function ScrollListMouseWheel(self,delta)
		if delta > 0 then
			self.ScrollBar.buttonUP:Click("LeftButton")
		else
			self.ScrollBar.buttonDown:Click("LeftButton")
		end
	end
	local function ScrollListListClick(self)
		local parent = self.mainFrame
		if not parent.dontDisable then
			for j=1,parent.linesNum do
				if j ~= self.id then
					parent.List[j]:SetEnabled(true)
				else
					parent.List[j]:SetEnabled(nil)
				end
			end
		end
		parent.selected = self.index
		parent:SetListValue(self.index)
	end
	local function ScrollListListEnter(self)
		if self.mainFrame.HoverListValue then
			self.mainFrame:HoverListValue(true,self.index)
		end
	end
	local function ScrollListListLeave(self)
		if self.mainFrame.HoverListValue then
			self.mainFrame:HoverListValue(false,self.index)
		end
	end
	function ExRT.lib.CreateScrollList(name,parent,relativePoint,x,y,width,linesNum)
		local self = CreateFrame("Frame",name,parent)
		local height = linesNum * 16 + 8
		self:SetSize(width,height)
		self:SetPoint(relativePoint or "TOPLEFT",x,y)
		self:SetBackdrop({bgFile = "", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		
		self.ScrollBar = ExRT.lib.CreateScrollBar2(name.."ScrollBar",self,16,height-8,-3,-4,1,10,"TOPRIGHT")
		self.linesNum = linesNum
		
		self.List = {}
		for i=1,linesNum do
			self.List[i] = CreateFrame("Button",name.."List"..tostring(i),self)
			self.List[i]:SetSize(width - 22,16)
			self.List[i]:SetPoint("TOPLEFT",3,-(i-1)*16-4)
			
			self.List[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight","ADD")
			
			self.List[i].text = ExRT.lib.CreateText(self.List[i],width - 30,16,nil,4,0,"LEFT","MIDDLE",nil,12,"List"..tostring(i),nil,1,1,1,1)
			
			self.List[i].PushedTexture = self.List[i]:CreateTexture()
			self.List[i].PushedTexture:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
			self.List[i].PushedTexture:SetBlendMode("ADD")
			self.List[i].PushedTexture:SetAllPoints()
			self.List[i].PushedTexture:SetVertexColor(1,1,0,1)
			
			self.List[i]:SetDisabledTexture(self.List[i].PushedTexture)
			
			self.List[i]:SetFontString(self.List[i].text)
			self.List[i]:SetPushedTextOffset(2, -1)
			
			self.List[i].mainFrame = self
			self.List[i].id = i
			self.List[i]:SetScript("OnClick",ScrollListListClick)
			
			self.List[i]:SetScript("OnEnter",ScrollListListEnter)
			self.List[i]:SetScript("OnLeave",ScrollListListLeave)		
		end
		
		self.L = {}
		function self.Update()
			ScrollListFrameUpdate = self
			ScrollListUpdate()
		end
		
		self:SetScript("OnMouseWheel",ScrollListMouseWheel)
		
		self:SetScript("OnShow",self.Update)
		self.ScrollBar:SetScript("OnValueChanged",self.Update)
		
		return self
	end
end

do
	local ScrollCheckFrameUpdate = nil
	local function ScrollCheckListUpdate()
		local self = ScrollCheckFrameUpdate
		local val = ExRT.mds.Round(self.ScrollBar:GetValue())
		local j = 0
		for i=val,#self.L do
			j = j + 1
			self.List[j]:SetText(self.L[i])
			self.List[j].chk:SetChecked(self.C[i])
			self.List[j]:Show()
			self.List[j].index = i
			if j >= self.linesNum then
				break
			end
		end
		for i=(j+1),self.linesNum do
			self.List[i]:Hide()
		end
		self.ScrollBar:SetMinMaxValues(1,max(#self.L-self.linesNum+1,1))
		self.ScrollBar:reButtonsState()
	end
	local function ScrollCheckListMouseWheel(self, delta)
		if delta > 0 then
			self.ScrollBar.buttonUP:Click("LeftButton")
		else
			self.ScrollBar.buttonDown:Click("LeftButton")
		end
	end
	local function ScrollCheckListListCheckClick(self)
		local listParent = self:GetParent()
		local parent = listParent.mainFrame
		if self:GetChecked() then
			parent.C[listParent.index] = true
		else
			parent.C[listParent.index] = nil
		end
		parent.ValueChanged(parent)
	end
	local function ScrollCheckListListClick(self)
		local parent = self.mainFrame
		parent.C[self.index] = not parent.C[self.index]
		parent.List[self.id].chk:SetChecked(parent.C[self.index])
		
		parent.ValueChanged(parent)
	end	
	local function ScrollCheckListListEnter(self)
		if self.mainFrame.HoverListValue then
			self.mainFrame:HoverListValue(true,self.index)
		end
	end
	local function ScrollCheckListListLeave(self)
		if self.mainFrame.HoverListValue then
			self.mainFrame:HoverListValue(false,self.index)
		end
	end
	function ExRT.lib.CreateScrollCheckList(name,parent,relativePoint,x,y,width,linesNum)
		local self = CreateFrame("Frame",name,parent)
		local height = linesNum * 16 + 8
		self:SetSize(width,height)
		self:SetPoint(relativePoint or "TOPLEFT",x,y)
		self:SetBackdrop({bgFile = "", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		
		self.ScrollBar = ExRT.lib.CreateScrollBar2(name.."ScrollBar",self,16,height-8,-3,-4,1,10,"TOPRIGHT")
		
		self.linesNum = linesNum
		
		self.List = {}
		for i=1,linesNum do
			self.List[i] = CreateFrame("Button",name.."List"..tostring(i),self)
			self.List[i]:SetSize(width - 22,16)
			self.List[i]:SetPoint("TOPLEFT",3,-(i-1)*16-4)
			
			self.List[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight","ADD")
			
			self.List[i].text = ExRT.lib.CreateText(self.List[i],width - 50,16,nil,24,0,"LEFT","MIDDLE",nil,12,"List"..tostring(i),nil,1,1,1,1)
			
			self.List[i].mainFrame = self
			self.List[i].id = i
			
			self.List[i].chk = CreateFrame("CheckButton",nil,self.List[i],"UICheckButtonTemplate")  
			self.List[i].chk:SetScale(0.75)
			self.List[i].chk:SetPoint("TOPLEFT",0,5)
			self.List[i].chk:SetScript("OnClick", ScrollCheckListListCheckClick)
			
			self.List[i].PushedTexture = self.List[i]:CreateTexture()
			self.List[i].PushedTexture:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
			self.List[i].PushedTexture:SetBlendMode("ADD")
			self.List[i].PushedTexture:SetAllPoints()
			self.List[i].PushedTexture:SetVertexColor(1,1,0,1)
			
			self.List[i]:SetDisabledTexture(self.List[i].PushedTexture)
			
			self.List[i]:SetFontString(self.List[i].text)
			self.List[i]:SetPushedTextOffset(2, -1)
			
 			self.List[i]:SetScript("OnClick", ScrollCheckListListClick)
			
			self.List[i]:SetScript("OnEnter", ScrollCheckListListEnter)
			self.List[i]:SetScript("OnLeave", ScrollCheckListListLeave)		
		end
		
		self.L = {}
		self.C = {}
		function self.Update()
			ScrollCheckFrameUpdate = self
			ScrollCheckListUpdate()
		end
		
		self:SetScript("OnMouseWheel", ScrollCheckListMouseWheel)
		
		self:SetScript("OnShow",self.Update)
		self.ScrollBar:SetScript("OnValueChanged",self.Update)
		
		return self
	end
end

do
	local function PopupFrameShow(self,anchor,notResetPosIfShown)
		if self:IsShown() and notResetPosIfShown then
			return
		end
		local x, y = GetCursorPosition()
		local Es = self:GetEffectiveScale()
		x, y = x/Es, y/Es
		self:ClearAllPoints()
		self:SetPoint(anchor or "BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y)
		self:Show()
	end
	function ExRT.lib.CreatePopupFrame(name,width,height,title)
		local self = CreateFrame("Frame",name,UIParent,"UIPanelDialogTemplate")
		self:SetSize(width,height)
		self:SetPoint("CENTER")
		self:SetFrameStrata("DIALOG")
		self:SetClampedToScreen(true)
		self:EnableMouse(true)
		self:SetMovable(true)
		self:RegisterForDrag("LeftButton")
		self:SetDontSavePosition(true)
		self:SetScript("OnDragStart", function(self) 
			self:StartMoving() 
		end)
		self:SetScript("OnDragStop", function(self) 
			self:StopMovingOrSizing() 
		end)
		self:Hide()
		
		self.ShowClick = PopupFrameShow
		
		if title then
			self.title = ExRT.lib.CreateText(self,width,14,"TOPLEFT",20,-8,"LEFT","TOP",nil,14,title,nil,1,1,1,1)
		end
		
		return self
	end
end

function ExRT.lib.CreateOneTab(parent,width,height,relativePoint,x,y,name)
	local self = CreateFrame("Frame",nil,parent)
	self:SetSize(width,height)
	self:SetBackdrop({bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
	self:SetBackdropColor(0,0,0,0.5)
	self:SetPoint(relativePoint or "TOPLEFT",x,y)
	if name then
		self.name = ExRT.lib.CreateText(self,width-20,20,"TOP",0,17,nil,nil,nil,nil,name,"GameFontNormal")
	end
	return self
end

function ExRT.lib.CreateColorPickButton(parent,width,height,relativePoint,x,y,cR,cG,cB,cA)
	local self = CreateFrame("Button",nil,parent)
	self:SetPoint(relativePoint or "TOPLEFT",x,y)
	self:SetSize(width,height)
	self:SetBackdrop({edgeFile = ExRT.mds.defBorder, edgeSize = 8})
	
	self:SetScript("OnEnter",function ()
		self:SetBackdropBorderColor(0.5,1,0,5,1)
	end)
	self:SetScript("OnLeave",function ()
	  	self:SetBackdropBorderColor(1,1,1,1)
	end)
	
	self.color = self:CreateTexture(nil, "BACKGROUND")
	self.color:SetTexture(cR or 0, cG or 0, cB or 0, cA or 1)
	self.color:SetAllPoints()
	
	return self
end

do
	local function ScrollTabsFrameNewTab(self,name)
		local i = #self.tab + 1
		self.list.L[i] = name
		self.tab[i] = ExRT.lib.CreateOneTab(self,self.newTabWidth,self.newTabHeight,"TOPLEFT",205+(self.newTabBorder and 0 or 5),self.newTabBorder and 0 or -5)
		
		self.list:Update()
	end
	function ExRT.lib.CreateScrollTabsFrame(name,parent,relativePoint,x,y,width,height,noSelfBorder,...)
		local linesNum = floor((height - 8)/16)
		height = height - ((height-8)%16) + (noSelfBorder and 0 or 10)
		relativePoint = relativePoint or "TOPLEFT"
		
		local self
		if noSelfBorder then
			self = CreateFrame("Frame",name,parent)
			self:SetSize(width,height)
			self:SetPoint(relativePoint,x,y)
		else
			self = ExRT.lib.CreateOneTab(parent,width,height,relativePoint,x,y)
			_G[name] = self
		end
		self.list = ExRT.lib.CreateScrollList(name.."ScrollList",self,"TOPLEFT",noSelfBorder and 0 or 5,noSelfBorder and 0 or -5,200,linesNum)
		self.tab = {}
		self.listCount = select("#", ...)
		for i=1,self.listCount do
			self.list.L[i] = select(i, ...)
			self.tab[i] = ExRT.lib.CreateOneTab(self,width-205-(noSelfBorder and 0 or 10),height-(noSelfBorder and 0 or 10),"TOPLEFT",205+(noSelfBorder and 0 or 5),noSelfBorder and 0 or -5)
		end
		self.list:Update()
		
		function self.list:SetListValue(index)
			for i=1,_G[name].listCount do
				ExRT.lib.ShowOrHide(_G[name].tab[i],i == index)
			end
		end
		self.list.selected = 1
		self.list:SetListValue(1)
		
		self.newTabWidth = width-205-(noSelfBorder and 0 or 10)
		self.newTabHeight = height-(noSelfBorder and 0 or 10)
		self.newTabBorder = noSelfBorder
		self.createNewTab = ScrollTabsFrameNewTab
	
		return self
	end
end

function ExRT.lib.CreateHiddenFrame(name,parent,relativePoint,x,y,width,height)
	local self = CreateFrame("Frame",name,parent)
	self:SetSize(width,height)
	self:SetPoint(relativePoint or "TOPLEFT",x,y)
		
	return self
end

function ExRT.lib.CreateDropDown(name,parent,relativePoint,x,y,width,tooltip)
	local self = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
	self:SetPoint(relativePoint or "TOPLEFT",x,y)
	self:SetWidth(width)
	UIDropDownMenu_SetWidth(self, width)
	self.width = width
	
	return self
end

---> Scroll Drop Down
do
	local function ScrollDropDownOnHide()
		ExRT.lib.ScrollDropDown.DropDownList:Hide()
	end
	function ExRT.lib.CreateScrollDropDown(name,parent,relativePoint,x,y,width,dropDownWidth,lines,defText,tooltip)
		local self = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
		self:SetPoint(relativePoint or "TOPLEFT",x,y)
		self:SetWidth(width)
		UIDropDownMenu_SetWidth(self, width)
		
		dropDownWidth = dropDownWidth or width
		
		_G[name.."Button"]:SetScript("OnClick",ExRT.lib.ScrollDropDown.ClickButton)
		self:SetScript("OnHide",ScrollDropDownOnHide)
		
		self.List = {}
		self.Width = dropDownWidth
		self.Lines = lines or 10
	
		return self
	end
end

ExRT.lib.ScrollDropDown = {}
ExRT.lib.ScrollDropDown.List = {}
ExRT.lib.ScrollDropDown.DropDownList = CreateFrame("Frame","ExRTDropDownList",UIParent,"ExRTDropDownListTemplate")
ExRT.lib.ScrollDropDown.DropDownList.Buttons = {}
ExRT.lib.ScrollDropDown.DropDownList.MaxLines = 10
for i=1,10 do
	ExRT.lib.ScrollDropDown.DropDownList.Buttons[i] = CreateFrame("Button","ExRTDropDownListButton"..i,ExRT.lib.ScrollDropDown.DropDownList,"ExRTDropDownMenuButtonTemplate")
	ExRT.lib.ScrollDropDown.DropDownList.Buttons[i]:SetPoint("TOPLEFT",18,-16 - (i-1) * 16)
end
ExRT.lib.ScrollDropDown.DropDownList.Slider = ExRT.lib.CreateSlider("ExRTDropDownListSlider",ExRT.lib.ScrollDropDown.DropDownList,15,170,-15,-11,1,10,"Text",1,"TOPRIGHT",true)
ExRT.lib.ScrollDropDown.DropDownList.Slider:SetScript("OnValueChanged",function (self,value)
	value = ExRT.mds.Round(value)
	ExRT.lib.ScrollDropDown.DropDownList.Position = value
	ExRT.lib.ScrollDropDown.Reload()
end)
ExRT.lib.ScrollDropDown.DropDownList.Slider:SetScript("OnEnter",function() UIDropDownMenu_StopCounting(ExRT.lib.ScrollDropDown.DropDownList) end)
ExRT.lib.ScrollDropDown.DropDownList.Slider:SetScript("OnLeave",function() UIDropDownMenu_StartCounting(ExRT.lib.ScrollDropDown.DropDownList) end)

ExRT.lib.ScrollDropDown.DropDownList:SetScript("OnMouseWheel",function (self,delta)
	local min,max = self.Slider:GetMinMaxValues()
	local val = self.Slider:GetValue()
	if (val - delta) < min then
		self.Slider:SetValue(min)
	elseif (val - delta) > max then
		self.Slider:SetValue(max)
	else
		self.Slider:SetValue(val - delta)
	end
end)

function ExRT.lib.ScrollDropDown.CreateButton(i)
	if ExRT.lib.ScrollDropDown.DropDownList.Buttons[i] then
		return
	end
	ExRT.lib.ScrollDropDown.DropDownList.Buttons[i] = CreateFrame("Button","ExRTDropDownListButton"..i,ExRT.lib.ScrollDropDown.DropDownList,"ExRTDropDownMenuButtonTemplate")
	ExRT.lib.ScrollDropDown.DropDownList.Buttons[i]:SetPoint("TOPLEFT",18,-16 - (i-1) * 16)
end

function ExRT.lib.ScrollDropDown.ClickButton(self)
	if ExRT.lib.ScrollDropDown.DropDownList:IsShown() then
		ExRT.lib.ScrollDropDown.DropDownList:Hide()
		return
	end
	ExRT.lib.ScrollDropDown.ToggleDropDownMenu(self:GetParent())
	PlaySound("igMainMenuOptionCheckBoxOn")
end

function ExRT.lib.ScrollDropDown.Reload()
	local val = ExRT.lib.ScrollDropDown.DropDownList.Position
	local count = #ExRT.lib.ScrollDropDown.List
	local now = 0
	for i=val,count do
		now = now + 1
		local data = ExRT.lib.ScrollDropDown.List[i]
		local button = ExRT.lib.ScrollDropDown.DropDownList.Buttons[now]
		local text = button.NormalText
		local icon = button.Icon
		local paddingLeft = data.padding or 0
		
		if data.icon then
			icon:SetTexture(data.icon)
			paddingLeft = paddingLeft + 16
			icon:Show()
		else
			icon:Hide()
		end
		
		if data.font and now <= 10 then
			local fontObject = _G["ExRTDropDownListFont"..now]
			fontObject:SetFont(data.font,12)
			fontObject:SetShadowOffset(1,-1)
			button:SetNormalFontObject(fontObject)
			button:SetHighlightFontObject(fontObject)
		else
			button:SetNormalFontObject(GameFontHighlightSmallLeft)
			button:SetHighlightFontObject(GameFontHighlightSmallLeft)
		end
		
		if data.colorCode then
			text:SetText( data.colorCode .. (data.text or "") .. "|r" )
		else
			text:SetText( data.text or "" )
		end
		
		if data.justifyH and data.justifyH == "CENTER"  then
			text:SetPoint("CENTER", button, "CENTER", -7, 0)
		else
			text:SetPoint("LEFT", button, "LEFT", 0, 0)
		end
		text:SetPoint("RIGHT", button, "RIGHT", 0, 0)
		text:SetJustifyH(data.justifyH or "LEFT")
		
		local texture = button.Texture
		if data.texture then
			texture:SetTexture(data.texture)
			texture:Show()
		else
			texture:Hide()
		end
		
		button.id = i
		button.arg1 = data.arg1
		button.arg2 = data.arg2
		button.func = data.func
		
		button:Show()
		
		if now >= ExRT.lib.ScrollDropDown.DropDownList.LinesNow then
			break
		end
	end
	for i=(now+1),ExRT.lib.ScrollDropDown.DropDownList.MaxLines do
		ExRT.lib.ScrollDropDown.DropDownList.Buttons[i]:Hide()
	end
end

function ExRT.lib.ScrollDropDown.Update(self, elapsed)
	if ( not self.showTimer or not self.isCounting ) then
		return
	elseif ( self.showTimer < 0 ) then
		self:Hide()
		self.showTimer = nil
		self.isCounting = nil
	else
		self.showTimer = self.showTimer - elapsed
	end
end

function ExRT.lib.ScrollDropDown.OnClick(self, button, down)
	local func = self.func
	if func then
		func(self, self.arg1, self.arg2)
	end
end

function ExRT.lib.ScrollDropDown.ToggleDropDownMenu(self)
	ExRT.lib.ScrollDropDown.List = self.List
	
	local count = #ExRT.lib.ScrollDropDown.List
	for i=(ExRT.lib.ScrollDropDown.DropDownList.MaxLines+1),self.Lines do
		ExRT.lib.ScrollDropDown.CreateButton(i)
	end
	ExRT.lib.ScrollDropDown.DropDownList.MaxLines = max(ExRT.lib.ScrollDropDown.DropDownList.MaxLines,self.Lines)
	
	for i=1,self.Lines do
		ExRT.lib.ScrollDropDown.DropDownList.Buttons[i]:SetSize(self.Width - 25,16)
	end
	ExRT.lib.ScrollDropDown.DropDownList.Position = 1
	ExRT.lib.ScrollDropDown.DropDownList.LinesNow = self.Lines
	ExRT.lib.ScrollDropDown.DropDownList.Slider:SetValue(1)
	ExRT.lib.ScrollDropDown.Reload()
	ExRT.lib.ScrollDropDown.DropDownList:SetPoint("TOPRIGHT",self,"BOTTOMRIGHT",-16,0)
	ExRT.lib.ScrollDropDown.DropDownList:SetSize(self.Width + 32,32 + 16 * self.Lines)
	ExRT.lib.ScrollDropDown.DropDownList.Slider:SetMinMaxValues(1,max(count-self.Lines+1,1))
	ExRT.lib.ScrollDropDown.DropDownList.Slider:SetHeight(self.Lines * 16 + 10)
	
	ExRT.lib.ScrollDropDown.DropDownList:Show()
end

function ExRT.lib.ScrollDropDown.CreateInfo(self,info)
	if info then
		self.List[#self.List + 1] = info
	end
	self.List[#self.List + 1] = {}
	return self.List[#self.List]
end

function ExRT.lib.ScrollDropDown.ClearData(self)
	table.wipe(self.List)
	return self.List
end

function ExRT.lib.ScrollDropDown.Close()
	ExRT.lib.ScrollDropDown.DropDownList:Hide()
end

---> End Scroll Drop Down

do
	local function ListFrameOnUpdate(self)
		local x, y = GetCursorPosition()
		local s = self:GetEffectiveScale()
		x, y = x/s, y/s
		local t,l,b,r = self:GetTop(),self:GetLeft(),self:GetBottom(),self:GetRight()
		if not (x >= l and x <= r and y <= t and y >= b) then
			if not self.hideTimer then
				self.hideTimer = ExRT.mds.ScheduleTimer(self.HideByTimer,2, self)
			end
		elseif self.hideTimer then
			ExRT.mds.CancelTimer(self.hideTimer)
			self.hideTimer = nil
		end
	end
	local function ListFrameHideByTimer(self)
		self:Hide()
		if self.hideTimer then
			ExRT.mds.CancelTimer(self.hideTimer)
		end
		self.hideTimer = nil
	end	
	local function ListFrameButtonToggle(self)
		local parent = self.parent
		if not parent:IsShown() then
			local x, y = GetCursorPosition()
			local s = self:GetEffectiveScale()
			x, y = x/s, y/s
			parent:ClearAllPoints()
			parent:SetPoint("TOPRIGHT",self,"BOTTOMLEFT",5,5)
			parent:Show()
			parent.hideTimer = ExRT.mds.ScheduleTimer(parent.HideByTimer,2, parent)
		else
			parent.HideByTimer(parent)
		end
	end
	function ExRT.lib.CreateListFrame(name,parent,width,buttonsNum,buttonPos,relativePoint,x,y,buttonText,listClickFunc)
		local self = CreateFrame("Frame",name,parent,"ExRTTranslucentFrameTemplate")
		self:SetSize(width,18*buttonsNum+30)
		self:Hide()
		self:SetFrameStrata("DIALOG")
		self:SetClampedToScreen(true)
 		self.HideByTimer = ListFrameHideByTimer
		self:SetScript("OnUpdate",ListFrameOnUpdate)
		
		self.buttonToggle = CreateFrame("Button",name.."ButtonToggle",parent,"ExRTUIChatDownButtonTemplate")
		if buttonPos == "RIGHT" then
			self.buttonToggle:SetPoint("TOPRIGHT",parent,relativePoint or "TOPLEFT",x,y)
			self.buttonToggleText = ExRT.lib.CreateText(self.buttonToggle,0,18,"TOPRIGHT",-24,-3,"RIGHT",nil,nil,12,buttonText,nil,1,1,1,1)
		else
			self.buttonToggle:SetPoint("TOPLEFT",parent,relativePoint or "TOPLEFT",x,y)
			self.buttonToggleText = ExRT.lib.CreateText(self.buttonToggle,0,18,"TOPLEFT",24,-3,"LEFT",nil,nil,12,buttonText,nil,1,1,1,1)
		end
		self.buttonToggle.parent = self
		self.buttonToggle:SetScript("OnClick",ListFrameButtonToggle)
		
		self.buttons = {}
		for i=1,buttonsNum do
			self.buttons[i] = CreateFrame("Button",nil,self)
			self.buttons[i]:SetSize(width-20,18)
			self.buttons[i]:SetPoint("TOP", 0, -15-(i-1)*18)
			
			if listClickFunc then
				self.buttons[i]:SetScript("OnClick",listClickFunc)
			end
			
			self.buttons[i].text = ExRT.lib.CreateText(self.buttons[i],width-20,18,nil,0,0,"CENTER",nil,nil,nil,"",nil,1,1,1)
			
			self.buttons[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight","ADD")
			
			self.buttons[i].id = i
		end
		
		return self
	end
end

function ExRT.lib.SetPoint(self,...)
	self:ClearAllPoints()
	self:SetPoint(...)
end