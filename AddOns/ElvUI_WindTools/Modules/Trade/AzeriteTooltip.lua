-- 原作：AzeriteTooltip
-- 原作者：jokair9
-- 修改：houshuu
-------------------
-- 主要修改条目：
-- 模块化
-- 增加设定项

local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local WT = E:GetModule("WindTools")
local AT = E:NewModule("Wind_AzeriteTooltip", "AceEvent-3.0", "AceHook-3.0")

local strsplit = strsplit
local tinsert = tinsert
local format = format
local GetSpellInfo = GetSpellInfo
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local GetContainerItemLink = GetContainerItemLink
local IsControlKeyDown = IsControlKeyDown
local C_AzeriteItem_FindActiveAzeriteItem = C_AzeriteItem.FindActiveAzeriteItem
local C_AzeriteItem_GetPowerLevel = C_AzeriteItem.GetPowerLevel
local C_AzeriteEmpoweredItem_GetPowerInfo = C_AzeriteEmpoweredItem.GetPowerInfo
local C_AzeriteEmpoweredItem_GetAllTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo
local C_AzeriteEmpoweredItem_IsPowerSelected = C_AzeriteEmpoweredItem.IsPowerSelected
local C_AzeriteEmpoweredItem_GetAllTierInfoByItemID = C_AzeriteEmpoweredItem.GetAllTierInfoByItemID
local C_AzeriteEmpoweredItem_IsAzeriteEmpoweredItem = C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem
local C_AzeriteEmpoweredItem_IsPowerAvailableForSpec = C_AzeriteEmpoweredItem.IsPowerAvailableForSpec
local C_AzeriteEmpoweredItem_IsAzeriteEmpoweredItemByID = C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID


local locationIDs = {
    ["Head"] = 1, 
    ["Shoulder"] = 3, 
    ["Chest"] = 5,
}

local itemEquipLocToSlot = {
    ["INVTYPE_HEAD"] = 1,
    ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_CHEST"] = 5,
    ["INVTYPE_ROBE"] = 5
}

local rings = {
    1,
    2,
}

local addText = ""

-- |Tpath:height[:width[:offsetX:offsetY:[textureWidth:textureHeight:leftTexel:rightTexel:topTexel:bottomTexel[:rVertexColor:gVertexColor:bVertexColor]]]]|t
-- 算法：
-- 先决定要切多少边
-- 然后再根据比例去切割材质，keep aspect ratio！
local iconString = "|T%s:18:21:0:0:64:64:5:59:10:54"

local function getIconString(icon, known)
    if known then
        return format(iconString..":255:255:255|t", icon)
    else
        return format(iconString..":150:150:150|t", icon)
    end
end

function AT:GetSpellID(powerID)
    local powerInfo = C_AzeriteEmpoweredItem_GetPowerInfo(powerID)
    if (powerInfo) then
        local azeriteSpellID = powerInfo["spellID"]
        return azeriteSpellID
    end
end

function AT:HasUnselectedPower(tooltip)
    local AzeriteUnlock = strsplit("%d", AZERITE_POWER_UNLOCKED_AT_LEVEL)
    for i = 8, tooltip:NumLines() do
        local left = _G[tooltip:GetName().."TextLeft"..i]
        local text = left:GetText()
        if text and ( text:find(AzeriteUnlock) or text:find(NEW_AZERITE_POWER_AVAILABLE) ) then
            return true
        end
    end
end

function AT:ScanSelectedTraits(tooltip, powerName)
    local empowered = GetSpellInfo(263978)
    for i = 8, tooltip:NumLines() do
        local left = _G[tooltip:GetName().."TextLeft"..i]
        local text = left:GetText()
        local newText
        local newPowerName
        if text and text:find("-") then
            newText = string.gsub(text, "-", " ")
        end
        if powerName:find("-") then
            newPowerName = string.gsub(powerName, "-", " ")
        end
        if text and text:find(powerName) then
            return true
           elseif (newText and newPowerName and newText:match(newPowerName)) then
               return true
        elseif (powerName == empowered and not self:HasUnselectedPower(tooltip)) then
             return true
        end
    end
end

function AT:GetAzeriteLevel()
    local level = 0
    local azeriteItemLocation = C_AzeriteItem_FindActiveAzeriteItem()
    if azeriteItemLocation then
        level = C_AzeriteItem_GetPowerLevel(azeriteItemLocation)
    end
    return level
end

function AT:ClearBlizzardText(tooltip)
    local textLeft = tooltip.textLeft
    if not textLeft then
        local tooltipName = tooltip:GetName()
        textLeft = setmetatable({}, { __index = function(t, i)
            local line = _G[tooltipName .. "TextLeft" .. i]
            t[i] = line
            return line
        end })
        tooltip.textLeft = textLeft
    end
    for i = 7, tooltip:NumLines() do
        if textLeft then
            local line = textLeft[i]		
            local text = line:GetText()
            local r, g, b = line:GetTextColor()
            if text then
                local ActiveAzeritePowers = strsplit("(%d/%d)", CURRENTLY_SELECTED_AZERITE_POWERS) -- Active Azerite Powers (%d/%d)
                local AzeritePowers = strsplit("(0/%d)", TOOLTIP_AZERITE_UNLOCK_LEVELS) -- Azerite Powers (0/%d)
                local AzeriteUnlock = strsplit("%d", AZERITE_POWER_UNLOCKED_AT_LEVEL) -- Unlocked at Heart of Azeroth Level %d
                local Durability = strsplit("%d / %d", DURABILITY_TEMPLATE)
                local ReqLevel = strsplit("%d", ITEM_MIN_LEVEL) 
                
                if text:match(NEW_AZERITE_POWER_AVAILABLE) then
                    line:SetText("")
                end

                if text:find(AzeriteUnlock) then
                    line:SetText("")
                end

                if text:find(Durability) or text:find(ReqLevel) then
                    textLeft[i-1]:SetText("")
                end

                if text:find(ActiveAzeritePowers) then
                    textLeft[i-1]:SetText("")
                    line:SetText("")
                    textLeft[i+1]:SetText(addText)
				elseif (text:find(AzeritePowers) and not text:find(">")) then
                    textLeft[i-1]:SetText("")
                    line:SetText("")
					textLeft[i+1]:SetText(addText)
                -- 8.1 FIX --
                elseif text:find(AZERITE_EMPOWERED_ITEM_FULLY_UPGRADED) then
                    textLeft[i-1]:SetText("")
                    line:SetText(addText)
                    textLeft[i+1]:SetText("")
                end
            end
        end
    end
end

function AT:RemovePowerText(tooltip, powerName)
    local textLeft = tooltip.textLeft
    if not textLeft then
        local tooltipName = tooltip:GetName()
        textLeft = setmetatable({}, { __index = function(t, i)
            local line = _G[tooltipName .. "TextLeft" .. i]
            t[i] = line
            return line
        end })
        tooltip.textLeft = textLeft
    end
    for i = 7, tooltip:NumLines() do
        if textLeft then
            local enchanted = strsplit("%d", ENCHANTED_TOOLTIP_LINE)
            local use = strsplit("%d", ITEM_SPELL_TRIGGER_ONUSE)
            local line = textLeft[i]		
            local text = line:GetText()
            local r, g, b = line:GetTextColor()
            local newText
            local newPowerName
            if text and text:find("-") then
                newText = string.gsub(text, "-", " ")
            end
            if powerName:find("-") then
                newPowerName = string.gsub(powerName, "-", " ")
            end
            if text then				
                if text:match(CURRENTLY_SELECTED_AZERITE_POWERS_INSPECT) then return end
                if text:find("- "..powerName) then
                    line:SetText("")
                elseif (newText and newPowerName and newText:match(newPowerName)) then
                       line:SetText("")
                end
                if ( r < 0.1 and g > 0.9 and b < 0.1 and not text:find(">") and not text:find(ITEM_SPELL_TRIGGER_ONEQUIP) and not text:find(enchanted) and not text:find(use) ) then
                    line:SetText("")
                end
            end
        end
    end
end

function AT:BuildTooltip(self)
    local name, link = self:GetItem()
      if not name then return end

      if C_AzeriteEmpoweredItem_IsAzeriteEmpoweredItemByID(link) then

        addText = ""
        
        local currentLevel = AT:GetAzeriteLevel()

        local specID = GetSpecializationInfo(GetSpecialization())
        local allTierInfo = C_AzeriteEmpoweredItem_GetAllTierInfoByItemID(link)

        if not allTierInfo then return end

        local activePowers = {}
        local activeAzeriteTrait = false

        if AT.db.compact then
            for j=1, 5 do
                if not allTierInfo[j] then break end

                local tierLevel = allTierInfo[j]["unlockLevel"]
                local azeritePowerID = allTierInfo[j]["azeritePowerIDs"][1]

                if not allTierInfo[1]["azeritePowerIDs"][1] then return end

                local azeriteTooltipText = " "
                for i, _ in pairs(allTierInfo[j]["azeritePowerIDs"]) do
                    local azeritePowerID = allTierInfo[j]["azeritePowerIDs"][i]
                    local azeriteSpellID = AT:GetSpellID(azeritePowerID)				
                    local azeritePowerName, _, icon = GetSpellInfo(azeriteSpellID)	

                    if tierLevel <= currentLevel then
                        if AT:ScanSelectedTraits(self, azeritePowerName) then
                            azeriteTooltipText = azeriteTooltipText.."  >"..getIconString(icon, true).."<"

                            tinsert(activePowers, {name = azeritePowerName})
                            activeAzeriteTrait = true
                        elseif C_AzeriteEmpoweredItem_IsPowerAvailableForSpec(azeritePowerID, specID) then
                            azeriteTooltipText = azeriteTooltipText.."  "..getIconString(icon, true)
                        elseif not AT.db.onlyspec or IsControlKeyDown() then
                            azeriteTooltipText = azeriteTooltipText.."  "..getIconString(icon, true)
                        end
                    elseif C_AzeriteEmpoweredItem_IsPowerAvailableForSpec(azeritePowerID, specID) then
                        azeriteTooltipText = azeriteTooltipText.."  "..getIconString(icon, false)
                    elseif not AT.db.onlyspec or IsControlKeyDown() then
                        azeriteTooltipText = azeriteTooltipText.."  "..getIconString(icon, false)
                    end
                end

                if tierLevel <= currentLevel then
                    if j > 1 then 
                        addText = addText.."\n \n|cFFffcc00"..LEVEL.." "..tierLevel..azeriteTooltipText.."|r"
                    else
                        addText = addText.."\n|cFFffcc00"..LEVEL.." "..tierLevel..azeriteTooltipText.."|r"
                    end
                else
                    if j > 1 then 
                        addText = addText.."\n \n|cFF7a7a7a"..LEVEL.." "..tierLevel..azeriteTooltipText.."|r"
                    else
                        addText = addText.."\n|cFF7a7a7a"..LEVEL.." "..tierLevel..azeriteTooltipText.."|r"
                    end
                end
            end
        else
            for j=1, 5 do
                if not allTierInfo[j] then break end

                local tierLevel = allTierInfo[j]["unlockLevel"]
                local azeritePowerID = allTierInfo[j]["azeritePowerIDs"][1]

                if not allTierInfo[1]["azeritePowerIDs"][1] then return end

                local r, g, b

                if tierLevel <= currentLevel then
                    r, g, b = 1, 0.8, 0
                else
                    r, g, b = 0.5, 0.5, 0.5
                end

                local rgb = ("ff%.2x%.2x%.2x"):format(r*255, g*255, b*255)
                
                if j > 1 then
                    addText = addText.. "\n\n|c" .. rgb .. format(" %s %d", LEVEL, tierLevel) .. "|r\n"
                else
                    addText = addText.. "\n|c" .. rgb .. format(" %s %d", LEVEL, tierLevel) .. "|r\n"
                end

                for i, v in pairs(allTierInfo[j]["azeritePowerIDs"]) do
                    local azeritePowerID = allTierInfo[j]["azeritePowerIDs"][i]
                    local azeriteSpellID = AT:GetSpellID(azeritePowerID)
                    local azeritePowerName, _, icon = GetSpellInfo(azeriteSpellID)
                    if tierLevel <= currentLevel then
                        if AT:ScanSelectedTraits(self, azeritePowerName) then
                            tinsert(activePowers, {name = azeritePowerName})
                            activeAzeriteTrait = true	
                            addText = addText.."\n|cFF00FF00"..getIconString(icon, true).."  "..azeritePowerName.."|r"			
                        elseif C_AzeriteEmpoweredItem_IsPowerAvailableForSpec(azeritePowerID, specID) then
                            addText = addText.."\n|cFFFFFFFF"..getIconString(icon, true).."  "..azeritePowerName.."|r"
                        elseif not AT.db.onlyspec or IsControlKeyDown()  then
                            addText = addText.."\n|cFF7a7a7a"..getIconString(icon, false).."  "..azeritePowerName.."|r"
                        end
                    elseif C_AzeriteEmpoweredItem_IsPowerAvailableForSpec(azeritePowerID, specID) then
                        addText = addText.."\n|cFF7a7a7a"..getIconString(icon, true).."  "..azeritePowerName.."|r"
                    elseif not AT.db.onlyspec or IsControlKeyDown() then
                        addText = addText.."\n|cFF7a7a7a"..getIconString(icon, false).."  "..azeritePowerName.."|r"
                    end	
                end
            end
        end

        if AT.db.removeblizzard then
            if activeAzeriteTrait then
                for k, v in pairs(activePowers) do
                    AT:RemovePowerText(self, v.name)
                end
            end
            AT:ClearBlizzardText(self)
        else
            self:AddLine(addText)
            self:AddLine(" ")
        end
        wipe(activePowers)
    end
end

function AT:CreateAzeriteIcons(button, azeriteEmpoweredItemLocation)
    if C_AzeriteEmpoweredItem_IsAzeriteEmpoweredItem(azeriteEmpoweredItemLocation) then
	    if not button.azerite then
	        button.azerite = CreateFrame("Frame", "$parent.azerite", button);
	        button.azerite:SetPoint(AT.db.icon_anchor, button, AT.db.icon_anchor)
	        button.azerite:SetSize(37, 18)
	    else
			button.azerite:ClearAllPoints()
			button.azerite:SetPoint(AT.db.icon_anchor, button, AT.db.icon_anchor)
			button.azerite:Show()
		end

        local allTierInfo = C_AzeriteEmpoweredItem_GetAllTierInfo(azeriteEmpoweredItemLocation)
        local noneSelected = true

        for j, k in ipairs(rings) do
            if not allTierInfo[j] then break end

            local azeritePowerID = allTierInfo[k]["azeritePowerIDs"][1]

            if not allTierInfo[1]["azeritePowerIDs"][1] then return end

            for i, _ in pairs(allTierInfo[k]["azeritePowerIDs"]) do
                local azeritePowerID = allTierInfo[k]["azeritePowerIDs"][i]
                local azeriteSpellID = self:GetSpellID(azeritePowerID)
                local azeritePowerName, _, icon = GetSpellInfo(azeriteSpellID)

                if C_AzeriteEmpoweredItem_IsPowerSelected(azeriteEmpoweredItemLocation, azeritePowerID) then
					noneSelected = false
					if not button.azerite[j] then
						button.azerite[j] = button.azerite:CreateTexture("$parent."..j, "OVERLAY", nil, button.azerite)
						if j == 1 then
							button.azerite[j]:SetPoint(AT.db.icon_anchor, button, AT.db.icon_anchor)
						else
							button.azerite[j]:SetPoint("BOTTOMLEFT", button.azerite[j-1], "BOTTOMRIGHT", 4, 0)
						end
						button.azerite[j]:SetSize(16, 16)
						button.azerite[j]:SetTexture(icon)
						-- Border
				        button.azerite[j].overlay = button.azerite:CreateTexture(nil, "ARTWORK", nil, 7)
				        button.azerite[j].overlay:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
				        button.azerite[j].overlay:SetVertexColor(0.7,0.7,0.7,0.8)
				        button.azerite[j].overlay:SetPoint("TOPLEFT", button.azerite[j], -3, 3)
				        button.azerite[j].overlay:SetPoint("BOTTOMRIGHT", button.azerite[j], 3, -3)
				        button.azerite[j].overlay:SetBlendMode("ADD")
					else
						if j == 1 then
							button.azerite[j]:ClearAllPoints()
							button.azerite[j]:SetPoint(AT.db.icon_anchor, button, AT.db.icon_anchor)
						end
	  					button.azerite[j]:SetTexture(icon)
					end
				end
            end					
        end
        if noneSelected	then button.azerite:Hide() end
    else
        if button.azerite then
            button.azerite:Hide()
        end
    end
end

function AT:SetContainerAzerite(self)
    local name = self:GetName();
    for i = 1, self.size or 1 do
        local button = self.size and _G[name .. "Item" .. i] or self;
        local self = self.size and self or button:GetParent()
        local link = GetContainerItemLink(self:GetID(), button:GetID())

        if not button then
            return
        end;

        if link then
            local azeriteEmpoweredItemLocation = ItemLocation:CreateFromBagAndSlot(self:GetID(), button:GetID())

            AT:CreateAzeriteIcons(button, azeriteEmpoweredItemLocation)
        else
            if button.azerite then
                button.azerite:Hide()
            end
        end
    end
end

function AT:SetPaperDollAzerite(self)
    local button = self
    local id = self:GetID();
    local textureName = GetInventoryItemTexture("player", id);

    local hasItem = textureName ~= nil;

    if (id == 1 or id == 3 or id == 5) and hasItem then

        local azeriteEmpoweredItemLocation = ItemLocation:CreateFromEquipmentSlot(id)

        AT:CreateAzeriteIcons(button, azeriteEmpoweredItemLocation)
    else
        if button.azerite then
            button.azerite:Hide()
        end
    end
end

function AT:SetFlyoutAzerite(self)
    if self.azerite then
        self.azerite:Hide()
    end

    if ( not self.location ) then
        return;
    end

    if ( self.location >= EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION ) then
        return;
    end

    local _, _, _, _, slot, bag = EquipmentManager_UnpackLocation(self.location)
    local azeriteEmpoweredItemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
    local button = self

    if not bag then return end

    if not button then
        return
    end;
    
    AT:CreateAzeriteIcons(button, azeriteEmpoweredItemLocation)
end

-- HOOKS

function AT:ContainerFrame_Update(frame)
    if not self.db.bags then return end

    self:SetContainerAzerite(frame)
end

function AT:PaperDollItemSlotButton_Update(frame)
    if not self.db.paperdoll then return end

    self:SetPaperDollAzerite(frame)
end

function AT:EquipmentFlyout_DisplayButton(frame)
    if not self.db.paperdoll then return end

    self:SetFlyoutAzerite(frame)
end

function AT:OnTooltipSetItem(frame)
    self:BuildTooltip(frame)
end

function AT:Initialize()
    if not E.db.WindTools["Trade"]["Azerite Tooltip"]["enabled"] then return end

	self.db = E.db.WindTools["Trade"]["Azerite Tooltip"]
	tinsert(WT.UpdateAll, function()
		AT.db = E.db.WindTools["Trade"]["Azerite Tooltip"]
    end)
    
    self:SecureHook('PaperDollItemSlotButton_Update')
    self:SecureHook('EquipmentFlyout_DisplayButton')
    self:SecureHook('ContainerFrame_Update')

    if IsAddOnLoaded("Bagnon") then
        hooksecurefunc(Bagnon.ItemSlot, "Update", function(self)
            if not AT.db.Bags then return end
            AT:SetContainerAzerite(self) 
        end)
    end

    self:SecureHookScript(GameTooltip, 'OnTooltipSetItem', 'OnTooltipSetItem')
    self:SecureHookScript(ItemRefTooltip, 'OnTooltipSetItem', 'OnTooltipSetItem')
    self:SecureHookScript(ShoppingTooltip1, 'OnTooltipSetItem', 'OnTooltipSetItem')
    self:SecureHookScript(EmbeddedItemTooltip, 'OnTooltipSetItem', 'OnTooltipSetItem')
end

local function InitializeCallback()
    AT:Initialize()
end
E:RegisterModule(AT:GetName(), InitializeCallback)
