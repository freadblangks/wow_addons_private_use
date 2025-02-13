local UPDATE_PORTRAIT_DELAY = 0.2;


local _, addon = ...

local API = addon.API;
local StatManager = addon.StatManager;
local HotkeyManager = addon.HotkeyManager;

local FadeFrame = NarciFadeUI.Fade;
local TransitionAPI = NarciAPI.TransitionAPI;

local C_BarberShop = C_BarberShop;
local SetCustomizationChoice = C_BarberShop.SetCustomizationChoice;
--C_BarberShop.SetViewingChrModel(chrModelID)   New API for Dragon Customization

local After = C_Timer.After;
local sin = math.sin;
local cos = math.cos;
local pi = math.pi;
local sqrt = math.sqrt;
local abs = math.abs;
local tremove = table.remove;
local tinsert = table.insert;
local unpack = unpack;
local wipe = wipe;

local IsMouseButtonDown = IsMouseButtonDown;
local GetMouseFocus = GetMouseFocus;
local PlaySound = PlaySound;

local function IsWidgetFocused(widget1, widget2)
    local focus = GetMouseFocus();
    if widget2 then
        return focus == widget1 or focus == widget2
    elseif widget1 then
        return focus == widget1
    end
end

local function linear(t, b, e, d)
	return (e - b) * t / d + b
end

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end


local L = Narci.L;
-----------------------------------------------

local MainFrame, MaleButtons, FemaleButtons, AlternateMaleButtons, AlternateFemaleButtons, EditButton, EditBox, DeleteButton, PlusButton, SettingFrame, SettingButton, LoadingFrame;
local BarbershopModel, ExportEditBox;
local BarberShopUI; --Blizzard BarberShopUI
local ACTIVE_BUTTON_POOL;

--[[
NarciBarberShopModelMixin = {};

local CameraUpdater = CreateFrame("Frame");

function CameraUpdater:ZoomTo(value)
    BarbershopModel:MakeCurrentCameraCustom();
    local currentDistance = BarbershopModel:GetCameraDistance();
    self.zoomDistance = value
    BarbershopModel:SetCameraDistance(value);
end

function NarciBarberShopModelMixin:OnLoad()
    self:SetUnit("player")
    self:SetLight(true, false, -0.707, 0, -0.707, 1, 1, 1, 1, 0.5, 1, 1, 1);
    self:SetCamera(0);
    self:SetPortraitZoom(0.9);
    self:SetAnimation(0, 0);
    self:SetPaused(true);
    self:SetKeepModelOnHide(true);
    
    local ScreenHeight = UIParent:GetHeight();
    self:SetSize(ScreenHeight, ScreenHeight)
    BarbershopModel = self;
    self:SetViewTranslation(0, -80);
    self:SetPosition(-0.5, 0.2, 0);
end

function NarciBarberShopModelMixin:OnShow()
    
end

function NarciBarberShopModelMixin:OnModelLoaded()
    self:SetPaused(true)
end

function NarciBarberShopModelMixin:ZoomTo(value)
    CameraUpdater:ZoomTo(value)
end
--]]



----------------------------------------------------------------------------------------------------
local CAMERA_PROFILES_BY_RACE = {
    --modelX, modelY, modelZ, facing
    bloodelf = {
        male = {3.38, 0.07, -1.88, 0.43},
        female = {3.54, -0.02, -1.75, 0.35},
    },

    voidelf = {
        male = {3.38, 0.07, -1.88, 0.43},
        female = {3.54, -0.02, -1.75, 0.35},
    },

    draenei = {
        male = {2.94, -0.19, -2.24, 0.43},
        female = {3.40, -0.09, -2.14, 0.35},
    },

    lightforgeddraenei = {
        male = {2.94, -0.19, -2.24, 0.43},
        female = {3.40, -0.09, -2.14, 0.35},
    },

    dwarf = {
        male = {3.24, -0.08, -1.34, 0.44},
        female = {3.43, -0.02, -1.34, 0.44}, 
    },

    darkirondwarf = {
        male = {3.24, -0.08, -1.34, 0.44},
        female = {3.43, -0.02, -1.34, 0.44}, 
    },

    gnome = {
        male = {3.23, -0.01, -0.92, 0.43},
        female = {3.37, -0.07, -0.9, 0.43},
    },

    mechagnome = {
        male = {3.23, -0.05, -0.93, 0.43},
        female = {3.37, -0.07, -0.9, 0.43},
    },

    goblin = {
        male = {3.24, 0, -1.08, 0.43},
        female = {3.40, -0.03, -1.14, 0.43},
    },

    human = {
        male = {3.38, -0.04, -1.87, 0.35},
        female = {3.51, -0.025, -1.745, 0.43},
    },

    kultiran = {
        male = {3.06, -0.05, -2.32, 0.43},
        female = {3.34, -0.01, -2.21, 0.43},
    },

    nightborne = {
        male = {3.37, 0.01, -2.26, 0.35},
        female = {3.40, 0.05, -2.09, 0.43},
    },

    nightelf = {
        male = {3.26, -0.07, -2.21, 0.43},
        female = {3.38, -0.06, -2.09, 0.43},
    },

    orc = {
        male = {2.79, -0.06, -1.84, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    uprightorc = {
        male = {3.11, -0.02, -2.08, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    magharorc = {
        male = {3.11, -0.02, -2.08, 0.35},
        female = {3.59, -0.02, -1.87, 0.35},
    },

    pandaren = {
        male = {3.14, -0.11, -2.11, 0.43},
        female = {3.1, -0.16, -1.95, 0.43},
    },

    tauren = {
        male = {1.97, -0.35, -2.2, 0.43},
        female = {2.86, -0.35, -2.4, 0.52},
    },

    highmountaintauren = {
        male = {1.97, -0.35, -2.2, 0.43},
        female = {2.86, -0.35, -2.4, 0.52},
    },

    troll = {
        male = {2.79, -0.19, -2.01, 0.43},
        female = {3.43, 0.035, -2.19, 0.35},
    },

    scourge = {
        male = {3.37, 0.03, -1.6, 0.43},
        female = {3.39, -0.035, -1.665, 0.43},
    },

    vulpera = {
        male = {3.33, -0.05, -1.09, 0.26},
        female = {3.33, -0.04, -1.09, 0.26},
    },

    worgen = {
        male = {2.41, -0.18, -1.93, 0.43},
        female = {3.06, -0.04, -2.19, 0.52},
    },

    zandalaritroll = {
        male = {3.16, 0.05, -2.55, 0.52},
        female = {3.35, 0.04, -2.51, 0.44},
    },

    dracthyr = {
        male = {3.1, -0.58, -2.6, 0.52},
        female = {3.1, -0.58, -2.6, 0.52},
    },
};


local HAS_ALTERNATE_FORM, IN_ALTERNATE_FORM = false, false;
local CAMEAR_KEY_TRUE_FORM;
local CAMEAR_KEY_ALTERNATE_FORM;

local RACE_WITH_ALTERNATE_FORM = {
    [22] = "human",       --worgen
    [52] = "bloodelf",    --dracthyr
    [70] = "bloodelf",    --dracthyr
};

do
    local _, _, raceID = UnitRace("player");
    if RACE_WITH_ALTERNATE_FORM[raceID] then
        CAMEAR_KEY_ALTERNATE_FORM = RACE_WITH_ALTERNATE_FORM[raceID];
        if raceID == 22 then
            CAMEAR_KEY_TRUE_FORM = "worgen"
        else
            CAMEAR_KEY_TRUE_FORM = "dracthyr"
        end
    end
end


local ALTERNATE_FORM_SAVED_ID = 220;   --custom
local MAX_SAVES = 10;
local NUM_ACTIVE_BUTTONS = 0;
local CAMERA_PROFILE;
local ACTIVE_CAMERA_PROFILE;
local SCROLLFRAME_CENTER_Y;

local function UpdateScrollButtonAlpha(buttons)
    local button;
    local alpha;
    local x, y, dy;

    for i = 1, NUM_ACTIVE_BUTTONS do
        button = buttons[i];
        x, y = button:GetCenter();
        dy = abs(y - SCROLLFRAME_CENTER_Y);
        if dy < 128 then
            alpha = 1;
            button:Show();
        else
            alpha = 1 - (dy - 128)/64;
            if alpha < 0 then
                alpha = 0;
                button:Hide();
            else
                button:Show();
                if alpha > 1 then
                    alpha = 1;
                end
            end
        end
        button:SetButtonAlpha(alpha);
    end
end

local ScrollButtonAlphaUpdater = CreateFrame("Frame");
ScrollButtonAlphaUpdater:Hide();
ScrollButtonAlphaUpdater.t = 0;
ScrollButtonAlphaUpdater.duration = 1/60;
ScrollButtonAlphaUpdater:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= self.duration then
        self.t = 0;
        UpdateScrollButtonAlpha(self.activeButtons);
    end
end);

function ScrollButtonAlphaUpdater:Start()
    self:Show();
end

function ScrollButtonAlphaUpdater:Stop()
    self:Hide();
end

function ScrollButtonAlphaUpdater:Refresh()
    UpdateScrollButtonAlpha(self.activeButtons);
end

function ScrollButtonAlphaUpdater:SetActiveButtonAlpha(alpha)
    for i = 1, NUM_ACTIVE_BUTTONS do
        self.activeButtons[i]:SetButtonAlpha(alpha);
    end
end

local ScrollBoundMarkUpdater = CreateFrame("Frame");
ScrollBoundMarkUpdater:Hide();
ScrollBoundMarkUpdater.t = 0;
ScrollBoundMarkUpdater.duration = 0.2;
ScrollBoundMarkUpdater.lastAlpha = 0;
ScrollBoundMarkUpdater:SetScript("OnUpdate", function(self, elapsed)
    local alpha = self.lastAlpha + 2 * elapsed;
    self.lastAlpha = alpha;
    if alpha >= self.toAlpha then
        alpha = self.toAlpha;
        self:Hide();
    end
    self.object1:SetAlpha(alpha);
    self.object2:SetAlpha(alpha);
end);

function ScrollBoundMarkUpdater:Start()
    self.lastAlpha = 0; --self.object1:GetAlpha();
    self.toAlpha = 0.5;
    self:Show();
end

function ScrollBoundMarkUpdater:Stop()
    self:Hide();
end

local function UpdateScrollBoundMark(ScrollFrame)
    --local ScrollFrame = MainFrame.activeCategory;
    local scrollValue = ScrollFrame.scrollBar:GetValue();
    local a, b = ScrollFrame.scrollBar:GetMinMaxValues();
    local isTop = scrollValue <= 0.1;
    local isBottom = scrollValue + 0.1 >= b;
    local numButtons = NUM_ACTIVE_BUTTONS or 0;
    ScrollFrame.BoundTop:SetShown(not isTop);
    ScrollFrame.BoundBottom:SetShown(not isBottom);
    
    ScrollFrame.BoundTop:SetAlpha(0);
    ScrollFrame.BoundBottom:SetAlpha(0);
    
    ScrollBoundMarkUpdater:Start();
end

local function UpdateScrollRange(ScrollFrame)
    if not ScrollFrame then
        ScrollFrame = MainFrame.activeCategory;
    end

    local range;
    local numButtons = NUM_ACTIVE_BUTTONS;
    if numButtons == 0 then
        range = 0;
    else
        range = (64 + 16) * numButtons -16 - ScrollFrame:GetHeight() + 14;   --the active sex is not neccessarily male, just use the male buttons for height referencing
        if range < 0 then
            range = 0;
        end
    end

    local scrollBar = ScrollFrame.scrollBar;
    scrollBar:SetMinMaxValues(0, range);
    ScrollFrame.range = range;
    scrollBar:SetShown(range ~= 0);

    UpdateScrollButtonAlpha(ScrollButtonAlphaUpdater.activeButtons);
    UpdateScrollBoundMark(ScrollFrame);

    if numButtons >= MAX_SAVES then
        PlusButton:SetCase(3);
    end
    PlusButton.numSaves = numButtons;
end

local function CreateSavedLooksButton(ScrollFrame, sex, isAlternateForm)
    local button;
    local buttons = {};
    local ScrollChild = ScrollFrame.ScrollChild;
    local buttonHeight = 64;
    local frameHeight = 4 * (buttonHeight + 16) - 2;
    ScrollFrame:SetSize(280, frameHeight);
    ScrollChild:SetSize(280, frameHeight);

    for i = 1, MAX_SAVES do
        button = CreateFrame("Button", nil, ScrollFrame.ClipFrame, "NarciBarberShopSavedLooksTemplate");
        tinsert(buttons, button);
        button:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 0, -8 + (buttonHeight + 16)*(1 - i));
        button.order = i;
        button:Hide();
    end

    local deltaRatio = 1;
    local speedRatio = 0.14;
    local range = buttons[1]:GetTop() - buttons[MAX_SAVES]:GetBottom() - ScrollFrame:GetHeight() + 14;
    local parentScrollFunc;
    local positionFunc = function(endValue, delta, scrollBar, isTop, isBottom)
        ScrollButtonAlphaUpdater:Start();
        ScrollFrame.BoundTop:SetShown(not isTop);
        ScrollFrame.BoundBottom:SetShown(not isBottom);
        ScrollBoundMarkUpdater:Stop();
        ScrollFrame.BoundTop:SetAlpha(0.0);
        ScrollFrame.BoundBottom:SetAlpha(0.0);
        ScrollFrame.BoundTop:StopAnimating();
        ScrollFrame.BoundBottom:StopAnimating();
    end;

    local onScrollFinishedFunc = function()
        ScrollButtonAlphaUpdater:Stop();
        ScrollBoundMarkUpdater:Start();
        ScrollFrame.BoundTop.BoundTopArrow.spring:Play();
        ScrollFrame.BoundBottom.BoundBottomArrow.spring:Play();
    end

    ScrollBoundMarkUpdater.object1 = ScrollFrame.BoundTop;
    ScrollBoundMarkUpdater.object2 = ScrollFrame.BoundBottom;

    NarciAPI_ApplySmoothScrollToScrollFrame(ScrollFrame, deltaRatio, speedRatio, positionFunc, (buttonHeight + 16), range, parentScrollFunc, onScrollFinishedFunc);


    if isAlternateForm then
        if sex == "male" then
            AlternateMaleButtons = buttons;
        else
            AlternateFemaleButtons = buttons;
        end
    else
        if sex == "male" then
            MaleButtons = buttons;
        else
            FemaleButtons = buttons;
        end
    end
end

local function GetOrcCameraProfile(model)
    local fileID = model:GetModelFileID();
    if fileID == 1968587 then
        --Upright
        return CAMERA_PROFILES_BY_RACE.uprightorc.male
    elseif fileID == 917116 then
        --Regular Orc and Maghar: 917116
        return CAMERA_PROFILES_BY_RACE.orc.male
    else
        return ACTIVE_CAMERA_PROFILE
    end
end

local function GetTrueFormCameraProfile(model)
    if IN_ALTERNATE_FORM then
        print(CAMEAR_KEY_ALTERNATE_FORM)
        return CAMERA_PROFILES_BY_RACE[CAMEAR_KEY_ALTERNATE_FORM].male
    else
        --[[
        local fileID = model:GetModelFileID();
        if fileID == 307453 then
            return CAMERA_PROFILES_BY_RACE.worgen.female
        elseif fileID == 307454 then
            return CAMERA_PROFILES_BY_RACE.worgen.male
        elseif fileID == 1000764 then
            return CAMERA_PROFILES_BY_RACE.human.female
        else
            return CAMERA_PROFILES_BY_RACE.human.male
        end--]]
        print(CAMEAR_KEY_TRUE_FORM)
        return CAMERA_PROFILES_BY_RACE[CAMEAR_KEY_TRUE_FORM].male
    end
end

local function UpdatePortraitCameraGeneric(model, profile)
    if not profile then
        profile = ACTIVE_CAMERA_PROFILE;
    end
    if not profile then return end;

    local modelX, modelY, modelZ, modelFacing = unpack(profile);
    if modelFacing then
        model:MakeCurrentCameraCustom();
        model:SetFacing(modelFacing);
        model:SetPosition(modelX, modelY, modelZ);
        local cameraX, cameraY, cameraZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 4, 0, 0);
        local targetX, targetY, targetZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 0, 0, 0);
        TransitionAPI.SetCameraPosition(model, cameraX, cameraY, cameraZ);
        TransitionAPI.SetCameraTarget(model, targetX, targetY, targetZ);
        return true
    end
end

local UpdatePortraitCamera = UpdatePortraitCameraGeneric;

local function UpdatePortraitCameraForOrc(model)
    UpdatePortraitCameraGeneric(model, GetOrcCameraProfile(model))
end

local function UpdatePortraitCameraForWorgen(model)
    UpdatePortraitCameraGeneric(model, GetTrueFormCameraProfile(model))
end



local DataProvider = {};
DataProvider.numMales = 0;
DataProvider.numFemales = 0;
DataProvider.numAlternateMales = 0;
DataProvider.numAlternateFemales = 0;
DataProvider.maleButtonOrder = {};
DataProvider.femaleButtonOrder = {};
DataProvider.alternateMaleButtonOrder = {};
DataProvider.alternateFemaleButtonOrder = {};

function DataProvider:GetCurrentSelection(customizationData, generateDescription)
    customizationData = customizationData or C_BarberShop.GetAvailableCustomizations();
    if not customizationData then
        return
    end
    local numCatetroy = #customizationData;
    local options, optionName, optionID, cuurentChoiceIndex, choice, choiceName, choiceID;
    local selectedOptions = {};
    local description = "";
    local addComma = false;

    local total = 0;

    for i = 1, numCatetroy do
        options = customizationData[i].options;
        local numOptions = #options;
        for j = 1, numOptions do
            optionName = options[j].name;
            optionID = options[j].id;
            cuurentChoiceIndex = options[j].currentChoiceIndex or 1;
            choice = options[j].choices[cuurentChoiceIndex];
            choiceName = choice.name or "";
            choiceID = choice.id;
            tinsert(selectedOptions, {optionID, choiceID} );
            total = total + 1;
            if generateDescription then
                if choiceName ~= "" and choiceName ~= "None" then
                    if addComma then
                        description = description..", ";
                    else
                        addComma = true;
                    end
                    description = description.. choiceName.." "..optionName;
                end
            end
        end
    end

    return selectedOptions, description
end

--sex 0 - Male 1- Female C_BarberShop.SetSelectedSex;

local RaceAtlas = {};

RaceAtlas.fixedRaceAtlasNames = {
    ["highmountaintauren"] = "highmountain",
    ["lightforgeddraenei"] = "lightforged",
    ["scourge"] = "undead",
    ["zandalaritroll"] = "zandalari",
};

RaceAtlas.alternateFormAtlasNames = {
    ["dracthyr"] = "dracthyrvisage",    --visage
    ["worgen"] = "human",
};

RaceAtlas.fixedModelAtlasNames = {
    --chrModelID
    [124] = "dragonriding-barbershop-icon-protodrake",
    [129] = "dragonriding-barbershop-icon-pterrodax",
    [123] = "dragonriding-barbershop-icon-drake",
    [126] = "dragonriding-barbershop-icon-wyvernspirit",
};

function RaceAtlas:GetAtlas(raceName, gender, useHiRez, alternateForm)
    if self.fixedModelAtlasNames[raceName] then
        return self.fixedModelAtlasNames[raceName]
    end

    if alternateForm and self.alternateFormAtlasNames[raceName] then
        raceName = self.alternateFormAtlasNames[raceName];
    end

    if (self.fixedRaceAtlasNames[raceName]) then
        raceName = self.fixedRaceAtlasNames[raceName];
    end

    local formatingString = useHiRez and "raceicon128-%s-%s" or "raceicon-%s-%s";
    return formatingString:format(raceName, gender);
end

--[[
local f = CreateFrame("Frame");
f:SetSize(96, 96);
f:SetPoint("CENTER", 0, 0);
local tex = f:CreateTexture(nil, "OVERLAY");
tex:SetAllPoints(true);
tex:SetAtlas( RaceAtlas:GetAtlas("dracthyr", "male", true, true) )
--]]


local function SetUpSavedLooksButton(buttonPool, dataSource, atlas)
    for i = 1, #dataSource do
        if i <= 4 then
            buttonPool[i]:Show();
        end
        buttonPool[i]:SetInfo(dataSource[i]);
        buttonPool[i].Portrait:SetAtlas(atlas);
    end
end

function DataProvider:LoadData()
    local raceID = API.GetPlayerRaceID();
    self.raceID = raceID or 1;

    if not NarciBarberShopDB then
        NarciBarberShopDB = {};
    end

    local DB = NarciBarberShopDB;

    --wipe(DB) --!!TEST
    
    if not DB.PlayerData then
        DB.PlayerData = {};
    end

    local unitType, realmID, playerID = string.split("-", UnitGUID("player"));
    if not DB.PlayerData[playerID] then
        local playerName = UnitName("player");
        local realmName = GetRealmName();
        DB.PlayerData[playerID] = { SavedLooks = {} , realmID = realmID, playerName = playerName, realmName = realmName};
    end

    local playerAppearanceDB = DB.PlayerData[playerID].SavedLooks;
    self.playerAppearanceDB = playerAppearanceDB;

    if not playerAppearanceDB[raceID] then
        playerAppearanceDB[raceID] = {male = {}, female = {}};
    end
    self.savedLooksByRace = playerAppearanceDB[raceID];

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    local raceName;
    if currentCharacterData then
        raceName = currentCharacterData.raceData.fileName;
    else
        raceName = "human";
    end

    raceName = string.lower(raceName);

    CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryMale, "male");
    CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryFemale, "female");
    
    --Worgen in human form. Dracthyr in visage form.
    if RACE_WITH_ALTERNATE_FORM[raceID] then
        HAS_ALTERNATE_FORM = true;
        local id = ALTERNATE_FORM_SAVED_ID;

        if not playerAppearanceDB[id] then
            playerAppearanceDB[id] = { male = {}, female = {} };
        end
        self.savedLooksInAlternateForm = playerAppearanceDB[id];
        CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryAlternateFormMale, "male", true);
        CreateSavedLooksButton(MainFrame.SavedLooksFrame.CategoryAlternateFormFemale, "female", true);

        local alternateMaleDB = playerAppearanceDB[id].male;
        local alternateFemaleDB = playerAppearanceDB[id].female;
        local numMales =  #alternateMaleDB;
        local numFemales = #alternateFemaleDB;
        self.numAlternateMales = numMales;
        self.numAlternateFemales = numFemales;
        local useHiRez = true;
        local raceAtlasMale = RaceAtlas:GetAtlas(raceName, "male", useHiRez, HAS_ALTERNATE_FORM);
        local raceAtlasFemale = RaceAtlas:GetAtlas(raceName, "female", useHiRez, HAS_ALTERNATE_FORM);
        --NarciDevReferencePortrait:SetAtlas(raceAtlasFemale);
        SetUpSavedLooksButton(AlternateMaleButtons, alternateMaleDB, raceAtlasMale);
        SetUpSavedLooksButton(AlternateFemaleButtons, alternateFemaleDB, raceAtlasFemale);
    end

    if CAMERA_PROFILES_BY_RACE[raceName] then
        CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE[raceName];
    else
        CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE["human"];
    end

    local useHiRez = true;
    
    local raceAtlasMale = RaceAtlas:GetAtlas(raceName, "male", useHiRez);
    local raceAtlasFemale = RaceAtlas:GetAtlas(raceName, "female", useHiRez);

    if raceName == "orc" or raceName == "magharorc" then
        UpdatePortraitCamera = UpdatePortraitCameraForOrc;
    end

    self.raceAtlasMale = raceAtlasMale;
    self.raceAtlasFemale = raceAtlasFemale;

    local maleDB = playerAppearanceDB[raceID].male;
    local femaleDB = playerAppearanceDB[raceID].female;
    local numMales =  #maleDB;
    local numFemales = #femaleDB;

    self.numMales = numMales;
    self.numFemales = numFemales;
    
    for i = 1, MAX_SAVES do
        self.maleButtonOrder[i] = i; 
        self.femaleButtonOrder[i] = i; 
        self.alternateMaleButtonOrder[i] = i;
        self.alternateFemaleButtonOrder[i] = i;
    end

    SetUpSavedLooksButton(MaleButtons, maleDB, raceAtlasMale);
    SetUpSavedLooksButton(FemaleButtons, femaleDB, raceAtlasFemale);
end

function DataProvider:GetRandomAppearance()
    local customizationData = C_BarberShop.GetAvailableCustomizations();
    if not customizationData then    --Not at the Barber
        return
    end

    local random = math.random;
    local selectedOptions = {};

    local option, options, optionName, optionID, cuurentChoiceIndex, choice, choiceName, choiceID;
    local numCatetroy = #customizationData;
    for i = 1, numCatetroy do
        options = customizationData[i].options;
        local numOptions = #options;
        for j = 1, numOptions do
            option = options[j];
            optionName = option.name;
            optionID = option.id;
            local numChoices = #option.choices;
            choice = option.choices[ random(numChoices) ]
            choiceID = choice.id;
            tinsert(selectedOptions, {optionID, choiceID} );
        end
    end

    return selectedOptions
end

function DataProvider:IsNewLooksUnique()
    local newLooks, generatedDescription = DataProvider:GetCurrentSelection();
    if not newLooks then
        return
    end
    local checkOnly = true;
    local isUnique = self:CheckAndSaveLooks(newLooks, nil, nil, checkOnly);
    return isUnique
end

function DataProvider:IsCharacterDataUnique(customizationData)
    local sex = self.currentSex or 0;
    local SavedLooks;
    local newLooks = self:GetCurrentSelection(customizationData);
    
    if HAS_ALTERNATE_FORM then
        if IN_ALTERNATE_FORM then
            if sex == 0 then
                SavedLooks = self.savedLooksInAlternateForm.male;
            else
                SavedLooks = self.savedLooksInAlternateForm.female;
            end
        else
            if sex == 0 then
                SavedLooks = self.savedLooksByRace.male;
            else
                SavedLooks = self.savedLooksByRace.female;
            end
        end
    else
        if sex == 0 then
            SavedLooks = self.savedLooksByRace.male;
        else
            SavedLooks = self.savedLooksByRace.female;
        end
    end

    local isUnique = true;
    local tempTable = {};
    local numLooks = #SavedLooks;
    local data;
    local matchID;
    local profileName;

    for i = 1, numLooks do
        wipe(tempTable);
        data = SavedLooks[i].data;
        local numData = #data;
        for j = 1, numData do
            tempTable[ data[j][1] ] = data[j][2];
        end

        local numSame = 0;
        for j = 1, #newLooks do
            if tempTable[ newLooks[j][1] ] == newLooks[j][2] then
                numSame = numSame + 1;
            end
        end

        if numSame == numData then
            isUnique = false;
            matchID = i;
            profileName = SavedLooks[i].name;
            break
        end
    end

    if isUnique then
        if numLooks < MAX_SAVES then
            PlusButton:SetCase(1);
        else
            PlusButton:SetCase(3);
        end
    else
        PlusButton:SetCase(2);
    end
    PlusButton.numSaves = numLooks;

    if ACTIVE_BUTTON_POOL then
        for i, portraitButton in ipairs(ACTIVE_BUTTON_POOL) do
            portraitButton:SetSelection(i == matchID);
        end
    end

    API.SetActiveAppearanceName(profileName);
end


function DataProvider:CheckAndSaveLooks(newLooks, generatedDescription, customName, checkOnly)
    if not newLooks then return false end;

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    if not currentCharacterData then return false end;
    
    local sex = currentCharacterData.sex;

    local SavedLooks;

    if HAS_ALTERNATE_FORM then
        if IN_ALTERNATE_FORM then
            if sex == 0 then
                SavedLooks = self.savedLooksInAlternateForm.male;
            else
                SavedLooks = self.savedLooksInAlternateForm.female;
            end
        else
            if sex == 0 then
                SavedLooks = self.savedLooksByRace.male;
            else
                SavedLooks = self.savedLooksByRace.female;
            end
        end
    else
        if sex == 0 then
            SavedLooks = self.savedLooksByRace.male;
        else
            SavedLooks = self.savedLooksByRace.female;
        end
    end

    local isUnique = true;
    local data;

    local tempTable = {};
    local numLooks = #SavedLooks;
    for i = 1, numLooks do
        wipe(tempTable);
        data = SavedLooks[i].data;
        local numData = #data;
        for j = 1, numData do
            tempTable[ data[j][1] ] = data[j][2];
        end

        local numSame = 0;
        for j = 1, #newLooks do
            if tempTable[ newLooks[j][1] ] == newLooks[j][2] then
                numSame = numSame + 1;
            end
        end

        if numSame == numData then
            isUnique = false;
            break
        end
    end

    wipe(tempTable);
    numLooks = numLooks + 1;

    if numLooks > MAX_SAVES then
        return false
    end

    local looksName = customName or ("New Look #"..(numLooks));
    if isUnique then
        if checkOnly then
            return true;
        else
            if numLooks < MAX_SAVES then
                PlusButton:SetCase(2);
            else
                PlusButton:SetCase(3);
            end
            local currentTime = time();
            tinsert(SavedLooks, 1, {name = looksName , description = generatedDescription, data = newLooks, timeCreated = currentTime});
            return SavedLooks[1], numLooks
        end
    else
        PlusButton:SetCase(2);
    end
    PlusButton.numSaves = numLooks;
end

function DataProvider:SaveNewLooks(customName)
    if NUM_ACTIVE_BUTTONS >= MAX_SAVES then
        return
    end
    local generateDescription = true;
    local newLooks, generatedDescription = DataProvider:GetCurrentSelection(nil, generateDescription);
    local data, numLooks = self:CheckAndSaveLooks(newLooks, generatedDescription, customName);
    if data then
        NUM_ACTIVE_BUTTONS = numLooks;
        if numLooks >= 4 then
            ScrollBoundMarkUpdater:Start();
        end

        return data
    else

    end
end

local function RepositionButtons(buttonPool)
    local _, relativeTo = buttonPool[1]:GetPoint();
    local buttonHeight = 64;
    local button;
    for i = 1, MAX_SAVES do
        --buttonPool[ orderTable[i] ]:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", 0, -8 + (buttonHeight + 16)*(1 - i));
        button = buttonPool[i];
        button:ClearAllPoints();
        button:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", 0, -8 + (buttonHeight + 16)*(1 - i));
        button.order = i;
    end
end

local function InsertButtonToTop(buttonPool, position)
    local removedButton = tremove(buttonPool, position);
    if removedButton then
        for i = #buttonPool, 1, -1  do
            buttonPool[i + 1] = buttonPool[i];
        end
        buttonPool[1] = removedButton;
        --RepositionButtons(buttonPool);
    end
end

function DataProvider:DeleteLooks(dataSource)
    if not dataSource then return end;
    local sex = self.currentSex;

    local SavedLooks, OrderTable, ButtonPool, categoryID;
    if HAS_ALTERNATE_FORM then
        if not IN_ALTERNATE_FORM then
            if sex == 0 then
                SavedLooks = self.savedLooksByRace.male;
                OrderTable = self.maleButtonOrder;
                ButtonPool = MaleButtons;
                categoryID = 1;
            else
                SavedLooks = self.savedLooksByRace.female;
                OrderTable = self.femaleButtonOrder;
                ButtonPool = FemaleButtons;
                categoryID = 2;
            end
        else
            if sex == 0 then
                SavedLooks = self.savedLooksInAlternateForm.male;
                OrderTable = self.alternateMaleButtonOrder;
                ButtonPool = AlternateMaleButtons;
                categoryID = 3;
            else
                SavedLooks = self.savedLooksInAlternateForm.female;
                OrderTable = self.alternateFemaleButtonOrder;
                ButtonPool = AlternateFemaleButtons;
                categoryID = 4;
            end
        end
    else
        if sex == 0 then
            SavedLooks = self.savedLooksByRace.male;
            OrderTable = self.maleButtonOrder;
            ButtonPool = MaleButtons;
            categoryID = 1;
        else
            SavedLooks = self.savedLooksByRace.female;
            OrderTable = self.femaleButtonOrder;
            ButtonPool = FemaleButtons;
            categoryID = 2;
        end
    end

    local numLooks = #SavedLooks;
    local position;
    for i = 1, numLooks do
        if SavedLooks[i] == dataSource then
            position = i;
            break
        end
    end
    if position then
        for i = position, numLooks do
            SavedLooks[i] = SavedLooks[i + 1];
        end

        local removedIndex = tremove(OrderTable, position);
        tinsert(OrderTable, removedIndex);

        local removedButton = tremove(ButtonPool, position);
        removedButton.isPortraitLoaded = false;
        removedButton.appearanceData = nil;
        tinsert(ButtonPool, removedButton);

        if categoryID == 1 then
            self.numMales = self.numMales - 1;
        elseif categoryID == 2 then
            self.numFemales = self.numFemales - 1;
        elseif categoryID == 3 then
            self.numAlternateMales = self.numAlternateMales - 1;
        elseif categoryID == 4 then
            self.numAlternateFemales = self.numAlternateFemales - 1;
        end
        NUM_ACTIVE_BUTTONS = NUM_ACTIVE_BUTTONS - 1;

        return ButtonPool, removedButton, position
    end
end

function DataProvider:GetButton()
    local currentCharacterData =  C_BarberShop.GetCurrentCharacterData();
    if not currentCharacterData then
        print("Error: No Character Data");
        return
    end
    local sex = currentCharacterData.sex;
    if sex == 0 then
        if HAS_ALTERNATE_FORM then
            if not IN_ALTERNATE_FORM then
                self.numMales = self.numMales + 1;
                if self.numMales > MAX_SAVES then
                    self.numMales = MAX_SAVES;
                end
                InsertButtonToTop(MaleButtons, self.numMales);
                return MaleButtons[1], MaleButtons;
            else
                self.numAlternateMales = self.numAlternateMales + 1;
                if self.numAlternateMales > MAX_SAVES then
                    self.numAlternateMales = MAX_SAVES;
                end
                InsertButtonToTop(AlternateMaleButtons, self.numAlternateMales);
                return AlternateMaleButtons[1], AlternateMaleButtons;
            end
        else
            self.numMales = self.numMales + 1;
            if self.numMales > MAX_SAVES then
                self.numMales = MAX_SAVES;
            end
            InsertButtonToTop(MaleButtons, self.numMales);
            return MaleButtons[1], MaleButtons;
        end
    elseif sex == 1 then
        if HAS_ALTERNATE_FORM then
            if not IN_ALTERNATE_FORM then
                self.numFemales = self.numFemales + 1;
                if self.numFemales > MAX_SAVES then
                    self.numFemales = MAX_SAVES;
                end
                InsertButtonToTop(FemaleButtons, self.numFemales);
                return FemaleButtons[1], FemaleButtons;
            else
                self.numAlternateFemales = self.numAlternateFemales + 1;
                if self.numAlternateFemales > MAX_SAVES then
                    self.numAlternateFemales = MAX_SAVES;
                end
                local index = self.alternateFemaleButtonOrder[self.numAlternateFemales];
                InsertButtonToTop(AlternateFemaleButtons, self.numAlternateFemales);
                return AlternateFemaleButtons[1], AlternateFemaleButtons;
            end
        else
            self.numFemales = self.numFemales + 1;
            if self.numFemales > MAX_SAVES then
                self.numFemales = MAX_SAVES;
            end
            local index = self.femaleButtonOrder[self.numFemales];
            InsertButtonToTop(FemaleButtons, self.numFemales);
            return FemaleButtons[1], FemaleButtons;
        end
    else
        print("Error: Unknown Gender");
        return
    end
end


local function SetFontStringShadow(fontString)
    fontString:SetShadowColor(0, 0, 0);
    fontString:SetShadowOffset(1, -1);
end

-------------------------------------------------------------

local CustomizationUtil = {};
CustomizationUtil.f = CreateFrame("Frame");

function CustomizationUtil.repeater_OnUpdate(f, elapsed)
    --Dracthyr Notes:
    --some options are only valid when certain options are selected
    --so we need to apply the same appearance profile again to ensure everything we need is selected
    --Arbitrarily use a 2-frame delay

    f.t = f.t + elapsed;

    if f.t > 0.033 then
        f:SetScript("OnUpdate", nil);
        for i = 1, #CustomizationUtil.appearanceData do
            local optionID, choiceID = unpack(CustomizationUtil.appearanceData[i]);
            SetCustomizationChoice(optionID, choiceID);
        end
        BarberShopUI:UpdateCharCustomizationFrame();
    end
end

function CustomizationUtil:UseCustomization(appearanceData)
    --appearanceData consisted of formated optionID-choiceID pairs
    if not appearanceData then return end;

    self.f:SetScript("OnUpdate", nil);
    self.appearanceData = appearanceData;

    local optionID, choiceID;
    for i = 1, #appearanceData do
        optionID, choiceID = unpack(appearanceData[i]);
        SetCustomizationChoice(optionID, choiceID);
    end

    self.f.t = 0;
    self.f:SetScript("OnUpdate", self.repeater_OnUpdate);
end

function CustomizationUtil:ApplyCustomizationCategoryData(customizationCategoryData, firstCall)
    --customizationCategoryData is the raw payload from C_BarberShop.GetAvailableCustomizations()
    local optionID, cuurentChoiceIndex, choice, choiceID;
    for i, data in ipairs(customizationCategoryData) do
        for j, option in ipairs(data.options) do
            optionID = option.id;
            cuurentChoiceIndex = option.currentChoiceIndex or 1;
            choice = option.choices[cuurentChoiceIndex];
            choiceID = choice.id;
            SetCustomizationChoice(optionID, choiceID);
        end
    end

    if firstCall then
        After(0.033, function()
            self:ApplyCustomizationCategoryData(customizationCategoryData);
            DataProvider:IsCharacterDataUnique(customizationCategoryData);
        end);
    end
end


NarciBarberShopSavedLooksMixin = {};

local function PortaitModel_OnModelLoaded(self)
    self:SetCamera(0);
    self:SetAnimation(0, 0);
    self:SetPaused(true);
    local p = self:GetParent();
    p:SetPortraitZoom(0.975);
    p:SetPortraitZoom(1);
    p.isPortraitLoaded = true;
    self:SetIgnoreParentAlpha(true);
    LoadingFrame:LoadNextPortrait(p.order);
end

function NarciBarberShopSavedLooksMixin:OnLoad()
    self.Portrait:SetVertexColor(0.5, 0.5, 0.5);
    self.Portrait:SetDesaturation(0.6);
    SetFontStringShadow(self.Description);

    local model = self.Model;
    model:SetUnit("player");
    model:SetKeepModelOnHide(true);
    model:SetFacing(pi/24);
    TransitionAPI.SetModelLight(model, true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 0.5, 0.5, 0.5, 1, 0.9, 0.9, 0.9);
    model:SetCamera(0);
    self:SetPortraitZoom(1);
    model:SetAnimation(0, 0);
    model:SetPaused(true);
    model:SetScript("OnModelLoaded", PortaitModel_OnModelLoaded);
    model:SetViewTranslation(0, 0);

    self:OnLeave();
end

function NarciBarberShopSavedLooksMixin:SetPortraitZoom(value)
    self.Model:SetPortraitZoom(value);
    self.portraitZoom = value;
end

function NarciBarberShopSavedLooksMixin:GetPortraitZoom(value)
    return self.portraitZoom or 1;
end

function NarciBarberShopSavedLooksMixin:RefreshPortrait(forcedRefresh)
    if (not self.isPortraitLoaded) or (forcedRefresh) then
        self.Model:Show();
        self.Portrait:Hide();
        self.PortraitText:Hide();
        self.isPortraitLoaded = true;
        self.Model:SetUnit("player");
        UpdatePortraitCamera(self.Model);
    end
end

function NarciBarberShopSavedLooksMixin:UpdateText()
    local textHeight = self.Name:GetHeight() + self.Description:GetHeight() + 6;
    self.Reference:SetHeight(textHeight);
end

function NarciBarberShopSavedLooksMixin:SetInfo(dataSource)
    self.dataSource = dataSource;
    self.Name:SetText(dataSource.name);
    self.Description:SetText(dataSource.description);
    self.appearanceData = dataSource.data;
    self:UpdateText()
end

function NarciBarberShopSavedLooksMixin:OnEnter()
    self.Name:SetAlpha(1);
    self.Description:SetAlpha(1);
    FadeFrame(self.BorderHighlight, 0.15, 1);
    MainFrame:FadeIn(0.2);
    --self.Model:SetPaused(false);  --Playing character idle animation seems distractive, disabled

    EditButton:SetParentObject(self);
    DeleteButton:SetParentObject(self);
end

function NarciBarberShopSavedLooksMixin:OnLeave()
    if self:IsMouseOver() and IsWidgetFocused(self) then
        return
    end
    self.Name:SetAlpha(0.66);
    self.Description:SetAlpha(0.66);
    FadeFrame(self.BorderHighlight, 0.25, 0);
    MainFrame:OnLeave();

    EditButton:Hide();
    DeleteButton:Hide();
end

function NarciBarberShopSavedLooksMixin:OnClick()
    --self:UseCustomization();
    CustomizationUtil:UseCustomization(self.appearanceData);

    if not self.isPortraitLoaded then
        After(UPDATE_PORTRAIT_DELAY, function()
            self:RefreshPortrait();
        end)
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function NarciBarberShopSavedLooksMixin:LoadPortrait()
    self:UseCustomization(true);
    if not self.isPortraitLoaded then
        After(UPDATE_PORTRAIT_DELAY, function()
            self:RefreshPortrait();
        end)
    end
end

function NarciBarberShopSavedLooksMixin:UseCustomization(dontUpdateButton)
    if not self.appearanceData then return end

    local BarberShopUI = BarberShopUI;
    for i = 1, #self.appearanceData do
        local optionID, choiceID = unpack(self.appearanceData[i]);
        SetCustomizationChoice(optionID, choiceID);
        --C_BarberShop.PreviewCustomizationChoice(optionID, choiceID);
    end

    if not dontUpdateButton then
        --determine if it should update the option buttons on the right side of the screen
        BarberShopUI:UpdateCharCustomizationFrame();
    end
end

function NarciBarberShopSavedLooksMixin:SetSelection(state)
    if state then
        if not self.isSelected then
            self.isSelected = true;
            self.Border:SetTexCoord(0.5, 1, 0, 1);
        end
    else
        if self.isSelected then
            self.isSelected = nil;
            self.Border:SetTexCoord(0, 0.5, 0, 1);
        end
    end
end

if addon.IsDragonflight() then
    function NarciBarberShopSavedLooksMixin:SetButtonAlpha(alpha)
        --Dragonflight Beta: Model no longer inherts parent alpha.
        --Probably a driver issue that only took place in beta but still
        self:SetAlpha(alpha);
        self.Model:SetModelAlpha(alpha); --SetAlpha caused the model to flicker
        self.buttonAlpha = alpha;
    end
else
    function NarciBarberShopSavedLooksMixin:SetButtonAlpha(alpha)
        self:SetAlpha(alpha);
    end
end


----------------------------------
local DURATION_FADE_OUT = 1.5;

local autoHideTimer = NarciAPI_CreateAnimationFrame(4);
autoHideTimer:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        self.total = 0;
        if MainFrame:IsVisible() then
            if not MainFrame:IsMouseOver() then
                self:Hide();
                MainFrame:FadeOut(DURATION_FADE_OUT);
            end
        else
            self:Hide();
        end
    end
end)

local animScrollFrame = NarciAPI_CreateAnimationFrame(0.25);
animScrollFrame:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local offsetY = linear(self.total, self.fromY, 0, self.duration);
    if self.total >= self.duration then
        self:Hide();
        offsetY = 0;
        ScrollButtonAlphaUpdater:Stop();
        if self.onFinishedFunc then
            self.onFinishedFunc();
            self.onFinishedFunc = nil;
        end
    end
    self.parentScrollBar:SetValue(offsetY);
end);

function animScrollFrame:ScrollToTop(ScrollFrame)
    self:Hide();
    local value = ScrollFrame:GetVerticalScroll();
    if value == 0 then
        return
    end
    self.parentScrollBar = ScrollFrame.scrollBar;
    self.fromY = value;
    local duration = sqrt( value/ 400) * 0.25;
    self.duration = duration;
    ScrollButtonAlphaUpdater:Start();
    self:Show();
end


local animScrollButtons = NarciAPI_CreateAnimationFrame(0.4);

animScrollButtons:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local offsetY = outSine(self.total, self.fromY, self.toY, self.duration);

    if self.newButton then
        local alpha = self.total/0.35;
        if alpha > 1 then
            alpha = 1;
        end
        local offsetX = inOutSine(self.total, -32, 0, self.duration);
        self.newButton:Show();
        self.newButton:SetAlpha(alpha);
        if self.total >= self.duration then
            offsetX = 0;
            offsetY = self.toY;
        end
        self.newButton:SetPoint("TOPLEFT", self.relativeTo, "TOPLEFT", offsetX, -8);
    end

    if self.oldButton then
        local alpha = 1 - self.total/0.35;
        
        if alpha < 0 then
            alpha = 0;
            self.oldButton:Hide();
        end
        local offsetX = outSine(self.total, 0, -120, self.duration);
        self.oldButton:SetAlpha(alpha);
        if self.total >= self.duration then
            offsetX = -64;
        end
        self.oldButton:SetPoint("TOPLEFT", self.relativeTo, "TOPLEFT", offsetX, self.oldButtonPosY);
    end

    if self.forthButton then
        local alpha = self.fromAlpha - self.total/0.25;
        if alpha < 0 then
            alpha = 0;
        end
        self.forthButton:SetAlpha(alpha);
        if alpha == 0 then
            self.forthButton:Hide();
        end
    end

    if self.total >= self.duration then
        offsetY = self.toY;
        self:Hide();
        MainFrame.ScrollBlocker:Hide();
        RepositionButtons(self.buttonPool);
        UpdateScrollRange();
        ScrollButtonAlphaUpdater:Stop();
    end
    
    for i = self.buttonIndex, self.numButtons do
        self.buttonPool[i]:SetPoint("TOPLEFT", self.relativeTo, "TOPLEFT", 0, -8 + 80*(1 - i) + offsetY);
    end
end)

function animScrollButtons:InsertNewButton(buttonPool, newButton)
    self:Hide();
    local _, ScrollChild = buttonPool[1]:GetPoint();
    self.relativeTo = ScrollChild;
    self.buttonPool = buttonPool;
    self.numButtons = #buttonPool;
    self.buttonIndex = 2;
    self.newButton = newButton;
    self.forthButton = buttonPool[5];
    self.oldButton = nil;
    self.fromAlpha = self.forthButton:GetAlpha();
    self.fromY = 80;
    self.toY = 0;

    local ScrollFrame = ScrollChild:GetParent();
    if ScrollFrame:GetVerticalScroll() > 0.1 then
        --ScrollFrame.scrollBar:SetValue(0);
        animScrollFrame.onFinishedFunc = function()
            self:Show();
            EditBox:SetParentObject(newButton, true);
        end
        animScrollFrame:ScrollToTop(ScrollFrame);
    else
        self:Show();
    end
    MainFrame.ScrollBlocker:Show();
end

function animScrollButtons:RemoveOldButton(buttonPool, button)
    self:Hide();
    self.forthButton = nil;
    self.newButton = nil;
    self.oldButton = button;
    local _, ScrollChild, _, _, posY = button:GetPoint();
    self.oldButtonPosY = posY;
    self.buttonIndex = button.order;
    self.relativeTo = ScrollChild;
    self.buttonPool = buttonPool;
    self.numButtons = #buttonPool - 1;
    self.fromY = -80;
    self.toY = 0;
    self:Show();
    ScrollButtonAlphaUpdater:Start();
    MainFrame.ScrollBlocker:Show();
end


--Click to save new looks
NarciBarberShopPlusButtonMixin = {};

function NarciBarberShopPlusButtonMixin:OnLoad()
    PlusButton = self;
    self:OnLeave();
    self.tooltipDefault = L["Save New Look"];
    self.tooltipReachMax = L["No Available Slot"];
    self.tooltipSaved = L["Look Saved"];
    self.tooltipShapeShifted = L["Cannot Save Forms"];
    self:SetCase(1);
end

function NarciBarberShopPlusButtonMixin:OnMouseDown()
    if self:IsEnabled() then
        self.Background:SetTexCoord(0.25, 0.5, 0, 1);
    end
end

function NarciBarberShopPlusButtonMixin:OnMouseUp()
    if self:IsEnabled() then
        self.Background:SetTexCoord(0, 0.25, 0, 1);
    end
end

function NarciBarberShopPlusButtonMixin:OnEnable()
    self.Background:SetTexCoord(0, 0.25, 0, 1);
    self.Label:SetTextColor(1, 1, 1);
    self.Label:SetAlpha(0.66);
end

function NarciBarberShopPlusButtonMixin:OnDisable()
    self.Background:SetTexCoord(0.5, 0.75, 0, 1);
    self.Label:SetTextColor(0.5, 0.5, 0.5);
end

function NarciBarberShopPlusButtonMixin:SetCase(caseID)
    if caseID == 1 then
        --Can be added
        self.Label:SetText(self.tooltipDefault);
        self:Enable();
    elseif caseID == 2 then
        --Already saved
        self.Label:SetText(self.tooltipSaved);
        self:Disable();
    elseif caseID == 3 then
        --Cannot save more
        self.Label:SetText(self.tooltipReachMax);
        self:Disable();
    elseif caseID == 4 then
        --Cannot add shapes
        self.Label:SetText(self.tooltipShapeShifted);
        self:Disable();
    end

    self.caseID = caseID;
end

function NarciBarberShopPlusButtonMixin:GetCase()
    return self.caseID
end

function NarciBarberShopPlusButtonMixin:OnEnter()
    self.Label:SetAlpha(1);
    MainFrame:OnEnter();
    EditButton:Hide();
    DeleteButton:Hide();

    local labelWidth = self.Label:GetWrappedWidth();
    self.Count:SetPoint("LEFT", self.Label, "LEFT", labelWidth + 8, 0);
    if self.numSaves then
        self.Count:SetText(self.numSaves.." / "..MAX_SAVES);
        self.Count:Show();
    else
        self.Count:Hide();
    end
end

function NarciBarberShopPlusButtonMixin:OnLeave()
    self.Label:SetAlpha(0.66);
    self.Count:Hide();
end

local function SaveCurrentAppearance(customName)
    if not PlusButton:IsEnabled() then return end;

    local data = DataProvider:SaveNewLooks(customName);
    if data then
        local button, buttonPool = DataProvider:GetButton();
        if button then
            animScrollButtons:InsertNewButton(buttonPool, button);
            button:SetInfo(data);
            button:Show();
            EditBox:SetParentObject(button, true);
            After(UPDATE_PORTRAIT_DELAY, function()
                button:RefreshPortrait(true);
                button:SetSelection(true);
            end)
        end
        return true
    end
end

API.SaveCurrentAppearance = SaveCurrentAppearance;

function NarciBarberShopPlusButtonMixin:OnClick()
    --Save new Looks
    SaveCurrentAppearance();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function NarciBarberShopPlusButtonMixin:Glow()
    self.GlowTexture.AnimGlow:Play();
    self.GlowTexture:Show();
    --PlaySound(SOUNDKIT.MAP_PING);
    PlaySound(23404)
end


NarciBarberShopEditButtonMixin = {};

function NarciBarberShopEditButtonMixin:OnLoad()
    EditButton = self;
    self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
    self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    self.Ring:SetVertexColor(0.8, 0.8, 0.8);
    self.Tooltip:SetText(L["Edit Name"]);
    SetFontStringShadow(self.Tooltip);
end

function NarciBarberShopEditButtonMixin:SetParentObject(object)
    self:ClearAllPoints();
    self:SetParent(object);
    self:SetPoint("BOTTOMRIGHT", object, "RIGHT", 0, 0);
    self:Show();
end

function NarciBarberShopEditButtonMixin:EditName()
    EditBox:SetParentObject(self:GetParent());
end

function NarciBarberShopEditButtonMixin:OnClick()
    self:EditName();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function NarciBarberShopEditButtonMixin:OnEnter()
    self:GetParent():OnEnter();
    self.Tooltip:Show();
end

function NarciBarberShopEditButtonMixin:OnLeave()
    MainFrame:OnLeave();
    self:GetParent():OnLeave();
    self.Tooltip:Hide();
end

function NarciBarberShopEditButtonMixin:OnHide()
    self:Hide();
    self:OnMouseUp();
    self.Tooltip:Hide();
end

function NarciBarberShopEditButtonMixin:OnMouseDown()
    self.Icon:SetSize(16, 16);
end

function NarciBarberShopEditButtonMixin:OnMouseUp()
    self.Icon:SetSize(20, 20);
end


NarciBarberShopDeleteButtonMixin = {};

function NarciBarberShopDeleteButtonMixin:OnLoad()
    DeleteButton = self;
    self.Icon:SetTexCoord(0, 0.25, 0, 1);
    self.Ring:SetTexCoord(0.25, 0.5, 0, 1);
    self.Ring:SetVertexColor(0.85, 0, 0);
    self.SemiCircleRight:SetVertexColor(0.85, 0, 0);
    self.SemiCircleLeft:SetVertexColor(0.85, 0, 0);
    self.Tooltip:SetText(L["Delete Look"]);
    self.Tooltip:SetTextColor(1, 0.31, 0.31);
    SetFontStringShadow(self.Tooltip);

    --self.Ring:SetDrawLayer("BORDER");
end

function NarciBarberShopDeleteButtonMixin:SetParentObject(object)
    self:SetParent(object);
    self:Show();
    self:OnMouseUp();
end

function NarciBarberShopDeleteButtonMixin:OnClick()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function NarciBarberShopDeleteButtonMixin:OnLongClick()
    local ButtonPool, removedButton = DataProvider:DeleteLooks(self:GetParent().dataSource);
    if ButtonPool then
        DataProvider:IsCharacterDataUnique();
        animScrollButtons:RemoveOldButton(ButtonPool, removedButton);
    end
end

function NarciBarberShopDeleteButtonMixin:OnEnter()
    self:GetParent():OnEnter();
    self.Tooltip:Show();
end

function NarciBarberShopDeleteButtonMixin:OnLeave()
    MainFrame:OnLeave();
    self:GetParent():OnLeave();
    self.Tooltip:Hide();
end

function NarciBarberShopDeleteButtonMixin:OnHide()
    self:Hide();
    self:OnMouseUp();
    self.Tooltip:Hide();
end

function NarciBarberShopDeleteButtonMixin:OnMouseDown()
    self.Icon:SetSize(14, 14);
    self:LockHighlight();
    self.SemiCircleLeft:Show();
    self.SemiCircleRight:Show();
    self.SemiCircleLeft.rotation:Play();
    self.SemiCircleRight.rotation:Play();
    self.Ring:SetVertexColor(0.25, 0, 0);
end

function NarciBarberShopDeleteButtonMixin:OnMouseUp()
    self.Icon:SetSize(20, 20);
    self:UnlockHighlight();
    self.SemiCircleRight:Hide();
    self.SemiCircleLeft:Hide();
    self:StopAnimating();
    self.Ring:SetVertexColor(0.85, 0, 0);
end


NarciBarberShopEditBoxMixin = {};

function NarciBarberShopEditBoxMixin:OnLoad()
    EditBox = self;
end

function NarciBarberShopEditBoxMixin:SetParentObject(object, alsoHighlightText)
    if self.parentObject then
        self.parentObject.Name:Show();
        self.parentObject:OnLeave();
    end
    self:ClearAllPoints();
    self:SetParent(object);
    self:SetPoint("LEFT", object.Name, "LEFT", 0, 0);
    self:SetText(object.Name:GetText());
    self:Show();
    self.parentObject = object;
    object.Name:Hide();
    if alsoHighlightText then
        After(0, function()
            self:HighlightText();
        end)
    end
end

function NarciBarberShopEditBoxMixin:OnEscapePressed()
    self.exitByPressingEscape = true;
    self:DiscardChanges();
end

function NarciBarberShopEditBoxMixin:OnEnterPressed()
    self:ConfirmChanges();
end

function NarciBarberShopEditBoxMixin:OnTextChanged()
    local remainingLetters = 36 - self:GetNumLetters(true);
    self.LetterCount:SetText(remainingLetters);
    if remainingLetters == 0 then
        self.LetterCount:SetTextColor(0.85, 0, 0);
    elseif remainingLetters <= 12 then
        self.LetterCount:SetTextColor(0.96, 0.64, 0.13);
    else
        self.LetterCount:SetTextColor(0.66, 0.66, 0.66);
    end
end

function NarciBarberShopEditBoxMixin:DiscardChanges()
    self:Hide();
end

function NarciBarberShopEditBoxMixin:ConfirmChanges()
    local text = strtrim(self:GetText() or "");
    if text ~= "" then
        self.parentObject.Name:SetText(text);
        self.parentObject:UpdateText();
        self.parentObject.dataSource.name = text;
    end
    self:Hide();
end

function NarciBarberShopEditBoxMixin:OnShow()
    self:SetFocus();
    self:SetCursorPosition(100);
end

function NarciBarberShopEditBoxMixin:OnHide()
    self:HighlightText(0, 0);
    self:ClearFocus();
    self:Hide();
    if self.parentObject then
        self.parentObject.Name:Show();
        self.parentObject:OnLeave();
    end
end

function NarciBarberShopEditBoxMixin:OnEditFocusGained()
    autoHideTimer:Hide();
end

function NarciBarberShopEditBoxMixin:OnEditFocusLost()
    if self.exitByPressingEscape then
        self.exitByPressingEscape = nil;
        self:Hide();
    else
        self:ConfirmChanges();
    end
    autoHideTimer:Show();
end

----------------------------------
--Main Frame




NarciBarberShopMixin = {};

function NarciBarberShopMixin:OnLoad()
    MainFrame = self;
    self.fadeController = CreateFrame("Frame", nil, self);
end

local function FadeController_OnUpdate(self, elapsed)
    self.alpha = self.alpha + self.fadeSpeed*elapsed;
    if self.alpha >= 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    elseif self.alpha <= 0 then
        self.alpha = 0;
        self:SetScript("OnUpdate", nil);
    end
    MainFrame:SetFrameAlpha(self.alpha);
end

function NarciBarberShopMixin:SetFrameAlpha(alpha)
    --temp fix for "Model Widgets Not Inherit Parent's Alpha"
    self:SetAlpha(alpha);
    ScrollButtonAlphaUpdater:SetActiveButtonAlpha(alpha);
end

function NarciBarberShopMixin:FadeIn(fullDuration)
    local alpha = self:GetAlpha();
    if alpha == 1 then
        self.fadeController:SetScript("OnUpdate", nil);
        return
    end
    self.fadeController.fadeSpeed = 1/fullDuration;
    self.fadeController.alpha = alpha;
    self.fadeController:SetScript("OnUpdate", FadeController_OnUpdate);
end

function NarciBarberShopMixin:FadeOut(fullDuration)
    local alpha = self:GetAlpha();
    if alpha == 0 then
        self.fadeController:SetScript("OnUpdate", nil);
        return
    end
    self.fadeController.fadeSpeed = -1/fullDuration;
    self.fadeController.alpha = alpha;
    self.fadeController:SetScript("OnUpdate", FadeController_OnUpdate);
end

function NarciBarberShopMixin:OnKeyDown(key)
    if HotkeyManager:RunCommandByKeyState(key, true) then
        self:SetPropagateKeyboardInput(false);
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciBarberShopMixin:ToggleNotification(state)
    self.checkUniqueness = state;
end

function NarciBarberShopMixin:ToggleRandomizeAppearanceButton(visible)
    --Deprecated
    --"Random" button is enabled by Blizzard
    local button = CharCustomizeFrame.RandomizeAppearanceButton;
    if button then
        button:SetShown(visible);
    end
end

function NarciBarberShopMixin:OnKeyUp(key)
    if HotkeyManager:RunCommandByKeyState(key, false) then
        self:SetPropagateKeyboardInput(false);
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciBarberShopMixin:OnShow()
    local _;
    _, SCROLLFRAME_CENTER_Y = self.SavedLooksFrame.CategoryMale:GetCenter();
    UpdateScrollButtonAlpha(ScrollButtonAlphaUpdater.activeButtons);
end

function NarciBarberShopMixin:OnHide()
    ScrollButtonAlphaUpdater:Stop();
    HotkeyManager:StopMovingCamera();
    autoHideTimer:Hide();
end

function NarciBarberShopMixin:OnEnter()
    self:FadeIn(0.2);
end

function NarciBarberShopMixin:OnLeave()
    if not self:IsMouseOver() and not IsMouseButtonDown() then
        autoHideTimer:Show();
    end
end

function NarciBarberShopMixin:ToggleSaves(visible)
    --For Shapeshifter
    if visible then
        self.SavedLooksFrame:Show();
        self:FadeIn(0.2);
    else
        PlusButton:SetCase(4);
        self.SavedLooksFrame:Hide();
        self:SetAlpha(0);
    end
end

function NarciBarberShopMixin:UpdateGenderCategory(sex)
    self:FadeIn(0.2);
    autoHideTimer:Hide();
    autoHideTimer:Show();

    if not sex then
        local currentCharacterData =  C_BarberShop.GetCurrentCharacterData();
        if currentCharacterData then
            sex = currentCharacterData.sex;
        else
            print("Error: No Character Data");
            return
        end
    end

    DataProvider.currentSex = sex;

    if HAS_ALTERNATE_FORM then
        IN_ALTERNATE_FORM = C_BarberShop.IsViewingAlteredForm();
        if sex == self.lastSex and IN_ALTERNATE_FORM == self.lastFrom then
            return
        else
            self.lastSex = sex;
            self.lastFrom = IN_ALTERNATE_FORM;
        end
    else
        if sex == self.lastSex then
            return
        else
            self.lastSex = sex;
        end
    end

    local activeCategory;
    if sex == 0 then
        if HAS_ALTERNATE_FORM then
            if IN_ALTERNATE_FORM then
                activeCategory = self.SavedLooksFrame.CategoryAlternateFormMale;
                self.SavedLooksFrame.CategoryMale:Hide();
                self.SavedLooksFrame.CategoryFemale:Hide();
                self.SavedLooksFrame.CategoryAlternateFormFemale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = AlternateMaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numAlternateMales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE[CAMEAR_KEY_ALTERNATE_FORM].male;
            else
                activeCategory = self.SavedLooksFrame.CategoryMale;
                self.SavedLooksFrame.CategoryFemale:Hide();
                self.SavedLooksFrame.CategoryAlternateFormMale:Hide();
                self.SavedLooksFrame.CategoryAlternateFormFemale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = MaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numMales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE[CAMEAR_KEY_TRUE_FORM].male;
            end
        else
            activeCategory = self.SavedLooksFrame.CategoryMale;
            self.SavedLooksFrame.CategoryFemale:Hide();
            ScrollButtonAlphaUpdater.activeButtons = MaleButtons;
            NUM_ACTIVE_BUTTONS = DataProvider.numMales;
            ACTIVE_CAMERA_PROFILE = CAMERA_PROFILE.male;
        end
    else
        if HAS_ALTERNATE_FORM then
            if IN_ALTERNATE_FORM then
                activeCategory = self.SavedLooksFrame.CategoryAlternateFormFemale;
                self.SavedLooksFrame.CategoryMale:Hide();
                self.SavedLooksFrame.CategoryFemale:Hide();
                self.SavedLooksFrame.CategoryAlternateFormMale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = AlternateFemaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numAlternateFemales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE[CAMEAR_KEY_ALTERNATE_FORM].female;
            else
                activeCategory = self.SavedLooksFrame.CategoryFemale;
                self.SavedLooksFrame.CategoryMale:Hide();
                self.SavedLooksFrame.CategoryAlternateFormMale:Hide();
                self.SavedLooksFrame.CategoryAlternateFormFemale:Hide();
                ScrollButtonAlphaUpdater.activeButtons = FemaleButtons;
                NUM_ACTIVE_BUTTONS = DataProvider.numFemales;
                ACTIVE_CAMERA_PROFILE = CAMERA_PROFILES_BY_RACE[CAMEAR_KEY_TRUE_FORM].female;
            end
        else
            activeCategory = self.SavedLooksFrame.CategoryFemale;
            self.SavedLooksFrame.CategoryMale:Hide();
            ScrollButtonAlphaUpdater.activeButtons = FemaleButtons;
            NUM_ACTIVE_BUTTONS = DataProvider.numFemales;
            ACTIVE_CAMERA_PROFILE = CAMERA_PROFILE.female;
        end
    end

    self.activeCategory = activeCategory;
    ACTIVE_BUTTON_POOL = ScrollButtonAlphaUpdater.activeButtons;

    activeCategory:Show();
    ScrollBoundMarkUpdater:Hide();
    ScrollBoundMarkUpdater.object1 = activeCategory.BoundTop;
    ScrollBoundMarkUpdater.object2 = activeCategory.BoundBottom;

    UpdateScrollRange(activeCategory);

    LoadingFrame:LoadPortraits();
end

function NarciBarberShopMixin:OnBarberShopOpen()
    self.initialCustomizationData = C_BarberShop.GetAvailableCustomizations();

    local isDragonriding;

    if self.initialCustomizationData then
        for _, categoryData in ipairs(self.initialCustomizationData) do
            if categoryData.chrModelID then
                isDragonriding = true;
                break
            end
        end
    end
    print("Dragonriding", isDragonriding)

    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    local sex;
    if currentCharacterData then
        sex = currentCharacterData.sex;
        self.initialIconAtlas = currentCharacterData.raceData and currentCharacterData.raceData.createScreenIconAtlas;
    end
    self:UpdateGenderCategory(sex);
    StatManager:OnBarberShopOpen();
end

function NarciBarberShopMixin:OnBarberShopClose()
    self.initialIconAtlas = nil;
    self.initialCustomizationData = nil;
    self.fadeController:SetScript("OnUpdate", nil);
    StatManager:OnBarberShopClose();
end

function NarciBarberShopMixin:ResetCustomizationInternally()
    if self.initialCustomizationData then
        CustomizationUtil:ApplyCustomizationCategoryData(self.initialCustomizationData, true);
    end
end

function NarciBarberShopMixin:IsCharacterCategoryChanged()
    --true if player is viewing a different category - i.g. was type1 but currently viewing type2
    local currentCharacterData = C_BarberShop.GetCurrentCharacterData();
    if currentCharacterData then
        if currentCharacterData.raceData then
            return self.initialIconAtlas ~= currentCharacterData.raceData.createScreenIconAtlas;
        else
            return true
        end
    else
        return true
    end
end

function NarciBarberShopMixin:OnViewingModelChanged(chrModelID)
    local effectiveChrModelID = C_BarberShop.GetViewingChrModel();
    print(effectiveChrModelID)
end

-----------------------------------------------------------------
local function InitializeBarberShopFrame()
    local frame = Narci_BarbershopFrame;
    frame:ClearAllPoints();
    frame:SetParent(BarberShopUI);
    frame:SetPoint("TOPLEFT", BarberShopUI, "TOPLEFT", 0, -95);
    frame:Show();

    --The WoW default action is automatically closing the BarberShopUI
    --But here we want to check if the newly applied appearance is unique and notifiy user to save it
    BarberShopUI:UnregisterEvent("BARBER_SHOP_APPEARANCE_APPLIED");
    SettingFrame:Initialize();
end

--/run TestPlayerModel:SetZoomDistance()


local function HookMixin()
    --[[
    hooksecurefunc(CharCustomizeFrame, "SetCustomizationChoice", function(self, optionID, choiceID)
        print("Set ",optionID, choiceID)
    end)
    hooksecurefunc(CharCustomizeFrame, "PreviewCustomizationChoice", function(self, optionID, choiceID)
        print("Preview ", optionID, choiceID)
    end)
    --]]
    
    hooksecurefunc(C_BarberShop, "SetSelectedSex", function(sexID)
        MainFrame:UpdateGenderCategory(sexID);
    end);

    hooksecurefunc(C_BarberShop, "SetViewingShapeshiftForm", function(formID)
        if formID then
            MainFrame:ToggleSaves(false);
        else
            MainFrame:ToggleSaves(true);
        end
    end);

    if HAS_ALTERNATE_FORM then
        hooksecurefunc(C_BarberShop, "SetViewingAlteredForm", function(viewingAlteredForm)
            MainFrame:UpdateGenderCategory();
        end);
    end

    if C_BarberShop.SetViewingChrModel then
        hooksecurefunc(C_BarberShop, "SetViewingChrModel", function(chrModelID)
            MainFrame:OnViewingModelChanged();
        end);
    end

    --Override the default method to:
    --1. Add looks uniqueness check
    --Constantly monitor this mixin!!

    if true then
        function BarberShopUI:UpdateCharCustomizationFrame(alsoReset)
            local customizationCategoryData = C_BarberShop.GetAvailableCustomizations();
            if not customizationCategoryData then
                return;
            end

            DataProvider:IsCharacterDataUnique(customizationCategoryData);

            if alsoReset then
                CharCustomizeFrame:Reset();
            end

            CharCustomizeFrame:SetCustomizations(customizationCategoryData);

            if self.UpdatePrice then
                --TransitionAPI *barbershop is free in Dragonflight
                self:UpdatePrice();
            end

            if self.UpdateButtons then
                self:UpdateButtons();
            end
            --ExportEditBox.profileString = nil; --It'll be updated when that editbox becomes visible
        end
    end
end



local EventListener = CreateFrame("Frame");
local events = {"BARBER_SHOP_COST_UPDATE", "BARBER_SHOP_FORCE_CUSTOMIZATIONS_UPDATE", "BARBER_SHOP_RESULT", "BARBER_SHOP_OPEN", "BARBER_SHOP_CLOSE", "BARBER_SHOP_APPEARANCE_APPLIED", "ADDON_LOADED"};    --"UNIT_MODEL_CHANGED"
for i = 1, #events do
    EventListener:RegisterEvent(events[i])
end


EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...;
        --Blizzard_CharacterCustomize
        --Blizzard_BarbershopUI
        if name == "Narcissus_Barbershop" then --Narcissus_Barbershop
            self:UnregisterEvent(event);
            if not (IsAddOnLoaded("Blizzard_BarbershopUI") and BarberShopFrame) then
                print("Narcissus Error: Blizzard_BarbershopUI not loaded!");
                self:UnregisterAllEvents();
                return
            end
            BarberShopUI = BarberShopFrame;
            DataProvider:LoadData();
            HotkeyManager:LoadHotkeys();
            StatManager:LoadData();
            HookMixin();
            InitializeBarberShopFrame();
            MainFrame:UpdateGenderCategory();
            MainFrame:OnBarberShopOpen();

            
            if true then
                C_Timer.After(0.5 , function()
                    BarberShopUI:SetPropagateKeyboardInput(true);    --DEBUG
                end)
            end
            
        end
    elseif event == "BARBER_SHOP_OPEN" then
        MainFrame:OnBarberShopOpen();

    elseif event == "BARBER_SHOP_CLOSE" then
        MainFrame:OnBarberShopClose();

    elseif event == "BARBER_SHOP_RESULT" then
        --MainFrame:UpdateGenderCategory();
        if BarberShopUI.UpdateButtons then
            BarberShopUI:UpdateButtons();
        end
    elseif event == "BARBER_SHOP_APPEARANCE_APPLIED" then
        if MainFrame.checkUniqueness and DataProvider:IsNewLooksUnique() then
            BarberShopUI:UpdateCharCustomizationFrame();
            PlusButton:Glow();
        else
            BarberShopUI:Cancel();
        end
        StatManager:UpdateMoney();
    end
end)





-------------------------------------------------------
--Settings
local TabButtons = {};

NarciBarberShopSettingTabButtonMixin = {};

function NarciBarberShopSettingTabButtonMixin:OnLoad()
    tinsert(TabButtons, self);
end

function NarciBarberShopSettingTabButtonMixin:OnEnter()
    if not self.isSelected then
        self.ButtonText:SetTextColor(1, 1, 1);
    end
end

function NarciBarberShopSettingTabButtonMixin:OnLeave()
    if not self.isSelected then
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciBarberShopSettingTabButtonMixin:SetSelection(isSelected)
    self.isSelected = isSelected;
    SettingFrame.ScrollFrame:SetOffset(0);
    if isSelected then
        self.ButtonText:SetTextColor(1, 0.82, 0);
        SettingFrame:SelectTab(self.Tab);
    else
        self:OnLeave();
        if self.Tab then
            self.Tab:Hide();
        end
    end
end

function NarciBarberShopSettingTabButtonMixin:OnClick()
    if self.isSelected then return end;
    
    for i = 1, #TabButtons do
        TabButtons[i]:SetSelection( TabButtons[i] == self );
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end


NarciBarberShopSettingCheckBoxMixin = {};

function NarciBarberShopSettingCheckBoxMixin:OnLoad()
    self.Box:SetVertexColor(0.8, 0.8, 0.8);
    self.Highlight:SetVertexColor(0.5, 0.5, 1);
end

function NarciBarberShopSettingCheckBoxMixin:SetChecked(state)
    self.isOn = state;
    self.Check:SetShown(state);
    if self.onClickFunc then
        self.onClickFunc(self.isOn);
    end
end

function NarciBarberShopSettingCheckBoxMixin:OnClick()
    self.isOn = not self.isOn;
    self:SetChecked(self.isOn);
    if self.name then
        NarciBarberShopDB[self.name] = self.isOn;
    end

    if self.isOn then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    end
end


local function ProfilesTab_Setup(tab)

end


local TabData = {
    { name= "General", order = 1, localizedName = GENERAL,
        layout = {
            { name = "ToggleNotification", type = "checkbox", localizedName = L["Save Notify"], defaultState = true,
                onClickFunc = function(state) MainFrame:ToggleNotification(state) end,
                tooltip = L["Save Notify Tooltip"];
            },
            --{ name = "ToggleRandomAppearance", type = "checkbox", localizedName = L["Show Randomize Button"], defaultState = false, onClickFunc = function(state) MainFrame:ToggleRandomizeAppearanceButton(state) end }, --RANDOMIZE_APPEARANCE
        },
    },

    { name = "Shortcuts", order = 2, localizedName = L["Hotkey"],
        layout = {
            { name = "Camera", type = "header", localizedName = CAMERA_LABEL},
            { name = "RotateLeft", type = "keybinding", localizedName = ROTATE_LEFT},
            { name = "RotateRight", type = "keybinding", localizedName = ROTATE_RIGHT},
            { name = "ZoomIn", type = "keybinding", localizedName = ZOOM_IN},
            { name = "ZoomOut", type = "keybinding", localizedName = ZOOM_OUT},
        },
    },

    { name = "Profiles", order = 3, localizedName = L["Profiles"],
        manuallyCreated = true,
        setupFunc = ProfilesTab_Setup,
    },

    { name = "Statistics", order = 0, localizedName = STATISTICS,
        layout = {
            { name = "Money", type = "header", localizedName = L["Coins Spent"] },
            { name = "CoinsSpentSinceShadowlands", type="money", localizedName = "9.0+", tooltip = "Coins spent since 9.0"},
            { name = "CoinsSpentLifetime", type="money", localizedName = HONOR_LIFETIME, tooltip = "Coins spent during lifetime"},
            { name = "Blank", type="header", localizedName=" ",},
            { name = "LocationHeader", type = "location", localizedName = L["Locations"] },
        },
    },
}


local function CreateTabs(frame)
    local Data;
    for i = 1, #TabData do
        Data = TabData[i];
        local button = CreateFrame("Button", nil, frame, "NarciBarberShopSettingTabButtonTemplate");
        local order = Data.order;
        button.order = order;
        if order ~= 0 then
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12 + 16 *(1 - i));
        else
            button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12);
        end
        button:SetText(Data.localizedName);

        if Data.layout then
            local totalHeight = 8;
            local objects = {};
            local ScrollFrame = frame.ScrollFrame;
            local Tab = CreateFrame("Frame", nil, ScrollFrame);
            button.Tab = Tab;
            if order == 0 then
                StatManager.StatFrame = Tab;
            end
            Tab:SetSize(ScrollFrame:GetSize());
            Tab:SetPoint("TOPLEFT", frame.ScrollFrame.ScrollChild, "TOPLEFT", 0, 0);
            for j, objectData in ipairs(Data.layout) do
                local type = objectData.type;
                local object;
                if type == "checkbox" then
                    object = CreateFrame("Button", nil, Tab, "NarciBarberShopSettingCheckBoxTemplate");
                    object.onClickFunc = objectData.onClickFunc;
                    object.Label:SetText(objectData.localizedName);
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    local textHeight = object.Label:GetHeight() or 12;
                    object:SetHeight(textHeight + 2);
                    totalHeight = totalHeight + textHeight + 12;
                    --Load settings
                    local dbName = objectData.name;
                    object.name = dbName;
                    if NarciBarberShopDB[dbName] == nil then
                        NarciBarberShopDB[dbName] = objectData.defaultState;
                    end
                    object:SetChecked(NarciBarberShopDB[dbName]);
                    if objectData.tooltip then
                        local infoButton = CreateFrame("Frame", nil, object, "NarciBarberShopInfoButtonTemplate");
                        infoButton:SetPoint("LEFT", object, "RIGHT", 12, 0);
                        infoButton.tooltip = objectData.tooltip;
                        objectData.tooltip = nil;
                    end
                elseif type == "keybinding" then
                    object = CreateFrame("Button", nil, Tab, "NarciBarberShopSettingKeyBindingButtonTemplate");
                    object.Label:SetText(objectData.localizedName);
                    object.command = objectData.name;
                    object:SetPoint("TOPRIGHT", Tab, "TOPRIGHT", -60, -totalHeight);
                    local textHeight = object.Label:GetHeight() or 12;
                    totalHeight = totalHeight + textHeight + 12;
                    object:SetText(HotkeyManager:GetHotkey(object.command));

                elseif type == "header" then
                    object = Tab:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
                    object:SetText(objectData.localizedName);
                    if objectData.anchor then
                        object:SetJustifyH("LEFT");
                    else
                        object:SetJustifyH("CENTER");
                    end
                    object:SetSpacing(2);
                    object:SetJustifyV("TOP");
                    object:SetPoint("TOP", Tab, "TOP", 0, -totalHeight);
                    object:SetTextColor(0.5, 0.5, 0.5);
                    object:SetWidth(270);
                    totalHeight = totalHeight + 16;

                elseif type == "money" then
                    object = CreateFrame("Frame", nil, Tab, "NarciBarberShopStatsMoneyFrameTemplate");
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    object:SetLabel(objectData.localizedName);
                    local textHeight = object.Label:GetHeight() or 12;
                    totalHeight = totalHeight + textHeight + 8;

                    StatManager.widgets[objectData.name] = object;
                elseif type == "location" then
                    object = CreateFrame("Frame", nil, Tab, "NarciBarberShopStatsLocationFrameTemplate");
                    object:SetPoint("TOPLEFT", Tab, "TOPLEFT", 8, -totalHeight);
                    object:SetHeader();
                    totalHeight = totalHeight + 16;
                    StatManager.widgets[objectData.name] = object;
                    
                end
            end

            Tab.tabHeight = totalHeight;
            Tab.basicHeight = totalHeight;

        elseif Data.manuallyCreated then
            local Tab = frame[Data.name.."Tab"];
            if Tab then
                button.Tab = Tab;
                Tab:ClearAllPoints();
                Tab:SetPoint("TOPLEFT", frame.ScrollFrame, "TOPLEFT", 0, 0);
                if Data.setupFunc then
                    Data.setupFunc(Tab);
                end
            end
        end
    end

    wipe(TabData);
end

NarciBarberShopSettingsMixin = CreateFromMixins(NarciChamferedFrameMixin);

function NarciBarberShopSettingsMixin:OnLoad()
    SettingFrame = self;
    StatManager.SettingFrame = self;
    ExportEditBox = self.ProfilesTab.ExportEditBox;

    local v = 0.2;
    self:SetBorderColor(v, v, v, 1);
    self:SetBackgroundColor(0, 0, 0, 1);
    self.Divider:SetVertexColor(v, v, v);
    self.ScrollFrame.ScrollBar.Background:SetVertexColor(0.5, 0.5, 0.5);

    NarciAPI.CreateSmoothScroll(self.ScrollFrame);
    self.ScrollFrame:SetStepSize(40);
end

function NarciBarberShopSettingsMixin:Initialize()
    CreateTabs(self);
    TabButtons[1]:Click();
end

function NarciBarberShopSettingsMixin:OnEvent(event)
    --GLOBAL_MOUSE_DOWN
    if not self:IsMouseOver() and not SettingButton:IsMouseOver() then
        self:Hide();
    end
end

function NarciBarberShopSettingsMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBarberShopSettingsMixin:OnHide()
    self:Hide();
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");

    autoHideTimer:Show();
end

function NarciBarberShopSettingsMixin:Toggle()
    self:SetShown(not self:IsShown());
end

function NarciBarberShopSettingsMixin:SelectTab(tab)
    --Update Scroll Range
    local frameHeight = math.floor(self.ScrollFrame:GetHeight() + 0.5);
    local range;
    if tab then
        tab:Show();
        if tab.tabHeight then
            range = tab.tabHeight - frameHeight;
            if range < 4 then
                range = 0;
            end
        else
            range = 0;
        end
        self.ScrollFrame:SetScrollRange(range);
    end
end

--Click to open Settings
NarciBarberShopSettingButtonMixin = {};

function NarciBarberShopSettingButtonMixin:OnLoad()
    SettingButton = self;
    self.Label:SetText(L["Settings And Share"]);
end

function NarciBarberShopSettingButtonMixin:OnMouseDown()
    self.Background:SetTexCoord(0.25, 0.5, 0, 1);
end

function NarciBarberShopSettingButtonMixin:OnMouseUp()
    self.Background:SetTexCoord(0, 0.25, 0, 1);
end

function NarciBarberShopSettingButtonMixin:OnEnter()
    self.Label:Show();
    EditButton:Hide();
    DeleteButton:Hide();
end

function NarciBarberShopSettingButtonMixin:OnLeave()
    self.Label:Hide();
end

function NarciBarberShopSettingButtonMixin:OnClick()
    SettingFrame:Toggle();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

-----------------------------------------------
--Dev Tool
local function round(number, digit)
    digit = digit or 0;
    local fold = 10^digit;
    return math.floor((number * fold + 0.5))/fold
end

NarciDevToolPortraitMixin = {};

function NarciDevToolPortraitMixin:OnLoad()
    if false then return end;
    
    local model = self.Model;
    model:SetUnit("player");
    model:SetKeepModelOnHide(true);
    model:SetDoBlend(true);
    model:SetFacing(0);
    TransitionAPI.SetModelLight(model, true, false, cos(pi/4)*sin(-pi/4) ,  cos(pi/4)*cos(-pi/4) , -cos(pi/4), 1, 0.5, 0.5, 0.5, 1, 0.9, 0.9, 0.9);
    model:SetCamera(0);
    model:SetPortraitZoom(1);
    model:SetAnimation(0, 0);
    model:SetPaused(true);
    self.facing = 0;
    self.cameraDistance = 1;
    self.cameraPitch = pi/2;
    self.translationX, self.translationY = 0, 0;

    self.FacingButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "LeftButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        self.facing = model:GetFacing() + delta;
        model:SetFacing(self.facing);
        frame.Value:SetText( round(self.facing, 2) );
    end)

    --[[
    self.CameraPitchButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        local cameraPitch = self.cameraPitch + delta;
        self.cameraPitch = cameraPitch;
        TransitionAPI.SetCameraPosition(model, self.cameraDistance*sin(cameraPitch), 0, self.cameraDistance*cos(cameraPitch) + 0.8);
        frame.Value:SetText(cameraPitch);
    end)
    --]]



    self.ModelXButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 16 * delta;
        end
        local x, y, z = model:GetPosition();
        model:SetPosition(x + delta, y, z);
        frame.Value:SetText( round(x + delta, 2) );
    end)

    self.ModelYButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 16 * delta;
        end
        local x, y, z = model:GetPosition();
        model:SetPosition(x, y + delta, z);
        frame.Value:SetText( round(y + delta, 2) );
    end)

    self.ModelZButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 16 * delta;
        end
        local x, y, z = model:GetPosition();
        model:SetPosition(x, y, z + delta);
        frame.Value:SetText( round(z + delta, 2) );
    end)

    self.DistanceButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "LeftButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        local cameraDistance = self.cameraDistance + delta;
        self.cameraDistance = cameraDistance;
        TransitionAPI.SetCameraPosition(model, cameraDistance*sin(self.cameraPitch), 0, cameraDistance*cos(self.cameraPitch) + 0.8);
        frame.Value:SetText( round(cameraDistance, 4) );
    end)

    self.OffsetXButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "LeftButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        local x, y = model:GetViewTranslation();
        model:SetViewTranslation(x + delta, y);
        frame.Value:SetText( round(x + delta) );
    end)

    self.OffsetYButton:SetScript("OnClick", function(frame, button)
        local delta = frame.delta;
        if button == "RightButton" then
            delta = - delta;
        end
        if IsShiftKeyDown() then
            delta = 4 * delta;
        end
        local x, y = model:GetViewTranslation();
        model:SetViewTranslation(x, y + delta);
        frame.Value:SetText( round(y + delta) );
    end)

    self.ReloadButton:SetScript("OnClick", function()
        self:LoadProfile();
    end)
end

function NarciDevToolPortraitMixin:OnShow()
    local model = self.Model;
    model:MakeCurrentCameraCustom();
    self.cameraDistance = model:GetCameraDistance();
    self.cameraPitch = pi/2;
    model:SetPosition(0, 0, 0);
    self.FacingButton.Value:SetText(model:GetFacing());
    self.DistanceButton.Value:SetText(self.cameraDistance);
    local x, y = model:GetViewTranslation();
    self.OffsetXButton.Value:SetText(x);
    self.OffsetYButton.Value:SetText(y);
end

function NarciDevToolPortraitMixin:LoadProfile(race, sex)
    local model = self.Model;
    model:RefreshUnit();
    model:SetAnimation(0, 0);
    model:SetPaused(true);
    model:MakeCurrentCameraCustom();
    if not UpdatePortraitCamera(model) then
        model:SetFacing(0.52);
        local modelX, modelY, modelZ = 3.4, -0.07, -2.09;
        model:SetPosition(modelX, modelY, modelZ);
    end
    local cameraX, cameraY, cameraZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 4, 0, 0);
    local targetX, targetY, targetZ = TransitionAPI.TransformCameraSpaceToModelSpace(model, 0, 0, 0);
    TransitionAPI.SetCameraTarget(model, targetX, targetY, targetZ);
    TransitionAPI.SetCameraPosition(model, cameraX, cameraY, cameraZ);
    local modelFacing = model:GetFacing();
    local modelPosX, modelPosY, modelPosZ = model:GetPosition();
    self.ModelXButton.Value:SetText(modelPosX);
    self.ModelYButton.Value:SetText(modelPosY);
    self.ModelZButton.Value:SetText(modelPosZ);
    self.FacingButton.Value:SetText(modelFacing);
end

--[[
    Statistics
    Gold spent at barber shops GetStatistic(1147)
    C_MapExplorationInfo.GetExploredAreaIDsAtPosition(109, C_Map.GetPlayerMapPosition(109, "player"))
    C_Map.GetMapInfoAtPosition(109, C_Map.GetPlayerMapPosition(109, "player"):GetXY())
New Look #10: Q.0.52k.i.5.c.1h.6.7.g.1.a.4.p.2.5.7.9.2.7.4.2.8.2g1.2.nD.J.9.B.16.7.7.c.f.w.3.5.4.5.C
Dracthyr Male: Q.0.52E.3.d.1i.4.9.g.3.6.3.j.9.6.3.3.8.3.4.8.1.6.1Th.g.mw.1.3.nV.p.9.J.19.3.b.1.O.1.8.5.C.aQ
Dracthyr Male: Q.0.52E.3.d.1i.4.9.g.3.6.3.j.9.6.3.3.8.3.4.8.1.6.1Th.h.P.lG.1.3.nV.p.9.J.19.3.b.1.O.1.8.5.C.aQ
--]]

local PORTRAIT_LOAD_DELAY = 0.1;
NarciBarberShopLoadingFrameMixin = {};

local function LoadingFrame_UpdatePortraitDelay(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > PORTRAIT_LOAD_DELAY then
        --self:SetScript("OnUpdate", nil);
        self.t = 0;
        self.button:RefreshPortrait(true);
    end
end

local function LoadingFrame_InitiateLoadingDelay(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.2 then
        self.t = 0;
        self:LoadNextPortrait(self.current);
    end
end

function NarciBarberShopLoadingFrameMixin:OnLoad()
    LoadingFrame = self;

    self.Name:SetText(Narci.L["Loading Portraits"] .."...");
    self.Name:SetTextColor(1, 1, 1);
    self.Progress:SetTextColor(0.67, 0.67, 0.67);
end

function NarciBarberShopLoadingFrameMixin:LoadPortraits()
    local fromID;
    local total = 0;
    if ACTIVE_BUTTON_POOL then
        for i = 1, #ACTIVE_BUTTON_POOL do
            if (not ACTIVE_BUTTON_POOL[i].isPortraitLoaded) and ACTIVE_BUTTON_POOL[i].appearanceData then
                total = total + 1;
                if not fromID  then
                    fromID = i;
                end
            end
        end
    end

    if total == 0 then
        self:Hide();
        self:SetScript("OnUpdate", nil);
        return
    else
        self.total = total;
    end

    self.Name:SetText(Narci.L["Loading Portraits"] .."...");
    self.current = fromID - 1;
    self.Ring.AnimSpin:Play();
    self.t = 0;
    self:SetScript("OnUpdate", LoadingFrame_InitiateLoadingDelay);

    FadeFrame(self, 0.25, 1, 0);
end

function NarciBarberShopLoadingFrameMixin:OnHide()
    self:SetScript("OnUpdate", nil);
end

function NarciBarberShopLoadingFrameMixin:LoadNextPortrait(buttonID)
    if buttonID and buttonID ~= self.current then
        return
    end

    self.current = self.current + 1;
    if self.current > self.total then
        --complete
        if self.isLoading then
            self:OnLoadingComplete();
        end
    else
        local button = ACTIVE_BUTTON_POOL[self.current];
        if button then
            button:UseCustomization(true);
            self.t = 0;
            self.button = button;
            self:SetScript("OnUpdate", LoadingFrame_UpdatePortraitDelay);
            self.isLoading = true;
            self.Progress:SetText(self.current .. " / " ..self.total);
        else
            self:OnLoadingComplete();
        end
    end
end

function NarciBarberShopLoadingFrameMixin:OnLoadingComplete()
    --self:StopAnimating();
    self:SetScript("OnUpdate", nil);
    self.isLoading = false;
    --self:Hide();
    FadeFrame(self, 0.5, 0);

    if MainFrame:IsCharacterCategoryChanged() then
        local customizationCategoryData = C_BarberShop.GetAvailableCustomizations();
        DataProvider:IsCharacterDataUnique(customizationCategoryData);
    else
        MainFrame:ResetCustomizationInternally();
    end
end