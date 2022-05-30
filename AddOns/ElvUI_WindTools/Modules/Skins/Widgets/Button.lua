local W, F, E, L = unpack(select(2, ...))
local LSM = E.Libs.LSM
local S = W.Modules.Skins
local WS = S.Widgets
local ES = E.Skins

local _G = _G

function WS:HandleButton(_, button)
    if not button or button.windWidgetSkinned then
        return
    end

    if not E.private.WT.skins.widgets then
        self:RegisterLazyLoad(
            button,
            function()
                self:HandleButton(nil, button)
            end
        )
    end

    if not E.private.WT.skins.enable or not E.private.WT.skins.widgets.button.enable then
        return
    end

    local db = E.private.WT.skins.widgets.button

    if db.text.enable then
        local text = button.Text or button.GetName and button:GetName() and _G[button:GetName() .. "Text"]
        if text and text.GetTextColor then
            F.SetFontWithDB(text, db.text.font)
        end
    end

    if db.backdrop.enable and (button.template or button.backdrop) then
        local parentFrame = button.backdrop or button

        -- Create background
        local bg = parentFrame:CreateTexture()
        bg:SetInside(parentFrame, 1, 1)
        bg:SetAlpha(0)
        bg:SetTexture(LSM:Fetch("statusbar", db.backdrop.texture) or E.media.normTex)

        if parentFrame.Center then
            local layer, subLayer = parentFrame.Center:GetDrawLayer()
            subLayer = subLayer and subLayer + 1 or 0
            bg:SetDrawLayer(layer, subLayer)
        end

        F.SetVertexColorWithDB(bg, db.backdrop.classColor and W.ClassColor or db.backdrop.color)

        local group, onEnter, onLeave =
            self.Animation(bg, db.backdrop.animationType, db.backdrop.animationDuration, db.backdrop.alpha)
        button.windAnimation = {
            bg = bg,
            group = group,
            onEnter = onEnter,
            onLeave = onLeave
        }

        self:SecureHookScript(button, "OnEnter", onEnter)
        self:SecureHookScript(button, "OnLeave", onLeave)

        -- Avoid the hook is flushed
        self:SecureHook(
            button,
            "SetScript",
            function(frame, scriptType)
                if scriptType == "OnEnter" then
                    self:Unhook(frame, "OnEnter")
                    self:SecureHookScript(frame, "OnEnter", onEnter)
                elseif scriptType == "OnLeave" then
                    self:Unhook(frame, "OnLeave")
                    self:SecureHookScript(frame, "OnLeave", onLeave)
                end
            end
        )

        if db.backdrop.removeBorderEffect then
            parentFrame.SetBackdropBorderColor = E.noop
        end
    end

    button.windWidgetSkinned = true
end

WS:SecureHook(ES, "HandleButton")
