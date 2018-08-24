-- 原作：TinyUntitled 的 Menu lua中的一段
-- loudsoul (http://bbs.ngacn.cc/read.php?tid=10240957)
-- 修改：houshuu
-------------------
-- 主要修改条目：
-- 模块化
-- 增加自定义功能设定项

local E, L, V, P, G = unpack(ElvUI)
local WT = E:GetModule("WindTools")
local EnhancedRCMenu = E:NewModule('EnhancedRCMenu');
local locale = GetLocale()

P["WindTools"]["Right-click Menu"] = {
	["enabled"] = true,
	["friend"] = {
		["ARMORY"] = true,
		["SEND_WHO"] = true,
		["NAME_COPY"] = true,
		["GUILD_ADD"] = true,
		["FRIEND_ADD"] = true,
		["MYSTATS"] = true,
		["ignoreReport"] = false,
	},
	["chat_roster"] = {
		["NAME_COPY"]  = true,
		["SEND_WHO"] = true,
		["FRIEND_ADD"] = true,
		["INVITE"] = true,
	},
	["guild"] = {
		["ARMORY"] = true,
		["NAME_COPY"] = true,
		["FRIEND_ADD"] = true,
	}
}

local function urlencode(s)
	s = string.gsub(s, "([^%w%.%- ])", function(c)
			return format("%%%02X", string.byte(c))
		end)
	return string.gsub(s, " ", "+")
end

local function gethost()
	local host = "http://us.battle.net/wow/en/character/"
	if (locale == "zhTW") then
		host = "http://tw.battle.net/wow/zh/character/"
	elseif (locale == "zhCN") then
		host = "http://www.battlenet.com.cn/wow/zh/character/"
	end
	return host
end

local function popupClick(self, info)
	local editBox
	local name, server = UnitName(info.unit)
	if (info.value == "ARMORY") then
		local armory = gethost() .. urlencode(server or GetRealmName()) .. "/" .. urlencode(name) .. "/advanced"
		editBox = ChatEdit_ChooseBoxForSend()
		ChatEdit_ActivateChat(editBox)
		editBox:SetText(armory)
		editBox:HighlightText()
	elseif (info.value == "NAME_COPY") then
		editBox = ChatEdit_ChooseBoxForSend()
		local hasText = (editBox:GetText() ~= "")
		ChatEdit_ActivateChat(editBox)
		editBox:Insert(name)
		if (not hasText) then editBox:HighlightText() end
	end
end

local friend_features = {
	"ARMORY",
	"MYSTATS",
	"NAME_COPY",
	"SEND_WHO",
	"FRIEND_ADD",
	"GUILD_ADD",
}
local cr_features = {
	"NAME_COPY",
	"SEND_WHO",
	"FRIEND_ADD",
	"INVITE",
}
local guild_features = {
	"ARMORY",
	"NAME_COPY",
	"FRIEND_ADD",
}

local UnitPopupButtonsExtra = {
	["ARMORY"] = L["Armory"],
	["SEND_WHO"] = L["Query Detail"],
	["NAME_COPY"] = L["Get Name"],
	["GUILD_ADD"] = L["Guild Invite"],
	["FRIEND_ADD"] = L["Add Friend"],
	["MYSTATS"] = L["Report MyStats"],
	["INVITE"] = L["Invite"],
}

function EnhancedRCMenu:Initialize()
	if not E.db.WindTools["Right-click Menu"]["enabled"] then return end

	-- 加入右键
	for k, v in pairs(UnitPopupButtonsExtra) do
		UnitPopupButtons[k] = {}
		UnitPopupButtons[k].text = v
	end
	-- 好友功能 载入
	for _, v in pairs(friend_features) do
		if E.db.WindTools["Right-click Menu"]["friend"][v] then
			tinsert(UnitPopupMenus["FRIEND"], 1, v)
		end
	end
	-- 聊天名单功能 载入
	for _, v in pairs(cr_features) do
		if E.db.WindTools["Right-click Menu"]["chat_roster"][v] then
			tinsert(UnitPopupMenus["CHAT_ROSTER"], 1, v)
		end
	end

	-- 公会功能 载入
	for _, v in pairs(guild_features) do
		if E.db.WindTools["Right-click Menu"]["guild"][v] then
			tinsert(UnitPopupMenus["GUILD"], 1, v)
			tinsert(UnitPopupMenus["COMMUNITIES_GUILD_MEMBER"], 1, v)
		end
	end

	-- 关闭回报功能解决错误
	if E.db.WindTools["Right-click Menu"]["chat_roster"]["ignoreReport"] then
		for k, v in pairs(UnitPopupMenus["FRIEND"]) do
			if v == "REPORT_PLAYER" then
				tremove(UnitPopupMenus["FRIEND"], k)
				break
			end
		end
	end

	-- 人物右键菜单
	for _, unit in pairs{"SELF","PLAYER","PARTY","RAID_PLAYER"} do
		for _, value in pairs{"ARMORY","NAME_COPY"} do
			tinsert(UnitPopupMenus[unit], 4, value)
		end
	end

	hooksecurefunc("UnitPopup_OnClick", function(self)
		local unit = UIDROPDOWNMENU_INIT_MENU.unit
		local name = UIDROPDOWNMENU_INIT_MENU.name
		local server = UIDROPDOWNMENU_INIT_MENU.server
		local fullname = name
		local editBox
		if (server and (not unit or UnitRealmRelationship(unit) ~= LE_REALM_RELATION_SAME)) then
			fullname = name .. "-" .. server
		end
		if (self.value == "ARMORY") then
			local armory = gethost() .. urlencode(server or GetRealmName()) .. "/" .. urlencode(name) .. "/advanced"
			editBox = ChatEdit_ChooseBoxForSend()
			ChatEdit_ActivateChat(editBox)
			editBox:SetText(armory)
			editBox:HighlightText()
		elseif (self.value == "MYSTATS") then
			local CRITICAL = TEXT_MODE_A_STRING_RESULT_CRITICAL or STAT_CRITICAL_STRIKE
			CRITICAL = gsub(CRITICAL, "[()]","")
			SendChatMessage(format("%s:%.1f %s:%s", ITEM_LEVEL_ABBR, select(2,GetAverageItemLevel()), HP, AbbreviateNumbers(UnitHealthMax("player"))), "WHISPER", nil, fullname)
			SendChatMessage(format(" - %s:%.2f%%", STAT_HASTE, GetHaste()), "WHISPER", nil, fullname)
			SendChatMessage(format(" - %s:%.2f%%", STAT_MASTERY, GetMasteryEffect()), "WHISPER", nil, fullname)
			--SendChatMessage(format(" - %s:%.2f%%", STAT_LIFESTEAL, GetLifesteal()), "WHISPER", nil, fullname)
			SendChatMessage(format(" - %s:%.2f%%", CRITICAL, max(GetRangedCritChance(), GetCritChance(), GetSpellCritChance(2))), "WHISPER", nil, fullname)
			SendChatMessage(format(" - %s:%.2f%%", STAT_VERSATILITY, GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)), "WHISPER", nil, fullname)
		elseif (self.value == "NAME_COPY") then
			editBox = ChatEdit_ChooseBoxForSend()
			local hasText = (editBox:GetText() ~= "")
			ChatEdit_ActivateChat(editBox)
			editBox:Insert(fullname)
			if (not hasText) then editBox:HighlightText() end
		elseif (self.value == "FRIEND_ADD") then
			AddFriend(fullname)
		elseif (self.value == "SEND_WHO") then
			SendWho("n-"..name)
		elseif (self.value == "GUILD_ADD") then
			GuildInvite(fullname)
		end
	end)
end

local function InsertOptions()
	-- 初始化空设定
	local Options = {
		friend = {
			order = 11,
			type = "group",
			name = L["Friend Menu"],
			guiInline = true,
			args = {}
		},
		chat_roster = {
			order = 12,
			type = "group",
			name = L["Chat Roster Menu"],
			guiInline = true,
			args = {}
		},
		guild = {
			order = 13,
			type = "group",
			name = L["Guild Menu"],
			guiInline = true,
			args = {}
		},
	}
	-- 循环载入设定
	for k, v in pairs(friend_features) do
		Options["friend"].args[v] = {
			order = k + 1,
			type = "toggle",
			name = UnitPopupButtonsExtra[v],
			get = function(info) return E.db.WindTools["Right-click Menu"]["friend"][v] end,
			set = function(info, value) E.db.WindTools["Right-click Menu"]["friend"][v] = value; E:StaticPopup_Show("PRIVATE_RL")  end,
		}
	end
	for k, v in pairs(cr_features) do
		Options["chat_roster"].args[v] = {
			order = k + 1,
			type = "toggle",
			name = UnitPopupButtonsExtra[v],
			get = function(info) return E.db.WindTools["Right-click Menu"]["chat_roster"][v] end,
			set = function(info, value) E.db.WindTools["Right-click Menu"]["chat_roster"][v] = value; E:StaticPopup_Show("PRIVATE_RL")  end,
		}
	end
	for k, v in pairs(guild_features) do
		Options["guild"].args[v] = {
			order = k + 1,
			type = "toggle",
			name = UnitPopupButtonsExtra[v],
			get = function(info) return E.db.WindTools["Right-click Menu"]["guild"][v] end,
			set = function(info, value) E.db.WindTools["Right-click Menu"]["guild"][v] = value; E:StaticPopup_Show("PRIVATE_RL")  end,
		}
	end

	Options["friend"].args.ignoreReport = {
		order = -1,
		type = "toggle",
		name = L["Disable REPORT to fix bug"],
		get = function(info) return E.db.WindTools["Right-click Menu"]["friend"]["ignoreReport"] end,
		set = function(info, value) E.db.WindTools["Right-click Menu"]["friend"]["ignoreReport"] = value; E:StaticPopup_Show("PRIVATE_RL")  end,
	}

	for k, v in pairs(Options) do
		E.Options.args.WindTools.args["Chat"].args["Right-click Menu"].args[k] = v
	end
end
WT.ToolConfigs["Right-click Menu"] = InsertOptions
E:RegisterModule(EnhancedRCMenu:GetName())
