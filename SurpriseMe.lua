-- Surprise Me! Core Module
-- Handles auto-inviting functionality for TurtleWoW

SurpriseMe = {}
SurpriseMe.version = "1.0"

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
    if event == "ADDON_LOADED" and arg1 == "SurpriseMe" then
        SurpriseMe:OnLoad()
        SurpriseMe:Print("Surprise Me! addon loaded! Type /surpriseme to open settings.")
        
    elseif event == "CHAT_MSG_WHISPER" then
        if SurpriseMeDB.enabled then
            SurpriseMe:HandleWhisper(arg1, arg2)
        end
        
    elseif event == "PARTY_MEMBERS_CHANGED" then
        -- Check if we need to convert to raid
        SurpriseMe:CheckRaidConversion()
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
    
    -- Check if we're in a full party and need to convert to raid
    local partySize = GetNumPartyMembers()
    local raidSize = GetNumRaidMembers()
    
    if SurpriseMeDB.debugMode then
        SurpriseMe:Print("Party size: " .. partySize .. ", Raid size: " .. raidSize)
    end
    
    -- If we're in a party of 5 (including leader), convert to raid
    if partySize >= 4 and raidSize == 0 then
        ConvertToRaid()
        if SurpriseMeDB.debugMode then
            SurpriseMe:Print("Converting party to raid...")
        end
    end
    
    -- Send the invite (1.12 uses InviteByName instead of InviteUnit)
    InviteByName(playerName)
    
    -- Send whisper response if enabled
    if SurpriseMeDB.whisperResponse and SurpriseMeDB.responseMessage then
        SendChatMessage(SurpriseMeDB.responseMessage, "WHISPER", nil, playerName)
    end
    
    SurpriseMe:Print("Invited " .. playerName .. " to the group!")
end

-- Check if we need to convert party to raid
function SurpriseMe:CheckRaidConversion()
    local partySize = GetNumPartyMembers()
    local raidSize = GetNumRaidMembers()
    
    -- If we have 5+ people and we're still in party mode, convert to raid
    if partySize >= 4 and raidSize == 0 then
        ConvertToRaid()
        if SurpriseMeDB.debugMode then
            SurpriseMe:Print("Auto-converting to raid due to party size")
        end
    end
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
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_WHISPER") 
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:SetScript("OnEvent", function() SurpriseMe:OnEvent(event) end)
