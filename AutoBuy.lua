local GlobalAddonName, ExRT = ...

local module = ExRT.mod:New("AutoBuy",nil,true)
module.db.itemsID = {
	[101616] = true,	--> Суп с лапшой
	[101617] = true,	--> Изысканный суп с лапшой
	[101618] = true,	--> Легендарный пандаренский суп с лапшой
}
function module.main:ADDON_LOADED()
	module:RegisterEvents("MERCHANT_SHOW")
end

local function funcUnregister()
	module.db.scheduleUnregisterEvent = nil
	module:UnregisterEvents('GET_ITEM_INFO_RECEIVED')
end

local function funcReMerchant()
	module.db.scheduleReMerchant = nil
	module.main:MERCHANT_SHOW()
end

function module.main:MERCHANT_SHOW()
	module:RegisterEvents('GET_ITEM_INFO_RECEIVED')
	if module.db.scheduleUnregisterEvent then
		ExRT.mds.CancelTimer(module.db.scheduleUnregisterEvent)
	end
	module.db.scheduleUnregisterEvent = ExRT.mds.ScheduleTimer(funcUnregister, 5)
	for i=1,GetMerchantNumItems() do
		local itemLink = GetMerchantItemLink(i)
		local merchantID = itemLink and string.match(itemLink,"item:(%d+)")
		if merchantID then
			merchantID = tonumber(merchantID) or 0
			if module.db.itemsID[merchantID] then
				local maxBuyCount = 5 - (GetItemCount(merchantID,true,false) or 0)
				for j=1,maxBuyCount do
					BuyMerchantItem(i,1)
				end
				return
			end
		end
	end
end

function module.main:GET_ITEM_INFO_RECEIVED()
	if not module.db.scheduleReMerchant then
		module.db.scheduleReMerchant = ExRT.mds.ScheduleTimer(funcReMerchant, 0.1)
	end
end