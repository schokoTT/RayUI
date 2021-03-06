local R, L, P, G = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB, GlobalDB
local IF = R:GetModule("InfoBar")

--Cache global variables
--Lua functions
local select, string, ipairs = select, string, ipairs
local wipe = wipe
local tinsert = table.insert
local strsplit = string.split

--WoW API / Variables
local CreateFrame = CreateFrame
local IsAltKeyDown = IsAltKeyDown
local InviteUnit = InviteUnit
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildRosterInfo = GetGuildRosterInfo
local ChatFrame_GetMobileEmbeddedTexture = ChatFrame_GetMobileEmbeddedTexture
local CanViewOfficerNote = CanViewOfficerNote
local IsInGuild = IsInGuild
local GetGuildInfo = GetGuildInfo
local GetText = GetText
local UnitSex = UnitSex
local GetGuildFactionInfo = GetGuildFactionInfo
local GetGuildRosterMOTD = GetGuildRosterMOTD
local GetQuestDifficultyColor = GetQuestDifficultyColor
local GuildFrame_LoadUI = GuildFrame_LoadUI
local GuildFrame_Toggle = GuildFrame_Toggle
local ToggleGuildFinder = ToggleGuildFinder
local LoadAddOn = LoadAddOn
local GuildRoster = GuildRoster
local InCombatLockdown = InCombatLockdown

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: SetItemRef, REMOTE_CHAT, NAME, LEVEL_ABBR, ZONE, RANK, GUILD_OFFICERNOTES_LABEL
-- GLOBALS: GUILD_RANK0_DESC, GuildFrame, ERR_FRIEND_ONLINE_SS, GUILD, LABEL_NOTE

local GuildTabletData = {}
local GuildOnline = 0
local guildTablet = LibStub("Tablet-2.0")
local ttheader = {0.4, 0.78, 1}
local PlayerStatusValToStr = {
    [1] = CHAT_FLAG_AFK,
    [2] = CHAT_FLAG_DND,
}
local displayString = string.join("", GUILD, ": %d|r")
local noGuildString = string.join("", "", L["没有公会"])
local GuildSection = {}
local resendRequest = false
local FRIEND_ONLINE
local resSizeExtra

local function Guild_TabletClickFunc(name)
    if not name then return end
    if IsAltKeyDown() then
        InviteUnit(name)
    else
        SetItemRef("player:"..name, "|Hplayer:"..name.."|h["..name.."|h", "LeftButton")
    end
end

local function Guild_BuidTablet()
    local guildonline = 0
    -- Total Online Guildies
    for i = 1, GetNumGuildMembers() do
        local gPrelist
        local name, rank, _, lvl, _class, zone, note, offnote, online, status, class, _, _, mobile = GetGuildRosterInfo(i)

        local r, g, b = R.colors.class[class].r, R.colors.class[class].g, R.colors.class[class].b
        -- Player Name
        local cname
        if status == 0 then
            cname = string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, name)
        else
            local curStatus = PlayerStatusValToStr[status] or ""
            cname = string.format("%s |cff%02x%02x%02x%s|r", curStatus, r * 255, g * 255, b * 255, name)
        end

        -- Class Color
        class = string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, class)

        -- Mobile
        if mobile then
            cname = ChatFrame_GetMobileEmbeddedTexture(73/255, 177/255, 73/255)..cname
            zone = REMOTE_CHAT
        end

        -- Add to list
        if online then
            GuildTabletData[guildonline + 1] = GuildTabletData[guildonline + 1] or {}
            if CanViewOfficerNote() then
                GuildTabletData[guildonline + 1][1] = cname
                GuildTabletData[guildonline + 1][2] = lvl
                GuildTabletData[guildonline + 1][3] = zone
                GuildTabletData[guildonline + 1][4] = rank
                GuildTabletData[guildonline + 1][5] = note
                GuildTabletData[guildonline + 1][6] = offnote
                GuildTabletData[guildonline + 1][7] = name
            else
                GuildTabletData[guildonline + 1][1] = cname
                GuildTabletData[guildonline + 1][2] = lvl
                GuildTabletData[guildonline + 1][3] = zone
                GuildTabletData[guildonline + 1][4] = rank
                GuildTabletData[guildonline + 1][5] = note
                GuildTabletData[guildonline + 1][6] = " "
                GuildTabletData[guildonline + 1][7] = name
            end
            guildonline = guildonline + 1
        end

        for i = guildonline+1, #GuildTabletData do
            GuildTabletData[i] = nil
        end
    end

    -- OnEnter
    GuildOnline = guildonline
end

local function Guild_UpdateTablet()
    if ( IsInGuild() and GuildOnline > 0 ) then
        resSizeExtra = 2
        local Cols, lineHeader
        wipe(GuildSection)

        -- Guild Name
        local gname, _, _ = GetGuildInfo("player")
        GuildSection.headerCat = guildTablet:AddCategory()
        GuildSection.headerCat:AddLine("text", gname, "size", 13 + resSizeExtra, "textR", ttheader[1], "textG", ttheader[2], "textB", ttheader[3])
        GuildSection.headerCat:AddLine("isLine", true, "text", "")

        -- Reputation
        GuildSection.headerCat:AddLine("text", GetText("FACTION_STANDING_LABEL"..GetGuildFactionInfo(), UnitSex("player")), "size", 11 + resSizeExtra, "textR", 0.7, "textG", 0.7, "textB", 0.7)
        R:AddBlankTabLine(GuildSection.headerCat, 5)

        -- GMOTD
        local gmotd = GetGuildRosterMOTD()
        if gmotd ~= "" then
            GuildSection.headerCat:AddLine("text", gmotd, "wrap", true, "textR", 1, "textG", 1, "textB", 1)
            R:AddBlankTabLine(GuildSection.headerCat, 5)
        end
        R:AddBlankTabLine(GuildSection.headerCat)

        -- Titles
        local Cols = {
            NAME,
            LEVEL_ABBR,
            ZONE,
            RANK,
            LABEL_NOTE
        }
        if CanViewOfficerNote() then
            tinsert(Cols, GUILD_OFFICERNOTES_LABEL)
        end

        GuildSection.guildCat = guildTablet:AddCategory("columns", #Cols)
        lineHeader = R:MakeTabletHeader(Cols, 10 + resSizeExtra, 0, {"LEFT", "RIGHT", "LEFT", "LEFT", "LEFT", "LEFT"})
        GuildSection.guildCat:AddLine(lineHeader)
        R:AddBlankTabLine(GuildSection.guildCat)

        -- Guild Members
        local nameslot = #Cols + 1
        local isPlayer, isFriend, isGM, normColor
        local line = {}
        for _, val in ipairs(GuildTabletData) do
            isPlayer = val[7] == R.myname
            if IF.FriendsTabletDataNames then
                isFriend = (not isPlayer) and IF.FriendsTabletDataNames[val[7]] or false
            end
            isGM = val[4] == GUILD_RANK0_DESC
            normColor = isPlayer and {0.3, 1, 0.3} or
            isFriend and {0, 0.8, 0.8} or
            isGM and {1, 0.65, 0.2} or
            {0.8, 0.8, 0.8}
            wipe(line)
            for i = 1, #Cols do
                if i == 1 then -- Name
                    line["text"] = val[i]
                    line["justify"] = "LEFT"
                    line["func"] = function() Guild_TabletClickFunc(val[7]) end
                    line["size"] = 11 + resSizeExtra
                elseif i == 2 then -- Level
                    line["text"..i] = val[i]
                    line["justify"..i] = "RIGHT"
                    local uLevelColor = GetQuestDifficultyColor(val[2])
                    line["text"..i.."R"] = uLevelColor.r
                    line["text"..i.."G"] = uLevelColor.g
                    line["text"..i.."B"] = uLevelColor.b
                    line["size"..i] = 11 + resSizeExtra
                else -- The rest
                    line["text"..i] = val[i]
                    line["justify"..i] = "LEFT"
                    line["text"..i.."R"] = normColor[1]
                    line["text"..i.."G"] = normColor[2]
                    line["text"..i.."B"] = normColor[3]
                    line["size"..i] = 11 + resSizeExtra
                end
            end
            GuildSection.guildCat:AddLine(line)
        end

        -- Hint
        guildTablet:SetHint(L["<点击玩家>发送密语, <Alt+点击玩家>邀请玩家."])
    end
end

local function Guild_OnClick(self)
    if IsInGuild() then
        GuildFrame_LoadUI()

        if GuildFrame_Toggle then
            GuildFrame_Toggle()
        end
    else
        ToggleGuildFinder()
    end
end

local eventHandlers = {
    ["CHAT_MSG_SYSTEM"] = function(self, arg1)
        if arg1 and arg1:find(FRIEND_ONLINE) then
            resendRequest = true
        end
    end,
    ["PLAYER_ENTERING_WORLD"] = function (self, arg1)
        if not GuildFrame and IsInGuild() then
            LoadAddOn("Blizzard_GuildUI")
            GuildRoster()
        end
    end,
    ["GUILD_ROSTER_UPDATE"] = function (self)
        if(resendRequest) then
            resendRequest = false
            return GuildRoster()
        end
    end,
    ["PLAYER_GUILD_UPDATE"] = function (self, arg1)
        GuildRoster()
    end,
    ["GUILD_MOTD"] = function (self, arg1)
    end,
}

local function Guild_OnEvent(self, event, ...)
    if not FRIEND_ONLINE then FRIEND_ONLINE = select(2, strsplit("cff00ffff", ERR_FRIEND_ONLINE_SS, 2)) end

    eventHandlers[event](self, select(1, ...))
    self:SetText(GUILD..": "..select(3, GetNumGuildMembers()))
end

local function Guild_OnEnter(self)
    if InCombatLockdown() or not IsInGuild() then return end
    -- Register guildTablet
    if not guildTablet:IsRegistered(self) then
        guildTablet:Register(self,
            "children", function()
                Guild_BuidTablet()
                Guild_UpdateTablet()
            end,
            "point", "BOTTOM",
            "relativePoint", "TOP",
            "maxHeight", 700,
            "clickable", true,
            "hideWhenEmpty", true
        )
    end

    if guildTablet:IsRegistered(self) then
        -- guildTablet appearance
        guildTablet:SetColor(self, 0, 0, 0)
        guildTablet:SetTransparency(self, .65)
        guildTablet:SetFontSizePercent(self, 1)

        -- Open
        -- if ( IsInGuild() and GuildOnline > 0 ) then
        -- GuildRoster()
        -- end
        guildTablet:Open(self)
    end
end

do -- Initialize
    local info = {}

    info.title = GUILD
    info.icon = "Interface\\Icons\\inv_shirt_guildtabard_01"
    info.clickFunc = Guild_OnClick
    info.events = { "PLAYER_ENTERING_WORLD", "CHAT_MSG_SYSTEM", "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "GUILD_MOTD" }
    info.eventFunc = Guild_OnEvent
    info.tooltipFunc = Guild_OnEnter

    IF:RegisterInfoBarType("Guild", info)
end
