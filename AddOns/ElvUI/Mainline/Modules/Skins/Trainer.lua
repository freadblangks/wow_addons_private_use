local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local next, unpack = next, unpack

function S:Blizzard_TrainerUI()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.trainer) then return end

	for _, object in next, {
		_G.ClassTrainerScrollFrameScrollChild,
		_G.ClassTrainerFrameSkillStepButton,
		_G.ClassTrainerFrameBottomInset,
	} do
		object:StripTextures()
	end

	for _, texture in next, {
		_G.ClassTrainerFramePortrait,
		_G.ClassTrainerScrollFrameScrollBarBG,
		_G.ClassTrainerScrollFrameScrollBarTop,
		_G.ClassTrainerScrollFrameScrollBarBottom,
		_G.ClassTrainerScrollFrameScrollBarMiddle,
	} do
		texture:Kill()
	end

	for _, button in next, { _G.ClassTrainerTrainButton } do
		button:StripTextures()
		S:HandleButton(button)
	end

	local ClassTrainerFrame = _G.ClassTrainerFrame
	S:HandlePortraitFrame(ClassTrainerFrame)

	--[[for _, button in next, ClassTrainerFrame.scrollFrame.buttons do
		button:StripTextures()
		button:StyleButton()
		button.icon:SetTexCoord(unpack(E.TexCoords))
		button:CreateBackdrop()
		button.backdrop:SetOutside(button.icon)
		button.icon:SetParent(button.backdrop)
		button.selectedTex:SetColorTexture(1, 1, 1, 0.3)
		button.selectedTex:SetInside()
	end]]

	S:HandleTrimScrollBar(_G.ClassTrainerFrame.ScrollBar)
	S:HandleDropDownBox(_G.ClassTrainerFrameFilterDropDown, 155)

	ClassTrainerFrame:Height(ClassTrainerFrame:GetHeight() + 5)
	ClassTrainerFrame:SetTemplate('Transparent')

	local stepButton = _G.ClassTrainerFrameSkillStepButton
	stepButton:SetTemplate()
	stepButton.icon:SetTexCoord(unpack(E.TexCoords))
	stepButton.selectedTex:SetColorTexture(1,1,1,0.3)
	_G.ClassTrainerFrameSkillStepButtonHighlight:SetColorTexture(1,1,1,0.3)

	local ClassTrainerStatusBar = _G.ClassTrainerStatusBar
	ClassTrainerStatusBar:StripTextures()
	ClassTrainerStatusBar:SetStatusBarTexture(E.media.normTex)
	ClassTrainerStatusBar:CreateBackdrop()
	ClassTrainerStatusBar.rankText:ClearAllPoints()
	ClassTrainerStatusBar.rankText:Point('CENTER', ClassTrainerStatusBar, 'CENTER')
	E:RegisterStatusBar(ClassTrainerStatusBar)
end

S:AddCallbackForAddon('Blizzard_TrainerUI')
