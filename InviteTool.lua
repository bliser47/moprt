local GlobalAddonName, ExRT = ...

local VExRT = nil

local module = ExRT.mod:New("InviteTool",ExRT.L.invite)
module.db.converttoraid = false
module.db.massinv = false
module.db.invWordsArray = {}
module.db.promoteWordsArray = {}
module.db.reInvite = {}
module.db.reInviteR = nil
module.db.reInviteFrame = nil

local function InviteBut()
	local gplayers = GetNumGuildMembers() or 0
	local nowinvnum = 1
	local inRaid = IsInRaid()
	module.db.converttoraid = true
	for i=1,gplayers do
		local name,_,rankIndex,level,_,_,_,_,online,_,_,_,_,isMobile = GetGuildRosterInfo(i)
		if rankIndex < VExRT.InviteTool.Rank and online and level >= 90 and not isMobile and not UnitName(name) and name ~= module.db.playerFullName then
			if inRaid == true then
				InviteUnit(name)
			elseif nowinvnum < 5 then
				nowinvnum = nowinvnum + 1
				InviteUnit(name)
			else
				module.db.massinv = true
				return
			end
		end
	end
end

local function DisbandBut()
	local n = GetNumGroupMembers() or 0
	local myname = UnitName("player")
	for j=n,1,-1 do
		local nown = GetNumGroupMembers() or 0
		if nown > 0 then
			local name, rank = GetRaidRosterInfo(j)
			if name and myname ~= name then
				UninviteUnit(name)
			end
		end
	end
end

local function ReinviteHelpFunc()
	local inRaid = IsInRaid()
	local nowinvnum = 0
	for i=1,#module.db.reInvite do
		if not UnitInRaid(module.db.reInvite[i]) then
			if inRaid == true then
				InviteUnit(module.db.reInvite[i])
			elseif nowinvnum < 5 then
				nowinvnum = nowinvnum + 1
				InviteUnit(module.db.reInvite[i])
			end
		end
	end
end

local function ReinviteBut()
	local inRaid = IsInRaid()
	if not inRaid then
		return
	end
	table.wipe(module.db.reInvite)
	local n = GetNumGroupMembers() or 0
	for j=1,n do
		local name = GetRaidRosterInfo(j)
		table.insert(module.db.reInvite,name)
	end
	DisbandBut()
	
	if not module.db.reInviteFrame then
		module.db.reInviteFrame = CreateFrame("Frame")
	end
	
	module.db.reInviteFrame.t = 0
	module.db.reInviteFrame:SetScript("OnUpdate",function(self,e)
		self.t = self.t + e
		if self.t > 5 then
			module.db.converttoraid = true
			module.db.reInviteR = true
			ReinviteHelpFunc()
			self:SetScript("OnUpdate",nil)
		end
	end)
end

local function createInvWordsArray()
	if VExRT.InviteTool.Words then
		table.wipe(module.db.invWordsArray)
		local tmpCount = 1
		local tmpStr = strsplit(" ",VExRT.InviteTool.Words)
		while tmpStr do
			if tmpStr ~= "" and tmpStr ~= " " then
				module.db.invWordsArray[tmpStr] = 1
			end
			tmpCount = tmpCount + 1
			tmpStr = select(tmpCount,strsplit(" ",VExRT.InviteTool.Words))
		end
	end
end

local function createPromoteArray()
	if VExRT.InviteTool.PromoteNames then
		table.wipe(module.db.promoteWordsArray)
		local tmpCount = 1
		local tmpStr = strsplit(" ",VExRT.InviteTool.PromoteNames)
		while tmpStr do
			if tmpStr ~= "" and tmpStr ~= " " then
				module.db.promoteWordsArray[tmpStr] = 1
			end
			tmpCount = tmpCount + 1
			tmpStr = select(tmpCount,strsplit(" ",VExRT.InviteTool.PromoteNames))
		end
	end
end

local function demoteRaid()
	for i = 1, GetNumGroupMembers() do
		local name, rank = GetRaidRosterInfo(i)
		if name and rank == 1 then
			DemoteAssistant(name)
		end
	end
end

function module.options:Load()
	self.dropDown = CreateFrame("Frame", self:GetName().."DropDown", self, "UIDropDownMenuTemplate")
	self.dropDown:SetPoint("TOPLEFT",-3,-10)
	self.dropDown:SetWidth(200)
	UIDropDownMenu_SetWidth(self.dropDown, 200)
	UIDropDownMenu_Initialize(self.dropDown, function(self, level, menuList)
		ExRT.mds.FixDropDown(200)
		local info = UIDropDownMenu_CreateInfo()
		if IsInGuild() then
			local granks = GuildControlGetNumRanks()
			for i=granks,1,-1 do
				local grankname = GuildControlGetRankName(i) or ""
				info.text, info.checked = grankname, VExRT.InviteTool.Rank == i
				info.menuList, info.hasArrow, info.arg1, info.minWidth = i, false, i, 200
				info.func = self.SetValue
				UIDropDownMenu_AddButton(info)
			end
		end
	end)
	
	function self.dropDown:SetValue(newValue)
		VExRT.InviteTool.Rank = newValue
		UIDropDownMenu_SetText(module.options.dropDown, ExRT.L.inviterank.." " .. GuildControlGetRankName(newValue) or "")
		CloseDropDownMenus()
	end
	
	self.butInv = ExRT.lib.CreateButton(nil,self,200,22,nil,235,-12,ExRT.L.inviteinv)
	self.butInv:SetScript("OnClick",function()
		InviteBut()
	end)  
	
	self.butInv.txt = ExRT.lib.CreateText(self,100,22,nil,445,-12,nil,nil,nil,11,"/rt inv")
	
	self.butDisband = ExRT.lib.CreateButton(nil,self,422,22,nil,13,-40,ExRT.L.invitedis)
	self.butDisband:SetScript("OnClick",function()
		DisbandBut()
	end)  
	self.butDisband.txt = ExRT.lib.CreateText(self,100,22,nil,445,-40,nil,nil,nil,11,"/rt dis")
	
	self.butReinvite = ExRT.lib.CreateButton(nil,self,422,22,nil,13,-65,ExRT.L.inviteReInv)
	self.butReinvite:SetScript("OnClick",function()
		ReinviteBut()
	end) 
	self.butReinvite.txt = ExRT.lib.CreateText(self,100,22,nil,445,-65,nil,nil,nil,11,"/rt reinv")

	self.chkOnlyGuild = ExRT.lib.CreateCheckBox(nil,self,nil,310,-100,ExRT.L.inviteguildonly)
	self.chkOnlyGuild:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.InviteTool.OnlyGuild = true
		else
			VExRT.InviteTool.OnlyGuild = nil
		end
	end)
	
	self.chkInvByChat = ExRT.lib.CreateCheckBox(nil,self,nil,10,-100,ExRT.L.invitewords)
	self.chkInvByChat:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.InviteTool.InvByChat = true
			module:RegisterEvents('CHAT_MSG_WHISPER')
		else
			VExRT.InviteTool.InvByChat = nil
			module:UnregisterEvents('CHAT_MSG_WHISPER')
		end
	end)
	
	self.wordsInput = ExRT.lib.CreateEditBox(self:GetName().."WordInput",self,590,24,"TOP",3,-125,ExRT.L.invitewordstooltip,nil,nil,"InputBoxTemplate",VExRT.InviteTool.Words)
	self.wordsInput:SetScript("OnTextChanged",function(self)
		VExRT.InviteTool.Words = self:GetText()
		createInvWordsArray()
	end) 	
	
	self.chkAutoInvAccept = ExRT.lib.CreateCheckBox(nil,self,nil,10,-160,ExRT.L.inviteaccept)
	self.chkAutoInvAccept:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.InviteTool.AutoInvAccept = true
			module:RegisterEvents('PARTY_INVITE_REQUEST')
		else
			VExRT.InviteTool.AutoInvAccept = nil
			module:UnregisterEvents('PARTY_INVITE_REQUEST')
		end
	end)
	
	self.chkAutoPromote = ExRT.lib.CreateCheckBox(nil,self,nil,10,-200,ExRT.L.inviteAutoPromote,VExRT.InviteTool.AutoPromote)
	self.chkAutoPromote:SetScript("OnClick", function(self,event) 
		if self:GetChecked() then
			VExRT.InviteTool.AutoPromote = true
		else
			VExRT.InviteTool.AutoPromote = nil
		end
	end)
	
	self.dropDownAutoPromote = CreateFrame("Frame", self:GetName().."DropDownAutoPromote", self, "UIDropDownMenuTemplate")
	self.dropDownAutoPromote:SetPoint("TOPLEFT",338,-201)
	self.dropDownAutoPromote:SetWidth(237)
	UIDropDownMenu_SetWidth(self.dropDownAutoPromote, 237)
	UIDropDownMenu_Initialize(self.dropDownAutoPromote, function(self, level, menuList)
		ExRT.mds.FixDropDown(237)
		local info = UIDropDownMenu_CreateInfo()
		if IsInGuild() then
			local granks = GuildControlGetNumRanks()
			for i=granks,1,-1 do
				local grankname = GuildControlGetRankName(i) or ""
				info.text, info.checked = grankname, VExRT.InviteTool.PromoteRank == i
				info.menuList, info.hasArrow, info.arg1, info.minWidth = i, false, i, 237
				info.func = self.SetValue
				UIDropDownMenu_AddButton(info)
			end
		end
		info.text, info.checked,info.menuList, info.hasArrow, info.arg1, info.minWidth, info.func = ExRT.L.inviteAutoPromoteDontUseGuild,VExRT.InviteTool.PromoteRank == 0,0,false,0,237,self.SetValue
		UIDropDownMenu_AddButton(info)
	end)
	
	function self.dropDownAutoPromote:SetValue(newValue)
		VExRT.InviteTool.PromoteRank = newValue
		UIDropDownMenu_SetText(module.options.dropDownAutoPromote, ExRT.L.inviterank.." " .. (newValue == 0 and ExRT.L.inviteAutoPromoteDontUseGuild or GuildControlGetRankName(newValue) or ""))
		CloseDropDownMenus()
	end
	
	self.autoPromoteInput = ExRT.lib.CreateEditBox(self:GetName().."PromoteInput",self,590,24,"TOP",3,-230,ExRT.L.inviteAutoPromoteTooltip,nil,nil,"InputBoxTemplate",VExRT.InviteTool.PromoteNames)
	self.autoPromoteInput:SetScript("OnTextChanged",function(self)
		VExRT.InviteTool.PromoteNames = self:GetText()
		createPromoteArray()
	end) 
	
	self.butRaidDemote = ExRT.lib.CreateButton(nil,self,422,22,nil,13,-255,ExRT.L.inviteRaidDemote)
	self.butRaidDemote:SetScript("OnClick",function()
		demoteRaid()
	end)
	
	self.HelpPlate = {
		FramePos = { x = 0, y = 0 },FrameSize = { width = 623, height = 568 },
		[1] = { ButtonPos = { x = 50,	y = -30 },  	HighLightBox = { x = 10, y = -8, width = 605, height = 85 },		ToolTipDir = "RIGHT",	ToolTipText = ExRT.L.inviteHelpRaid },
		[2] = { ButtonPos = { x = 50,  y = -110 }, 	HighLightBox = { x = 10, y = -100, width = 605, height = 55 },		ToolTipDir = "RIGHT",	ToolTipText = ExRT.L.inviteHelpAutoInv },
		[3] = { ButtonPos = { x = 50,  y = -154 }, 	HighLightBox = { x = 10, y = -160, width = 605, height = 30 },		ToolTipDir = "RIGHT",	ToolTipText = ExRT.L.inviteHelpAutoAccept },
		[4] = { ButtonPos = { x = 50,  y = -218},  	HighLightBox = { x = 10, y = -198, width = 605, height = 85 },		ToolTipDir = "RIGHT",	ToolTipText = ExRT.L.inviteHelpAutoPromote },
	}
	self.HELPButton = ExRT.lib.CreateHelpButton(self,self.HelpPlate)

	UIDropDownMenu_SetText(self.dropDown, ExRT.L.inviterank.." " .. GuildControlGetRankName(VExRT.InviteTool.Rank) or "")
	UIDropDownMenu_SetText(self.dropDownAutoPromote, ExRT.L.inviterank.." " .. (VExRT.InviteTool.PromoteRank == 0 and ExRT.L.inviteAutoPromoteDontUseGuild or GuildControlGetRankName(VExRT.InviteTool.PromoteRank) or ""))

	if VExRT.InviteTool.OnlyGuild then self.chkOnlyGuild:SetChecked(VExRT.InviteTool.OnlyGuild) end
	if VExRT.InviteTool.InvByChat then self.chkInvByChat:SetChecked(VExRT.InviteTool.InvByChat) end
	if VExRT.InviteTool.AutoInvAccept then self.chkAutoInvAccept:SetChecked(VExRT.InviteTool.AutoInvAccept) end
end


local promoteRosterUpdate
do
	local promotes,scheduledPromotes={},nil
	local guildmembers = nil
	
	local function GuildReview()
		guildmembers = {}
		for j=1,GetNumGuildMembers() do
			local guild_name,_,rankIndex = GetGuildRosterInfo(j)
			if guild_name then
				guildmembers[ExRT.mds.delUnitNameServer(guild_name)] = rankIndex
			end
		end		
	end
	
	function promoteRosterUpdate()
		for i = 1, GetNumGroupMembers() do
			local name, rank = GetRaidRosterInfo(i)
			if name and rank == 0 then
				if module.db.promoteWordsArray[ExRT.mds.delUnitNameServer(name)] then
					promotes[name] = true
				elseif IsInGuild() and UnitIsInMyGuild(ExRT.mds.delUnitNameServer(name)) then
					if not guildmembers then
						GuildReview()
					end
					if (guildmembers[ExRT.mds.delUnitNameServer(name)] or 99) < VExRT.InviteTool.PromoteRank then
						promotes[name] = true
					end
				end
			end
		end
		if not scheduledPromotes then
			scheduledPromotes = ExRT.mds.ScheduleTimer(function ()
				scheduledPromotes = nil
				for name,v in pairs(promotes) do
					PromoteToAssistant(name)
					promotes[name] = nil
				end
			end, 2)
		end
	end
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.InviteTool = VExRT.InviteTool or {OnlyGuild=true,InvByChat=true}
	VExRT.InviteTool.Rank = VExRT.InviteTool.Rank or 1
	
	VExRT.InviteTool.Words = VExRT.InviteTool.Words or "инв inv byd штм 123"
	createInvWordsArray()
	
	VExRT.InviteTool.PromoteNames = VExRT.InviteTool.PromoteNames or ""
	VExRT.InviteTool.PromoteRank = VExRT.InviteTool.PromoteRank or 3
	createPromoteArray()
	
	module:RegisterEvents('GROUP_ROSTER_UPDATE')
	if VExRT.InviteTool.InvByChat then
		module:RegisterEvents('CHAT_MSG_WHISPER')
	end
	if VExRT.InviteTool.AutoInvAccept then
		module:RegisterEvents('PARTY_INVITE_REQUEST')
	end
	
	module:RegisterSlash()
	
	module.db.playerFullName = ExRT.mds.UnitCombatlogname("player")
end

function module.main:CHAT_MSG_WHISPER(msg, user)
	msg = string.lower(msg)
	if (msg and module.db.invWordsArray[msg]) and (UnitIsInMyGuild(ExRT.mds.delUnitNameServer(user))==1 or not VExRT.InviteTool.OnlyGuild) then
		if not IsInRaid() and GetNumGroupMembers() == 5 then 
			ConvertToRaid() 
		end
		InviteUnit(user)
	end
end

function module.main:GROUP_ROSTER_UPDATE()
	if module.db.converttoraid == true then
		module.db.converttoraid = false
		ConvertToRaid()
	end
	local inRaid = IsInRaid()
	if module.db.reInviteR and inRaid == true then
		module.db.reInviteR = nil
		ReinviteHelpFunc()
		return
	end
	if module.db.massinv == true and inRaid == true then
		module.db.massinv = false
		InviteBut()
	end
	if inRaid and UnitIsGroupLeader("player") then
		promoteRosterUpdate()
	end	
end

do
	local function IsFriend(name)
		for i=1,GetNumFriends() do if(GetFriendInfo(i)==name) then return true end end
		if(IsInGuild()) then for i=1, GetNumGuildMembers() do if(ExRT.mds.delUnitNameServer(GetGuildRosterInfo(i) or "?")==name) then return true end end end
		local b,a=BNGetNumFriends() for i=1,a do local bName=select(5,BNGetFriendInfo(i)) if bName==name then return true end end
	end
	function module.main:PARTY_INVITE_REQUEST(nameinv)
		-- PhoenixStyle
		nameinv = nameinv and ExRT.mds.delUnitNameServer(nameinv)
		if nameinv and (IsFriend(nameinv)) then
			AcceptGroup()
			for i = 1, 4 do
				local frame = _G["StaticPopup"..i]
				if(frame:IsVisible() and frame.which=="PARTY_INVITE") then
					frame.inviteAccepted = 1
					StaticPopup_Hide("PARTY_INVITE")
					return
				end
			end
		end
	end
end

function module:slash(arg)
	if arg == "inv" then
		InviteBut()
	elseif arg == "dis" then
		DisbandBut()
	elseif arg == "reinv" then
		ReinviteBut()
	end
end
