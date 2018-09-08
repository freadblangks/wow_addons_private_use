-- 原作：Already Known?
-- 原作者：ahak (https://wow.curseforge.com/projects/alreadyknown)
-- 修改：houshuu
-------------------
-- 主要修改条目：
-- 模块化
-- 增加颜色设定

local E, L, V, P, G = unpack(ElvUI);
local WT = E:GetModule("WindTools")
local AlreadyKnown = E:NewModule('Wind_AlreadyKnown', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');

local knownTable = {} -- Save known items for later use
local db
local questItems = { -- Quest items and matching quests
	-- Equipment Blueprint: Tuskarr Fishing Net
	[128491] = 39359, -- Alliance
	[128251] = 39359, -- Horde
	-- Equipment Blueprint: Unsinkable
	[128250] = 39358, -- Alliance
	[128489] = 39358, -- Horde
}
local specialItems = { -- Items needing special treatment
	-- Krokul Flute -> Flight Master's Whistle
	[152964] = { 141605, 11, 269 } -- 269 for Flute applied Whistle, 257 (or anything else than 269) for pre-apply Whistle
}
local S_PET_KNOWN = strmatch(_G.ITEM_PET_KNOWN, "[^%(]+")

local scantip = CreateFrame("GameTooltip", "AKScanningTooltip", nil, "GameTooltipTemplate")
scantip:SetOwner(UIParent, "ANCHOR_NONE")

local function _checkIfKnown(itemLink)
	if knownTable[itemLink] then -- Check if we have scanned this item already and it was known then
		return true
	end
	local itemID = tonumber(itemLink:match("item:(%d+)"))
	if itemID and questItems[itemID] then -- Check if item is a quest item.
		if IsQuestFlaggedCompleted(questItems[itemID]) then -- Check if the quest for item is already done.
			knownTable[itemLink] = true -- Mark as known for later use
			return true -- This quest item is already known
		end
		return false -- Quest item is uncollected... or something went wrong
	elseif itemID and specialItems[itemID] then -- Check if we need special handling, this is most likely going to break with then next item we add to this
		local specialData = specialItems[itemID]
		local _, specialLink = GetItemInfo(specialData[1])
		if specialLink then
			local specialTbl = { strsplit(":", specialLink) }
			local specialInfo = tonumber(specialTbl[specialData[2]])
			if specialInfo == specialData[3] then
				knownTable[itemLink] = true -- Mark as known for later use
				return true -- This specialItem is already known
			end
		end
		return false -- Item is specialItem, but data isn't special
	end

	if itemLink:match("|H(.-):") == "battlepet" then -- Check if item is Caged Battlepet (dummy item 82800)
		local _, battlepetID = strsplit(":", itemLink)
		if C_PetJournal.GetNumCollectedInfo(battlepetID) > 0 then
			knownTable[itemLink] = true -- Mark as known for later use
			return true -- Battlepet is collected
		end
		return false -- Battlepet is uncollected... or something went wrong
	end

	scantip:ClearLines()
	scantip:SetHyperlink(itemLink)

	--for i = 2, scantip:NumLines() do -- Line 1 is always the name so you can skip it.
	local lines = scantip:NumLines()
	for i = 2, lines do -- Line 1 is always the name so you can skip it.
		local text = _G["AKScanningTooltipTextLeft"..i]:GetText()
		if text == _G.ITEM_SPELL_KNOWN or strmatch(text, S_PET_KNOWN) then
			--knownTable[itemLink] = true -- Mark as known for later use
			--return true -- Item is known and collected
			if lines - i <= 3 then -- Mounts have Riding skill and Reputation requirements under Already Known -line
				knownTable[itemLink] = true -- Mark as known for later use
			end
		elseif text == _G.TOY and _G["AKScanningTooltipTextLeft"..i + 2] and _G["AKScanningTooltipTextLeft"..i + 2]:GetText() == _G.ITEM_SPELL_KNOWN then
			knownTable[itemLink] = true
		end
	end
	--return false -- Item is not known, uncollected... or something went wrong
	return knownTable[itemLink] and true or false
end

local function _hookAH() -- Most of this found from AddOns/Blizzard_AuctionUI/Blizzard_AuctionUI.lua
	local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)

	for i=1, _G.NUM_BROWSE_TO_DISPLAY do
		if (_G["BrowseButton"..i.."Item"] and _G["BrowseButton"..i.."ItemIconTexture"]) or _G["BrowseButton"..i].id then -- Something to do with ARL?
			local itemLink
			if _G["BrowseButton"..i].id then
				itemLink = GetAuctionItemLink('list', _G["BrowseButton"..i].id)
			else
				itemLink = GetAuctionItemLink('list', offset + i)
			end

			if itemLink and _checkIfKnown(itemLink) then
				if _G["BrowseButton"..i].id then
					_G["BrowseButton"..i].Icon:SetVertexColor(db.r, db.g, db.b)
				else
					_G["BrowseButton"..i.."ItemIconTexture"]:SetVertexColor(db.r, db.g, db.b)
				end

				if db.monochrome then
					if _G["BrowseButton"..i].id then
						_G["BrowseButton"..i].Icon:SetDesaturated(true)
					else
						_G["BrowseButton"..i.."ItemIconTexture"]:SetDesaturated(true)
					end
				end
			else
				if _G["BrowseButton"..i].id then
					_G["BrowseButton"..i].Icon:SetVertexColor(1, 1, 1)
					_G["BrowseButton"..i].Icon:SetDesaturated(false)
				else
					_G["BrowseButton"..i.."ItemIconTexture"]:SetVertexColor(1, 1, 1)
					_G["BrowseButton"..i.."ItemIconTexture"]:SetDesaturated(false)
				end
			end
		end
	end
end

local function _hookMerchant() -- Most of this found from FrameXML/MerchantFrame.lua
	for i = 1, _G.MERCHANT_ITEMS_PER_PAGE do
		local index = (((MerchantFrame.page - 1) * _G.MERCHANT_ITEMS_PER_PAGE) + i)
		local itemButton = _G["MerchantItem"..i.."ItemButton"]
		local merchantButton = _G["MerchantItem"..i]
		local itemLink = GetMerchantItemLink(index)

		if itemLink and _checkIfKnown(itemLink) then
			SetItemButtonNameFrameVertexColor(merchantButton, db.r, db.g, db.b)
			SetItemButtonSlotVertexColor(merchantButton, db.r, db.g, db.b)
			SetItemButtonTextureVertexColor(itemButton, 0.9*db.r, 0.9*db.g, 0.9*db.b)
			SetItemButtonNormalTextureVertexColor(itemButton, 0.9*db.r, 0.9*db.g, 0.9*db.b)

			if db.monochrome then
				_G["MerchantItem"..i.."ItemButtonIconTexture"]:SetDesaturated(true)
			end
		else
			_G["MerchantItem"..i.."ItemButtonIconTexture"]:SetDesaturated(false)
		end
	end
end

function AlreadyKnown:Initialize()
	if not E.db.WindTools["Trade"]["Already Known"]["enabled"] then return end
	local f = CreateFrame("Frame")
	if IsAddOnLoaded("Blizzard_AuctionUI") then
		if IsAddOnLoaded("Auc-Advanced") and _G.AucAdvanced.Settings.GetSetting("util.compactui.activated") then
			hooksecurefunc("GetNumAuctionItems", _hookAH)
		else
			hooksecurefunc("AuctionFrameBrowse_Update", _hookAH)
		end
	end
	db = {
		r = E.db.WindTools["Trade"]["Already Known"]["color"].r,
		g = E.db.WindTools["Trade"]["Already Known"]["color"].g,
		b = E.db.WindTools["Trade"]["Already Known"]["color"].b,
		monochrome = false,
	}
	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", _hookMerchant)
end

local function InitializeCallback()
	AlreadyKnown:Initialize()
end
E:RegisterModule(AlreadyKnown:GetName(), InitializeCallback)
