local W, F, E, L = unpack(select(2, ...))
local S = W.Modules.Skins

local _G = _G
local hooksecurefunc = hooksecurefunc
local pairs = pairs
local select = select

local GetClassInfo = GetClassInfo

local function updateClassIcon(row)
    if not row or not row.expanded then
        return
    end

    local memberInfo = row:GetMemberInfo()
    local classId = memberInfo and memberInfo.classID
    local englishClassName = classId and select(2, GetClassInfo(classId))
    if englishClassName then
        row.Class:SetTexture(F.GetClassIconWithStyle(englishClassName, "flat"))
        row.Class:SetTexCoord(0, 1, 0, 1)
    end
end

function S:Blizzard_Communities()
    if not self:CheckDB("communities") then
        return
    end

    local CommunitiesFrame = _G.CommunitiesFrame
    if not CommunitiesFrame then
        return
    end

    self:CreateShadow(CommunitiesFrame)
    self:CreateShadow(CommunitiesFrame.ChatTab)
    self:CreateShadow(CommunitiesFrame.RosterTab)
    self:CreateShadow(CommunitiesFrame.GuildBenefitsTab)
    self:CreateShadow(CommunitiesFrame.GuildInfoTab)
    self:CreateShadow(CommunitiesFrame.GuildMemberDetailFrame)
    self:CreateShadow(CommunitiesFrame.ClubFinderInvitationFrame)

    self:CreateShadow(_G.CommunitiesGuildLogFrame)
    self:CreateShadow(_G.CommunitiesSettingsDialog)

    local ClubFinderCommunityAndGuildFinderFrame = _G.ClubFinderCommunityAndGuildFinderFrame
    if ClubFinderCommunityAndGuildFinderFrame then
        self:CreateShadow(ClubFinderCommunityAndGuildFinderFrame.ClubFinderPendingTab)
        self:CreateShadow(ClubFinderCommunityAndGuildFinderFrame.ClubFinderSearchTab)
        self:CreateShadow(ClubFinderCommunityAndGuildFinderFrame.RequestToJoinFrame)
    end

    local ClubFinderCommunityAndGuildFinderFrame = _G.ClubFinderCommunityAndGuildFinderFrame
    if ClubFinderCommunityAndGuildFinderFrame then
        self:CreateShadow(ClubFinderCommunityAndGuildFinderFrame.ClubFinderPendingTab)
        self:CreateShadow(ClubFinderCommunityAndGuildFinderFrame.ClubFinderSearchTab)
        self:CreateShadow(ClubFinderCommunityAndGuildFinderFrame.RequestToJoinFrame)
    end

    self:CreateShadow(_G.CommunitiesFrame.RecruitmentDialog)

    hooksecurefunc(
        CommunitiesFrame.MemberList,
        "RefreshListDisplay",
        function(memberList)
            local target = memberList.ScrollBox:GetScrollTarget()
            if not target or not target.GetChildren then
                return
            end

            for _, row in pairs({target:GetChildren()}) do
                if row and not row.__windSkinHook then
                    hooksecurefunc(row, "RefreshExpandedColumns", updateClassIcon)
                    row.__windSkinHook = true
                end
            end
        end
    )

    local BossModel = _G.CommunitiesFrameGuildDetailsFrameNews.BossModel
    self:CreateShadow(BossModel)
    self:CreateShadow(BossModel.TextFrame)
end

S:AddCallbackForAddon("Blizzard_Communities")
