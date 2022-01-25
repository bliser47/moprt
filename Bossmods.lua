local GlobalAddonName, ExRT = ...

local UnitAura, UnitIsDeadOrGhost, UnitIsConnected, UnitPower, UnitGUID, UnitName = UnitAura, UnitIsDeadOrGhost, UnitIsConnected, UnitPower, UnitGUID, UnitName
local GetTime, tonumber, tostring = GetTime, tonumber, tostring
local cos, sin, sqrt, acos, abs, floor, min, max, GGetPlayerMapPosition, GetPlayerFacing, GetNumGroupMembers = math.cos, math.sin, math.sqrt, acos, math.abs, math.floor, math.min, math.max, GetPlayerMapPosition, GetPlayerFacing, GetNumGroupMembers
local ClassColorNum, SetMapToCurrentZone, GetCurrentMapAreaID, GetCurrentMapDungeonLevel, GetRaidRosterInfo = ExRT.mds.classColorNum, SetMapToCurrentZone, GetCurrentMapAreaID, GetCurrentMapDungeonLevel, GetRaidRosterInfo
local sort, wipe, PI = table.sort, table.wipe, PI

local VExRT = nil

local module = ExRT.mod:New("Bossmods",ExRT.L.bossmods)
-----------------------------------------
-- functions
-----------------------------------------

local function RaidRank()
	local n = UnitInRaid("player") or 0
	local name,rank = GetRaidRosterInfo(n)
	if name then
		return rank
	end
	return 0
end

local GetPlayerMapPosition
do
	local currentMap = 0
	local currentMapLevel = 0
	function GetPlayerMapPosition(...)
		local nowMap = GetCurrentMapAreaID()
		local nowMapLevel = GetCurrentMapDungeonLevel()
		if currentMap ~= nowMap or currentMapLevel ~= nowMapLevel then
			SetMapToCurrentZone()
			currentMap = GetCurrentMapAreaID()
			currentMapLevel = GetCurrentMapDungeonLevel()
		end
		return GGetPlayerMapPosition(...)
	end
end

-----------------------------------------
-- Ра-ден
-----------------------------------------
local RaDen = {}
RaDen.mainframe = nil
RaDen.party = nil
RaDen.unstableVita_id1 = 138308
RaDen.unstableVita_id2 = 138297
RaDen.vitaSensitivity_id = 138372

function RaDen:RefreshAll()
	local n = GetNumGroupMembers() or 0
	if n > 0 then
		local grps = {0,0,0,0}
		for j=1,n do
			local name,_,subgroup = GetRaidRosterInfo(j)
			if name and subgroup == 2 then
				grps[1] = grps[1] + 1
				RaDen.party[1][grps[1]] = name
			elseif name and subgroup == 4 then
				grps[2] = grps[2] + 1
				RaDen.party[2][grps[2]] = name
			elseif name and subgroup == 3 then
				grps[3] = grps[3] + 1
				RaDen.party[3][grps[3]] = name
			elseif name and subgroup == 5 then
				grps[4] = grps[4] + 1
				RaDen.party[4][grps[4]] = name
			end
		end
		for i=1,4 do
			for j=(grps[i]+1),5 do
				RaDen.party[i][j] = ""
			end
			sort(RaDen.party[i])
			for j=1,5 do
				RaDen.mainframe.names[(i-1)*5+j].text:SetText(RaDen.party[i][j])
			end
		end
	end
end

function RaDen:timerfunc(elapsed)
	self.tmr = self.tmr + elapsed
	if self.tmr > 0.2 then
		self.tmr = 0
		for i=1,4 do
			for j=1,5 do
				if RaDen.party[i][j] and RaDen.party[i][j] ~= "" then
					local white = true
					for k=1,40 do
						local _,_,_,_,_,duration,expires,_,_,_,spellId = UnitAura(RaDen.party[i][j],k,"HARMFUL")
						if spellId == RaDen.unstableVita_id1 or spellId == RaDen.unstableVita_id2 then
							RaDen.mainframe.names[(i-1)*5+j].text:SetTextColor(0.5, 1, 0.5, 1)
							white = nil
						elseif spellId == RaDen.vitaSensitivity_id then
							RaDen.mainframe.names[(i-1)*5+j].text:SetTextColor(1, 0.5, 0.5, 1)
							white = nil
						elseif not spellId then 
							break
						end
					end
					if white then
						RaDen.mainframe.names[(i-1)*5+j].text:SetTextColor(1, 1, 1, 1)
					end
					if UnitIsDeadOrGhost(RaDen.party[i][j]) or not UnitIsConnected(RaDen.party[i][j]) then
						RaDen.mainframe.names[(i-1)*5+j].text:SetTextColor(1, 0.5, 0.5, 1)
					end
				else
					RaDen.mainframe.names[(i-1)*5+j].text:SetTextColor(0.1, 0.1, 0.1, 1)
				end
			end
		end
	end
end

function RaDen:EventHandler(event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _,event_n,_,_,_,_,_,_,_,_,_,spellId = ...
		if event_n == "SPELL_AURA_APPLIED" and (spellId == RaDen.unstableVita_id1 or spellId == RaDen.unstableVita_id2) then
			RaDen.mainframe.vitacooldown.cooldown:SetCooldown(GetTime(), 5)
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		RaDen:RefreshAll()
	end
end

function RaDen:Load()
	if not RaDen.mainframe then
		RaDen.mainframe = CreateFrame("Frame","ExRTBossmodsRaden",UIParent)
		RaDen.mainframe:SetHeight(130)
		RaDen.mainframe:SetWidth(160)
		if VExRT.Bossmods.RaDenLeft and VExRT.Bossmods.RaDenTop then
			RaDen.mainframe:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Bossmods.RaDenLeft,VExRT.Bossmods.RaDenTop)
		else
			RaDen.mainframe:SetPoint("TOP",UIParent, "TOP", 0, 0)
		end
		RaDen.mainframe:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 8})
		RaDen.mainframe:SetBackdropColor(0.05,0.05,0.05,0.85)
		RaDen.mainframe:SetBackdropBorderColor(0.2,0.2,0.2,0.4)
		RaDen.mainframe:EnableMouse(true)
		RaDen.mainframe:SetMovable(true)
		RaDen.mainframe:RegisterForDrag("LeftButton")
		RaDen.mainframe:SetScript("OnDragStart", function(self)
			if self:IsMovable() then
				self:StartMoving()
			end
		end)
		RaDen.mainframe:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			VExRT.Bossmods.RaDenLeft = self:GetLeft()
			VExRT.Bossmods.RaDenTop = self:GetTop()
		end)
		if VExRT.Bossmods.Alpha then RaDen.mainframe:SetAlpha(VExRT.Bossmods.Alpha/100) end
		if VExRT.Bossmods.Scale then RaDen.mainframe:SetScale(VExRT.Bossmods.Scale/100) end
		
		RaDen.mainframe.tmr = 0

		RaDen.mainframe.names = {}

		for i=1,20 do
			RaDen.mainframe.names[i]=CreateFrame("Frame",nil,RaDen.mainframe)
			RaDen.mainframe.names[i]:SetSize(80,12)
			RaDen.mainframe.names[i]:SetPoint("TOPLEFT", (math.floor((i-1)/10))*80, -(((i-1)%10)*12)-5)
			RaDen.mainframe.names[i].text = RaDen.mainframe.names[i]:CreateFontString(nil,"ARTWORK")
			RaDen.mainframe.names[i].text:SetJustifyH("CENTER")
			RaDen.mainframe.names[i].text:SetFont(ExRT.mds.defFont, 12,"OUTLINE")
			local b = GetNumGuildMembers()
			local a
			if b == 0 then 
				a = UnitName("player")
			else 
				a = GetGuildRosterInfo(math.random(1,b)) 
			end
			RaDen.mainframe.names[i].text:SetText(a)
			if i%3==0 then RaDen.mainframe.names[i].text:SetTextColor(1, 0.5, 0.5, 1) end
			if i%3==1 then RaDen.mainframe.names[i].text:SetTextColor(0.5, 1, 0.5, 1) end
			if i%3==2 then RaDen.mainframe.names[i].text:SetTextColor(1, 1, 1, 1) end
			RaDen.mainframe.names[i].text:SetAllPoints()
		end

		RaDen.mainframe.vitacooldown = CreateFrame("Frame",nil,RaDen.mainframe)
		RaDen.mainframe.vitacooldown:SetHeight(32)
		RaDen.mainframe.vitacooldown:SetWidth(32)
		RaDen.mainframe.vitacooldown:SetPoint("TOPLEFT", 0, -130)
		RaDen.mainframe.vitacooldown.tex = RaDen.mainframe.vitacooldown:CreateTexture(nil, "BACKGROUND")
		local tx = GetSpellTexture(RaDen.unstableVita_id2)
		RaDen.mainframe.vitacooldown.tex:SetTexture(tx)
		RaDen.mainframe.vitacooldown.tex:SetAllPoints()
		RaDen.mainframe.vitacooldown.cooldown = CreateFrame("Cooldown", nil, RaDen.mainframe.vitacooldown)
		RaDen.mainframe.vitacooldown.cooldown:SetAllPoints()

		RaDen.party = {}
		for i=1,4 do RaDen.party[i]={} end
		RaDen:RefreshAll()

		RaDen.mainframe:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
		RaDen.mainframe:RegisterEvent("GROUP_ROSTER_UPDATE")
		RaDen.mainframe:SetScript("OnUpdate", RaDen.timerfunc)
		RaDen.mainframe:SetScript("OnEvent", RaDen.EventHandler)

		print(ExRT.L.bossmodsradenhelp)
	end
end

-----------------------------------------
-- Sha of Pride
-----------------------------------------
local ShaOfPride = {}
ShaOfPride.mainframe = nil
ShaOfPride.raid = {}
ShaOfPride.norushen = nil

function ShaOfPride:SetTextColor(j,c_r,c_g,c_b,c_a)
	ShaOfPride.mainframe.names[j].text:SetTextColor(c_r, c_g, c_b, c_a)
	ShaOfPride.mainframe.names[j].textr:SetTextColor(c_r, c_g, c_b, c_a)
end

function ShaOfPride:timerfunc(elapsed)
	self.tmr = self.tmr + elapsed
	if self.tmr > 0.3 then
		self.tmr = 0
		for j=1,#ShaOfPride.raid do
			ShaOfPride.raid[j][2] = UnitPower(ShaOfPride.raid[j][1],10)
			if ShaOfPride.raid[j][2] == nil then ShaOfPride.raid[j][2] = 0 end
		end
		sort(ShaOfPride.raid,function(a,b) if(a[2]==b[2]) then return a[1] < b[1] else return a[2] > b[2] end end)
		for j=1,#ShaOfPride.raid do
			ShaOfPride.mainframe.names[j].text:SetText(ShaOfPride.raid[j][1])
			ShaOfPride.mainframe.names[j].textr:SetText(ShaOfPride.raid[j][2])
			if ShaOfPride.norushen == 1 then
				if ShaOfPride.raid[j][2]>=100 then ShaOfPride:SetTextColor(j, 1, 0.3, 0.3, 1)
					elseif ShaOfPride.raid[j][2]>=75 then ShaOfPride:SetTextColor(j, 1, 1, 0.2, 1)
					else ShaOfPride:SetTextColor(j, 1, 1, 1, 1) end
				for i=1,40 do
					local _,_,_,_,_,_,_,_,_,_,spellId = UnitAura(ShaOfPride.raid[j][1], i,"HARMFUL")
					if spellId == 144851 or spellId == 144849 or spellId == 144850 then ShaOfPride:SetTextColor(j, 0.5, 1, 0.3, 1) break
						elseif spellId == nil then break end
				end
			elseif ShaOfPride.norushen == 2 then
				if ShaOfPride.raid[j][2]>=100 then ShaOfPride:SetTextColor(j, 0.8, 0.3, 0.8, 1)
					elseif ShaOfPride.raid[j][2]>=75 then ShaOfPride:SetTextColor(j, 0.5, 0.5, 1, 1)
					elseif ShaOfPride.raid[j][2]>=50 then ShaOfPride:SetTextColor(j, 1, 0.3, 0.3, 1)
					elseif ShaOfPride.raid[j][2]>=25 then ShaOfPride:SetTextColor(j, 1, 1, 0.2, 1)
					else ShaOfPride:SetTextColor(j, 1, 1, 1, 1) end
			else
				ShaOfPride:SetTextColor(j, 1, 1, 1, 1)
			end
		end
	end
end

function ShaOfPride:RefreshAll()
	local n = GetNumGroupMembers() or 0
	local gMax = ExRT.mds.GetRaidDiffMaxGroup()
	if n > 0 then
		wipe(ShaOfPride.raid)
		for j=1,n do
			local name,_,subgroup = GetRaidRosterInfo(j)
			if name and subgroup <= gMax then
				ShaOfPride.raid[#ShaOfPride.raid + 1] = {name,UnitPower(name,10)}
			end
		end
		sort(ShaOfPride.raid,function(a,b) if(a[2]==b[2]) then return a[1] < b[1] else return a[2] < b[2] end end)
		for j=1,#ShaOfPride.raid do if j<=25 then
			ShaOfPride.mainframe.names[j].text:SetText(ShaOfPride.raid[j][1].." "..tostring(ShaOfPride.raid[j][2]))
		end end
		for j=(#ShaOfPride.raid+1),25 do
			ShaOfPride.mainframe.names[j].text:SetText("")
			ShaOfPride.mainframe.names[j].textr:SetText("")
		end
	else
		for j=1,gMax*5 do
			local b = GetNumGuildMembers()
			local a
			if b == 0 then 
				a = UnitName("player")
			else 
				a = GetGuildRosterInfo(math.random(1,b)) 
			end
			local c = math.random(0,20)*5
			local h = math.random(1,3)
			if h == 3 then a = a..a..a elseif h == 2 then a = a..a end
			ShaOfPride.mainframe.names[j].text:SetText(a)
			ShaOfPride.mainframe.names[j].text:SetTextColor(0.1, 0.1, 0.1, 1)

			ShaOfPride.mainframe.names[j].textr:SetText(tostring(c))
			ShaOfPride.mainframe.names[j].textr:SetTextColor(0.1, 0.1, 0.1, 1)
		end
	end
end

function ShaOfPride:EventHandler(event, ...)
	if event == "GROUP_ROSTER_UPDATE" then
		ShaOfPride:RefreshAll()
	elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
		if not UnitGUID("boss1") then return end
		if tonumber((UnitGUID("boss1")):sub(-13, -9), 16) == 72276 then
			ShaOfPride.norushen = 1
		elseif tonumber((UnitGUID("boss1")):sub(-13, -9), 16) == 71734 then
			ShaOfPride.norushen = 2
		else
			ShaOfPride.norushen = nil
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _,event_n,_,_,_,_,_,destGUID = ...
		if event_n == "UNIT_DIED" and destGUID then
			local unitid = tonumber((destGUID):sub(-13, -9), 16)
			if unitid == 71734 then
				ExRT.mds:ExBossmodsCloseAll()
			end
		end
	end
end

function ShaOfPride:Load()
	if ShaOfPride.mainframe then 
		return 
	end
	ShaOfPride.mainframe = CreateFrame("Frame","ExRTBossmodsShaOfPride",UIParent)
	local gMax = ExRT.mds.GetRaidDiffMaxGroup()
	ShaOfPride.mainframe:SetSize(100,gMax*5*12+8)
	if VExRT.Bossmods.ShaofprideLeft and VExRT.Bossmods.ShaofprideTop then
		ShaOfPride.mainframe:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Bossmods.ShaofprideLeft,VExRT.Bossmods.ShaofprideTop)
	else
		ShaOfPride.mainframe:SetPoint("TOP",UIParent, "TOP", 0, 0)	
	end
	ShaOfPride.mainframe:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 8})
	ShaOfPride.mainframe:SetBackdropColor(0.05,0.05,0.05,0.85)
	ShaOfPride.mainframe:SetBackdropBorderColor(0.2,0.2,0.2,0.4)
	ShaOfPride.mainframe:EnableMouse(true)
	ShaOfPride.mainframe:SetMovable(true)
	ShaOfPride.mainframe:RegisterForDrag("LeftButton")
	ShaOfPride.mainframe:SetScript("OnDragStart", function(self)
		if self:IsMovable() then
			self:StartMoving()
		end
	end)
	ShaOfPride.mainframe:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		VExRT.Bossmods.ShaofprideLeft = self:GetLeft()
		VExRT.Bossmods.ShaofprideTop = self:GetTop()
	end)
	if VExRT.Bossmods.Alpha then ShaOfPride.mainframe:SetAlpha(VExRT.Bossmods.Alpha/100) end
	if VExRT.Bossmods.Scale then ShaOfPride.mainframe:SetScale(VExRT.Bossmods.Scale/100) end

	ShaOfPride.mainframe.tmr = 0

	ShaOfPride.mainframe.names = {}

	for i=1,25 do
		ShaOfPride.mainframe.names[i]=CreateFrame("Frame",nil,ShaOfPride.mainframe)
		ShaOfPride.mainframe.names[i]:SetSize(100,12)
		ShaOfPride.mainframe.names[i]:SetPoint("TOPLEFT", 0, -((i-1)*12)-4)
		ShaOfPride.mainframe.names[i].text = ExRT.lib.CreateText(ShaOfPride.mainframe.names[i],71,12,nil,4,0,nil,"TOP",ExRT.mds.defFont,12,nil,nil,1,1,1,nil,1)
		ShaOfPride.mainframe.names[i].textr = ExRT.lib.CreateText(ShaOfPride.mainframe.names[i],50,12,"TOPRIGHT",-4,0,"RIGHT","TOP",ExRT.mds.defFont,12,nil,nil,1,1,1,nil,1)
	end

	ShaOfPride:RefreshAll()
	ShaOfPride.mainframe:RegisterEvent("GROUP_ROSTER_UPDATE")
	ShaOfPride.mainframe:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	ShaOfPride.mainframe:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ShaOfPride.mainframe:SetScript("OnUpdate", ShaOfPride.timerfunc)
	ShaOfPride.mainframe:SetScript("OnEvent", ShaOfPride.EventHandler)
end

-----------------------------------------
-- Malkorok
-----------------------------------------
local Malkorok = {}
Malkorok.mainframe = nil
Malkorok.tmr = 0
Malkorok.main_coord_top_x = 0.36427
Malkorok.main_coord_top_y = 0.34581
Malkorok.main_coord_bot_x = 0.46707
Malkorok.main_coord_bot_y = 0.50000
Malkorok.unitid = 71454
Malkorok.spell = 142842
Malkorok.spell_baoe = 142861
Malkorok.baoe_num = 0
Malkorok.raid_marks_p = nil
Malkorok.raid_marks_e = nil
Malkorok.rotate = false
Malkorok.center = 90
Malkorok.pie_coord = {
	{{90,90},{90,-5},{0,36}},	--1
	{{90,90},{0,36},{-1,141}},	--2
	{{90,90},{-1,141},{90,185}},	--3
	{{90,90},{90,185},{182,144}},	--4
	{{90,90},{182,144},{185,38}},	--5
	{{90,90},{185,38},{90,-5}},	--6
}
Malkorok.pie_status = {0,0,0,0,0,0,0,0}
Malkorok.def_angle = (PI/180)*8
Malkorok.rotate_coords={tl={x=0,y=0},br={x=180/256,y=180/256}}
Malkorok.rotate_origin={x=90/256,y=90/256}
Malkorok.rotate_angle = 0
Malkorok.maps = {
	--[map]={topX,topY,botX,botY},
	[0]={0.36427,0.34581,0.46707,0.500},
	[807]={0.5157,0.4745,0.5207,0.4853},
	--[807]={0.5168,0.4767,0.5201,0.4844},
	[811]={0.4284,0.4285,0.4426,0.4478},
	[891]={0.4337,0.4589,0.4559,0.5276},
	[492]={0.7361,0.2098,0.7473,0.2264},
	[953]={0.36427,0.34581,0.46707,0.50000},
}
Malkorok.maps_t = {
	--[map]={link,topX,botX,topY,botY},
	--[map]={[MapDungeonLevel]={...},[MapDungeonLevel]={...}},
	--[807]={"Interface\\AddOns\\ExRT\\media\\Bossmods_807",0.22,0.8799,0.2037,0.9167},
	[807]={"Interface\\AddOns\\ExRT\\media\\Bossmods_807"},
	[953]={[8]={"Interface\\AddOns\\ExRT\\media\\Bossmods_953_8",0.293,0.6875,0.293,0.6875}},
}

Malkorok.maps_a = {}

function Malkorok:Danger(u)
	if u and not Malkorok.mainframe.Danger.shown then
		Malkorok.mainframe.Danger:Show() 
		Malkorok.mainframe.Danger.shown = true
		Malkorok.mainframe:SetBackdropColor(0.5,0,0,0.7)
		Malkorok.mainframe:SetBackdropBorderColor(1,0.2,0.2,0.9)
	elseif not u and Malkorok.mainframe.Danger.shown then
		Malkorok.mainframe.Danger:Hide() 
		Malkorok.mainframe.Danger.shown = nil
		Malkorok.mainframe:SetBackdropColor(0,0,0,0.5)
		Malkorok.mainframe:SetBackdropBorderColor(0.2,0.2,0.2,0.4)
	end
end

function Malkorok:PShow()
	if not Malkorok.mainframe then return end 

	Malkorok.raid_marks_e = not Malkorok.raid_marks_e
	Malkorok.raid_marks_p = UnitName("player")

	if not Malkorok.mainframe.raidMarks then
		Malkorok.mainframe.raidMarks = {}
		local mSize = 12
		for i=1,40 do
			Malkorok.mainframe.raidMarks[i] = CreateFrame("Frame",nil,Malkorok.mainframe.main)
			Malkorok.mainframe.raidMarks[i]:SetSize(mSize,mSize)
			Malkorok.mainframe.raidMarks[i]:SetPoint("TOPLEFT", 0, 0)
			Malkorok.mainframe.raidMarks[i]:SetBackdrop({bgFile = "Interface\\AddOns\\ExRT\\media\\blip.tga",tile = true,tileSize = mSize})
			Malkorok.mainframe.raidMarks[i]:SetBackdropColor(0,1,0,0.8)
			Malkorok.mainframe.raidMarks[i]:SetFrameStrata("HIGH")
			Malkorok.mainframe.raidMarks[i]:Hide()
		end
	end
	if not Malkorok.raid_marks_e then
		for i=1,40 do
			Malkorok.mainframe.raidMarks[i]:Hide()
		end
	end
end

function Malkorok:MapNow()
	if not Malkorok.mainframe then return end 
	local mapNow = GetCurrentMapAreaID()
	if not Malkorok.maps_t[mapNow] then return end 
	local mp = Malkorok.maps_t[mapNow]

	local mapNowLevel = GetCurrentMapDungeonLevel()
	if type(Malkorok.maps_t[mapNow][1]) ~= "string" then
		if not mapNowLevel or not Malkorok.maps_t[mapNow][mapNowLevel] then return end
		mp = nil
		mp = Malkorok.maps_t[mapNow][mapNowLevel]
	end

	if not Malkorok.mainframe.main.t then
		Malkorok.mainframe.main.t = Malkorok.mainframe.main:CreateTexture(nil, "BACKGROUND")
		Malkorok.mainframe.main.t:SetAllPoints()
	end

	Malkorok.mainframe.main.t:SetTexture(mp[1])
	Malkorok.mainframe.main.t.xT = mp[2] or 0
	Malkorok.mainframe.main.t.xB = mp[3] or 1
	Malkorok.mainframe.main.t.yT = mp[4] or 0
	Malkorok.mainframe.main.t.yB = mp[5] or 1
	Malkorok.mainframe.main.t.xC = (Malkorok.mainframe.main.t.xB - Malkorok.mainframe.main.t.xT) / 2 + Malkorok.mainframe.main.t.xT
	Malkorok.mainframe.main.t.yC = (Malkorok.mainframe.main.t.yB - Malkorok.mainframe.main.t.yT) / 2 + Malkorok.mainframe.main.t.yT
	Malkorok.mainframe.main.t.r = 1

	for i=1,6 do
		Malkorok.mainframe.pie[i]:Hide()
	end
	Malkorok.def_angle = 0
end

function Malkorok:Cursor()
	local x,y = GetCursorPosition()

	local x1 = Malkorok.mainframe.main:GetLeft()
	local y1 = Malkorok.mainframe.main:GetTop()

	Malkorok.mainframe_scale = Malkorok.mainframe:GetScale()
	local uiparent_scale = UIParent:GetScale()
	x1 = x1 * Malkorok.mainframe_scale*uiparent_scale
	y1 = y1 * Malkorok.mainframe_scale*uiparent_scale

	x = x - x1
	y = -(y - y1)

	x = x / (Malkorok.mainframe_scale * uiparent_scale)
	y = y / (Malkorok.mainframe_scale * uiparent_scale)

	return x,y
end

function Malkorok.RotateCoordPair(x,y,ox,oy,a,asp)
	y=y/asp
	oy=oy/asp
	return ox + (x-ox)*cos(a) - (y-oy)*sin(a),(oy + (y-oy)*cos(a) + (x-ox)*sin(a))*asp
end

function Malkorok.RotateTexture(self,angle,xT,yT,xB,yB,xC,yC,userAspect)
	local aspect = userAspect or (xT-xB)/(yT-yB)
	local g1,g2 = Malkorok.RotateCoordPair(xT,yT,xC,yC,angle,aspect)
	local g3,g4 = Malkorok.RotateCoordPair(xT,yB,xC,yC,angle,aspect)
	local g5,g6 = Malkorok.RotateCoordPair(xB,yT,xC,yC,angle,aspect)
	local g7,g8 = Malkorok.RotateCoordPair(xB,yB,xC,yC,angle,aspect)

	self:SetTexCoord(g1,g2,g3,g4,g5,g6,g7,g8)
end

do
	if Malkorok.def_angle~=0 then
		for i=1,6 do 
			for j=2,3 do
				Malkorok.pie_coord[i][j][1],Malkorok.pie_coord[i][j][2] = Malkorok.RotateCoordPair(Malkorok.pie_coord[i][j][1],Malkorok.pie_coord[i][j][2],Malkorok.pie_coord[i][1][1],Malkorok.pie_coord[i][1][2],-Malkorok.def_angle,1)
			end 
		end
	end
end

function Malkorok.def_angle_rotate()
	for i=1,6 do		
		Malkorok.RotateTexture(Malkorok.mainframe.pie[i].tex,Malkorok.def_angle,Malkorok.rotate_coords.tl.x,Malkorok.rotate_coords.tl.y,Malkorok.rotate_coords.br.x,Malkorok.rotate_coords.br.y,Malkorok.rotate_origin.x,Malkorok.rotate_origin.y)
	end
end

function Malkorok:findpie(x0,y0,pxy)
	for i=1,6 do
		local x1,y1 = Malkorok.pie_coord[i][1][1],Malkorok.pie_coord[i][1][2]
		local x2,y2 = Malkorok.pie_coord[i][2][1],Malkorok.pie_coord[i][2][2]
		local x3,y3 = Malkorok.pie_coord[i][3][1],Malkorok.pie_coord[i][3][2]
		if Malkorok.rotate == true and pxy == 1 then
			x2,y2= Malkorok.RotateCoordPair(x2,y2,Malkorok.center,Malkorok.center,-Malkorok.rotate_angle+Malkorok.def_angle,1)
			x3,y3= Malkorok.RotateCoordPair(x3,y3,Malkorok.center,Malkorok.center,-Malkorok.rotate_angle+Malkorok.def_angle,1)
		end

		local r1 = (x1 - x0) * (y2 - y1) - (x2 - x1) * (y1 - y0)
		local r2 = (x2 - x0) * (y3 - y2) - (x3 - x2) * (y2 - y0)
		local r3 = (x3 - x0) * (y1 - y3) - (x1 - x3) * (y3 - y0)

		if (r1>=0 and r2>=0 and r3>=0) or (r1<=0 and r2<=0 and r3<=0) then 
			return i 
		end
	end
	return 0
end

do
	local timerElapsed = 0
	function Malkorok:timerfunc(elapsed)
		timerElapsed = timerElapsed + elapsed
		if timerElapsed > 0.05 then
			timerElapsed = 0
			local px, py = GetPlayerMapPosition("player")
			if px == 0 and py == 0 and not Malkorok.raid_marks_e then return end
			if px >= Malkorok.main_coord_top_x and px<=Malkorok.main_coord_bot_x and py>=Malkorok.main_coord_top_y and py<=Malkorok.main_coord_bot_y then
				if not Malkorok.mainframe.Player.shown then 
					Malkorok.mainframe.Player.shown = 1 
					Malkorok.mainframe.Player:Show() 
				end
				local px1 = (px-Malkorok.main_coord_top_x)/(Malkorok.main_coord_bot_x-Malkorok.main_coord_top_x)*180
				local py1 = (py-Malkorok.main_coord_top_y)/(Malkorok.main_coord_bot_y-Malkorok.main_coord_top_y)*180
	
				local numpie = Malkorok:findpie(px1,py1)
				
				if not Malkorok.rotate then
					Malkorok.mainframe.Player:SetPoint("TOPLEFT", px1 / Malkorok.mainframe.Player.scale -15, -py1 / Malkorok.mainframe.Player.scale +20)
					Malkorok.RotateTexture(Malkorok.mainframe.Player.Texture,GetPlayerFacing(),0,0,1,1,15/32,20/32)
					if Malkorok.mainframe.main.t and Malkorok.mainframe.main.t.r then
						Malkorok.mainframe.main.t:SetTexCoord(Malkorok.mainframe.main.t.xT,Malkorok.mainframe.main.t.xB,Malkorok.mainframe.main.t.yT,Malkorok.mainframe.main.t.yB)
						Malkorok.mainframe.main.t.r = nil
					end
				else
					local h1,h2,h3 = sqrt( (Malkorok.center-px1)^2 + (180-py1)^2 ),sqrt( (Malkorok.center-Malkorok.center)^2 + (180-Malkorok.center)^2 ),sqrt( (Malkorok.center-px1)^2 + (Malkorok.center-py1)^2 )
					local h4 = (h2^2+h3^2-h1^2)/(2*h2*h3)
	
					h4 = acos(h4)
					if px1<Malkorok.center then h4=360-h4 end
					h4 = -h4
					Malkorok.rotate_angle=PI/180*h4 + Malkorok.def_angle
	
					Malkorok.RotateTexture(Malkorok.mainframe.Player.Texture,Malkorok.rotate_angle+GetPlayerFacing()-Malkorok.def_angle,0,0,1,1,15/32,20/32)
					Malkorok.mainframe.Player:SetPoint("TOPLEFT", Malkorok.center / Malkorok.mainframe.Player.scale - 15, (-Malkorok.center - h3)/ Malkorok.mainframe.Player.scale +20)
	
					for i=1,6 do	
						Malkorok.RotateTexture(Malkorok.mainframe.pie[i].tex,Malkorok.rotate_angle,Malkorok.rotate_coords.tl.x,Malkorok.rotate_coords.tl.y,Malkorok.rotate_coords.br.x,Malkorok.rotate_coords.br.y,Malkorok.rotate_origin.x,Malkorok.rotate_origin.y)
					end
	
					if Malkorok.mainframe.main.t then
						Malkorok.RotateTexture(Malkorok.mainframe.main.t,Malkorok.rotate_angle,Malkorok.mainframe.main.t.xT,Malkorok.mainframe.main.t.yT,Malkorok.mainframe.main.t.xB,Malkorok.mainframe.main.t.yB,Malkorok.mainframe.main.t.xC,Malkorok.mainframe.main.t.yC,1)
						Malkorok.mainframe.main.t.r = 1
					end
				end
	
				if not Malkorok.mainframe.main.t then
					if numpie>0 and Malkorok.pie_status[numpie] == 1 then 
						Malkorok:Danger(1)
					elseif numpie==0 or Malkorok.pie_status[numpie] == 0 then
						Malkorok:Danger()
					end
				else
					if Malkorok.maps_a[floor(py1)+1] and Malkorok.maps_a[floor(py1)+1][floor(px1)+1] == 1 then Malkorok:Danger(1) else Malkorok:Danger() end
				end
			else
				if Malkorok.mainframe.Player.shown then 
					Malkorok.mainframe.Player.shown = nil 
					Malkorok.mainframe.Player:Hide() 
				end
				if Malkorok.rotate then
					for i=1,6 do
						Malkorok.mainframe.pie[i].tex:SetTexCoord(0,180/256,0,180/256)
					end	
					Malkorok.rotate_angle = 0
					if Malkorok.def_angle~=0 then Malkorok.def_angle_rotate() end
				end
				Malkorok:Danger()		
			end
	
			local n = GetNumGroupMembers() or 0
			if n > 0 and Malkorok.raid_marks_e then
				for j=1,n do
					local name, _,subgroup,_,_,class = GetRaidRosterInfo(j)
					if name and subgroup <= 5 and not UnitIsDeadOrGhost(name) and UnitIsConnected(name) and name ~= Malkorok.raid_marks_p then
						local px, py = GetPlayerMapPosition(name)
	
						if px >= Malkorok.main_coord_top_x and px<=Malkorok.main_coord_bot_x and py>=Malkorok.main_coord_top_y and py<=Malkorok.main_coord_bot_y then
							local px1 = (px-Malkorok.main_coord_top_x)/(Malkorok.main_coord_bot_x-Malkorok.main_coord_top_x)*180
							local py1 = (py-Malkorok.main_coord_top_y)/(Malkorok.main_coord_bot_y-Malkorok.main_coord_top_y)*180
	
							if Malkorok.rotate then
								px1,py1 = Malkorok.RotateCoordPair(px1,py1,Malkorok.center,Malkorok.center,-Malkorok.rotate_angle+Malkorok.def_angle,1)
							end
				
							local cR,cG,cB = ClassColorNum(class)
							Malkorok.mainframe.raidMarks[j]:SetBackdropColor(cR,cG,cB,1)
							Malkorok.mainframe.raidMarks[j]:SetPoint("TOPLEFT", px1 - 8, -py1 + 8)
							Malkorok.mainframe.raidMarks[j]:Show()
						else
							Malkorok.mainframe.raidMarks[j]:Hide()
						end
					else
						if Malkorok.mainframe.raidMarks[j] then Malkorok.mainframe.raidMarks[j]:Hide() end
					end
				end
			end
		end
	end
end

function Malkorok:EventHandler(event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _,event_n,_,_,_,_,_,destGUID,_,_,_,spellId = ...
		if event_n == "SPELL_CAST_SUCCESS" and spellId == Malkorok.spell then
			for i=1,6 do  
				Malkorok.pie_status[i]=0
				Malkorok.mainframe.pie[i].tex:SetVertexColor(0,1,0,0.8)
			end
			if Malkorok.baoe_num == 0 then 
				Malkorok.mainframe.aoecd.cooldown:SetCooldown(GetTime(), 60)
				Malkorok.baoe_num = 1
			else
				Malkorok.baoe_num = 0
			end
		elseif event_n == "SPELL_CAST_SUCCESS" and spellId == Malkorok.spell_baoe then
			Malkorok.baoe_num = 0
			Malkorok.mainframe.aoecd.cooldown:SetCooldown(GetTime(), 64)
			for i=1,6 do  
				Malkorok.pie_status[i]=0
				Malkorok.mainframe.pie[i].tex:SetVertexColor(0,1,0,0.8)
			end
		elseif event_n == "UNIT_DIED" and destGUID then
			local unitid = tonumber((destGUID):sub(-13, -9), 16)
			if unitid == Malkorok.unitid then
				ExRT.mds:ExBossmodsCloseAll()
			end
		end
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		SetMapToCurrentZone()
		local cmap = GetCurrentMapAreaID()
		if not Malkorok.maps[cmap] then cmap = 0 end
		Malkorok.main_coord_top_x = Malkorok.maps[cmap][1]
		Malkorok.main_coord_top_y = Malkorok.maps[cmap][2]
		Malkorok.main_coord_bot_x = Malkorok.maps[cmap][3]
		Malkorok.main_coord_bot_y = Malkorok.maps[cmap][4]	
	end
end


function module:addonMessage(sender, prefix, ...)
	if not Malkorok.mainframe then return end 
	if prefix == "malkorok" then
		local pienum,piecol = ...
		if not tonumber(pienum) or tonumber(pienum) == 0 then return end 
		pienum = tonumber(pienum)
		if pienum > 6 then return end
		if Malkorok.pie_status[pienum] == 0 and piecol == "R" then
			Malkorok.pie_status[pienum]=1
			Malkorok.mainframe.pie[pienum].tex:SetVertexColor(1,0,0,0.8)
		elseif Malkorok.pie_status[pienum] == 1 and piecol == "G" then
			Malkorok.pie_status[pienum]=0
			Malkorok.mainframe.pie[pienum].tex:SetVertexColor(0,1,0,0.8)
		end
	end
end


function Malkorok:Load()
	if Malkorok.mainframe then return end
	Malkorok.mainframe = CreateFrame("Frame","ExRTBossmodsMalkorok",UIParent)
	Malkorok.mainframe:SetSize(200,200)
	if VExRT.Bossmods.MalkorokLeft and VExRT.Bossmods.MalkorokTop then
		Malkorok.mainframe:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Bossmods.MalkorokLeft,VExRT.Bossmods.MalkorokTop)
	else
		Malkorok.mainframe:SetPoint("TOP",UIParent, "TOP", 0, 0)
	end
	Malkorok.mainframe:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 8})
	Malkorok.mainframe:SetBackdropColor(0,0,0,0.5)
	Malkorok.mainframe:SetBackdropBorderColor(0.2,0.2,0.2,0.4)
	Malkorok.mainframe:EnableMouse(true)
	Malkorok.mainframe:SetMovable(true)
	Malkorok.mainframe:RegisterForDrag("LeftButton")
	Malkorok.mainframe:SetScript("OnDragStart", function(self)
		if self:IsMovable() then
			self:StartMoving()
		end
	end)

	Malkorok.mainframe:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		VExRT.Bossmods.MalkorokLeft = self:GetLeft()
		VExRT.Bossmods.MalkorokTop = self:GetTop()
	end)
	if VExRT.Bossmods.Alpha then Malkorok.mainframe:SetAlpha(VExRT.Bossmods.Alpha/100) end
	if VExRT.Bossmods.Scale then Malkorok.mainframe:SetScale(VExRT.Bossmods.Scale/100) end

	Malkorok.mainframe.main = CreateFrame("Frame",nil,Malkorok.mainframe)
	Malkorok.mainframe.main:SetSize(180,180)
	Malkorok.mainframe.main:SetPoint("TOPLEFT",10, -10)

	Malkorok.mainframe.pie = {}
	for i=1,6 do 
		Malkorok.mainframe.pie[i] = CreateFrame("Frame",nil,Malkorok.mainframe.main)
		Malkorok.mainframe.pie[i]:SetSize(180,180)
		Malkorok.mainframe.pie[i]:SetPoint("TOPLEFT", 0, 0)

		Malkorok.mainframe.pie[i].tex = Malkorok.mainframe.pie[i]:CreateTexture(nil, "BACKGROUND")
		Malkorok.mainframe.pie[i].tex:SetTexture("Interface\\AddOns\\ExRT\\media\\Pie"..i)
		Malkorok.mainframe.pie[i].tex:SetAllPoints()
		Malkorok.mainframe.pie[i].tex:SetTexCoord(0,180/256,0,180/256)
		Malkorok.mainframe.pie[i].tex:SetVertexColor(0,1,0,0.8)
		Malkorok.pie_status[i]=0
	end

	Malkorok.mainframe:SetScript("OnMouseDown", function(self,button)
		local j1,j2 = Malkorok:Cursor()

		if j1 < 6 and j2 < 6 then
			if not VExRT.Bossmods.MalkorokLock then
				Malkorok.mainframe.Lock.texture:SetTexture("Interface\\AddOns\\ExRT\\media\\lock.tga")
				Malkorok.mainframe:SetMovable(false)
				VExRT.Bossmods.MalkorokLock = true
			else
				Malkorok.mainframe.Lock.texture:SetTexture("Interface\\AddOns\\ExRT\\media\\un_lock.tga")
				Malkorok.mainframe:SetMovable(true)
				VExRT.Bossmods.MalkorokLock = nil
			end
		elseif j1 < 22 and j2 < 6 then
			if Malkorok.rotate then
				VExRT.Bossmods.MalkorokRotate = nil
				Malkorok.rotate = nil
				for i=1,6 do
					Malkorok.mainframe.pie[i].tex:SetTexCoord(0,180/256,0,180/256)
				end
				Malkorok.rotate_angle = 0
				if Malkorok.def_angle~=0 then Malkorok.def_angle_rotate() end	
			else
				VExRT.Bossmods.MalkorokRotate = true
				Malkorok.rotate = true
			end
		elseif j1 < 8 and j2 > 170 then
			VExRT.Bossmods.MalkorokIconHide = not VExRT.Bossmods.MalkorokIconHide
			if VExRT.Bossmods.MalkorokIconHide then
				Malkorok.mainframe.aoecd:Hide()
			else
				Malkorok.mainframe.aoecd:Show()
			end
		end	

		local numpie = Malkorok:findpie(j1,j2,1)
		if numpie>0 then
			if button == "LeftButton" then
				Malkorok.pie_status[numpie]=1
				Malkorok.mainframe.pie[numpie].tex:SetVertexColor(1,0,0,0.8)
			elseif button == "RightButton" then
				Malkorok.pie_status[numpie]=0
				Malkorok.mainframe.pie[numpie].tex:SetVertexColor(0,1,0,0.8)
			end
			local col = "R"
			if button == "RightButton" then col = "G" end
			if RaidRank()>0 then 
				ExRT.mds.SendExMsg("malkorok",tostring(numpie).."\t"..col) 
				ExRT.mds.SendExMsg("malkorok",tostring(numpie).."\t"..col,nil,nil,"MHADD")
			end
		end
	end)
	
	Malkorok.mainframe.Player = CreateFrame("Frame",nil,Malkorok.mainframe.main)
	Malkorok.mainframe.Player:SetSize(32,32)
	Malkorok.mainframe.Player.Texture =Malkorok.mainframe.Player:CreateTexture(nil, "ARTWORK")
	Malkorok.mainframe.Player.Texture:SetSize(32,32)
	Malkorok.mainframe.Player.Texture:SetPoint("TOPLEFT",0,0)
	Malkorok.mainframe.Player.Texture:SetTexture("Interface\\MINIMAP\\MinimapArrow")
	Malkorok.mainframe.Player.scale = 1
	Malkorok.mainframe.Player:SetScale(Malkorok.mainframe.Player.scale)

	Malkorok.mainframe.Danger = ExRT.lib.CreateText(Malkorok.mainframe,200,18,"TOP",0,15,"CENTER","TOP",ExRT.mds.defFont,18,ExRT.L.bossmodsmalkorokdanger,nil,1,0.2,0.2,nil,1)
	Malkorok.mainframe.Danger:Hide()

	Malkorok.mainframe.Lock = ExRT.lib.CreateIcon(nil,Malkorok.mainframe,14,nil,2,-1,"Interface\\AddOns\\ExRT\\media\\un_lock.tga")
	if VExRT.Bossmods.MalkorokLock then 
		Malkorok.mainframe.Lock.texture:SetTexture("Interface\\AddOns\\ExRT\\media\\lock.tga")
		Malkorok.mainframe:SetMovable(false)
	end

	Malkorok.mainframe.Rotate = ExRT.lib.CreateIcon(nil,Malkorok.mainframe,14,nil,18,-1,"Interface\\AddOns\\ExRT\\media\\icon-config.tga")
	Malkorok.mainframe.Rotate.texture:SetVertexColor(0.6,0.6,0.6,0.8)
	if VExRT.Bossmods.MalkorokRotate then 
		Malkorok.rotate = true
	else
		if Malkorok.def_angle~=0 then Malkorok.def_angle_rotate() end
	end

	Malkorok.mainframe.aoecd = ExRT.lib.CreateIcon(nil,Malkorok.mainframe,32,"BOTTOMLEFT",2,1,nil)
	Malkorok.mainframe.aoecd.texture:SetTexture("Interface\\Icons\\Spell_Shadow_Shadesofdarkness")
	Malkorok.mainframe.aoecd.cooldown = CreateFrame("Cooldown", nil, Malkorok.mainframe.aoecd)
	Malkorok.mainframe.aoecd.cooldown:SetAllPoints()
	if VExRT.Bossmods.MalkorokIconHide then
		Malkorok.mainframe.aoecd:Hide()
	end

	Malkorok.mainframe:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
	Malkorok.mainframe:RegisterEvent("ZONE_CHANGED_NEW_AREA") 
	Malkorok.mainframe:SetScript("OnUpdate", Malkorok.timerfunc)
	Malkorok.mainframe:SetScript("OnEvent", Malkorok.EventHandler)

	print(ExRT.L.bossmodsmalkorokhelp)

	SetMapToCurrentZone()
	if Malkorok.maps[GetCurrentMapAreaID()] then
		Malkorok.main_coord_top_x = Malkorok.maps[GetCurrentMapAreaID()][1]
		Malkorok.main_coord_top_y = Malkorok.maps[GetCurrentMapAreaID()][2]
		Malkorok.main_coord_bot_x = Malkorok.maps[GetCurrentMapAreaID()][3]
		Malkorok.main_coord_bot_y = Malkorok.maps[GetCurrentMapAreaID()][4]
	end
end

-----------------------------------------
-- Malkorok AI
-----------------------------------------
local MalkorokAI = {}
MalkorokAI.mainframe = nil
MalkorokAI.pie = {0,0,0,0,0,0}
MalkorokAI.pie_raid = {}
MalkorokAI.pie_yellow = 0
MalkorokAI.tmr = 0
MalkorokAI.tmr2 = 0
MalkorokAI.spell_aoe = 143805

function MalkorokAI:timerfunc2(elapsed)
	MalkorokAI.tmr2 = MalkorokAI.tmr2 + elapsed
	if MalkorokAI.tmr2 > 5 then
		for i=1,6 do 
			if MalkorokAI.pie[i] == 1 and Malkorok.pie_status[i]==1 then
				Malkorok.mainframe.pie[i].tex:SetVertexColor(1,0,0,0.8)
			end
			MalkorokAI.pie[i] = 0
		end
		MalkorokAI.mainframe:SetScript("OnUpdate", nil)
		MalkorokAI.tmr2 = 0
	end
end

function MalkorokAI:timerfunc(elapsed)
	MalkorokAI.tmr = MalkorokAI.tmr + elapsed
	if MalkorokAI.tmr > 0.5 then
		for i=1,6 do 
			if MalkorokAI.pie[i] == 1 then
				Malkorok.mainframe.pie[i].tex:SetVertexColor(1,0.8,0,0.8)
			end
		end
		MalkorokAI.mainframe:SetScript("OnUpdate", MalkorokAI.timerfunc2)
		MalkorokAI.tmr = 0
	end
end

MalkorokAI.mainframe_2 = nil
MalkorokAI.tmr_do = 0
function MalkorokAI:timerfunc_do(elapsed)
	MalkorokAI.tmr_do = MalkorokAI.tmr_do + elapsed
	if MalkorokAI.tmr_do > 4.5 then
		local n = GetNumGroupMembers() or 0
		if n > 0 then
			local gMax = ExRT.mds.GetRaidDiffMaxGroup()
			for i=1,6 do MalkorokAI.pie_raid[i]=0 end
			for j=1,n do
				local name, _,subgroup = GetRaidRosterInfo(j)
				if name and subgroup <= gMax and not UnitIsDeadOrGhost(name) then
					local px, py = GetPlayerMapPosition(name)
					if px >= Malkorok.main_coord_top_x and px<=Malkorok.main_coord_bot_x and py>=Malkorok.main_coord_top_y and py<=Malkorok.main_coord_bot_y then
						local px1 = (px-Malkorok.main_coord_top_x)/(Malkorok.main_coord_bot_x-Malkorok.main_coord_top_x)*180
						local py1 = (py-Malkorok.main_coord_top_y)/(Malkorok.main_coord_bot_y-Malkorok.main_coord_top_y)*180
				
						local numpie = Malkorok:findpie(px1,py1)

						for i_a=1,40 do
							local _,_,_,_,_,_,_,_,_,_,auraSpellId = UnitAura(name, i_a,"HELPFUL")
							if not auraSpellId then 
								break
							elseif auraSpellId == 19263 or	--Deterrence
								auraSpellId == 110696 or--Ice Block druid
								auraSpellId == 110700 or--Divine Shield druid
								auraSpellId == 45438 or	--Ice Block
								auraSpellId == 47585 or	--Dispersion
								auraSpellId == 113862 or--Greater Invisibility
								auraSpellId == 110960 or--Greater Invisibility
								auraSpellId == 1022 or	--Hand of Protection
								auraSpellId == 642 then	--Divine Shield
									numpie = 0
							end
						end
						if numpie > 0 then 
							MalkorokAI.pie_raid[numpie] = MalkorokAI.pie_raid[numpie] + 1
						end
					end
				end
			end
			local minpieam = 40
			for i=1,6 do 
				minpieam = min(minpieam,MalkorokAI.pie_raid[i])
			end
			for i=1,6 do 
				if MalkorokAI.pie_raid[i]==minpieam then
					if RaidRank()>0 then 
						ExRT.mds.SendExMsg("malkorok",tostring(i).."\tR")
						ExRT.mds.SendExMsg("malkorok",tostring(i).."\tR",nil,nil,"MHADD")
					end
					MalkorokAI.pie[i] = 1
					Malkorok.pie_status[i]=1
				end
			end
			MalkorokAI.mainframe:SetScript("OnUpdate", MalkorokAI.timerfunc)
		end
		MalkorokAI.tmr_do = 0
		self:SetScript("OnUpdate", nil)
	end
end

function MalkorokAI:EventHandler(event,_,event_n,_,_,_,_,_,_,_,_,_,spellId)
	if event_n == "SPELL_CAST_SUCCESS" and spellId == MalkorokAI.spell_aoe then
		for i=1,6 do MalkorokAI.pie[i]=0 end
		MalkorokAI.tmr_do = 0
		MalkorokAI.mainframe_2:SetScript("OnUpdate", MalkorokAI.timerfunc_do)
	end
end

function MalkorokAI:Load()
	if not Malkorok.mainframe then return end
	if MalkorokAI.mainframe then return end

	MalkorokAI.mainframe = CreateFrame("Frame","ExRTBossmodsMalkorokAI",nil)
	if not MalkorokAI.mainframe_2 then MalkorokAI.mainframe_2 = CreateFrame("Frame") end

	MalkorokAI.mainframe:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
	MalkorokAI.mainframe:SetScript("OnEvent", MalkorokAI.EventHandler)

	MalkorokAI.mainframe.text = CreateFrame("SimpleHTML", nil,Malkorok.mainframe)
	MalkorokAI.mainframe.text:SetText("AI")
	MalkorokAI.mainframe.text:SetFont(ExRT.mds.defFont, 16,"OUTLINE")
	MalkorokAI.mainframe.text:SetHeight(12)
	MalkorokAI.mainframe.text:SetWidth(12)
	MalkorokAI.mainframe.text:SetPoint("CENTER", Malkorok.mainframe,"BOTTOMRIGHT", -12,12)
	MalkorokAI.mainframe.text:SetTextColor(1, 1, 1, 1)

	print(ExRT.L.bossmodsmalkorokaihelp)
end

-----------------------------------------
-- Spoils of Pandaria
-----------------------------------------
local SpoilsOfPandaria = {}
SpoilsOfPandaria.mainframe = nil
SpoilsOfPandaria.side1 = nil
SpoilsOfPandaria.side2 = nil
SpoilsOfPandaria.tmr = 0

SpoilsOfPandaria.tmp_point_b_x = 0.4153
SpoilsOfPandaria.tmp_point_b_y = 0.4013
SpoilsOfPandaria.tmp_point_t_x = 0.6516
SpoilsOfPandaria.tmp_point_t_y = 0.1602
SpoilsOfPandaria.tmp_point_tg = abs(( SpoilsOfPandaria.tmp_point_t_y-SpoilsOfPandaria.tmp_point_b_y ) / ( SpoilsOfPandaria.tmp_point_b_x-SpoilsOfPandaria.tmp_point_t_x ))

function SpoilsOfPandaria.findroom(px,py)
	if px < SpoilsOfPandaria.tmp_point_b_x or px > SpoilsOfPandaria.tmp_point_t_x or py < SpoilsOfPandaria.tmp_point_t_y or py > SpoilsOfPandaria.tmp_point_b_y then return 0 end

	local tg_1 = abs( SpoilsOfPandaria.tmp_point_b_x-px )
	local tg_2 = SpoilsOfPandaria.tmp_point_tg * tg_1
	local tg_y = SpoilsOfPandaria.tmp_point_b_y - tg_2

	if tg_y > py then return 1 else return 2 end
end

SpoilsOfPandaria.point_subRoom_b_x = 0.5633
SpoilsOfPandaria.point_subRoom_b_y = 0.3701
SpoilsOfPandaria.point_subRoom_t_x = 0.4885
SpoilsOfPandaria.point_subRoom_t_y = 0.1993
function SpoilsOfPandaria.findroom2(x0,y0)
	local side = (SpoilsOfPandaria.tmp_point_b_x - x0) * (SpoilsOfPandaria.tmp_point_t_y - SpoilsOfPandaria.tmp_point_b_y) - (SpoilsOfPandaria.tmp_point_t_x - SpoilsOfPandaria.tmp_point_b_x) * (SpoilsOfPandaria.tmp_point_b_y - y0)
	if side < 0 then --TOP side
		side = -1
	else
		side = 1
	end
	local subRoom = (SpoilsOfPandaria.point_subRoom_b_x - x0) * (SpoilsOfPandaria.point_subRoom_t_y - SpoilsOfPandaria.point_subRoom_b_y) - (SpoilsOfPandaria.point_subRoom_t_x - SpoilsOfPandaria.point_subRoom_b_x) * (SpoilsOfPandaria.point_subRoom_b_y - y0)
	if subRoom < 0 then --LEFT room
		subRoom = 1
	else
		subRoom = 2
	end
	local room = side * subRoom
	if room < 0 then
		return room + 3
	else
		return room + 2
	end
	-- 1: TOP Mogu
	-- 2: TOP Klaxxi
	-- 3: BOTTOM: Klaxxi
	-- 4: BOTTOM: Mogu
end

function SpoilsOfPandaria:timerfunc(elapsed)
	SpoilsOfPandaria.tmr = SpoilsOfPandaria.tmr + elapsed
	if SpoilsOfPandaria.tmr > 1 then
		SpoilsOfPandaria.tmr = 0
		local o = {[1]=-1,[2]=-1,[0]=-1}
		local n = GetNumGroupMembers() or 0
		if n > 0 then
			for j=1,n do
				local name,_,subgroup = GetRaidRosterInfo(j)
				if name and subgroup <= 5 and UnitIsDeadOrGhost(name) ~= 1 and UnitIsConnected(name) then
					local px, py = GetPlayerMapPosition(name)
					local pr = SpoilsOfPandaria.findroom(px,py)
					if o[pr] < UnitPower(name,10) then
						o[pr] = UnitPower(name,10)
					end
				end
			end
			for j=1,2 do
				SpoilsOfPandaria.mainframe.side[j].pts = o[j]
				if o[j]==-1 then 
					SpoilsOfPandaria.mainframe.side[j].text:SetText("?") 
				else 
					SpoilsOfPandaria.mainframe.side[j].text:SetText(SpoilsOfPandaria.mainframe.side[j].pts) 
				end
			end
		else
			for j=1,2 do
				SpoilsOfPandaria.mainframe.side[j].text:SetText("?")
				SpoilsOfPandaria.mainframe.side[j].pts = 0
			end
		end
	end
end

SpoilsOfPandaria.roomNames = {
	ExRT.L.BossmodsSpoilsofPandariaMogu,
	ExRT.L.BossmodsSpoilsofPandariaKlaxxi,
	ExRT.L.BossmodsSpoilsofPandariaKlaxxi,
	ExRT.L.BossmodsSpoilsofPandariaMogu,
}
function SpoilsOfPandaria:onEvent(event,unitID,_,_,_,spellID)
	if spellID == 144229 then
		local name = ExRT.mds.UnitCombatlogname(unitID)
		
		if name and ExRT.mds.AntiSpam("SpoilsOfPandaria"..name,0.5) then
			local px, py = GetPlayerMapPosition(unitID)
			local room = SpoilsOfPandaria.findroom2(px, py)
			local color = ExRT.mds.classColorByGUID(UnitGUID(unitID))
			local ctime_ = ExRT.mds.GetEncounterTime() or 0
			print(format("%d:%02d",ctime_/60,ctime_%60).." |c"..color..name.."|r ".. ExRT.L.BossmodsSpoilsofPandariaOpensBox .." "..SpoilsOfPandaria.roomNames[room])
		end
	end
end

function SpoilsOfPandaria:Load()
	if SpoilsOfPandaria.mainframe then return end
	SpoilsOfPandaria.mainframe = CreateFrame("Frame","ExRTBossmodsSpoilsOfPandaria",UIParent)
	SpoilsOfPandaria.mainframe:SetSize(70,50)
	if VExRT.Bossmods.SpoilsofPandariaLeft and VExRT.Bossmods.SpoilsofPandariaTop then
		SpoilsOfPandaria.mainframe:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Bossmods.SpoilsofPandariaLeft,VExRT.Bossmods.SpoilsofPandariaTop)
	else
		SpoilsOfPandaria.mainframe:SetPoint("TOP",UIParent, "TOP", 0, 0)
	end
	SpoilsOfPandaria.mainframe:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",edgeFile = ExRT.mds.defBorder,tile = false,edgeSize = 8})
	SpoilsOfPandaria.mainframe:SetBackdropColor(0.05,0.05,0.05,0.85)
	SpoilsOfPandaria.mainframe:SetBackdropBorderColor(0.2,0.2,0.2,0.4)
	SpoilsOfPandaria.mainframe:EnableMouse(true)
	SpoilsOfPandaria.mainframe:SetMovable(true)
	SpoilsOfPandaria.mainframe:RegisterForDrag("LeftButton")
	SpoilsOfPandaria.mainframe:SetScript("OnDragStart", function(self)
		if self:IsMovable() then
			self:StartMoving()
		end
	end)
	SpoilsOfPandaria.mainframe:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		VExRT.Bossmods.SpoilsofPandariaLeft = self:GetLeft()
		VExRT.Bossmods.SpoilsofPandariaTop = self:GetTop()
	end)
	if VExRT.Bossmods.Alpha then SpoilsOfPandaria.mainframe:SetAlpha(VExRT.Bossmods.Alpha/100) end
	if VExRT.Bossmods.Scale then SpoilsOfPandaria.mainframe:SetScale(VExRT.Bossmods.Scale/100) end


	SpoilsOfPandaria.mainframe.side = {}
	for i=1,2 do
		SpoilsOfPandaria.mainframe.side[i] = CreateFrame("Frame",nil,SpoilsOfPandaria.mainframe)
		SpoilsOfPandaria.mainframe.side[i]:SetSize(70,20)
		SpoilsOfPandaria.mainframe.side[i].text = SpoilsOfPandaria.mainframe.side[i]:CreateFontString(nil,"ARTWORK")
		SpoilsOfPandaria.mainframe.side[i].text:SetJustifyH("CENTER")	
		SpoilsOfPandaria.mainframe.side[i].text:SetFont(ExRT.mds.defFont, 20,"OUTLINE")	
		SpoilsOfPandaria.mainframe.side[i].text:SetText("100")
		SpoilsOfPandaria.mainframe.side[i].text:SetTextColor(1, 1, 1, 1)
		SpoilsOfPandaria.mainframe.side[i].text:SetAllPoints()
		SpoilsOfPandaria.mainframe.side[i].pts = 0
	end
	SpoilsOfPandaria.mainframe.side[1]:SetPoint("TOPLEFT", 0, -5)
	SpoilsOfPandaria.mainframe.side[2]:SetPoint("TOPLEFT", 0, -25)

	SpoilsOfPandaria.mainframe:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") 
	SpoilsOfPandaria.mainframe:SetScript("OnUpdate", SpoilsOfPandaria.timerfunc)
	SpoilsOfPandaria.mainframe:SetScript("OnEvent", SpoilsOfPandaria.onEvent)
end

-----------------------------------------
-- Malkorok Skada
-----------------------------------------
local MalkorokSkada = {}
MalkorokSkada.mod = nil

function MalkorokSkada:Load()
	-- Based on Skada: SkadaHealing

	local Skada = Skada
	if not Skada then
		print(ExRT.L.BossmodsMalkorokSkadaError1)
		return
	end
	if Skada.modules["ExRT:Malkorok Healing"] then
		print(ExRT.L.BossmodsMalkorokSkadaError2)
		return
	end

	local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
	local mod = Skada:NewModule("ExRT:Malkorok Healing")
	MalkorokSkada.mod = mod
	local UnitAura,math_max,bit_band,ipairs,string_format = UnitAura,math.max,bit.band,ipairs,string.format
	local COMBATLOG_OBJECT_CONTROL_PLAYER,COMBATLOG_OBJECT_REACTION_MASK,COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_CONTROL_PLAYER,COMBATLOG_OBJECT_REACTION_MASK,COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
	local greenAuraName = GetSpellInfo(142865)

	local function log_heal(set, heal, is_absorb)
		-- Get the player from set.
		local player = Skada:get_player(set, heal.playerid, heal.playername)
		if player then
			local isGreenOnTarget = UnitAura(heal.dstName,greenAuraName,nil,"HARMFUL") --HELPFUL
			if isGreenOnTarget then
				heal.overhealing = heal.amount + heal.absorbed
				heal.amount = 0
				heal.absorbed = 0
			end
		
			-- Subtract overhealing
			local amount = math_max(0, heal.amount - heal.overhealing)
			-- Add absorbed
			amount = amount + heal.absorbed
	
			-- Add to player total.
			player.ExRT_Malkorok_healing = player.ExRT_Malkorok_healing + amount
			player.ExRT_Malkorok_overhealing = player.ExRT_Malkorok_overhealing + heal.overhealing
			player.ExRT_Malkorok_healingabsorbed = player.ExRT_Malkorok_healingabsorbed + heal.absorbed
			if is_absorb then
				player.ExRT_Malkorok_shielding = player.ExRT_Malkorok_shielding + amount
			end
	
			-- Also add to set total damage.
			set.ExRT_Malkorok_healing = set.ExRT_Malkorok_healing + amount
			set.ExRT_Malkorok_overhealing = set.ExRT_Malkorok_overhealing + heal.overhealing
			set.ExRT_Malkorok_healingabsorbed = set.ExRT_Malkorok_healingabsorbed + heal.absorbed
			if is_absorb then
				set.ExRT_Malkorok_shielding = set.ExRT_Malkorok_shielding + amount
			end
	
		end
	end
	
	local heal = {}
	
	local function SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		-- Healing
		local spellId, spellName, spellSchool, samount, soverhealing, absorbed, scritical = ...
	
		-- We want to avoid "heals" that are really drains from mobs
		-- So check if a) the source is player-controlled
		-- and b) the source and dest have the same reaction
		-- (since we can't test directly if they're friendly to each other).
		
		if bit_band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0 and bit_band(srcFlags, dstFlags, COMBATLOG_OBJECT_REACTION_MASK) ~= 0 then
			heal.dstName = dstName
			heal.playerid = srcGUID
			heal.playername = srcName
			heal.spellid = spellId
			heal.spellname = spellName
			heal.amount = samount
			heal.overhealing = soverhealing
			heal.critical = scritical
			heal.absorbed = absorbed
	
			Skada:FixPets(heal)
			log_heal(Skada.current, heal)
			log_heal(Skada.total, heal)
		end
	end
	
	
	local shields = {}
	
	local function AuraApplied(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		-- Auras
		local spellId, spellName, spellSchool, auraType, amount = ...
	
		if amount ~= nil and dstName and srcName then
			-- see if the source and destination are both part valid
			-- controlled by player:
			local valid = (bit_band(srcFlags, dstFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
			-- affiliation in party/raid:
			-- note: test separately
			valid = valid and (bit_band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0)
			valid = valid and (bit_band(dstFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0)
			-- lastly, check the reaction
			-- If a raid member is mind-controlled, we don't want to start tracking heal absorb debuffs
			-- so we need to make sure both source and destination are friendly to each other.
			-- Unfortunately, we can't test that trivially, so lets just test if their reaction to the player
			-- is the same.
			valid = valid and (bit_band(srcFlags, dstFlags, COMBATLOG_OBJECT_REACTION_MASK) ~= 0)
	
			if valid then
				if shields[dstName] == nil then shields[dstName] = {} end
				if shields[dstName][spellId] == nil then shields[dstName][spellId] = {} end
				shields[dstName][spellId][srcName] = amount
			end
		end
	end
	
	local function AuraRefresh(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		-- Auras
		local spellId, spellName, spellSchool, auraType, amount = ...
	
		if amount ~= nil then
			if shields[dstName] and shields[dstName][spellId] and shields[dstName][spellId][srcName] then
				local prev = shields[dstName][spellId][srcName]
				if prev and prev > amount then
	
					heal.dstName = dstName
					heal.playerid = srcGUID
					heal.playername = srcName
					heal.spellid = spellId
					heal.spellname = spellName
					heal.amount = prev - amount
					heal.overhealing = 0
					heal.critical = nil
					heal.absorbed = 0
	
					Skada:FixPets(heal)
					log_heal(Skada.current, heal, true)
					log_heal(Skada.total, heal, true)
				end
				shields[dstName][spellId][srcName] = amount
			end
		end
	end
	
	local function AuraRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		-- Auras
		local spellId, spellName, spellSchool, auraType, amount = ...
	
		if amount ~= nil then
			if shields[dstName] and shields[dstName][spellId] and shields[dstName][spellId][srcName] then
				local prev = shields[dstName][spellId][srcName]
				if prev and prev > amount then
	
					heal.dstName = dstName
					heal.playerid = srcGUID
					heal.playername = srcName
					heal.spellid = spellId
					heal.spellname = spellName
					heal.amount = prev
					heal.overhealing = amount
					heal.critical = nil
					heal.absorbed = 0
	
					Skada:FixPets(heal)
					log_heal(Skada.current, heal, true)
					log_heal(Skada.total, heal, true)
				end
				shields[dstName][spellId][srcName] = nil
			end
		end
	end
	
	
	
	local function getHPS(set, player)
		local totaltime = Skada:PlayerActiveTime(set, player)
	
		return player.ExRT_Malkorok_healing / math_max(1,totaltime)
	end
	
	local function getHPSByValue(set, player, healing)
		local totaltime = Skada:PlayerActiveTime(set, player)
	
		return healing / math_max(1,totaltime)
	end
	
	local function getRaidHPS(set)
		if set.time > 0 then
			return set.ExRT_Malkorok_healing / math_max(1, set.time)
		else
			local endtime = set.endtime or time()
			return set.ExRT_Malkorok_healing / math_max(1, endtime - set.starttime)
		end
	end
		
	function mod:Update(win, set)
		local nr = 1
		local max = 0
	
		for i, player in ipairs(set.players) do
			if player.ExRT_Malkorok_healing > 0 then
	
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
	
				d.id = player.id
				d.label = player.name
				d.value = player.ExRT_Malkorok_healing
	
				d.valuetext = Skada:FormatValueText(
					Skada:FormatNumber(player.ExRT_Malkorok_healing), self.metadata.columns.Healing,
					string_format("%02.1f", getHPS(set, player)), self.metadata.columns.HPS,
					string_format("O:%s", Skada:FormatNumber(player.ExRT_Malkorok_overhealing)), self.metadata.columns.Overheal
				) 
				d.class = player.class
	
				if player.ExRT_Malkorok_healing > max then
					max = player.ExRT_Malkorok_healing
				end
	
				nr = nr + 1
			end
		end
	
		win.metadata.maxvalue = max
	end
	
	function mod:OnEnable()
		mod.metadata		= {showspots = true, columns = {Healing = true, HPS = true, Overheal = true}}
	
		-- handlers for Healing spells
		Skada:RegisterForCL(SpellHeal, 'SPELL_HEAL', {src_is_interesting = true})
		Skada:RegisterForCL(SpellHeal, 'SPELL_PERIODIC_HEAL', {src_is_interesting = true})
	
		-- handlers for Absorption spells
		Skada:RegisterForCL(AuraApplied, 'SPELL_AURA_APPLIED', {src_is_interesting_nopets = true})
		Skada:RegisterForCL(AuraRefresh, 'SPELL_AURA_REFRESH', {src_is_interesting_nopets = true})
		Skada:RegisterForCL(AuraRemoved, 'SPELL_AURA_REMOVED', {src_is_interesting_nopets = true})
	
		Skada:AddMode(self)
	end
	
	function mod:OnDisable()
	end
	
	function mod:AddToTooltip(set, tooltip)
		local endtime = set.endtime
		if not endtime then
			endtime = time()
		end
		local raidhps = set.ExRT_Malkorok_healing / (endtime - set.starttime + 1)
	 	GameTooltip:AddDoubleLine(L["HPS"], ("%02.1f"):format(raidhps), 1,1,1)
	end
	
	function mod:GetSetSummary(set)
		return Skada:FormatValueText(
			Skada:FormatNumber(set.ExRT_Malkorok_healing), self.metadata.columns.Healing,
			("%02.1f"):format(getRaidHPS(set)), self.metadata.columns.HPS
		)
	end
	
	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		player.ExRT_Malkorok_healing = player.ExRT_Malkorok_healing or 0			-- Total healing
		player.ExRT_Malkorok_shielding = player.ExRT_Malkorok_shielding or 0			-- Total shields
		player.ExRT_Malkorok_overhealing = player.ExRT_Malkorok_overhealing or 0		-- Overheal total
		player.ExRT_Malkorok_healingabsorbed = player.ExRT_Malkorok_healingabsorbed or 0	-- Absorbed total
	end
	
	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		set.ExRT_Malkorok_healing = set.ExRT_Malkorok_healing or 0
		set.ExRT_Malkorok_shielding = set.ExRT_Malkorok_shielding or 0
		set.ExRT_Malkorok_overhealing = set.ExRT_Malkorok_overhealing or 0
		set.ExRT_Malkorok_healingabsorbed = set.ExRT_Malkorok_healingabsorbed or 0
		wipe(shields)
	end
	
	mod:OnEnable()
	print(ExRT.L.BossmodsMalkorokSkadaOnLoad1)
	print(ExRT.L.BossmodsMalkorokSkadaOnLoad2)
end

-----------------------------------------
-- Options
-----------------------------------------

function module.options:Load()
	local PI2 = PI * 2

	local model = CreateFrame("PlayerModel", self:GetName().."model", self)
	model:SetSize(300,200)
	model:SetPoint("BOTTOMRIGHT", -10, 85)
	model:Hide()
	--EncounterJournal.ceatureDisplayID
	
	model.fac = 0
	model:SetScript("OnUpdate",function (self,elapsed)
		self.fac = self.fac + 0.5
		if self.fac >= 360 then
			self.fac = 0
		end
		self:SetFacing(PI2 / 360 * self.fac)
		
	end)
	model:SetScript("OnShow",function (self)
		self.fac = 0
	end)

	local tottitle = ExRT.lib.CreateText(self,600,22,nil,10,-10,"CENTER",nil,nil,14,ExRT.L.bossmodstot,nil,1,1,1)
	
	local raden_loadbut = ExRT.lib.CreateButton(nil,self,600,22,nil,10,-30,ExRT.L.bossmodsraden,nil,'/rt raden')
	raden_loadbut:SetScript("OnClick",RaDen.Load) 
	raden_loadbut:SetScript("OnEnter",function(self) model:Show() model:SetDisplayInfo(47739) ExRT.lib.OnEnterTooltip(self) end) 
	raden_loadbut:SetScript("OnLeave",function(self) model:Hide() ExRT.lib.OnLeaveTooltip(self) end) 

	local sootitle = ExRT.lib.CreateText(self,600,22,nil,10,-55,"CENTER",nil,nil,14,ExRT.L.bossmodssoo,nil,1,1,1)
	
	local shaofpride_loadbut = ExRT.lib.CreateButton(nil,self,600,22,nil,10,-75,ExRT.L.bossmodsshaofpride,nil,'/rt shapride')
	shaofpride_loadbut:SetScript("OnClick",ShaOfPride.Load) 
	shaofpride_loadbut:SetScript("OnEnter",function(self) model:Show() model:SetDisplayInfo(49098) ExRT.lib.OnEnterTooltip(self) end) 
	shaofpride_loadbut:SetScript("OnLeave",function(self) model:Hide() ExRT.lib.OnLeaveTooltip(self) end) 
	
	local malkorok_loadbut = ExRT.lib.CreateButton(nil,self,575,22,nil,10,-100,ExRT.L.bossmodsmalkorok,nil,'/rt malkorok\n/rt malkorok raid')
	malkorok_loadbut:SetScript("OnClick",Malkorok.Load) 
	malkorok_loadbut:SetScript("OnEnter",function(self) model:Show() model:SetDisplayInfo(49070) ExRT.lib.OnEnterTooltip(self) end) 
	malkorok_loadbut:SetScript("OnLeave",function(self) model:Hide() ExRT.lib.OnLeaveTooltip(self) end) 

	local malkorok_autoloadchk = ExRT.lib.CreateCheckBox(nil,self,nil,582,-96,"",not VExRT.Bossmods.MalkorokAutoload,ExRT.L.bossmodsAutoLoadTooltip)
	malkorok_autoloadchk:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Bossmods.MalkorokAutoload = nil
		else
			VExRT.Bossmods.MalkorokAutoload = true
		end
	end)
	
	local malkorokAI_loadbut = ExRT.lib.CreateButton(nil,self,575,22,nil,10,-125,ExRT.L.bossmodsmalkorokai,nil,'/rt malkorokai')
	malkorokAI_loadbut:SetScript("OnClick",MalkorokAI.Load) 
	malkorokAI_loadbut:SetScript("OnEnter",function(self) model:Show() model:SetDisplayInfo(49070) ExRT.lib.OnEnterTooltip(self) end) 
	malkorokAI_loadbut:SetScript("OnLeave",function(self) model:Hide() ExRT.lib.OnLeaveTooltip(self) end) 
	
	local malkorokAI_autoloadchk = ExRT.lib.CreateCheckBox(nil,self,nil,582,-121,"",VExRT.Bossmods.MalkorokAIAutoload,ExRT.L.bossmodsAutoLoadTooltip)
	malkorokAI_autoloadchk:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Bossmods.MalkorokAIAutoload = true
		else
			VExRT.Bossmods.MalkorokAIAutoload = nil
		end
	end)
	
	local malkorokSkada_loadbut = ExRT.lib.CreateButton(nil,self,600,22,nil,10,-150,ExRT.L.BossmodsMalkorokSkada,nil,ExRT.L.BossmodsMalkorokSkadaTooltip)
	malkorokSkada_loadbut:SetScript("OnClick",MalkorokSkada.Load) 
	malkorokSkada_loadbut:SetScript("OnEnter",function(self) model:Show() model:SetDisplayInfo(49070) ExRT.lib.OnEnterTooltip(self) end)
	malkorokSkada_loadbut:SetScript("OnLeave",function(self) model:Hide() ExRT.lib.OnLeaveTooltip(self) end)	
	
	local Spoils_of_Pandaria_loadbut = ExRT.lib.CreateButton(nil,self,575,22,nil,10,-175,ExRT.L.bossmodsSpoilsofPandaria,nil,'/rt sop')
	Spoils_of_Pandaria_loadbut:SetScript("OnClick",SpoilsOfPandaria.Load) 
	Spoils_of_Pandaria_loadbut:SetScript("OnEnter",function(self) model:Show() model:SetDisplayInfo(51173) ExRT.lib.OnEnterTooltip(self) end) 
	Spoils_of_Pandaria_loadbut:SetScript("OnLeave",function(self) model:Hide() ExRT.lib.OnLeaveTooltip(self) end) 
	
	local Spoils_of_Pandaria_autoloadchk = ExRT.lib.CreateCheckBox(nil,self,nil,582,-171,"",VExRT.Bossmods.SpoilsOfPandariaAutoload,ExRT.L.bossmodsAutoLoadTooltip)
	Spoils_of_Pandaria_autoloadchk:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.Bossmods.SpoilsOfPandariaAutoload = true
		else
			VExRT.Bossmods.SpoilsOfPandariaAutoload = nil
		end
	end)
	
	local BossmodsSlider1 = ExRT.lib.CreateSlider(self:GetName().."SliderAlpha",self,550,15,0,-500,0,100,ExRT.L.bossmodsalpha,nil,"TOP")
	BossmodsSlider1:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.Bossmods.Alpha = event	
		if RaDen.mainframe then
			RaDen.mainframe:SetAlpha(event/100)
		end
		if Malkorok.mainframe then
			Malkorok.mainframe:SetAlpha(event/100)
		end
		if ShaOfPride.mainframe then
			ShaOfPride.mainframe:SetAlpha(event/100)
		end
		if SpoilsOfPandaria.mainframe then
			SpoilsOfPandaria.mainframe:SetAlpha(event/100)
		end
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	
	local BossmodsSlider2 = ExRT.lib.CreateSlider(self:GetName().."SliderScale",self,550,15,0,-530,5,200,ExRT.L.bossmodsscale,100,"TOP")
	BossmodsSlider2:SetScript("OnValueChanged", function(self,event) 
		event = event - event%1
		VExRT.Bossmods.Scale = event
		if RaDen.mainframe then
			ExRT.mds.SetScaleFix(RaDen.mainframe,event/100)
		end
		if Malkorok.mainframe then
			ExRT.mds.SetScaleFix(Malkorok.mainframe,event/100)
		end
		if ShaOfPride.mainframe then
			ExRT.mds.SetScaleFix(ShaOfPride.mainframe,event/100)
		end
		if SpoilsOfPandaria.mainframe then
			ExRT.mds.SetScaleFix(SpoilsOfPandaria.mainframe,event/100)
		end
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	
	local clearallbut = ExRT.lib.CreateButton(nil,self,600,22,nil,10,-460,ExRT.L.bossmodsclose)
	clearallbut:SetScript("OnClick",function()
		ExRT.mds:ExBossmodsCloseAll()
	end) 
	
	local ButtonToCenter = ExRT.lib.CreateButton(nil,self,600,22,nil,10,-435,ExRT.L.BossmodsResetPos,nil,ExRT.L.BossmodsResetPosTooltip)
	ButtonToCenter:SetScript("OnClick",function()
		VExRT.Bossmods.RaDenLeft = nil
		VExRT.Bossmods.RaDenTop = nil
		if RaDen.mainframe then
			RaDen.mainframe:ClearAllPoints()
			RaDen.mainframe:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
		end
		
		VExRT.Bossmods.ShaofprideLeft = nil
		VExRT.Bossmods.ShaofprideTop = nil
		if ShaOfPride.mainframe then
			ShaOfPride.mainframe:ClearAllPoints()
			ShaOfPride.mainframe:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
		end
		
		VExRT.Bossmods.MalkorokLeft = nil
		VExRT.Bossmods.MalkorokTop = nil
		if Malkorok.mainframe then
			Malkorok.mainframe:ClearAllPoints()
			Malkorok.mainframe:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
		end	
		
		VExRT.Bossmods.SpoilsofPandariaLeft = nil
		VExRT.Bossmods.SpoilsofPandariaTop = nil
		if SpoilsOfPandaria.mainframe then
			SpoilsOfPandaria.mainframe:ClearAllPoints()
			SpoilsOfPandaria.mainframe:SetPoint("CENTER",UIParent, "CENTER", 0, 0)
		end
	end) 


	if VExRT.Bossmods.Alpha then BossmodsSlider1:SetValue(VExRT.Bossmods.Alpha) end
	if VExRT.Bossmods.Scale then BossmodsSlider2:SetValue(VExRT.Bossmods.Scale) end
end

function ExRT.mds:ExBossmodsCloseAll()
	if RaDen.mainframe then
		RaDen.mainframe:Hide()
		RaDen.mainframe:SetScript("OnUpdate", nil)
		RaDen.mainframe:SetScript("OnEvent", nil)
		RaDen.mainframe:UnregisterAllEvents()
		RaDen.mainframe = nil
	end
	if MalkorokAI.mainframe then
		MalkorokAI.mainframe:Hide()
		MalkorokAI.mainframe:UnregisterAllEvents() 
		MalkorokAI.mainframe:SetScript("OnUpdate", nil)
		MalkorokAI.mainframe:SetScript("OnEvent", nil)
		if MalkorokAI.mainframe_2 then
			MalkorokAI.mainframe_2:SetScript("OnUpdate", nil)
			MalkorokAI.mainframe_2 = nil
		end
		MalkorokAI.mainframe = nil
	end
	if Malkorok.mainframe then
		Malkorok.mainframe:Hide()
		Malkorok.mainframe:UnregisterAllEvents()
		Malkorok.mainframe:SetScript("OnUpdate", nil)
		Malkorok.mainframe:SetScript("OnEvent", nil)
		Malkorok.mainframe = nil
	end
	if ShaOfPride.mainframe then
		ShaOfPride.mainframe:Hide()
		ShaOfPride.mainframe:UnregisterAllEvents()
		ShaOfPride.mainframe:SetScript("OnUpdate", nil)
		ShaOfPride.mainframe:SetScript("OnEvent", nil)
		ShaOfPride.mainframe = nil
	end
	if SpoilsOfPandaria.mainframe then
		SpoilsOfPandaria.mainframe:Hide()
		SpoilsOfPandaria.mainframe:SetScript("OnUpdate", nil)
		SpoilsOfPandaria.mainframe = nil
	end
	if MalkorokSkada.mod then
		print(ExRT.L.BossmodsMalkorokSkadaOnLoad2)
	end
end

function module:miniMapMenu()
	local cmap = GetCurrentMapAreaID()
	local clvl = GetCurrentMapDungeonLevel()

	if cmap==930 and clvl==8 then
		ExRT.mds.MinimapMenuAdd(ExRT.L.bossmodsraden, function() RaDen:Load() CloseDropDownMenus() end)
	else
		ExRT.mds.MinimapMenuRemove(ExRT.L.bossmodsraden)
	end

	if cmap==953 and clvl==8 then
		ExRT.mds.MinimapMenuAdd(ExRT.L.bossmodsmalkorok, function() Malkorok:Load() CloseDropDownMenus() end)
	else
		ExRT.mds.MinimapMenuRemove(ExRT.L.bossmodsmalkorok)
	end

	if cmap==953 and clvl==8 then
		ExRT.mds.MinimapMenuAdd(ExRT.L.bossmodsmalkorokai, function() MalkorokAI:Load() CloseDropDownMenus() end)
	else
		ExRT.mds.MinimapMenuRemove(ExRT.L.bossmodsmalkorokai)
	end

	if cmap==953 and clvl==3 then
		ExRT.mds.MinimapMenuAdd(ExRT.L.bossmodsshaofpride, function() ShaOfPride:Load() CloseDropDownMenus() end)
	else
		ExRT.mds.MinimapMenuRemove(ExRT.L.bossmodsshaofpride)
	end

	if cmap==953 and clvl==9 then
		ExRT.mds.MinimapMenuAdd(ExRT.L.bossmodsSpoilsofPandaria, function() SpoilsOfPandaria:Load() CloseDropDownMenus() end)
	else
		ExRT.mds.MinimapMenuRemove(ExRT.L.bossmodsSpoilsofPandaria)
	end

	if RaDen.mainframe or Malkorok.mainframe or ShaOfPride.mainframe or SpoilsOfPandaria.mainframe then
		ExRT.mds.MinimapMenuAdd(ExRT.L.bossmodsclose, function() ExRT.mds:ExBossmodsCloseAll() CloseDropDownMenus() end)
	else
		ExRT.mds.MinimapMenuRemove(ExRT.L.bossmodsclose)
	end
end


function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.Bossmods = VExRT.Bossmods or {}
	
	module:RegisterEvents('ENCOUNTER_START','ENCOUNTER_END')
	module:RegisterAddonMessage()
	module:RegisterMiniMapMenu()
	module:RegisterSlash()
end

function module.main:ENCOUNTER_START(encounterID)
	if encounterID == 1595 and not VExRT.Bossmods.MalkorokAutoload and not Malkorok.mainframe then
		Malkorok:Load()
		if VExRT.Bossmods.MalkorokAIAutoload then
			MalkorokAI:Load()
		end
	elseif encounterID == 1594 and VExRT.Bossmods.SpoilsOfPandariaAutoload and not SpoilsOfPandaria.mainframe then
		SpoilsOfPandaria:Load()
	end
end

function module.main:ENCOUNTER_END(encounterID,_,_,_,success)
	if success == 1 and encounterID == 1594 and SpoilsOfPandaria.mainframe then
		ExRT.mds:ExBossmodsCloseAll()
	end
end

function module:slash(arg)
	if arg == "raden" then
		RaDen:Load()
	elseif arg == "malkorok raid" then
		Malkorok:PShow()
	elseif arg == "malkorok map" then
		Malkorok:MapNow()
	elseif arg == "malkorok" then
		Malkorok:Load()
	elseif arg == "malkorokai" then
		MalkorokAI:Load()
	elseif arg == "shapride" then
		ShaOfPride:Load()
	elseif arg == "sop" then
		SpoilsOfPandaria:Load()
	elseif arg == "bmreset" then
		ExRT.mds:BossmodsresetFramePosition()
	end
end