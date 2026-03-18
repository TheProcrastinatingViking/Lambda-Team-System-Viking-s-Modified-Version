if SERVER then AddCSLuaFile() end

LambdaTeams = LambdaTeams or {}

LambdaTeams.AlliedTeams = LambdaTeams.AlliedTeams or {}
LambdaTeams.AOSExempt   = LambdaTeams.AOSExempt   or {}

local ALLIANCE_FILE   = "lambdaplayers/team_alliances.json"
local AOS_EXEMPT_FILE = "lambdaplayers/aos_exempt.json"

function LambdaTeams:LoadAlliances()
    EnsureDataFolder()

    if not file.Exists(ALLIANCE_FILE, "DATA") then
        LambdaTeams.AlliedTeams = {}
        WriteJSON(ALLIANCE_FILE, {})
        print("ALERT: The Team Alliances file is being generated.")
        return
    end

    local data = ReadJSON(ALLIANCE_FILE)

    if istable(data) then
        for k, v in pairs(data) do
            if istable(v) then
                for k2, _ in pairs(v) do
                    v[tostring(k2)] = true
                end
            end
        end

        LambdaTeams.AlliedTeams = data
        print("Loaded alliances: " .. table.Count(data))
    else
        print("WARNING: Alliance file corrupted. Resetting...")
        LambdaTeams.AlliedTeams = {}
        WriteJSON(ALLIANCE_FILE, {})
    end
end

function LambdaTeams:LoadAOSExempt()
    EnsureDataFolder()

    if not file.Exists(AOS_EXEMPT_FILE, "DATA") then
        LambdaTeams.AOSExempt = {}
        WriteJSON(AOS_EXEMPT_FILE, {})
        print("ALERT: The Attack on Sight Exemptions file is being generated.")
        return
    end

    local data = ReadJSON(AOS_EXEMPT_FILE)

    if istable(data) then
        for k, v in pairs(data) do
            if istable(v) then
                for k2, _ in pairs(v) do
                    v[tostring(k2)] = true
                end
            end
        end

        LambdaTeams.AOSExempt = data
        print("Loaded AOS exemptions: " .. table.Count(data))
    else
        print("WARNING: AOS exempt file corrupted. Resetting...")
        LambdaTeams.AOSExempt = {}
        WriteJSON(AOS_EXEMPT_FILE, {})
    end
end

local function EnsureDataFolder()
    if not file.Exists("lambdaplayers", "DATA") then
        file.CreateDir("lambdaplayers")
    end
end

local function ReadJSON(path)
    if LAMBDAFS and LAMBDAFS.ReadFile then
        return LAMBDAFS:ReadFile(path, "json")
    end

    if not file.Exists(path, "DATA") then return nil end
    local raw = file.Read(path, "DATA")
    if not raw or raw == "" then return nil end
    return util.JSONToTable(raw)
end

local function WriteJSON(path, tbl)
    if LAMBDAFS and LAMBDAFS.WriteFile then
        LAMBDAFS:WriteFile(path, tbl, "json", false)
        return
    end

    file.Write(path, util.TableToJSON(tbl, false) or "{}")
end

function LambdaTeams:LoadAlliances()
    EnsureDataFolder()

    if not file.Exists(ALLIANCE_FILE, "DATA") then
        LambdaTeams.AlliedTeams = {}
        print("ALERT: The Team Alliances file is now loading.")
        return
    end

    local data = ReadJSON(ALLIANCE_FILE)

    if istable(data) then
        for k, v in pairs(data) do
            if istable(v) then
                for k2, _ in pairs(v) do
                    v[tostring(k2)] = true
                end
            end
        end

        LambdaTeams.AlliedTeams = data
        print("Loaded alliances: " .. table.Count(data))
    else
        print("WARNING: Alliance file corrupted. Resetting...")
        LambdaTeams.AlliedTeams = {}
    end
end

function LambdaTeams:SaveAlliances()
    EnsureDataFolder()

    local safe = {}

    for teamA, tbl in pairs(LambdaTeams.AlliedTeams or {}) do
        safe[tostring(teamA)] = {}
        for teamB, _ in pairs(tbl) do
            safe[tostring(teamA)][tostring(teamB)] = true
        end
    end

    WriteJSON(ALLIANCE_FILE, safe)
    print("Team alliances saved (" .. tostring(table.Count(safe)) .. ")")
end

function LambdaTeams:LoadAOSExempt()
    EnsureDataFolder()

    if not file.Exists(AOS_EXEMPT_FILE, "DATA") then
        LambdaTeams.AOSExempt = {}
        print("ALERT: The Attack on Sight Exemption file is now loading.")
        return
    end

    local data = ReadJSON(AOS_EXEMPT_FILE)

    if istable(data) then
        for k, v in pairs(data) do
            if istable(v) then
                for k2, _ in pairs(v) do
                    v[tostring(k2)] = true
                end
            end
        end

        LambdaTeams.AOSExempt = data
        print("Loaded AOS exemptions: " .. table.Count(data))
    else
        print("WARNING: AOS exempt file corrupted. Resetting...")
        LambdaTeams.AOSExempt = {}
    end
end

function LambdaTeams:SaveAOSExempt()
    EnsureDataFolder()

    local safe = {}

    for teamA, tbl in pairs(LambdaTeams.AOSExempt or {}) do
        safe[tostring(teamA)] = {}
        for teamB, _ in pairs(tbl) do
            safe[tostring(teamA)][tostring(teamB)] = true
        end
    end

    WriteJSON(AOS_EXEMPT_FILE, safe)
    print("AOS exemptions saved (" .. tostring(table.Count(safe)) .. ")")
end

function LambdaTeams:IsAllied(teamA, teamB)
    teamA = tostring(teamA or "")
    teamB = tostring(teamB or "")
    local t = LambdaTeams.AlliedTeams and LambdaTeams.AlliedTeams[teamA]
    return (t and t[teamB]) and true or false
end

function LambdaTeams:AddAlliance(teamA, teamB)
    teamA = tostring(teamA or "")
    teamB = tostring(teamB or "")
    if teamA == "" or teamB == "" or teamA == teamB then return end

    LambdaTeams.AlliedTeams[teamA] = LambdaTeams.AlliedTeams[teamA] or {}
    LambdaTeams.AlliedTeams[teamB] = LambdaTeams.AlliedTeams[teamB] or {}

    LambdaTeams.AlliedTeams[teamA][teamB] = true
    LambdaTeams.AlliedTeams[teamB][teamA] = true

    LambdaTeams:SaveAlliances()
end

function LambdaTeams:RemoveAlliance(teamA, teamB)
    teamA = tostring(teamA or "")
    teamB = tostring(teamB or "")
    if teamA == "" or teamB == "" then return end

    local a = LambdaTeams.AlliedTeams[teamA]
    if a then a[teamB] = nil end

    local b = LambdaTeams.AlliedTeams[teamB]
    if b then b[teamA] = nil end

    LambdaTeams:SaveAlliances()
end

function LambdaTeams:ClearAllAlliances()
    LambdaTeams.AlliedTeams = {}
    LambdaTeams:SaveAlliances()
end

function LambdaTeams:IsAOSExempt(teamA, teamB)
    teamA = tostring(teamA or "")
    teamB = tostring(teamB or "")
    local t = LambdaTeams.AOSExempt and LambdaTeams.AOSExempt[teamA]
    return (t and t[teamB]) and true or false
end

function LambdaTeams:AddAOSExemption(teamA, teamB)
    teamA = tostring(teamA or "")
    teamB = tostring(teamB or "")
    if teamA == "" or teamB == "" or teamA == teamB then return end

    LambdaTeams.AOSExempt[teamA] = LambdaTeams.AOSExempt[teamA] or {}
    LambdaTeams.AOSExempt[teamB] = LambdaTeams.AOSExempt[teamB] or {}

    LambdaTeams.AOSExempt[teamA][teamB] = true
    LambdaTeams.AOSExempt[teamB][teamA] = true

    LambdaTeams:SaveAOSExempt()
end

function LambdaTeams:RemoveAOSExemption(teamA, teamB)
    teamA = tostring(teamA or "")
    teamB = tostring(teamB or "")
    if teamA == "" or teamB == "" then return end

    local a = LambdaTeams.AOSExempt[teamA]
    if a then a[teamB] = nil end

    local b = LambdaTeams.AOSExempt[teamB]
    if b then b[teamA] = nil end

    LambdaTeams:SaveAOSExempt()
end

function LambdaTeams:ClearAllAOSExempt()
    LambdaTeams.AOSExempt = {}
    LambdaTeams:SaveAOSExempt()
end

local function LTS_IsSuperAdmin(ply)
    if not IsValid(ply) then return false end
    if game.SinglePlayer() then return true end
    if ply.IsListenServerHost and ply:IsListenServerHost() then return true end
    return ply:IsSuperAdmin()
end

if SERVER then
    util.AddNetworkString("LTS_SendAllianceData")
    util.AddNetworkString("LTS_RequestAllianceData")
    util.AddNetworkString("LTS_AddAlliance")
    util.AddNetworkString("LTS_RemoveAlliance")
    util.AddNetworkString("LTS_AllAllies")
    util.AddNetworkString("LTS_ClearAllAllies")

    util.AddNetworkString("LTS_RequestAOSExemptData")
    util.AddNetworkString("LTS_SendAOSExemptData")
    util.AddNetworkString("LTS_AddAOSExempt")
    util.AddNetworkString("LTS_RemoveAOSExempt")
    util.AddNetworkString("LTS_ClearAOSExempt")

    local function TeamExists(name)
        if not name or name == "" then return false end
        if LambdaTeams and LambdaTeams.TeamData and LambdaTeams.TeamData[name] then return true end
        return true
    end

    local function BroadcastAllianceData()
        net.Start("LTS_SendAllianceData")
            net.WriteTable(LambdaTeams.AlliedTeams or {})
        net.Broadcast()
    end

    local function BroadcastAOSData()
        net.Start("LTS_SendAOSExemptData")
            net.WriteTable(LambdaTeams.AOSExempt or {})
        net.Broadcast()
    end

    net.Receive("LTS_RequestAllianceData", function(_, ply)
        if not IsValid(ply) then return end
        net.Start("LTS_SendAllianceData")
            net.WriteTable(LambdaTeams.AlliedTeams or {})
        net.Send(ply)
    end)

    net.Receive("LTS_RequestAOSExemptData", function(_, ply)
        if not IsValid(ply) then return end
        net.Start("LTS_SendAOSExemptData")
            net.WriteTable(LambdaTeams.AOSExempt or {})
        net.Send(ply)
    end)

    net.Receive("LTS_AddAlliance", function(_, ply)
        if not LTS_IsSuperAdmin(ply) then return end
        local a = net.ReadString()
        local b = net.ReadString()
        if not TeamExists(a) or not TeamExists(b) then return end

        LambdaTeams:AddAlliance(a, b)
        BroadcastAllianceData()
    end)

    net.Receive("LTS_RemoveAlliance", function(_, ply)
        if not LTS_IsSuperAdmin(ply) then return end
        local a = net.ReadString()
        local b = net.ReadString()
        if not TeamExists(a) or not TeamExists(b) then return end

        LambdaTeams:RemoveAlliance(a, b)
        BroadcastAllianceData()
    end)

    net.Receive("LTS_AllAllies", function(_, ply)
        if not LTS_IsSuperAdmin(ply) then return end

        local teams = {}
        if LambdaTeams and LambdaTeams.TeamData then
            for name, _ in pairs(LambdaTeams.TeamData) do
                teams[#teams + 1] = tostring(name)
            end
        end

        for i = 1, #teams do
            for j = i + 1, #teams do
                LambdaTeams:AddAlliance(teams[i], teams[j])
            end
        end

        BroadcastAllianceData()
    end)

    net.Receive("LTS_ClearAllAllies", function(_, ply)
        if not LTS_IsSuperAdmin(ply) then return end
        LambdaTeams:ClearAllAlliances()
        BroadcastAllianceData()
    end)

    net.Receive("LTS_AddAOSExempt", function(_, ply)
        if not LTS_IsSuperAdmin(ply) then return end
        local a = net.ReadString()
        local b = net.ReadString()
        if not TeamExists(a) or not TeamExists(b) then return end

        LambdaTeams:AddAOSExemption(a, b)
        BroadcastAOSData()
    end)

    net.Receive("LTS_RemoveAOSExempt", function(_, ply)
        if not LTS_IsSuperAdmin(ply) then return end
        local a = net.ReadString()
        local b = net.ReadString()
        if not TeamExists(a) or not TeamExists(b) then return end

        LambdaTeams:RemoveAOSExemption(a, b)
        BroadcastAOSData()
    end)

    net.Receive("LTS_ClearAOSExempt", function(_, ply)
        if not LTS_IsSuperAdmin(ply) then return end
        LambdaTeams:ClearAllAOSExempt()
        BroadcastAOSData()
    end)

    hook.Add("Initialize", "LTS_Relations_LoadOnInit", function()
        if LambdaTeams and LambdaTeams.LoadAlliances then
            LambdaTeams:LoadAlliances()
        end
        if LambdaTeams and LambdaTeams.LoadAOSExempt then
            LambdaTeams:LoadAOSExempt()
        end
    end)

    hook.Add("ShutDown", "LTS_SaveRelations_OnShutdown", function()
        if LambdaTeams and LambdaTeams.SaveAlliances then
            LambdaTeams:SaveAlliances()
        end
        if LambdaTeams and LambdaTeams.SaveAOSExempt then
            LambdaTeams:SaveAOSExempt()
        end
    end)

    hook.Add("OnReloaded", "LTS_SaveRelations_OnReload", function()
        if LambdaTeams and LambdaTeams.SaveAlliances then
            LambdaTeams:SaveAlliances()
        end
        if LambdaTeams and LambdaTeams.SaveAOSExempt then
            LambdaTeams:SaveAOSExempt()
        end
    end)
end

if CLIENT then
    net.Receive("LTS_SendAllianceData", function()
        LambdaTeams.AlliedTeams = net.ReadTable() or {}
    end)

    net.Receive("LTS_SendAOSExemptData", function()
        LambdaTeams.AOSExempt = net.ReadTable() or {}
    end)

    concommand.Add("lts_relations_request", function()
        net.Start("LTS_RequestAllianceData") net.SendToServer()
        net.Start("LTS_RequestAOSExemptData") net.SendToServer()
    end)
end
