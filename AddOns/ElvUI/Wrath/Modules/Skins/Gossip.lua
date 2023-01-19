local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local next = next
local gsub = gsub
local select = select
local strmatch = strmatch
local hooksecurefunc = hooksecurefunc

local function ReplaceGossipFormat(button, textFormat, text)
	local newFormat, count = gsub(textFormat, '000000', 'ffffff')
	if count > 0 then
		button:SetFormattedText(newFormat, text)
	end
end

local ReplacedGossipColor = {
	['000000'] = 'ffffff',
	['414141'] = '7b8489',
}

local function ReplaceGossipText(button, text)
	if text and text ~= '' then
		local newText, count = gsub(text, ':32:32:0:0', ':32:32:0:0:64:64:5:59:5:59')
		if count > 0 then
			text = newText
			button:SetFormattedText('%s', text)
		end

		local colorStr, rawText = strmatch(text, '|c[fF][fF](%x%x%x%x%x%x)(.-)|r')
		colorStr = ReplacedGossipColor[colorStr]
		if colorStr and rawText then
			button:SetFormattedText('|cff%s%s|r', colorStr, rawText)
		end
	end
end

function S:GossipFrame()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.gossip) then return end

	local GossipFrame = _G.GossipFrame
	S:HandleScrollBar(_G.ItemTextScrollFrameScrollBar)
	S:HandlePortraitFrame(GossipFrame, true)

	local GreetingPanel = _G.GossipFrame.GreetingPanel
	S:HandleTrimScrollBar(GreetingPanel.ScrollBar)
	S:HandleButton(GreetingPanel.GoodbyeButton, true)

	GreetingPanel:StripTextures()
	GreetingPanel:CreateBackdrop()
	GreetingPanel.backdrop:Point('TOPLEFT', GreetingPanel.ScrollBox, 0, 0)
	GreetingPanel.backdrop:Point('BOTTOMRIGHT', GreetingPanel.ScrollBox, 0, 80)

	GossipFrame.backdrop:ClearAllPoints()
	GossipFrame.backdrop:Point('TOPLEFT', GreetingPanel.ScrollBox, -10, 70)
	GossipFrame.backdrop:Point('BOTTOMRIGHT', GreetingPanel.ScrollBox, 40, 40)

	S:HandleNextPrevButton(_G.ItemTextNextPageButton)
	S:HandleNextPrevButton(_G.ItemTextPrevPageButton)

	if not E.private.skins.parchmentRemoverEnable then
		_G.ItemTextFrame:StripTextures()

		local spellTex = GreetingPanel:CreateTexture(nil, 'ARTWORK')
		spellTex:SetTexture([[Interface\QuestFrame\QuestBG]])
		spellTex:SetTexCoord(0, 0.586, 0.02, 0.655)
		spellTex:SetInside(GreetingPanel.backdrop)

		GreetingPanel.spellTex = spellTex
	else
		_G.QuestFont:SetTextColor(1, 1, 1)
		_G.ItemTextFrame:StripTextures(true)
		_G.ItemTextPageText:SetTextColor('P', 1, 1, 1)

		hooksecurefunc(_G.ItemTextPageText, 'SetTextColor', function(pageText, headerType, r, g, b)
			if r ~= 1 or g ~= 1 or b ~= 1 then
				pageText:SetTextColor(headerType, 1, 1, 1)
			end
		end)

		hooksecurefunc(GreetingPanel.ScrollBox, 'Update', function(frame)
			for _, button in next, { frame.ScrollTarget:GetChildren() } do
				if not button.IsSkinned then
					local buttonText = select(3, button:GetRegions())
					if buttonText and buttonText:IsObjectType('FontString') then
						ReplaceGossipText(button, button:GetText())
						hooksecurefunc(button, 'SetText', ReplaceGossipText)
						hooksecurefunc(button, 'SetFormattedText', ReplaceGossipFormat)
					end

					button.IsSkinned = true
				end
			end
		end)

		if GossipFrame.Background then
			GossipFrame.Background:Hide()
		end
	end

	_G.ItemTextFrame:SetTemplate('Transparent')
	_G.ItemTextScrollFrame:StripTextures()
end

S:AddCallback('GossipFrame')
