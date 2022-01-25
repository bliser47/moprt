local GlobalAddonName, ExRT = ...

local IsEncounterInProgress, GetTime = IsEncounterInProgress, GetTime

local VExRT = nil

local module = ExRT.mod:New("RaidCheck",ExRT.L.raidcheck)
module.db.isEncounter = nil
module.db.tableFood = {
--Stamina,	Spirit,		Int,		Agi,		Str
[104283]=300,	[104280]=300,	[104277]=300,	[104275]=300,	[104272]=300,
[146808]=300,	[146807]=300,	[146806]=300,	[146805]=300,	[146804]=300,	--5.4 food
[104282]=275,	[104279]=275,	[104276]=275,	[104274]=275,	[104271]=275,
[104281]=250,	[104278]=250,	[104264]=250,	[104273]=250,	[104267]=250,
}
module.db.tableFood_headers = {0,250,275,300}
module.db.tableFlask = {
--Stamina,	Spirit,		Int,		Agi,		Str
[105694]=1000,	[105693]=1000,	[105691]=1000,	[105689]=1000,	[105696]=1000,
}
module.db.tableFlask_headers = {0,1000}
module.db.tablePotion = {
[105702]=true,	--Int
[105697]=true,	--Agi	
[105706]=true,	--Str
[105709]=true,	--Mana 30k
[105701]=true,	--Mana 45k
[105707]=true,	--Run haste
[105698]=true,	--Armor
[125282]=true,	--Kafa Boost
}
module.db.potionList = {}
module.db.hsList = {}
module.db.tableFoodInProgress = nil
module.db.RaidCheckReadyCheckHide = nil
module.db.RaidCheckReadyCheckTime = nil
module.db.RaidCheckReadyCheckTable = {}
module.db.RaidCheckReadyPPLNum = 0
module.db.RaidCheckReadyCheckHideSchedule = nil

local function GetFood(arg1,arg2)
	local f = {[0]={},[250]={},[275]={},[300]={}}
	local gMax = ExRT.mds.GetRaidDiffMaxGroup()
	for j=1,40 do
		local name,_,subgroup = GetRaidRosterInfo(j)
		if name and subgroup <= gMax then
			local b = nil
			for i=1,40 do
				local spellId = select(11,UnitAura(name, i,"HELPFUL"))
				if not spellId then
					break
				elseif module.db.tableFood[spellId] then
					table.insert(f[module.db.tableFood[spellId]],name)
					b = true
				end
			end
			if not b then
				table.insert(f[0],name)
			end
		end
	end

	local function toChat(h,y)
		local chat_type = ExRT.mds.chatType(true)
		if arg1 == 2 then print(h) end
		if arg1 == 1 then SendChatMessage(h,chat_type) end
		if arg2 == 1 and y == 0 then SendChatMessage(h,chat_type) end	  
	end
	
	for i=1,#module.db.tableFood_headers do
		local h = format("%d (%d): ",module.db.tableFood_headers[i],#f[module.db.tableFood_headers[i]])
		if arg2 == 1 and module.db.tableFood_headers[i] == 0 then h = format("%s (%d): ",ExRT.L.raidchecknofood,#f[module.db.tableFood_headers[i]]) end
		for j=1,#f[module.db.tableFood_headers[i]] do
			h = h .. f[module.db.tableFood_headers[i]][j] .. (j < #f[module.db.tableFood_headers[i]] and ", " or "")
			if #h > 230 then
				toChat(h,module.db.tableFood_headers[i])
				h = ""
			end
		end
		toChat(h,module.db.tableFood_headers[i])
	end
end


local function GetFlask(arg1,arg2)
	local f = {[0]={},[1000]={}}
	local gMax = ExRT.mds.GetRaidDiffMaxGroup()
	for j=1,40 do
		local name,_,subgroup = GetRaidRosterInfo(j)
		if name and subgroup <= gMax then
			local b = nil
			for i=1,40 do
				local expires,_,_,_,spellId = select(7,UnitAura(name, i,"HELPFUL"))
				if not spellId then
					break
				elseif module.db.tableFlask[spellId] then
					expires = expires or 9999999
					table.insert(f[module.db.tableFlask[spellId]],{name,expires-GetTime()})
					b = true
				end
			end
			if not b then
				table.insert(f[0],{name,901})
			end
		end
	end
	table.sort(f[1000],function(a,b) return a[2]<b[2] end)

	local function toChat(h,y)
		local chat_type = ExRT.mds.chatType(true)
		if arg1 == 2 then print(h) end
		if arg1 == 1 then SendChatMessage(h,chat_type) end
		if arg2 == 1 and y == 0 then SendChatMessage(h,chat_type) end	  
	end
	
	for i=1,#module.db.tableFlask_headers do
		local k = module.db.tableFlask_headers[i]
		local h = format("%d (%d): ",k,#f[k])
		if arg2 == 1 and k == 0 then h = format("%s (%d): ",ExRT.L.raidchecknoflask,#f[k]) end
		for j=1,#f[k] do
			h = h .. format("%s%s%s",f[k][j][1] or "?", f[k][j][2] and f[k][j][2] <= 900 and ("("..tostring(math.floor(f[k][j][2]/60))..")") or "" ,j < #f[k] and ", " or "")
			if #h > 230 then
				toChat(h,k)
				h = ""
			end
		end
		toChat(h,k)
	end
end

local function GetPotion(arg1)
	local h = ExRT.L.raidcheckPotion
	local t = {}
	for key,val in pairs(module.db.potionList) do
		t[#t+1] = {key,val}
	end

	local function toChat(h)
		local chat_type = ExRT.mds.chatType(true)
		if arg1 == 2 then print(h) end
		if arg1 == 1 then SendChatMessage(h,chat_type) end  
	end

	table.sort(t,function(a,b) return a[2]>b[2] end)
	for i=1,#t do
		h = h .. format("%s %d%s",t[i][1],t[i][2],i<#t and ", " or "")
		if #h > 230 then
			toChat(h)
			h = ""
		end
	end
	toChat(h)
end

local function GetHs(arg1)
	local h = ExRT.L.raidcheckHS
	local t = {}
	for key,val in pairs(module.db.hsList) do
		t[#t+1] = {key,val}
	end

	local function toChat(h)
		local chat_type = ExRT.mds.chatType(true)
		if arg1 == 2 then print(h) end
		if arg1 == 1 then SendChatMessage(h,chat_type) end
	end

	table.sort(t,function(a,b) return a[2]>b[2] end)
	for i=1,#t do
		h = h .. format("%s %d%s",t[i][1],t[i][2],i<#t and ", " or "")
		if #h > 230 then
			toChat(h)
			h = ""
		end
	end
	toChat(h)
end

function module.options:Load()
	self.food = ExRT.lib.CreateButton(nil,self,230,22,nil,10,-10,ExRT.L.raidcheckfood)       
	self.food:SetScript("OnClick",function()
		GetFood(2)
	end)  
	
	self.foodToChat = ExRT.lib.CreateButton(nil,self,230,22,nil,311,-10,ExRT.L.raidcheckfoodchat)       
	self.foodToChat:SetScript("OnClick",function()
		GetFood(1)
	end)  
	
	self.flask = ExRT.lib.CreateButton(nil,self,230,22,nil,10,-35,ExRT.L.raidcheckflask)       
	self.flask:SetScript("OnClick",function()
		GetFlask(2)
	end)  
	
	self.flaskToChat = ExRT.lib.CreateButton(nil,self,230,22,nil,311,-35,ExRT.L.raidcheckflaskchat)       
	self.flaskToChat:SetScript("OnClick",function()
		GetFlask(1)
	end)
	
	self.food.txt = ExRT.lib.CreateText(self,100,22,nil,245,-10,nil,nil,nil,11,"/rt food")
	self.foodToChat.txt = ExRT.lib.CreateText(self,100,22,nil,546,-10,nil,nil,nil,11,"/rt foodchat")
	self.flask.txt = ExRT.lib.CreateText(self,100,22,nil,245,-35,nil,nil,nil,11,"/rt flask")
	self.flaskToChat.txt = ExRT.lib.CreateText(self,100,22,nil,546,-35,nil,nil,nil,11,"/rt flaskchat")
	
	self.chkSlak = ExRT.lib.CreateCheckBox(nil,self,nil,10,-60,ExRT.L.raidcheckslak)
	self.chkSlak:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.RaidCheck.ReadyCheck = true
			module:RegisterEvents('READY_CHECK')
		else
			VExRT.RaidCheck.ReadyCheck = nil
			if not VExRT.RaidCheck.ReadyCheckFrame then
				module:UnregisterEvents('READY_CHECK')
			end
		end
	end)
	
	self.chkPotion = ExRT.lib.CreateCheckBox(nil,self,nil,10,-85,ExRT.L.raidcheckPotionCheck)
	self.chkPotion:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.RaidCheck.PotionCheck = true
			module.options.potionToChat:Enable()
			module.options.potion:Enable()
			module.options.hs:Enable()
			module.options.hsToChat:Enable()
			--module:RegisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
		else
			VExRT.RaidCheck.PotionCheck = nil
			module.options.potionToChat:Disable()
			module.options.potion:Disable()
			module.options.hs:Disable()
			module.options.hsToChat:Disable()
			--module:UnregisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
		end
	end)

	self.potion = ExRT.lib.CreateButton(nil,self,230,22,nil,10,-115,ExRT.L.raidcheckPotionLastPull,not VExRT.RaidCheck.PotionCheck)       
	self.potion:SetScript("OnClick",function()
		GetPotion(2)
	end)  
	
	self.potionToChat = ExRT.lib.CreateButton(nil,self,230,22,nil,311,-115,ExRT.L.raidcheckPotionLastPullToChat,not VExRT.RaidCheck.PotionCheck)       
	self.potionToChat:SetScript("OnClick",function()
		GetPotion(1)
	end)
	
	self.potion.txt = ExRT.lib.CreateText(self,100,22,nil,245,-115,nil,nil,nil,11,"/rt potion")
	self.potionToChat.txt = ExRT.lib.CreateText(self,100,22,nil,546,-115,nil,nil,nil,11,"/rt potionchat")
	
	self.hs = ExRT.lib.CreateButton(nil,self,230,22,nil,10,-140,ExRT.L.raidcheckHSLastPull,not VExRT.RaidCheck.PotionCheck)       
	self.hs:SetScript("OnClick",function()
		GetHs(2)
	end)  
	
	self.hsToChat = ExRT.lib.CreateButton(nil,self,230,22,nil,311,-140,ExRT.L.raidcheckHSLastPullToChat,not VExRT.RaidCheck.PotionCheck)       
	self.hsToChat:SetScript("OnClick",function()
		GetHs(1)
	end)  

	self.optReadyCheckFrameHeader = ExRT.lib.CreateText(self,550,20,nil,20,-167,nil,nil,nil,nil,ExRT.L.raidcheckReadyCheck)

	self.optReadyCheckFrame = CreateFrame("Frame",nil,self)
	self.optReadyCheckFrame:SetSize(603,85)
	self.optReadyCheckFrame:SetBackdrop({bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
	self.optReadyCheckFrame:SetBackdropColor(0,0,0,0.5)
	self.optReadyCheckFrame:SetPoint("TOP",0,-185)

	self.chkReadyCheckFrameEnable = ExRT.lib.CreateCheckBox(nil,self.optReadyCheckFrame,nil,15,-10,ExRT.L.senable)
	self.chkReadyCheckFrameEnable:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			module:RegisterEvents('READY_CHECK','READY_CHECK_FINISHED','READY_CHECK_CONFIRM')
			VExRT.RaidCheck.ReadyCheckFrame = true
		else
			module:UnregisterEvents('READY_CHECK_FINISHED','READY_CHECK_CONFIRM')
			if not VExRT.RaidCheck.ReadyCheck then
				module:UnregisterEvents('READY_CHECK')
			end
			VExRT.RaidCheck.ReadyCheckFrame = nil
		end
	end)

	self.chkReadyCheckFrameSliderScale = ExRT.lib.CreateSlider(self:GetName().."ReadyCheckFrameSliderScale",self.optReadyCheckFrame,250,15,25,-50,5,200,ExRT.L.raidcheckReadyCheckScale,100)
	self.chkReadyCheckFrameSliderScale:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.RaidCheck.ReadyCheckFrameScale = event
		ExRT.mds.SetScaleFix(module.frame,event/100)
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.chkReadyCheckFrameButTest = ExRT.lib.CreateButton(nil,self.optReadyCheckFrame,280,22,nil,310,-10,ExRT.L.raidcheckReadyCheckTest)
	self.chkReadyCheckFrameButTest:SetScript("OnClick", function(self) 
		module.main:READY_CHECK("raid1",35,"TEST")
		for i=2,25 do
			local y = math.random(1,30000)
			local r = math.random(1,2)
			ExRT.mds.ScheduleTimer(function() module.main:READY_CHECK_CONFIRM("raid"..i,r==1,"TEST") end, y/1000)
		end
	end)

	self.chkReadyCheckFrameHtmlTimer = ExRT.lib.CreateText(self.optReadyCheckFrame,200,24,nil,310,-50,nil,nil,nil,11,ExRT.L.raidcheckReadyCheckTimerTooltip)

	self.chkReadyCheckFrameEditBoxTimer = ExRT.lib.CreateEditBox(self:GetName().."ReadyCheckFrameEditBoxTimer",self.optReadyCheckFrame,50,24,nil,515,-50,nil,6,1,"InputBoxTemplate","4")
	self.chkReadyCheckFrameEditBoxTimer:SetScript("OnTextChanged",function(self)
		VExRT.RaidCheck.ReadyCheckFrameTimerFade = tonumber(self:GetText()) or 4
		if VExRT.RaidCheck.ReadyCheckFrameTimerFade < 2.5 then VExRT.RaidCheck.ReadyCheckFrameTimerFade = 2.5 end
	end) 

	self.chkSlak:SetChecked(VExRT.RaidCheck.ReadyCheck)
	self.chkPotion:SetChecked(VExRT.RaidCheck.PotionCheck)
	self.chkReadyCheckFrameEnable:SetChecked(VExRT.RaidCheck.ReadyCheckFrame)
	self.chkReadyCheckFrameSliderScale:SetValue(VExRT.RaidCheck.ReadyCheckFrameScale or 100)
	self.chkReadyCheckFrameEditBoxTimer:SetText(VExRT.RaidCheck.ReadyCheckFrameTimerFade or 4)

	self:SetScript("OnShow",nil)
end

local function CheckPotionsOnPull()
	table.wipe(module.db.potionList)
	local gMax = ExRT.mds.GetRaidDiffMaxGroup()
	for j=1,40 do
		local name,_,subgroup = GetRaidRosterInfo(j)
		if name and subgroup <= gMax then
			local b = nil
			for i=1,40 do
				local _,_,_,_,_,_,_,_,_,_,spellId = UnitAura(name, i,"HELPFUL")
				if not spellId then
					break
				elseif module.db.tablePotion[spellId] then
					module.db.potionList[name] = 1
					b = true
				end
			end
			if not b then
				module.db.potionList[name] = 0
			end
		end
	end
end

function module:timer(elapsed)
	if VExRT.RaidCheck.PotionCheck then
		if not module.db.isEncounter and IsEncounterInProgress() then
			module.db.isEncounter = true

			ExRT.mds.ScheduleTimer(CheckPotionsOnPull,1.5)
			
			table.wipe(module.db.hsList)
			local gMax = ExRT.mds.GetRaidDiffMaxGroup()
			for j=1,40 do
				local name,_,subgroup = GetRaidRosterInfo(j)
				if name and subgroup <= gMax then
					module.db.hsList[name] = 0
				end
			end
			
			module:RegisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
		elseif module.db.isEncounter and not IsEncounterInProgress() then
			module.db.isEncounter = nil
			
			module:UnregisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
		end
	end
	if VExRT.RaidCheck.ReadyCheckFrame and module.db.RaidCheckReadyCheckHide then
		module.db.RaidCheckReadyCheckHide = module.db.RaidCheckReadyCheckHide - elapsed
		if module.db.RaidCheckReadyCheckHide < 2 and not module.frame.anim:IsPlaying() then
			module.frame.anim:Play()
		end
		if module.db.RaidCheckReadyCheckHide < 0 then
			module.db.RaidCheckReadyCheckHide = nil
		end
	end
	if VExRT.RaidCheck.ReadyCheckFrame and module.frame:IsShown() then
		local h = ""
		local ctime_ = module.db.RaidCheckReadyCheckTime - GetTime()
		if ctime_ > 0 then 
			h = format(" (%d %s)",ctime_+1,ExRT.L.raidcheckReadyCheckSec) 
		end
		module.frame.headText:SetText(ExRT.L.raidcheckReadyCheck..h)
	end
end

function module:slash(arg)
	if arg == "food" then
		GetFood(2)
	elseif arg == "flask" then
		GetFlask(2)
	elseif arg == "foodchat" then
		GetFood(1)
	elseif arg == "flaskchat" then
		GetFlask(1)
	elseif arg == "potion" and VExRT.RaidCheck.PotionCheck then
		GetPotion(2)
	elseif arg == "potionchat" and VExRT.RaidCheck.PotionCheck then
		GetPotion(1)
	end
end

module.frame = CreateFrame("FRAME","ExRTRaidCheckReadyCheckFrame",UIParent,"UIPanelDialogTemplate")
module.frame:SetSize(140*2+20,18*13+40)
module.frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
module.frame:SetFrameStrata("DIALOG")
module.frame:EnableMouse(true)
module.frame:SetMovable(true)
module.frame:RegisterForDrag("LeftButton")
module.frame:SetScript("OnDragStart", function(self) 
	self:StartMoving()
end)
module.frame:SetScript("OnDragStop", function(self) 
	self:StopMovingOrSizing()
	VExRT.RaidCheck.ReadyCheckLeft = self:GetLeft()
	VExRT.RaidCheck.ReadyCheckTop = self:GetTop()
end)
module.frame:Hide()
module.frame.headText = ExRT.lib.CreateText(module.frame,290,18,nil,15,-7,nil,nil,ExRT.mds.defFont,14,ExRT.L.raidcheckReadyCheck,nil,1,1,1,1)

module.frame.anim = module.frame:CreateAnimationGroup()
module.frame.timer = module.frame.anim:CreateAnimation()
module.frame.timer:SetScript("OnFinished", function() 
	module.frame.anim:Stop() 
	module.frame:Hide() 
end)
module.frame.timer:SetDuration(2)
module.frame.timer:SetScript("OnUpdate", function(self,elapsed) 
	module.frame:SetAlpha(1-self:GetProgress())
end)
module.frame:SetScript("OnHide", function(self) 
	module.frame.anim:Stop()
end)

module.frame.u = {}
for i=1,25 do
	module.frame.u[i] = CreateFrame("FRAME",nil,module.frame)
	module.frame.u[i]:SetPoint("TOPLEFT", ((i-1)%2)*140+10, -floor((i-1)/2)*18-30)
	module.frame.u[i]:SetSize(140,18)

	module.frame.u[i].t = ExRT.lib.CreateText(module.frame.u[i],120,18,nil,20,0,nil,nil,ExRT.mds.defFont,12,"raid"..i,nil,1,1,1,1)

	module.frame.u[i].icon = ExRT.lib.CreateIcon(nil,module.frame.u[i],18,nil,0,0,"Interface\\RaidFrame\\ReadyCheck-Waiting",nil)
end

local function RaidCheckReadyCheckReset(starter,isTest)
	table.wipe(module.db.RaidCheckReadyCheckTable)
	local j = 0
	local gMax = ExRT.mds.GetRaidDiffMaxGroup()
	module.db.RaidCheckReadyPPLNum = 0
	module.frame:SetHeight(18*ceil(gMax*5/2)+40)
	for i=1,40 do
		local name,_,subgroup = GetRaidRosterInfo(i)
		if isTest then
			name = format("%s%d","raid",i)
			subgroup = i / 5
		end
		if name and subgroup <= gMax then 
			j = j + 1
			if j > 25 then break end
			module.frame.u[j].t:SetText(name)
			module.frame.u[j].t:SetTextColor(1,1,1,1)
			module.frame.u[j].icon.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
			module.frame.u[j]:Show()

			module.db.RaidCheckReadyPPLNum = module.db.RaidCheckReadyPPLNum + 1
			module.db.RaidCheckReadyCheckTable[ExRT.mds.delUnitNameServer(name)] = j
		end
	end
	for i=(j+1),25 do
		module.frame.u[i]:Hide()
	end
	module.frame.anim:Stop()
	module.frame:SetAlpha(1)
	module.frame:Show()
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.RaidCheck = VExRT.RaidCheck or {}

	if VExRT.RaidCheck.ReadyCheckLeft and VExRT.RaidCheck.ReadyCheckTop then
		module.frame:ClearAllPoints()
		module.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.RaidCheck.ReadyCheckLeft,VExRT.RaidCheck.ReadyCheckTop) 
	end
	if VExRT.RaidCheck.ReadyCheckFrameScale then
		module.frame:SetScale(VExRT.RaidCheck.ReadyCheckFrameScale/100)
	end
	VExRT.RaidCheck.ReadyCheckFrameTimerFade = VExRT.RaidCheck.ReadyCheckFrameTimerFade or 4
	
	module.db.tableFoodInProgress = GetSpellInfo(104934)
	
	if VExRT.RaidCheck.ReadyCheckFrame then
		module:RegisterEvents('READY_CHECK_FINISHED','READY_CHECK_CONFIRM')
	end
	if VExRT.RaidCheck.ReadyCheck or VExRT.RaidCheck.ReadyCheckFrame then
		module:RegisterEvents('READY_CHECK')	
	end
	if VExRT.RaidCheck.PotionCheck then
		--module:RegisterEvents('COMBAT_LOG_EVENT_UNFILTERED')
	end
	
	module:RegisterSlash()
	module:RegisterTimer()
end

function module.main:READY_CHECK(starter,timer,isTest)
	if VExRT.RaidCheck.ReadyCheck then
		GetFood(nil,1)
		GetFlask(nil,1)
	end
	if VExRT.RaidCheck.ReadyCheckFrame then
		if not (isTest == "TEST") then isTest = nil end
		module.db.RaidCheckReadyCheckHide = nil
		module.db.RaidCheckReadyCheckTime = GetTime() + (timer or 35)
		ExRT.mds.CancelTimer(module.db.RaidCheckReadyCheckHideSchedule)
		module.db.RaidCheckReadyCheckHideSchedule = ExRT.mds.ScheduleTimer(function() module.main:READY_CHECK_FINISHED() end, timer or 35)
		RaidCheckReadyCheckReset(starter,isTest)
		module.main:READY_CHECK_CONFIRM(ExRT.mds.delUnitNameServer(starter),true,isTest)
	end
end

function module.main:READY_CHECK_FINISHED()
	if not module.db.RaidCheckReadyCheckHide then
		module.db.RaidCheckReadyCheckHide = VExRT.RaidCheck.ReadyCheckFrameTimerFade
	end
end

function module.main:READY_CHECK_CONFIRM(unit,response,isTest)
	if not (isTest == "TEST") then unit = UnitName(unit) isTest = nil end
	if unit and module.db.RaidCheckReadyCheckTable[unit] then
		local foodBuff = nil
		local flaskBuff = nil
		for i=1,40 do
			local name,_,_,_,_,_,_,_,_,_,spellId = UnitAura(unit, i,"HELPFUL")
			if not spellId then
				break
			elseif module.db.tableFood[spellId] then
				foodBuff = true
			elseif module.db.tableFlask[spellId] then
				flaskBuff = true
			elseif name and module.db.tableFoodInProgress == name then
				foodBuff = true
			end
		end
		if isTest then
			if math.random(1,2) == 1 then foodBuff = nil flaskBuff = nil else foodBuff = true flaskBuff = true end
		end
		if not foodBuff or not flaskBuff then
			module.frame.u[module.db.RaidCheckReadyCheckTable[unit]].t:SetTextColor(1,0.5,0.5,1)
		end
		if response == true then
			module.frame.u[module.db.RaidCheckReadyCheckTable[unit]].icon.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		else
			module.frame.u[module.db.RaidCheckReadyCheckTable[unit]].icon.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
		end
		if foodBuff and flaskBuff and response then
			module.frame.u[module.db.RaidCheckReadyCheckTable[unit]]:Hide()
		end

		module.db.RaidCheckReadyPPLNum = module.db.RaidCheckReadyPPLNum - 1
		if module.db.RaidCheckReadyPPLNum <= 0 then
			module.db.RaidCheckReadyCheckHide = VExRT.RaidCheck.ReadyCheckFrameTimerFade
		end
		module.db.RaidCheckReadyCheckTable[unit] = nil
	end
end

do
	local _db = module.db
	function module.main:COMBAT_LOG_EVENT_UNFILTERED(_,event,_,_,sourceName,_,_,_,_,_,_,spellId)
		if event == "SPELL_CAST_SUCCESS" and sourceName then
			if spellId == 6262 then
				_db.hsList[sourceName] = _db.hsList[sourceName] and _db.hsList[sourceName] + 1 or 1
			elseif _db.tablePotion[spellId] then
				_db.potionList[sourceName] = _db.potionList[sourceName] and _db.potionList[sourceName] + 1 or 1
			end
		end
	end
end