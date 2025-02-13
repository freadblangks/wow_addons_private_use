local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin
local GetHitModifier = GetHitModifier
local GetCombatRatingBonus = GetCombatRatingBonus
local STAT_HIT_CHANCE = STAT_HIT_CHANCE
local STAT_CATEGORY_ENHANCEMENTS = STAT_CATEGORY_ENHANCEMENTS
local CR_HIT_MELEE = CR_HIT_MELEE or 6
local CR_HIT_RANGED = CR_HIT_RANGED or 7

local displayString = ''

local function OnEvent(self)
	local hitRating = (E.Classic and GetHitModifier()) or GetCombatRatingBonus(E.myclass == 'HUNTER' and CR_HIT_RANGED or CR_HIT_MELEE) or 0
	if E.global.datatexts.settings.Hit.NoLabel then
		self.text:SetFormattedText(displayString, hitRating)
	else
		self.text:SetFormattedText(displayString, E.global.datatexts.settings.Hit.Label ~= '' and E.global.datatexts.settings.Hit.Label or STAT_HIT_CHANCE..': ', hitRating)
	end
end

local function ValueColorUpdate(self, hex)
	displayString = strjoin('', E.global.datatexts.settings.Hit.NoLabel and '' or '%s', hex, '%.'..E.global.datatexts.settings.Hit.decimalLength..'f%%|r')

	OnEvent(self)
end

DT:RegisterDatatext('Hit', STAT_CATEGORY_ENHANCEMENTS, { 'UNIT_STATS', 'UNIT_AURA' }, OnEvent, nil, nil, nil, nil, STAT_HIT_CHANCE, nil, ValueColorUpdate)
