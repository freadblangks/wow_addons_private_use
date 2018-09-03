local SLE, T, E, L, V, P, G = unpack(select(2, ...))
if SLE._Compatibility["ElvUI_ChaoticUI"] then return end
local ES = SLE:NewModule('EnhancedShadows', 'AceEvent-3.0')
local AB, UF = SLE:GetElvModules("ActionBars", "UnitFrames")
local ClassColor = RAID_CLASS_COLORS[E.myclass]
local Border, LastSize
local Abars = SLE._Compatibility["ElvUI_ExtraActionBars"] and 10 or 6
--GLOBALS: hooksecurefunc
local _G = _G
local UnitAffectingCombat = UnitAffectingCombat

ES.shadows = {}

local UFrames = {
	{"player", "Player"},
	{"target", "Target"},
	{"targettarget", "TargetTarget"},
	{"focus", "Focus"},
	{"focustarget", "FocusTarget"},
	{"pet", "Pet"},
	{"pettarget", "PetTarget"},
}

local UGroups = {
	{"boss", "Boss", 5},
	{"arena", "Arena", 5},
}

function ES:UpdateShadows()
	if UnitAffectingCombat('player') then ES:RegisterEvent('PLAYER_REGEN_ENABLED', ES.UpdateShadows) return end

	for frame, _ in T.pairs(ES.shadows) do
		ES:UpdateShadow(frame)
	end
end

function ES:RegisterShadow(shadow, frame)
	if shadow.isRegistered then return end
	ES.shadows[shadow] = true
	shadow.isRegistered = true
end

function ES:UpdateFrame(frame, db)
	if not frame then return end
	local size = E.db.sle.shadows.size
	if frame.Health.EnhShadow then
		frame.Health.EnhShadow:SetOutside(frame.Health, size, size)
	end
	if frame.Power.EnhShadow then
		frame.Power.EnhShadow:SetOutside(frame.Power, size, size)
	end
	if frame.EnhShadow then
		frame.EnhShadow:SetOutside(frame, size, size)
	end
end

function ES:CreateFrameShadow(frame, parent)
	if not frame then return end
	--UF Health
	if frame.Health then
		frame.Health:CreateShadow()
		frame.Health.EnhShadow = frame.Health.shadow
		frame.Health.shadow = nil
		ES:RegisterShadow(frame.Health.EnhShadow)
		frame.Health.EnhShadow:SetParent(frame.Health)
	end
	--UF Power
	if frame.Power then
		frame.Power:CreateShadow()
		frame.Power.EnhShadow = frame.Power.shadow
		frame.Power.shadow = nil
		ES:RegisterShadow(frame.Power.EnhShadow)
		frame.Power.EnhShadow:SetParent(frame.Power)
	end
	--if it is not UF at all
	if not frame.Health and not frame.Power then
		frame:CreateShadow()
		frame.EnhShadow = frame.shadow
		frame.shadow = nil
		ES:RegisterShadow(frame.EnhShadow)
		if parent and parent ~= "none" then 
			frame.EnhShadow:SetParent(parent)
		elseif not parent then
			frame.EnhShadow:SetParent(frame)
		end
	end
end

function ES:CreateShadows()
	for i = 1, #UFrames do
		local unit, name = T.unpack(UFrames[i])
		if E.private.sle.module.shadows[unit] then
			ES:CreateFrameShadow(_G["ElvUF_"..name],_G["ElvUF_"..name])
			hooksecurefunc(UF, "Update_"..name.."Frame", ES.UpdateFrame)
		end
	end
	for i = 1, #UGroups do
		local unit, name, num = T.unpack(UGroups[i])
		if E.private.sle.module.shadows[unit] then
			for j = 1, num do
				ES:CreateFrameShadow(_G["ElvUF_"..name..j], _G["ElvUF_"..name..j])
				hooksecurefunc(UF, "Update_"..name.."Frames", ES.UpdateFrame)
			end
		end
	end
	for i=1, Abars do
		if E.private.sle.module.shadows.actionbars["bar"..i] then
			ES:CreateFrameShadow( _G["ElvUI_Bar"..i],  _G["ElvUI_Bar"..i].backdrop)
		end
		if E.private.sle.module.shadows.actionbars["bar"..i.."buttons"] then
			for j = 1, 12 do
				ES:CreateFrameShadow(_G["ElvUI_Bar"..i.."Button"..j], _G["ElvUI_Bar"..i.."Button"..j].backdrop)
			end
		end
	end
	if E.private.sle.module.shadows.actionbars.stancebar then
		ES:CreateFrameShadow(_G["ElvUI_StanceBar"], _G["ElvUI_StanceBar"].backdrop)
	end
	if E.private.sle.module.shadows.actionbars.stancebarbuttons then
		for i = 1, 12 do
			if not _G["ElvUI_StanceBarButton"..i] then break end
			ES:CreateFrameShadow(_G["ElvUI_StanceBarButton"..i], _G["ElvUI_StanceBarButton"..i].backdrop)
		end
	end
	if E.private.sle.module.shadows.actionbars.microbar then
		ES:CreateFrameShadow(_G["ElvUI_MicroBar"], "none")
	end
	if E.private.sle.module.shadows.actionbars.microbarbuttons then
		for i=1, (#MICRO_BUTTONS) do
			if not _G[MICRO_BUTTONS[i]] then break end
			ES:CreateFrameShadow(_G[MICRO_BUTTONS[i]], _G[MICRO_BUTTONS[i]].backdrop)
		end
	end
	if E.private.sle.module.shadows.actionbars.petbar then
		ES:CreateFrameShadow(_G["ElvUI_BarPet"], _G["ElvUI_BarPet"].backdrop)
	end
	if E.private.sle.module.shadows.actionbars.petbarbuttons then
		for i = 1, 12 do
			if not _G["PetActionButton"..i] then break end
			ES:CreateFrameShadow(_G["PetActionButton"..i], _G["PetActionButton"..i].backdrop)
		end
	end
	if E.private.sle.module.shadows.minimap then
		ES:CreateFrameShadow(_G["MMHolder"], "none")
	end
	if E.private.sle.module.shadows.chat.left then
		ES:CreateFrameShadow(_G["LeftChatPanel"], "none")
	end
	if E.private.sle.module.shadows.chat.right then
		ES:CreateFrameShadow(_G["RightChatPanel"], "none")
	end
end

function ES:UpdateShadow(shadow)
	local ShadowColor = E.db.sle.shadows.shadowcolor
	local r, g, b = ShadowColor['r'], ShadowColor['g'], ShadowColor['b']
	if E.db.sle.shadows.classcolor then r, g, b = ClassColor['r'], ClassColor['g'], ClassColor['b'] end

	local size = E.db.sle.shadows.size
	shadow:SetOutside(shadow:GetParent(), size, size)
	shadow:SetBackdrop({
		edgeFile = Border, edgeSize = E:Scale(size > 3 and size or 3),
		insets = {left = E:Scale(5), right = E:Scale(5), top = E:Scale(5), bottom = E:Scale(5)},
	})
	shadow:SetBackdropColor(r, g, b, 0)
	shadow:SetBackdropBorderColor(r, g, b, 0.9)
end

function ES:Initialize()
	if not SLE.initialized then return end
	Border = E.LSM:Fetch('border', 'ElvUI GlowBorder')
	ES:CreateShadows()
	ES:UpdateShadows()
	function ES:ForUpdateAll()
		ES:UpdateShadows()
	end
end

_G.EnhancedShadows = ES;

SLE:RegisterModule(ES:GetName())
