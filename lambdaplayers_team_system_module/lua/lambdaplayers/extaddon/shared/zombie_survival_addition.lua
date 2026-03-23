if SERVER then AddCSLuaFile() end

if not CreateLambdaConvar or not CreateLambdaConsoleCommand then return end
if not LambdaTeams then return end

local ZS_GAMEID = 9

local COLOR_TAG = Color(255, 255, 255)
local COLOR_LTS = Color(140, 220, 255)
local DEFAULT_ZOMBIES = { "npc_zombie", "npc_fastzombie", "npc_zombine", "npc_poisonzombie" }
local DEFAULT_SPECIAL = { "npc_antlion", "npc_antlion", "npc_antlion", "npc_antlionguard" }
local NET_ZS_SETNPCLISTS = "LTS_ZS_SetNPCLists"
local CV_ZS_SND_MATCHSTART = "lambdaplayers_teamsystem_zs_snd_matchstart"
local CV_ZS_SND_MATCHEND   = "lambdaplayers_teamsystem_zs_snd_matchend"
local CV_ZS_SND_ROUNDSTART = "lambdaplayers_teamsystem_zs_snd_roundstart"
local CV_ZS_SND_ROUNDEND   = "lambdaplayers_teamsystem_zs_snd_roundend"
local CV_ZS_SND_SPECIALROUNDSTART = "lambdaplayers_teamsystem_zs_snd_specialroundstart"

CreateLambdaConvar( CV_ZS_SND_MATCHSTART, "lambdaplayers/zs/roundstart.mp3", true, true, false, "Sound played when Zombie Survival starts.", 0, 1, { name = "Sound - Match Start", type = "Text", category = "Team System - Zombie Survival" } )
CreateLambdaConvar( CV_ZS_SND_MATCHEND, "lambdaplayers/zs/matchend.mp3", true, true, false, "Sound played when Zombie Survival ends/stops.", 0, 1, { name = "Sound - Match End", type = "Text", category = "Team System - Zombie Survival" } )
CreateLambdaConvar( CV_ZS_SND_ROUNDSTART, "lambdaplayers/zs/roundstart.mp3", true, true, false, "Sound played when a round starts.", 0, 1, { name = "Sound - Round Start", type = "Text", category = "Team System - Zombie Survival" } )
CreateLambdaConvar( CV_ZS_SND_ROUNDEND, "lambdaplayers/zs/roundend.mp3", true, true, false, "Sound played when a round ends.", 0, 1, { name = "Sound - Round End", type = "Text", category = "Team System - Zombie Survival" } )
CreateLambdaConvar( CV_ZS_SND_SPECIALROUNDSTART, "lambdaplayers/zs/specialroundstart.mp3", true, true, false, "Sound played when a special round starts.", 0, 1, { name = "Sound - Special Round Start", type = "Text", category = "Team System - Zombie Survival" } )

local function ChatAll(...)
    if LambdaPlayers_ChatAdd then
        LambdaPlayers_ChatAdd(nil, COLOR_TAG, "[LTS:ZS] ", COLOR_LTS, ...)
    else
        local parts = {}
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            if isstring(v) then parts[#parts + 1] = v end
        end
        print("[LTS:ZS] " .. table.concat(parts, ""))
    end
end

local function IsTeamSystemEnabled()
    return GetGlobalBool("LambdaTeamSystem_Enabled", false)
end

local function SafeWeaponClass(s)
    if not isstring(s) then return "" end
    s = string.Trim(s)
    if not string.match(s, "^[%w_]+$") then return "" end
    return s
end

local function SafeNPCClass(s)
    if not isstring(s) then return "" end
    s = string.Trim(string.lower(s))
    if not string.match(s, "^[%w_]+$") then return "" end
    return s
end

if SERVER then
    util.AddNetworkString(NET_ZS_SETNPCLISTS)

    net.Receive(NET_ZS_SETNPCLISTS, function(_, ply)
        if not IsValid(ply) or not ply:IsPlayer() or not ply:IsSuperAdmin() then return end

        local useCustom = net.ReadBool()

        local zCount = math.min(net.ReadUInt(7), 64)
        local zombies, zSeen = {}, {}
        for i = 1, zCount do
            local c = SafeNPCClass(net.ReadString() or "")
            if c ~= "" and not zSeen[c] then zSeen[c] = true zombies[#zombies + 1] = c end
        end

        local sCount = math.min(net.ReadUInt(7), 64)
        local special, sSeen = {}, {}
        for i = 1, sCount do
            local c = SafeNPCClass(net.ReadString() or "")
            if c ~= "" and not sSeen[c] then sSeen[c] = true special[#special + 1] = c end
        end

        -- SPAMMING STRINGS DOESNT HELP WITH THIS GAMEMODE EITHER
        local function JoinCapped(t)
            local out = table.concat(t, ",")
            if #out > 2048 then out = string.sub(out, 1, 2048) end
            return out
        end

        local cvUse = GetConVar("lambdaplayers_teamsystem_zs_usecustomnpcs")
        local cvZ   = GetConVar("lambdaplayers_teamsystem_zs_zombie_npclist")
        local cvS   = GetConVar("lambdaplayers_teamsystem_zs_special_npclist")

        if cvUse then cvUse:SetBool(useCustom) end
        if cvZ then cvZ:SetString(JoinCapped(zombies)) end
        if cvS then cvS:SetString(JoinCapped(special)) end

        ply:ChatPrint("[LTS:ZS] Updated Zombie Survival NPC lists.")
    end)
end

local function ParseNPCList(str, maxItems)
    maxItems = maxItems or 64
    local out, seen = {}, {}
    if not isstring(str) then return out end

    for token in string.gmatch(str, "[^,;|%s]+") do
        if #out >= maxItems then break end
        token = SafeNPCClass(token)
        if token ~= "" and not seen[token] then
            seen[token] = true
            out[#out + 1] = token
        end
    end

    return out
end

local function DeepCopyBoolTable2D(src)
    local out = {}
    for k, v in pairs(src or {}) do
        out[k] = {}
        if istable(v) then
            for k2, v2 in pairs(v) do
                out[k][k2] = (v2 == true)
            end
        end
    end
    return out
end

local function GetAllParticipants(includeNoTeam)
    local add = table.Add
    local list = {}
    add(list, GetLambdaPlayers())
    add(list, player.GetAll())

    local teams = {}
    local anyCount = 0

    for _, ent in ipairs(list) do
        if not IsValid(ent) then continue end

        local t = LambdaTeams:GetPlayerTeam(ent)
        if (not t or t == "") and includeNoTeam then
            t = "Neutral"
        end
        if not t or t == "" then continue end

        teams[t] = teams[t] or { members = {} }
        teams[t].members[#teams[t].members + 1] = ent
        anyCount = anyCount + 1
    end

    return teams, anyCount
end

local function IsAliveParticipant(ent, state)
    if not IsValid(ent) then return false end

    if ent:IsPlayer() then
        if state.deadPlayers[ent] then return false end
        return ent:Alive()
    end

    if ent.IsLambdaPlayer then
        if ent.lts_zs_downed then return false end

        return (ent:Health() > 0)
    end

    return false
end

local function CountAliveTeams(state)
    local aliveTeams = 0
    local aliveByTeam = {}

    for teamName, tdata in pairs(state.teams) do
        local alive = 0
        for _, ent in ipairs(tdata.members) do
            if IsAliveParticipant(ent, state) then alive = alive + 1 end
        end
        aliveByTeam[teamName] = alive
        if alive > 0 then aliveTeams = aliveTeams + 1 end
    end

    return aliveTeams, aliveByTeam
end

local function ClearSpawnedEnemies(state)
    for _, e in ipairs(state.spawnedEnemies) do
        if IsValid(e) then e:Remove() end
    end
    table.Empty(state.spawnedEnemies)
    state.enemiesRemaining = 0
    state.enemiesToSpawn = 0
    state.enemiesSpawnedTotal = 0
    SetGlobalInt("LTS_ZS_EnemiesRemaining", 0)
end

local function ZS_StopAllSounds()
    if not LambdaTeams or not LambdaTeams.StopConVarSound then return end
    LambdaTeams:StopConVarSound( CV_ZS_SND_MATCHSTART )
    LambdaTeams:StopConVarSound( CV_ZS_SND_MATCHEND )
    LambdaTeams:StopConVarSound( CV_ZS_SND_ROUNDSTART )
    LambdaTeams:StopConVarSound( CV_ZS_SND_ROUNDEND )
    LambdaTeams:StopConVarSound( CV_ZS_SND_SPECIALROUNDSTART )
end

local function ZS_PlaySound( sndCvar )
    if not LambdaTeams or not LambdaTeams.PlayConVarSound then return end
    -- I'M GONNA NUT I MEAN BLOW UP THE DEV CONSOLE
    if LambdaTeams.StopConVarSound then LambdaTeams:StopConVarSound( sndCvar ) end
    LambdaTeams:PlayConVarSound( sndCvar, "all" )
end

local function ResetKOTHPointsIfAny()
    for _, kp in ipairs(ents.FindByClass("lambda_koth_point")) do
        if not IsValid(kp) then continue end
        if kp.GetIsCaptured and kp:GetIsCaptured() and kp.BecomeNeutral then
            kp:BecomeNeutral()
        end
    end
end

local function ForceAllTeamsAllied(state, enable)
    if not enable then
        LambdaTeams.AlliedTeams = DeepCopyBoolTable2D(state.savedAlliances)
        return
    end

    LambdaTeams.AlliedTeams = DeepCopyBoolTable2D(state.savedAlliances)

    local names = {}
    for teamName, _ in pairs(state.teams) do
        names[#names + 1] = teamName
    end

    for _, a in ipairs(names) do
        LambdaTeams.AlliedTeams[a] = LambdaTeams.AlliedTeams[a] or {}
        for _, b in ipairs(names) do
            LambdaTeams.AlliedTeams[a][b] = true
        end
    end
end

local POWERUP_NUKE         = "nuke"
local POWERUP_DOUBLEPOINTS = "doublepoints"
local POWERUP_AMMO         = "ammo"

local POWERUP_MODELS = {
    [POWERUP_NUKE]         = "models/Items/combine_rifle_ammo01.mdl",
    [POWERUP_DOUBLEPOINTS] = "models/Items/battery.mdl",
    [POWERUP_AMMO]         = "models/Items/BoxMRounds.mdl"
}

local POWERUP_COLORS = {
    [POWERUP_NUKE]         = Color(255, 180, 80),
    [POWERUP_DOUBLEPOINTS] = Color(80, 170, 255),
    [POWERUP_AMMO]         = Color(120, 255, 120)
}

local IGNORE_LOADOUT_WEAPONS = {
    ["gmod_tool"] = true,
    ["gmod_camera"] = true,
    ["weapon_physgun"] = true,
    ["weapon_physcannon"] = true
}

local function ApplyWeaponRestrictionToPlayer(ply, wepClass)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if wepClass == "" then return end

    if not IsValid(ply:GetWeapon(wepClass)) then
        ply:Give(wepClass)
    end

    timer.Simple(0, function()
        if IsValid(ply) and ply:Alive() and IsValid(ply:GetWeapon(wepClass)) then
            ply:SelectWeapon(wepClass)
        end
    end)
end

local function ZS_SetLambdaSpawnWeapon(lb, wepClass, switchNow)
    if not IsValid(lb) or not lb.IsLambdaPlayer then return end

    wepClass = SafeWeaponClass(wepClass)
    if wepClass == "" then return end

    if lb.WeaponDataExists and not lb:WeaponDataExists(wepClass) then return end

    lb.l_SpawnWeapon = wepClass
    if lb.SetNW2String then
        lb:SetNW2String("lambda_spawnweapon", wepClass)
    end

    if switchNow and lb.SwitchWeapon then
        lb:SwitchWeapon(wepClass, true, true)
    end
end

local function ApplyWeaponRestrictionToLambda(lb, wepClass)
    ZS_SetLambdaSpawnWeapon(lb, wepClass, true)
end

local function ZS_GetParticipantTeam(state, ent)
    if not IsValid(ent) then return nil end

    local teamName = LambdaTeams:GetPlayerTeam(ent)
    if (not teamName or teamName == "") and state.cvIncludeNoTeams:GetBool() then
        teamName = "Neutral"
    end

    return teamName
end

local function ZS_InitTeamKillCounters(state)
    state.teamKillGlobals = {}
    LambdaTeams.TeamPoints = LambdaTeams.TeamPoints or {}

    for teamName, _ in pairs(state.teams) do
        local globalName = "LambdaTeamMatch_TeamPoints_" .. teamName
        state.teamKillGlobals[teamName] = globalName
        LambdaTeams.TeamPoints[teamName] = globalName
        SetGlobalInt(globalName, 0)
    end
end

local function ZS_ClearTeamKillCounters(state)
    if not state.teamKillGlobals then return end

    for teamName, globalName in pairs(state.teamKillGlobals) do
        SetGlobalInt(globalName, 0)
        if LambdaTeams.TeamPoints then
            LambdaTeams.TeamPoints[teamName] = nil
        end
    end

    state.teamKillGlobals = {}
end

local function ZS_AddTeamKill(state, ent, amount)
    if not IsValid(ent) then return end

    local teamName = ZS_GetParticipantTeam(state, ent)
    if not teamName then return end

    local globalName = state.teamKillGlobals and state.teamKillGlobals[teamName]
    if not globalName then return end

    SetGlobalInt(globalName, math.max(0, GetGlobalInt(globalName, 0) + math.max(0, amount or 0)))
end

local function ZS_SetPlayerPoints(state, ent, amount)
    if not IsValid(ent) then return end
    amount = math.max(0, math.floor(amount or 0))

    state.playerPoints[ent] = amount

    if ent:IsPlayer() then
        if ent.SetNW2Int then
            ent:SetNW2Int("LTS_ZS_Points", amount)
        else
            ent:SetNWInt("LTS_ZS_Points", amount)
        end

        if ent.SetFrags then
            ent:SetFrags(amount)
        end
    elseif ent.IsLambdaPlayer and ent.SetNW2Int then
        ent:SetNW2Int("LTS_ZS_Points", amount)
    end
end

local function ZS_AddPlayerPoints(state, ent, amount, ignoreMultiplier)
    if not IsValid(ent) then return 0 end

    local pts = math.max(0, math.floor(amount or 0))
    if pts <= 0 then return 0 end

    if not ignoreMultiplier and (state.doublePointsUntil or 0) > CurTime() then
        pts = pts * 2
    end

    ZS_SetPlayerPoints(state, ent, (state.playerPoints[ent] or 0) + pts)
    return pts
end

local function ZS_ResetAllPlayerPoints(state)
    local startPts = math.max(0, state.cvStartingPoints:GetInt())

    table.Empty(state.playerPoints)

    for _, tdata in pairs(state.teams) do
        for _, ent in ipairs(tdata.members) do
            if IsValid(ent) then
                ZS_SetPlayerPoints(state, ent, startPts)
            end
        end
    end
end

local function ZS_ShouldTrackWeapon(wep)
    if not IsValid(wep) then return false end
    local class = wep:GetClass()
    if not class or class == "" then return false end
    if IGNORE_LOADOUT_WEAPONS[class] then return false end
    return true
end

local function ZS_CountTrackedWeapons(ply)
    local count = 0
    for _, wep in ipairs(ply:GetWeapons()) do
        if ZS_ShouldTrackWeapon(wep) then
            count = count + 1
        end
    end
    return count
end

local function ZS_EnforceWeaponLimit(state, ply, preferredWep)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local limit = math.max(1, state.cvWeaponLimit:GetInt())
    local tracked = {}

    for _, wep in ipairs(ply:GetWeapons()) do
        if ZS_ShouldTrackWeapon(wep) then
            tracked[#tracked + 1] = wep
        end
    end

    if #tracked <= limit then return end

    local active = ply:GetActiveWeapon()

    table.sort(tracked, function(a, b)
        if a == preferredWep then return true end
        if b == preferredWep then return false end

        if a == active then return true end
        if b == active then return false end

        return a:EntIndex() > b:EntIndex()
    end)

    for i = limit + 1, #tracked do
        if IsValid(tracked[i]) then
            ply:StripWeapon(tracked[i]:GetClass())
        end
    end
end

local function ZS_GiveStarterWeapon(state, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local starter = SafeWeaponClass(state.cvStarterWeapon:GetString())
    if starter == "" then return end

    if not IsValid(ply:GetWeapon(starter)) then
        ply:Give(starter)
    end

    timer.Simple(0, function()
        if IsValid(ply) and ply:Alive() and IsValid(ply:GetWeapon(starter)) then
            ply:SelectWeapon(starter)
        end
    end)
end

local function ZS_GiveStarterWeaponToLambda(state, lb)
    if not IsValid(lb) or not lb.IsLambdaPlayer then return end

    local starter = SafeWeaponClass(state.cvStarterWeaponLambda:GetString())
    if starter == "" then return end

    ZS_SetLambdaSpawnWeapon(lb, starter, true)
end

local function ZS_SetParticipantState(ent, enabled)
    if not IsValid(ent) then return end

    if ent.SetNW2Bool then
        ent:SetNW2Bool("LTS_ZS_Participant", enabled and true or false)
    else
        ent:SetNWBool("LTS_ZS_Participant", enabled and true or false)
    end
end

local function ZS_CacheLambdaWeaponState(state, lb)
    if not IsValid(lb) or not lb.IsLambdaPlayer then return end

    local oldSpawn = SafeWeaponClass(lb.l_SpawnWeapon or (lb.GetNW2String and lb:GetNW2String("lambda_spawnweapon", "")) or "")

    state.cachedLambdaWeapons[lb] = {
        spawn = oldSpawn
    }

    if lb.SetExternalVar then
        lb:SetExternalVar("lts_zs_oldSpawnWeapon", oldSpawn)
    else
        lb.lts_zs_oldSpawnWeapon = oldSpawn
    end
end

local function ZS_RestoreLambdaWeaponState(state, lb)
    if not IsValid(lb) or not lb.IsLambdaPlayer then return end

    local cached = state.cachedLambdaWeapons[lb]
    local spawn = SafeWeaponClass(
        (cached and cached.spawn)
        or (lb.GetExternalVar and lb:GetExternalVar("lts_zs_oldSpawnWeapon"))
        or lb.lts_zs_oldSpawnWeapon
        or ""
    )

    if lb.SetExternalVar then
        lb:SetExternalVar("lts_zs_oldSpawnWeapon", nil)
    else
        lb.lts_zs_oldSpawnWeapon = nil
    end

    if spawn == "" then
        spawn = "physgun"
    end

    if lb.WeaponDataExists and not lb:WeaponDataExists(spawn) then
        spawn = "physgun"
    end

    lb.l_SpawnWeapon = spawn
    if lb.SetNW2String then
        lb:SetNW2String("lambda_spawnweapon", spawn)
    end

    if lb.SwitchWeapon then
        timer.Simple(0, function()
            if IsValid(lb) and lb.IsLambdaPlayer then
                lb:SwitchWeapon(spawn, true, true)
            end
        end)
    end
end

local function ZS_CachePlayerLoadout(state, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local data = {
        weapons = {},
        ammo = {},
        active = nil
    }

    local active = ply:GetActiveWeapon()

    for _, wep in ipairs(ply:GetWeapons()) do
        if not ZS_ShouldTrackWeapon(wep) then continue end

        local class = SafeWeaponClass(wep:GetClass())
        if class == "" then continue end

        data.weapons[#data.weapons + 1] = class
        if wep == active then
            data.active = class
        end

        local pType = wep:GetPrimaryAmmoType()
        if pType and pType >= 0 then
            data.ammo[pType] = ply:GetAmmoCount(pType)
        end

        local sType = wep:GetSecondaryAmmoType()
        if sType and sType >= 0 then
            data.ammo[sType] = ply:GetAmmoCount(sType)
        end
    end

    state.cachedLoadouts[ply] = data
end

local function ZS_RestorePlayerLoadout(state, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    if state.cvRestrictWeapons:GetBool() then
        local forced = SafeWeaponClass(state.cvWeaponClass:GetString())
        if forced ~= "" then
            ply:StripWeapons()
            ply:RemoveAllAmmo()
            ply:Give(forced)
            timer.Simple(0, function()
                if IsValid(ply) and ply:Alive() and IsValid(ply:GetWeapon(forced)) then
                    ply:SelectWeapon(forced)
                end
            end)
        end
        return
    end

    local limit = math.max(1, state.cvWeaponLimit:GetInt())
    local snapshot = state.cachedLoadouts[ply]

    if not snapshot or not snapshot.weapons or #snapshot.weapons == 0 then
        if state.round == 1 and state.cvResetOnRoundOne:GetBool() then
            ply:StripWeapons()
            ply:RemoveAllAmmo()
        end

        ZS_GiveStarterWeapon(state, ply)
        timer.Simple(0, function()
            if IsValid(ply) and ply:Alive() then
                ZS_EnforceWeaponLimit(state, ply)
                ZS_CachePlayerLoadout(state, ply)
            end
        end)
        return
    end

    ply:StripWeapons()

    for ammoType, _ in pairs(snapshot.ammo or {}) do
        local cur = ply:GetAmmoCount(ammoType)
        if cur > 0 then
            ply:RemoveAmmo(cur, ammoType)
        end
    end

    local seen = {}
    local given = 0

    for _, class in ipairs(snapshot.weapons) do
        class = SafeWeaponClass(class)
        if class == "" or seen[class] then continue end

        seen[class] = true
        given = given + 1
        if given > limit then break end

        ply:Give(class)
    end

    for ammoType, amount in pairs(snapshot.ammo or {}) do
        local cur = ply:GetAmmoCount(ammoType)
        if amount > cur then
            ply:GiveAmmo(amount - cur, ammoType, true)
        end
    end

    local active = SafeWeaponClass(snapshot.active or "")
    timer.Simple(0, function()
        if not IsValid(ply) or not ply:Alive() then return end

        if active ~= "" and IsValid(ply:GetWeapon(active)) then
            ply:SelectWeapon(active)
        end

        if ZS_CountTrackedWeapons(ply) <= 0 then
            ZS_GiveStarterWeapon(state, ply)
        end

        ZS_EnforceWeaponLimit(state, ply)
        ZS_CachePlayerLoadout(state, ply)
    end)
end

local function ZS_ClearPowerups(state)
    for ent, _ in pairs(state.powerups) do
        if IsValid(ent) then ent:Remove() end
    end

    table.Empty(state.powerups)
    state.doublePointsUntil = 0
    SetGlobalInt("LTS_ZS_DoublePointsRemaining", 0)
end

local function ZS_GetLivingParticipants(state)
    local out = {}

    for _, tdata in pairs(state.teams) do
        for _, ent in ipairs(tdata.members) do
            if IsAliveParticipant(ent, state) then
                out[#out + 1] = ent
            end
        end
    end

    return out
end

local function ZS_SpawnPowerup(state, pos, kind)
    if not SERVER then return end
    if not state.cvPowerups:GetBool() then return end
    if not pos then return end
    if kind == "" then return end

    local aliveCount = 0
    for ent, _ in pairs(state.powerups) do
        if IsValid(ent) then
            aliveCount = aliveCount + 1
        end
    end

    if aliveCount >= math.max(1, state.cvMaxWorldPowerups:GetInt()) then return end

    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return end

    ent:SetModel(POWERUP_MODELS[kind] or POWERUP_MODELS[POWERUP_DOUBLEPOINTS])
    ent:SetPos(pos + Vector(0, 0, 10))
    ent:Spawn()
    ent:Activate()
    ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
    ent:SetColor(POWERUP_COLORS[kind] or color_white)
    ent:SetMoveType(MOVETYPE_NONE)

    if kind == POWERUP_NUKE then
        ent:SetModelScale(1.35, 0)
    else
        ent:SetModelScale(1.0, 0)
    end

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end

    ent.lts_zs_powerup = kind
    ent.lts_zs_expire = CurTime() + math.max(5, state.cvPowerupLifetime:GetInt())

    state.powerups[ent] = true
end

local function ZS_PickPowerupType(state)
    local choices = {}

    if state.cvPowerupNuke:GetBool() then
        choices[#choices + 1] = POWERUP_NUKE
    end
    if state.cvPowerupDoublePoints:GetBool() then
        choices[#choices + 1] = POWERUP_DOUBLEPOINTS
    end
    if state.cvPowerupAmmo:GetBool() then
        choices[#choices + 1] = POWERUP_AMMO
    end

    if #choices == 0 then return nil end
    return choices[math.random(#choices)]
end

local function ZS_GiveAmmoClips(state, ply, clips)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if clips <= 0 then return end

    local ammoByType = {}

    for _, wep in ipairs(ply:GetWeapons()) do
        if not ZS_ShouldTrackWeapon(wep) then continue end

        local ammoType = wep:GetPrimaryAmmoType()
        if ammoType and ammoType >= 0 then
            local clipSize = wep:GetMaxClip1()
            if not clipSize or clipSize <= 0 then
                clipSize = wep:Clip1()
            end
            if not clipSize or clipSize <= 0 then
                clipSize = 30
            end

            ammoByType[ammoType] = math.max(ammoByType[ammoType] or 0, clipSize)
        end
    end

    for ammoType, clipSize in pairs(ammoByType) do
        ply:GiveAmmo(math.max(1, clipSize) * clips, ammoType, true)
    end

    ZS_CachePlayerLoadout(state, ply)
end

local function ZS_ActivatePowerup(state, ent, activator)
    if not IsValid(ent) then return end

    local kind = ent.lts_zs_powerup
    if not kind or kind == "" then return end

    if kind == POWERUP_NUKE then
        local killed = 0

        for _, npc in ipairs(state.spawnedEnemies) do
            if not IsValid(npc) then continue end
            if not npc.lts_zs_enemy then continue end
            if npc.lts_zs_round ~= state.round then continue end

            npc.lts_zs_ignorekillreward = true
            npc.lts_zs_nukeactivator = activator
            killed = killed + 1

            npc:TakeDamage(math.max(1000, npc:Health() + 100), IsValid(activator) and activator or game.GetWorld(), IsValid(activator) and activator or game.GetWorld())
            if IsValid(npc) then
                npc:Remove()
            end
        end

        if IsValid(activator) then
            local killPts = math.max(0, state.cvKillPoints:GetInt())
            if killPts > 0 and killed > 0 then
                ZS_AddPlayerPoints(state, activator, killPts * killed)
                ZS_AddTeamKill(state, activator, killed)
            end
        end

        ChatAll("Powerup grabbed: NUKE!")
    elseif kind == POWERUP_DOUBLEPOINTS then
        local dur = math.max(1, state.cvDoublePointsDuration:GetInt())
        state.doublePointsUntil = math.max(state.doublePointsUntil or 0, CurTime()) + dur
        ChatAll("Powerup grabbed: DOUBLE POINTS for ", tostring(dur), " seconds!")
    elseif kind == POWERUP_AMMO then
        local minClips = math.max(1, state.cvAmmoMinClips:GetInt())
        local maxClips = math.max(minClips, state.cvAmmoMaxClips:GetInt())
        local clips = math.random(minClips, maxClips)

        for _, target in ipairs(ZS_GetLivingParticipants(state)) do
            if IsValid(target) and target:IsPlayer() then
                ZS_GiveAmmoClips(state, target, clips)
            end
        end

        ChatAll("Powerup grabbed: AMMO! Granted ", tostring(clips), " clip(s).")
    end

    state.powerups[ent] = nil
    if IsValid(ent) then ent:Remove() end
end

local function ZS_ThinkPowerups(state)
    if not state.active or state.phase ~= "round" then return end

    local now = CurTime()
    local living = ZS_GetLivingParticipants(state)

    for ent, _ in pairs(state.powerups) do
        if not IsValid(ent) then
            state.powerups[ent] = nil
            continue
        end

        if now >= (ent.lts_zs_expire or 0) then
            state.powerups[ent] = nil
            ent:Remove()
            continue
        end

        local entPos = ent:GetPos()
        for _, collector in ipairs(living) do
            if not IsValid(collector) then continue end
            if entPos:DistToSqr(collector:GetPos()) > (90 * 90) then continue end

            ZS_ActivatePowerup(state, ent, collector)
            break
        end
    end
end

local function RespawnAll(state)
    for ply, _ in pairs(state.deadPlayers) do
        if IsValid(ply) then
            ply:UnSpectate()
            if not ply:Alive() then
                ply:Spawn()
            end
        end
    end
    table.Empty(state.deadPlayers)

    for _, lb in ipairs(GetLambdaPlayers()) do
        if not IsValid(lb) or not lb.IsLambdaPlayer then continue end

        if lb.lts_zs_downed then
            lb.lts_zs_downed = nil
            lb:SetNW2Bool("lts_zs_downed", false)
            lb:SetNoDraw(false)
            lb:SetNotSolid(false)
            lb:SetMoveType(MOVETYPE_WALK)
            lb:SetCollisionGroup(COLLISION_GROUP_NPC)
        end

        if lb.SetExternalVar then
            lb:SetExternalVar("l_LTS_ZS_Dead", false)
        end
    end
end

local function PickRoundType(state, roundNum)
    if state.cvEndlessRounds:GetBool() and state.cvEndlessSpecials:GetBool() then
        local endlessMin = math.max(1, state.cvEndlessSpecialMinRound:GetInt())
        local endlessChance = math.Clamp(state.cvEndlessSpecialChance:GetFloat(), 0, 1)

        if roundNum >= endlessMin and math.Rand(0, 1) <= endlessChance then
            return "antlions"
        end

        return "zombies"
    end

    if not state.cvSpecialRounds:GetBool() then
        return "zombies"
    end

    local minRound = state.cvSpecialMinRound:GetInt()
    if roundNum < minRound then
        return "zombies"
    end

    local chance = math.Clamp(state.cvSpecialChance:GetFloat(), 0, 1)
    if math.Rand(0, 1) <= chance then
        return "antlions"
    end

    return "zombies"
end

local function RoundEnemyClasses(state, roundType)
    if state and state.cvUseCustomNPCs and state.cvUseCustomNPCs:GetBool() then
        local str = (roundType == "antlions") and state.cvSpecialNPCList:GetString() or state.cvZombieNPCList:GetString()
        local list = ParseNPCList(str, 64)
        if #list > 0 then return list end
    end

    if roundType == "antlions" then
        return DEFAULT_SPECIAL
    end
    return DEFAULT_ZOMBIES
end

local function FindSpawnPosNearLiving(state)
    local alive = {}
    for _, tdata in pairs(state.teams) do
        for _, ent in ipairs(tdata.members) do
            if IsAliveParticipant(ent, state) then
                alive[#alive + 1] = ent
            end
        end
    end
    if #alive == 0 then return nil end

    local anchor = alive[math.random(#alive)]
    local basePos = anchor:GetPos()

    local minDist = state.cvSpawnMinDist:GetInt()
    local maxDist = state.cvSpawnMaxDist:GetInt()
    if maxDist < minDist + 64 then maxDist = minDist + 64 end

    if state.navAreas and #state.navAreas > 0 and navmesh.GetRandomPoint then
        for _ = 1, 12 do
            local area = state.navAreas[math.random(#state.navAreas)]
            if not IsValid(area) then continue end

            local p = area:GetRandomPoint()
            if p:DistToSqr(basePos) < (minDist * minDist) then continue end
            if p:DistToSqr(basePos) > (maxDist * maxDist) then continue end

            p.z = p.z + 8
            return p
        end
    end

    local dir = VectorRand()
    dir.z = 0
    dir:Normalize()

    local dist = math.random(minDist, maxDist)
    local p = basePos + dir * dist
    p.z = p.z + 8
    return p
end

local function SpawnEnemy(state, className)
    if not SERVER then return end

    local pos = FindSpawnPosNearLiving(state)
    if not pos then return end

    local npc = ents.Create(className)
    if not IsValid(npc) then return end

    npc:SetPos(pos)
    npc:Spawn()
    npc:Activate()

    npc.lts_zs_enemy = true
    npc.lts_zs_round = state.round
    npc.lts_zs_counted = false
    npc.lts_zs_ignorekillreward = false

    local hpMul = math.max(0.1, state.cvEnemyHealthMul:GetFloat())
    if hpMul ~= 1 then
        local mh = npc:GetMaxHealth()
        if mh and mh > 0 then
            npc:SetMaxHealth(math.floor(mh * hpMul))
            npc:SetHealth(math.floor(mh * hpMul))
        end
    end

    state.spawnedEnemies[#state.spawnedEnemies + 1] = npc
    state.enemiesRemaining = state.enemiesRemaining + 1
    state.enemiesSpawnedTotal = state.enemiesSpawnedTotal + 1

    SetGlobalInt("LTS_ZS_EnemiesRemaining", state.enemiesRemaining)
end

local function StartRound(state, roundNum, isRestart)
    state.phase = "round"
    state.round = roundNum
    state.roundType = PickRoundType(state, roundNum)

    SetGlobalInt("LTS_ZS_Round", state.round)
    SetGlobalString("LTS_ZS_RoundType", state.roundType)

    if roundNum == 1 and not isRestart and state.cvResetOnRoundOne:GetBool() then
        table.Empty(state.cachedLoadouts)
    end

    RespawnAll(state)
    ZS_ClearPowerups(state)

    table.Empty(state.pvpRoundPoints)
    for teamName, _ in pairs(state.teams) do
        state.pvpRoundPoints[teamName] = 0
    end

    if state.cvPvPEnable:GetBool() and state.cvPvPMode:GetInt() == 1 then
        ResetKOTHPointsIfAny()
    end

    for _, tdata in pairs(state.teams) do
        for _, ent in ipairs(tdata.members) do
            if not IsValid(ent) then continue end

            if ent:IsPlayer() then
                timer.Simple(0, function()
                    if IsValid(ent) and ent:Alive() then
                        ZS_RestorePlayerLoadout(state, ent)
                    end
                end)
			elseif ent.IsLambdaPlayer then
				timer.Simple(0, function()
					if not IsValid(ent) or not ent.IsLambdaPlayer then return end

					if state.cvRestrictWeapons:GetBool() then
						local forced = SafeWeaponClass( state.cvWeaponClassLambda:GetString() )
						if forced ~= "" then
							ApplyWeaponRestrictionToLambda( ent, forced )
						end
					elseif roundNum == 1 and not isRestart and state.cvResetOnRoundOne:GetBool() then
						ZS_GiveStarterWeaponToLambda( state, ent )
					end
				end)
			end
        end
    end

    ClearSpawnedEnemies(state)

    local totalParticipants = 0
    for _, tdata in pairs(state.teams) do
        totalParticipants = totalParticipants + #tdata.members
    end
    totalParticipants = math.max(1, totalParticipants)

    local base = state.cvBaseEnemiesPerPlayer:GetInt()
    local addPerRound = state.cvEnemiesAddPerRound:GetInt()
    local total = (base * totalParticipants) + (addPerRound * math.max(0, roundNum - 1))
    total = math.Clamp(total, 1, state.cvRoundEnemyCap:GetInt())

    state.enemiesToSpawn = total
    state.enemiesSpawnedTotal = 0
    state.enemiesRemaining = 0

    local maxAlive = state.cvMaxAliveEnemies:GetInt()
    if maxAlive > 0 then
        maxAlive = maxAlive + (math.max(0, roundNum - 1) * math.max(0, state.cvMaxAliveAddPerRound:GetInt()))
    end
    state.curMaxAliveEnemies = maxAlive

    local spawnInterval = state.cvSpawnInterval:GetFloat() - (math.max(0, roundNum - 1) * state.cvSpawnIntervalDecay:GetFloat())
    state.curSpawnInterval = math.max(0.05, spawnInterval)

    local useTimer = state.cvUseRoundTimer:GetBool()
    local timeSec = math.max(0, state.cvRoundTime:GetInt())
    if useTimer and timeSec > 0 then
        state.roundEndsAt = CurTime() + timeSec
        SetGlobalInt("LTS_ZS_TimeRemaining", timeSec)
    else
        state.roundEndsAt = nil
        SetGlobalInt("LTS_ZS_TimeRemaining", -1)
    end

    ChatAll(
        (isRestart and "Round restarted: " or "Round started: "),
        tostring(state.round),
        " (", state.roundType, ") - Enemies: ", tostring(total)
    )
    if state.roundType == "antlions" then
		ZS_PlaySound( CV_ZS_SND_SPECIALROUNDSTART )
	else
		ZS_PlaySound( CV_ZS_SND_ROUNDSTART )
	end

    timer.Remove("LTS_ZS_SpawnPump")
    timer.Create("LTS_ZS_SpawnPump", state.curSpawnInterval, 0, function()
        if not state.active or state.phase ~= "round" then
            timer.Remove("LTS_ZS_SpawnPump")
            return
        end

        if GetGlobalInt("LambdaTeamMatch_GameID", 0) ~= ZS_GAMEID then
            ChatAll("Another Team System match was started; ending Zombie Survival to avoid conflicts.")
            state:EndMatch(false, true)
            return
        end

        local curMaxAlive = state.curMaxAliveEnemies or state.cvMaxAliveEnemies:GetInt()
        if curMaxAlive > 0 and state.enemiesRemaining >= curMaxAlive then return end

        if state.enemiesSpawnedTotal >= state.enemiesToSpawn then
            if state.enemiesRemaining <= 0 then
                timer.Remove("LTS_ZS_SpawnPump")
            end
            return
        end

        local classes = RoundEnemyClasses(state, state.roundType)
        local className = classes[math.random(#classes)]
        SpawnEnemy(state, className)
    end)
end

local function EndRound(state, reason)
    state.phase = "intermission"
    timer.Remove("LTS_ZS_SpawnPump")
    ZS_ClearPowerups(state)

    if state.cvCleanupEnemiesBetweenRounds:GetBool() then
        ClearSpawnedEnemies(state)
    end

    local pvpEnabled = state.cvPvPEnable:GetBool()
    if pvpEnabled then
        local mode = state.cvPvPMode:GetInt()
        local aliveTeams, aliveByTeam = CountAliveTeams(state)

        local winner = nil
        if mode == 0 then
            if aliveTeams == 1 then
                for teamName, c in pairs(aliveByTeam) do
                    if c > 0 then
                        winner = teamName
                        break
                    end
                end
            end
        else
            local best = -1
            for teamName, pts in pairs(state.pvpRoundPoints) do
                if pts > best then
                    best = pts
                    winner = teamName
                end
            end
        end

        if winner then
            state.pvpMatchWins[winner] = (state.pvpMatchWins[winner] or 0) + 1
            ChatAll("PvP round winner: ", winner, " (match wins: ", tostring(state.pvpMatchWins[winner]), ")")
            ZS_PlaySound(CV_ZS_SND_ROUNDEND)
        else
            ChatAll("PvP round ended with no clear winner.")
            ZS_PlaySound(CV_ZS_SND_ROUNDEND)
        end
    end

    ChatAll("Round finished. ", (reason or ""))
    ZS_PlaySound(CV_ZS_SND_ROUNDEND)

    local delay = math.max(0, state.cvIntermissionTime:GetInt())
    timer.Simple(delay, function()
        if not state.active then return end

        if not state.cvEndlessRounds:GetBool() and state.round >= state.cvTotalRounds:GetInt() then
            state:EndMatch(true, false)
            return
        end

        StartRound(state, state.round + 1, false)
    end)
end

-- THIS IS WHERE THE MAGIC BEGINS TO HAPPEN
-- IF YOU EDIT ANYTHING, CLEAN IT UP
-- RESPECT MY LEGACY BY NOT SPAGHETTI CODING MY SHIT
local function BuildState()
    local state = {}
    state.active = false
    state.phase = "idle"
    state.round = 0
    state.roundType = "zombies"

    state.teams = {}
    state.deadPlayers = {}
    state.spawnedEnemies = {}
	
    state.enemiesToSpawn = 0
    state.enemiesSpawnedTotal = 0
    state.enemiesRemaining = 0

    state.savedAlliances = DeepCopyBoolTable2D(LambdaTeams.AlliedTeams or {})

    state.pvpRoundPoints = {}
    state.pvpMatchWins = {}

    state.playerPoints = {}
    state.cachedLoadouts = {}
	state.cachedLambdaWeapons = {}
    state.powerups = {}
    state.teamKillGlobals = {}
    state.doublePointsUntil = 0
    state.curMaxAliveEnemies = 0
    state.curSpawnInterval = 0.35
    state.nextLoadoutCacheT = 0

    state.navAreas = nil

-- I ACTUALLY TOOK THE TIME TO PUT THEM ALL ON SINGLE LINES
-- YOU GOTTA BUY ME A PEPSI FOR THAT 

-- THE MAIN SETTINGS
state.cvIncludeNoTeams = CreateLambdaConvar("lambdaplayers_teamsystem_zs_includenoteams", 0, true, false, false, "If enabled, players/lambdas with no assigned Lambda Team are included as 'Neutral'.", 0, 1, { name = "Place Neutrals On A Team", type = "Bool", category = "Team System - Zombie Survival" })
state.cvTotalRounds = CreateLambdaConvar("lambdaplayers_teamsystem_zs_totalrounds", 10, true, false, false, "How many rounds players must survive to finish the match.", 1, 255, { name = "Total Rounds", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvEndlessRounds = CreateLambdaConvar("lambdaplayers_teamsystem_zs_endless", 0, true, false, false, "If enabled, Zombie Survival never ends by round count.", 0, 1, { name = "Endless Rounds", type = "Bool", category = "Team System - Zombie Survival" })
state.cvIntermissionTime = CreateLambdaConvar("lambdaplayers_teamsystem_zs_intermission", 8, true, false, false, "Seconds between rounds.", 0, 60, { name = "Intermission Timer", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvBaseEnemiesPerPlayer = CreateLambdaConvar("lambdaplayers_teamsystem_zs_baseenemiesperplayer", 6, true, false, false, "Base enemies per participant per round.", 1, 50, { name = "Base Enemies Per Player", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvEnemiesAddPerRound = CreateLambdaConvar("lambdaplayers_teamsystem_zs_addenemiesperround", 2, true, false, false, "Additional enemies added each round.", 0, 100, { name = "Add Enemies Per Round", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvRoundEnemyCap = CreateLambdaConvar("lambdaplayers_teamsystem_zs_roundenemycap", 200, true, false, false, "The hard cap for how many enemies can spawn in a round.", 1, 5000, { name = "Enemy Maximum Per Round", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvMaxAliveEnemies = CreateLambdaConvar("lambdaplayers_teamsystem_zs_maxaliveenemies", 25, true, false, false, "Max alive enemies at once. Set 0 for unlimited.", 0, 300, { name = "Max Alive Enemies", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvMaxAliveAddPerRound = CreateLambdaConvar("lambdaplayers_teamsystem_zs_maxalive_addperround", 1, true, false, false, "Adds this many extra alive enemies each round to increase endless pressure.", 0, 50, { name = "Max Alive Added Per Round", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvSpawnInterval = CreateLambdaConvar("lambdaplayers_teamsystem_zs_spawninterval", 0.35, true, false, false, "Enemy spawn interval in seconds.", 0.05, 5.0, { name = "Spawn Interval", type = "Slider", decimals = 2, category = "Team System - Zombie Survival" })
state.cvSpawnIntervalDecay = CreateLambdaConvar("lambdaplayers_teamsystem_zs_spawninterval_decay", 0.005, true, false, false, "How much the spawn interval shrinks each round.", 0.0, 0.25, { name = "Spawn Interval Decay", type = "Slider", decimals = 3, category = "Team System - Zombie Survival" })
state.cvSpawnMinDist = CreateLambdaConvar("lambdaplayers_teamsystem_zs_spawnmindist", 900, true, false, false, "Minimum distance from a player to spawn an enemy.", 0, 6000, { name = "Spawn Min Distance", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvSpawnMaxDist = CreateLambdaConvar("lambdaplayers_teamsystem_zs_spawnmaxdist", 2600, true, false, false, "Maximum distance from a player to spawn an enemy.", 256, 12000, { name = "Spawn Max Distance", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvEnemyHealthMul = CreateLambdaConvar("lambdaplayers_teamsystem_zs_enemyhealthmul", 1.0, true, false, false, "Enemy HP multiplier.", 0.1, 10.0, { name = "Enemy HP Multiplier", type = "Slider", decimals = 1, category = "Team System - Zombie Survival" })
state.cvCleanupEnemiesBetweenRounds = CreateLambdaConvar("lambdaplayers_teamsystem_zs_cleanup_betweenrounds", 1, true, false, false, "If enabled, removes remaining enemies between rounds.", 0, 1, { name = "Cleanup Enemies Between Rounds", type = "Bool", category = "Team System - Zombie Survival" })
state.cvStartingPoints = CreateLambdaConvar("lambdaplayers_teamsystem_zs_startingpoints", 0, true, false, false, "Points each participant starts with.", 0, 10000, { name = "Starting Points", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvKillPoints = CreateLambdaConvar("lambdaplayers_teamsystem_zs_killpoints", 10, true, false, false, "Personal points awarded per zombie kill.", 0, 500, { name = "Kill Points", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })
state.cvUseRoundTimer = CreateLambdaConvar("lambdaplayers_teamsystem_zs_use_roundtimer", 0, true, false, false, "If enabled, the round has a timer.", 0, 1, { name = "Use Round Timer", type = "Bool", category = "Team System - Zombie Survival" })
state.cvRoundTime = CreateLambdaConvar("lambdaplayers_teamsystem_zs_roundtime", 180, true, false, false, "Total time in seconds for each round.", 10, 3600, { name = "Round Time", type = "Slider", decimals = 0, category = "Team System - Zombie Survival" })

-- THE WEAPON SETTINGS
state.cvRestrictWeapons = CreateLambdaConvar("lambdaplayers_teamsystem_zs_restrictweapons", 0, true, false, false, "If enabled, all players are forced to one weapon. This will prevent players from using any other weapon (NOT EVERY WEAPON IS LAMBDA PLAYER FRIENDLY, USE WEAPONS LAMBDA PLAYERS CAN EQUIP OR USE DEFAULT WEAPONS).", 0, 1, { name = "Restrict Weapon Giving & Pick-ups", type = "Bool", category = "Team System - Zombie Survival - Weapons" })
state.cvWeaponClass = CreateLambdaConvar("lambdaplayers_teamsystem_zs_weaponclass", "weapon_smg1", true, false, false, "Restricted human weapon class.", 0, 1)
state.cvWeaponClassLambda = CreateLambdaConvar("lambdaplayers_teamsystem_zs_weaponclass_lambda", "weapon_smg1", true, false, false, "Restricted lambda weapon class.", 0, 1)
state.cvStarterWeapon = CreateLambdaConvar("lambdaplayers_teamsystem_zs_starterweapon", "m9k_colt1911", true, false, false, "Starter human weapon class.", 0, 1)
state.cvStarterWeaponLambda = CreateLambdaConvar("lambdaplayers_teamsystem_zs_starterweapon_lambda", "m9k_pistol_colt1911", true, false, false, "Starter lambda weapon class.", 0, 1)
state.cvWeaponLimit = CreateLambdaConvar("lambdaplayers_teamsystem_zs_weaponlimit", 4, true, false, false, "Maximum amount of weapons a player may carry.", 1, 12, { name = "Weapon Limit", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Weapons" })
state.cvResetOnRoundOne = CreateLambdaConvar("lambdaplayers_teamsystem_zs_resetloadout_round1", 1, true, false, false, "If enabled, round 1 wipes all players loadouts and gives everyone the selected starter weapon (NOT EVERY WEAPON IS LAMBDA PLAYER FRIENDLY, USE WEAPONS LAMBDA PLAYERS CAN EQUIP OR USE DEFAULT WEAPONS).", 0, 1, { name = "Reset Loadout On Round 1", type = "Bool", category = "Team System - Zombie Survival - Weapons" })

-- THE ADDITIONAL SETTINGS 
state.cvSpecialRounds = CreateLambdaConvar("lambdaplayers_teamsystem_zs_specialrounds", 0, true, false, false, "If enabled, some rounds spawn antlions instead of zombies.", 0, 1, { name = "Enable Special Rounds", type = "Bool", category = "Team System - Zombie Survival - Additional" })
state.cvSpecialChance = CreateLambdaConvar("lambdaplayers_teamsystem_zs_specialchance", 0.20, true, false, false, "Chance each round becomes a special antlion round.", 0.0, 1.0, { name = "Special Round Chance", type = "Slider", decimals = 2, category = "Team System - Zombie Survival - Additional" })
state.cvSpecialMinRound = CreateLambdaConvar("lambdaplayers_teamsystem_zs_specialminround", 4, true, false, false, "Special rounds won't appear before this round.", 1, 100, { name = "Special Round Min Round", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Additional" })
state.cvEndlessSpecials = CreateLambdaConvar("lambdaplayers_teamsystem_zs_endless_specials", 1, true, false, false, "If the endless round is enabled, allow special zombies in endless mode (this is similar to COD 2023 & BOCW zombies).", 0, 1, { name = "Endless Specials", type = "Bool", category = "Team System - Zombie Survival - Additional" })
state.cvEndlessSpecialChance = CreateLambdaConvar("lambdaplayers_teamsystem_zs_endless_specialchance", 0.25, true, false, false, "Chance for specials to appear during endless rounds.", 0.0, 1.0, { name = "Endless Special Chance", type = "Slider", decimals = 2, category = "Team System - Zombie Survival - Additional" })
state.cvEndlessSpecialMinRound = CreateLambdaConvar("lambdaplayers_teamsystem_zs_endless_specialminround", 6, true, false, false, "Minimum round before endless mode can start throwing specials in.", 1, 255, { name = "Endless Special Min Round", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Additional" })
state.cvUseCustomNPCs = CreateLambdaConvar("lambdaplayers_teamsystem_zs_usecustomnpcs", 0, true, false, false, "If enabled, the Zombie Survival gamemode will instead use NPCs that you want to use (USE ONLY 1 METHOD TO CHANGE THE ZOMBIES, EITHER THE PANEL IN PANELS OR TEXT BELOW) (DO NOT USE LAMBDA PLAYERS AS ZOMBIES, IT CAN POTENTIALLY BREAK THE ADDON) (CHANGING BOTH WILL CAUSE GAMEMODE ISSUES).", 0, 1, { name = "Use Custom NPCs For Zombie Survival", type = "Bool", category = "Team System - Zombie Survival - Additional" })
state.cvZombieNPCList = CreateLambdaConvar("lambdaplayers_teamsystem_zs_zombie_npclist", "npc_zombie,npc_fastzombie,npc_zombine,npc_poisonzombie", true, false, false, "NPC classes used for regular rounds.", 0, 1, { name = "Zombie NPCs", type = "Text", category = "Team System - Zombie Survival - Additional" })
state.cvSpecialNPCList = CreateLambdaConvar("lambdaplayers_teamsystem_zs_special_npclist", "npc_antlion,npc_antlionguard", true, false, false, "NPC classes used for special rounds.", 0, 1, { name = "Special Round NPCs", type = "Text", category = "Team System - Zombie Survival - Additional" })

-- THE MYSTERY BOX SETINGS
CreateLambdaConvar( "lambdaplayers_mysterybox_enabled", 1, true, false, false, "If enabled, Lambda Players will be allowed to use the Mystery Box Entity (Sandbox/TTT) (2023 Update).", 0, 1, { name = "Enable Mystery Box Compat", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_box_radius", 90, true, false, false, "Distance for Lambdas to use nearby mystery boxes (putting it higher than 100 will make it look freaky).", 1, 500, { name = "Box Use Radius", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_reward_radius", 100, true, false, false, "Distance for Lambdas to claim nearby mystery box rewards.", 1, 500, { name = "Reward Pickup Radius", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_scan_interval", 0.33, true, false, false, "How often Lambda Players search for boxes and rewards (Lower values will cause slight performance decreases).", 0.05, 2.0, { name = "Search Interval", type = "Slider", decimals = 2, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_require_outofcombat", 1, true, false, false, "If enabled, Lambda Players will only use mystery boxes while out of combat.", 0, 1, { name = "Use Mystery Box Out Of Combat", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_skip_owned", 1, true, false, false, "If enabled, Lambda Players will not collect weapons from the Mystery Box that they already have.", 0, 1, { name = "Skip Current Weapon", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_guard_enabled", 0, true, false, false, "If enabled, some Lambda Players near mystery boxes may stay and guard the area around it.", 0, 1, { name = "Guard Nearby Boxes", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_guard_chance", 30, true, false, false, "Chance that a Lambda Player will guard a mystery box.", 0, 100, { name = "Guard Chance", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_guard_radius", 250, true, false, false, "How close a guarding Lambda should remain to the box.", 64, 1000, { name = "Guard Radius", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_guard_time_min", 8, true, false, false, "Minimum time a Lambda Player will guard a mystery box.", 1, 120, { name = "Guard Time Min", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_guard_time_max", 18, true, false, false, "Maximum time a Lambda Player will guard near mystery box.", 1, 120, { name = "Guard Time Max", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_uses_min", 1, true, false, false, "Minimum times Lambda Players can use mystery boxes.", 0, 20, { name = "Min Box Uses", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_uses_max", 3, true, false, false, "Maximum times Lambda Players can use mystery boxes.", 0, 20, { name = "Max Box Uses", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
CreateLambdaConvar( "lambdaplayers_mysterybox_debug", 0, true, false, false, "Print debugging information for the compatibility patches between Lambda Players & the Mystery Box Entity.", 0, 1, { name = "Debug Logging", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )

LambdaTeams.LTS_ZS_HumanToLambdaWeapon = LambdaTeams.LTS_ZS_HumanToLambdaWeapon or {
    m9k_acr = "m9k_ar_acr",
    m9k_ak47 = "m9k_ar_ak47",
    m9k_ak74 = "m9k_ar_ak74",
    m9k_an94 = "m9k_ar_an94",
    m9k_amd65 = "m9k_ar_amd65",
    m9k_asval = "m9k_ar_asval",
    m9k_f2000 = "m9k_ar_f2000",
    m9k_fal = "m9k_ar_fal",
    m9k_famas = "m9k_ar_famas",
    m9k_g36 = "m9k_ar_g36c",
    m9k_hk416 = "m9k_ar_hk416",
    m9k_m4a1 = "m9k_ar_m4a1",
    m9k_m14sp = "m9k_ar_m14",
    m9k_m16a4_acog = "m9k_ar_m16a1",
    m9k_scar = "m9k_ar_scar",
    m9k_tar21 = "m9k_ar_tar21",
    m9k_vikhr = "m9k_ar_vikhr",
    m9k_winchester73 = "m9k_ar_winchester_rifle",

    m9k_colt1911 = "m9k_pistol_colt1911",
    m9k_deagle = "m9k_pistol_deagle",
    m9k_hk45 = "m9k_pistol_hk45",
    m9k_luger = "m9k_pistol_luger",
    m9k_m29satan = "m9k_pistol_satan",
    m9k_m92beretta = "m9k_pistol_m92beretta",
    m9k_model3russian = "m9k_pistol_model3russian",
    m9k_mp412rex = "m9k_pistol_mp412rex",
    m9k_python = "m9k_pistol_python",
    m9k_remington1858 = "m9k_pistol_remington1858",
    m9k_ragingbull = "m9k_pistol_ragingb",
    m9k_sig_p229r = "m9k_pistol_sigp229",
    m9k_model500 = "m9k_pistol_sw500",
    m9k_model627 = "m9k_pistol_sw627",
    m9k_usp = "m9k_pistol_usp",

    m9k_bizonp19 = "m9k_smg_bizon",
    m9k_honeybadger = "m9k_smg_honeybadger",
    m9k_kac_pdw = "m9k_smg_pdw",
    m9k_magpulpdr = "m9k_smg_pdr",
    m9k_mp5 = "m9k_smg_mp5",
    m9k_mp5sd = "m9k_smg_mp5sd",
    m9k_mp7 = "m9k_smg_mp7",
    m9k_mp9 = "m9k_smg_mp9",
    m9k_p90 = "m9k_smg_p90",
    m9k_sten = "m9k_smg_sten",
    m9k_tec9 = "m9k_smg_tec9",
    m9k_thompson = "m9k_smg_tommygun",
    m9k_uzi = "m9k_smg_uzi",
    m9k_ump45 = "m9k_smg_ump45",
    m9k_vector = "m9k_smg_vector",
    m9k_usc = "m9k_smg_usc",

    m9k_1887winchester = "m9k_hvy_1887winchester",
    m9k_barret_m82 = "m9k_hvy_barret_m82",
    m9k_browningauto5 = "m9k_hvy_browningauto5",
    m9k_m24 = "m9k_hvy_m24",
    m9k_m249lmg = "m9k_hvy_m249",
    m9k_m3 = "m9k_hvy_benellim3",
    m9k_m60 = "m9k_hvy_m60",
    m9k_mossberg590 = "m9k_hvy_mossberg590",
    m9k_pkm = "m9k_hvy_pkm",
    m9k_psg1 = "m9k_hvy_psg1",
    m9k_remington870 = "m9k_hvy_remington870",
    m9k_spas12 = "m9k_hvy_spas12",
    m9k_svu = "m9k_hvy_dragunovsvu",
    m9k_svt40 = "m9k_hvy_svt40",
    m9k_usas = "m9k_hvy_usas",
}

-- THE POWERUP SETTINGS
state.cvPowerups = CreateLambdaConvar("lambdaplayers_teamsystem_zs_powerups", 1, true, false, false, "Enable powerups in Zombie Survival.", 0, 1, { name = "Enable Powerups", type = "Bool", category = "Team System - Zombie Survival - Powerup Settings" })
state.cvPowerupChance = CreateLambdaConvar("lambdaplayers_teamsystem_zs_powerupchance", 0.08, true, false, false, "Chance an enemy drops a powerup.", 0.0, 1.0, { name = "Powerup Drop Chance", type = "Slider", decimals = 2, category = "Team System - Zombie Survival - Powerup Settings" })
state.cvPowerupLifetime = CreateLambdaConvar("lambdaplayers_teamsystem_zs_poweruplifetime", 20, true, false, false, "Seconds before a powerup disappears.", 5, 120, { name = "Powerup Lifetime", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Powerup Settings" })
state.cvMaxWorldPowerups = CreateLambdaConvar("lambdaplayers_teamsystem_zs_powerupmaxworld", 2, true, false, false, "Maximum amount of powerups that can exist in the world at once.", 1, 10, { name = "Max World Powerups", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Powerup Settings" })
state.cvPowerupNuke = CreateLambdaConvar("lambdaplayers_teamsystem_zs_powerup_nuke", 1, true, false, false, "Enable the Nuke powerup.", 0, 1, { name = "Enable Nuke Powerup", type = "Bool", category = "Team System - Zombie Survival - Powerup Settings" })
state.cvPowerupDoublePoints = CreateLambdaConvar("lambdaplayers_teamsystem_zs_powerup_doublepoints", 1, true, false, false, "Enable the Double Points powerup.", 0, 1, { name = "Enable Double Points", type = "Bool", category = "Team System - Zombie Survival - Powerup Settings" })
state.cvPowerupAmmo = CreateLambdaConvar("lambdaplayers_teamsystem_zs_powerup_ammo", 1, true, false, false, "Enable the Ammo powerup.", 0, 1, { name = "Enable Ammo Powerup", type = "Bool", category = "Team System - Zombie Survival - Powerup Settings" })
state.cvDoublePointsDuration = CreateLambdaConvar("lambdaplayers_teamsystem_zs_doublepoints_duration", 25, true, false, false, "How long Double Points lasts.", 1, 120, { name = "Double Points Duration", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Powerup Settings" })
state.cvAmmoMinClips = CreateLambdaConvar("lambdaplayers_teamsystem_zs_ammo_minclips", 5, true, false, false, "Minimum amount of clips the Ammo powerup gives.", 1, 50, { name = "Ammo Powerup Min Clips", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Powerup Settings" })
state.cvAmmoMaxClips = CreateLambdaConvar("lambdaplayers_teamsystem_zs_ammo_maxclips", 10, true, false, false, "Maximum amount of clips the Ammo powerup gives.", 1, 50, { name = "Ammo Powerup Max Clips", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Powerup Settings" })

-- THE PVP SETTINGS
state.cvPvPEnable = CreateLambdaConvar("lambdaplayers_teamsystem_zs_pvp_enable", 0, true, false, false, "If enabled, lambda teams compete against each other to win the match.", 0, 1, { name = "Enable PvP", type = "Bool", category = "Team System - Zombie Survival - PVP Settings" })
state.cvPvPMode = CreateLambdaConvar("lambdaplayers_teamsystem_zs_pvp_mode", 0, true, false, false, "0 = Last Team Standing, 1 = Domination", 0, 1, { name = "Versus Gamemode", type = "Combo", options = { [0] = "Last Team Standing", [1] = "KOTH Points" }, category = "Team System - Zombie Survival - PVP Settings" })
state.cvPvPRespawns = CreateLambdaConvar("lambdaplayers_teamsystem_zs_pvp_allowrespawn", 0, true, false, false, "If enabled, participants may respawn during the round.", 0, 1, { name = "Allow Respawns", type = "Bool", category = "Team System - Zombie Survival - PVP Settings" })
state.cvPvPRespawnCount = CreateLambdaConvar("lambdaplayers_teamsystem_zs_pvp_respawns", 2, true, false, false, "How many respawns are allowed per participant.", 0, 20, { name = "Respawn Count", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - PVP Settings" })
state.cvPvPRespawnDelay = CreateLambdaConvar("lambdaplayers_teamsystem_zs_pvp_respawndelay", 4, true, false, false, "Delay before respawning a participant.", 0, 30, { name = "Respawn Delay", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - PVP Settings" })
state.cvPvPTimerRestart = CreateLambdaConvar("lambdaplayers_teamsystem_zs_pvp_timerrestart", 1, true, false, false, "If the timer hits 0 and more than one team is alive, restart the round.", 0, 1, { name = "Restart On Timeout", type = "Bool", category = "Team System - Zombie Survival - PVP Settings" })

    function state:EndMatch(won, endedPrematurely)
        if not self.active then return end

        self.active = false
        self.phase = "finished"

        ZS_StopAllSounds()
        ZS_PlaySound(CV_ZS_SND_MATCHEND)

        timer.Remove("LTS_ZS_SpawnPump")
        timer.Remove("LTS_ZS_MainThink")
        timer.Remove("LTS_ZS_KOTHScore")

        ClearSpawnedEnemies(self)
        ZS_ClearPowerups(self)

        ForceAllTeamsAllied(self, false)

        SetGlobalBool("LTS_ZS_Active", false)
        SetGlobalInt("LTS_ZS_Round", 0)
        SetGlobalInt("LTS_ZS_EnemiesRemaining", 0)
        SetGlobalInt("LTS_ZS_TimeRemaining", 0)
        SetGlobalInt("LTS_ZS_DoublePointsRemaining", 0)
        SetGlobalString("LTS_ZS_RoundType", "")

        if GetGlobalInt("LambdaTeamMatch_GameID", 0) == ZS_GAMEID then
            SetGlobalInt("LambdaTeamMatch_GameID", 0)
        end

		for _, tdata in pairs(self.teams) do
			for _, ent in ipairs(tdata.members) do
				if IsValid(ent) then
					ZS_SetParticipantState(ent, false)

					if ent.IsLambdaPlayer then
						ZS_RestoreLambdaWeaponState(self, ent)
					end
				end
			end
		end

		RespawnAll(self)

		for _, tdata in pairs(self.teams) do
			for _, ent in ipairs(tdata.members) do
				if IsValid(ent) then
					ZS_SetPlayerPoints(self, ent, 0)
				end
			end
		end

		table.Empty(self.cachedLambdaWeapons)
		ZS_ClearTeamKillCounters(self)

        if endedPrematurely then
            ChatAll("Zombie Survival ended prematurely.")
            return
        end

        if won then
            if self.cvEndlessRounds:GetBool() then
                ChatAll("Endless Zombie Survival ended after reaching round ", tostring(self.round), ".")
            elseif self.cvPvPEnable:GetBool() then
                local bestTeam, best = nil, -1
                for teamName, wins in pairs(self.pvpMatchWins) do
                    if wins > best then
                        best = wins
                        bestTeam = teamName
                    end
                end

                if bestTeam then
                    ChatAll("Zombie Survival finished! PvP winner: ", bestTeam, " with ", tostring(best), " round win(s).")
                else
                    ChatAll("Zombie Survival finished! (PvP enabled) No winner recorded.")
                end
            else
                ChatAll("Zombie Survival finished! Players survived all rounds.")
            end
        else
            ChatAll("Zombie Survival failed at round ", tostring(self.round), ".")
        end
    end

    return state
end

LambdaTeams.LTS_ZS_State = LambdaTeams.LTS_ZS_State or BuildState()
local STATE = LambdaTeams.LTS_ZS_State

local function StartMatch(ply)
    if SERVER then
        if IsValid(ply) and ply:IsPlayer() and not ply:IsSuperAdmin() then
            if LambdaPlayers_Notify then
                LambdaPlayers_Notify(ply, "You must be a Super Admin to start Zombie Survival!", 1, 6)
            end
            return
        end

        if not IsTeamSystemEnabled() then
            ChatAll("Team System is disabled, you cannot start Zombie Survival.")
            return
        end

        if STATE.active then
            ChatAll("Zombie Survival is already active.")
            return
        end

        local curID = GetGlobalInt("LambdaTeamMatch_GameID", 0)
        if curID ~= 0 then
            ChatAll("You need to stop your current gamemode before starting Zombie Survival!")
            return
        end

        local teams, count = GetAllParticipants(STATE.cvIncludeNoTeams:GetBool())
        if count <= 0 then
            ChatAll("All players must be on a team in order to start!")
            return
        end

		STATE.teams = teams
		table.Empty(STATE.deadPlayers)
		table.Empty(STATE.spawnedEnemies)
		table.Empty(STATE.pvpMatchWins)
		table.Empty(STATE.playerPoints)
		table.Empty(STATE.cachedLoadouts)
		table.Empty(STATE.cachedLambdaWeapons)
		table.Empty(STATE.powerups)
		STATE.pvpRoundPoints = {}
		STATE.doublePointsUntil = 0
		STATE.nextLoadoutCacheT = 0

		for _, tdata in pairs(STATE.teams) do
			for _, ent in ipairs(tdata.members) do
				if IsValid(ent) then
					ZS_SetParticipantState(ent, true)

					if ent.IsLambdaPlayer then
						ZS_CacheLambdaWeaponState(STATE, ent)
					end
				end
			end
		end

        STATE.savedAlliances = DeepCopyBoolTable2D(LambdaTeams.AlliedTeams or {})

        if navmesh and navmesh.GetAllNavAreas then
            local areas = navmesh.GetAllNavAreas()
            if areas and #areas > 0 then
                STATE.navAreas = areas
            else
                STATE.navAreas = nil
            end
        end

        local pvp = STATE.cvPvPEnable:GetBool()
        ForceAllTeamsAllied(STATE, not pvp)

        STATE.active = true
        STATE.phase = "intermission"
        STATE.round = 0

        SetGlobalBool("LTS_ZS_Active", true)
        SetGlobalInt("LTS_ZS_Round", 0)
        SetGlobalInt("LTS_ZS_EnemiesRemaining", 0)
        SetGlobalInt("LTS_ZS_TimeRemaining", -1)
        SetGlobalInt("LTS_ZS_DoublePointsRemaining", 0)
        SetGlobalString("LTS_ZS_RoundType", "")
        SetGlobalInt("LambdaTeamMatch_GameID", ZS_GAMEID)

        ZS_InitTeamKillCounters(STATE)
        ZS_ResetAllPlayerPoints(STATE)

        ChatAll(
            "Zombie Survival started. ",
            (STATE.cvEndlessRounds:GetBool() and "Rounds: ENDLESS" or ("Rounds: " .. tostring(STATE.cvTotalRounds:GetInt()))),
            (pvp and " | PvP: ON" or " | PvP: OFF")
        )
        ZS_PlaySound(CV_ZS_SND_MATCHSTART)

        timer.Remove("LTS_ZS_MainThink")
        timer.Create("LTS_ZS_MainThink", 0.25, 0, function()
            if not STATE.active then
                timer.Remove("LTS_ZS_MainThink")
                return
            end

            if GetGlobalInt("LambdaTeamMatch_GameID", 0) ~= ZS_GAMEID then
                ChatAll("Detected a different Team System match; ending Zombie Survival.")
                STATE:EndMatch(false, true)
                return
            end

            local dpRem = math.max(0, math.ceil((STATE.doublePointsUntil or 0) - CurTime()))
            SetGlobalInt("LTS_ZS_DoublePointsRemaining", dpRem)

            if STATE.phase ~= "round" then return end

            if CurTime() >= (STATE.nextLoadoutCacheT or 0) then
                for _, tdata in pairs(STATE.teams) do
                    for _, ent in ipairs(tdata.members) do
                        if IsValid(ent) and ent:IsPlayer() and ent:Alive() and not STATE.deadPlayers[ent] then
                            ZS_CachePlayerLoadout(STATE, ent)
                        end
                    end
                end
                STATE.nextLoadoutCacheT = CurTime() + 1.0
            end

            ZS_ThinkPowerups(STATE)

            if STATE.roundEndsAt then
                local rem = math.floor(STATE.roundEndsAt - CurTime())
                if rem < 0 then rem = 0 end
                SetGlobalInt("LTS_ZS_TimeRemaining", rem)

                if rem <= 0 and STATE.enemiesRemaining > 0 then
                    if STATE.cvPvPEnable:GetBool() and STATE.cvPvPTimerRestart:GetBool() then
                        local aliveTeams = CountAliveTeams(STATE)
                        if aliveTeams > 1 then
                            ChatAll("Timer expired with multiple teams alive! Restarting the round.")
                            StartRound(STATE, STATE.round, true)
                            return
                        end
                    end

                    ChatAll("Timer expired while enemies remained. The match has ended.")
                    STATE:EndMatch(false, false)
                    return
                end
            end

            local aliveTeams = CountAliveTeams(STATE)
            if aliveTeams <= 0 then
                STATE:EndMatch(false, false)
                return
            end

            if STATE.enemiesSpawnedTotal >= STATE.enemiesToSpawn and STATE.enemiesRemaining <= 0 then
                EndRound(STATE, "All enemies defeated.")
                return
            end
        end)

        timer.Remove("LTS_ZS_KOTHScore")
        timer.Create("LTS_ZS_KOTHScore", 1.0, 0, function()
            if not STATE.active or STATE.phase ~= "round" then return end
            if not STATE.cvPvPEnable:GetBool() then return end
            if STATE.cvPvPMode:GetInt() ~= 1 then return end

            for _, kp in ipairs(ents.FindByClass("lambda_koth_point")) do
                if not IsValid(kp) then continue end

                local capturer = ""
                if kp.GetCapturerName then
                    capturer = kp:GetCapturerName()
                end

                if not isstring(capturer) or capturer == "" or capturer == "Neutral" then continue end

                if STATE.pvpRoundPoints[capturer] ~= nil then
                    STATE.pvpRoundPoints[capturer] = STATE.pvpRoundPoints[capturer] + 1
                end
            end
        end)

        timer.Simple(math.max(0, STATE.cvIntermissionTime:GetInt()), function()
            if not STATE.active then return end
            StartRound(STATE, 1, false)
        end)
    end
end

local function StopMatch(ply)
    if SERVER then
        if IsValid(ply) and ply:IsPlayer() and not ply:IsSuperAdmin() then
            if LambdaPlayers_Notify then
                LambdaPlayers_Notify(ply, "You must be a Super Admin to stop Zombie Survival!", 1, 6)
            end
            return
        end

        if not STATE.active then
            ChatAll("Zombie Survival is not active.")
            return
        end

        STATE:EndMatch(STATE.cvEndlessRounds:GetBool(), true)
    end
end

CreateLambdaConsoleCommand("lambdaplayers_teamsystem_zs_startmatch", function(ply) StartMatch(ply) end, false,
    "Start a match of Zombie Survival.", { name = "Start Zombie Survival", category = "Team System - Gamemodes" })

CreateLambdaConsoleCommand("lambdaplayers_teamsystem_zs_stopmatch", function(ply) StopMatch(ply) end, false,
    "Stop an ongoing match of Zombie Survival.", { name = "Stop Zombie Survival", category = "Team System - Gamemodes" })

local function ZS_ResolvePointOwner(attacker, inflictor)
    if IsValid(attacker) and (attacker:IsPlayer() or attacker.IsLambdaPlayer) then
        return attacker
    end

    if IsValid(attacker) and attacker:IsWeapon() and IsValid(attacker:GetOwner()) then
        local owner = attacker:GetOwner()
        if owner:IsPlayer() or owner.IsLambdaPlayer then
            return owner
        end
    end

    if IsValid(inflictor) and inflictor.GetOwner and IsValid(inflictor:GetOwner()) then
        local owner = inflictor:GetOwner()
        if owner:IsPlayer() or owner.IsLambdaPlayer then
            return owner
        end
    end
end

hook.Add("OnNPCKilled", "LTS_ZS_OnNPCKilled", function(npc, attacker, inflictor)
    if not STATE.active or STATE.phase ~= "round" then return end
    if not IsValid(npc) or not npc.lts_zs_enemy then return end
    if npc.lts_zs_round ~= STATE.round then return end
    if npc.lts_zs_counted then return end

    npc.lts_zs_counted = true

    STATE.enemiesRemaining = math.max(0, STATE.enemiesRemaining - 1)
    SetGlobalInt("LTS_ZS_EnemiesRemaining", STATE.enemiesRemaining)

    if npc.lts_zs_ignorekillreward then return end

    local owner = ZS_ResolvePointOwner(attacker, inflictor)
    if IsValid(owner) then
        local killPts = math.max(0, STATE.cvKillPoints:GetInt())
        if killPts > 0 then
            ZS_AddPlayerPoints(STATE, owner, killPts)
        end

        ZS_AddTeamKill(STATE, owner, 1)
    end

    if STATE.cvPowerups:GetBool() and math.Rand(0, 1) <= math.Clamp(STATE.cvPowerupChance:GetFloat(), 0, 1) then
        local kind = ZS_PickPowerupType(STATE)
        if kind then
            ZS_SpawnPowerup(STATE, npc:GetPos(), kind)
        end
    end
end)

hook.Add("EntityRemoved", "LTS_ZS_EnemyRemoved", function(ent)
    if not STATE.active or STATE.phase ~= "round" then return end
    if not IsValid(ent) then return end
    if not ent.lts_zs_enemy then return end
    if ent.lts_zs_round ~= STATE.round then return end
    if ent.lts_zs_counted then return end

    ent.lts_zs_counted = true
    STATE.enemiesRemaining = math.max(0, STATE.enemiesRemaining - 1)
    SetGlobalInt("LTS_ZS_EnemiesRemaining", STATE.enemiesRemaining)
end)

hook.Add("PlayerDeath", "LTS_ZS_PlayerDeath", function(ply)
    if not STATE.active or STATE.phase ~= "round" then return end
    if not IsValid(ply) then return end

    ZS_CachePlayerLoadout(STATE, ply)

    local isPvP = STATE.cvPvPEnable:GetBool()
    local allowRespawn = isPvP and STATE.cvPvPRespawns:GetBool()

    if allowRespawn then
        local maxResp = math.max(0, STATE.cvPvPRespawnCount:GetInt())
        ply.lts_zs_pvp_lives = ply.lts_zs_pvp_lives or maxResp

        if ply.lts_zs_pvp_lives > 0 then
            ply.lts_zs_pvp_lives = ply.lts_zs_pvp_lives - 1

            local delay = math.max(0, STATE.cvPvPRespawnDelay:GetInt())
            timer.Simple(delay, function()
                if not STATE.active or STATE.phase ~= "round" then return end
                if not IsValid(ply) then return end

                ply:UnSpectate()
                ply:Spawn()

                timer.Simple(0, function()
                    if IsValid(ply) and ply:Alive() then
                        ZS_RestorePlayerLoadout(STATE, ply)
                    end
                end)
            end)

            return
        end
    end

    STATE.deadPlayers[ply] = true

    timer.Simple(0, function()
        if not IsValid(ply) then return end
        ply:StripWeapons()
        ply:Spectate(OBS_MODE_ROAMING)
    end)
end)

hook.Add("PlayerDeathThink", "LTS_ZS_PlayerDeathThink", function(ply)
    if not STATE.active or STATE.phase ~= "round" then return end
    if STATE.deadPlayers[ply] then return false end
end)

hook.Add("PlayerSpawn", "LTS_ZS_PlayerSpawn", function(ply)
    if not STATE.active then return end

    if STATE.phase == "round" and STATE.deadPlayers[ply] then
        timer.Simple(0, function()
            if not IsValid(ply) then return end
            ply:StripWeapons()
            ply:Spectate(OBS_MODE_ROAMING)
        end)
        return
    end

    timer.Simple(0, function()
        if IsValid(ply) and ply:Alive() then
            ZS_RestorePlayerLoadout(STATE, ply)
        end
    end)
end)

hook.Add("WeaponEquip", "LTS_ZS_WeaponEquip", function(wep, owner)
    if not STATE.active or STATE.phase ~= "round" then return end
    if not IsValid(owner) or not owner:IsPlayer() then return end

    timer.Simple(0, function()
        if not IsValid(owner) or not owner:Alive() then return end
        ZS_EnforceWeaponLimit(STATE, owner, wep)
        ZS_CachePlayerLoadout(STATE, owner)
    end)
end)

hook.Add("PlayerCanPickupWeapon", "LTS_ZS_BlockWeaponPickup", function(ply, wep)
    if not STATE.active then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(wep) then return end

    if STATE.cvRestrictWeapons:GetBool() then
        local forced = SafeWeaponClass(STATE.cvWeaponClass:GetString())
        if forced == "" then return end
        return (wep:GetClass() == forced)
    end

	local class = wep:GetClass()
	if class == "" then return end

	-- when restrict is OFF, allow any weapon pickup
	-- I swear I have had it with going back and forth with solutions for this problem
	return true
end)

hook.Add("LambdaOnKilled", "LTS_ZS_LambdaKilled", function(self, dmginfo)
    if not STATE.active or STATE.phase ~= "round" then return end
    if not IsValid(self) or not self.IsLambdaPlayer then return end

    local isPvP = STATE.cvPvPEnable:GetBool()
    local allowRespawn = isPvP and STATE.cvPvPRespawns:GetBool()

    if allowRespawn then
        local maxResp = math.max(0, STATE.cvPvPRespawnCount:GetInt())
        self.lts_zs_pvp_lives = self.lts_zs_pvp_lives or maxResp

        if self.lts_zs_pvp_lives > 0 then
            self.lts_zs_pvp_lives = self.lts_zs_pvp_lives - 1
            return
        end
    end

    if self.SetExternalVar then
        self:SetExternalVar("l_LTS_ZS_Dead", true)
    end
end)

local function DownLambda(self)
    if not IsValid(self) or not self.IsLambdaPlayer then return end

    self.lts_zs_downed = true
    self:SetNW2Bool("lts_zs_downed", true)
    self:SetNoDraw(true)
    self:SetNotSolid(true)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    if self.SetEnemy then
        self:SetEnemy(NULL)
    end
end

hook.Add("LambdaPostRecreated", "LTS_ZS_LambdaPostRecreated", function(self)
    if not STATE.active or STATE.phase ~= "round" then return end
    if not IsValid(self) or not self.IsLambdaPlayer then return end

    local deadFlag = self.l_LTS_ZS_Dead
    if deadFlag == nil and self.GetNW2Bool then
        deadFlag = self:GetNW2Bool("l_LTS_ZS_Dead", false)
    end

    if deadFlag then
        DownLambda(self)
        return
    end

    timer.Simple(0, function()
        if not IsValid(self) or not self.IsLambdaPlayer then return end
        if not STATE.active or STATE.phase ~= "round" then return end

        if STATE.cvRestrictWeapons:GetBool() then
            local wep = SafeWeaponClass( STATE.cvWeaponClassLambda:GetString() )
            if wep ~= "" then
                ApplyWeaponRestrictionToLambda( self, wep )
            end
        elseif STATE.round == 1 and STATE.cvResetOnRoundOne:GetBool() then
            ZS_GiveStarterWeaponToLambda( STATE, self )
        end
    end)
end)

hook.Add("PlayerShouldTakeDamage", "LTS_ZS_CoopNoTeamDamage", function(ply, attacker)
    if not STATE.active or STATE.phase ~= "round" then return end
    if STATE.cvPvPEnable:GetBool() then return end

    if not IsValid(attacker) then return end
    if attacker == ply then return end

    if attacker:IsPlayer() or attacker.IsLambdaPlayer then
        return false
    end
end)

if CLIENT then
    local function PlayClick()
        if PlayClientSound then PlayClientSound("buttons/button15.wav")
        else surface.PlaySound("buttons/button15.wav") end
    end

    local function ParseNPCList(str)
        local out, seen = {}, {}
        if not isstring(str) then return out end
        for token in string.gmatch(str, "[^,;|%s]+") do
            token = string.Trim(string.lower(token))
            if string.match(token, "^[%w_]+$") and not seen[token] then
                seen[token] = true
                out[#out + 1] = token
            end
        end
        return out
    end

    local function GetNPCDirectory()
        local npcTbl = list.Get("NPC") or {}
        local byClass = {}
        local entries = {}

        for _, data in pairs(npcTbl) do
            local class = data.Class or data.class
            if isstring(class) then
                local name = data.Name or class
                local cat  = data.Category or "Other"
                class = string.lower(class)

                byClass[class] = { name = name, class = class, category = cat }
                entries[#entries + 1] = byClass[class]
            end
        end

        table.sort(entries, function(a, b)
            if a.category == b.category then return a.name < b.name end
            return a.category < b.category
        end)

        return entries, byClass
    end

    local function LV_HasClass(lv, class)
        for _, line in ipairs(lv:GetLines()) do
            if string.lower(line:GetColumnText(2) or "") == class then return true end
        end
        return false
    end

    local function LV_Add(lv, info)
        if not info or not info.class or info.class == "" then return end
        if LV_HasClass(lv, info.class) then return end
        local line = lv:AddLine(info.name or info.class, info.class, info.category or "")
        line:SetSortValue(1, info.name or info.class)
        line:SetSortValue(2, info.class)
        line:SetSortValue(3, info.category or "")
    end

    local function LV_ToArray(lv)
        local out = {}
        for _, line in ipairs(lv:GetLines()) do
            local c = string.lower(line:GetColumnText(2) or "")
            if c ~= "" then out[#out + 1] = c end
        end
        return out
    end

    local function OpenZSNPCPicker()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:IsSuperAdmin() then
            notification.AddLegacy("You must be a Super Admin to use this menu!", 1, 4)
            if PlayClientSound then PlayClientSound("buttons/button10.wav") end
            return
        end

        local entries, byClass = GetNPCDirectory()

        local frame
        if LAMBDAPANELS and LAMBDAPANELS.CreateFrame then
            frame = LAMBDAPANELS:CreateFrame("Zombie Survival Custom NPCs Menu", 980, 600)
        else
            frame = vgui.Create("DFrame")
            frame:SetTitle("Zombie Survival Custom NPCs Menu")
            frame:SetSize(980, 600)
            frame:Center()
            frame:MakePopup()
        end

        local left = vgui.Create("DPanel", frame)
        left:Dock(LEFT)
        left:SetWide(520)
        left:DockMargin(6, 6, 6, 6)

        local right = vgui.Create("DPanel", frame)
        right:Dock(FILL)
        right:DockMargin(0, 6, 6, 6)

        local search = vgui.Create("DTextEntry", left)
        search:Dock(TOP)
        search:SetTall(24)
        search:SetPlaceholderText("Search NPC name (by class)")

        local avail = vgui.Create("DListView", left)
        avail:Dock(FILL)
        avail:AddColumn("NPC")
        avail:AddColumn("Class")
        avail:AddColumn("Category")

        local topBar = vgui.Create("DPanel", right)
        topBar:Dock(TOP)
        topBar:SetTall(28)

        local useCustom = vgui.Create("DCheckBoxLabel", topBar)
        useCustom:Dock(LEFT)
        useCustom:DockMargin(6, 4, 0, 0)
        useCustom:SetText("Use custom NPCs for the Zombie Survival gamemode")
        useCustom:SetValue(GetConVar("lambdaplayers_teamsystem_zs_usecustomnpcs") and GetConVar("lambdaplayers_teamsystem_zs_usecustomnpcs"):GetBool() and 1 or 0)
        useCustom:SizeToContents()

        local zombiesLbl = vgui.Create("DLabel", right)
        zombiesLbl:Dock(TOP)
        zombiesLbl:SetText("Zombie Rounds")
        zombiesLbl:DockMargin(0, 8, 0, 2)

        local zombiesLV = vgui.Create("DListView", right)
        zombiesLV:Dock(TOP)
        zombiesLV:SetTall(210)
        zombiesLV:AddColumn("NPC")
        zombiesLV:AddColumn("Class")
        zombiesLV:AddColumn("Category")

        local specialLbl = vgui.Create("DLabel", right)
        specialLbl:Dock(TOP)
        specialLbl:SetText("Special Rounds")
        specialLbl:DockMargin(0, 8, 0, 2)

        local specialLV = vgui.Create("DListView", right)
        specialLV:Dock(FILL)
        specialLV:AddColumn("NPC")
        specialLV:AddColumn("Class")
        specialLV:AddColumn("Category")

        local btnRow = vgui.Create("DPanel", right)
        btnRow:Dock(BOTTOM)
        btnRow:SetTall(36)

        local addZombie = vgui.Create("DButton", btnRow)
        addZombie:Dock(LEFT)
        addZombie:SetWide(150)
        addZombie:SetText("Add to Zombies")

        local addSpecial = vgui.Create("DButton", btnRow)
        addSpecial:Dock(LEFT)
        addSpecial:SetWide(150)
        addSpecial:SetText("Add to Specials")
        addSpecial:DockMargin(6, 0, 0, 0)

        local remove = vgui.Create("DButton", btnRow)
        remove:Dock(LEFT)
        remove:SetWide(120)
        remove:SetText("Remove Selected")
        remove:DockMargin(6, 0, 0, 0)

        local apply = vgui.Create("DButton", btnRow)
        apply:Dock(RIGHT)
        apply:SetWide(140)
        apply:SetText("Apply")

        local function RebuildAvailable(filter)
            avail:Clear()
            filter = string.lower(filter or "")
            for _, info in ipairs(entries) do
                if filter == "" or string.find(string.lower(info.name), filter, 1, true) or string.find(info.class, filter, 1, true) then
                    local line = avail:AddLine(info.name, info.class, info.category)
                    line._zsinfo = info
                end
            end
        end

        search.OnChange = function(self) RebuildAvailable(self:GetText()) end
        RebuildAvailable("")

        -- IM GONNA GET (your lists)
        local cz = GetConVar("lambdaplayers_teamsystem_zs_zombie_npclist")
        local cs = GetConVar("lambdaplayers_teamsystem_zs_special_npclist")

        for _, cls in ipairs(ParseNPCList(cz and cz:GetString() or "")) do
            LV_Add(zombiesLV, byClass[cls] or { name = cls, class = cls, category = "Custom/Unknown" })
        end
        for _, cls in ipairs(ParseNPCList(cs and cs:GetString() or "")) do
            LV_Add(specialLV, byClass[cls] or { name = cls, class = cls, category = "Custom/Unknown" })
        end

        local function GetSelectedAvailInfo()
            local _, line = avail:GetSelectedLine()
            if not line then return nil end
            return line._zsinfo
        end

        addZombie.DoClick = function()
            local info = GetSelectedAvailInfo()
            if not info then return end
            LV_Add(zombiesLV, info)
            PlayClick()
        end

        addSpecial.DoClick = function()
            local info = GetSelectedAvailInfo()
            if not info then return end
            LV_Add(specialLV, info)
            PlayClick()
        end

        function avail:OnRowRightClick(_, line)
            if not line or not line._zsinfo then return end
            local m = DermaMenu(false, frame)
            m:AddOption("Add to Normal Rounds", function() LV_Add(zombiesLV, line._zsinfo) PlayClick() end)
            m:AddOption("Add to Special Rounds", function() LV_Add(specialLV, line._zsinfo) PlayClick() end)
            m:AddOption("Cancel", function() end)
            m:Open()
        end

        remove.DoClick = function()
            local _, zLine = zombiesLV:GetSelectedLine()
            if zLine then zombiesLV:RemoveLine(zombiesLV:GetSelectedLine()) PlayClick() return end

            local _, sLine = specialLV:GetSelectedLine()
            if sLine then specialLV:RemoveLine(specialLV:GetSelectedLine()) PlayClick() return end
        end

        apply.DoClick = function()
            local z = LV_ToArray(zombiesLV)
            local s = LV_ToArray(specialLV)

            net.Start(NET_ZS_SETNPCLISTS)
                net.WriteBool(useCustom:GetChecked())
                net.WriteUInt(#z, 7)
                for _, cls in ipairs(z) do net.WriteString(cls) end
                net.WriteUInt(#s, 7)
                for _, cls in ipairs(s) do net.WriteString(cls) end
            net.SendToServer()

            notification.AddLegacy("Sent ZS NPC lists to server.", 0, 3)
            PlayClick()
        end
    end

    -- OPEN WIDE BABY HERE COMES THE FIREWORKS
    if RegisterLambdaPanel then
        RegisterLambdaPanel(
            "LTS_ZS_NPCPicker",
            "Opens a panel that allows you to choose NPCs to use in the Zombie Survival gamemode (Super Admin only).",
            OpenZSNPCPicker
        )
    else
        concommand.Add("lambdaplayers_teamsystem_zs_open_npcpicker", OpenZSNPCPicker)
    end
end

if CLIENT then
    surface.CreateFont("LTS_ZS_HUDBig", { font = "Trebuchet24", size = 20, weight = 900 })
    surface.CreateFont("LTS_ZS_HUDSmall", { font = "Trebuchet24", size = 16, weight = 700 })

    local function ZS_IsParticipant(ent)
        if not IsValid(ent) then return false end
        if ent.GetNW2Bool then
            return ent:GetNW2Bool("LTS_ZS_Participant", false)
        end
        return ent:GetNWBool("LTS_ZS_Participant", false)
    end

    local function ZS_GetPoints(ent)
        if not IsValid(ent) then return 0 end
        if ent.GetNW2Int then
            return ent:GetNW2Int("LTS_ZS_Points", 0)
        end
        return ent:GetNWInt("LTS_ZS_Points", 0)
    end

    local function ZS_GetDisplayName(ent)
        if ent:IsPlayer() then return ent:Nick() end

        if ent.GetLambdaName then
            local nm = ent:GetLambdaName()
            if nm and nm ~= "" then return nm end
        end

        local nm = ent:GetName()
        return (nm ~= "" and nm or "Lambda")
    end

    hook.Add("HUDPaint", "LTS_ZS_HUD", function()
        if not GetGlobalBool("LTS_ZS_Active", false) then return end

        local round = GetGlobalInt("LTS_ZS_Round", 0)
        local rem = GetGlobalInt("LTS_ZS_EnemiesRemaining", 0)
        local t = GetGlobalInt("LTS_ZS_TimeRemaining", -1)
        local rtype = GetGlobalString("LTS_ZS_RoundType", "zombies")

        local statusClr = (rtype == "antlions" and Color(255, 70, 70) or Color(200, 230, 255))
        local roundLabel = (rtype == "antlions" and "SPECIAL" or string.upper(tostring(rtype)))

        local status = "ZS | Round " .. tostring(round) .. " | " .. roundLabel .. " | " .. tostring(rem) .. " Left"
        if t and t >= 0 then
            status = status .. " | " .. tostring(t) .. "s"
        end

        surface.SetFont("LTS_ZS_HUDSmall")
        local statusW, statusH = surface.GetTextSize(status)

        local x, y = 22, 22
        draw.RoundedBox(6, x - 8, y - 6, statusW + 16, statusH + 12, Color(0, 0, 0, 150))
        draw.SimpleText(status, "LTS_ZS_HUDSmall", x, y, statusClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local entries = {}
        local everyone = {}
        table.Add(everyone, GetLambdaPlayers())
        table.Add(everyone, player.GetAll())

        for _, ent in ipairs(everyone) do
            if not ZS_IsParticipant(ent) then continue end

            local teamName = LambdaTeams:GetPlayerTeam(ent) or "Neutral"
            entries[#entries + 1] = {
                name = ZS_GetDisplayName(ent),
                color = LambdaTeams:GetTeamColor(teamName, true) or color_white,
                points = ZS_GetPoints(ent)
            }
        end

        table.sort(entries, function(a, b)
            if a.points == b.points then
                return a.name < b.name
            end
            return a.points > b.points
        end)

        local listX = ScrW() - 320
        local listY = 24
        local rowH = 18
        local shown = math.min(#entries, 12)
        local boxH = 30 + (shown * rowH) + 10

        draw.RoundedBox(6, listX - 10, listY - 8, 300, boxH, Color(0, 0, 0, 150))
        draw.SimpleText("Zombie Survival Kills", "LTS_ZS_HUDBig", listX, listY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        listY = listY + 24

        for i = 1, shown do
            local entry = entries[i]

            draw.SimpleText(entry.name, "LTS_ZS_HUDSmall", listX, listY, entry.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(entry.points), "LTS_ZS_HUDSmall", listX + 270, listY, Color(255, 220, 120), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

            listY = listY + rowH
        end
    end)
end

if CLIENT then
    local function ZS_GetHumanWeaponEntries()
        local out, seen = {}, {}

        for _, wep in ipairs( weapons.GetList() or {} ) do
            local class = SafeWeaponClass( wep.ClassName or wep.Class or "" )
            if class == "" or seen[ class ] then continue end

            seen[ class ] = true
            out[ #out + 1 ] = {
                name = ( wep.PrintName and wep.PrintName ~= "" and wep.PrintName or class ),
                class = class
            }
        end

        table.sort( out, function( a, b ) return a.name < b.name end )
        return out
    end

    local function ZS_GetLambdaWeaponEntries()
        local out = {}
        if not _LAMBDAPLAYERSWEAPONS then return out end

        for class, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
            if class == "none" then continue end
            if class == "physgun" then continue end
            if data.cantbeselected then continue end

            out[ #out + 1 ] = {
                name = ( data.notagprettyname or data.prettyname or class ),
                class = class
            }
        end

        table.sort( out, function( a, b ) return a.name < b.name end )
        return out
    end

	local function ZS_GetSelectedLinePanel( listview )
		if not IsValid( listview ) then return nil end

		if listview.GetSelected then
			local selected = listview:GetSelected()

			if IsValid( selected ) then
				return selected
			end

			if istable( selected ) then
				for _, line in pairs( selected ) do
					if IsValid( line ) then
						return line
					end
				end
			end
		end

		if listview.GetSelectedLine and listview.GetLine then
			local lineID = listview:GetSelectedLine()
			if isnumber( lineID ) then
				local line = listview:GetLine( lineID )
				if IsValid( line ) then
					return line
				end
			end
		end

		return nil
	end

	local function ZS_SelectLineByClass( listview, class )
		if not IsValid( listview ) or not isstring( class ) or class == "" then return nil end

		for _, line in ipairs( listview:GetLines() or {} ) do
			if IsValid( line ) and line._zsclass == class then
				listview:SelectItem( line )

				local canvas = listview.GetCanvas and listview:GetCanvas()
				if IsValid( canvas ) and canvas.ScrollToChild then
					canvas:ScrollToChild( line )
				elseif listview.ScrollToChild then
					listview:ScrollToChild( line )
				elseif line.MakeVisible then
					line:MakeVisible()
				end

				return line
			end
		end

		return nil
	end

    local function ZS_OpenWeaponPairPanel( ply, title, humanCvarName, lambdaCvarName )
        if not IsValid( ply ) or not ply:IsSuperAdmin() then
            notification.AddLegacy( "You must be a Super Admin in order to use this!", NOTIFY_ERROR, 4 )
            surface.PlaySound( "buttons/button10.wav" )
            return
        end

        local humanCv = GetConVar( humanCvarName )
        local lambdaCv = GetConVar( lambdaCvarName )
        if not humanCv or not lambdaCv then
            notification.AddLegacy( "ZS weapon cvars were not found!", NOTIFY_ERROR, 4 )
            surface.PlaySound( "buttons/button10.wav" )
            return
        end

        local frame = vgui.Create( "DFrame" )
        frame:SetTitle( title )
        frame:SetSize( 1000, 560 )
        frame:Center()
        frame:MakePopup()

        local left = vgui.Create( "DPanel", frame )
        left:Dock( LEFT )
        left:SetWide( 490 )
        left:DockMargin( 6, 6, 3, 6 )

        local right = vgui.Create( "DPanel", frame )
        right:Dock( FILL )
        right:DockMargin( 3, 6, 6, 6 )

        local humanLV = vgui.Create( "DListView", left )
        humanLV:Dock( FILL )
        humanLV:AddColumn( "Human Weapon" )
        humanLV:AddColumn( "Class" )

        local lambdaLV = vgui.Create( "DListView", right )
        lambdaLV:Dock( FILL )
        lambdaLV:AddColumn( "Lambda Weapon" )
        lambdaLV:AddColumn( "Class" )

        for _, info in ipairs( ZS_GetHumanWeaponEntries() ) do
            local line = humanLV:AddLine( info.name, info.class )
            line._zsclass = info.class
        end

        for _, info in ipairs( ZS_GetLambdaWeaponEntries() ) do
            local line = lambdaLV:AddLine( info.name, info.class )
            line._zsclass = info.class
        end

        humanLV.OnRowSelected = function( _, _, line )
            if not line then return end
            local humanClass = line._zsclass
            local remap = LambdaTeams.LTS_ZS_HumanToLambdaWeapon or {}
            local lambdaClass = remap[ humanClass ] or humanClass
            ZS_SelectLineByClass( lambdaLV, lambdaClass )
        end

        ZS_SelectLineByClass( humanLV, humanCv:GetString() )
        ZS_SelectLineByClass( lambdaLV, lambdaCv:GetString() )

        local buttons = vgui.Create( "DPanel", frame )
        buttons:Dock( BOTTOM )
        buttons:SetTall( 36 )
        buttons:DockMargin( 6, 0, 6, 6 )

        local autoMap = vgui.Create( "DButton", buttons )
        autoMap:Dock( LEFT )
        autoMap:SetWide( 180 )
        autoMap:SetText( "Auto Map Lambda From Human" )
		autoMap.DoClick = function()
			local line = ZS_GetSelectedLinePanel( humanLV )
			if not line then return end

			local remap = LambdaTeams.LTS_ZS_HumanToLambdaWeapon or {}
			local lambdaClass = remap[ line._zsclass ] or line._zsclass
			ZS_SelectLineByClass( lambdaLV, lambdaClass )
			surface.PlaySound( "buttons/button15.wav" )
		end

        local save = vgui.Create( "DButton", buttons )
        save:Dock( RIGHT )
        save:SetWide( 120 )
        save:SetText( "Save" )
		save.DoClick = function()
    local humanLine = ZS_GetSelectedLinePanel( humanLV )
    local lambdaLine = ZS_GetSelectedLinePanel( lambdaLV )

    if not humanLine or not lambdaLine then
        notification.AddLegacy( "Select both a human weapon and a lambda weapon first.", NOTIFY_ERROR, 4 )
        surface.PlaySound( "buttons/button10.wav" )
        return
    end

    RunConsoleCommand( humanCvarName, humanLine._zsclass )
    RunConsoleCommand( lambdaCvarName, lambdaLine._zsclass )

    notification.AddLegacy( "Updated Zombie Survival weapon pair!", NOTIFY_GENERIC, 4 )
    surface.PlaySound( "buttons/button15.wav" )
    frame:Close()
end
	end

    CreateLambdaConsoleCommand(
        "lambdaplayers_teamsystem_zs_openrestrictedweaponpanel",
        function( ply )
            ZS_OpenWeaponPairPanel(
                ply,
                "Team System - ZS Restricted Weapons",
                "lambdaplayers_teamsystem_zs_weaponclass",
                "lambdaplayers_teamsystem_zs_weaponclass_lambda"
            )
        end,
        true,
        "Opens a panel to pick the human and lambda restricted weapons for Zombie Survival.",
        { name = "Edit Restricted Weapon", category = "Team System - Zombie Survival - Weapons" }
    )

    CreateLambdaConsoleCommand(
        "lambdaplayers_teamsystem_zs_openstarterweaponpanel",
        function( ply )
            ZS_OpenWeaponPairPanel(
                ply,
                "Team System - ZS Starter Weapons",
                "lambdaplayers_teamsystem_zs_starterweapon",
                "lambdaplayers_teamsystem_zs_starterweapon_lambda"
            )
        end,
        true,
        "Opens a panel to pick the human and lambda starter weapons for Zombie Survival.",
        { name = "Edit Starter Weapon", category = "Team System - Zombie Survival - Weapons" }
    )
end