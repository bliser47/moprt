local GlobalAddonName, ExRT = ...

local UnitGUID, UnitCombatlogname = UnitGUID, ExRT.mds.UnitCombatlogname

local module = ExRT.mod:New("Pets",nil,true)
module.db.petsDB = {}

function module.main:ADDON_LOADED()
	module:RegisterEvents("COMBAT_LOG_EVENT_UNFILTERED",'UNIT_PET')
	
	local n = GetNumGroupMembers() or 0
	local partyType = IsInRaid() and "raid" or "party"	
	for i=1,n do
		module.main:UNIT_PET(partyType..i)
	end
end

function module.main:COMBAT_LOG_EVENT_UNFILTERED(_,event,_,sourceGUID,sourceName,_,_,destGUID,destName)
	if event == "SPELL_SUMMON" then
		module.db.petsDB[destGUID] = {sourceGUID,sourceName,destName}
	end
end

function module.main:UNIT_PET(arg)
	local guid = UnitGUID(arg.."pet")
	if guid and not module.db.petsDB[guid] then
		module.db.petsDB[guid] = {UnitGUID(arg),UnitCombatlogname(arg),UnitCombatlogname(arg.."pet")}
	end
end

ExRT.mds.Pets = {}

function ExRT.mds.Pets:getOwnerName(petName)
	for i,val in pairs(module.db.petsDB) do
		if petName == val[3] then
			return val[2]
		end
	end
end

function ExRT.mds.Pets:getOwnerNameByGUID(petGUID)
	for i,val in pairs(module.db.petsDB) do
		if petGUID == i then
			return val[2]
		end
	end
end

function ExRT.mds.Pets:getOwnerGUID(petGUID)
	for i,val in pairs(module.db.petsDB) do
		if petGUID == i then
			return val[1]
		end
	end
end

function ExRT.mds.Pets:getOwnerGUIDByName(petName)
	for i,val in pairs(module.db.petsDB) do
		if petName == val[3] then
			return val[1]
		end
	end
end