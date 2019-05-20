-- CVars 快速编辑
-- 作者：houshuu
-------------------

local E, _, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local L = unpack(select(2, ...))
local WT = E:GetModule("WindTools")
local CVarsTool = E:NewModule('Wind_CVarsTool');

-- 将布尔值转换为部分值为 0/1 的 CVar，并设定
function CVarsTool.SetCVarBool(cvar, value)
	if value then
		SetCVar(cvar, 1)
	else
		SetCVar(cvar, 0)
	end
end

E:RegisterModule(CVarsTool:GetName())
