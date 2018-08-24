-- 作者：houshuu
---------------------------------------------------
-- 插件创建声明
---------------------------------------------------
local E, L, V, P, G = unpack(ElvUI);
local WT = E:NewModule('WindTools', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');
local EP = LibStub("LibElvUIPlugin-1.0")
local addonName, addonTable = ...
---------------------------------------------------
-- 缓存及提高代码可读性
---------------------------------------------------
local linebreak = "\n"
local format    = format
local gsub      = string.gsub
---------------------------------------------------
-- 初始化
---------------------------------------------------
-- 获取版本信息
WT.Version = GetAddOnMetadata(addonName, "Version")
-- 根据语言获取插件名
WT.Title = L["WindTools"]
-- 初始化设定
WT.ToolConfigs = {}
P["WindTools"] = {}
---------------------------------------------------
-- 常用函数
---------------------------------------------------
-- 摘自 ElvUI 源代码
-- 转换 RGB 数值为 16 进制
-- 此处 r, g, b 各值均为 0~1 之间
local function RGBToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return format("%02x%02x%02x", r*255, g*255, b*255)
end
-- 改自 ElvUI_CustomTweaks
-- 为字符串添加自定义颜色
function WT:ColorStr(str, r, g, b)
	local hex
	local coloredString
	
	if r and g and b then
		hex = RGBToHex(r, g, b)
	else
		-- 默认设置为浅蓝色
		hex = RGBToHex(52/255, 152/255, 219/255)
	end
	
	coloredString = "|cff"..hex..str.."|r"
	return coloredString
end
-- 功能列表
local ToolsOrder = {
	["Interface"]  = 1,
	["Trade"]      = 2,
	["Chat"]       = 3,
	["Quest"]      = 4,
	["More Tools"] = 5,
}
local Tools = {
	["Trade"] = {
		{"Auto Delete", L["Enter DELETE automatically."], "bulleet", "houshuu"},
		{"Already Known", L["Change item color if learned before."], "ahak", "houshuu"},
	},
	["Interface"] = {
		{"Auto Buttons", L["Add two bars to contain questitem buttons and inventoryitem buttons."], "EUI", "SomeBlu"},
		{"Minimap Buttons", L["Add a bar to contain minimap buttons."], "ElvUI Enhanced", "houshuu"},
		{"iShadow", L["Movie effect for WoW."], "iShadow", "houshuu"},
		{"Raid Progression", L["Add progression info to tooltip."], "ElvUI Enhanced", "houshuu"},
		{"EasyShadow", L["Add shadow to frames."], "houshuu", "houshuu"},
		{"Enhanced World Map", L["Customize your world map."], "houshuu", "houshuu"},
		{"Dragon Overlay", L["Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite"], "Azilroka", "houshuu"},
	},
	["Chat"] = {
		{"Enhanced Friend List", L["Customize friend frame."], "ProjectAzilroka", "houshuu"},
		{"Right-click Menu", L["Enhanced right-click menu"], "loudsoul", "houshuu"},
		{"Tab Chat Mod", L["Use tab to switch channel."], "EUI", "houshuu"},
	},
	["Quest"] = {
	    {"Quest List Enhanced", L["Add the level information in front of the quest name."], "wandercga", "houshuu"},
		{"Quest Announcment", L["Let you know quest is completed."], "EUI", "houshuu"},
	    {"Close Quest Voice", L["Disable TalkingHeadFrame."], "houshuu", "houshuu"},
		{"Objective Progress", L["Add quest/mythic+ dungeon progress to tooltip."], "Simca", "houshuu"},
	},
	["More Tools"] = {
		{"Announce System", L["A simply announce system."], "Shestak", "houshuu"},
		{"CVarsTool", L["Setting CVars easily."], "houshuu", "houshuu"},
		{"Enter Combat Alert", L["Alert you after enter or leave combat."], "loudsoul", "houshuu"},
		{"Fast Loot", L["Let auto-loot quickly."], "Leatrix", "houshuu"},
		{"Enhanced Blizzard Frame", L["Move frames and set scale of buttons."], "ElvUI S&L", "houshuu"},
		{"Enhanced Tag", L["Add some tags."], "houshuu", "houshuu"},
	}
}

function WT:InsertOptions()
	-- 感谢名单
	local WindToolsCreditList = {
		"Blazeflack",
		"Elv",
		"Leatrix",
		"bulleet",
		"ahak",
		"Simca",
		"EUI",
		"wandercga",
		"Leatrix",
		"iShadow",
		"Masque",
	}
	E.Options.args.WindTools = {
		-- 插件基本信息
		order = 2,
		type = "group",
		name = WT.Title,
		args = {
			titleimage = {
				order = 1,
				type = "description",
				name = "",
				image = function(info) return "Interface\\Addons\\ElvUI_WindTools\\Texture\\WindTools.blp", 512, 128 end,
			},
			header1 = {
				order = 2,
				type = "header",
				name = format(L["%s version: %s"], WT.Title, WT.Version),
			},		
			description1 = {
				order = 3,
				type  = "description",
				name  = format(L["%s is a collection of useful tools."], WT.Title),
			},
			spacer1 = {
				order = 4,
				type  = "description",
				name  = "\n",
			},
			header2 = {
				order = 5,
				type  = "header",
				name  = L["Release / Update Link"],
			},
			ngapage = {
				order = 6,
				type  = "input",
				width = "full",
				name  = L["You can use the following link to get more information (in Chinese)"],
				get   = function(info) return "http://bbs.ngacn.cc/read.php?tid=12142815" end,
				set   = function(info) return "http://bbs.ngacn.cc/read.php?tid=12142815" end,
			},
			spacer2 = {
				order = 7,
				type  = "description",
				name  = "\n",
			},
			header3 = {
				order = 8,
				type  = "header",
				name  = WT:ColorStr(L["Author"]),
			},
			author = {
				order = 9,
				type  = "description",
				name  = "|cffC79C6Ehoushuu @ NGA|r (|cff00FF96雲遊僧|r-語風)\nSomeBlu @ Github"
			},
			credit = {
				order = -1,
				type  = "group",
				name  = L["Credit List"],
				args  = {},
			},
		},
	}
	-- 生成感谢名单
	for i = 1, #WindToolsCreditList do
		local cname = WindToolsCreditList[i]
		E.Options.args.WindTools.args.credit.args[cname] = {
			order = i,
			type  = "description",
			name  = WindToolsCreditList[i],
		}
	end
	-- 生成功能相关设定列表
	for cat, tools in pairs(Tools) do
		E.Options.args.WindTools.args[cat] = {
			order       = ToolsOrder[cat],
			type        = "group",
			name        = L[cat],
			childGroups = "tab",
			args        = {}
		}
		local n = 0
		for _, tool in pairs(tools) do
			local tName   = tool[1]
			local tDesc   = tool[2]
			local oAuthor = tool[3]
			local cAuthor = tool[4]
			n = n + 1
			E.Options.args.WindTools.args[cat].args[tName] = {
				order = n,
				type  = "group",
				name  = L[tName],
				args  = {
					header1 = {
						order = 0,
						type  = "header",
						name  = L["Information"],
					},
					oriauthor = {
						order = 1,
						type  = "description",
						name  = format(L["Author: %s, Edited by %s"], oAuthor, cAuthor)
					},
					tooldesc = {
						order = 2,
						type  = "description",
						name  = tDesc
					},
					header2 = {
						order = 3,
						type  = "header",
						name  = L["Setting"],
					},
					enablebtn = {
						order = 4,
						type  = "toggle",
						width = "full",
						name  = WT:ColorStr(L["Enable"]),
						get   = function(info) return E.db.WindTools[tName]["enabled"] end,
						set   = function(info, value) E.db.WindTools[tName]["enabled"]     = value; E:StaticPopup_Show("PRIVATE_RL") end,
					}
				}
			}
		end
	end
	-- 加载功能内部函数设定
	-- TODO: 变更为性能更佳的载入方式
	for _, func in pairs(WT.ToolConfigs) do func() end
end
---------------------------------------------------
-- ElvUI 设定部分初始化
---------------------------------------------------
function WT:Initialize()
	EP:RegisterPlugin(addonName, WT.InsertOptions)
end
---------------------------------------------------
-- 注册 ElvUI 模块
---------------------------------------------------
E:RegisterModule(WT:GetName())
