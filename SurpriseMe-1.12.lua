-- Surprise Me! Core Module
-- Handles auto-inviting functionality for TurtleWoW

SurpriseMe = {}
SurpriseMe.version = "1.1"
SurpriseMe.pendingInvite = nil
SurpriseMe.pendingElapsed = 0

-- Default configuration
local defaults = {
    enabled = true,
    keywords = {
        ["invite"] = true,
        ["inv"] = true,
        ["raid"] = true,
    },
    whisperResponse = true,
    responseMessage = "You have been invited to the group!",
    debugMode = false,
}

-- Initialize saved variables
function SurpriseMe:OnLoad()
    -- Initialize saved variables if they don't exist
    if not SurpriseMeDB then
        SurpriseMeDB = {}
    end
    
    -- Set defaults for missing values
    for key, value in pairs(defaults) do
        if SurpriseMeDB[key] == nil then
            SurpriseMeDB[key] = value
        end
    end
    
    if SurpriseMeDB.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Surprise Me!: Addon loaded successfully!", 0, 1, 0)
    end
end

-- Handle events
function SurpriseMe:OnEvent(event)
    if event == "ADDON_LOADED" and arg1 == "SurpriseMe-1.12" then
        SurpriseMe:OnLoad()
        SurpriseMe:Print("Surprise Me! addon loaded! Type /surpriseme to open settings.")
        
    elseif event == "CHAT_MSG_WHISPER" then
        if SurpriseMeDB and SurpriseMeDB.enabled then
            SurpriseMe:HandleWhisper(arg1, arg2)
        end
        
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        -- Roster events fire on login, dungeon-finder group formation, and
        -- when finder promotes you to leader. Never auto-convert here.
        -- Only complete a pending invite after we converted for a 6th player.
        SurpriseMe:TrySendPendingInvite()
    end
end

-- Handle incoming whispers
function SurpriseMe:HandleWhisper(message, sender)
    if not message or not sender then return end
    
    -- Convert message to lowercase for case-insensitive matching
    local lowerMessage = string.lower(message)
    
    -- Check if message contains any of our keywords
    local shouldInvite = false
    for keyword, enabled in pairs(SurpriseMeDB.keywords) do
        if enabled and string.find(lowerMessage, string.lower(keyword)) then
            shouldInvite = true
            break
        end
    end
    
    if shouldInvite then
        SurpriseMe:InvitePlayer(sender)
    end
end

-- True when dungeon finder / LFG queue or an LFG party is active.
-- Covers vanilla meeting stones plus LFG APIs some 1.12 servers backport.
function SurpriseMe:IsDungeonFinderActive()
    if IsInMeetingStoneQueue then
        local ok, queued = pcall(IsInMeetingStoneQueue)
        if ok and queued then
            return true
        end
    end

    if GetLFGMode then
        local ok, mode = pcall(GetLFGMode)
        if ok and mode and mode ~= "" then
            return true
        end
    end

    if HasLFGRestrictions then
        local ok, restricted = pcall(HasLFGRestrictions)
        if ok and restricted then
            return true
        end
    end

    if IsPartyLFG then
        local ok, isLfg = pcall(IsPartyLFG)
        if ok and isLfg then
            return true
        end
    end

    if GetLFGQueueStats then
        local ok, hasData = pcall(GetLFGQueueStats)
        if ok and hasData then
            return true
        end
    end

    -- TurtleWoW Looking For Turtles addon
    if type(LFT) == "table" then
        if LFT.queued or LFT.inQueue or LFT.isQueued then
            return true
        end
    end

    return false
end

-- Convert only when inviting a 6th player into a full 5-man party.
-- GetNumPartyMembers() excludes the player, so 4 means a full party of 5.
function SurpriseMe:ShouldConvertToRaidForInvite()
    if not SurpriseMeDB or not SurpriseMeDB.enabled then
        return false
    end
    if GetNumRaidMembers() > 0 then
        return false
    end
    if GetNumPartyMembers() < 4 then
        return false
    end
    if not IsPartyLeader() then
        return false
    end
    if SurpriseMe:IsDungeonFinderActive() then
        return false
    end
    return true
end

function SurpriseMe:SendInvite(playerName)
    -- Send the invite (1.12 uses InviteByName instead of InviteUnit)
    InviteByName(playerName)

    if SurpriseMeDB.whisperResponse and SurpriseMeDB.responseMessage then
        SendChatMessage(SurpriseMeDB.responseMessage, "WHISPER", nil, playerName)
    end

    SurpriseMe:Print("Invited " .. playerName .. " to the group!")
end

function SurpriseMe:TrySendPendingInvite()
    if not SurpriseMe.pendingInvite then
        return true
    end
    if GetNumRaidMembers() > 0 then
        local playerName = SurpriseMe.pendingInvite
        SurpriseMe.pendingInvite = nil
        SurpriseMe:StopPendingInviteTimer()
        SurpriseMe:SendInvite(playerName)
        return true
    end
    return false
end

function SurpriseMe:StopPendingInviteTimer()
    SurpriseMe.pendingElapsed = 0
    if SurpriseMe.eventFrame then
        SurpriseMe.eventFrame:SetScript("OnUpdate", nil)
    end
end

function SurpriseMe:StartPendingInviteTimer()
    SurpriseMe.pendingElapsed = 0
    if SurpriseMe.eventFrame then
        SurpriseMe.eventFrame:SetScript("OnUpdate", function()
            SurpriseMe:OnUpdate(arg1)
        end)
    end
end

function SurpriseMe:OnUpdate(elapsed)
    SurpriseMe.pendingElapsed = (SurpriseMe.pendingElapsed or 0) + (elapsed or 0)
    if SurpriseMe:TrySendPendingInvite() then
        return
    end
    -- ConvertToRaid can apply on a later frame; retry briefly, then invite anyway.
    if SurpriseMe.pendingElapsed > 2 then
        local playerName = SurpriseMe.pendingInvite
        SurpriseMe.pendingInvite = nil
        SurpriseMe:StopPendingInviteTimer()
        if playerName then
            SurpriseMe:SendInvite(playerName)
        end
    end
end

-- Invite a player to the group
function SurpriseMe:InvitePlayer(playerName)
    if not playerName then return end
    
    -- Check if player is already in group
    local playerInGroup = false
    
    -- Check if it's the player themselves
    if playerName == UnitName("player") then
        playerInGroup = true
    end
    
    -- Check party members
    if not playerInGroup then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == playerName then
                playerInGroup = true
                break
            end
        end
    end
    
    -- Check raid members
    if not playerInGroup then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid" .. i) == playerName then
                playerInGroup = true
                break
            end
        end
    end
    
    if playerInGroup then
        if SurpriseMeDB.debugMode then
            SurpriseMe:Print(playerName .. " is already in the group!")
        end
        return
    end
    
    local partySize = GetNumPartyMembers()
    local raidSize = GetNumRaidMembers()
    
    if SurpriseMeDB.debugMode then
        SurpriseMe:Print("Party size: " .. partySize .. ", Raid size: " .. raidSize)
    end
    
    -- Full 5-man party: convert only to make room for this 6th invite.
    if SurpriseMe:ShouldConvertToRaidForInvite() then
        if SurpriseMeDB.debugMode then
            SurpriseMe:Print("Converting party to raid to invite a 6th player...")
        end

        SurpriseMe.pendingInvite = playerName
        ConvertToRaid()
        if not SurpriseMe:TrySendPendingInvite() then
            SurpriseMe:StartPendingInviteTimer()
        end
        return
    end

    -- Full party but conversion is not allowed (dungeon finder, not leader, etc.)
    if partySize >= 4 and raidSize == 0 then
        if SurpriseMe:IsDungeonFinderActive() then
            SurpriseMe:Print("Cannot invite " .. playerName .. " while Dungeon Finder is active (party is full).")
        elseif not IsPartyLeader() then
            SurpriseMe:Print("Cannot convert to raid to invite " .. playerName .. " (you are not the party leader).")
        else
            SurpriseMe:Print("Cannot invite " .. playerName .. " - party is full.")
        end
        return
    end

    SurpriseMe:SendInvite(playerName)
end

-- Add a keyword
function SurpriseMe:AddKeyword(keyword)
    if not keyword or keyword == "" then
        SurpriseMe:Print("Please provide a keyword to add.")
        return
    end
    
    SurpriseMeDB.keywords[keyword] = true
    SurpriseMe:Print("Added keyword: " .. keyword)
    
    -- Refresh GUI if it's open
    if SurpriseMeGUI and SurpriseMeGUI.frame and SurpriseMeGUI.frame:IsVisible() then
        SurpriseMeGUI:RefreshKeywordList()
    end
end

-- Remove a keyword
function SurpriseMe:RemoveKeyword(keyword)
    if not keyword or keyword == "" then
        SurpriseMe:Print("Please provide a keyword to remove.")
        return
    end
    
    if SurpriseMeDB.keywords[keyword] then
        SurpriseMeDB.keywords[keyword] = nil
        SurpriseMe:Print("Removed keyword: " .. keyword)
    else
        SurpriseMe:Print("Keyword not found: " .. keyword)
    end
    
    -- Refresh GUI if it's open
    if SurpriseMeGUI and SurpriseMeGUI.frame and SurpriseMeGUI.frame:IsVisible() then
        SurpriseMeGUI:RefreshKeywordList()
    end
end

-- Toggle addon on/off
function SurpriseMe:Toggle()
    SurpriseMeDB.enabled = not SurpriseMeDB.enabled
    local status = SurpriseMeDB.enabled and "enabled" or "disabled"
    SurpriseMe:Print("Surprise Me! is now " .. status)
end

-- Print message to chat
function SurpriseMe:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Surprise Me!]|r " .. message)
end

-- Slash command handler
function SurpriseMe:SlashCommand(msg)
    -- Ensure SurpriseMeDB is initialized
    if not SurpriseMeDB then
        SurpriseMe:OnLoad()
    end
    
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, word)
    end
    
    local command = args[1] and string.lower(args[1]) or ""
    
    if command == "" or command == "gui" or command == "config" then
        SurpriseMeGUI:Show()
    elseif command == "toggle" then
        SurpriseMe:Toggle()
    elseif command == "add" then
        if args[2] then
            SurpriseMe:AddKeyword(args[2])
        else
            SurpriseMe:Print("Usage: /surpriseme add <keyword>")
        end
    elseif command == "remove" or command == "del" then
        if args[2] then
            SurpriseMe:RemoveKeyword(args[2])
        else
            SurpriseMe:Print("Usage: /surpriseme remove <keyword>")
        end
    elseif command == "list" then
        SurpriseMe:ListKeywords()
    elseif command == "help" then
        SurpriseMe:ShowHelp()
    else
        SurpriseMe:Print("Unknown command. Type '/surpriseme help' for available commands.")
    end
end

-- List all keywords
function SurpriseMe:ListKeywords()
    SurpriseMe:Print("Current keywords:")
    local count = 0
    for keyword, enabled in pairs(SurpriseMeDB.keywords) do
        if enabled then
            SurpriseMe:Print("  - " .. keyword)
            count = count + 1
        end
    end
    if count == 0 then
        SurpriseMe:Print("  No keywords configured.")
    end
end

-- Show help
function SurpriseMe:ShowHelp()
    SurpriseMe:Print("Available commands:")
    SurpriseMe:Print("  /surpriseme - Open configuration GUI")
    SurpriseMe:Print("  /surpriseme toggle - Enable/disable auto invite")
    SurpriseMe:Print("  /surpriseme add <keyword> - Add a keyword")
    SurpriseMe:Print("  /surpriseme remove <keyword> - Remove a keyword")
    SurpriseMe:Print("  /surpriseme list - List all keywords")
    SurpriseMe:Print("  /surpriseme help - Show this help")
end

-- Register slash commands
SLASH_SURPRISEME1 = "/surpriseme"
SLASH_SURPRISEME2 = "/sm"
SlashCmdList["SURPRISEME"] = function(msg)
    SurpriseMe:SlashCommand(msg)
end

-- Create the main frame
local frame = CreateFrame("Frame", "SurpriseMeFrame")
SurpriseMe.eventFrame = frame
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:SetScript("OnEvent", function() SurpriseMe:OnEvent(event) end)
