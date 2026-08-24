-- Headless tests for Surprise Me! raid conversion.
-- Mocks the WoW 1.12 API and loads SurpriseMe-1.12.lua.

local testsPassed = 0
local testsFailed = 0
local convertCalls = 0
local inviteCalls = {}
local chatMessages = {}
local registeredEvents = {}

-- Lua 5.1+ compatibility with WoW 1.12's string.gfind
if not string.gfind and string.gmatch then
    string.gfind = string.gmatch
end

local env = {
    partyMembers = 0,
    raidMembers = 0,
    isLeader = true,
    meetingStoneQueue = false,
    lfgMode = nil,
    hasLfgRestrictions = false,
    isPartyLfg = false,
    lfgQueueStats = nil,
    playerName = "Leader",
    partyNames = {},
    raidNames = {},
    convertSync = true,
}

local function resetEnv(overrides)
    env.partyMembers = 0
    env.raidMembers = 0
    env.isLeader = true
    env.meetingStoneQueue = false
    env.lfgMode = nil
    env.hasLfgRestrictions = false
    env.isPartyLfg = false
    env.lfgQueueStats = nil
    env.playerName = "Leader"
    env.partyNames = {}
    env.raidNames = {}
    env.convertSync = true
    convertCalls = 0
    inviteCalls = {}
    chatMessages = {}
    if SurpriseMe then
        SurpriseMe.pendingInvite = nil
        SurpriseMe.pendingElapsed = 0
    end
    if SurpriseMeDB then
        SurpriseMeDB.enabled = true
        SurpriseMeDB.whisperResponse = false
        SurpriseMeDB.debugMode = false
    end
    if overrides then
        for k, v in pairs(overrides) do
            env[k] = v
        end
    end
end

-- Minimal WoW frame mock
local Frame = {}
Frame.__index = Frame
function Frame:RegisterEvent(eventName)
    registeredEvents[eventName] = true
end
function Frame:SetScript(script, handler)
    self.scripts = self.scripts or {}
    self.scripts[script] = handler
end

function CreateFrame(frameType, name)
    local frame = setmetatable({ scripts = {} }, Frame)
    if name then
        _G[name] = frame
    end
    return frame
end

function GetNumPartyMembers()
    return env.partyMembers
end

function GetNumRaidMembers()
    return env.raidMembers
end

function IsPartyLeader()
    if env.isLeader then
        return 1
    end
    return nil
end

function IsInMeetingStoneQueue()
    return env.meetingStoneQueue
end

function GetLFGMode()
    return env.lfgMode
end

function HasLFGRestrictions()
    return env.hasLfgRestrictions
end

function IsPartyLFG()
    return env.isPartyLfg
end

function GetLFGQueueStats()
    return env.lfgQueueStats
end

function UnitName(unit)
    if unit == "player" then
        return env.playerName
    end
    local kind, index = string.find(unit, "^(party)(%d+)$")
    if not kind then
        kind, index = string.find(unit, "^(raid)(%d+)$")
    end
    -- Fallback simple parse
    if string.sub(unit, 1, 5) == "party" then
        local i = tonumber(string.sub(unit, 6))
        return env.partyNames[i]
    end
    if string.sub(unit, 1, 4) == "raid" then
        local i = tonumber(string.sub(unit, 5))
        return env.raidNames[i]
    end
    return nil
end

function ConvertToRaid()
    convertCalls = convertCalls + 1
    if env.convertSync then
        env.raidMembers = env.partyMembers + 1
        env.partyMembers = 0
    end
end

function InviteByName(name)
    table.insert(inviteCalls, name)
end

function SendChatMessage()
end

DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, msg)
        table.insert(chatMessages, msg)
    end
}

SlashCmdList = {}
arg1 = nil
arg2 = nil
event = nil
LFT = nil

dofile("SurpriseMe-1.12.lua")

SurpriseMeDB = {
    enabled = true,
    keywords = { invite = true, inv = true, raid = true },
    whisperResponse = false,
    responseMessage = "You have been invited to the group!",
    debugMode = false,
}

local function assertTrue(cond, message)
    if cond then
        testsPassed = testsPassed + 1
        print("  PASS  " .. message)
    else
        testsFailed = testsFailed + 1
        print("  FAIL  " .. message)
    end
end

local function assertEqual(actual, expected, message)
    if actual == expected then
        testsPassed = testsPassed + 1
        print("  PASS  " .. message)
    else
        testsFailed = testsFailed + 1
        print("  FAIL  " .. message .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
    end
end

local function fireEvent(eventName, a1, a2)
    event = eventName
    arg1 = a1
    arg2 = a2
    SurpriseMe:OnEvent(eventName)
end

print("Surprise Me! raid conversion tests")
print("==================================")

print("\nDecision helper")
resetEnv({ partyMembers = 0, raidMembers = 0 })
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "solo does not convert")

resetEnv({ partyMembers = 3, raidMembers = 0 })
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "4-player party does not convert")

resetEnv({ partyMembers = 4, raidMembers = 0, isLeader = true })
assertTrue(SurpriseMe:ShouldConvertToRaidForInvite(), "full 5-player party converts when inviting 6th")

resetEnv({ partyMembers = 4, raidMembers = 0, isLeader = false })
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "non-leader does not convert")

resetEnv({ partyMembers = 4, raidMembers = 5 })
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "already in a raid does not convert")

resetEnv({ partyMembers = 4, raidMembers = 0 })
SurpriseMeDB.enabled = false
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "disabled addon does not convert")

print("\nDungeon Finder detection")
resetEnv({ partyMembers = 4, raidMembers = 0, meetingStoneQueue = true })
assertTrue(SurpriseMe:IsDungeonFinderActive(), "meeting stone queue is dungeon finder")
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "queued meeting stone does not convert")

resetEnv({ partyMembers = 4, raidMembers = 0, lfgMode = "queued" })
assertTrue(SurpriseMe:IsDungeonFinderActive(), "GetLFGMode queued is dungeon finder")
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "LFG queued does not convert")

resetEnv({ partyMembers = 4, raidMembers = 0, lfgMode = "lfgparty" })
assertTrue(SurpriseMe:IsDungeonFinderActive(), "GetLFGMode lfgparty is dungeon finder")
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "LFG party does not convert")

resetEnv({ partyMembers = 4, raidMembers = 0, hasLfgRestrictions = true })
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "HasLFGRestrictions does not convert")

resetEnv({ partyMembers = 4, raidMembers = 0, isPartyLfg = true })
assertTrue(not SurpriseMe:ShouldConvertToRaidForInvite(), "IsPartyLFG does not convert")

LFT = { queued = true }
resetEnv({ partyMembers = 4, raidMembers = 0 })
assertTrue(SurpriseMe:IsDungeonFinderActive(), "LFT queued is dungeon finder")
LFT = nil

print("\nReported Dungeon Finder regressions: roster events must not convert")
local function assertRosterDoesNotConvert(label, overrides)
    resetEnv(overrides)
    fireEvent("PARTY_MEMBERS_CHANGED")
    assertEqual(convertCalls, 0, label .. " (PARTY_MEMBERS_CHANGED)")
    fireEvent("RAID_ROSTER_UPDATE")
    assertEqual(convertCalls, 0, label .. " (RAID_ROSTER_UPDATE)")
end

assertRosterDoesNotConvert("login while queued for dungeon finder", {
    partyMembers = 4,
    raidMembers = 0,
    isLeader = true,
    lfgMode = "queued",
})

assertRosterDoesNotConvert("in a dungeon finder group", {
    partyMembers = 4,
    raidMembers = 0,
    isLeader = true,
    lfgMode = "lfgparty",
})

assertRosterDoesNotConvert("dungeon finder makes you leader", {
    partyMembers = 4,
    raidMembers = 0,
    isLeader = true,
    lfgMode = "lfgparty",
})

assertRosterDoesNotConvert("full 5-man party login without LFG APIs", {
    partyMembers = 4,
    raidMembers = 0,
    isLeader = true,
})

print("\nInvite path converts only for a 6th player")
resetEnv({ partyMembers = 3, raidMembers = 0, isLeader = true })
SurpriseMe:InvitePlayer("Sixth")
assertEqual(convertCalls, 0, "inviting a 5th player does not convert")
assertEqual(inviteCalls[1], "Sixth", "inviting a 5th player still sends invite")

resetEnv({ partyMembers = 4, raidMembers = 0, isLeader = true, convertSync = true })
SurpriseMe:InvitePlayer("Sixth")
assertEqual(convertCalls, 1, "inviting a 6th player converts to raid")
assertEqual(inviteCalls[1], "Sixth", "inviting a 6th player sends invite after convert")

resetEnv({ partyMembers = 4, raidMembers = 0, isLeader = true, lfgMode = "lfgparty" })
SurpriseMe:InvitePlayer("Sixth")
assertEqual(convertCalls, 0, "6th invite in dungeon finder group does not convert")
assertEqual(inviteCalls[1], nil, "6th invite in dungeon finder group is blocked")

resetEnv({ partyMembers = 4, raidMembers = 0, isLeader = true, convertSync = false })
SurpriseMe:InvitePlayer("Sixth")
assertEqual(convertCalls, 1, "async convert still calls ConvertToRaid")
assertEqual(SurpriseMe.pendingInvite, "Sixth", "async convert stores pending invite")
assertEqual(inviteCalls[1], nil, "async convert waits until raid exists")
env.raidMembers = 5
fireEvent("RAID_ROSTER_UPDATE")
assertEqual(inviteCalls[1], "Sixth", "pending 6th invite sends after RAID_ROSTER_UPDATE")
assertEqual(SurpriseMe.pendingInvite, nil, "pending invite is cleared")

print("\nKeyword whisper still invites in a normal party")
resetEnv({ partyMembers = 1, raidMembers = 0 })
fireEvent("CHAT_MSG_WHISPER", "inv please", "Alice")
assertEqual(inviteCalls[1], "Alice", "keyword whisper invites the sender")
assertEqual(convertCalls, 0, "keyword whisper in small party does not convert")

print("\nCheckRaidConversion removed")
assertTrue(SurpriseMe.CheckRaidConversion == nil, "legacy CheckRaidConversion helper is gone")

print("\nGit/folder addon name")
SurpriseMeDB = nil
fireEvent("ADDON_LOADED", "SurpriseMe")
assertTrue(SurpriseMeDB == nil, "legacy SurpriseMe folder name does not initialize")
fireEvent("ADDON_LOADED", "SurpriseMe-1.12")
assertTrue(SurpriseMeDB ~= nil, "SurpriseMe-1.12 addon name initializes saved vars")

local toc = io.open("SurpriseMe-1.12.toc", "r")
assertTrue(toc ~= nil, "SurpriseMe-1.12.toc exists for git clone folder name")
local tocText = toc and toc:read("*a") or ""
if toc then toc:close() end
assertTrue(string.find(tocText, "SurpriseMe-1.12.lua", 1, true) ~= nil, "toc loads SurpriseMe-1.12.lua")
assertTrue(string.find(tocText, "SurpriseMe-1.12-GUI.lua", 1, true) ~= nil, "toc loads SurpriseMe-1.12-GUI.lua")

print("\n==================================")
print(string.format("Passed: %d  Failed: %d", testsPassed, testsFailed))
if testsFailed > 0 then
    os.exit(1)
end
