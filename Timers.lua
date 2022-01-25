local GlobalAddonName, ExRT = ...

local math_ceil, IsEncounterInProgress, abs, UnitHealth, UnitHealthMax, GetTime, format = math.ceil, IsEncounterInProgress, abs, UnitHealth, UnitHealthMax, GetTime, format

local VExRT = nil

local module = ExRT.mod:New("Timers",ExRT.L.timers)
module.db.lasttimertopull = 0
module.db.timertopull = 0
module.db.firstmsg = false
module.db.timeToKill = {}
module.db.segmentToKill = 1
module.db.maxSegments = 16	-- 0.5 sec every seg
for i=1,module.db.maxSegments do
	module.db.timeToKill[i] = {0,0}
end
local timeToKillEnabled = nil

local function ToRaid(msg)
	if IsInRaid() then
		SendChatMessage(msg, "raid_warning")
	else
		RaidWarningFrame_OnEvent(RaidWarningFrame,"CHAT_MSG_RAID_WARNING",msg)
		print(msg)
	end
end

local function CreateTimers(ctime,cname)
	local chat_type,playerName = ExRT.mds.chatType()

	if cname == ExRT.L.timerattack then
		SendAddonMessage("BigWigs", "T:BWPull "..ctime, chat_type,playerName)
	else
		SendAddonMessage("BigWigs", "T:BWCustomBar "..ctime.." "..cname, chat_type,playerName)
	end
	SendAddonMessage("DXE", "^1^SAlertsRaidBar^N"..ctime.."^S~`"..cname.."^^", chat_type,playerName)
	local Uname = "U"
	if cname == ExRT.L.timerattack then Uname = "PT" end
	if ctime == 0 and cname ~= ExRT.L.timerattack then ctime = 1 end
	if DBM and Uname == "U" then
		DBM:CreatePizzaTimer(ctime, cname, UnitName("player"))
	else
		SendAddonMessage("D4", ("%s\t%s\t%s"):format(Uname,ctime, cname), chat_type,playerName)
	end
end

function module:timer(elapsed)
	if module.db.timertopull > 0 then
		if math_ceil(module.db.timertopull) < math_ceil(module.db.lasttimertopull) then
			if module.db.firstmsg == true or math_ceil(module.db.timertopull) % 5 == 0 or math_ceil(module.db.timertopull) == 7 or math_ceil(module.db.timertopull) < 5 then
				ToRaid(ExRT.L.timerattackt.." "..math_ceil(module.db.timertopull).." "..ExRT.L.timersec)
				module.db.firstmsg = false
			end
			module.db.lasttimertopull = module.db.timertopull
		end
		module.db.timertopull = module.db.timertopull - elapsed
		if module.db.timertopull < 0 then
			module.db.timertopull = 0
			ToRaid(">>> "..ExRT.L.timerattack.." <<<")
		end
	end
	if VExRT.Timers.enabled and not module.frame.encounter and IsEncounterInProgress() then
		module.frame.encounter = true
		module.frame.total = 0
	elseif VExRT.Timers.enabled and module.frame.encounter and not IsEncounterInProgress() then
		module.frame.encounter = nil
	end
end

function ExRT.mds:DoPull(inum)
	if module.db.timertopull > 0 then
		module.db.timertopull = 0
		ToRaid(">>> "..ExRT.L.timerattackcancel.." <<<")
		CreateTimers(0,ExRT.L.timerattack)
	else
		inum = tonumber(inum) or 10
		module.db.firstmsg = true
		module.db.lasttimertopull = inum + 1
		module.db.timertopull = inum
		CreateTimers(inum,ExRT.L.timerattack)
	end
end

function module:slash(arg)
	if arg == "pull" then
		if module.db.timertopull > 0 then
			module.db.timertopull = 0
			ToRaid(">>> "..ExRT.L.timerattackcancel.." <<<")
			CreateTimers(0,ExRT.L.timerattack)
		else
			module.db.firstmsg = true
			module.db.lasttimertopull = 11
			module.db.timertopull = 10
			CreateTimers(10,ExRT.L.timerattack)
		end
	elseif string.find(arg,"^pull ") then
		if module.db.timertopull > 0 then
			module.db.timertopull = 0
			ToRaid(">>> "..ExRT.L.timerattackcancel.." <<<")
			CreateTimers(0,ExRT.L.timerattack)
		else
			local id
			for w in string.gmatch(arg, "%d+") do
				id = tonumber(w)
				break
			end
			if id then
				module.db.firstmsg = true
				module.db.lasttimertopull = id + 1
				module.db.timertopull = id
				CreateTimers(id,ExRT.L.timerattack)
			end
		end
	elseif string.find(arg,"^afk ") then
		local id
		for w in string.gmatch(arg, "%d+") do
			id = tonumber(w)
			break
		end
		if id then
			if id > 0 then
				CreateTimers(id*60,ExRT.L.timerafk)
				ToRaid(ExRT.L.timerafk.." "..math.ceil(id).." "..ExRT.L.timermin)
			else
				CreateTimers(0,ExRT.L.timerafk)
				ToRaid(ExRT.L.timerafkcancel)
			end
		end
	elseif string.find(arg,"^timer ") then
		local id1,id2
		arg = string.sub(arg,7)
		if string.sub(arg,-2,-2) == " " then id1 = string.sub(arg,1,-3) id2 = tonumber(string.sub(arg,-1,-1))
			elseif string.sub(arg,-3,-3) == " " then id1 = string.sub(arg,1,-4) id2 = tonumber(string.sub(arg,-2,-1))
			elseif string.sub(arg,-4,-4) == " " then id1 = string.sub(arg,1,-5) id2 = tonumber(string.sub(arg,-3,-1))
			elseif string.sub(arg,-5,-5) == " " then id1 = string.sub(arg,1,-6) id2 = tonumber(string.sub(arg,-4,-1)) end

		if id1 and id2 then
			CreateTimers(id2,id1)
		end
	elseif VExRT.Timers.enabled and string.find(arg,"^mytimer ") then
		for w in string.gmatch(arg, "%d+") do
			if tonumber(w) then
				module.frame.total = -tonumber(w)
			end
			break
		end	
	end
end

function module.options:Load()
	self.shtml1 = ExRT.lib.CreateText(self,605,200,nil,10,-15,nil,"TOP",nil,13,ExRT.L.timerstxt1)
	self.shtml2 = ExRT.lib.CreateText(self,505,200,nil,110,-15,nil,"TOP",nil,13,ExRT.L.timerstxt2,nil,1,1,1)

	self.chkEnable = ExRT.lib.CreateCheckBox(nil,self,nil,10,-135,ExRT.L.timerTimerFrame)
	self.chkEnable:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Timers.enabled = true
			module.frame:Show()
			module.frame:SetScript("OnUpdate", module.frame.OnUpdateFunc)
			module:RegisterEvents('PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED')
			module.options.chkTimeToKill:SetEnabled(true)
		else
			VExRT.Timers.enabled = nil
			VExRT.Timers.timeToKill = nil
			module.frame:Hide() 
			module.frame:SetScript("OnUpdate", nil)
			module:UnregisterEvents('PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED')
			module.options.chkTimeToKill:SetEnabled(false)
			module.options.chkTimeToKill:SetChecked(nil)
		end
	end)
	self.chkEnable:SetChecked(VExRT.Timers.enabled)
	
	self.chkTimeToKill = ExRT.lib.CreateCheckBox(nil,self,nil,10,-160,ExRT.L.TimerTimeToKill)
	self.chkTimeToKill:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Timers.timeToKill = true
			timeToKillEnabled = true
			module:RegisterEvents('PLAYER_TARGET_CHANGED')
		else
			VExRT.Timers.timeToKill = nil
			timeToKillEnabled = nil
			module:UnregisterEvents('PLAYER_TARGET_CHANGED')
			module.frame.killTime:SetText("")
		end
	end)
	self.chkTimeToKill:SetChecked(VExRT.Timers.timeToKill)
	
	if not VExRT.Timers.enabled then
		self.chkTimeToKill:SetChecked(nil)
		self.chkTimeToKill:SetEnabled(false)
	end
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.Timers = VExRT.Timers or {}

	if VExRT.Timers.Left and VExRT.Timers.Top then 
		module.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Timers.Left,VExRT.Timers.Top) 
	end

	if VExRT.Timers.enabled then 
		module.frame:Show() 
		module.frame:SetScript("OnUpdate", module.frame.OnUpdateFunc)
		module:RegisterEvents('PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED')		
	end
	if VExRT.Timers.enabled and VExRT.Timers.timeToKill then 
		module:RegisterEvents('PLAYER_TARGET_CHANGED')
		timeToKillEnabled = true
	end
	module:RegisterTimer()
	module:RegisterSlash()
end

function module.main:PLAYER_REGEN_DISABLED()
	if not module.frame.encounter then 
		module.frame.total = 0 
	end
	module.frame.inCombat = true
end

function module.main:PLAYER_REGEN_ENABLED()
	module.frame.inCombat = nil
end

function module.main:PLAYER_TARGET_CHANGED()
	for i=1,module.db.maxSegments do
		module.db.timeToKill[i][1] = 0
		module.db.timeToKill[i][2] = 0
	end
	module.frame.killTime:SetText("")
end

module.frame = CreateFrame("Frame",nil,UIParent)
module.frame:Hide()
module.frame:SetSize(77,27)
module.frame:SetPoint("CENTER", 0, 0)
module.frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 4})
module.frame:SetBackdropBorderColor(0.1,0.1,0.1,0.7)
module.frame:SetBackdropColor(0,0,0,0.7)
module.frame:EnableMouse(true)
module.frame:SetMovable(true)
module.frame:RegisterForDrag("LeftButton")
module.frame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
module.frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	VExRT.Timers.Left = self:GetLeft()
	VExRT.Timers.Top = self:GetTop()
end)
module.frame.total = 0
module.frame.tmr = 0
module.frame.killTmr = 0
module.frame.txt = ExRT.lib.CreateText(module.frame,77,27,"CENTER",0,0,"CENTER",nil,ExRT.mds.defFont,16,"00:00.0",nil,1,1,1,1,"OUTLINE")
module.frame.killTime = ExRT.lib.CreateText(module.frame,77,27,"TOP",0,0,"CENTER","TOP",ExRT.mds.defFont,14,"",nil,1,1,1,1,"OUTLINE")
module.frame.killTime:ClearAllPoints()
module.frame.killTime:SetPoint("TOP",module.frame,"BOTTOM",0,0)
module:RegisterHideOnPetBattle(module.frame)

local function NumToTime(num)
	if num >= 600 or num < 0 then
		return ""
	elseif num >= 60 then
		return format("%d:%02d",floor(num/60),num % 60)
	else
		return format("%d",num)
	end
end

function module.frame.OnUpdateFunc(self,elapsed)
	self.tmr = self.tmr + elapsed
	if self.tmr > 0.05 and (self.inCombat or self.encounter or self.total < 0) then
		self.total = self.total + self.tmr
		local txt = format("%2.2d:%2.2d\.%1.1d",abs(self.total)/60,abs(self.total)%60,(abs(self.total)*10)%10)
		if txt ~= self.ExTimerTxt then
			module.frame.txt:SetText(txt)
			self.ExTimerTxt = txt
		end
		self.tmr = 0
	elseif self.tmr > 0.05 then
		self.tmr = 0
	end
	
	if timeToKillEnabled then
		self.killTmr = self.killTmr + elapsed
		if self.killTmr > 0.5 then
			self.killTmr = 0
			local health = UnitHealth("target")
			local maxHealth = UnitHealthMax("target")
			local ctime_ = GetTime()
			local now
			local seg
			if health and maxHealth > 0 then
				now = health / maxHealth
				module.db.timeToKill[ module.db.segmentToKill ][1] = now
				module.db.timeToKill[ module.db.segmentToKill ][2] = ctime_
				module.db.segmentToKill = module.db.segmentToKill + 1
				if module.db.segmentToKill >= module.db.maxSegments then
					module.db.segmentToKill = 1
				end
				seg = module.db.segmentToKill
			else
				return
			end
			if seg % 2 == 1 then
				return
			end
			
			local MAX = module.db.timeToKill[seg][1]
			local MIN_time = module.db.timeToKill[seg][2]
			
			if MIN_time == 0 or MIN_time == ctime_ or MAX == 0 then
				self.killTime:SetText(NumToTime(600))
			else
				local perSec = (MAX - now) / (ctime_ - MIN_time)
				if perSec == 0 then
					self.killTime:SetText(NumToTime(600))
					return
				end
				local diff = now / perSec
				self.killTime:SetText(NumToTime(diff))
			end
		end
	end
end