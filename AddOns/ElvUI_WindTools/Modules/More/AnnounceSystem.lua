-- 原作：ShestakUI 的一个通告组件
-- 原作者：Shestak (http://www.wowinterface.com/downloads/info19033-ShestakUI.html)
-- 修改：houshuu
-------------------
-- 主要修改条目：
-- 模块化
-- 职业染色
-- 修改函数判定参数
-- 修正宠物打断不通告问题
-- 添加嘲讽模块
-- 增减了部分光环通告
-- 汉化使其更加适合中文语法
-- 频道检测更加多样化
-- 添加了一些可设置项

local E, L, V, P, G = unpack(ElvUI)
local WT = E:GetModule("WindTools")
local AnnounceSystem = E:NewModule('AnnounceSystem', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');

local format = string.format
local pairs = pairs

P["WindTools"]["Announce System"] = {
	["enabled"] = true,
	["Taunt"] = {
		["enabled"] = true,
		["missenabled"] = true,
		["PlayerSmart"] = false,
		["PetSmart"] = false,
		["OtherTankSmart"] = false,
		["IncludePet"] = true,
		["IncludeOtherTank"] = true,
	},
	["Interrupt"] = {
		["enabled"] = true,
		["SoloYell"] = false,
		["IncludePet"] = true,
	},
	["ResAndThreat"] = {
		["enabled"] = true,
	},
	["ResThanks"] = {
		["enabled"] = true,
	},
	["RaidUsefulSpells"] = {
		["enabled"] = true,
	},
}

local myName = UnitName("player")
local simpleline = "|cffe84393----------------------|r"
local simplestart = "|cffe84393|--|r"

local ASL = {
	["AS"] = "通告系統",
	["UseSpellNoTarget"] = "%s 使用了 %s",
	["UseSpellTarget"] = "%s 使用了 %s -> %s",
	["UseSpellTargetInChat"] = "|cffd63031通告系統：|r %s |cff00ff00使用了|r %s -> |cfffdcb6e%s|r",
	["PutNormal"] = "%s 放置了 %s",
	["PutFeast"] = "天啊，土豪 %s 竟然擺出了 %s！",
	["PutPortal"] = "%s 開啟了 %s",
	["PutRefreshmentTable"] = "%s 使用了 %s，各位快來領餐包哦！",
	["RitualOfSummoning"] = "%s 正在進行 %s，請配合點門哦！",
	["SoulWell"] = "%s 發糖了，快點拿喲！",
	["Interrupt"] = "我打斷了 %s 的 >%s<！",
	["InterruptInChat"] = "|cffd63031通告系統：|r |cff00ff00成功打斷|r -> |cfffdcb6e%s|r >%s<！",
	["Thanks"] = "%s，謝謝你復活我:)",
	["Taunt"] = "我成功嘲諷了 %s！",
	["TauntInChat"] = "|cffd63031通告系統：|r |cff00ff00成功嘲諷|r -> |cfffdcb6e%s|r！",
	["PetTaunt"] = "我的寵物成功嘲諷了 %s！",
	["PetTauntInChat"] = "|cffd63031通告系統：|r |cff00ff00寵物成功嘲諷|r -> |cfffdcb6e%s|r！",
	["OtherTankTaunt"] = "%s 成功嘲諷了 %s",
	["OtherTankTauntInChat"] = "|cffd63031通告系統：|r %s |cff00ff00成功嘲諷|r -> |cfffdcb6e%s|r！",
	["TauntMiss"] = "我嘲諷 %s 失敗！",
	["TauntMissInChat"] = "|cffd63031通告系統：|r |cffff0000嘲諷失敗|r -> |cfffdcb6e%s|r！",
	["PetTauntMiss"] = "我的寵物嘲諷了 %s 失敗！",
	["PetTauntMissInChat"] = "|cffd63031通告系統：|r |cffff0000寵物嘲諷失敗|r -> |cfffdcb6e%s|r！",
	["OtherTankTauntMiss"] = "%s 嘲諷 %s 失敗！",
	["OtherTankTauntMissInChat"] = "|cffd63031通告系統：|r %s |cffff0000嘲諷失敗|r -> |cfffdcb6e%s|r！",
}
if GetLocale() == "zhCN" then
	ASL = {
		["AS"] = "通告系统",
		["UseSpellNoTarget"] = "%s 使用了 %s",
		["UseSpellTarget"] = "%s 使用了 %s -> %s",
		["UseSpellTargetInChat"] = "|cffd63031通告系统：|r %s |cff00ff00使用了|r %s -> |cfffdcb6e%s|r",
		["PutNormal"] = "%s 放置了 %s",
		["PutFeast"] = "天啊，土豪 %s 竟然摆出了 %s！",
		["PutPortal"] = "%s 开启了 %s",
		["PutRefreshmentTable"] = "%s 使用了 %s，各位快來领面包哦！",
		["RitualOfSummoning"] = "%s 正在进行 %s，请配合点门哦！",
		["SoulWell"] = "%s 发糖了，快点拿哟！",
		["Interrupt"] = "我打断了 %s 的 >%s<！",
		["InterruptInChat"] = "|cffd63031通告系统：|r |cff00ff00成功打断|r -> |cfffdcb6e%s|r >%s<！",
		["Thanks"] = "%s，谢谢你复活我:)",
		["Taunt"] = "我成功嘲讽了 %s！",
		["TauntInChat"] = "|cffd63031通告系統：|r |cff00ff00成功嘲讽|r -> |cfffdcb6e%s|r！",
		["PetTaunt"] = "我的宠物成功嘲讽了 %s！",
		["PetTauntInChat"] = "|cffd63031通告系统：|r |cff00ff00宠物成功嘲讽|r -> |cfffdcb6e%s|r！",
		["OtherTankTaunt"] = "%s 成功嘲讽了 %s",
		["OtherTankTauntInChat"] = "|cffd63031通告系统：|r %s |cff00ff00成功嘲讽|r -> |cfffdcb6e%s|r！",
		["TauntMiss"] = "我嘲讽 %s 失败！",
		["TauntMissInChat"] = "|cffd63031通告系统：|r |cffff0000嘲讽失败|r -> |cfffdcb6e%s|r！",
		["PetTauntMiss"] = "我的宠物嘲讽了 %s 失败！",
		["PetTauntMissInChat"] = "|cffd63031通告系统：|r |cffff0000宠物嘲讽失败|r -> |cfffdcb6e%s|r！",
		["OtherTankTauntMiss"] = "%s 嘲讽 %s 失败！",
		["OtherTankTauntMissInChat"] = "|cffd63031通告系统：|r %s |cffff0000嘲讽失败|r -> |cfffdcb6e%s|r！",
	}
end

----------------------------------------------------------------------------------------
--	名字染色
----------------------------------------------------------------------------------------
local function AddClassColor(playerID)
	local _, englishClass, _, _, _, playerName = GetPlayerInfoByGUID(playerID)
	local colorString = RAID_CLASS_COLORS[englishClass].colorStr

	return "|c"..colorString..playerName.."|r"
end
----------------------------------------------------------------------------------------
--	智能頻道檢測
----------------------------------------------------------------------------------------
local function CheckChat(warning)
	-- 随机团队频道 > 副本警告频道 > 副本频道 > 队伍频道 > 说频道
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		return "INSTANCE_CHAT"
	elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
		if warning and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or IsEveryoneAssistant()) then
			return "RAID_WARNING"
		else
			return "RAID"
		end
	elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
		return "PARTY"
	end

	return "SAY"
end

----------------------------------------------------------------------------------------
--	打断频道检测
----------------------------------------------------------------------------------------
local function CheckChatInterrupt ()
	-- 随机团队频道 > 副本频道 > 队伍频道 > 大喊频道（设定的话） > 聊天框显示
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		return "INSTANCE_CHAT"
	elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
		return "RAID"
	elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
		return "PARTY"
	elseif E.db.WindTools["Announce System"]["Interrupt"]["SoloYell"] then
		return "YELL"
	end

	return "ChatFrame"
end

----------------------------------------------------------------------------------------
--	嘲讽频道检测
----------------------------------------------------------------------------------------
local function CheckChatTaunt ()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		return "INSTANCE_CHAT"
	elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
		return "RAID"
	elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
		return "PARTY"
	end
	return "YELL"
end

local ThanksSpells = {
	-- 复活技能
	[20484] = true,		-- 復生
	[61999] = true,		-- 盟友復生
	[20707] = true,		-- 靈魂石
	[50769] = true,		-- 復活
	[2006]  = true,		-- 復活術
	[7328]  = true,		-- 救贖
	[2008]  = true,		-- 先祖之魂
	[115178] = true,	-- 回命訣
}
local CombatResSpells = {
	-- 战复技能
	[61999] = true,	-- 盟友復生
	[20484] = true,	-- 復生
	[20707] = true,	-- 靈魂石
}
local TransferThreatSpells = {
	-- 仇恨转移技能
	[34477] = true,	-- 誤導
	[57934] = true,	-- 偷天換日
}

local FeastSpells = {
	-- 大餐通報列表
	[126492] = true,  -- 燒烤盛宴
	[126494] = true,  -- 豪华燒烤盛宴
	[126495] = true,  -- 快炒盛宴
	[126496] = true,  -- 豪华快炒盛宴
	[126501] = true,  -- 烘烤盛宴
	[126502] = true,  -- 豪华烘烤盛宴
	[126497] = true,  -- 燉煮盛宴
	[126498] = true,  -- 豪华燉煮盛宴
	[126499] = true,  -- 蒸煮盛宴
	[126500] = true,  -- 豪華蒸煮盛宴
	[104958] = true,  -- 熊貓人盛宴
	[126503] = true,  -- 美酒盛宴
	[126504] = true,  -- 豪華美酒盛宴
	[145166] = true,  -- 拉麵推車
	[145169] = true,  -- 豪華拉麵推車
	[145196] = true,  -- 熊貓人國寶級拉麵推車
	[188036] = true,  -- 靈魂大鍋
	[201352] = true,  -- 蘇拉瑪爾豪宴
}

local Bots = {
	-- 機器人通報列表
	[22700] = true,		-- 修理機器人74A型
	[44389] = true,		-- 修理機器人110G型
	[54711] = true,		-- 廢料機器人
	[67826] = true,		-- 吉福斯
	[126459] = true,	-- 布靈登4000型
	[161414] = true,	-- 布靈登5000型
	[198989] = true,	-- (Test)布靈登66000型
	[199109] = true,	-- 自動鐵錘
	[226241] = true,	-- 靜心寶典
}


local Toys = {
	-- 玩具
	[61031] = true,		-- 玩具火車組
	[49844] = true,		-- 恐酒遙控器
}

local PortalSpells = {
	-- 傳送門通報列表
	-- 聯盟
	[10059] = true,		-- 暴風城
	[11416] = true,		-- 鐵爐堡
	[11419] = true,		-- 達納蘇斯
	[32266] = true,		-- 艾克索達
	[49360] = true,		-- 塞拉摩
	[33691] = true,		-- 撒塔斯
	[88345] = true,		-- 托巴拉德
	[132620] = true,	-- 恆春谷
	[176246] = true,	-- 暴風之盾
	-- 部落
	[11417] = true,		-- 奧格瑪
	[11420] = true,		-- 雷霆崖
	[11418] = true,		-- 幽暗城
	[32267] = true,		-- 銀月城
	[49361] = true,		-- 斯通納德
	[35717] = true,		-- 撒塔斯
	[88346] = true,		-- 托巴拉德
	[132626] = true,	-- 恆春谷
	[176244] = true,	-- 戰爭之矛
	-- 中立
	[53142] = true,		-- 達拉然
	[120146] = true,	-- 遠古達拉然
}

local TauntSpells = {
	[355] = true,    -- Warrior
	--  [114198] = true, -- Warrior (Mocking Banner)
	[2649] = true,   -- Hunter (Pet)
	[20736] = true,  -- Hunter (Distracting Shot)
	[123588] = true, -- Hunter (Distracting Shot - glyphed)
	[6795] = true,   -- Druid
	[17735] = true,  -- Warlock (Voidwalker)
	[97827] = true,  -- Warlock (Provocation (Metamorphosis))
	[49560] = true,  -- Death Knight (Death Grip (aura))
	[56222] = true,  -- Death Knight
	[73684] = true,  -- Shaman (Unleash Earth)
	[62124] = true,  -- Paladin
	[116189] = true, -- Monk (Provoke (aura))
	[118585] = true, -- Monk (Leer of the Ox)
	[118635] = true, -- Monk (Black Ox Provoke)
}


----------------------------------------------------------------------------------------
--	团队战斗有用技能提示
----------------------------------------------------------------------------------------
function AnnounceSystem:RaidUsefulSpells()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self, event)
		local _, subEvent, _, _, _, srcName, srcName2, _, _, destName, destName2, _, spellID = CombatLogGetCurrentEventInfo() 
		if not IsInGroup() or InCombatLockdown() or not subEvent or not spellID or not srcName then return end
		if not UnitInRaid(srcName) and not UnitInParty(srcName) then return end

		local srcName = srcName:gsub("%-[^|]+", "")
		if subEvent == "SPELL_CAST_SUCCESS" then
			-- 大餐
			if FeastSpells[spellID] then 
				SendChatMessage(format(ASL["PutFeast"], srcName, GetSpellLink(spellID)), CheckChat(true))
			end
			-- 召喚餐點桌
			if spellID == 43987 then
				SendChatMessage(format(ASL["PutRefreshmentTable"], srcName, GetSpellLink(spellID)), CheckChat(true))
			-- 召喚儀式
			elseif spellID == 698 then
				SendChatMessage(format(ASL["RitualOfSummoning"], srcName, GetSpellLink(spellID)), CheckChat(true))
			end
		elseif subEvent == "SPELL_SUMMON" then
			-- 修理機器人
			if Bots[spellID] then
				SendChatMessage(format(ASL["PutNormal"], srcName, GetSpellLink(spellID)), CheckChat(true))
			end
		elseif subEvent == "SPELL_CREATE" then
			-- MOLL-E 郵箱
			if spellID == 54710 then
				SendChatMessage(format(ASL["PutNormal"], srcName, GetSpellLink(spellID)), CheckChat(true))
			-- 靈魂之井
			elseif spellID == 29893 then
				SendChatMessage(format(ASL["SoulWell"], srcName), CheckChat(true))
			-- 玩具
			elseif Toys[spellID] then
				SendChatMessage(format(ASL["PutNormal"], srcName, GetSpellLink(spellID)), CheckChat())
			-- 傳送門
			elseif PortalSpells[spellID] then
				SendChatMessage(format(ASL["PutPortal"], srcName, GetSpellLink(spellID)), CheckChat(true))
			end
		-- elseif subEvent == "SPELL_AURA_APPLIED" then
		-- 	-- 火鷄羽毛 及 派對手榴彈
		-- 	if spellID == 61781 or ((spellID == 51508 or spellID == 51510)) then
		-- 		SendChatMessage(format(ASL["UseSpellNoTarget"], srcName, GetSpellLink(spellID)), CheckChat())
		-- 	end
		end
	end)
end

----------------------------------------------------------------------------------------
--	战复 / 误导
----------------------------------------------------------------------------------------
function AnnounceSystem:ResAndThreat()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self, event)	
		local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
		local _, _, difficultyID = GetInstanceInfo()
		
		if event ~= "SPELL_CAST_SUCCESS" then return end
		
		if destName then destName = destName:gsub("%-[^|]+", "") end
		if sourceName then sourceName = sourceName:gsub("%-[^|]+", "") else return end
		
		-- 在副本里启用战复技能提示
		if difficultyID ~= 0 then
			if CombatResSpells[spellID] then
				if destName == nil then
					SendChatMessage(format(ASL["UseSpellNoTarget"], sourceName, GetSpellLink(spellID)), CheckChat())
				else
					SendChatMessage(format(ASL["UseSpellTarget"], sourceName, GetSpellLink(spellID), destName), CheckChat())
				end
			end
		end

		-- 仇恨转移技能提示
		if TransferThreatSpells[spellID] then
			if destName == myName or sourceName == myName then
				-- 如果自己被误导或者自己误导别人，用表情进行通告
				-- 其他时候则显示在聊天框
				SendChatMessage(format(": "..ASL["UseSpellTarget"], sourceName, GetSpellLink(spellID), destName), "EMOTE")
			else
				-- 如果确认转移目标是玩家的话，进行职业染色
				if strsplit("-", destGUID) == "Player" then
					ChatFrame1:AddMessage(format(ASL["UseSpellTargetInChat"], AddClassColor(sourceGUID), GetSpellLink(spellID), AddClassColor(destGUID)))
				else
					ChatFrame1:AddMessage(format(ASL["UseSpellTargetInChat"], AddClassColor(sourceGUID), GetSpellLink(spellID), destName))
				end
			end
		end

	end)
end

----------------------------------------------------------------------------------------
--	复活感谢
----------------------------------------------------------------------------------------
function AnnounceSystem:ResThanks()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self,event)
		local _, event, _, subEvent, _, _, buffer, _, _, _, player, _, _, spell = CombatLogGetCurrentEventInfo()
		for key, value in pairs(ThanksSpells) do
			if spell == key and value == true and player == myName and buffer ~= myName and subEvent == "SPELL_CAST_SUCCESS" then
				local thanksTargetName = buffer:gsub("%-[^|]+", "") -- 去除服务器名
				SendChatMessage(format(ASL["Thanks"], thanksTargetName), "WHISPER", nil, buffer)
			end
		end
	end)
end

----------------------------------------------------------------------------------------
--	打断
----------------------------------------------------------------------------------------
function AnnounceSystem:Interrupt()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self,event)
		local _, event, _, sourceGUID, _, _, _, _, destName, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
		-- 打断

		if not (event == "SPELL_INTERRUPT" and spellID) then return end

		local canAnnounce = false

		if sourceGUID == UnitGUID("player") then
			canAnnounce = true
		elseif sourceGUID == UnitGUID("pet") and E.db.WindTools["Announce System"]["Interrupt"]["IncludePet"] then
			canAnnounce = true
		else
			canAnnounce = false
		end

		if canAnnounce then
			local destChannel = CheckChatInterrupt()
			if destChannel == "ChatFrame" then
				-- 如果没有设定个人情况发送到大喊频道，就在聊天框显示一下（就自己能看到）
				ChatFrame1:AddMessage(simpleline)
				ChatFrame1:AddMessage(format(ASL["InterruptInChat"], destName, GetSpellLink(spellID)))
				ChatFrame1:AddMessage(simpleline)
			else
				-- 智能检测频道并发送信息
				SendChatMessage(format(ASL["Interrupt"], destName, GetSpellLink(spellID)), destChannel)
			end
		end
	end)
end

----------------------------------------------------------------------------------------
--	嘲讽
----------------------------------------------------------------------------------------
function AnnounceSystem:Taunt()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self, event)
		local _, event, _, sourceGUID, sourceName, _, _, _, destName, _, _, spellID, _, _, missType = CombatLogGetCurrentEventInfo()
		-- 嘲讽
		if event == "SPELL_AURA_APPLIED" and TauntSpells[spellID] then
			-- 如果施放嘲讽技能成功
			if sourceGUID == UnitGUID("player") then
				-- 玩家嘲讽
				if E.db.WindTools["Announce System"]["Taunt"]["PlayerSmart"] then
					-- 玩家嘲讽智能喊话
					SendChatMessage(format(ASL["Taunt"], destName), CheckChatTaunt())
				else
					-- 玩家嘲讽信息显示于综合
					ChatFrame1:AddMessage(format(ASL["TauntInChat"], destName))
				end
			elseif sourceGUID == UnitGUID("pet") and E.db.WindTools["Announce System"]["Taunt"]["IncludePet"] then
				-- 宠物嘲讽
				if E.db.WindTools["Announce System"]["Taunt"]["PetSmart"] then
					-- 宠物嘲讽智能喊话
					SendChatMessage(format(ASL["PetTaunt"], destName), CheckChatTaunt())
				else
					-- 宠物嘲讽信息显示于综合
					ChatFrame1:AddMessage(format(ASL["PetTauntInChat"], destName))
				end
			elseif E.db.WindTools["Announce System"]["Taunt"]["IncludeOtherTank"] and UnitGroupRolesAssigned(sourceName) == "TANK" then
				-- 他人嘲讽
				-- 去除服务器信息
				local oriSourceName = sourceName
				sourceName = sourceName:gsub("%-[^|]+", "")
				if E.db.WindTools["Announce System"]["Taunt"]["OtherTankSmart"] then
					-- 他人嘲讽智能喊话
					SendChatMessage(format(ASL["OtherTankTaunt"], sourceName, destName), CheckChatTaunt())
				else
					-- 他人嘲讽信息显示于聊天框架
					ChatFrame1:AddMessage(simpleline)
					ChatFrame1:AddMessage(format(ASL["OtherTankTauntInChat"], AddClassColor(sourceGUID), destName))
					ChatFrame1:AddMessage(simpleline)
				end
			end
		end

		if not E.db.WindTools["Announce System"]["Taunt"]["missenabled"] then return end
		if event == "SPELL_MISSED" and TauntSpells[spellID] then
			-- 如果施放嘲讽技能失败
			if sourceGUID == UnitGUID("player") then
				-- 玩家嘲讽
				if E.db.WindTools["Announce System"]["Taunt"]["PlayerSmart"] then
					-- 玩家嘲讽智能喊话
					SendChatMessage(format(ASL["TauntMiss"], destName), CheckChatTaunt())
				else
					-- 玩家嘲讽信息显示于综合
					ChatFrame1:AddMessage(format(ASL["TauntMissInChat"], destName))
				end
			elseif sourceGUID == UnitGUID("pet") and E.db.WindTools["Announce System"]["Taunt"]["IncludePet"] then
				-- 宠物嘲讽
				if E.db.WindTools["Announce System"]["Taunt"]["PetSmart"] then
					-- 宠物嘲讽智能喊话
					SendChatMessage(format(ASL["PetTauntMiss"], destName), CheckChatTaunt())
				else
					-- 宠物嘲讽信息显示于综合
					ChatFrame1:AddMessage(format(ASL["PetTauntMissInChat"], destName))
				end
			elseif E.db.WindTools["Announce System"]["Taunt"]["IncludeOtherTank"] and UnitGroupRolesAssigned(sourceName) == "TANK" then
				-- 他坦嘲讽
				-- 去除服务器信息
				local oriSourceName = sourceName
				sourceName = sourceName:gsub("%-[^|]+", "")
				if E.db.WindTools["Announce System"]["Taunt"]["OtherTankSmart"] then
					-- 他人嘲讽智能喊话
					SendChatMessage(format(ASL["OtherTankTauntMiss"], sourceName, destName), CheckChatTaunt())
				else
					-- 他人嘲讽信息显示于综合
					ChatFrame1:AddMessage(simpleline)
					ChatFrame1:AddMessage(format(ASL["OtherTankTauntMissInChat"], AddClassColor(sourceGUID), destName))
					ChatFrame1:AddMessage(simpleline)
				end
			end
		end
	end)
end

function AnnounceSystem:Initialize()
	if not (GetLocale() == "zhCN" or GetLocale() == "zhTW") then return end
	if not E.db.WindTools["Announce System"]["enabled"] then return end
	
	if E.db.WindTools["Announce System"]["Interrupt"]["enabled"] then
		AnnounceSystem:Interrupt()
	end
	if E.db.WindTools["Announce System"]["Taunt"]["enabled"] then
		AnnounceSystem:Taunt()
	end
	if E.db.WindTools["Announce System"]["ResAndThreat"]["enabled"] then
		AnnounceSystem:ResAndThreat()
	end
	if E.db.WindTools["Announce System"]["ResThanks"]["enabled"] then
		AnnounceSystem:ResThanks()
	end
	if E.db.WindTools["Announce System"]["RaidUsefulSpells"]["enabled"] then
		AnnounceSystem:RaidUsefulSpells()
	end
end

local function InsertOptions()
	E.Options.args.WindTools.args["More Tools"].args["Announce System"].args["Interrupt"] = {
		order = 10,
		type = "group",
		name = L["Interrupt"],
		guiInline = true,
		args = {
			Enable = {
				order = 1,
				type = "toggle",
				name = L["Enable"],
				get = function(info) return E.db.WindTools["Announce System"]["Interrupt"]["enabled"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Interrupt"]["enabled"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			SoloYell = {
				order = 2,
				type = "toggle",
				name = L["Solo Yell"],
				get = function(info) return E.db.WindTools["Announce System"]["Interrupt"]["SoloYell"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Interrupt"]["SoloYell"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			IncludePet = {
				order = 3,
				type = "toggle",
				name = L["Include Pet"],
				get = function(info) return E.db.WindTools["Announce System"]["Interrupt"]["IncludePet"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Interrupt"]["IncludePet"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
		}
	}
	E.Options.args.WindTools.args["More Tools"].args["Announce System"].args["Taunt"] = {
		order = 11,
		type = "group",
		name = L["Taunt"],
		guiInline = true,
		args = {
			Enable = {
				order = 0,
				type = "toggle",
				name = L["Enable"],
				get = function(info) return E.db.WindTools["Announce System"]["Taunt"]["enabled"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Taunt"]["enabled"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			Enable = {
				order = 1,
				type = "toggle",
				name = L["Enable Miss"],
				get = function(info) return E.db.WindTools["Announce System"]["Taunt"]["missenabled"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Taunt"]["missenabled"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			PlayerSmart = {
				order = 2,
				type = "toggle",
				name = L["Player Smart"],
				get = function(info) return E.db.WindTools["Announce System"]["Taunt"]["PlayerSmart"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Taunt"]["PlayerSmart"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			PetSmart = {
				order = 3,
				type = "toggle",
				name = L["Pet Smart"],
				get = function(info) return E.db.WindTools["Announce System"]["Taunt"]["PetSmart"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Taunt"]["PetSmart"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			OtherTankSmart = {
				order = 4,
				type = "toggle",
				name = L["Other Tank Smart"],
				get = function(info) return E.db.WindTools["Announce System"]["Taunt"]["OtherTankSmart"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Taunt"]["OtherTankSmart"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			IncludePet = {
				order = 5,
				type = "toggle",
				name = L["Include Pet"],
				get = function(info) return E.db.WindTools["Announce System"]["Taunt"]["IncludePet"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Taunt"]["IncludePet"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
			IncludeOthers = {
				order = 5,
				type = "toggle",
				name = L["Include Other Tank"],
				get = function(info) return E.db.WindTools["Announce System"]["Taunt"]["IncludeOtherTank"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["Taunt"]["IncludeOtherTank"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
		}
	}
	E.Options.args.WindTools.args["More Tools"].args["Announce System"].args["ResAndThreat"] = {
		order = 12,
		type = "group",
		name = L["Res And Threat"],
		guiInline = true,
		args = {
			Enable = {
				order = 1,
				type = "toggle",
				name = L["Enable"],
				get = function(info) return E.db.WindTools["Announce System"]["ResAndThreat"]["enabled"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["ResAndThreat"]["enabled"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
		}
	}
	E.Options.args.WindTools.args["More Tools"].args["Announce System"].args["ResThanks"] = {
		order = 13,
		type = "group",
		name = L["Res Thanks"],
		guiInline = true,
		args = {
			Enable = {
				order = 1,
				type = "toggle",
				name = L["Enable"],
				get = function(info) return E.db.WindTools["Announce System"]["ResThanks"]["enabled"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["ResThanks"]["enabled"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
		}
	}
	E.Options.args.WindTools.args["More Tools"].args["Announce System"].args["RaidUsefulSpells"] = {
		order = 14,
		type = "group",
		name = L["Raid Useful Spells"],
		guiInline = true,
		args = {
			Enable = {
				order = 1,
				type = "toggle",
				name = L["Enable"],
				get = function(info) return E.db.WindTools["Announce System"]["RaidUsefulSpells"]["enabled"] end,
				set = function(info, value) E.db.WindTools["Announce System"]["RaidUsefulSpells"]["enabled"] = value;E:StaticPopup_Show("PRIVATE_RL")end
			},
		}
	}
end

WT.ToolConfigs["Announce System"] = InsertOptions
E:RegisterModule(AnnounceSystem:GetName())
