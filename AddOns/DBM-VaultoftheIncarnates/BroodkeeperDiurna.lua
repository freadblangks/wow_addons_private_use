local mod	= DBM:NewMod(2493, "DBM-VaultoftheIncarnates", nil, 1200)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230117184100")
mod:SetCreatureID(190245)
mod:SetEncounterID(2614)
mod:SetUsedIcons(8, 7, 6, 5, 4)
mod:SetHotfixNoticeRev(20230117000000)
mod:SetMinSyncRevision(20221230000000)
mod.respawnTime = 33

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 376073 375871 388716 375870 375716 376272 376257 375485 375575 375457 375653 375630 388918 396269 396779 375475",
	"SPELL_CAST_SUCCESS 380175 375870 396269 181113",
	"SPELL_AURA_APPLIED 375889 375829 376073 378782 390561 376272 375487 375475 375620 375879 376330 396264 380483",
	"SPELL_AURA_APPLIED_DOSE 375829 378782 376272 375475 375879",
	"SPELL_AURA_REMOVED 376073 375809 376330 396264",
	"SPELL_AURA_REMOVED_DOSE 375809",
	"SPELL_PERIODIC_DAMAGE 390747",
	"SPELL_PERIODIC_MISSED 390747",
	"UNIT_DIED"
)

--TODO, add https://www.wowhead.com/beta/spell=388644/vicious-thrust ? it's instant cast but maybe a timer? depends how many adds there are. omitting for now to avoid clutter
--TODO, improve auto marking of the priority adds (like mages that need interrupt rotations)?
--TODO, what is range of tremors? does the mob turn while casting it? These answers affect warning defaults/filters, for now it's everyone
--[[
(ability.id = 376073 or ability.id = 375871 or ability.id = 388716 or ability.id = 388918 or ability.id = 375870 or ability.id = 376272 or ability.id = 375475 or ability.id = 375485 or ability.id = 396269 or ability.id = 396779) and type = "begincast"
 or ability.id = 380175 and type = "cast"
 or ability.id = 375879
 or (ability.id = 375716 or ability.id = 375653 or ability.id = 375457 or ability.id = 375630 or ability.id = 376257 or ability.id = 375575) and type = "begincast"
 or ability.id = 181113
--]]
--Stage One: The Primalist Clutch
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25119))
----Broodkeeper Diurna
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25120))
local warnEggsLeft								= mod:NewCountAnnounce(19873, 1)
local warnGreatstaffsWrath						= mod:NewTargetNoFilterAnnounce(375889, 2)
local warnClutchwatchersRage					= mod:NewStackAnnounce(375829, 2)
local warnRapidIncubation						= mod:NewSpellAnnounce(376073, 3)
local warnMortalWounds							= mod:NewStackAnnounce(378782, 2, nil, "Tank|Healer")
local warnDiurnasGaze							= mod:NewYouAnnounce(390561, 3)

local specWarnGreatstaffoftheBroodkeeper		= mod:NewSpecialWarningCount(375842, nil, nil, nil, 2, 2)
local specWarnGreatstaffsWrath					= mod:NewSpecialWarningYou(375889, nil, nil, nil, 1, 2)
local yellGreatstaffsWrath						= mod:NewYell(375889)
local specWarnWildfire							= mod:NewSpecialWarningDodge(375871, nil, nil, nil, 2, 2)
local specWarnIcyShroud							= mod:NewSpecialWarningCount(388716, nil, nil, nil, 2, 2)
local specWarnStormFissure						= mod:NewSpecialWarningDodge(396779, nil, nil, nil, 2, 2, 4)
local specWarnMortalStoneclaws					= mod:NewSpecialWarningDefensive(375870, nil, nil, nil, 1, 2)
local specWarnMortalWounds						= mod:NewSpecialWarningTaunt(378782, nil, nil, nil, 1, 2)
local specWarnGTFO								= mod:NewSpecialWarningGTFO(340324, nil, nil, nil, 1, 8)

local timerGreatstaffoftheBroodkeeperCD			= mod:NewCDCountTimer(24.4, 375842, L.staff, nil, nil, 5)--Shared CD ability?
local timerRapidIncubationCD					= mod:NewCDCountTimer(24.4, 376073, nil, nil, nil, 1)--Shared CD ability?
local timerWildfireCD							= mod:NewCDCountTimer(21.4, 375871, nil, nil, nil, 3)--21.4-28
local timerIcyShroudCD							= mod:NewCDCountTimer(39.1, 388716, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.MAGIC_ICON)--Static CD
local timerMortalStoneclawsCD					= mod:NewCDCountTimer(20.2, 375870, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)--Shared CD in P1, 7.3-15 P2
local timerStormFissureCD						= mod:NewCDTimer(24, 396779, nil, nil, nil, 3, nil, DBM_COMMON_L.MYTHIC_ICON)
--local berserkTimer							= mod:NewBerserkTimer(600)

mod:GroupSpells(375842, 375889)--Greatstaff spawn ith greatstaff wrath debuff
mod:GroupSpells(375870, 378782)--Mortal Claws with Mortal Wounds
----Primalist Reinforcements
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25129))
local warnBurrowingStrike						= mod:NewStackAnnounce(376272, 2, nil, "Tank|Healer")
local warnCauterizingFlashflames				= mod:NewCastAnnounce(375485, 4)
local warnFlameSentry							= mod:NewCastAnnounce(375575, 3)
local warnRendingBite							= mod:NewStackAnnounce(375475, 2, nil, "Tank|Healer")
local warnChillingTantrum						= mod:NewCastAnnounce(375457, 3)
local warnIonizingCharge						= mod:NewTargetAnnounce(375630, 3)

local specWarnPrimalistReinforcements			= mod:NewSpecialWarningAddsCount(257554, "-Healer", nil, nil, 1, 2)
local specWarnIceBarrage						= mod:NewSpecialWarningInterruptCount(375716, "HasInterrupt", nil, nil, 1, 2)
local specWarnBurrowingStrike					= mod:NewSpecialWarningDefensive(376272, nil, nil, nil, 1, 2, 3)
local specWarnTremors							= mod:NewSpecialWarningDodge(376257, nil, nil, nil, 2, 2)
local specWarnCauterizingFlashflames			= mod:NewSpecialWarningDispel(375487, "MagicDispeller", nil, nil, 1, 2)
local specWarnRendingBite						= mod:NewSpecialWarningDefensive(375475, nil, nil, nil, 1, 2, 3)
local specWarnStaticJolt						= mod:NewSpecialWarningInterruptCount(375653, "HasInterrupt", nil, nil, 1, 2)
local specWarnIonizingCharge					= mod:NewSpecialWarningMoveAway(375630, nil, nil, nil, 1, 2)
local yellIonizingCharge						= mod:NewYell(375630)

local timerPrimalistReinforcementsCD			= mod:NewAddsCustomTimer(60, 257554, nil, nil, nil, 1)
local timerBurrowingStrikeCD					= mod:NewCDTimer(8.1, 376272, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEROIC_ICON)
local timerTremorsCD							= mod:NewCDTimer(11, 376257, nil, nil, nil, 3)
local timerCauterizingFlashflamesCD				= mod:NewCDTimer(11.7, 375485, nil, "MagicDispeller", nil, 5)
local timerFlameSentryCD						= mod:NewCDTimer(12.2, 375575, nil, nil, nil, 3)
local timerRendingBiteCD						= mod:NewCDTimer(11, 375475, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEROIC_ICON)
local timerChillingTantrumCD					= mod:NewCDTimer(11.1, 375457, nil, nil, nil, 3)
local timerIonizingChargeCD						= mod:NewCDTimer(10, 375630, nil, nil, nil, 3)

--mod:AddRangeFrameOption("8")
--mod:AddInfoFrameOption(361651, true)
mod:AddNamePlateOption("NPFixate", 376330, true)
mod:AddSetIconOption("SetIconOnMages", "ej25144", true, true, {6, 5, 4})
mod:AddSetIconOption("SetIconOnStormbringers", "ej25139", true, true, {8, 7})

mod:GroupSpells(375485, 375487)--Cauterizing Flashflames cast and dispel IDs
mod:GroupSpells(385618, "ej25144", "ej25139")--Icon Marking with general adds announce
--Stage Two: A Broodkeeper Scorned
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25146))
local warnBroodkeepersFury						= mod:NewStackAnnounce(375879, 2)
local warnEGreatstaffsWrath						= mod:NewTargetNoFilterAnnounce(380483, 2)

local specWarnEGreatstaffoftheBroodkeeper		= mod:NewSpecialWarningCount(380176, nil, nil, nil, 2, 2)
local specWarnEGreatstaffsWrath					= mod:NewSpecialWarningYou(380483, nil, nil, nil, 1, 2)
local yellEGreatstaffsWrath						= mod:NewYell(380483)
local specWarnFrozenShroud						= mod:NewSpecialWarningCount(388918, nil, nil, nil, 2, 2)
local specWarnMortalStoneSlam					= mod:NewSpecialWarningDefensive(396269, nil, nil, nil, 1, 2, 4)
local specWarnDetonatingStoneslam				= mod:NewSpecialWarningYou(396264, false, nil, nil, 1, 2, 4)--Bit redundant, so off by default
local yellDetonatingStoneslam					= mod:NewShortYell(396264, nil, nil, nil, "YELL")
local yellDetonatingStoneslamFades				= mod:NewShortFadesYell(396264, nil, nil, nil, "YELL")
local specWarnDetonatingStoneslamTaunt			= mod:NewSpecialWarningTaunt(396264, nil, nil, nil, 1, 2, 4)

local timerBroodkeepersFuryCD					= mod:NewNextCountTimer(30, 375879, nil, nil, nil, 5)--Static CD
local timerEGreatstaffoftheBroodkeeperCD		= mod:NewCDCountTimer(24.4, 380176, L.staff, nil, nil, 5)--Shared CD ability
local timerFrozenShroudCD						= mod:NewCDCountTimer(40.5, 388918, nil, nil, nil, 2, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.MAGIC_ICON)--Static CD
local timerMortalStoneSlamCD					= mod:NewCDCountTimer(20.7, 396269, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.MYTHIC_ICON)

local castsPerGUID = {}
mod.vb.staffCount = 0
mod.vb.icyCount = 0
mod.vb.addsCount = 0
mod.vb.tankCombocount = 0
mod.vb.wildFireCount = 0
mod.vb.incubationCount = 0
mod.vb.mageIcon = 6
mod.vb.StormbringerIcon = 8
mod.vb.eggsGone = false
local mythicAddsTimers	= {32.9, 14.7, 48.9, 14.4, 41.1, 18.9, 44.7, 15.3, 41.4, 18.2}
local heroicAddsTimers	= {36.4, 19.0, 36.6, 20.0, 44.1, 19.8, 36.8, 19.9, 43.1, 21.0, 35.7, 20.0}
local normalAddsTimers	= {35.6, 24.6, 36.6, 24.9, 43.1, 24.9, 36.5, 24.9, 43.1, 24.8}
local p2StaffMythic		= {0, 19, 17, 25, 24.5, 25, 31.9, 17.5, 31, 18.7, 25, 25}--Some of this pattern is accurate but it can change, need to figure out actual cause.

function mod:OnCombatStart(delay)
	table.wipe(castsPerGUID)
	self:SetStage(1)
	self.vb.tankCombocount = 0
	self.vb.staffCount = 0
	self.vb.icyCount = 0
	self.vb.addsCount = 0
	self.vb.wildFireCount = 0
	self.vb.incubationCount = 0
	self.vb.mageIcon = 6
	self.vb.StormbringerIcon = 8
	self.vb.eggsGone = false
	timerMortalStoneclawsCD:Start(3.2-delay, 1)
	timerWildfireCD:Start(8.2-delay, 1)
	if not self:IsEasy() then
		timerRapidIncubationCD:Start(14.3-delay, 1)
	end
	timerGreatstaffoftheBroodkeeperCD:Start(16.2-delay, 1)
	timerPrimalistReinforcementsCD:Start(self:IsMythic() and 32.9 or self:IsHeroic() and 36.4 or 35.6-delay, 1)
	timerIcyShroudCD:Start(26.2-delay, 1)
	if self.Options.NPFixate then
		DBM:FireEvent("BossMod_EnableHostileNameplates")
	end
	if self:IsMythic() then
		timerStormFissureCD:Start(28-delay)
		timerPrimalistReinforcementsCD:Start(32.9-delay, 1)
	else--Heroic and Normal
		timerPrimalistReinforcementsCD:Start(35.6-delay, 1)
	end
end

function mod:OnCombatEnd()
--	if self.Options.RangeFrame then
--		DBM.RangeCheck:Hide()
--	end
--	if self.Options.InfoFrame then
--		DBM.InfoFrame:Hide()
--	end
	if self.Options.NPFixate then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 376073 then
		self.vb.incubationCount = self.vb.incubationCount + 1
		warnRapidIncubation:Show(self.vb.incubationCount)
		if not self.vb.eggsGone then
			timerRapidIncubationCD:Start(24, self.vb.incubationCount+1)
		end
	elseif spellId == 375871 and self:AntiSpam(10, 1) then
		self.vb.wildFireCount = self.vb.wildFireCount + 1
		specWarnWildfire:Show()
		specWarnWildfire:Play("scatter")
		specWarnWildfire:ScheduleVoice(1.5, "watchstep")
		timerWildfireCD:Start(self:IsMythic() and 23 or self:IsHeroic() and 21.4 or 25, self.vb.wildFireCount+1)
	elseif spellId == 388716 then
		self.vb.icyCount = self.vb.icyCount + 1
		specWarnIcyShroud:Show(self.vb.icyCount)
		specWarnIcyShroud:Play("aesoon")
		timerIcyShroudCD:Start(self:IsMythic() and 41 or self:IsHeroic() and 39.1 or 44, self.vb.icyCount+1)
	elseif spellId == 388918 then
		self.vb.icyCount = self.vb.icyCount + 1
		specWarnFrozenShroud:Show(self.vb.icyCount)
		specWarnFrozenShroud:Play("aesoon")
		timerFrozenShroudCD:Start(nil, self.vb.icyCount+1)--40-45
	elseif spellId == 375870 then
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnMortalStoneclaws:Show()
			specWarnMortalStoneclaws:Play("defensive")
		end
	elseif spellId == 396269 then
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnMortalStoneSlam:Show()
			specWarnMortalStoneSlam:Play("defensive")
		end
	elseif spellId == 376272 then
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) then
			specWarnBurrowingStrike:Show()
			specWarnBurrowingStrike:Play("defensive")
		end
		if self:AntiSpam(1, spellId) then
			timerBurrowingStrikeCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 375475 then
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) then
			specWarnRendingBite:Show()
			specWarnRendingBite:Play("defensive")
		end
		if self:AntiSpam(1, spellId) then
			timerRendingBiteCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 376257 then
		if self:AntiSpam(1, spellId) then
			specWarnTremors:Show()
			specWarnTremors:Play("shockwave")
			timerTremorsCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 375485 then
		if self:AntiSpam(1, spellId) then
			warnCauterizingFlashflames:Show()
			timerCauterizingFlashflamesCD:Start(self:IsMythic() and 8.6 or 11.7, args.sourceGUID)--TODO, recheck heroic
		end
	elseif spellId == 375575 then
		if self:AntiSpam(1, spellId) then
			warnFlameSentry:Show()
			timerFlameSentryCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 375457 then
		if self:AntiSpam(1, spellId) then
			warnChillingTantrum:Show()
			timerChillingTantrumCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 375630 then
		if self:AntiSpam(1, spellId) then
			timerIonizingChargeCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 375716 then
		if not castsPerGUID[args.sourceGUID] then
			castsPerGUID[args.sourceGUID] = 0
			if self.Options.SetIconOnMages and self.vb.mageIcon > 5 then--Only use up to 3 icons
				self:ScanForMobs(args.sourceGUID, 2, self.vb.mageIcon, 1, nil, 12, "SetIconOnMages")
			end
			self.vb.mageIcon = self.vb.mageIcon - 1
		end
		castsPerGUID[args.sourceGUID] = castsPerGUID[args.sourceGUID] + 1
		local count = castsPerGUID[args.sourceGUID]
		if self:CheckInterruptFilter(args.sourceGUID, false, false) then--Count interrupt, so cooldown is not checked
			specWarnIceBarrage:Show(args.sourceName, count)
			if count < 6 then
				specWarnIceBarrage:Play("kick"..count.."r")
			else
				specWarnIceBarrage:Play("kickcast")
			end
		end
	elseif spellId == 375653 then
		if not castsPerGUID[args.sourceGUID] then
			castsPerGUID[args.sourceGUID] = 0
			if self.Options.SetIconOnStormbringers and self.vb.StormbringerIcon > 6 then--Only use up to 3 icons
				self:ScanForMobs(args.sourceGUID, 2, self.vb.StormbringerIcon, 1, nil, 12, "SetIconOnStormbringers")
			end
			self.vb.StormbringerIcon = self.vb.StormbringerIcon - 1
		end
		castsPerGUID[args.sourceGUID] = castsPerGUID[args.sourceGUID] + 1
		local count = castsPerGUID[args.sourceGUID]
		if self:CheckInterruptFilter(args.sourceGUID, false, false) then--Count interrupt, so cooldown is not checked
			specWarnStaticJolt:Show(args.sourceName, count)
			if count < 6 then
				specWarnStaticJolt:Play("kick"..count.."r")
			else
				specWarnStaticJolt:Play("kickcast")
			end
		end
	elseif spellId == 396779 then
		specWarnStormFissure:Show()
		specWarnStormFissure:Play("watchstep")
		timerStormFissureCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 380175 then
		self.vb.staffCount = self.vb.staffCount + 1
		if self.vb.phase == 1 then
			specWarnGreatstaffoftheBroodkeeper:Show(self.vb.staffCount)
			specWarnGreatstaffoftheBroodkeeper:Play("specialsoon")
			timerGreatstaffoftheBroodkeeperCD:Start(24.3, self.vb.staffCount+1)--24-29 in all difficulties
		else
			specWarnEGreatstaffoftheBroodkeeper:Show(self.vb.staffCount)
			specWarnEGreatstaffoftheBroodkeeper:Play("specialsoon")
			if self:IsMythic() then
				local timer = p2StaffMythic[self.vb.staffCount+1] or 17.5
				timerEGreatstaffoftheBroodkeeperCD:Start(timer, self.vb.staffCount+1)
			else
				timerEGreatstaffoftheBroodkeeperCD:Start(20.6, self.vb.staffCount+1)--20-27
			end
		end
	elseif spellId == 375870 then
		self.vb.tankCombocount = self.vb.tankCombocount + 1
		--Sometimes boss interrupts cast to cast another ability then starts cast over, so we start timer here
		local timer = ((self:IsEasy() or self.vb.phase == 1) and 22.4 or 7.3)-1.5
		timerMortalStoneclawsCD:Start(timer, self.vb.tankCombocount+1)
	elseif spellId == 396269 then
		self.vb.tankCombocount = self.vb.tankCombocount + 1
		--Sometimes boss interrupts cast to cast another ability then starts cast over, so we start timer here
		local timer = (self.vb.phase == 1 and 21.9 or 7.3)-1.5
		timerMortalStoneSlamCD:Start(timer, self.vb.tankCombocount+1)
	elseif spellId == 181113 and self:AntiSpam(10, 2) then
		self.vb.addsCount = self.vb.addsCount + 1
		self.vb.mageIcon = 6
		self.vb.StormbringerIcon = 8
		specWarnPrimalistReinforcements:Show(self.vb.addsCount)
		specWarnPrimalistReinforcements:Play("killmob")
		local timer = self:IsMythic() and mythicAddsTimers[self.vb.addsCount+1] or self:IsHeroic() and heroicAddsTimers[self.vb.addsCount+1] or self:IsEasy() and normalAddsTimers[self.vb.addsCount+1]
		if timer then
			timerPrimalistReinforcementsCD:Start(timer, self.vb.addsCount+1)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 375889 then
		warnGreatstaffsWrath:CombinedShow(2, args.destName)--Aggregated for now in case strat is to just pop multiple eggs and CD like fuck for Clutchwatcher's Rage
		if args:IsPlayer() then
			specWarnGreatstaffsWrath:Show()
			specWarnGreatstaffsWrath:Play("targetyou")
			yellGreatstaffsWrath:Yell()
		end
	elseif spellId == 380483 then
		warnEGreatstaffsWrath:CombinedShow(2, args.destName)--Aggregated for now in case strat is to just pop multiple eggs and CD like fuck for Clutchwatcher's Rage
		if args:IsPlayer() then
			specWarnEGreatstaffsWrath:Show()
			specWarnEGreatstaffsWrath:Play("targetyou")
			yellEGreatstaffsWrath:Yell()
		end
	elseif spellId == 375620 then
		warnIonizingCharge:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnIonizingCharge:Show()
			specWarnIonizingCharge:Play("range5")
			yellIonizingCharge:Yell()
		end
	elseif spellId == 396264 then
		if args:IsPlayer() then
			specWarnDetonatingStoneslam:Show()
			specWarnDetonatingStoneslam:Play("gathershare")
			yellDetonatingStoneslam:Yell()
			yellDetonatingStoneslamFades:Countdown(spellId)
		else
			specWarnDetonatingStoneslamTaunt:Show(args.destName)
			specWarnDetonatingStoneslamTaunt:Play("tauntboss")
		end
	elseif spellId == 375829 then
		warnClutchwatchersRage:Cancel()
		warnClutchwatchersRage:Schedule(3, args.destName, args.amount or 1)
	elseif spellId == 376330 then
		if args:IsPlayer() then
			if self.Options.NPFixate then
				DBM.Nameplate:Show(true, args.sourceGUID, spellId)
			end
		end
	elseif spellId == 378782 and not args:IsPlayer() then
		local amount = args.amount or 1
		local _, _, _, _, _, expireTime = DBM:UnitDebuff("player", spellId)
		local remaining
		if expireTime then
			remaining = expireTime-GetTime()
		end
		if self.vb.phase == 2 and (not remaining or remaining and remaining < 6.1) and not UnitIsDeadOrGhost("player") and not self:IsHealer() then
			specWarnMortalWounds:Show(args.destName)
			specWarnMortalWounds:Play("tauntboss")
		else
			warnMortalWounds:Show(args.destName, amount)
		end
	elseif spellId == 390561 and args:IsPlayer() then
		warnDiurnasGaze:Show()
	elseif spellId == 376272 and not args:IsPlayer() then
		local amount = args.amount or 1
		--local _, _, _, _, _, expireTime = DBM:UnitDebuff("player", spellId)
		--local remaining
		--if expireTime then
		--	remaining = expireTime-GetTime()
		--end
		--if (not remaining or remaining and remaining < 6.1) and not UnitIsDeadOrGhost("player") and not self:IsHealer() then
		--	specWarnMortalWounds:Show(args.destName)
		--	specWarnMortalWounds:Play("tauntboss")
		--else
			warnBurrowingStrike:Show(args.destName, amount)
		--end
	elseif spellId == 375475 and not args:IsPlayer() then
		local amount = args.amount or 1
		--local _, _, _, _, _, expireTime = DBM:UnitDebuff("player", spellId)
		--local remaining
		--if expireTime then
		--	remaining = expireTime-GetTime()
		--end
		--if (not remaining or remaining and remaining < 6.1) and not UnitIsDeadOrGhost("player") and not self:IsHealer() then
		--	specWarnMortalWounds:Show(args.destName)
		--	specWarnMortalWounds:Play("tauntboss")
		--else
			warnRendingBite:Show(args.destName, amount)
		--end
	elseif spellId == 375487 then
		specWarnCauterizingFlashflames:CombinedShow(1, args.destName)
		specWarnCauterizingFlashflames:ScheduleVoice(1, "helpldispel")
	elseif spellId == 375879 then
		local amount = args.amount or 1
		warnBroodkeepersFury:Show(args.destName, amount)
		timerBroodkeepersFuryCD:Start(30, amount+1)
		if self.vb.phase == 1 then
			self:SetStage(2)
			self.vb.wildFireCount = 0
			--Just stop outright
--			timerRapidIncubationCD:Stop()
			timerPrimalistReinforcementsCD:Stop()
			--Timers that do not reset.
			--Mortal Stone Claws, since we don't swap timers, no action needed
			--On mythic mortal claws swaps to mortal slam, doesn't change on heroic and below
			if self:IsMythic() then
				timerMortalStoneclawsCD:Stop()
				timerMortalStoneSlamCD:Start(15, 1)
				self.vb.tankCombocount = 0
				timerGreatstaffoftheBroodkeeperCD:Stop()
				timerEGreatstaffoftheBroodkeeperCD:Start(19, 1)
			else
				--Tank timer doesn't reset, just keeps going, staff timer doesn't restart, just swaps to new object
				local remainingStaff = timerGreatstaffoftheBroodkeeperCD:GetRemaining(self.vb.staffCount+1)
				if remainingStaff then
					timerGreatstaffoftheBroodkeeperCD:Stop()
					timerEGreatstaffoftheBroodkeeperCD:Start(remainingStaff, 1)--Does NOT restart anymore, even though on mythic it inherits a cast sequence, it still finishes out previous CD
				end
			end
			local remainingIcy = timerGreatstaffoftheBroodkeeperCD:GetRemaining(self.vb.icyCount+1)
			if remainingIcy then
				timerIcyShroudCD:Stop()
				timerFrozenShroudCD:Start(remainingIcy, 1)
			end
			self.vb.staffCount = 0
			self.vb.icyCount = 0--Reused for frozen shroud
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 375809 then
		local amount = args.amount or 0
		warnEggsLeft:Cancel()
		warnEggsLeft:Schedule(2, amount)
		if amount == 0 then
			self.vb.eggsGone = true
		end
	elseif spellId == 376330 then
		if args:IsPlayer() then
			if self.Options.NPFixate then
				DBM.Nameplate:Hide(true, args.sourceGUID, spellId)
			end
		end
	elseif spellId == 396264 then
		if args:IsPlayer() then
			yellDetonatingStoneslamFades:Cancel()
		end
	end
end
mod.SPELL_AURA_REMOVED_DOSE = mod.SPELL_AURA_REMOVED

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 191225 then--Tarasek Earthreaver
		timerBurrowingStrikeCD:Stop(args.destGUID)
		timerTremorsCD:Stop(args.destGUID)
	elseif cid == 192771 or cid == 191230 then--Dragonspawn Flamebender
		timerCauterizingFlashflamesCD:Stop(args.destGUID)
		timerFlameSentryCD:Stop(args.destGUID)
	elseif cid == 191222 then--Juvenile Frost Proto-Dragon
		timerRendingBiteCD:Stop(args.destGUID)
		timerChillingTantrumCD:Stop(args.destGUID)
	elseif cid == 191232 then--Drakonid Stormbringer
		timerIonizingChargeCD:Stop(args.destGUID)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 390747 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
