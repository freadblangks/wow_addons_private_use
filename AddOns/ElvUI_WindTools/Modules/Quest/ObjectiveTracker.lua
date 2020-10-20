local W, F, E, L = unpack(select(2, ...))
local OT = W:NewModule("ObjectiveTracker", "AceHook-3.0", "AceEvent-3.0")

local _G = _G
local abs = abs
local format = format
local floor = floor
local ipairs = ipairs
local min = min
local pairs = pairs
local strmatch = strmatch
local tonumber = tonumber

local IsAddOnLoaded = IsAddOnLoaded
local ObjectiveTracker_Update = ObjectiveTracker_Update

local SystemCache = {
    TitleNormalColor = {
        r = _G.OBJECTIVE_TRACKER_COLOR["Header"].r,
        g = _G.OBJECTIVE_TRACKER_COLOR["Header"].g,
        b = _G.OBJECTIVE_TRACKER_COLOR["Header"].b
    },
    TitleHighlightColor = {
        r = _G.OBJECTIVE_TRACKER_COLOR["HeaderHighlight"].r,
        g = _G.OBJECTIVE_TRACKER_COLOR["HeaderHighlight"].g,
        b = _G.OBJECTIVE_TRACKER_COLOR["HeaderHighlight"].b
    }
}

local classColor = _G.RAID_CLASS_COLORS[E.myclass]

local color = {
    start = {
        r = 1.000,
        g = 0.647,
        b = 0.008
    },
    complete = {
        r = 0.180,
        g = 0.835,
        b = 0.451
    }
}

local function GetProgressColor(progress)
    local r = (color.complete.r - color.start.r) * progress + color.start.r
    local g = (color.complete.g - color.start.g) * progress + color.start.g
    local b = (color.complete.r - color.start.b) * progress + color.start.b

    -- 色彩亮度补偿
    local addition = 0.35
    r = min(r + abs(0.5 - progress) * addition, r)
    g = min(g + abs(0.5 - progress) * addition, g)
    b = min(b + abs(0.5 - progress) * addition, b)

    return {r = r, g = g, b = b}
end

function OT:ChangeQuestHeaderStyle()
    local frame = _G.ObjectiveTrackerFrame.MODULES
    if not self.db or not frame then
        return
    end

    for i = 1, #frame do
        local modules = frame[i]
        if modules and modules.Header and modules.Header.Text then
            F.SetFontWithDB(modules.Header.Text, self.db.header)
        end
    end
end

function OT:HandleTitleText(text)
    F.SetFontWithDB(text, self.db.title)
    local height = text:GetStringHeight() + 2
    if height ~= text:GetHeight() then
        text:SetHeight(height)
    end
end

function OT:HandleInfoText(text)
    self:ColorfulProgression(text)
    F.SetFontWithDB(text, self.db.info)
    text:SetHeight(text:GetStringHeight())

    local line = text:GetParent()
    local dash = line.Dash or line.Icon

    if self.db.noDash and dash then
        dash:Hide()
        text:ClearAllPoints()
        text:Point("TOPLEFT", dash, "TOPLEFT", 0, 0)
    else
        if dash.SetText then
            F.SetFontWithDB(dash, self.db.info)
        end
        dash:Show()
        text:ClearAllPoints()
        text:Point("TOPLEFT", dash, "TOPRIGHT", 0, 0)
    end
end

function OT:ChangeQuestFontStyle(_, block)
    if not self.db or not block then
        return
    end

    if block.HeaderText then
        self:HandleTitleText(block.HeaderText)
    end

    if block.currentLine then
        if block.currentLine.objectiveKey == 0 then -- 世界任务标题
            self:HandleTitleText(block.currentLine.Text)
        else
            self:HandleInfoText(block.currentLine.Text)
        end
    end
end

function OT:ScenarioObjectiveBlock_UpdateCriteria()
    if _G.ScenarioObjectiveBlock then
        local childs = {_G.ScenarioObjectiveBlock:GetChildren()}
        for _, child in pairs(childs) do
            if child.Text then
                self:HandleInfoText(child.Text)
            end
        end
    end
end

function OT:ColorfulProgression(text)
    if not self.db or not text then
        return
    end

    local info = text:GetText()
    if not info then
        return
    end

    local current, required, details = strmatch(info, "^(%d-)/(%d-) (.+)")

    if not (current and required and details) then
        details, current, required = strmatch(info, "(.+): (%d-)/(%d-)$")
    end

    if not (current and required and details) then
        return
    end

    local oldHeight = text:GetHeight()
    local progress = tonumber(current) / tonumber(required)

    if self.db.colorfulProgress then
        info = F.CreateColorString(current .. "/" .. required, GetProgressColor(progress))
        info = info .. " " .. details
    end

    if self.db.percentage then
        local percentage = format("[%.f%%]", progress * 100)
        if self.db.colorfulPercentage then
            percentage = F.CreateColorString(percentage, GetProgressColor(progress))
        end
        info = info .. " " .. percentage
    end

    text:SetText(info)
end

function OT:ChangeQuestTitleColor()
    if not IsAddOnLoaded("Blizzard_ObjectiveTracker") then
        return
    end

    local config = self.db.titleColor
    if not config then
        return
    end

    if config.enable and self.db.enable then
        _G.OBJECTIVE_TRACKER_COLOR["Header"] = {
            r = config.classColor and classColor.r or config.customColorNormal.r,
            g = config.classColor and classColor.g or config.customColorNormal.g,
            b = config.classColor and classColor.b or config.customColorNormal.b
        }

        _G.OBJECTIVE_TRACKER_COLOR["HeaderHighlight"] = {
            r = config.classColor and classColor.r or config.customColorHighlight.r,
            g = config.classColor and classColor.g or config.customColorHighlight.g,
            b = config.classColor and classColor.b or config.customColorHighlight.b
        }

        self.titleColorChanged = true
    elseif (not config.enable or not self.db.enable) and self.titleColorChanged then
        _G.OBJECTIVE_TRACKER_COLOR["Header"] = {
            r = SystemCache["TitleNormalColor"].r,
            g = SystemCache["TitleNormalColor"].g,
            b = SystemCache["TitleNormalColor"].b
        }

        _G.OBJECTIVE_TRACKER_COLOR["HeaderHighlight"] = {
            r = SystemCache["TitleHighlightColor"].r,
            g = SystemCache["TitleHighlightColor"].g,
            b = SystemCache["TitleHighlightColor"].b
        }

        self.titleColorChanged = false
    end

    ObjectiveTracker_Update()
end

function OT:UpdateTextWidth()
    if self.db.noDash then
        _G.OBJECTIVE_TRACKER_TEXT_WIDTH = _G.OBJECTIVE_TRACKER_LINE_WIDTH - 12
    else
        _G.OBJECTIVE_TRACKER_TEXT_WIDTH = _G.OBJECTIVE_TRACKER_LINE_WIDTH - _G.OBJECTIVE_TRACKER_DASH_WIDTH - 12
    end
end

function OT:Initialize()
    self.db = E.private.WT.quest.objectiveTracker
    if not self.db.enable then
        return
    end

    self:UpdateTextWidth()

    if not self.Initialized then
        local trackerModules = {
            _G.UI_WIDGET_TRACKER_MODULE,
            _G.BONUS_OBJECTIVE_TRACKER_MODULE,
            _G.WORLD_QUEST_TRACKER_MODULE,
            _G.CAMPAIGN_QUEST_TRACKER_MODULE,
            _G.QUEST_TRACKER_MODULE,
            _G.ACHIEVEMENT_TRACKER_MODULE
        }

        for _, module in pairs(trackerModules) do
            self:SecureHook(module, "AddObjective", "ChangeQuestFontStyle")
        end

        self:SecureHook("ObjectiveTracker_Update", "ChangeQuestHeaderStyle")
        self:SecureHook(_G.SCENARIO_CONTENT_TRACKER_MODULE, "UpdateCriteria", "ScenarioObjectiveBlock_UpdateCriteria")

        self.Initialized = true
    end

    self:ChangeQuestTitleColor()
end

W:RegisterModule(OT:GetName())
