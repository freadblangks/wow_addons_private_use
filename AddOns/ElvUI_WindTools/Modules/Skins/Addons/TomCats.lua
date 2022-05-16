local W, F, E, L = unpack(select(2, ...))
local S = W.Modules.Skins
local ES = E.Skins
local TT = E:GetModule("Tooltip")

local _G = _G
local pairs = pairs
local unpack = unpack

local GetItemQualityColor = GetItemQualityColor

local atlasToQuality = {
    ["auctionhouse-itemicon-border-gray"] = 0,
    ["auctionhouse-itemicon-border-white"] = 1,
    ["auctionhouse-itemicon-border-green"] = 2,
    ["auctionhouse-itemicon-border-blue"] = 3,
    ["auctionhouse-itemicon-border-purple"] = 4,
    ["auctionhouse-itemicon-border-orange"] = 5,
    ["auctionhouse-itemicon-border-artifact"] = 6,
    ["auctionhouse-itemicon-border-account"] = 8
}

local function HandleTomCatsIcon(icon)
    if not icon or not icon:IsShown() then
        return
    end

    if not icon.windStyle then
        local maskNum = icon.Icon:GetNumMaskTextures()
        for i = maskNum, 1 do
            icon.Icon:RemoveMaskTexture(icon.Icon:GetMaskTexture(i))
        end

        ES:HandleIcon(icon.Icon, true)
        icon.IconBorder:SetAlpha(0)
    end

    local atlas = icon.IconBorder:IsShown() and icon.IconBorder:GetAtlas()
    local quality = atlas and atlasToQuality[atlas]

    if quality then
        icon.Icon.backdrop:SetBackdropBorderColor(GetItemQualityColor(quality))
    else
        icon.Icon.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
    end

    if icon.CategoryIcon then
        icon.CategoryIcon:SetFrameLevel(icon:GetFrameLevel() + 2)
        HandleTomCatsIcon(icon.CategoryIcon)
    end
end

function S:TomCats_SkinTooltipItems(tt, owner)
    for _, item in pairs(tt.Loot) do
        HandleTomCatsIcon(item)
    end
end

function S:TomCats_HeaderCollapseButton_SetNormalAtlas(button, atlas)
    if atlas == "Campaign_HeaderIcon_Closed" then
        return button:SetNormalTexture(E.Media.Textures.PlusButton)
    elseif atlas == "Campaign_HeaderIcon_Open" then
        return button:SetNormalTexture(E.Media.Textures.MinusButton)
    end

    self.hooks[button].SetNormalAtlas(button, atlas)
end

function S:TomCats_HeaderCollapseButton_SetPushedAtlas(button, atlas)
    if atlas == "Campaign_HeaderIcon_ClosedPressed" then
        return button:SetPushedTexture(E.Media.Textures.PlusButton)
    elseif atlas == "Campaign_HeaderIcon_OpenPressed" then
        return button:SetPushedTexture(E.Media.Textures.MinusButton)
    end

    self.hooks[button].SetPushedAtlas(button, atlas)
end

function S:TomCats()
    if not E.private.WT.skins.enable or not E.private.WT.skins.addons.tomCats then
        return
    end

    TT:SetStyle(_G.TomCatsVignetteTooltip)
    self:SecureHook(_G.TomCatsVignetteTooltip, "SetOwner", "TomCats_SkinTooltipItems")

    if _G.TomCatsVignettesSection and _G.TomCatsVignettesSection.Header then
        local header = _G.TomCatsVignettesSection.Header
        self:RawHook(header, "SetNormalAtlas", "TomCats_HeaderCollapseButton_SetNormalAtlas", true)
        self:RawHook(header, "SetPushedAtlas", "TomCats_HeaderCollapseButton_SetPushedAtlas", true)
        header:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        header.SetHighlightTexture = E.noop
        header:Size(16, 16)
        header.topPadding = 16
        F.SetFontOutline(header.text)
    end
end

S:AddCallbackForAddon("TomCats")
