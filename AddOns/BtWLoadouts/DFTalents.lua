--[[
    To get a list of nodes that count towards a gate we might be able check condition ids vs cost ids for each node
]]

local ADDON_NAME,Internal = ...
local L = Internal.L

BTWLOADOUTS_DF_TALENTS_ACTIVE = Internal.IsDragonflightPatch

--@NOTE Copying parts of the original talents code over. Dont want to use wrong mixin
local BtWLoadoutsTalentsMixin = false

Internal.OnEvent("LOADOUT_CHANGE_END", function ()
    if C_Traits then
        C_Traits.RollbackConfig(C_ClassTalents.GetActiveConfigID()); -- Rollback to what we were at before starting a loadout
    end
end)

local function CompareSets(a, b)
    if a.specID ~= b.specID then
        return false
    end
    if a.treeID ~= b.treeID then
        return false
    end

    if not tCompare(a.nodes, b.nodes, 10) then
        return false
    end
    if type(a.restrictions) ~= type(b.restrictions) and not tCompare(a.restrictions, b.restrictions, 10) then
        return false
    end

    return true
end

local function UpdateSetFilters(set)
    set.filters = set.filters or {}

    local specID = set.specID;
    local filters = set.filters

    Internal.UpdateRestrictionFilters(set)

    filters.spec = specID
    if specID then
        filters.role, filters.class = select(5, GetSpecializationInfoByID(specID))
    else
        filters.role, filters.class = nil, nil
    end

    -- Rebuild character list
    filters.character = filters.character or {}
    local characters = filters.character
    table.wipe(characters)
    local class = filters.class
    for _,character in Internal.CharacterIterator() do
        if class == Internal.GetCharacterInfo(character).class then
            characters[#characters+1] = character
        end
    end

    set.filters = filters

    return set
end
local function RefreshSet(set)
    local nodes = set.nodes or {};
    local specID, specName = GetSpecializationInfo(GetSpecialization());
    if specID == set.specID then
        wipe(nodes);
        local configID = C_ClassTalents.GetActiveConfigID();
        if not configID then
            return
        end
        local configInfo = C_Traits.GetConfigInfo(configID);
        local treeID = configInfo.treeIDs[1];

        local treeInfo = Internal.GetTreeInfoBySpecID(specID);
        if treeInfo.ID == treeID then
            local nodeIDs = C_Traits.GetTreeNodes(configInfo.treeIDs[1]);
            for _,nodeID in ipairs(nodeIDs) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
                if nodeInfo.isVisible then
                    if #nodeInfo.entryIDs > 1 then
                        if nodeInfo.activeEntry then
                            for index,entryID in ipairs(nodeInfo.entryIDs) do
                                if entryID == nodeInfo.activeEntry.entryID then
                                    nodes[nodeID] = index;
                                    break;
                                end
                            end
                        end
                    elseif nodeInfo.ranksPurchased > 0 then
                        nodes[nodeID] = nodeInfo.ranksPurchased;
                    end
                end
            end
            set.treeID = treeID
        end
    end
    set.nodes = nodes;

    return UpdateSetFilters(set)
end
local function AddSet()
    local specIndex = GetSpecialization()
    if specIndex == 5 then
        specIndex = 1
    end
    local classID = select(3, UnitClass("player"))
    local specID, specName = GetSpecializationInfo(specIndex);
    return Internal.AddSet("dftalents", RefreshSet({
        classID = classID,
        specID = specID,
        name = format(L["New %s Set"], specName),
        useCount = 0,
        nodes = {},
    }))
end
local function DeleteSet(id)
    Internal.DeleteSet(BtWLoadoutsSets.dftalents, id);

    if type(id) == "table" then
        id = id.setID;
    end
    for _,set in pairs(BtWLoadoutsSets.profiles) do
        if type(set) == "table" then
            for index,setID in ipairs(set.dftalents) do
                if setID == id then
                    table.remove(set.dftalents, index)
                end
            end
        end
    end

    local frame = BtWLoadoutsFrame.DFTalents;
    local set = frame.set;
    if set.setID == id then
        frame.set = nil
        BtWLoadoutsFrame:Update(true);
    end
end
local function GetSet(id)
    if type(id) == "table" then
        return id;
    else
        return BtWLoadoutsSets.dftalents[id]
    end
end
local function GetSets(id, ...)
    if id ~= nil then
        return GetSet(id), GetSets(...);
    end
end
-- In General, For Player, For Player Spec
local function SetIsValid(set)
	set = GetSet(set);

	local playerSpecID = GetSpecializationInfo(GetSpecialization());
	local playerClass = select(2, UnitClass("player"));
	local specClass = select(6, GetSpecializationInfoByID(set.specID));

	return true, (playerClass == specClass), (playerSpecID == set.specID)
end
local function GetByName(name)
    return Internal.GetSetByName(BtWLoadoutsSets.dftalents, name, SetIsValid)
end
local function IsSetActive(set)
    local configID = C_ClassTalents.GetActiveConfigID();
    for nodeID,value in pairs(set.nodes) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
        if not nodeInfo then -- Does this mean we cant activate this set at all?
            return false;
        end
        if not nodeInfo.isVisible then
            return false;
        end

        if #nodeInfo.entryIDs > 1 then
            if not nodeInfo.activeEntry then
                return false;
            end
            if nodeInfo.activeEntry.entryID ~= nodeInfo.entryIDs[value] then
                return false;
            end
        else
            if nodeInfo.activeRank ~= value then
                return false;
            end
        end
    end

    return true;
end
local function IsNodeEntryOnCooldown(nodeEntryID)
    local entryInfo = C_Traits.GetEntryInfo(C_ClassTalents.GetActiveConfigID(), nodeEntryID);
    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID);
    
    local spellID = definitionInfo.spellID;
    if spellID then
        spellID = FindSpellOverrideByID(spellID);
        local start, duration = GetSpellCooldown(spellID);
        if start ~= 0 then -- Talent spell on cooldown, we need to wait before switching
            Internal.DirtyAfter((start + duration) - GetTime() + 1);
            return true;
        end
    end

    return false;
end
local function SetRequirements(set)
    local isActive, waitForCooldown = true, false

    local configID = C_ClassTalents.GetActiveConfigID();
    if not configID then
        return
    end

    local configInfo = C_Traits.GetConfigInfo(configID);
    local nodeIDs = C_Traits.GetTreeNodes(configInfo.treeIDs[1]);
    
    for _,nodeID in ipairs(nodeIDs) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
        if nodeInfo.isVisible then
            local value = set.nodes[nodeID];
            if #nodeInfo.entryIDs > 1 then
                if nodeInfo.activeEntry and nodeInfo.activeEntry.entryID and (not value or nodeInfo.entryIDs[value] ~= nodeInfo.activeEntry.entryID) then
                    isActive = false;
                    waitForCooldown = waitForCooldown or IsNodeEntryOnCooldown(nodeInfo.activeEntry.entryID);
                    if waitForCooldown then
                        break -- We dont actually need to check anything more
                    end
                else
                    if not nodeInfo.ranksPurchased == 1 or not nodeInfo.activeEntry or nodeInfo.activeEntry.entryID ~= nodeInfo.entryIDs[value] then
                        isActive = false;
                    end
                end
            else
                if value then
                    if nodeInfo.ranksPurchased ~= value then
                        isActive = false;
                    end
                elseif nodeInfo.ranksPurchased > 0 then
                    waitForCooldown = waitForCooldown or IsNodeEntryOnCooldown(nodeInfo.activeEntry.entryID);
                    isActive = false;
                    if waitForCooldown then
                        break -- We dont actually need to check anything more
                    end
                end
            end
        end
    end

    return isActive, waitForCooldown
end
local function CombineSets(result, state, ...)
    result = result or {};

	for i=1,select('#', ...) do
		local set = GetSet(select(i, ...));
        result.nodes = set.nodes; -- @TODO Proper Combining?
    end

    if state then
        local isActive, waitForCooldown, anySelected = SetRequirements(result)

        if not isActive then
            if state.blockers then
                state.blockers[Internal.GetSpellCastingBlocker()] = true
                state.blockers[Internal.GetCombatBlocker()] = true
                state.blockers[Internal.GetMythicPlusBlocker()] = true
                state.blockers[Internal.GetJailersChainBlocker()] = true
            end
            
            state.customWait = state.customWait or (waitForCooldown and L["Waiting for talent cooldown"])
        end
    end

    return result;
end
local function ActivateSet(set, state)
    local complete = true;

    local spellId = select(9, UnitCastingInfo("player"));
    if spellId == 384255 then
        complete = false;
    elseif not IsSetActive(set) and not state.dfTalentsAttempted then
        complete = false;

        local specID = GetSpecializationInfo(GetSpecialization());

        if ClassTalentFrame then
            ClassTalentFrame.TalentsTab:ClearLastSelectedConfigID();
            ClassTalentFrame.TalentsTab:MarkTreeDirty();
        end
        C_ClassTalents.UpdateLastSelectedSavedConfigID(specID, 0) -- Set active loadout to "Default Loadout"

        local configID = C_ClassTalents.GetActiveConfigID();
        if not configID then
            return
        end

        local configInfo = C_Traits.GetConfigInfo(configID);
        C_Traits.ResetTree(configID, configInfo.treeIDs[1]);

        local done = {};
        local a, b = {}, {};
        local function PurchaseNode(nodeID)
            if not done[nodeID] and set.nodes[nodeID] then
                local nodeInfo = Internal.GetNodeInfoBySpecID(specID, nodeID);
                local incomingEdges = nodeInfo.incomingEdgesBySpecID and nodeInfo.incomingEdgesBySpecID[specID] or nodeInfo.incomingEdges
                if incomingEdges then
                    for _,sourceNode in ipairs(incomingEdges) do
                        PurchaseNode(sourceNode);
                    end
                end

                if #nodeInfo.entryIDs > 1 then
                    local entryIndex = set.nodes[nodeID];
                    local success = C_Traits.SetSelection(configID, nodeID, nodeInfo.entryIDs[entryIndex]);
                    Internal.LogMessage("Set talent choice to %d for node %d (%s)", nodeInfo.entryIDs[entryIndex], nodeID, success and "true" or "false");
                    if not success then
                        b[nodeID] = true;
                        return;
                    end
                else
                    local points = set.nodes[nodeID];
                    for i=1,points do
                        local success = C_Traits.PurchaseRank(configID, nodeID);
                        Internal.LogMessage("Purchase talent point %d of %d for node %d (%s)", i, points, nodeID, success and "true" or "false");
                        if not success then
                            b[nodeID] = true;
                            return;
                        end
                    end
                end

                done[nodeID] = true;
            end
        end
        for nodeID in pairs(set.nodes) do
            a[nodeID] = true;
        end
        local tries = 10;
        while next(a) and tries > 0 do
            Internal.LogMessage("Talent loop %d", 11 - tries);
            wipe(b);
            for nodeID in pairs(a) do
                PurchaseNode(nodeID);
            end
            b, a = a, b;
            tries = tries - 1;
        end

        state.dfTalentsAttempted = true
        local success = C_ClassTalents.CommitConfig(configID);
        Internal.LogMessage("Commit talent config (%s)", success and "true" or "false");
    end

    if complete then
        local specID = GetSpecializationInfo(GetSpecialization());
        if ClassTalentFrame then
            ClassTalentFrame.TalentsTab:ClearLastSelectedConfigID();
            ClassTalentFrame.TalentsTab:MarkTreeDirty();
        end
        C_ClassTalents.UpdateLastSelectedSavedConfigID(specID, 0) -- Set active loadout to "Default Loadout"
    end

    return complete
end
local function CheckErrors(errorState, set)
    set = GetSet(set)
    errorState.specID = errorState.specID or set.specID

    if errorState.specID ~= set.specID then
        return L["Incompatible Specialization"]
    end

    if not Internal.AreRestrictionsValidFor(set.restrictions, errorState.specID) then
        return L["Incompatible Restrictions"]
    end
end

-- Initializes the set dropdown menu for the Loadouts page
local function SetDropDownInit(self, set, index)
    Internal.SetDropDownInit(self, set, index, "dftalents", BtWLoadoutsFrame.DFTalents)
end

Internal.AddLoadoutSegment({
    id = "dftalents",
    name = L["Talents"],
    events = BTWLOADOUTS_DF_TALENTS_ACTIVE and "TRAIT_CONFIG_UPDATED" or nil,
    enabled = BTWLOADOUTS_DF_TALENTS_ACTIVE,
    add = AddSet,
    get = GetSets,
    getByName = GetByName,
    isActive = IsSetActive,
    combine = CombineSets,
    activate = ActivateSet,
    checkerrors = CheckErrors,
    dropdowninit = SetDropDownInit,

    export = function (set)
        return {
            version = 1,
            name = set.name,
            classID = set.classID,
            specID = set.specID,
            treeID = set.treeID,
            nodes = set.nodes,
            restrictions = set.restrictions,
        }
    end,
    import = function (source, version, name, ...)
        assert(version == 1)

        local specID, classID = ...
        specID = source.specID or specID
        classID = source.classID or classID

        return Internal.AddSet("dftalents", UpdateSetFilters({
            classID = classID,
            specID = specID,
            treeID = source.treeID,
            name = name or source.name,
            useCount = 0,
            nodes = source.nodes,
            restrictions = source.restrictions,
        }))
    end,
    getByValue = function (set)
        return Internal.GetSetByValue(BtWLoadoutsSets.dftalents, set, CompareSets)
    end,
    verify = function (source, ...)
        local specID, classID = ...

        specID = source.specID or specID
        if not specID or not GetSpecializationInfoByID(specID) then
            return false, L["Invalid specialization"]
        end

        classID = source.classID or classID
        local classFile = select(6, GetSpecializationInfoByID(specID))
        if not classID or Internal.GetClassID(classFile) ~= classID then
            return false, L["Invalid class"]
        end

        local nodes = C_Traits.GetTreeNodes(source.treeID)
        if next(nodes) == nil then
            return false, L["Invalid talent tree"]
        end
        if  type(source.nodes) ~= "table" then
            return false, L["Invalid nodes"]
        end
        if source.restrictions ~= nil and type(source.restrictions) ~= "table" then
            return false, L["Missing restrictions"]
        end

        local nodeIDs = {}
        for _,nodeID in ipairs(nodes) do
            nodeIDs[nodeID] = true
        end

        for nodeID in pairs(source.nodes) do
            if not nodeIDs[nodeID] then
                return false, L["Invalid nodes"]
            end
        end

        return true
    end,
})

local DFTalentButtonMixin = CreateFromMixins(TalentButtonSpendMixin or {})
function DFTalentButtonMixin:OnLoad()
	TalentButtonSpendMixin.OnLoad(self);

    self.sizingAdjustment = {
        { region = "Icon", adjust = 0, },
        { region = "DisabledOverlay", adjust = 0, },
        { region = "StateBorder", adjust = 0, },
        { region = "StateBorderHover", adjust = 0, },
        { region = "IconMask", adjust = 0, },
        { region = "DisabledOverlayMask", adjust = 0, },
        { region = "Shadow", adjust = 0, },
    }
end
local DFTalentButtonSplitMixin = CreateFromMixins(TalentButtonSplitSelectMixin or {});
function DFTalentButtonSplitMixin:OnLoad()
	TalentButtonSplitSelectMixin.OnLoad(self);

    self.sizingAdjustment = {
        { region = "Icon", adjust = 0, },
        { region = "Icon2", adjust = 0, },
        { region = "DisabledOverlay", adjust = 0, },
        { region = "IconMask", adjust = 0, },
        { region = "Icon2Mask", adjust = 0, },
        { region = "IconSplitMask", adjust = 0, },
        { region = "DisabledOverlayMask", adjust = 0, },
        { region = "Shadow", adjust = 0, },
    }
end
function DFTalentButtonSplitMixin:ApplySize(width, height)
	TalentButtonBasicArtMixin.ApplySize(self, width, height);
    self.StateBorder:SetSize(width + 18, height + 12);
    self.StateBorderHover:SetSize(width + 18, height + 12);
end
local DFTalentSelectionChoiceMixin = CreateFromMixins(TalentSelectionChoiceMixin or {});
-- function DFTalentSelectionChoiceMixin:OnLoad()
    -- print(self.sizingAdjustment)
    -- self.sizingAdjustment = {
    --     { region = "Icon", adjust = 0, },
    --     { region = "DisabledOverlay", adjust = 0, },
    --     { region = "StateBorder", adjust = 10, },
    --     { region = "IconMask", adjust = 0, },
    --     { region = "DisabledOverlayMask", adjust = 0, },
    --     { region = "Shadow", adjust = 0, },
    -- }
-- end

local function GetSpecializedMixin(nodeInfo, talentType)
	if nodeInfo and (nodeInfo.type == Enum.TraitNodeType.Selection) then
		if FlagsUtil.IsSet(nodeInfo.flags, Enum.TraitNodeFlag.ShowMultipleIcons) then
			return DFTalentButtonSplitMixin;
		end
	end
    return DFTalentButtonMixin;
end

BtWLoadoutsDFTalentFrameBaseButtonsParentMixin = CreateFromMixins(TalentFrameBaseButtonsParentMixin or {})
BtWLoadoutsDFTalentSelectionChoiceFrameMixin = CreateFromMixins(TalentSelectionChoiceFrameMixin or {})
BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnLoad = BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnLoad or function () end
BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnShow = BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnShow or function () end
BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnHide = BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnHide or function () end
BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnEvent = BtWLoadoutsDFTalentSelectionChoiceFrameMixin.OnEvent or function () end

BtWLoadoutsDFTalentsMixin = CreateFromMixins(TalentFrameBaseMixin or CallbackRegistryMixin)
function BtWLoadoutsDFTalentsMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self);

    if not C_ClassTalents then
        return
    end

	self:SetBasePanOffset(0, 0);

    self.Scroll:RegisterForDrag("LeftButton");
    self.RestrictionsDropDown:SetSupportedTypes("race")
    self.RestrictionsDropDown:SetScript("OnChange", function ()
        self:Update()
    end)

    self.temp = {}

	self.talentButtonCollection = CreateFramePoolCollection();
	self.talentDislayFramePool = CreateFramePoolCollection();
	self.edgePool = CreateFramePoolCollection();
	self.gatePool = CreateFramePool("FRAME", self.Scroll:GetScrollChild(), "BtWLoadoutsTalentFrameGateTemplate");
	self.nodeIDToButton = {};
	self.buttonsWithDirtyEdges = {};
	self.treeInfoDirty = false;
	self.definitionInfoCache = {};
	self.dirtyDefinitionIDSet = {};
	self.entryInfoCache = {};
	self.dirtyEntryIDSet = {};
	self.nodeInfoCache = {};
	self.dirtyNodeIDSet = {};
	self.condInfoCache = {};
	self.dirtyCondIDSet = {};
	self.panOffsetX = 0;
	self.panOffsetY = 0;

    self.ButtonsParent = self.Scroll:GetScrollChild():GetChildren();

    self.getSpecializedMixin = GetSpecializedMixin;
end
function BtWLoadoutsDFTalentsMixin:OnShow()
    if not self.initialized then
		self.SpecDropDown.includeNone = false;
        UIDropDownMenu_SetWidth(self.SpecDropDown, 170);
        UIDropDownMenu_JustifyText(self.SpecDropDown, "LEFT");

        self.SpecDropDown.GetValue = function ()
            if self.set then
                return self.set.specID, self.set.classID
            end
        end
        self.SpecDropDown.SetValue = function (_, _, arg1, arg2)
            CloseDropDownMenus();

            local set = self.set;
            if set then
                local temp = self.temp;

                temp[set.specID] = set.nodes;

                set.specID = arg1;
                set.classID = arg2;

                local result = Internal.GetTreeInfoBySpecID(arg1);
                set.treeID = result.ID;

                set.nodes = temp[set.specID] or {};

                self:Update(true);
            end
        end

        self.initialized = true;
    end

    -- self:Update(true);
end
function BtWLoadoutsDFTalentsMixin:OnUpdate(...)
    self:UpdateTreeCurrencyInfo();
    TalentFrameBaseMixin.OnUpdate(self, ...);
end
function BtWLoadoutsDFTalentsMixin:ChangeSet(set)
    self.set = set
    wipe(self.temp);
    self:Update(true)
end
function BtWLoadoutsDFTalentsMixin:UpdateSetName(value)
    if self.set and self.set.name ~= not value then
        self.set.name = value;
        self:Update(false, true);
    end
end
function BtWLoadoutsDFTalentsMixin:OnButtonClick(button)
    CloseDropDownMenus()
    if button.isAdd then
        BtWLoadoutsHelpTipFlags["TUTORIAL_NEW_SET"] = true;

        self.Name:ClearFocus()
        self:ChangeSet(AddSet())
        C_Timer.After(0, function ()
            self.Name:HighlightText()
            self.Name:SetFocus()
        end)
    elseif button.isDelete then
        local set = self.set
        if set.useCount > 0 then
            StaticPopup_Show("BTWLOADOUTS_DELETEINUSESET", set.name, nil, {
                set = set,
                func = DeleteSet,
            })
        else
            StaticPopup_Show("BTWLOADOUTS_DELETESET", set.name, nil, {
                set = set,
                func = DeleteSet,
            })
        end
    elseif button.isRefresh then
        local set = self.set;
        RefreshSet(set)
        self:Update()
    elseif button.isExport then
        local set = self.set;
        self:GetParent():SetExport(Internal.Export("dftalents", set.setID))
    elseif button.isActivate then
        local set = self.set;
        if select(6, GetSpecializationInfoByID(set.specID)) == select(2, UnitClass("player")) then
            Internal.ActivateProfile({
                dftalents = {set.setID}
            });
        end
    end
end
function BtWLoadoutsDFTalentsMixin:OnSidebarItemClick(button)
    CloseDropDownMenus()
    if button.isHeader then
        button.collapsed[button.id] = not button.collapsed[button.id]
        self:Update()
    else
        if IsModifiedClick("SHIFT") then
            local set = GetSet(button.id);
            if select(6, GetSpecializationInfoByID(set.specID)) == select(2, UnitClass("player")) then
                Internal.ActivateProfile({
                    dftalents = {button.id}
                });
            end
        else
            self.Name:ClearFocus();
            self:ChangeSet(GetSet(button.id))
        end
    end
end
function BtWLoadoutsDFTalentsMixin:OnSidebarItemDoubleClick(button)
    CloseDropDownMenus()
    if button.isHeader then
        return
    end

    local set = GetSet(button.id);
    if select(6, GetSpecializationInfoByID(set.specID)) == select(2, UnitClass("player")) then
        Internal.ActivateProfile({
            dftalents = {button.id}
        });
    end
end
function BtWLoadoutsDFTalentsMixin:OnSidebarItemDragStart(button)
    CloseDropDownMenus()
    if button.isHeader then
        return
    end

    local icon = "INV_Misc_QuestionMark";
    local set = GetSet(button.id);
    local command = format("/btwloadouts activate dftalents %d", button.id);
    if set.specID then
        icon = select(4, GetSpecializationInfoByID(set.specID));
    end

    if command then
        local macroId;
        local numMacros = GetNumMacros();
        for i=1,numMacros do
            if GetMacroBody(i):trim() == command then
                macroId = i;
                break;
            end
        end

        if not macroId then
            if numMacros == MAX_ACCOUNT_MACROS then
                print(L["Cannot create any more macros"]);
                return;
            end
            if InCombatLockdown() then
                print(L["Cannot create macros while in combat"]);
                return;
            end

            macroId = CreateMacro(set.name, icon, command, false);
        else
            -- Rename the macro while not in combat
            if not InCombatLockdown() then
                icon = select(2,GetMacroInfo(macroId))
                EditMacro(macroId, set.name, icon, command)
            end
        end

        if macroId then
            PickupMacro(macroId);
        end
    end
end
function BtWLoadoutsDFTalentsMixin:Update(updatePosition, skipUpdateTree)
    self:GetParent():SetTitle(L["Talents"]);
    local sidebar = BtWLoadoutsFrame.Sidebar

    sidebar:SetSupportedFilters("spec", "class", "role", "character", "covenant", "race")
    sidebar:SetSets(BtWLoadoutsSets.dftalents)
    sidebar:SetCollapsed(BtWLoadoutsCollapsed.dftalents)
    sidebar:SetCategories(BtWLoadoutsCategories.dftalents)
    sidebar:SetFilters(BtWLoadoutsFilters.dftalents)
    sidebar:SetSelected(self.set)

    sidebar:Update()
    self.set = sidebar:GetSelected()
    local set = self.set
    
    local showingNPE = BtWLoadoutsFrame:SetNPEShown(set == nil, L["Talents"], L["Create different talent layouts for the type of content you wish to do."])
        
    self:GetParent().ExportButton:SetEnabled(true)
    self:GetParent().DeleteButton:SetEnabled(true);

    if not showingNPE then
        local treeInfo = Internal.GetTreeInfoBySpecID(self.set.specID);
        if treeInfo.ID ~= set.treeID and set.configID == nil then
            print(format(L["[%s]: Talent Tree has changed and your set has been reset."], ADDON_NAME));
            set.treeID = treeInfo.ID;
            set.nodes = {};
        end

        local classID = set.classID
        local specID = set.specID
        local treeID = set.treeID
        if not classID then
            local classInfo = Internal.GetClassInfoBySpecID(specID)
            set.classID = classInfo.classID
            classID = classInfo.classID
        end

        UpdateSetFilters(set)
        sidebar:Update()
        
        set.restrictions = set.restrictions or {}
        self.RestrictionsDropDown:SetSelections(set.restrictions)
        self.RestrictionsDropDown:SetLimitations()
        self.RestrictionsButton:SetEnabled(true);

        if not self.Name:HasFocus() then
            self.Name:SetText(set.name or "");
        end

        local _, specName, _, icon, _, classFile = GetSpecializationInfoByID(specID);
        local className = LOCALIZED_CLASS_NAMES_MALE[classFile];
        local classColor = C_ClassColor.GetClassColor(classFile);
        UIDropDownMenu_SetText(self.SpecDropDown, format("%s: %s", classColor:WrapTextInColorCode(className), specName));

        self.talentTreeID = treeID;
        self:UpdateTreeInfo(true);

        if not skipUpdateTree then
            self:LoadTalentTreeInternal();
        end
        
        local nodes = C_Traits.GetTreeNodes(treeID)
        local rect = {left = 65536, right = 0, top = 65536, bottom = 0}
        for _,nodeID in ipairs(nodes) do
            local nodeInfo = self:GetAndCacheNodeInfo(nodeID); -- /tinspect C_Traits.GetNodeInfo(C_ClassTalents.GetActiveConfigID(), 61086)
            if nodeInfo and nodeInfo.posY > 0 then
                if rect.left > nodeInfo.posX then
                    rect.left = nodeInfo.posX
                end
                if rect.right < nodeInfo.posX then
                    rect.right = nodeInfo.posX
                end
                if rect.top > nodeInfo.posY then
                    rect.top = nodeInfo.posY
                end
                if rect.bottom < nodeInfo.posY then
                    rect.bottom = nodeInfo.posY
                end
            end
        end

        -- self.ButtonsParent:SetSize(rect.right * 0.1, rect.bottom * 0.1)

        local center = (rect.right - rect.left) * 0.5 + rect.left;
        local leftSide = {left = 65536, right = 0, top = 65536, bottom = 0}
        local rightSide = {left = 65536, right = 0, top = 65536, bottom = 0}
        for _,nodeID in ipairs(nodes) do
            local nodeInfo = self:GetAndCacheNodeInfo(nodeID); -- /tinspect C_Traits.GetNodeInfo(C_ClassTalents.GetActiveConfigID(), 61086)
            if nodeInfo and nodeInfo.posY > 0 then
                if nodeInfo.posX < center then
                    if leftSide.left > nodeInfo.posX then
                        leftSide.left = nodeInfo.posX
                    end
                    if leftSide.right < nodeInfo.posX then
                        leftSide.right = nodeInfo.posX
                    end
                else
                    if rightSide.left > nodeInfo.posX then
                        rightSide.left = nodeInfo.posX
                    end
                    if rightSide.right < nodeInfo.posX then
                        rightSide.right = nodeInfo.posX
                    end
                end
            end
        end

        local scroll = self.Scroll;
        local scale = self.ButtonsParent:GetScale();
        local halfWidth = scroll:GetWidth() * 0.5;

        self.leftOffset = (((leftSide.right - leftSide.left) * 0.5 + leftSide.left) * 0.1) * scale - halfWidth;
        self.rightOffset = (((rightSide.right - rightSide.left) * 0.5 + rightSide.left) * 0.1) * scale - halfWidth;
        
        if updatePosition then
            self.endScrolling = true;
            self.DragHandler:Show();
        end

        local playerSpecIndex = GetSpecialization()
        self:GetParent().RefreshButton:SetEnabled((playerSpecIndex and specID == GetSpecializationInfo(playerSpecIndex)) or (specID == nil and classID == select(3, UnitClass("player"))))
        self:GetParent().ActivateButton:SetEnabled(classID == select(3, UnitClass("player")));

        local helpTipBox = self:GetParent().HelpTipBox;
        helpTipBox:Hide();
        
        BtWLoadoutsHelpTipFlags["TUTORIAL_CREATE_TALENT_SET"] = true;
    else
        local specIndex = GetSpecialization()
        if not specIndex or specIndex == 5 then
            specIndex = 1
        end

        local specID, specName = GetSpecializationInfo(specIndex);

        self.Name:SetText(format(L["New %s Set"], specName));

        local _, specName, _, icon, _, classID = GetSpecializationInfoByID(specID);
        local className = LOCALIZED_CLASS_NAMES_MALE[classID];
        local classColor = C_ClassColor.GetClassColor(classID);
        UIDropDownMenu_SetText(self.SpecDropDown, format("%s: %s", classColor:WrapTextInColorCode(className), specName));

        local helpTipBox = self:GetParent().HelpTipBox;
        helpTipBox:Hide();
    end
end
function BtWLoadoutsDFTalentsMixin:SetSetByID(setID)
    self.set = GetSet(setID)
end
function BtWLoadoutsDFTalentsMixin:OnDrag()
    local scroll = self.Scroll;

    local maxXScroll, maxYScroll = scroll:GetHorizontalScrollRange(), scroll:GetVerticalScrollRange()
    local minXScroll = self.leftOffset;
    local maxXScroll = self.rightOffset;

    local scrollX, scrollY

    if self.endScrolling then -- Maybe check which direction the drag was going in before hand?
        scrollX = scroll:GetHorizontalScroll();
        scrollY = scroll:GetVerticalScroll();
        if ApproximatelyEqual(scrollX, minXScroll, 0.1) then
            scrollX = minXScroll;
            self.DragHandler:Hide();
        elseif ApproximatelyEqual(scrollX, maxXScroll, 0.1) then
            scrollX = maxXScroll;
            self.DragHandler:Hide();
        else
            local halfWay = maxXScroll * 0.5;
            if scrollX < maxXScroll * 0.5 then
                scrollX = FrameDeltaLerp(scrollX, minXScroll, 0.1);
            else
                scrollX = FrameDeltaLerp(scrollX, maxXScroll, 0.1);
            end
        end
    else
        local mouseX, mouseY = GetCursorPosition()
        local scale = scroll:GetScrollChild():GetEffectiveScale()
        mouseX, mouseY = mouseX / scale, mouseY / scale

        scrollX = min(max(self.mouseX - mouseX + self.scrollX, minXScroll), maxXScroll)
        scrollY = min(max(mouseY - self.mouseY + self.scrollY, 0), maxYScroll)
    end

    scroll:SetHorizontalScroll(scrollX)
    scroll:SetVerticalScroll(scrollY)
end
function BtWLoadoutsDFTalentsMixin:BeginScrollDrag()
    local scroll = self.Scroll;

    self.scrollX, self.scrollY = scroll:GetHorizontalScroll(), scroll:GetVerticalScroll()
    self.mouseX, self.mouseY = GetCursorPosition()

    local scale = scroll:GetScrollChild():GetEffectiveScale()
    self.mouseX, self.mouseY = self.mouseX / scale, self.mouseY / scale

    self.endScrolling = false;
    -- self:SetScript("OnUpdate", self.OnDrag)
    self.DragHandler:Show();
end
function BtWLoadoutsDFTalentsMixin:EndScrollDrag()
    self.endScrolling = true;
end
function BtWLoadoutsDFTalentsMixin:UpdateTreeInfo(skipButtonUpdates)
	self.talentTreeInfo = Internal.GetTreeInfoBySpecID(self.set.specID);
	self:UpdateTreeCurrencyInfo(skipButtonUpdates);

	if not skipButtonUpdates then
		self:RefreshGates();
	end
end
function BtWLoadoutsDFTalentsMixin:UpdateTreeCurrencyInfo(skipButtonUpdates)
    local treeInfo = self:GetTreeInfo();
    
	self.treeCurrencyInfoMap = {};
    for _,currency in ipairs(treeInfo.currencies) do
        if GetMaxLevelForPlayerExpansion() == 60 then
            self.treeCurrencyInfoMap[currency.traitCurrencyID] = {
                traitCurrencyID = currency.traitCurrencyID,
                maxQuantity = currency.maxQuantity - 5,
                quantity = currency.maxQuantity - 5,
                spent = 0,
            }
        else
            currency.quantity = currency.maxQuantity;
            currency.spent = 0;
            self.treeCurrencyInfoMap[currency.traitCurrencyID] = currency;
        end
    end
    
    -- Calculate spent currencies
    for _,nodeID in ipairs(treeInfo.nodes) do
        -- local nodeInfo = self:GetAndCacheNodeInfo(nodeID);
        -- if nodeInfo and nodeInfo.ranksPurchased > 0 then
        --     for _,cost in ipairs(nodeInfo.costs) do
        --         self.treeCurrencyInfoMap[cost.ID].spent = self.treeCurrencyInfoMap[cost.ID].spent + (cost.amount * nodeInfo.ranksPurchased);
        --         self.treeCurrencyInfoMap[cost.ID].quantity = self.treeCurrencyInfoMap[cost.ID].quantity - (cost.amount * nodeInfo.ranksPurchased);
        --     end
        -- end
        local value = self.set.nodes[nodeID];
        if value then
            local nodeInfo = Internal.GetNodeInfoBySpecID(self.set.specID, nodeID);
            if #nodeInfo.entryIDs > 1 then
                value = 1;
            end
            for _,cost in ipairs(nodeInfo.costs) do
                self.treeCurrencyInfoMap[cost.ID].spent = self.treeCurrencyInfoMap[cost.ID].spent + (cost.amount * value);
                self.treeCurrencyInfoMap[cost.ID].quantity = self.treeCurrencyInfoMap[cost.ID].quantity - (cost.amount * value);
            end
        end
    end

	if not skipButtonUpdates then
		for condID, condInfo in pairs(self.condInfoCache) do
			if condInfo.isGate then
				self:MarkCondInfoCacheDirty(condID);
				self:ForceCondInfoUpdate(condID);
			end
		end

		self:RefreshGates();
	end
end
function BtWLoadoutsDFTalentsMixin:GetAndCacheNodeInfo(nodeID)
    if not self.set then
        return
    end

    local function GetNodeInfoCallback()
        local result = CopyTable(Internal.GetNodeInfoBySpecID(self.set.specID, nodeID), true);

        result.canPurchaseRank = true;
        result.canRefundRank = true;
        result.isAvailable = true; -- Not Gated
        result.meetsEdgeRequirements = true; -- Not Locked

        local incomingEdges = result.incomingEdgesBySpecID and result.incomingEdgesBySpecID[self.set.specID] or result.incomingEdges
        if incomingEdges and #incomingEdges > 0 then
            result.meetsEdgeRequirements = false;
            for _,ID in ipairs(incomingEdges) do
                local from = self:GetAndCacheNodeInfo(ID)
                if from.activeRank == from.maxRanks then
                    result.meetsEdgeRequirements = true;
                    break;
                end
            end
        end

        local tree = self:GetTreeInfo();
        for _,condID in ipairs(result.conditionIDs) do
            local cond = self:GetAndCacheCondInfo(condID);
            if cond and cond.spentAmountRequired > 0 then
                result.isAvailable = false;
                result.canPurchaseRank = false;
                break;
            end
        end
        if self.set.nodes[nodeID] then
            if not result.meetsEdgeRequirements or not result.isAvailable then
                self.set.nodes[nodeID] = nil;
            end
        end

        if self.set.nodes[nodeID] then
            if #result.entryIDs == 1 then
                if result.maxRanks < self.set.nodes[nodeID] then
                    self.set.nodes[nodeID] = result.maxRanks;
                end
                result.activeRank = self.set.nodes[nodeID];
                result.currentRank = self.set.nodes[nodeID];
                result.ranksPurchased = self.set.nodes[nodeID];
                result.activeEntry.rank = self.set.nodes[nodeID];
            else
                result.activeRank = 1;
                result.currentRank = 1;
                result.ranksPurchased = 1;
                result.activeEntry = {
                    entryID = result.entryIDs[self.set.nodes[nodeID]],
                    rank = 1,
                }
            end
        elseif #result.entryIDs > 1 then
            result.activeEntry = nil;
        end

        return result;
    end

    return GetOrCreateTableEntryByCallback(self.nodeInfoCache, nodeID, GetNodeInfoCallback);
end
function BtWLoadoutsDFTalentsMixin:GetAndCacheDefinitionInfo(definitionID)
	local function GetDefinitionInfoCallback()
		-- self.dirtyDefinitionIDSet[definitionID] = nil;
		return C_Traits.GetDefinitionInfo(definitionID);
	end

	return GetOrCreateTableEntryByCallback(self.definitionInfoCache, definitionID, GetDefinitionInfoCallback);
end
function BtWLoadoutsDFTalentsMixin:GetAndCacheEntryInfo(entryID)
	local function GetEntryInfoCallback()
		-- self.dirtyEntryIDSet[entryID] = nil;
		return C_Traits.GetEntryInfo(C_ClassTalents.GetActiveConfigID(), entryID);
	end

	return GetOrCreateTableEntryByCallback(self.entryInfoCache, entryID, GetEntryInfoCallback);
end
function BtWLoadoutsDFTalentsMixin:GetAndCacheCondInfo(condID)
    local function GetCondInfoCallback()
        local tree = self:GetTreeInfo();
        for _,gate in ipairs(tree.gates) do
            if gate.conditionID == condID then
                local result = {
                    isGate = true,
                    isAlwaysMet = false,

                    condID = gate.conditionID,
                    spentAmountRequired = gate.spentAmountRequired,
                    traitCurrencyID = gate.traitCurrencyID,
                }

                local spent = 0;
                for _,nodeID in ipairs(C_Traits.GetTreeNodes(tree.ID)) do
                    local nodeInfo = Internal.GetNodeInfoBySpecID(self.set.specID, nodeID);
                    if nodeInfo and self.set.nodes[nodeID] and not tContains(nodeInfo.conditionIDs, gate.conditionID) then
                        local purchased = #nodeInfo.entryIDs == 1 and self.set.nodes[nodeID] or 1;
                        for _,cost in ipairs(nodeInfo.costs) do
                            if cost.ID == gate.traitCurrencyID then
                                spent = spent + (cost.amount * purchased);
                            end
                        end
                    end
                end
                result.spentAmountRequired = math.max(0, result.spentAmountRequired - spent);
                result.isMet = result.spentAmountRequired == 0;

                return result;
            end
        end
	end

	return GetOrCreateTableEntryByCallback(self.condInfoCache, condID, GetCondInfoCallback);
end
function BtWLoadoutsDFTalentsMixin:GetNodeCost(nodeID)
    local nodeInfo = self:GetAndCacheNodeInfo(nodeID)
    return nodeInfo.costs;
end
function BtWLoadoutsDFTalentsMixin:AddConditionsToTooltip()
    
end
function BtWLoadoutsDFTalentsMixin:MarkNodeDirty(nodeID)
    local nodeInfo = self:GetAndCacheNodeInfo(nodeID);
    for _,edge in ipairs(nodeInfo.visibleEdges) do
        self:MarkNodeDirty(edge.targetNode);
    end
    self:MarkNodeInfoCacheDirty(nodeID);
end
function BtWLoadoutsDFTalentsMixin:PurchaseRank(nodeID)
    local nodeInfo = self:GetAndCacheNodeInfo(nodeID);
    if nodeInfo.maxRanks > nodeInfo.activeRank then
        self.set.nodes[nodeID] = (self.set.nodes[nodeID] or 0) + 1;
    end
    -- self:MarkNodeDirty(nodeID);
    -- self:RefreshButtons()
    self:Update();
end
function BtWLoadoutsDFTalentsMixin:RefundRank(nodeID)
    if self.set.nodes[nodeID] then
        self.set.nodes[nodeID] = (self.set.nodes[nodeID] or 0) - 1;
        if self.set.nodes[nodeID] <= 0 then
            self.set.nodes[nodeID] = nil;
        end
        -- self:MarkNodeDirty(nodeID);
        self:Update();
    end
end
function BtWLoadoutsDFTalentsMixin:GetSpecializedSelectionChoiceMixin(entryInfo, talentType)
	return DFTalentSelectionChoiceMixin;
end
function BtWLoadoutsDFTalentsMixin:SetSelection(nodeID, entryID)
    if entryID == nil then
        self.set.nodes[nodeID] = nil;
    else
        local nodeInfo = self:GetAndCacheNodeInfo(nodeID)
        for index,nodeEntryID in ipairs(nodeInfo.entryIDs) do
            if nodeEntryID == entryID then
                self.set.nodes[nodeID] = index;
            end
        end
    end
    -- self:MarkNodeDirty(nodeID);
    self:Update();
end
function BtWLoadoutsDFTalentsMixin:InstantiateTalentButton(nodeID, nodeInfo)
	nodeInfo = nodeInfo or self:GetAndCacheNodeInfo(nodeID);

	if not nodeInfo.isVisible and not self:ShouldInstantiateInvisibleButtons() then
		return nil;
	end

	local activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID or nil;
	local entryInfo = (activeEntryID ~= nil) and self:GetAndCacheEntryInfo(activeEntryID) or nil;
	local talentType = (entryInfo ~= nil) and entryInfo.type or nil;
	local function InitTalentButton(newTalentButton)
		newTalentButton:SetNodeID(nodeID);
	end

	local offsetX = nil;
	local offsetY = nil;
	local newTalentButton = self:AcquireTalentButton(nodeInfo, talentType, offsetX, offsetY, InitTalentButton);

	if newTalentButton then
		TalentButtonUtil.ApplyPosition(newTalentButton, self, nodeInfo.posX, nodeInfo.posY);

		local frameLevel = newTalentButton:GetParent():GetFrameLevel() + self:GetFrameLevelForButton(nodeInfo);
		self:SetElementFrameLevel(newTalentButton, frameLevel);
		newTalentButton:Show();
	end

	return newTalentButton;
end
