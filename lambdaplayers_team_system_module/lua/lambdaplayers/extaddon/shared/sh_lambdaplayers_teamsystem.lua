local ipairs = ipairs
local IsValid = IsValid
local CurTime = CurTime
local tostring = tostring
local pairs = pairs
local GetGlobalInt = GetGlobalInt
local SetGlobalInt = SetGlobalInt
local Rand = math.Rand
local random = math.random
local table_Count = table.Count
local table_Empty = table.Empty
local team_SetUp = team.SetUp
local team_SetColor = team.SetColor
local team_GetColor = team.GetColor
local net = net
local ents_GetAll = ents.GetAll
local ents_FindByClass = ents.FindByClass
local player_GetAll = player.GetAll
local table_Add = table.Add
local table_Copy = table.Copy
local table_remove = table.remove
local timer_Simple = timer.Simple
local timer_Create = timer.Create
local timer_Remove = timer.Remove
local file_Exists = file.Exists


local modulePrefix = "Lambda_TeamSystem_"
local defaultPlyClr = Color( 255, 255, 100 )
local color_glacier = Color( 130, 164, 192 )

local ignorePlys = GetConVar( "ai_ignoreplayers" )
local rasp = GetConVar( "lambdaplayers_lambda_respawnatplayerspawns" )

if SERVER and !file_Exists( "lambdaplayers/teamlist.json", "DATA" ) then
    LAMBDAFS:WriteFile( "lambdaplayers/teamlist.json", {
        [ "Based Bros" ] = {
            name = "Based Bros",
            color = Vector( 1, 0, 0 )
        },
        [ "Counter-Minges" ] = {
            name = "Counter-Minges",
            color = Vector( 0, 0.2471, 1 )
        },
        [ "Eeveelutioners" ] = {
            name = "Eeveelutioners",
            color = Vector( 0, 1, 1 )
        },
        [ "ARCLIGHT" ] = {
            name = "ARCLIGHT",
            color = Vector( 0.6039, 0.2392, 1 )
        }
    }, "json", false )
end

LambdaTeams = LambdaTeams or {}
LambdaTeams.AlliedTeams = LambdaTeams.AlliedTeams or {}
LambdaTeams.AOSExempt = LambdaTeams.AOSExempt or {}

local function TeamSystemEnabled()
    local cv = GetConVar( "lambdaplayers_teamsystem_enable" )
    return ( cv and cv:GetBool() ) or false
end

function LambdaTeams:UpdateData()
    local teamList = LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" )
    if table_Count( teamList ) == 0 then print( "LAMBDA TEAM SYSTEM WARNING: THERE ARE NO TEAMS REGISTERED!" ) return end
    
    LambdaTeams.TeamData = teamList
    LambdaTeams.RealTeams = LambdaTeams.RealTeams or {}
    LambdaTeams.RealTeamCount = LambdaTeams.RealTeamCount or 0

    if ( CLIENT ) then
        LambdaTeams.TeamOptions = { [ "None" ] = "" }
        LambdaTeams.TeamOptionsRandom = { [ "None" ] = "", [ "Random" ] = "random" }
    end

    local teamID = ( LambdaTeams.RealTeamCount + 1 )
    for name, data in pairs( LambdaTeams.TeamData ) do 
        if ( CLIENT ) then
            LambdaTeams.TeamOptions[ name ] = name 
            LambdaTeams.TeamOptionsRandom[ name ] = name
        end

        local teamClr = data.color
        teamClr = ( teamClr and teamClr:ToColor() or defaultPlyClr )

        if !LambdaTeams.RealTeams[ name ] then
            team_SetUp( teamID, name, teamClr, false )
            LambdaTeams.RealTeams[ name ] = teamID

            teamID = teamID + 1
            LambdaTeams.RealTeamCount = teamID
        else
            team_SetColor( LambdaTeams.RealTeams[ name ], teamClr )
        end
    end
end

	LambdaTeams:UpdateData()

---

local teamsEnabled  = CreateLambdaConvar( "lambdaplayers_teamsystem_enable", 0, true, false, false, "Enables the work of the module.", 0, 1, { name = "Enable Team System", type = "Bool", category = "Team System" } )
local mwsTeam       = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_spawnteam", "", true, false, false, "The team the newly spawned Lambda Players from MWS should be assigned into.", 0, 1, { name = "Spawn Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "MWS" } )
local incNoTeams    = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_includenoteams", 0, true, false, false, "When spawning a Lambda Player from MWS with random team, should they also have a chance to spawn without being assigned to any team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "MWS" }  )
local mwsTeamLimit  = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_teamlimit", 0, true, false, false, "The limit of how many members can be allowed to be assigned to each team. Set to zero for no limit.", 0, 50, { name = "Team Member Limit", type = "Slider", decimals = 0, category = "MWS" }  )
CreateLambdaConvar( "lambdaplayers_teamsystem_lambdateam", "", true, true, true, "The team the newly spawned Lambda Players should be assigned into.", 0, 1, { name = "Lambda Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "Team System" } )
local playerTeam    = CreateLambdaConvar( "lambdaplayers_teamsystem_playerteam", "", true, true, true, "The lambda team you are currently assigned to.", 0, 1, { name = "Player Team", type = "Combo", options = LambdaTeams.TeamOptions, category = "Team System" }  )

if SERVER then
    SetGlobalBool("LambdaTeamSystem_Enabled", TeamSystemEnabled())
end

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_updateteamlist", function( ply ) 
    LambdaTeams:UpdateData()

	for _, option in ipairs( _LAMBDAConVarSettings ) do
		if option.name == "Player Team" then option.options = LambdaTeams.TeamOptions end
		if option.name == "Lambda Team" then option.options = LambdaTeams.TeamOptionsRandom end
		if option.name == "Attacking Team" then option.options = LambdaTeams.TeamOptions end
		if option.name == "Defending Team" then option.options = LambdaTeams.TeamOptions end
	end

-- Oops someone didnt know how to spell editing
    ply:ConCommand( "spawnmenu_reload" )
end, true, "Refreshes the team list. Use this after editing teams in the team panel.", { name = "Refresh Team List", category = "Team System" } )

-- General Settings (Also why tf did you space out the convars so much star I genuinely wanna know)
CreateLambdaConvar( "lambdaplayers_teamsystem_includenoteams", 0, true, true, true, "When spawning a Lambda Player with random team, should they also have a chance to spawn without being assigned to a team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "Team System" } )
local teamLimit = CreateLambdaConvar( "lambdaplayers_teamsystem_teamlimit", 0, true, false, false, "The limit of how many members can be allowed to be assigned to each team. Set to 0 for no limit.", 0, 50, { name = "Team Member Limit", type = "Slider", decimals = 0, category = "Team System" } )
local attackOthers = CreateLambdaConvar( "lambdaplayers_teamsystem_attackotherteams", 0, true, false, false, "If enabled, Lambda Players will attack other Lambda Players outside of their team or alliance.", 0, 1, { name = "Attack On Sight", type = "Bool", category = "Team System" } )
local stickTogether = CreateLambdaConvar( "lambdaplayers_teamsystem_sticktogether", 1, true, false, false, "If enabled, Lambda Players will attempt to stay together with their teamates.", 0, 1, { name = "Stick Together", type = "Bool", category = "Team System" } )
local huntDown = CreateLambdaConvar( "lambdaplayers_teamsystem_huntdownotherteams", 0, true, false, false, "If enabled, Lambda Players will hunt down other Lambda Players not on their team (enable Attack On Sight for this to take full effect).", 0, 1, { name = "Hunt Down Enemy Teams", type = "Bool", category = "Team System" } )
local teamAggression = CreateLambdaConvar( "lambdaplayers_teamsystem_aggression", 50, true, false, false, "How committed Lambda Players should be when reacting to enemy teams (Lower values make them break off sooner, Higher values make them chase harder & longer).", 0, 100, { name = "Aggression Level", type = "Slider", decimals = 0, category = "Team System" } )
local specificCampWeapons = CreateLambdaConvar( "lambdaplayers_teamsystem_specificcampweapons", "m9k_hvy_areshrike, m9k_hvy_aw50, m9k_hvy_bar, m9k_hvy_barret_m82, m9k_hvy_barret_m98b, m9k_hvy_dragunov_svd, m9k_hvy_dragunov_svu, m9k_hvy_fg42, m9k_hvy_g2contender, m9k_hvy_hksl8, m9k_hvy_intervention, m9k_hvy_m24, m9k_hvy_m60, m9k_hvy_m249, m9k_hvy_pkm, m9k_hvy_psg1, m9k_hvy_remington_7615p, m9k_hvy_svt40", true, false, false, "(Comma separated) If a Lambda Player is using one of these weapons, they may hold their position and fire from range instead of pushing forward (THIS HAS BEEN TESTED ONLY WITH THE LAMBDA PLAYER M9K ADDON, THIS MAY NOT WORK WITH OTHERS).", 0, 1, { name = "Specific Lambda Players Can Camp (M9K)", type = "Text", category = "Team System" } )
local noFriendFire = CreateLambdaConvar( "lambdaplayers_teamsystem_nofriendlyfire", 1, true, false, false, "If enabled, Lambda & Human players will not be able to damage each other if they're on the same team.", 0, 1, { name = "No Friendly Fire", type = "Bool", category = "Team System" } )
local useSpawnpoints = CreateLambdaConvar( "lambdaplayers_teamsystem_usespawnpoints", 0, true, false, false, "If enabled, Lambda Players will respawn at one of their team's spawn points.", 0, 1, { name = "Respawn In Team Spawn Points", type = "Bool", category = "Team System" } )
local plyUseSpawnpoints = CreateLambdaConvar( "lambdaplayers_teamsystem_plyusespawnpoints", 0, true, true, true, "If enabled, you will respawn at one of your Lambda Team's spawn points.", 0, 1, { name = "Respawn In Team Spawn Points", type = "Bool", category = "Team System" } )
local drawTeamName = CreateLambdaConvar( "lambdaplayers_teamsystem_drawteamname", 1, true, true, false, "Enables drawing team names above your Lambda teammates.", 0, 1, { name = "Draw Team Names", type = "Bool", category = "Team System" } )
local drawHalo = CreateLambdaConvar( "lambdaplayers_teamsystem_drawhalo", 1, true, true, false, "Enables drawing halos around you Lambda Teammates", 0, 1, { name = "Draw Halos", type = "Bool", category = "Team System" } )
local teamSpawnEnemyRadius = CreateLambdaConvar( "lambdaplayers_teamsystem_teamspawn_enemyradius", 600, true, false, false, "How close enemies can be to a team spawn before it is avoided. Set to 0 to disable safe spawning.", 0, 4000, { name = "Safezone Spawn Radius", type = "Slider", decimals = 0, category = "Team System" } )
local drawTeamNameMaxDist = CreateLambdaConvar( "lambdaplayers_teamsystem_drawteamname_maxdist", 2000, true, true, false, "Max distance at which teammate names are drawn. Set to 0 to disable the distance limit.", 0, 10000, { name = "Team Name Max Distance", type = "Slider", decimals = 0, category = "Team System" } )
local drawHaloMaxDist = CreateLambdaConvar( "lambdaplayers_teamsystem_drawhalo_maxdist", 1800, true, true, false, "Max distance at which teammate halos are drawn. Set to 0 to disable the distance limit.", 0, 10000, { name = "Halo Max Distance", type = "Slider", decimals = 0, category = "Team System" } )
---

local gmMatchTime = CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_gametime", 5, true, false, false, "The time the gamemode match will take to end in minutes. Set to zero for an endless match.", 0, 180, { name = "Match Time", type = "Slider", decimals = 0, category = "Team System - Gamemode Settings" } )
local gmPointsLimit = CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_pointslimit", 30, true, false, false, "How many points should the team score in gamemode match in order to win. Set to zero to disable points", 0, 5000, { name = "Points Limit", type = "Slider", decimals = 0, category = "Team System - Gamemode Settings" } )
local gmTPToSpawns = CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_tptospawns", 1, true, false, false, "If team players should be teleported to their spawn positions on gamemode start", 0, 1, { name = "Teleport To Spawn On Start", type = "Bool", category = "Team System - Gamemode Settings" } )
local objCommitTime = CreateLambdaConvar( "lambdaplayers_teamsystem_obj_commit_time", 3.5, true, false, false, "How long Lambdas Players should commit to a specific objective before reconsidering/changing (Higher values make the gamemodes faster paced).", 0.5, 15, { name = "Objective Commitment Time", type = "Slider", decimals = 1, category = "Team System - Gamemode Settings" } )
local objRepathCooldown = CreateLambdaConvar( "lambdaplayers_teamsystem_obj_repath_cooldown", 1.0, true, false, false, "How often should Lambda Players retry to commit to gamemode objectives if they fail (lower values will lower performance slightly).", 0.1, 10, { name = "Objective Retrying", type = "Slider", decimals = 1, category = "Team System - Gamemode Settings" } )
local objStuckTime = CreateLambdaConvar( "lambdaplayers_teamsystem_obj_stuck_time", 2.0, true, false, false, "How long must a Lambda Player fail to make progress before objective is considered a lost cause (I recommend setting it anywhere between 2-6 seconds, imagine sucking lol).", 0.5, 10, { name = "Objective Confidence", type = "Slider", decimals = 1, category = "Team System - Gamemode Settings" } )
local objStuckMove = CreateLambdaConvar( "lambdaplayers_teamsystem_obj_stuck_move", 55, true, false, false, "The minimum movement over stuck time to be considered making progress (sad piano music).", 5, 250, { name = "Confidence Movement Threshold", type = "Slider", decimals = 0, category = "Team System - Gamemode Settings" } )


--
local gmMinTeams = CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_minteams", 2, true, false, false, "The minimum amount of active teams required to start a gamemode match (Set to 1 if you are playing Zombie Survival or it will not start).", 1, 16, { name = "Minimum Teams To Start", type = "Slider", decimals = 0, category = "Team System - Gamemode Settings" } )
local hudScoreRefresh = CreateLambdaConvar( "lambdaplayers_teamsystem_hud_score_refresh", 0.25, true, true, false, "How often the match score list on the HUD refreshes. Lower values are more responsive but slightly heavier.", 0.05, 2.0, { name = "HUD Score Refresh", type = "Slider", decimals = 2, category = "Team System - Gamemode Settings" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_onwin", "lambdaplayers/gamewon/*", true, true, false, "The sound that plays when your team wins a gamemode match", 0, 1, { name = "Sound - On Game Won", type = "Text", category = "Team System - Gamemode Settings" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_onlose", "lambdaplayers/gamelost/*", true, true, false, "The sound that plays when your team loses a gamemode match", 0, 1, { name = "Sound - On Game Lost", type = "Text", category = "Team System - Gamemode Settings" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_gamestart", "lambdaplayers/gamestart/*", true, true, false, "The sound that plays when a gamemode starts.", 0, 1, { name = "Sound - On Match Begin", type = "Text", category = "Team System - Gamemode Settings" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_match60left", "", true, true, false, "The sound that plays when there's 60 seconds left before match's end.", 0, 1, { name = "Sound - 60 Second Left", type = "Text", category = "Team System - Gamemode Settings" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_match30left", "lambdaplayers/matchtimeleft/30seconds.mp3", true, true, false, "The sound that plays when there's 30 seconds left before match's end.", 0, 1, { name = "Sound - 30 Second Left", type = "Text", category = "Team System - Gamemode Settings" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_match10left", "lambdaplayers/matchtimeleft/10seconds.mp3", true, true, false, "The sound that plays when there's 10 seconds left before match's end.", 0, 1, { name = "Sound - 10 Second Left", type = "Text", category = "Team System - Gamemode Settings" } )

LambdaTeams.TeamPoints = LambdaTeams.TeamPoints or {}
LambdaTeams.SoundsToStop = LambdaTeams.SoundsToStop or {}

local gamemodeName, pointsName
local matchWinReason, matchWinTeam
local nextTimerProgressT = ( CurTime() + 1 )

local function GetTheMatchStats( endedPrematurely )
    local winnerTeam, winnerClr
    local curPoints, samePoints = 0, 0

    local contesters = {}
    for teamName, globalName in pairs( LambdaTeams.TeamPoints ) do
        local teamPoints = GetGlobalInt( globalName, 0 )
        local teamColor = LambdaTeams:GetTeamColor( teamName, true )

        if teamPoints > curPoints or !winnerTeam then
            winnerTeam = teamName
            winnerClr = teamColor
            curPoints = teamPoints
            samePoints = 1
        elseif teamPoints == curPoints then
            samePoints = ( samePoints + 1 )
        end

        contesters[ #contesters + 1 ] = { teamName, teamPoints, teamColor }
    end

    if samePoints != #contesters then
        if matchWinReason == "assault_fullcap" and matchWinTeam == winnerTeam then
            LambdaPlayers_ChatAdd(
                nil,
                color_white, "[LTS] ",
                winnerClr, winnerTeam,
                color_glacier, " won the match of ",
                color_white, gamemodeName,
                color_glacier, " by capturing every sector!"
            )
        elseif matchWinReason == "assault_timeout" and matchWinTeam == winnerTeam then
            LambdaPlayers_ChatAdd(
			
                nil,
                color_white, "[LTS] ",
                winnerClr, winnerTeam,
                color_glacier, " won the match of ",
                color_white, gamemodeName,
                color_glacier, " by holding the line until time expired!"
            )
		elseif matchWinReason == "sabotage_lastsite" and matchWinTeam == winnerTeam then
			LambdaPlayers_ChatAdd(
				nil,
				color_white, "[LTS] ",
				winnerClr, winnerTeam,
				color_glacier, " won the match of ",
				color_white, gamemodeName,
				color_glacier, " by being the last team with a sabotage site!"
			)
        else
            LambdaPlayers_ChatAdd(
                nil,
                color_white, "[LTS] ",
                winnerClr, winnerTeam,
                color_glacier, " won the match of ",
                color_white, gamemodeName,
                color_glacier, " with total of ",
                color_white, tostring( curPoints ),
                color_glacier, " ",
                pointsName,
                ( curPoints > 1 and "s" or "" ),
                "!"
            )
        end

        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_onwin", winnerTeam )

		for _, contestData in ipairs( contesters ) do
			local contestTeam = contestData[ 1 ]
			if contestTeam == winnerTeam then continue end

			local contestPoints = contestData[ 2 ]
			local contestClr = contestData[ 3 ]

			if gamemodeName == "Assault" then
				if matchWinReason == "assault_fullcap" then
					LambdaPlayers_ChatAdd(
						nil,
						color_white, "[LTS] ",
						contestClr, contestTeam,
						color_glacier, " failed to hold the sectors >:("
					)
				elseif matchWinReason == "assault_timeout" then
					LambdaPlayers_ChatAdd(
						nil,
						color_white, "[LTS] ",
						contestClr, contestTeam,
						color_glacier, " failed to breach every sector before time expired D:"
					)
				else
					LambdaPlayers_ChatAdd(
						nil,
						color_white, "[LTS] ",
						contestClr, contestTeam,
						color_glacier, " captured ",
						color_white, tostring( contestPoints ),
						color_glacier, " sector",
						( contestPoints != 1 and "s" or "" ),
						"."
					)
				end
			
			elseif gamemodeName == "Sabotage" then
				local lostSite = ( LambdaTeams.IsSabotageTeamAlive and !LambdaTeams:IsSabotageTeamAlive( contestTeam ) )

				if lostSite then
					LambdaPlayers_ChatAdd(
						nil,
						color_white, "[LTS] ",
						contestClr, contestTeam,
						color_glacier, " lost their sabotage site."
					)
				elseif contestPoints > 0 then
					LambdaPlayers_ChatAdd(
						nil,
						color_white, "[LTS] ",
						contestClr, contestTeam,
						color_glacier, " destroyed ",
						color_white, tostring( contestPoints ),
						color_glacier, " enemy site",
						( contestPoints != 1 and "s" or "" ),
						"."
					)
				else
					LambdaPlayers_ChatAdd(
						nil,
						color_white, "[LTS] ",
						contestClr, contestTeam,
						color_glacier, " failed to destroy any enemy sites."
					)
				end
	
			elseif contestPoints == 0 then
				LambdaPlayers_ChatAdd(
					nil,
					color_white, "[LTS] ",
					contestClr, contestTeam,
					color_glacier, " ended up with no ",
					pointsName,
					"s at all :("
				)
			else
				LambdaPlayers_ChatAdd(
					nil,
					color_white, "[LTS] ",
					contestClr, contestTeam,
					color_glacier, " ended with total of ",
					color_white, tostring( contestPoints ),
					color_glacier, " ",
					pointsName,
					( contestPoints > 1 and "s" or "" )
				)
			end

			LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_onlose", contestTeam )
		end
		
    elseif !endedPrematurely then
        LambdaPlayers_ChatAdd(
            nil,
            color_white, "[LTS] ",
            color_glacier, "Stalemate! Each team got the same amount of ",
            pointsName,
            ( curPoints > 1 and "s" or "" ),
            "!"
        )
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_onlose" )
    end
end

local function LTS_SetBoolCompat( ent, key, val )
    if !IsValid( ent ) then return end
    ent:SetNW2Bool( key, val )
    ent:SetNWBool( key, val )
end

local function LTS_SetStringCompat( ent, key, val )
    if !IsValid( ent ) then return end
    ent:SetNW2String( key, val )
    ent:SetNWString( key, val )
end

local function LTS_SetIntCompat( ent, key, val )
    if !IsValid( ent ) then return end
    ent:SetNW2Int( key, val )
    ent:SetNWInt( key, val )
end

local function LTS_AssaultNeedsTwoTeams()
    local cv = assaultRequireTwoTeams or GetConVar( "lambdaplayers_teamsystem_assault_requiretwoteams" )
    return ( cv and cv:GetBool() ) or false
end

local function LTS_AssaultStartOwned()
    local cv = GetConVar( "lambdaplayers_teamsystem_assault_startowned" )
    if cv then
        return cv:GetBool()
    end

    return ( assaultStartOwned and assaultStartOwned:GetBool() ) or false
end

local function LTS_AssaultAutoOrder()
    return ( assaultAutoOrder and assaultAutoOrder:GetBool() ) or false
end

local function LTS_NormalizeAssaultPointName( name )
    name = string.Trim( tostring( name or "" ) )
    name = string.gsub( name, "%s+", " " )
    return string.lower( name )
end

local function LTS_GetAssaultPointName( point )
    if !IsValid( point ) then return "" end

    local candidates = {
        ( point.GetPointName and point:GetPointName() ) or nil,
        point.CustomName,
        point.PointName,
        point.LTS_PointName,
        point.AssaultPointName,
        point.GetName and point:GetName() or nil
    }

    for _, name in ipairs( candidates ) do
        local normalized = LTS_NormalizeAssaultPointName( name )
        if normalized != "" then
            return normalized
        end
    end

    return ""
end

local function LTS_SortAssaultPointsStable( points )
    table.sort( points, function( a, b )
        if !IsValid( a ) then return false end
        if !IsValid( b ) then return true end

        local aName = LTS_GetAssaultPointName( a )
        local bName = LTS_GetAssaultPointName( b )

        if aName != "" and bName == "" then return true end
        if aName == "" and bName != "" then return false end

        if aName != "" and bName != "" and aName != bName then
            return aName < bName
        end

        local aID = ( a.GetCreationID and a:GetCreationID() ) or 0
        local bID = ( b.GetCreationID and b:GetCreationID() ) or 0
        if aID != bID then
            return aID < bID
        end

        return a:EntIndex() < b:EntIndex()
    end )
end

local function LTS_OrderAssaultPoints( points )
    if !points or #points == 0 then return {} end

    local ordered = table_Copy( points )
    LTS_SortAssaultPointsStable( ordered )

    if LTS_AssaultAutoOrder() then
        return ordered
    end

    local rawOrder = ( assaultPointOrder and assaultPointOrder:GetString() ) or ""
    local wanted = {}

    for token in string.gmatch( rawOrder, "([^,;]+)" ) do
        token = LTS_NormalizeAssaultPointName( token )
        if token != "" then
            wanted[ #wanted + 1 ] = token
        end
    end

    if #wanted == 0 then
        return ordered
    end

    local byName = {}
    for _, pt in ipairs( ordered ) do
        if !IsValid( pt ) then continue end

        local pointName = LTS_GetAssaultPointName( pt )
        if pointName == "" then continue end

        byName[ pointName ] = byName[ pointName ] or {}
        byName[ pointName ][ #byName[ pointName ] + 1 ] = pt
    end

    local finalOrder = {}
    local used = {}

    for _, wantedName in ipairs( wanted ) do
        local matches = byName[ wantedName ]
        if !matches then continue end

        for _, pt in ipairs( matches ) do
            if used[ pt ] then continue end
            used[ pt ] = true
            finalOrder[ #finalOrder + 1 ] = pt
            break
        end
    end

    for _, pt in ipairs( ordered ) do
        if !IsValid( pt ) or used[ pt ] then continue end
        finalOrder[ #finalOrder + 1 ] = pt
    end

    return finalOrder
end

local function LTS_GetAssaultPoints()
    local points = {}
    local seen = {}

    for _, ent in ipairs( ents_FindByClass( "lambda_assault_point" ) ) do
        if !IsValid( ent ) or seen[ ent ] then continue end
        points[ #points + 1 ] = ent
        seen[ ent ] = true
    end

    for _, ent in ipairs( ents_GetAll() ) do
        if !IsValid( ent ) or seen[ ent ] then continue end
        if ent.IsLambdaAssault
        or ent:GetNW2Bool( "LTS_IsAssaultPoint", false )
        or ent:GetNWBool( "LTS_IsAssaultPoint", false )
        then
            points[ #points + 1 ] = ent
            seen[ ent ] = true
        end
    end

    return points
end

local function LTS_ClearAssaultFlags()
    for _, pt in ipairs( LTS_GetAssaultPoints() ) do
        if !IsValid( pt ) then continue end
        LTS_SetBoolCompat( pt, "LTS_AssaultActive", false )
        LTS_SetStringCompat( pt, "LTS_AssaultAttackTeam", "" )
        LTS_SetStringCompat( pt, "LTS_AssaultDefendTeam", "" )
    end
end

local function LTS_ColorToVector( clr )
    if isvector( clr ) then return clr end
    if !clr then return Vector( 1, 1, 1 ) end

    if clr.ToVector then
        return clr:ToVector()
    end

    if clr.r and clr.g and clr.b then
        return Vector( clr.r / 255, clr.g / 255, clr.b / 255 )
    end

    return Vector( 1, 1, 1 )
end

local function LTS_ForceOwnAssaultPoint( point, teamName )
    if !IsValid( point ) or !teamName or teamName == "" then return false end

    local teamClr = LambdaTeams:GetTeamColor( teamName )
    local clrVec = LTS_ColorToVector( teamClr )

    if point.BecomeNeutral then
        point:BecomeNeutral()
    end

    if point.SetIsCaptured then point:SetIsCaptured( true ) end
    if point.SetCapturerName then point:SetCapturerName( teamName ) end
    if point.SetCapturePercent then point:SetCapturePercent( 100 ) end
    if point.SetCapturerColor then point:SetCapturerColor( clrVec ) end
    if point.SetContesterTeam then point:SetContesterTeam( "" ) end
    if point.SetContesterColor then point:SetContesterColor( Vector( 1, 1, 1 ) ) end

    point.IsNonTeamCaptured = false
    point.OldCapturer = teamName
    point.OldColor = clrVec

    LTS_SetBoolCompat( point, "LTS_AssaultCaptured", true )
    LTS_SetStringCompat( point, "LTS_AssaultOwner", teamName )
    LTS_SetStringCompat( point, "LTS_AssaultContester", "" )
    LTS_SetIntCompat( point, "LTS_AssaultCapturePercent", 100 )

    return true
end

function LambdaTeams:GetAssaultAttackTeam()
    local cv = assaultAttackingTeam or GetConVar( "lambdaplayers_teamsystem_assault_attackteam" )
    local teamName = ( cv and cv:GetString() ) or ""
    return ( teamName != "" and teamName or nil )
end

function LambdaTeams:GetAssaultDefendTeam()
    local cv = assaultDefendingTeam or GetConVar( "lambdaplayers_teamsystem_assault_defendteam" )
    local teamName = ( cv and cv:GetString() ) or ""
    return ( teamName != "" and teamName or nil )
end

local function LTS_GetMatchTeams()
    local teams = {}
    local seen = {}

    for teamName, _ in pairs( LambdaTeams.TeamPoints or {} ) do
        if !teamName or teamName == "" or seen[ teamName ] then continue end
        seen[ teamName ] = true
        teams[ #teams + 1 ] = teamName
    end

    if #teams > 0 then
        return teams
    end

    local allEnts = {}
    if GetLambdaPlayers then
        table_Add( allEnts, GetLambdaPlayers() or {} )
    end
    table_Add( allEnts, player_GetAll() or {} )

    for _, ent in ipairs( allEnts ) do
        if !IsValid( ent ) then continue end

        local teamName = LambdaTeams:GetPlayerTeam( ent )
        if !teamName or teamName == "" or seen[ teamName ] then continue end

        seen[ teamName ] = true
        teams[ #teams + 1 ] = teamName
    end

    return teams
end

function LambdaTeams:Assault_Rebuild()
    local attackTeam = self:GetAssaultAttackTeam()
    local defendTeam = self:GetAssaultDefendTeam()

    if !attackTeam or !defendTeam or attackTeam == defendTeam then
        self.Assault_State = nil
        if SERVER then LTS_ClearAssaultFlags() end
        return nil
    end

    local teams = LTS_GetMatchTeams()
    if LTS_AssaultNeedsTwoTeams() and #teams != 2 then
        self.Assault_State = nil
        if SERVER then LTS_ClearAssaultFlags() end
        return nil
    end

    local activeSet = {}
    for _, t in ipairs( teams ) do activeSet[ t ] = true end
    if !activeSet[ attackTeam ] or !activeSet[ defendTeam ] then
        self.Assault_State = nil
        if SERVER then LTS_ClearAssaultFlags() end
        return nil
    end

    local points = LTS_GetAssaultPoints()
	points = LTS_OrderAssaultPoints( points )
	
	print( "[LTS Assault] Auto Order:", LTS_AssaultAutoOrder() )
	print( "[LTS Assault] Manual Order:", ( assaultPointOrder and assaultPointOrder:GetString() ) or "" )
	print( "[LTS Assault] Start Owned:", LTS_AssaultStartOwned() )

	for i, pt in ipairs( points ) do
		if IsValid( pt ) then
			print( "[LTS Assault] Ordered Point #" .. i .. ": " .. tostring( pt:GetPointName() ) )
		end
	end

    if !points or #points == 0 then
        self.Assault_State = nil
        if SERVER then LTS_ClearAssaultFlags() end
        return nil
    end

    if SERVER then
        for i, pt in ipairs( points ) do
            if !IsValid( pt ) then continue end

            LTS_SetBoolCompat( pt, "LTS_AssaultActive", i == 1 )
            LTS_SetStringCompat( pt, "LTS_AssaultAttackTeam", attackTeam )
            LTS_SetStringCompat( pt, "LTS_AssaultDefendTeam", defendTeam )

            if LTS_AssaultStartOwned() then
                LTS_ForceOwnAssaultPoint( pt, defendTeam )
            else
                pt:BecomeNeutral()
            end
        end
    end

    self.Assault_State = {
        AttackTeam = attackTeam,
        DefendTeam = defendTeam,
        Points = points,
        Index = 1,
        LastCapturer = nil
    }

    self.Assault_CurrentPoint = points[ 1 ]
    self.Assault_Points = points
    return self.Assault_State
end

local function LTS_GetNetworkedAssaultActivePoint()
    for _, pt in ipairs( LTS_GetAssaultPoints() ) do
        if IsValid( pt ) and pt:GetNW2Bool( "LTS_AssaultActive", pt:GetNWBool( "LTS_AssaultActive", false ) ) then
            local attackTeam = pt:GetNW2String( "LTS_AssaultAttackTeam", pt:GetNWString( "LTS_AssaultAttackTeam", "" ) )
            local defendTeam = pt:GetNW2String( "LTS_AssaultDefendTeam", pt:GetNWString( "LTS_AssaultDefendTeam", "" ) )
            return pt, attackTeam, defendTeam
        end
    end

    return nil, nil, nil
end

function LambdaTeams:GetAssaultActivePoint()
    if CLIENT then
        local activePoint = LTS_GetNetworkedAssaultActivePoint()
        return activePoint
    end

    local state = self.Assault_State
    if !state then state = self:Assault_Rebuild() end
    return ( state and state.Points and state.Points[ state.Index ] or nil )
end

function LambdaTeams:GetAssaultAttackPoint( teamName )
    if CLIENT then
        local activePoint, attackTeam = LTS_GetNetworkedAssaultActivePoint()
        if !IsValid( activePoint ) or !attackTeam or attackTeam == "" or teamName != attackTeam then return nil end
        return activePoint
    end

    local state = self.Assault_State
    if !state then state = self:Assault_Rebuild() end
    if !state or teamName != state.AttackTeam then return nil end
    return state.Points[ state.Index ]
end

function LambdaTeams:GetAssaultDefensePoint( teamName )
    if CLIENT then
        local activePoint, _, defendTeam = LTS_GetNetworkedAssaultActivePoint()
        if !IsValid( activePoint ) or !defendTeam or defendTeam == "" or teamName != defendTeam then return nil end
        return activePoint
    end

    local state = self.Assault_State
    if !state then state = self:Assault_Rebuild() end
    if !state or teamName != state.DefendTeam then return nil end
    return state.Points[ state.Index ]
end

function LambdaTeams:GetAssaultObjectivePoints( teamName )
    if CLIENT then
        local activePoint, attackTeam, defendTeam = LTS_GetNetworkedAssaultActivePoint()
        if !IsValid( activePoint ) then return nil, nil end

        if teamName == attackTeam then
            return activePoint, nil
        elseif teamName == defendTeam then
            return nil, activePoint
        end

        return nil, nil
    end

    local state = self.Assault_State
    if !state then state = self:Assault_Rebuild() end
    if !state then return nil, nil end

    local active = state.Points[ state.Index ]
    if teamName == state.AttackTeam then
        return active, nil
    elseif teamName == state.DefendTeam then
        return nil, active
    end

    return nil, nil
end

local function LTS_SalvageBankFirstCapture()
    return ( salvageBankFirstCapture and salvageBankFirstCapture:GetBool() ) or false
end

local function LTS_SalvageBankInCombat()
    return ( salvageBankInCombat and salvageBankInCombat:GetBool() ) or false
end

local function LTS_SalvageGuardBanks()
    return ( salvageGuardBanks and salvageGuardBanks:GetBool() ) or false
end

function LambdaTeams:TeamHasSalvageBank( teamName )
    if !teamName or teamName == "" then return false end

    for _, bank in ipairs( ents_FindByClass( "lambda_salvage_bank" ) ) do
        if !IsValid( bank ) then continue end
        if !bank:GetIsCaptured() then continue end

        local capTeam = bank.GetCapturerName and bank:GetCapturerName() or ""
        if capTeam == teamName then
            return true
        end
    end

    return false
end

function LambdaTeams:GetBestSalvageCaptureBank( teamName, fromPos )
    if !teamName or teamName == "" then return end

    local bestBank, bestScore = nil, -math.huge

    for _, bank in ipairs( ents_FindByClass( "lambda_salvage_bank" ) ) do
        if !IsValid( bank ) then continue end

        local captured = ( bank.GetIsCaptured and bank:GetIsCaptured() ) or false
        local capTeam = ( bank.GetCapturerName and bank:GetCapturerName() ) or ""
        local score = -fromPos:DistToSqr( bank:GetPos() )

        if !captured or capTeam == "" or capTeam == "Neutral" then
            score = score + 8000000
        elseif capTeam != teamName then
            score = score + 9500000
        else
            score = score - 9000000
        end

        if score > bestScore then
            bestScore = score
            bestBank = bank
        end
    end

    return bestBank
end

local function LTS_SalvageBankRange()
    return ( salvageBankRange and salvageBankRange:GetInt() ) or 200
end

local function LTS_SalvageLoseOnDeath()
    local cv = salvageLoseOnDeath or GetConVar( "lambdaplayers_teamsystem_salvagerun_loseondeath" )
    return ( cv and cv:GetBool() ) or false
end

local function LTS_SabotageAbsorbLosers()
    local cv = sabotageAbsorbLosers or GetConVar( "lambdaplayers_teamsystem_sabotage_absorblosers" )
    return ( cv and cv:GetBool() ) or false
end

local nextConquestDrainT = 0
LambdaTeams.ConquestRemainder = LambdaTeams.ConquestRemainder or {}

function LambdaTeams:ConquestDrainTickets()
    if GetGlobalInt( "LambdaTeamMatch_GameID", 0 ) ~= 1 then return end
    if not GetGlobalBool( "LambdaTeamMatch_IsConquest", false ) then return end

	local baseDrainCvar = GetConVar( "lambdaplayers_teamsystem_conquest_basedrain" )
    local baseDrain = ( baseDrainCvar and baseDrainCvar:GetFloat() or 1.0 )
    if baseDrain <= 0 then return end

    local points = ents.FindByClass( "lambda_koth_point" )
    if not points or #points == 0 then return end

    local ownedCounts = {}
    local total = 0
    local top = 0

    for _, kp in ipairs( points ) do
        if not IsValid( kp ) then continue end
        if not kp:GetIsCaptured() then continue end
        if kp.IsNonTeamCaptured then continue end

        local capTeam = kp:GetCapturerName()
        if not capTeam or capTeam == "" or capTeam == "Neutral" then continue end
        if not LambdaTeams.TeamPoints[ capTeam ] then continue end

        local c = ( ownedCounts[ capTeam ] or 0 ) + 1
        ownedCounts[ capTeam ] = c
        total = total + 1
        if c > top then top = c end
    end

    if total <= 0 or top <= 0 then return end

    for teamName, globalName in pairs( LambdaTeams.TeamPoints ) do
        local tickets = GetGlobalInt( globalName, 0 )
        if tickets <= 0 then
            LambdaTeams.ConquestRemainder[ teamName ] = 0
            continue
        end

        local owned = ownedCounts[ teamName ] or 0
        local diff = top - owned
        if diff <= 0 then
            LambdaTeams.ConquestRemainder[ teamName ] = 0
            continue
        end

        local delta = baseDrain * ( diff / total )
        local accum = ( LambdaTeams.ConquestRemainder[ teamName ] or 0 ) + delta
        local drainInt = math.floor( accum )
        LambdaTeams.ConquestRemainder[ teamName ] = ( accum - drainInt )

        if drainInt > 0 then
            LambdaTeams:AddTeamPoints( teamName, -drainInt )
        end
    end
end

local function HQ_FloatCVar( name, fallback )
    local cv = GetConVar( name )
    return ( cv and cv:GetFloat() or fallback )
end

function LambdaTeams:GetHQObjective()
    local ent = LambdaTeams.HQ_Current
    if IsValid( ent ) then return ent end
end

function LambdaTeams:HQ_SelectNew()
    local points = ents_FindByClass( "lambda_hq_objective" )
    if not points or #points == 0 then return end

    for _, hq in ipairs( points ) do
        if IsValid( hq ) then
            hq:ResetHQ()
        end
    end

    local chosen = points[ random( #points ) ]
    if hqAvoidRepeatLast and hqAvoidRepeatLast:GetBool() and IsValid( LambdaTeams.HQ_Last ) and #points > 1 then
        for _ = 1, 6 do
            if chosen ~= LambdaTeams.HQ_Last then break end
            chosen = points[ random( #points ) ]
        end
    end

    LambdaTeams.HQ_Last = chosen
    LambdaTeams.HQ_Current = chosen

    chosen:ResetHQ()
    chosen:SetArming( true )
    chosen:SetActive( false )

    LambdaTeams.HQ_State = "arming"
	LambdaTeams.HQ_ActivateAt = CurTime() + HQ_FloatCVar( "lambdaplayers_teamsystem_hq_armtime", 30 )
	
	local armTime = HQ_FloatCVar( "lambdaplayers_teamsystem_hq_armtime", 30 )
    local secs = math.max( 0, math.ceil( armTime ) )

    LambdaPlayers_ChatAdd( nil,
        color_white, "[LTS] ", color_glacier,
        "New HQ location selected! Activating in ", color_white, tostring( secs ), color_glacier, " seconds."
    )
    LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_hq_snd_onarming", "all" )

end

function LambdaTeams:GetCurrentGamemodeID()
    return GetGlobalInt( "LambdaTeamMatch_GameID", 0 )
end

local function LTS_SetBoolCompat( ent, key, val )
    if !IsValid( ent ) then return end
    ent:SetNW2Bool( key, val )
    ent:SetNWBool( key, val )
end

local function LTS_SetIntCompat( ent, key, val )
    if !IsValid( ent ) then return end
    ent:SetNW2Int( key, val )
    ent:SetNWInt( key, val )
end

local function LTS_SetStringCompat( ent, key, val )
    if !IsValid( ent ) then return end
    ent:SetNW2String( key, val )
    ent:SetNWString( key, val )
end

local function LTS_GetMatchTeams()
    local teams = {}
    local seen = {}

    for teamName, _ in pairs( LambdaTeams.TeamPoints ) do
        if !teamName or teamName == "" or seen[ teamName ] then continue end

        teams[ #teams + 1 ] = teamName
        seen[ teamName ] = true
    end

    if #teams == 0 then
        for _, ent in ipairs( ents_GetAll() ) do
            local entTeam = LambdaTeams:GetPlayerTeam( ent )
            if !entTeam or entTeam == "" or seen[ entTeam ] then continue end

            teams[ #teams + 1 ] = entTeam
            seen[ entTeam ] = true
        end
    end

    table.sort( teams )
    return teams
end

local function LTS_SetTempFriendly( teamA, teamB, isFriendly )
    if !teamA or !teamB or teamA == "" or teamB == "" or teamA == teamB then return end

    LambdaTeams.AlliedTeams[ teamA ] = LambdaTeams.AlliedTeams[ teamA ] or {}
    LambdaTeams.AlliedTeams[ teamB ] = LambdaTeams.AlliedTeams[ teamB ] or {}

    if isFriendly then
        LambdaTeams.AlliedTeams[ teamA ][ teamB ] = true
        LambdaTeams.AlliedTeams[ teamB ][ teamA ] = true
    else
        LambdaTeams.AlliedTeams[ teamA ][ teamB ] = nil
        LambdaTeams.AlliedTeams[ teamB ][ teamA ] = nil
    end
end

function LambdaTeams:GetSalvageCarry( ent )
    if !IsValid( ent ) then return 0 end
    return math.max( 0, ent.LTS_SalvageCarry or ent:GetNW2Int( "LTS_SalvageCarry", ent:GetNWInt( "LTS_SalvageCarry", 0 ) ) )
end

function LambdaTeams:SetSalvageCarry( ent, amount )
    if !IsValid( ent ) then return 0 end

    amount = math.max( 0, math.floor( amount or 0 ) )
    ent.LTS_SalvageCarry = amount
    LTS_SetIntCompat( ent, "LTS_SalvageCarry", amount )

    return amount
end

function LambdaTeams:AddSalvageCarry( ent, delta )
    return LambdaTeams:SetSalvageCarry( ent, LambdaTeams:GetSalvageCarry( ent ) + ( delta or 0 ) )
end

function LambdaTeams:GetNearestSalvageBank( teamName, fromPos )
    if !teamName or teamName == "" then return end

    local nearest, nearestDist
    for _, bank in ipairs( ents_FindByClass( "lambda_salvage_bank" ) ) do
        if !IsValid( bank ) then continue end
        if !bank:GetIsCaptured() then continue end

        local capTeam = bank.GetCapturerName and bank:GetCapturerName() or nil
        if capTeam != teamName then continue end

        local dist = fromPos:DistToSqr( bank:GetPos() )
        if !nearestDist or dist < nearestDist then
            nearest = bank
            nearestDist = dist
        end
    end

    return nearest
end

function LambdaTeams:TryBankSalvage( ent )
    if !IsValid( ent ) then return false end

    local carry = LambdaTeams:GetSalvageCarry( ent )
    if carry <= 0 then return false end

    if ent.InCombat and ent:InCombat() and !LTS_SalvageBankInCombat() then
        return false
    end

    local teamName = LambdaTeams:GetPlayerTeam( ent )
    if !teamName then return false end

    local bank = LambdaTeams:GetNearestSalvageBank( teamName, ent:GetPos() )
    if !IsValid( bank ) then return false end

    local maxDist = LTS_SalvageBankRange()
    if ent:GetPos():DistToSqr( bank:GetPos() ) > ( maxDist * maxDist ) then return false end

    LambdaTeams:AddTeamPoints( teamName, carry )
    LambdaTeams:SetSalvageCarry( ent, 0 )

    LambdaPlayers_ChatAdd(
        nil,
        color_white, "[LTS] ",
        LambdaTeams:GetTeamColor( teamName, true ), teamName,
        color_glacier, " banked ",
        color_white, tostring( carry ),
        color_glacier, " salvage!"
    )

    return true
end

function LambdaTeams:OnSalvageCollected( collector, victimTeam, tagEnt )
    if !IsValid( collector ) then return false end

    local collectorTeam = LambdaTeams:GetPlayerTeam( collector )
    if !collectorTeam then return false end

    local enemyConfirm = ( victimTeam and victimTeam != "" and victimTeam != collectorTeam )

    if enemyConfirm then
        LambdaTeams:AddSalvageCarry( collector, 1 )
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_kd_snd_confirm", collectorTeam )
    else
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_kd_snd_deny", collectorTeam )
    end

    if SERVER then
        net.Start( "lambda_teamsystem_kd_feedback" )
            net.WriteString( collectorTeam )
            net.WriteBool( enemyConfirm )
        net.Broadcast()
    end

    return enemyConfirm
end

function LambdaTeams:OnSalvageCarrierKilled( victim )
    if !IsValid( victim ) or !LTS_SalvageLoseOnDeath() then return end
    LambdaTeams:SetSalvageCarry( victim, 0 )
end

function LambdaTeams:GetSabotageSite( teamName )
    local state = LambdaTeams.Sabotage_State
    if !state or !state.Sites then return end
    return state.Sites[ teamName ]
end

function LambdaTeams:GetNearestEnemySabotageSite( myTeam, fromPos )
    local state = LambdaTeams.Sabotage_State
    if !state or !state.Sites then return end
    if !myTeam or myTeam == "" then return end

    local allies = LambdaTeams.AlliedTeams[ myTeam ]

    local nearest, nearestDist
    for teamName, site in pairs( state.Sites ) do
        if teamName == myTeam then continue end
        if allies and allies[ teamName ] then continue end
        if !IsValid( site ) then continue end

        local destroyed = site.LTS_SabotageDestroyed or site:GetNW2Bool( "LTS_SAB_Destroyed", site:GetNWBool( "LTS_SAB_Destroyed", false ) )
        if destroyed then continue end

        local dist = fromPos:DistToSqr( site:GetPos() )
        if !nearestDist or dist < nearestDist then
            nearest = site
            nearestDist = dist
        end
    end

    return nearest
end

function LambdaTeams:Sabotage_AssignSites()
    local teams = LTS_GetMatchTeams()
    local sites = ents_FindByClass( "lambda_sabotage_site" )
    if #teams < 2 or #sites < #teams then
        LambdaTeams.Sabotage_State = nil
        return nil
    end

    table.sort( teams )
    table.sort( sites, function( a, b ) return a:EntIndex() < b:EntIndex() end )

    local assigned = {}
    for i, teamName in ipairs( teams ) do
        local site = sites[ i ]
        if !IsValid( site ) then break end

        assigned[ teamName ] = site
        site.LTS_SabotageTeam = teamName
        site.LTS_SabotageDestroyed = false
        site.LTS_SabotageResolved = false
        site.LTS_SabotageDestroyedBy = nil

        if site.ResetSite then
            site:ResetSite( teamName )
        else
            site:SetSiteTeam( teamName )
            site:SetArmingTeam( "" )
            site:SetDestroyedBy( "" )

            if site.SetDefusingTeam then
                site:SetDefusingTeam( "" )
            end

            site:SetIsArmed( false )
            site:SetIsDestroyed( false )
            site:SetArmProgress( 0 )
            site:SetDefuseProgress( 0 )
            site:SetDetonateAt( 0 )

            if site.RemoveBombProp then
                site:RemoveBombProp()
            end

            site:SetColor( Color( 255, 255, 255 ) )

            LTS_SetStringCompat( site, "LTS_SAB_Team", teamName )
            LTS_SetStringCompat( site, "LTS_SAB_DestroyedBy", "" )
            LTS_SetStringCompat( site, "LTS_SAB_DefusingTeam", "" )
            LTS_SetBoolCompat( site, "LTS_SAB_Destroyed", false )
            LTS_SetBoolCompat( site, "LTS_SAB_Armed", false )
        end
    end

    LambdaTeams.Sabotage_State = {
        Teams = teams,
        Sites = assigned,
        TempFriendlies = {}
    }

    LambdaTeams.Sabotage_Sites = assigned
    return LambdaTeams.Sabotage_State
end

function LambdaTeams:IsSabotageTeamAlive( teamName )
    local site = LambdaTeams:GetSabotageSite( teamName )
    if !IsValid( site ) then return false end

    return !( site.LTS_SabotageDestroyed or site:GetNW2Bool( "LTS_SAB_Destroyed", site:GetNWBool( "LTS_SAB_Destroyed", false ) ) )
end

function LambdaTeams:GetSabotageAliveTeams()
    local alive = {}

    for teamName, _ in pairs( LambdaTeams.TeamPoints ) do
        if LambdaTeams:IsSabotageTeamAlive( teamName ) then
            alive[ #alive + 1 ] = teamName
        end
    end

    table.sort( alive )
    return alive
end

local function LTS_SAB_AddTempFriendly( state, teamA, teamB )
    if !teamA or !teamB or teamA == "" or teamB == "" or teamA == teamB then return end

    state.TempFriendlyLookup = state.TempFriendlyLookup or {}
    local keyAB = teamA .. "\0" .. teamB
    local keyBA = teamB .. "\0" .. teamA

    if state.TempFriendlyLookup[ keyAB ] or state.TempFriendlyLookup[ keyBA ] then return end

    LTS_SetTempFriendly( teamA, teamB, true )
    state.TempFriendlies[ #state.TempFriendlies + 1 ] = { teamA, teamB }
    state.TempFriendlyLookup[ keyAB ] = true
    state.TempFriendlyLookup[ keyBA ] = true
end

local function LTS_SAB_GetAllianceMembers( teamName, out, seen )
    out = out or {}
    seen = seen or {}

    if !teamName or teamName == "" or seen[ teamName ] then return out end

    seen[ teamName ] = true
    out[ #out + 1 ] = teamName

    local allies = LambdaTeams.AlliedTeams[ teamName ]
    if allies then
        for allyName, isFriendly in pairs( allies ) do
            if isFriendly then
                LTS_SAB_GetAllianceMembers( allyName, out, seen )
            end
        end
    end

    return out
end

function LambdaTeams:Sabotage_AbsorbTeam( deadTeam, intoTeam )
    if !LTS_SabotageAbsorbLosers() then return end
    if !deadTeam or !intoTeam or deadTeam == intoTeam then return end

    local state = LambdaTeams.Sabotage_State
    if !state then return end

    state.Absorbed = state.Absorbed or {}
    state.TempFriendlies = state.TempFriendlies or {}

    if state.Absorbed[ deadTeam ] then return end

    local deadGroup = LTS_SAB_GetAllianceMembers( deadTeam )
    local intoGroup = LTS_SAB_GetAllianceMembers( intoTeam )

    for _, deadName in ipairs( deadGroup ) do
        state.Absorbed[ deadName ] = intoTeam

        for _, intoName in ipairs( intoGroup ) do
            if deadName != intoName then
                LTS_SAB_AddTempFriendly( state, deadName, intoName )
            end
        end
    end

    LambdaPlayers_ChatAdd(
        nil,
        color_white, "[LTS] ",
        LambdaTeams:GetTeamColor( deadTeam, true ), deadTeam,
        color_glacier, " has joined ",
        LambdaTeams:GetTeamColor( intoTeam, true ), intoTeam,
        color_glacier, "'s alliance!"
    )
end

function LambdaTeams:OnSabotageSiteDestroyed( site, destroyerTeam )
    if !IsValid( site ) or site.LTS_SabotageResolved then return end

    local ownerTeam = site.LTS_SabotageTeam or site:GetNW2String( "LTS_SAB_Team", site:GetNWString( "LTS_SAB_Team", "" ) )
    if ownerTeam == "" then return end

    site.LTS_SabotageResolved = true
    site.LTS_SabotageDestroyed = true
    LTS_SetBoolCompat( site, "LTS_SAB_Destroyed", true )

    if destroyerTeam and destroyerTeam != "" and destroyerTeam != ownerTeam then
        LambdaTeams:AddTeamPoints( destroyerTeam, 1 )
    end

    local aliveTeams = LambdaTeams:GetSabotageAliveTeams()
    local adoptTeam = nil

    if destroyerTeam and destroyerTeam != "" and destroyerTeam != ownerTeam and LambdaTeams:IsSabotageTeamAlive( destroyerTeam ) then
        adoptTeam = destroyerTeam
    else
        for _, teamName in ipairs( aliveTeams ) do
            if teamName != ownerTeam then
                adoptTeam = teamName
                break
            end
        end
    end

    if adoptTeam then
        LambdaTeams:Sabotage_AbsorbTeam( ownerTeam, adoptTeam )
    end
end

function LambdaTeams:HQ_Tick()
    if GetGlobalInt( "LambdaTeamMatch_GameID", 0 ) ~= 5 then return end

    local state = LambdaTeams.HQ_State
    local cur = LambdaTeams:GetHQObjective()

    if state == "cooldown" then
        if CurTime() >= ( LambdaTeams.HQ_NextSelectAt or 0 ) then
            LambdaTeams.HQ_NextSelectAt = nil
            LambdaTeams:HQ_SelectNew()
        end
        return
    end

    if !state or !IsValid( cur ) then
        LambdaTeams:HQ_SelectNew()
        return
    end

    if state == "arming" then
        if CurTime() >= ( LambdaTeams.HQ_ActivateAt or 0 ) then
            if IsValid( cur ) then
                cur:SetArming( false )
                cur:SetActive( true )
                cur.HQ_Destroyed = false
                cur.HQ_DestroyReason = nil
                cur.HQ_DestroyedBy = nil
            end

            LambdaTeams.HQ_State = "active"
            LambdaTeams.HQ_HeldSince = nil
            LambdaTeams.HQ_NextScoreAt = nil

            LambdaPlayers_ChatAdd(
                nil,
                color_white, "[LTS] ", color_glacier,
                "HQ is now ", color_white, "ACTIVE", color_glacier, "!"
            )
            LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_hq_snd_onactive", "all" )
        end
        return
    end

    if state == "active" then
        if IsValid( cur ) and cur:GetIsCaptured() then
            local captTeam = cur.GetCapturerName and cur:GetCapturerName() or nil
            if !captTeam or captTeam == "" then captTeam = "Unknown" end

            local captClr = LambdaTeams:GetTeamColor( captTeam, true ) or color_glacier

            LambdaPlayers_ChatAdd(
                nil,
                color_white, "[LTS] ", color_glacier,
                "HQ secured by ", captClr, captTeam, color_white, "!"
            )

            for teamName, _ in pairs( LambdaTeams.TeamPoints ) do
                if teamName == captTeam then
                    LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_hq_snd_onsecure_ally", teamName )
                else
                    LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_hq_snd_onsecure_enemy", teamName )
                end
            end

            LambdaTeams.HQ_State = "held"
            LambdaTeams.HQ_HeldSince = CurTime()
            LambdaTeams.HQ_NextScoreAt = CurTime() + HQ_FloatCVar( "lambdaplayers_teamsystem_hq_scoregaintime", 5 )
        end
        return
    end

    if state == "held" then
        if !IsValid( cur ) then
            LambdaTeams.HQ_State = nil
            LambdaTeams.HQ_HeldSince = nil
            LambdaTeams.HQ_NextScoreAt = nil
            return
        end

        local heldSince = LambdaTeams.HQ_HeldSince or CurTime()
        local holdLimit = HQ_FloatCVar( "lambdaplayers_teamsystem_hq_holdlimit", 60 )

        if holdLimit > 0 and ( CurTime() - heldSince ) >= holdLimit then
            if cur.ForceDestroyHQ then
                cur:ForceDestroyHQ()
            else
                cur.HQ_Destroyed = true
                cur.HQ_DestroyReason = "timeout"
            end
        end

        if cur.HQ_Destroyed then
            local reason = cur.HQ_DestroyReason
            local delay = 0

            if reason == "captured" then
                local destroyedBy = cur.HQ_DestroyedBy
                if !destroyedBy or destroyedBy == "" then destroyedBy = "Unknown" end

                local dClr = LambdaTeams:GetTeamColor( destroyedBy, true ) or color_glacier

                LambdaPlayers_ChatAdd(
                    nil,
                    color_white, "[LTS] ", color_glacier,
                    "HQ destroyed by ", dClr, destroyedBy, color_white, "!"
                )

                for teamName, _ in pairs( LambdaTeams.TeamPoints ) do
                    if teamName == destroyedBy then
                        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_hq_snd_ondestroy_ally", teamName )
                    else
                        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_hq_snd_ondestroy_enemy", teamName )
                    end
                end

                delay = HQ_FloatCVar( "lambdaplayers_teamsystem_hq_destroyed_delay", 15 )
            else
                LambdaPlayers_ChatAdd(
                    nil,
                    color_white, "[LTS] ", color_glacier,
                    "The HQ has been destroyed!"
                )
                LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_hq_snd_ondestroy_enemy", "all" )
                delay = HQ_FloatCVar( "lambdaplayers_teamsystem_hq_destroyed_delay", 15 )
            end

            if IsValid( cur ) then
                cur:SetArming( false )
                cur:SetActive( false )
            end

            LambdaTeams.HQ_State = "cooldown"
            LambdaTeams.HQ_HeldSince = nil
            LambdaTeams.HQ_NextScoreAt = nil
            LambdaTeams.HQ_NextSelectAt = CurTime() + delay
            return
        end

        if cur:GetIsCaptured() then
            local captTeam = cur.GetCapturerName and cur:GetCapturerName() or nil
            if captTeam and captTeam != "" and CurTime() >= ( LambdaTeams.HQ_NextScoreAt or 0 ) then
                LambdaTeams:AddTeamPoints(
                    captTeam,
                    math.max( 1, math.floor( HQ_FloatCVar( "lambdaplayers_teamsystem_hq_scoregainamount", 5 ) ) )
                )

                LambdaTeams.HQ_NextScoreAt = CurTime() + HQ_FloatCVar( "lambdaplayers_teamsystem_hq_scoregaintime", 5 )
            end
        end

        return
    end
end

function LambdaTeams:Assault_Tick()
    local state = self.Assault_State
    if !state then state = self:Assault_Rebuild() end
    if !state then return end

    local activeTeams = LTS_GetMatchTeams()
    local activeSet = {}
    for _, t in ipairs( activeTeams ) do
        activeSet[ t ] = true
    end

    if LTS_AssaultNeedsTwoTeams() and #activeTeams != 2 then
        LambdaPlayers_ChatAdd(
            nil,
            color_white, "[LTS] ",
            color_glacier, "Assault stopped because it no longer has exactly 2 teams."
        )
        StopGameMatch()
        return
    end

    if !activeSet[ state.AttackTeam ] or !activeSet[ state.DefendTeam ] then
        LambdaPlayers_ChatAdd(
            nil,
            color_white, "[LTS] ",
            color_glacier, "Assault stopped because a participating team is no longer active."
        )
        StopGameMatch()
        return
    end

    local curPoint = state.Points[ state.Index ]
    if !IsValid( curPoint ) then
        self:Assault_Rebuild()
        return
    end

    if self.Assault_CurrentPoint != curPoint then
        self.Assault_CurrentPoint = curPoint

        for _, pt in ipairs( state.Points ) do
            LTS_SetBoolCompat( pt, "LTS_AssaultActive", pt == curPoint )
        end
    end

    if !curPoint:GetIsCaptured() then
        state.LastCapturer = nil
        return
    end

    local captTeam = ( curPoint.GetCapturerName and curPoint:GetCapturerName() ) or ""
    if captTeam != state.AttackTeam then
        state.LastCapturer = nil
        return
    end

    if captTeam == state.LastCapturer then return end

    state.LastCapturer = captTeam
    self:AddTeamPoints( captTeam, 1 )

    state.Index = state.Index + 1
    if state.Index > #state.Points then
        matchWinReason = "assault_fullcap"
        matchWinTeam = state.AttackTeam

        local curPoints = self:GetTeamPoints( state.AttackTeam )
        local pointLimit = math.max( #state.Points, curPoints, 1 )
        SetGlobalInt( "LambdaTeamMatch_PointLimit", pointLimit )
        return
    end

    self.Assault_CurrentPoint = state.Points[ state.Index ]
    state.LastCapturer = nil

    for _, pt in ipairs( state.Points ) do
        LTS_SetBoolCompat( pt, "LTS_AssaultActive", pt == self.Assault_CurrentPoint )
    end
end

function LambdaTeams:SalvageRun_Tick()
    for _, ent in ipairs( table_Add( GetLambdaPlayers(), player_GetAll() ) ) do
        if !IsValid( ent ) then continue end
        if !LambdaTeams:GetPlayerTeam( ent ) then continue end

        LambdaTeams:TryBankSalvage( ent )
    end
end

function LambdaTeams:Sabotage_Tick()
    local state = LambdaTeams.Sabotage_State
    if !state then state = LambdaTeams:Sabotage_AssignSites() end
    if !state then return end

    for teamName, site in pairs( state.Sites ) do
        if !IsValid( site ) then continue end

        local destroyed = site.LTS_SabotageDestroyed or site:GetNW2Bool( "LTS_SAB_Destroyed", site:GetNWBool( "LTS_SAB_Destroyed", false ) )
        if !destroyed or site.LTS_SabotageResolved then continue end

        local destroyer = site.LTS_SabotageDestroyedBy or site:GetNW2String( "LTS_SAB_DestroyedBy", site:GetNWString( "LTS_SAB_DestroyedBy", "" ) )
        LambdaTeams:OnSabotageSiteDestroyed( site, destroyer )
    end

    local aliveTeams = LambdaTeams:GetSabotageAliveTeams()
    if #aliveTeams <= 1 then
		local winner = aliveTeams[ 1 ]
		if !winner then return end

		matchWinReason = "sabotage_lastsite"
		matchWinTeam = winner

		local curPoints = LambdaTeams:GetTeamPoints( winner )
		local pointLimit = GetGlobalInt( "LambdaTeamMatch_PointLimit", 0 )
		local winAt = math.max( pointLimit, curPoints + 1, 1 )

		SetGlobalInt( "LambdaTeamMatch_PointLimit", winAt )
		LambdaTeams:AddTeamPoints( winner, winAt - curPoints )
	end
end

local function StopGameMatch()
    SetGlobalInt( "LambdaTeamMatch_GameID", 0 )
    timer_Remove( "LambdaTeamMatch_ThinkTimer" )

    LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_gamestart" )
    LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match60left" )
    LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match30left" )
    LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match10left" )

    local stopSnds = LambdaTeams.SoundsToStop
    if stopSnds then
        for _, sndCvar in ipairs( stopSnds ) do
            net.Start( "lambda_teamsystem_stopclientsound" )
                net.WriteString( sndCvar )
            net.Broadcast()
        end
    end
	
    for _, hq in ipairs( ents_FindByClass( "lambda_hq_objective" ) ) do
        if IsValid( hq ) then
            hq:ResetHQ()
        end
    end

    LambdaTeams.HQ_State = nil
    LambdaTeams.HQ_Current = nil
    LambdaTeams.HQ_ActivateAt = nil
    LambdaTeams.HQ_HeldSince = nil
    LambdaTeams.HQ_NextSelectAt = nil

    for _, kp in ipairs( ents_FindByClass( "lambda_koth_point" ) ) do
        if !kp:GetIsCaptured() then continue end
        kp:BecomeNeutral()
    end

	for _, bank in ipairs( ents_FindByClass( "lambda_salvage_bank" ) ) do
		if !IsValid( bank ) or !bank:GetIsCaptured() then continue end
		bank:BecomeNeutral()
	end

    for _, ent in ipairs( table_Add( GetLambdaPlayers(), player_GetAll() ) ) do
        if IsValid( ent ) then
            LambdaTeams:SetSalvageCarry( ent, 0 )
        end
    end

	for _, site in ipairs( ents_FindByClass( "lambda_sabotage_site" ) ) do
    if !IsValid( site ) then continue end

    local teamName = site.LTS_SabotageTeam
        or site:GetNW2String( "LTS_SAB_Team", site:GetNWString( "LTS_SAB_Team", site:GetSiteTeam() ) )

    if site.ResetSite then
        site:ResetSite( teamName or "" )
    else
        site:SetSiteTeam( teamName or "" )
        site:SetArmingTeam( "" )
        site:SetDestroyedBy( "" )

        if site.SetDefusingTeam then
            site:SetDefusingTeam( "" )
        end

        site:SetIsArmed( false )
        site:SetIsDestroyed( false )
        site:SetArmProgress( 0 )
        site:SetDefuseProgress( 0 )
        site:SetDetonateAt( 0 )

        if site.RemoveBombProp then
            site:RemoveBombProp()
        end

        site:SetColor( Color( 255, 255, 255 ) )

        LTS_SetStringCompat( site, "LTS_SAB_Team", teamName or "" )
        LTS_SetStringCompat( site, "LTS_SAB_DestroyedBy", "" )
        LTS_SetStringCompat( site, "LTS_SAB_DefusingTeam", "" )
        LTS_SetBoolCompat( site, "LTS_SAB_Destroyed", false )
        LTS_SetBoolCompat( site, "LTS_SAB_Armed", false )
    end
end

    if LambdaTeams.Sabotage_State and LambdaTeams.Sabotage_State.TempFriendlies then
        for _, pair in ipairs( LambdaTeams.Sabotage_State.TempFriendlies ) do
            LTS_SetTempFriendly( pair[ 1 ], pair[ 2 ], false )
        end
    end
	
	LTS_ClearAssaultFlags()

	LambdaTeams.Assault_State = nil
	LambdaTeams.Assault_CurrentPoint = nil
	LambdaTeams.Assault_Points = nil

    LambdaTeams.Salvage_State = nil
    LambdaTeams.Salvage_Banks = nil

    LambdaTeams.Sabotage_State = nil
    LambdaTeams.Sabotage_Sites = nil
	
	matchWinReason = nil
	matchWinTeam = nil

end

local function GameMatchThinkTimer()
    if !TeamSystemEnabled() then
		StopGameMatch()
		return
	end

    local gameID = GetGlobalInt( "LambdaTeamMatch_GameID", 0 )
    local isConquest = ( gameID == 1 and GetGlobalBool( "LambdaTeamMatch_IsConquest", false ) )

    if not isConquest then
        local pointLimit = GetGlobalInt( "LambdaTeamMatch_PointLimit" )
        if pointLimit != 0 then
            for teamName, globalName in pairs( LambdaTeams.TeamPoints ) do
                local teamPoints = GetGlobalInt( globalName, 0 )
                if teamPoints < pointLimit then continue end

                GetTheMatchStats()
                StopGameMatch()
                return
            end
        end
    else
        local drainInterval = 5
        local cv = GetConVar( "lambdaplayers_teamsystem_koth_scoregaintime" )
        if cv then drainInterval = cv:GetFloat() end

        if CurTime() >= ( nextConquestDrainT or 0 ) then
            LambdaTeams:ConquestDrainTickets()
            nextConquestDrainT = CurTime() + drainInterval
        end

        local aliveTeams = 0
        for _, globalName in pairs( LambdaTeams.TeamPoints ) do
            if GetGlobalInt( globalName, 0 ) > 0 then
                aliveTeams = aliveTeams + 1
            end
        end

        if aliveTeams <= 1 then
            LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", color_glacier, "A team has run out of tickets!" )
            GetTheMatchStats()
            StopGameMatch()
            return
        end
    end

	if gameID == 5 then
		LambdaTeams:HQ_Tick()
	elseif gameID == 6 then
		LambdaTeams:Assault_Tick()
	elseif gameID == 7 then
		LambdaTeams:SalvageRun_Tick()
	elseif gameID == 8 then
		LambdaTeams:Sabotage_Tick()
	end

	local timeRemain = GetGlobalInt( "LambdaTeamMatch_TimeRemaining", 0 )
	if timeRemain != -1 and CurTime() >= nextTimerProgressT then
		if timeRemain == 0 then
			if gameID == 6 and LambdaTeams.Assault_State then
				matchWinReason = "assault_timeout"
				matchWinTeam = LambdaTeams.Assault_State.DefendTeam

				local pointLimit = math.max( 1, GetGlobalInt( "LambdaTeamMatch_PointLimit", 1 ) )
				local curPoints = LambdaTeams:GetTeamPoints( matchWinTeam )
				if curPoints < pointLimit then
					LambdaTeams:AddTeamPoints( matchWinTeam, pointLimit - curPoints )
				end
			end

			LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", color_glacier, "Reached the time limit of the match!" )
			GetTheMatchStats()
			StopGameMatch()
			return
		end

		nextTimerProgressT = CurTime() + 1
		timeRemain = timeRemain - 1
		SetGlobalInt( "LambdaTeamMatch_TimeRemaining", timeRemain )

        if timeRemain == 60 then
            LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match60left", "all" )
        elseif timeRemain == 30 then
            LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match60left" )
            LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match30left", "all" )
        elseif timeRemain == 10 then
            LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match30left" )
            LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match10left", "all" )
        end
		end
	end

local function StartGamemode( ply, gameIndex, stopSnds )
    if not ply:IsSuperAdmin() then
        LambdaPlayers_Notify( ply, "You must be a Super Admin in order to start a match!", 1, "buttons/button10.wav" )
        return
    end

    local curIndex = GetGlobalInt( "LambdaTeamMatch_GameID", 0 )
    if curIndex ~= 0 then
        LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", color_glacier, "Player ", team_GetColor( ply:Team() ), ply:Nick(), color_glacier, " ended the match prematurely!" )
        GetTheMatchStats( true )
        StopGameMatch()
        return
    end

    if not TeamSystemEnabled() then
        LambdaPlayers_Notify( ply, "You must have Team System enabled!", 1, "buttons/button10.wav" )
        return
    end

    if gameIndex == 1 and #ents_FindByClass( "lambda_koth_point" ) == 0 then
        LambdaPlayers_Notify( ply, "You must have atleast one Point exist in order to start!", 1, "buttons/button10.wav" )
        return
    elseif gameIndex == 2 and #ents_FindByClass( "lambda_ctf_flag" ) <= 1 then
        LambdaPlayers_Notify( ply, "You must have atleast two CTF Flags exist for each team in order to start!", 1, "buttons/button10.wav" )
        return
    elseif gameIndex == 5 and #ents_FindByClass( "lambda_hq_objective" ) == 0 then
        LambdaPlayers_Notify( ply, "You must have atleast one HQ Objective placed to start!", 1, "buttons/button10.wav" )
        return
	elseif gameIndex == 6 then
		local assaultPoints = LTS_GetAssaultPoints()
		if #assaultPoints == 0 then
			LambdaPlayers_Notify( ply, "The assault gamemode requires at least one Assault point!", 1, "buttons/button10.wav" )
			return
		end
	elseif gameIndex == 7 and #ents_FindByClass( "lambda_salvage_bank" ) == 0 then
		LambdaPlayers_Notify( ply, "The salvage run gamemode requires at least one Salvage Run bank!", 1, "buttons/button10.wav" )
		return
    elseif gameIndex == 8 and #ents_FindByClass( "lambda_sabotage_site" ) < 2 then
        LambdaPlayers_Notify( ply, "The sabotage gamemode requires at least two sabotage sites!", 1, "buttons/button10.wav" )
        return
    end

	matchWinReason = nil
	matchWinTeam = nil

    LambdaTeams.SoundsToStop = stopSnds

    local isConquest = ( gameIndex == 1 and adConquestMode and adConquestMode:GetBool() )
    SetGlobalBool( "LambdaTeamMatch_IsConquest", isConquest )

    SetGlobalInt( "LambdaTeamMatch_GameID", gameIndex )
	SetGlobalInt( "LambdaTeamMatch_PointLimit", ( isConquest or gameIndex == 6 ) and 0 or gmPointsLimit:GetInt() )

    local ticketsStart = gmPointsLimit:GetInt()
    if ticketsStart <= 0 then ticketsStart = 200 end
    SetGlobalInt( "LambdaTeamMatch_ConquestTicketCap", ticketsStart )

    for _, globalName in pairs( LambdaTeams.TeamPoints ) do
        SetGlobalInt( globalName, 0 )
    end
    table.Empty( LambdaTeams.TeamPoints )

    local curTeams = {}
    for _, p in ipairs( table_Add( GetLambdaPlayers(), player_GetAll() ) ) do
        local pTeam = LambdaTeams:GetPlayerTeam( p )
        if not pTeam then continue end

        if not LambdaTeams.TeamPoints[ pTeam ] then
            LambdaTeams.TeamPoints[ pTeam ] = "LambdaTeamMatch_TeamPoints_" .. pTeam
            curTeams[ pTeam ] = {}
        end
        curTeams[ pTeam ][ #curTeams[ pTeam ] + 1 ] = p
    end

    pointsName = "point"
    if gameIndex == 1 then
        gamemodeName = "Attack/Defend"
        if isConquest then pointsName = "tickets" end
    elseif gameIndex == 2 then
        gamemodeName = "Capture The Flag"
        pointsName = "flag captured"
    elseif gameIndex == 3 then
        gamemodeName = "Team Deathmatch"
        pointsName = "kills"
    elseif gameIndex == 4 then
        gamemodeName = "Kill Confirmed"
        pointsName = "kill confirm"
    elseif gameIndex == 5 then
        gamemodeName = "Headquarters"
        pointsName = "HQ points"
	elseif gameIndex == 6 then
		gamemodeName = "Assault"
		pointsName = "sectors captured"
    elseif gameIndex == 7 then
        gamemodeName = "Salvage Run"
        pointsName = "salvage delivered"
    elseif gameIndex == 8 then
        gamemodeName = "Sabotage"
        pointsName = "sites destroyed"
    end

    local timeLimit = gmMatchTime:GetInt()
    if timeLimit ~= 0 then
        nextTimerProgressT = ( CurTime() + 1 )
        SetGlobalInt( "LambdaTeamMatch_TimeRemaining", ( timeLimit * 60 ) )
    else
        SetGlobalInt( "LambdaTeamMatch_TimeRemaining", -1 )
    end

    LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_gamestart", "all" )

	if gameIndex == 6 then
		if !LTS_AssaultStartOwned() then
			for _, ap in ipairs( LTS_GetAssaultPoints() ) do
				if IsValid( ap ) and ap:GetIsCaptured() then
					ap:BecomeNeutral()
				end
			end
		end
	elseif gameIndex == 7 then
		for _, bank in ipairs( ents_FindByClass( "lambda_salvage_bank" ) ) do
			if IsValid( bank ) and bank:GetIsCaptured() then
				bank:BecomeNeutral()
			end
		end
	else
		for _, kp in ipairs( ents_FindByClass( "lambda_koth_point" ) ) do
			if IsValid( kp ) and kp:GetIsCaptured() then
				kp:BecomeNeutral()
			end
		end
	end
	
    if gameIndex == 5 then
        LambdaTeams.HQ_State = nil
        LambdaTeams.HQ_Current = nil
        LambdaTeams.HQ_ActivateAt = nil
        LambdaTeams.HQ_HeldSince = nil
        LambdaTeams.HQ_NextSelectAt = nil
        LambdaTeams:HQ_SelectNew()
	elseif gameIndex == 6 then
        LambdaTeams.Assault_State = nil
        LambdaTeams.Assault_CurrentPoint = nil
        LambdaTeams.Assault_Points = nil
    elseif gameIndex == 7 then
        LambdaTeams.Salvage_State = nil
        LambdaTeams.Salvage_Banks = nil
    elseif gameIndex == 8 then
        LambdaTeams.Sabotage_State = nil
        LambdaTeams.Sabotage_Sites = nil
    end
	
	local activeTeamCount = table_Count( curTeams )
    local minTeams = math.max( 1, gmMinTeams:GetInt() )

    if activeTeamCount < minTeams then
        SetGlobalInt( "LambdaTeamMatch_GameID", 0 )
        SetGlobalInt( "LambdaTeamMatch_PointLimit", 0 )
        SetGlobalInt( "LambdaTeamMatch_ConquestTicketCap", 0 )
        SetGlobalBool( "LambdaTeamMatch_IsConquest", false )
        table_Empty( LambdaTeams.TeamPoints )

        LambdaPlayers_Notify( ply, "You need at least " .. minTeams .. " active teams to start this match!", 1, "buttons/button10.wav" )
        return
    end

	if gameIndex == 6 then
		LambdaTeams:Assault_Rebuild()

		timer.Simple( 0, function()
			if GetGlobalInt( "LambdaTeamMatch_GameID", 0 ) != 6 then return end
			if !LambdaTeams or !LambdaTeams.Assault_Rebuild then return end

			LambdaTeams:Assault_Rebuild()
		end )

		local attackTeam = LambdaTeams:GetAssaultAttackTeam()
		local defendTeam = LambdaTeams:GetAssaultDefendTeam()

		if !attackTeam or !defendTeam or attackTeam == defendTeam then
			SetGlobalInt( "LambdaTeamMatch_GameID", 0 )
			SetGlobalInt( "LambdaTeamMatch_PointLimit", 0 )
			SetGlobalInt( "LambdaTeamMatch_ConquestTicketCap", 0 )
			SetGlobalBool( "LambdaTeamMatch_IsConquest", false )
			table_Empty( LambdaTeams.TeamPoints )

			LambdaPlayers_Notify( ply, "Assault requires different attacking and defending teams to be selected!", 1, "buttons/button10.wav" )
			return
		end

		if LTS_AssaultNeedsTwoTeams() and activeTeamCount != 2 then
			SetGlobalInt( "LambdaTeamMatch_GameID", 0 )
			SetGlobalInt( "LambdaTeamMatch_PointLimit", 0 )
			SetGlobalInt( "LambdaTeamMatch_ConquestTicketCap", 0 )
			SetGlobalBool( "LambdaTeamMatch_IsConquest", false )
			table_Empty( LambdaTeams.TeamPoints )

			LambdaPlayers_Notify( ply, "Assault requires exactly 2 active teams!", 1, "buttons/button10.wav" )
			return
		end

		if !curTeams[ attackTeam ] or !curTeams[ defendTeam ] then
			SetGlobalInt( "LambdaTeamMatch_GameID", 0 )
			SetGlobalInt( "LambdaTeamMatch_PointLimit", 0 )
			SetGlobalInt( "LambdaTeamMatch_ConquestTicketCap", 0 )
			SetGlobalBool( "LambdaTeamMatch_IsConquest", false )
			table_Empty( LambdaTeams.TeamPoints )

			LambdaPlayers_Notify( ply, "The selected attacking and defending teams must be present in the match!", 1, "buttons/button10.wav" )
			return
		end

		SetGlobalInt( "LambdaTeamMatch_PointLimit", math.max( 1, #LTS_GetAssaultPoints() ) )
	end
	
    if gameIndex == 8 then
        local sabotageSites = ents_FindByClass( "lambda_sabotage_site" )
        if #sabotageSites < activeTeamCount then
            SetGlobalInt( "LambdaTeamMatch_GameID", 0 )
            SetGlobalInt( "LambdaTeamMatch_PointLimit", 0 )
            SetGlobalInt( "LambdaTeamMatch_ConquestTicketCap", 0 )
            SetGlobalBool( "LambdaTeamMatch_IsConquest", false )
            table_Empty( LambdaTeams.TeamPoints )

            LambdaPlayers_Notify( ply, "Sabotage needs at least one site per active team!", 1, "buttons/button10.wav" )
            return
        end
    end

    timer.Remove( "LambdaTeamMatch_ThinkTimer" )
    timer_Create( "LambdaTeamMatch_ThinkTimer", 0.1, 0, GameMatchThinkTimer )
end
---

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_koth_startmatch", function( ply )
    StartGamemode( ply, 1 )
end, false, "Start a match of the KOTH/AD gamemode", { name = "Start KOTH/AD Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_ctf_startmatch", function( ply )
    StartGamemode( ply, 2 )
end, false, "Start a match of the Capture The Flag gamemode", { name = "Start CTF Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_tdm_startmatch", function( ply )
    StartGamemode( ply, 3, { "lambdaplayers_teamsystem_tdm_snd_10killsleft" } )
end, false, "Start a match of the Team Deathmatch gamemode", { name = "Start TDM Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_kd_startmatch", function( ply )
    StartGamemode( ply, 4 )
end, false, "Start a match of the Kill Confirmed gamemode", { name = "Start KD Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_hq_startmatch", function( ply )
    StartGamemode( ply, 5 )
end, false, "Start a match of the Headquarters gamemode", { name = "Start HQ Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_assault_startmatch", function( ply )
    StartGamemode( ply, 6 )
end, false, "Start a match of the Assault gamemode", { name = "Start Assault Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_salvagerun_startmatch", function( ply )
    StartGamemode( ply, 7 )
end, false, "Start a match of the Salvage Run gamemode", { name = "Start Salvage Run Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_sabotage_startmatch", function( ply )
    StartGamemode( ply, 8 )
end, false, "Start a match of the Sabotage gamemode", { name = "Start Sabotage Match", category = "Team System - Gamemodes" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_koth_capturerate", 0.2, true, false, false, "The speed rate of capturing the KOTH Points.", 0.01, 5.0, { name = "Capture Rate", type = "Slider", decimals = 2, category = "Team System - KOTH/AD" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_scoregaintime", 5, true, false, false, "How much time should pass before the KOTH Point gives point to its team.", 0.1, 60, { name = "Score Gain Time", type = "Slider", decimals = 1, category = "Team System - KOTH/AD" } )
local kothCapRange = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_capturerange", 500, true, false, false, "How close player should be to start capturing the point.", 100, 1000, { name = "Capture Range", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )

local kothIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_enabled", 1, true, true, false, "If your team's captured KOTH point should have a icon drawn on them.", 0, 1, { name = "Enable Icons", type = "Bool", category = "Team System - KOTH/AD" } )
local kothIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_alwaysdraw", 0, true, true, false, "If the icon should always be drawn no matter if it's visible.", 0, 1, { name = "Always Draw Icon", type = "Bool", category = "Team System - KOTH/AD" } )
local kothIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_fadeinstartdist", 2000, true, true, false, "How far you should be from the icon for it to completely fade out of view.", 0, 4096, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )
local kothIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_fadeinenddist", 500, true, true, false, "How close you should be from the icon for it to become fully visible.", 0, 4096, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )

adConquestMode = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_conquest", 0, true, false, false, "If enabled, KOTH/AD uses conquest rules (ticket drain instead of score rising).", 0, 1, { name = "Enable Conquest Rules", type = "Bool", category = "Team System - KOTH/AD" } )
conquestBaseDrain = CreateLambdaConvar( "lambdaplayers_teamsystem_conquest_basedrain", 1, true, false, false, "Base tickets drained (per tick), scaled by control-point advantage (Conquest only).", 1, 50, { name = "Base Drain Per Tick", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )
conquestKillDrain = CreateLambdaConvar( "lambdaplayers_teamsystem_conquest_killdrain", 1, true, false, false, "Tickets drained from the victim's team per kill (Conquest only).", 0, 50, { name = "Drain On Kill", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )

local adRole_DefendWeight = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_role_defend", 35, true, false, false, "How persistent should defenders be.", 0, 100, { name = "Defender Persistence", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )
local adRole_AttackWeight = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_role_attack", 55, true, false, false, "How persistent should attackers be.", 0, 100, { name = "Attacker Persistence", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )
local adRole_RoamWeight = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_role_roam", 10, true, false, false, "How persistent should PVPing players be (higher values will cause matches to last longer).", 0, 100, { name = "Roaming Persistence", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )
local adBotObjective = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_botobjective", 1, true, false, false, "If Lambda Players should actively seek AD/KOTH points (I recommend this to stop matches from being ridiculously long).", 0, 1, { name = "Lambdas Play Objectives", type = "Bool", category = "Team System - KOTH/AD" } )
local adBotObjectiveRange = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_botobjective_range", 6000, true, false, false, "Max distance Lambdas Players will go to reach objectives.", 0, 10000, { name = "Objective Detection Range", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )
local adBotObjectiveInCombat = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_botobjective_incombat", 0, true, false, false, "If Lambda Players should prioritize objectives while in combat.", 0, 1, { name = "Seek Objectives In Combat", type = "Bool", category = "Team System - KOTH/AD" } )
local adBotStackPenalty = CreateLambdaConvar( "lambdaplayers_teamsystem_ad_botobjective_stackpenalty", 250000, true, false, false, "Penalty per other Lambda already going after an objective (reduces several from going after a single objective).", 0, 1000000, { name = "Stacking Penalty", type = "Slider", decimals = 0, category = "Team System - KOTH/AD" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointcaptured", "lambdaplayers/koth/captured.mp3", true, true, false, "The sound that plays when your team has successfully captured a KOTH point.", 0, 1, { name = "Sound - On Point Capture", type = "Text", category = "Team System - KOTH/AD" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointneutered", "lambdaplayers/koth/holdlost.mp3", true, true, false, "The sound that plays when a KOTH point has become neutral.", 0, 1, { name = "Sound - On Point Neutral", type = "Text", category = "Team System - KOTH/AD" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointrestored", "lambdaplayers/koth/holdrestored.mp3", true, true, false, "The sound that plays when your team's KOTH point is reclaimed back from neutral.", 0, 1, { name = "Sound - On Point Reclaim", type = "Text", category = "Team System - KOTH/AD" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointlost", "lambdaplayers/koth/loss.mp3", true, true, false, "The sound that plays when your team's KOTH point is lost.", 0, 1, { name = "Sound - On Point Lost", type = "Text", category = "Team System - KOTH/AD" } )

--

CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_returntime", 15, true, false, false, "The time Lambda Flag can be in dropped state before returning to its capture zone.", 0, 120, { name = "Time Before Returning", type = "Slider", decimals = 0, category = "Team System - CTF" } )

local ctfBotObjective = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_botobjective", 1, true, false, false, "If Lambda Players should actively play the Objective.", 0, 1, { name = "Lambdas Play Objective", type = "Bool", category = "Team System - CTF" } )
local ctfBotObjectiveInCombat = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_botobjective_incombat", 0, true, false, false,  "If Lambdas Players should seek out flags during combat.", 0, 1, { name = "Seek Objective In Combat", type = "Bool", category = "Team System - CTF" } )
local ctfMinDefenders = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_min_defenders", 1, true, false, false, "How many (at least) Lambda Players per team that will prefer defending over attacking when their flag is at home.", 0, 16, { name = "Defender Count", type = "Slider", decimals = 0, category = "Team System - CTF" } )

local ctfRole_DefendWeight = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_role_defend", 35, true, false, false, "How persistent should flag defenders be.", 0, 100, { name = "Defender Commitment", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfRole_AttackWeight = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_role_attack", 45, true, false, false, "How persistent should attackers be.", 0, 100, { name = "Attacker Commitment", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfRole_EscortWeight = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_role_escort", 10, true, false, false, "How persistent should flag escorters be.", 0, 100, { name = "Escort Commitment", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfRole_HuntWeight = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_role_hunt", 10, true, false, false, "How persistent should player hunters be.", 0, 100, { name = "Hunter Commitment", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfBotObjectiveRange = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_botobjective_range", 9000, true, false, false, "Max distance Lambdas will seek out flags.", 0, 10000, { name = "Objective Consider Range", type = "Slider", decimals = 0, category = "Team System - CTF" } )

local ctfDefendBoostWhenFlagTaken = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_defend_boost_taken", 35, true, false, false, "How vigilant (aggressive) should flag defenders be when the flag is not at home (higher values can cause the gamemode to be very difficult).", 0, 200, { name = "Defense Aggro When Flag Taken", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_alwaysdraw", 0, true, true, false, "If the icon should always be drawn no matter if it's visible.", 0, 1, { name = "Always Draw Icon", type = "Bool", category = "Team System - CTF" } )
local ctfIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_enabled", 1, true, true, false, "If your team's dropped flag or enemy flag carried by your teammate should have a icon drawn on them.", 0, 1, { name = "Enable Icons", type = "Bool", category = "Team System - CTF" } )

local ctfIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_fadeinstartdist", 2000, true, true, false, "How far you should be from the icon for it to completely fade out of view.", 0, 4096, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_fadeinenddist", 500, true, true, false, "How close you should be from the icon for it to become fully visible.", 0, 4096, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_enemy", "lambdaplayers/ctf/flagsteal.mp3", true, true, false, "The sound that plays when your team picks up enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_ally", "lambdaplayers/ctf/ourflagstole.mp3", true, true, false, "The sound that plays when enemy team picks up your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_ally", "lambdaplayers/ctf/flagcapture.mp3", true, true, false, "The sound that plays when your team has captured enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_enemy", "lambdaplayers/ctf/ourflagcaptured.mp3", true, true, false, "The sound that plays when enemy team has captured your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_ondrop", "lambdaplayers/ctf/flagdropped.mp3", true, true, false, "The sound that plays when the CTF Flag is dropped.", 0, 1, { name = "Sound - On Flag Drop", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onreturn", "lambdaplayers/ctf/flagreturn.mp3", true, true, false, "The sound that plays when the CTF Flag has returned to its base.", 0, 1, { name = "Sound - On Flag Return", type = "Text", category = "Team System - CTF" } )

---

CreateLambdaConvar( "lambdaplayers_teamsystem_tdm_snd_10killsleft", "lambdaplayers/tdm/10killsleft.mp3", true, true, false, "The sound that plays when there are only 10 kills left to win.", 0, 1, { name = "Sound - 10 Kills Left", type = "Text", category = "Team System - TDM" } )

---

local kdPickupEnableDelay = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_pickupenable_delay", 0.25, true, false, false, "Delay before newly dropped KD tags can be collected.", 0.0, 3.0, { name = "Pickup Enable Delay", type = "Slider", decimals = 2, category = "Team System - KD" } )
local kdRemoveTime = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_removetime", 20, true, false, false, "For how much time the pickups can be dropped before they disappear?", 1, 120, { name = "Pickup Remove Time", type = "Slider", decimals = 0, category = "Team System - KD" } )
local kdCustomMdl = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_custommodel", "", true, false, false, "Custom model that will be set for the pickup. Leave empty to use default skull model.", 0, 1, { name = "Pickup Custom Model", type = "Text", category = "Team System - KD" } )
local kdUsePoints = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_usekothpoints", 0, true, false, false, "If enabled, tags will need to be dropped off at a KOTH point before team points are given (A KOTH point is required, this is not recommend due to Salvage Run's existence).", 0, 1, { name = "Pickups Use KOTH Points", type = "Bool", category = "Team System - KD" } )
local kdPickupSounds = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_pickupsounds", 1, true, true, false, "If enabled, KD confirm/deny sounds will play.", 0, 1, { name = "Enable Confirm/Deny Sounds", type = "Bool", category = "Team System - KD" } )
local kdDrawWorldText = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_worldtext", 1, true, true, false, "If enabled, KD tags will draw confirm/deny world text.", 0, 1, { name = "Draw Confirm/Deny World Text", type = "Bool", category = "Team System - KD" } )
local kdWorldTextDist = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_worldtextdist", 1500, true, true, false, "Max distance to draw KD tag world text.", 200, 8000, { name = "World Text Max Distance", type = "Slider", decimals = 0, category = "Team System - KD" } )
local kdDrawHalo = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_halo", 1, true, true, false, "If enabled, KD tags will get a halo highlight.", 0, 1, { name = "Highlight Tags (Halo)", type = "Bool", category = "Team System - KD" } )
local kdLambdaSeekTags = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_lambdaseek", 1, true, false, false, "If enabled, Lambdas will seek out Kill Confirm tags (I recommend enabling this to keep Lambda Players on objective).", 0, 1, { name = "Should Lambda Players Collect KD Tags", type = "Bool", category = "Team System - KD" } )
local kdLambdaSeekEnemyOnly = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_lambdaseek_enemyonly", 0, true, false, false, "If enabled, Lambdas will only try to seek enemy tags & will try to avoid collecting friendly tags.", 0, 1, { name = "Only Seek Enemy Tags", type = "Bool", category = "Team System - KD" } )
local kdLambdaSeekRange = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_lambdaseek_range", 2500, true, false, false, "How far Lambdas should look for KD tags (Changing the distance to higher values effects performance minimally).", 250, 10000, { name = "Find Distance", type = "Slider", decimals = 0, category = "Team System - KD" } )
local kdLambdaSeekInterval = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_lambdaseek_interval", 0.25, true, false, false, "How often Lambdas will look for KD tags (Lower = constant rescanning & degraded performance, Higher = better performance)", 0.05, 2.0, { name = "KD Tag Seeking Interval", type = "Slider", decimals = 2, category = "Team System - KD" } )
local kdLambdaSeekInCombat = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_lambdaseek_incombat", 0, true, false, false, "If enabled, Lambdas can pursue tags even while in combat.", 0, 1, { name = "Collect Tags During Combat", type = "Bool", category = "Team System - KD" } )
local kdSndConfirm = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_snd_confirm", "buttons/button17.wav", true, true, false, "The sound thats played to the collector's TEAM when an enemy tag is CONFIRMED.", 0, 1, { name = "Sound - Confirm", type = "Text", category = "Team System - KD" } )
local kdSndDeny = CreateLambdaConvar( "lambdaplayers_teamsystem_kd_snd_deny", "buttons/button10.wav", true, true, false, "The sound thats played to the collector's TEAM when a friendly tag is DENIED.", 0, 1, { name = "Sound - Deny", type = "Text", category = "Team System - KD" } )

local assaultRequireTwoTeams = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_requiretwoteams", 1, true, false, false, "If enabled, Assault can only run with exactly 2 active teams.", 0, 1, { name = "Require Exactly 2 Teams", type = "Bool", category = "Team System - Assault" } )
local assaultAttackingTeam = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_attackteam", "", true, false, false, "Which team is the attacking team in Assault.", 0, 1, { name = "Attacking Team", type = "Combo", options = LambdaTeams.TeamOptions, category = "Team System - Assault" } )
local assaultDefendingTeam = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_defendteam", "", true, false, false, "Which team is the defending team in Assault.", 0, 1, { name = "Defending Team", type = "Combo", options = LambdaTeams.TeamOptions, category = "Team System - Assault" } )
local assaultDefensiveRoles = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_defensiveroles", 1, true, false, false, "If enabled, some Lambdas on the defending team will play defensively.", 0, 1, { name = "Enable Defensive Roles", type = "Bool", category = "Team System - Assault" } )
local assaultStartOwned = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_startowned", 1, true, false, false, "If enabled, all Assault points start owned by the defending team (I recommend you enable this to avoid the gamemode from deviating from its original purpose).", 0, 1, { name = "Defenders Own Sectors On Start", type = "Bool", category = "Team System - Assault" } )
local assaultAutoOrder = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_autoorder", 0, true, false, false, "If enabled, Assault automatically determines point order from the placed points. Disable this to use the manual point order list.", 0, 1, { name = "Automatic Point Order", type = "Bool", category = "Team System - Assault" } )
local assaultPointOrder = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_pointorder", "", true, false, false, "(Comma-separated) Assault point names in the exact order they should be captured when auto order is disabled (EXACT POINT NAMES REQUIRED).", 0, 1, { name = "Point Order", type = "Text", category = "Team System - Assault" } )
local assaultIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_icon_enabled", 1, true, true, false, "If enabled, you can see Assault objective markers.", 0, 1, { name = "Enable Objective Icons", type = "Bool", category = "Team System - Assault" } )
local assaultIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_icon_alwaysdraw", 0, true, true, false, "If enabled, Assault objective icons are drawn even when the point is not visible.", 0, 1, { name = "Persistent Icons", type = "Bool", category = "Team System - Assault" } )
local assaultDrawHalo = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_halo", 1, true, true, false, "If enabled, the current Assault objective gets a halo highlight.", 0, 1, { name = "Highlight Objective", type = "Bool", category = "Team System - Assault" } )
local assaultIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_icon_fadeinstartdist", 2500, true, true, false, "How far you should be from Assault objective icons for them to start fading out.", 0, 10000, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - Assault" } )
local assaultIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_icon_fadeinenddist", 700, true, true, false, "How close you should be from Assault objective icons for them to become fully visible.", 0, 10000, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - Assault" } )
local assaultDrawWorldText = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_worldtext", 1, true, true, false, "If enabled, the current Assault objective draws text in the world for you.", 0, 1, { name = "Draw Objective Text", type = "Bool", category = "Team System - Assault" } )
local assaultWorldTextDist = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_worldtextdist", 3500, true, true, false, "Max distance at which Assault objective text is drawn. Set to 0 to disable the distance limit.", 0, 12000, { name = "Objective Text Max Distance", type = "Slider", decimals = 0, category = "Team System - Assault" } )
local assaultCapRate = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_capturerate", 0.2, true, false, false, "The speed rate of capturing Assault points.", 0.01, 5.0, { name = "Capture Rate", type = "Slider", decimals = 2, category = "Team System - Assault" } )
local assaultCapRange = CreateLambdaConvar( "lambdaplayers_teamsystem_assault_capturerange", 500, true, false, false, "How close players should be to start capturing an Assault point.", 100, 2000, { name = "Capture Range", type = "Slider", decimals = 0, category = "Team System - Assault" } )


local salvageBankRange = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_bankrange", 250, true, false, false, "How close a salvage carrier must be to a friendly bank point to deposit their carried salvage.", 50, 1000, { name = "Bank Range", type = "Slider", decimals = 0, category = "Team System - Salvage Run" } )
local salvageLoseOnDeath = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_loseondeath", 1, true, false, false, "If enabled, carried salvage is lost when the carrier dies.", 0, 1, { name = "Lose Carry On Death", type = "Bool", category = "Team System - Salvage Run" } )
local salvageBankFirstCapture = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_bankfirstcapture", 0, true, false, false, "If enabled, Lambdas will try to secure one bank before focusing on salvage pickups.", 0, 1, { name = "Prioritize Capturing A Bank", type = "Bool", category = "Team System - Salvage Run" } )
local salvageBankInCombat = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_bank_incombat", 0, true, false, false, "If enabled, Lambdas can bank salvage while in combat.", 0, 1, { name = "Bank In Combat", type = "Bool", category = "Team System - Salvage Run" } )
local salvageGuardBanks = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_guardbanks", 0, true, false, false, "If enabled, some Lambdas will guard friendly banks instead of only chasing salvage.", 0, 1, { name = "Guard Friendly Banks", type = "Bool", category = "Team System - Salvage Run" } )
local salvagePickupEnableDelay = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_pickupenable_delay", 0.25, true, false, false, "Delay before newly dropped salvage can be collected.", 0.0, 3.0, { name = "Pickup Enable Delay", type = "Slider", decimals = 2, category = "Team System - Salvage Run" } )
local salvageRemoveTime = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_removetime", 20, true, false, false, "How long dropped salvage remains before disappearing.", 1, 120, { name = "Pickup Remove Time", type = "Slider", decimals = 0, category = "Team System - Salvage Run" } )
local salvageDrawWorldText = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_worldtext", 1, true, true, false, "If enabled, dropped salvage will draw world text.", 0, 1, { name = "Draw World Text", type = "Bool", category = "Team System - Salvage Run" } )
local salvageWorldTextDist = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_worldtextdist", 2500, true, true, false, "Max distance at which salvage world text is drawn.", 250, 10000, { name = "World Text Distance", type = "Slider", decimals = 0, category = "Team System - Salvage Run" } )
local salvageCustomMdl = CreateLambdaConvar( "lambdaplayers_teamsystem_salvagerun_custommodel", "", true, false, false, "Custom model for dropped salvage (leave empty to use KD tag).", 0, 1, { name = "Pickup Custom Model", type = "Text", category = "Team System - Salvage Run" } )

local sabotagePlantTime = CreateLambdaConvar( "lambdaplayers_teamsystem_sabotage_planttime", 3.0, true, false, false, "How long it takes to arm an enemy bomb site.", 0.5, 15.0, { name = "Plant Time", type = "Slider", decimals = 1, category = "Team System - Sabotage" } )
local sabotageAbsorbLosers = CreateLambdaConvar( "lambdaplayers_teamsystem_sabotage_absorblosers", 1, true, false, false, "If enabled, teams that lose their site become friendly to a surviving team.", 0, 1, { name = "Absorb Destroyed Teams", type = "Bool", category = "Team System - Sabotage" } )
local sabotageDefuseEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_sabotage_defuseenabled", 1, true, false, false, "If enabled, armed sabotage sites can be defused by the owning team.", 0, 1, { name = "Enable Defusing", type = "Bool", category = "Team System - Sabotage" } )
local sabotageDetonateTime = CreateLambdaConvar( "lambdaplayers_teamsystem_sabotage_detonatetime", 10.0, true, false, false, "How long after a site is armed before it detonates.", 1.0, 60.0, { name = "Detonation Time", type = "Slider", decimals = 1, category = "Team System - Sabotage" } )
local sabotageDefuseTime = CreateLambdaConvar( "lambdaplayers_teamsystem_sabotage_defusetime", 4.0, true, false, false, "How long it takes to defuse an armed sabotage site.", 0.5, 15.0, { name = "Defuse Time", type = "Slider", decimals = 1, category = "Team System - Sabotage" } )
local sabotageUseRange = CreateLambdaConvar( "lambdaplayers_teamsystem_sabotage_userange", 140, true, false, false, "How close human players must be to arm or defuse a sabotage site while holding USE.", 50, 400, { name = "Interact Range", type = "Slider", decimals = 0, category = "Team System - Sabotage" } )

local hqAvoidRepeatLast = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_avoid_repeat_last", 1, true, false, false, "If enabled, HQ selection will try to avoid repeating the previous HQ location (I recommend enabling this if you have multiple HQ locations for the HQ gamemode).", 0, 1, { name = "Avoid Repeating Last Location", type = "Bool", category = "Team System - HQ" } )
local hqCapRate = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_capturerate", 2.0, true, false, false, "How long it takes for objectives to get captured (higher values means faster capturing speed).", 0.01, 5.0, { name = "Capture Rate", type = "Slider", decimals = 2, category = "Team System - HQ" } )
local hqCapRange = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_capturerange", 500, true, false, false, "How close player should be to start capturing the HQ objective.", 100, 1000, { name = "Capture Range", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqArmTime = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_armtime", 30, true, false, false, "How long (in seconds) before the HQ objective becomes activated.", 0, 120, { name = "Arm Time", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqDestroyedDelay = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_destroyed_delay", 15, true, false, false, "How long (in seconds) should the game wait after the objective is destroyed before selecting the next location.", 0, 60, { name = "Delay Timer", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqHoldLimit = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_holdlimit", 60, true, false, false, "How long an HQ objective can stay alive for (I recommend anywhere between 30-60 seconds, anything more will make matches significantly longer).", 5, 300, { name = "Hold Time Limit", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqScoreGainTime = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_scoregaintime", 5, true, false, false, "How much time should pass before the HQ objective gives points to the holding team.", 0.1, 60, { name = "Score Gain Time", type = "Slider", decimals = 1, category = "Team System - HQ" } )
local hqScoreGainAmount = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_scoregainamount", 5, true, false, false, "How many points should be awarded each score tick to the holding team.", 1, 100, { name = "Score Per Tick", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqBotStackPenalty = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_botstackpenalty", 125000, true, false, false, "How committed should Lambda Players be when the HQ objective is active (higher values can make this gamemode challenging).", 0, 500000, { name = "Stacking Penalty", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqBotObjective = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_botobjective", 1, true, false, false, "If Lambda Players should actively play the HQ objective (this is recommended to stop matches from taking forever).", 0, 1, { name = "Lambda Players Play Objective", type = "Bool", category = "Team System - HQ" } )
local hqBotObjectiveRange = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_botobjective_range", 9000, true, false, false, "Max distance Lambdas will seek out the HQ objective.", 0, 10000, { name = "Objective Detection Range", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqBotObjectiveInCombat = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_botobjective_incombat", 0, true, false, false, "If enabled, Lambdas Players will play objectives while in combat.", 0, 1, { name = "Play Objectives In Combat", type = "Bool", category = "Team System - HQ" } )

local hqIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_icon_enabled", 1, true, true, false, "If the active HQ objective should have a HUD marker.", 0, 1, { name = "Enable Icons", type = "Bool", category = "Team System - HQ" } )
local hqIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_icon_alwaysdraw", 0, true, true, false, "If the HQ icon should always be drawn, no matter what (this can look ugly in some places).", 0, 1, { name = "Always Draw Icon", type = "Bool", category = "Team System - HQ" } )
local hqIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_icon_fadeinstartdist", 2000, true, true, false, "How far you should be from the HQ icon for it to completely fade out of view.", 0, 4096, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - HQ" } )
local hqIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_hq_icon_fadeinenddist", 500, true, true, false, "How close you should be from the HQ icon for it to become fully visible.", 0, 4096, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - HQ" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_hq_snd_onarming", "buttons/button15.wav", true, true, false, "Sound that plays when a new HQ is selected and starts activating.", 0, 1, { name = "Sound - HQ Activating", type = "Text", category = "Team System - HQ" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_hq_snd_onactive", "buttons/button17.wav", true, true, false, "Sound that plays when the HQ goes online.", 0, 1, { name = "Sound - HQ Active", type = "Text", category = "Team System - HQ" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_hq_snd_onsecure_ally", "lambdaplayers/ctf/flagcapture.mp3", true, true, false, "Sound that plays for your team when it captures the HQ.", 0, 1, { name = "Sound - On Ally HQ Secure", type = "Text", category = "Team System - HQ" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_hq_snd_onsecure_enemy", "lambdaplayers/ctf/ourflagcaptured.mp3", true, true, false, "Sound that plays when an enemy team captures the HQ.", 0, 1, { name = "Sound - On Enemy HQ Secure", type = "Text", category = "Team System - HQ" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_hq_snd_ondestroy_ally", "", true, true, false, "Sound that plays for the team that destroys the HQ.", 0, 1, { name = "Sound - On Ally HQ Destroy", type = "Text", category = "Team System - HQ" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_hq_snd_ondestroy_enemy", "", true, true, false, "Sound that plays for teams when an enemy destroys the HQ.", 0, 1, { name = "Sound - On Enemy HQ Destroy", type = "Text", category = "Team System - HQ" } )

---

function LambdaTeams:GetCurrentGamemodeID()
    return GetGlobalInt( "LambdaTeamMatch_GameID", 0 )
end

function LambdaTeams:GamemodeMatchActive()
    return ( LambdaTeams:GetCurrentGamemodeID() != 0 )
end

function LambdaTeams:AreTeamsHostile()
    return ( LambdaTeams:GamemodeMatchActive() or attackOthers:GetBool() )
end

function LambdaTeams:GetTeamPoints( teamName )
    return ( GetGlobalInt( "LambdaTeamMatch_TeamPoints_" .. teamName, 0 ) )
end

function LambdaTeams:AddTeamPoints( teamName, count )
    local teamPoints = LambdaTeams.TeamPoints[ teamName ]
    if not teamPoints then
        teamPoints = "LambdaTeamMatch_TeamPoints_" .. teamName
        LambdaTeams.TeamPoints[ teamName ] = teamPoints
    end

    local old = GetGlobalInt( teamPoints, 0 )
    local newCount = old + count

    if newCount < 0 then newCount = 0 end

    if GetGlobalInt( "LambdaTeamMatch_GameID", 0 ) == 1 and GetGlobalBool( "LambdaTeamMatch_IsConquest", false ) then
        local cap = GetGlobalInt( "LambdaTeamMatch_ConquestTicketCap", 0 )
        if cap > 0 and newCount > cap then newCount = cap end
    end

    if LambdaTeams:GetCurrentGamemodeID() == 3 and ( GetGlobalInt( "LambdaTeamMatch_PointLimit" ) - newCount ) == 10 then
        LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", LambdaTeams:GetTeamColor( teamName, true ), teamName, color_glacier, " needs 10 more kills to win!" )
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_tdm_snd_10killsleft", "all" )
    end

    SetGlobalInt( teamPoints, newCount )
end

function LambdaTeams:GetTeamColor( teamName, realColor )
    local data = LambdaTeams.TeamData[ teamName ]
    return ( data and data.color and ( !realColor and data.color or data.color:ToColor() ) )
end

function LambdaTeams:GetPlayerTeam( ply )
    if !IsValid( ply ) then return end
    local plyTeam = nil

    if ply.IsLambdaPlayer then
        if CLIENT then
            plyTeam = ply:GetNW2String( "lambda_teamname" )
            if !plyTeam or plyTeam == "" then
                plyTeam = ply:GetNWString( "lambda_teamname" )
            end
        else
            plyTeam = ply.l_TeamName
            if !plyTeam or plyTeam == "" then
                plyTeam = ply:GetNW2String( "lambda_teamname" )
                if !plyTeam or plyTeam == "" then
                    plyTeam = ply:GetNWString( "lambda_teamname" )
                end
            end
        end

	elseif ply:IsPlayer() then
		plyTeam = ply:GetNW2String( "lambda_teamname", "" )
		if !plyTeam or plyTeam == "" then
			plyTeam = ply:GetNWString( "lambda_teamname", "" )
		end

		if ( !plyTeam or plyTeam == "" ) and CLIENT then
			plyTeam = playerTeam:GetString()
		end

		if ( !plyTeam or plyTeam == "" ) and SERVER then
			if ply.l_IsInLambdaTeam then
				plyTeam = ply.LTS_SelectedTeam or ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
			end

			if !plyTeam or plyTeam == "" then
				local tname = team.GetName( ply:Team() )
				if tname and tname != "" and LambdaTeams.RealTeams[ tname ] then
					plyTeam = tname
				end
			end
		end
	end

    return ( plyTeam != "" and plyTeam or nil )
end

function LambdaTeams:AreTeammates( ent, target )
    if !IsValid( ent ) or !IsValid( target ) then return end

    local entTeam = LambdaTeams:GetPlayerTeam( ent )
    if !entTeam then return end

    local targetTeam = LambdaTeams:GetPlayerTeam( target )
    if !targetTeam then return end

    if entTeam == targetTeam then return true end

    local allies = LambdaTeams.AlliedTeams[ entTeam ]
    if allies and allies[ targetTeam ] then
        return true
    end

    return false
end

function LambdaTeams:MakeTeamsFriendly( teamA, teamB )
    if !teamA or !teamB or teamA == "" or teamB == "" then return end

    LambdaTeams.AlliedTeams[ teamA ] = LambdaTeams.AlliedTeams[ teamA ] or {}
    LambdaTeams.AlliedTeams[ teamB ] = LambdaTeams.AlliedTeams[ teamB ] or {}

    LambdaTeams.AlliedTeams[ teamA ][ teamB ] = true
    LambdaTeams.AlliedTeams[ teamB ][ teamA ] = true

    LambdaTeams:SaveAlliances()
end

function LambdaTeams:RemoveFriendlyTeams( teamA, teamB )
    if !teamA or !teamB or teamA == "" or teamB == "" then return end

    if LambdaTeams.AlliedTeams[ teamA ] then
        LambdaTeams.AlliedTeams[ teamA ][ teamB ] = nil
    end
    if LambdaTeams.AlliedTeams[ teamB ] then
        LambdaTeams.AlliedTeams[ teamB ][ teamA ] = nil
    end

    LambdaTeams:SaveAlliances()
end

function LambdaTeams:ClearAllAlliances()
    LambdaTeams.AlliedTeams = {}
    LambdaTeams:SaveAlliances()
end

function LambdaTeams:AddAOSExemption(teamA, teamB)
    if not teamA or not teamB then return end

    LambdaTeams.AOSExempt[teamA] = LambdaTeams.AOSExempt[teamA] or {}
    LambdaTeams.AOSExempt[teamA][teamB] = true

    LambdaTeams:SaveAOSExempt()
end

function LambdaTeams:RemoveAOSExemption(teamA, teamB)
    if LambdaTeams.AOSExempt[teamA] then
        LambdaTeams.AOSExempt[teamA][teamB] = nil
    end
    
    LambdaTeams:SaveAOSExempt()
end

function LambdaTeams:IsAOSExempt(teamA, teamB)
    return LambdaTeams.AOSExempt[teamA]
       and LambdaTeams.AOSExempt[teamA][teamB] == true
end

function LambdaTeams:GetTeamCount( teamName )
    local count = 0
    
    for _, ply in ipairs( ents_GetAll() ) do
        if LambdaTeams:GetPlayerTeam( ply ) == teamName and ( !ply:IsPlayer() or !ignorePlys:GetBool() ) then 
            count = count + 1 
        end
    end
    
    return count
end

function LambdaTeams:GetSpawnPoints( teamName )
    local points = {}

    for _, point in ipairs( ents_FindByClass( "lambda_teamspawnpoint" ) ) do
        if !IsValid( point ) then continue end
        
        local pointTeam = point:GetSpawnTeam()
        if pointTeam != "" and ( !teamName or pointTeam != teamName ) then continue end

        points[ #points + 1 ] = point
    end

    return points
end
