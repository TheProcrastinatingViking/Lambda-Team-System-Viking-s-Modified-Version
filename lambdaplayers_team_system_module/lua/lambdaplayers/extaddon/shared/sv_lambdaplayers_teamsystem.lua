if ( SERVER ) then

    util.AddNetworkString( "lambda_teamsystem_playclientsound" )
    util.AddNetworkString( "lambda_teamsystem_stopclientsound" )
    util.AddNetworkString( "lambda_teamsystem_setplayerteam" )
    util.AddNetworkString( "lambda_teamsystem_updatedata" )
    util.AddNetworkString( "lambda_teamsystem_sendupdateddata" )
	util.AddNetworkString( "lambda_teamsystem_kd_feedback" )

	local GetNearestNavArea = navmesh.GetNearestNavArea
	local VectorRand = VectorRand
	local FrameTime = FrameTime
	local RandomPairs = RandomPairs
	local table_Random = table.Random
	local table_Count = table.Count
	local table_Copy = table.Copy
	local ents_GetAll = ents.GetAll
	local tobool = tobool
	local min = math.min
	local abs = math.abs
	local lower = string.lower
	local Rand = math.Rand
	local random = math.random
	local timer_Simple = timer.Simple
	
    local modulePrefix = "Lambda_TeamSystem_"

    local teamsEnabled = GetConVar( "lambdaplayers_teamsystem_enable" )
    local mwsTeam = GetConVar( "lambdaplayers_teamsystem_mws_spawnteam" )
    local incNoTeams = GetConVar( "lambdaplayers_teamsystem_mws_includenoteams" )
    local mwsTeamLimit = GetConVar( "lambdaplayers_teamsystem_mws_teamlimit" )
	local teamSpawnEnemyRadius = GetConVar( "lambdaplayers_teamsystem_teamspawn_enemyradius" )
    local gmMinTeams = GetConVar( "lambdaplayers_teamsystem_gamemodes_minteams" )
	
    local teamLimit = GetConVar( "lambdaplayers_teamsystem_teamlimit" )
    local attackOthers = GetConVar( "lambdaplayers_teamsystem_attackotherteams" )
    local noFriendFire = GetConVar( "lambdaplayers_teamsystem_nofriendlyfire" )
    local stickTogether = GetConVar( "lambdaplayers_teamsystem_sticktogether" )
    local huntDown = GetConVar( "lambdaplayers_teamsystem_huntdownotherteams" )
	local teamAggression = GetConVar( "lambdaplayers_teamsystem_aggression" )
    local specificCampWeapons = GetConVar( "lambdaplayers_teamsystem_specificcampweapons" )
    local useSpawnpoints = GetConVar( "lambdaplayers_teamsystem_usespawnpoints" )

    local objCommitTime = GetConVar( "lambdaplayers_teamsystem_obj_commit_time" )
    local objRepathCooldown = GetConVar( "lambdaplayers_teamsystem_obj_repath_cooldown" )
    local objStuckTime = GetConVar( "lambdaplayers_teamsystem_obj_stuck_time" )
    local objStuckMove = GetConVar( "lambdaplayers_teamsystem_obj_stuck_move" )

    local adRole_DefendWeight = GetConVar( "lambdaplayers_teamsystem_ad_role_defend" )
    local adRole_AttackWeight = GetConVar( "lambdaplayers_teamsystem_ad_role_attack" )
    local adRole_RoamWeight = GetConVar( "lambdaplayers_teamsystem_ad_role_roam" )
    local adBotObjective = GetConVar( "lambdaplayers_teamsystem_ad_botobjective" )
    local adBotObjectiveRange = GetConVar( "lambdaplayers_teamsystem_ad_botobjective_range" )
    local adBotObjectiveInCombat = GetConVar( "lambdaplayers_teamsystem_ad_botobjective_incombat" )
    local adBotStackPenalty = GetConVar( "lambdaplayers_teamsystem_ad_botobjective_stackpenalty" )

    local ctfRole_DefendWeight = GetConVar( "lambdaplayers_teamsystem_ctf_role_defend" )
    local ctfRole_AttackWeight = GetConVar( "lambdaplayers_teamsystem_ctf_role_attack" )
    local ctfRole_EscortWeight = GetConVar( "lambdaplayers_teamsystem_ctf_role_escort" )
    local ctfRole_HuntWeight = GetConVar( "lambdaplayers_teamsystem_ctf_role_hunt" )
    local ctfMinDefenders = GetConVar( "lambdaplayers_teamsystem_ctf_min_defenders" )
    local ctfBotObjective = GetConVar( "lambdaplayers_teamsystem_ctf_botobjective" )
    local ctfBotObjectiveRange = GetConVar( "lambdaplayers_teamsystem_ctf_botobjective_range" )
    local ctfBotObjectiveInCombat = GetConVar( "lambdaplayers_teamsystem_ctf_botobjective_incombat" )
    local ctfDefendBoostWhenFlagTaken = GetConVar( "lambdaplayers_teamsystem_ctf_defend_boost_taken" )

	local kdPickupEnableDelay = GetConVar( "lambdaplayers_teamsystem_kd_pickupenable_delay" )
    local kdRemoveTime = GetConVar( "lambdaplayers_teamsystem_kd_removetime" )
    local kdCustomMdl = GetConVar( "lambdaplayers_teamsystem_kd_custommodel" )
    local kdUsePoints = GetConVar( "lambdaplayers_teamsystem_kd_usekothpoints" )
    local kdLambdaSeekTags = GetConVar( "lambdaplayers_teamsystem_kd_lambdaseek" )
    local kdLambdaSeekEnemyOnly = GetConVar( "lambdaplayers_teamsystem_kd_lambdaseek_enemyonly" )

    local hqAvoidRepeatLast = GetConVar( "lambdaplayers_teamsystem_hq_avoid_repeat_last" )
    local hqCapRange = GetConVar( "lambdaplayers_teamsystem_hq_capturerange" )
    local hqArmTime = GetConVar( "lambdaplayers_teamsystem_hq_armtime" )
    local hqDestroyedDelay = GetConVar( "lambdaplayers_teamsystem_hq_destroyed_delay" )
    local hqHoldLimit = GetConVar( "lambdaplayers_teamsystem_hq_holdlimit" )
    local hqScoreGainTime = GetConVar( "lambdaplayers_teamsystem_hq_scoregaintime" )
    local hqScoreGainAmount = GetConVar( "lambdaplayers_teamsystem_hq_scoregainamount" )
    local hqBotStackPenalty = GetConVar( "lambdaplayers_teamsystem_hq_botstackpenalty" )
    local hqBotObjective = GetConVar( "lambdaplayers_teamsystem_hq_botobjective" )
    local hqBotObjectiveRange = GetConVar( "lambdaplayers_teamsystem_hq_botobjective_range" )
    local hqBotObjectiveInCombat = GetConVar( "lambdaplayers_teamsystem_hq_botobjective_incombat" )
	
	local assaultDefensiveRoles = GetConVar( "lambdaplayers_teamsystem_assault_defensiveroles" )

	local salvageBankFirstCapture = GetConVar( "lambdaplayers_teamsystem_salvagerun_bankfirstcapture" )
	local salvageBankInCombat = GetConVar( "lambdaplayers_teamsystem_salvagerun_bank_incombat" )
	local salvageGuardBanks = GetConVar( "lambdaplayers_teamsystem_salvagerun_guardbanks" )
	local salvagePickupEnableDelay = GetConVar( "lambdaplayers_teamsystem_salvagerun_pickupenable_delay" )
	local salvageRemoveTime = GetConVar( "lambdaplayers_teamsystem_salvagerun_removetime" )
	local salvageCustomMdl = GetConVar( "lambdaplayers_teamsystem_salvagerun_custommodel" )
	local salvageBankRange = GetConVar( "lambdaplayers_teamsystem_salvagerun_bankrange" )
	local salvageLoseOnDeath = GetConVar( "lambdaplayers_teamsystem_salvagerun_loseondeath" )
	local salvageDrawWorldText = GetConVar( "lambdaplayers_teamsystem_salvagerun_worldtext" )
	local salvageWorldTextDist = GetConVar( "lambdaplayers_teamsystem_salvagerun_worldtextdist" )


    local rndBodyGroups = GetConVar( "lambdaplayers_lambda_allowrandomskinsandbodygroups" )

	local vector_origin = Vector( 0, 0, 0 )
	local LTS_SetPlayerLambdaTeamState
	local LTS_ApplyPlayerLambdaTeam

	local function TeamSystemEnabled()
		local cv = GetConVar( "lambdaplayers_teamsystem_enable" )
		return ( cv and cv:GetBool() ) or false
	end

	local function LTS_GetRealTeams()
		if !LambdaTeams then return {} end

		if !LambdaTeams.RealTeams then
			if LambdaTeams.UpdateData then
				LambdaTeams:UpdateData()
			end
		end

		return LambdaTeams.RealTeams or {}
	end

	LTS_SetPlayerLambdaTeamState = function( ply, forcedTeamName )
		if !IsValid( ply ) or !ply:IsPlayer() then return end

		if forcedTeamName != nil then
			ply.LTS_SelectedTeam = forcedTeamName
		end

		local teamName = ply.LTS_SelectedTeam
		if !teamName or teamName == "" then
			teamName = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
			if teamName and teamName != "" then
				ply.LTS_SelectedTeam = teamName
			end
		end

		local realTeams = LTS_GetRealTeams()
		local teamID = ( teamName and realTeams[ teamName ] or nil )

		if teamsEnabled and TeamSystemEnabled() and teamID then
			ply:SetTeam( teamID )
			ply.l_IsInLambdaTeam = true

			ply:SetNW2String( "lambda_teamname", teamName )
			ply:SetNWString( "lambda_teamname", teamName )

			local teamClr = LambdaTeams.GetTeamColor and LambdaTeams:GetTeamColor( teamName )
			local vecClr = ( isvector( teamClr ) and teamClr ) or ( teamClr and teamClr:ToVector() ) or vector_origin

			ply:SetNW2Vector( "lambda_teamcolor", vecClr )
			ply:SetNWVector( "lambda_teamcolor", vecClr )
		else
			ply:SetTeam( 1001 )
			ply.l_IsInLambdaTeam = false
			ply.LTS_SelectedTeam = nil

			ply:SetNW2String( "lambda_teamname", "" )
			ply:SetNWString( "lambda_teamname", "" )
			ply:SetNW2Vector( "lambda_teamcolor", vector_origin )
			ply:SetNWVector( "lambda_teamcolor", vector_origin )
		end
	end

	LTS_ApplyPlayerLambdaTeam = function( ply )
		if !IsValid( ply ) or !ply:IsPlayer() then return end
		LTS_SetPlayerLambdaTeamState( ply )
	end

	net.Receive( "lambda_teamsystem_setplayerteam", function( _, ply )
		if !IsValid( ply ) or !ply:IsPlayer() then return end

		local teamName = net.ReadString()
		if teamName == nil then return end

		LTS_SetPlayerLambdaTeamState( ply, teamName )
	end )

	local function LTS_SafeRefreshTeamData()
		if !LambdaTeams then return false end

		if LambdaTeams.UpdateData then
			LambdaTeams:UpdateData()
		else
			return false
		end

		if LambdaTeams.LoadAlliances then
			LambdaTeams:LoadAlliances()
		end

		if LambdaTeams.LoadAOSExempt then
			LambdaTeams:LoadAOSExempt()
		end

		return true
	end

	local function LTS_BroadcastTeamData()
		if !LTS_SafeRefreshTeamData() then return end

		net.Start( "lambda_teamsystem_sendupdateddata" )
		net.Broadcast()
	end

	net.Receive( "lambda_teamsystem_updatedata", function( _, ply )
		if IsValid( ply ) and !ply:IsPlayer() then return end
		LTS_BroadcastTeamData()
	end )

	hook.Add( "Initialize", "Lambda_TeamSystem_ServerInitialData", function()
		timer.Simple( 1, function()
			LTS_BroadcastTeamData()
		end )
	end )

	hook.Add( "PlayerInitialSpawn", "Lambda_TeamSystem_PlayerInitialData", function( ply )
		timer.Simple( 1, function()
			if !IsValid( ply ) then return end
			if !LTS_SafeRefreshTeamData() then return end

			net.Start( "lambda_teamsystem_sendupdateddata" )
			net.Send( ply )
		end )
	end )

    function LambdaTeams:PlayConVarSound( sndCvar, targetTeam )
        net.Start( "lambda_teamsystem_playclientsound" )
            net.WriteString( targetTeam or "" )
            net.WriteString( sndCvar )
        net.Broadcast()
    end

    function LambdaTeams:StopConVarSound( sndCvar )
        net.Start( "lambda_teamsystem_stopclientsound" )
            net.WriteString( sndCvar )
        net.Broadcast()
    end

	local function OnTeamSystemDisable( name, oldVal, newVal )
		local isEnabled = tobool( newVal )

		SetGlobalBool( "LambdaTeamSystem_Enabled", isEnabled )

		for _, ply in ipairs( ents_GetAll() ) do
			if !IsValid( ply ) then continue end

			if ply.IsLambdaPlayer then
				local realTeams = LTS_GetRealTeams()
				local teamID = realTeams[ ply.l_TeamName ]

				if isEnabled then
					if teamID then
						ply:SetTeam( teamID )
						if ply.l_TeamColor then
							ply:SetPlyColor( ply.l_TeamColor:ToVector() )
						end
					end
				elseif ply:Team() != 0 then
					ply:SetTeam( 0 )
					if ply.l_PlyNoTeamColor then
						ply:SetPlyColor( ply.l_PlyNoTeamColor )
					end
				end

			elseif ply:IsPlayer() then
				if isEnabled then
					LTS_SetPlayerLambdaTeamState( ply )
				else
					ply:SetTeam( 1001 )
					ply.l_IsInLambdaTeam = false
					ply.LTS_SelectedTeam = nil
					ply:SetNW2String( "lambda_teamname", "" )
					ply:SetNWString( "lambda_teamname", "" )
					ply:SetNW2Vector( "lambda_teamcolor", vector_origin )
					ply:SetNWVector( "lambda_teamcolor", vector_origin )
				end
			end
		end
	end

    cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_enable", modulePrefix .. "OnSystemChanged" )
    cvars.AddChangeCallback( "lambdaplayers_teamsystem_enable", OnTeamSystemDisable, modulePrefix .. "OnSystemChanged" )

    local function SetTeamToLambda( lambda, team, rndNoTeams, limit, useMdls )
        if !TeamSystemEnabled() then return end

        local teamTbl = LambdaTeams.TeamData
        if limit and limit > 0 then
            teamTbl = table_Copy( teamTbl )
            for name, _ in pairs( teamTbl ) do
                if LambdaTeams:GetTeamCount( name ) < limit then continue end
                teamTbl[ name ] = nil
            end
        end

        local teamData
        if team == "random" then
            if rndNoTeams then
                local teamCount = table_Count( teamTbl )
                if random( teamCount + 1 ) > teamCount then return end
            end

            teamData = table_Random( teamTbl )
        else
            teamData = teamTbl[ team ]
        end
        if !teamData then return end

        local name = teamData.name
        lambda:SetExternalVar( "l_TeamName", name )
        lambda:SetNW2String( "lambda_teamname", name )
        lambda:SetNWString( "lambda_teamname", name )

        if useMdls == nil then useMdls = true end
        if useMdls then
            local plyMdls = teamData.playermdls
            if plyMdls and #plyMdls > 0 then 
                lambda:SetModel( plyMdls[ random( #plyMdls ) ] ) 

                lambda.l_BodyGroupData = {}
                if rndBodyGroups:GetBool() then
                    for _, bg in ipairs( lambda:GetBodyGroups() ) do
                        local subMdls = #bg.submodels
                        if subMdls == 0 then continue end 

                        local rndID = random( 0, subMdls )
                        lambda:SetBodygroup( bg.id, rndID )
                        lambda.l_BodyGroupData[ bg.id ] = rndID
                    end

                    local skinCount = lambda:SkinCount()
                    if skinCount > 0 then lambda:SetSkin( random( 0, skinCount - 1 ) ) end
                end
            end
        end

        local color = teamData.color
        lambda:SetExternalVar( "l_TeamColor", color:ToColor() )
        lambda:SetPlyColor( color )
        lambda:SetNW2Vector( "lambda_teamcolor", color )
        lambda:SetNWVector( "lambda_teamcolor", color )

        local realTeams = LTS_GetRealTeams()
		local teamID = realTeams[ name ]
        if teamID then lambda:SetTeam( teamID ) end

        lambda:SetExternalVar( "l_TeamSpawnHealth", teamData.spawnhealth )
        lambda:SetExternalVar( "l_TeamSpawnArmor", teamData.spawnarmor )
        lambda:SetExternalVar( "l_TeamVoiceProfile", teamData.voiceprofile )
        lambda:SetExternalVar( "l_TeamWepRestrictions", teamData.weaponrestrictions )
    end

    local function OnPlayerSpawnedNPC( ply, npc )
        if !npc.IsLambdaPlayer then return end
        SetTeamToLambda( npc, ply:GetInfo( "lambdaplayers_teamsystem_lambdateam" ), tobool( ply:GetInfo( "lambdaplayers_teamsystem_includenoteams" ) ), teamLimit:GetInt() )
    end

	local function LTS_IsLivingTeamEnt( ent )
		if !IsValid( ent ) then return false end

		if ent.IsLambdaPlayer then
			return !ent:GetIsDead()
		end

		if ent:IsPlayer() then
			return ent:Alive()
		end

		return false
	end

	local function LTS_IsSpawnPointSafe( spawnPoint, teamName, enemyRadius )
		if enemyRadius <= 0 or !IsValid( spawnPoint ) then return true end

		local radiusSqr = enemyRadius * enemyRadius
		local spawnPos = spawnPoint:GetPos()

		for _, ent in ipairs( ents_GetAll() ) do
			if !LTS_IsLivingTeamEnt( ent ) then continue end

			local entTeam = LambdaTeams:GetPlayerTeam( ent )
			if !entTeam or entTeam == "" then continue end
			if teamName and teamName != "" and entTeam == teamName then continue end

			if ent:GetPos():DistToSqr( spawnPos ) <= radiusSqr then
				return false
			end
		end

		return true
	end

	local function LTS_SelectTeamSpawn( teamName )
		local spawnPoints = ( LambdaTeams.GetSpawnPoints and LambdaTeams:GetSpawnPoints( teamName ) ) or {}
		if !spawnPoints or #spawnPoints == 0 then return nil end

		local enemyRadius = math.max( 0, ( teamSpawnEnemyRadius and teamSpawnEnemyRadius:GetFloat() ) or 0 )
		local safePoint
		local unoccupiedPoint
		local fallback = spawnPoints[ random( #spawnPoints ) ]

		for _, point in RandomPairs( spawnPoints ) do
			if !IsValid( point ) then continue end

			local isSafe = LTS_IsSpawnPointSafe( point, teamName, enemyRadius )

			if !point.IsOccupied and isSafe then
				return point
			end

			if !safePoint and isSafe then
				safePoint = point
			end

			if !unoccupiedPoint and !point.IsOccupied then
				unoccupiedPoint = point
			end
		end

		return safePoint or unoccupiedPoint or fallback
	end

    local function LambdaOnInitialize( self )
        self.l_NextEnemyTeamSearchT = CurTime() + Rand( 0.33, 1.0 )
        self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )
		self.l_TeamMovePos = nil

        self:SimpleTimer( 0.1, function()
            if !self.l_TeamName then
                if self.l_MWSspawned then
                    self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )
                    SetTeamToLambda( self, mwsTeam:GetString(), incNoTeams:GetBool(), mwsTeamLimit:GetInt() )
                else
                    local ply = self:GetCreator()
                    if IsValid( ply ) then
                        self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )
                        SetTeamToLambda( self, ply:GetInfo( "lambdaplayers_teamsystem_lambdateam" ), tobool( ply:GetInfo( "lambdaplayers_teamsystem_includenoteams" ) ), teamLimit:GetInt(), false ) 
                    end
                end

                if self.l_TeamColor then self:SetPlyColor( self.l_TeamColor:ToVector() ) end
            end

            if useSpawnpoints:GetBool() then
                local spawnPoint = LTS_SelectTeamSpawn( self.l_TeamName )
                if IsValid( spawnPoint ) then
                    self:SetPos( spawnPoint:GetPos() )
                    self:SetAngles( spawnPoint:GetAngles() )
                end
            end

            if self.l_TeamName then 
                local spawnHealth = self.l_TeamSpawnHealth
                if spawnHealth then 
                    self:SetHealth( spawnHealth )
                    if spawnHealth > self:GetMaxHealth() then self:SetMaxHealth( spawnHealth ) end
                end

                local spawnArmor = self.l_TeamSpawnArmor
                if spawnArmor then 
                    self:SetArmor( spawnArmor )
                    if spawnArmor > self:GetMaxArmor() then self:SetMaxArmor( spawnArmor ) end
                end

                local voiceProfile = self.l_TeamVoiceProfile
                if voiceProfile then 
                    self.l_VoiceProfile = voiceProfile
                    self:SetNW2String( "lambda_vp", voiceProfile )
                elseif !self.l_VoiceProfile then
                    local modelVP = LambdaModelVoiceProfiles[ lower( self:GetModel() ) ]
                    if modelVP then 
                        self.l_VoiceProfile = modelVP 
                        self:SetNW2String( "lambda_vp", modelVP )
                    end
                end

                local wepRestrictions = self.l_TeamWepRestrictions
                if wepRestrictions and !wepRestrictions[ self.l_Weapon ] then 
                    local _, rndWep = table_Random( wepRestrictions )
                    self:SwitchWeapon( rndWep )
                end
            end
        end, true )
    end

    local function LambdaPostRecreated( self )
        if !self.l_TeamName then return end
        self:SetNW2String( "lambda_teamname", self.l_TeamName )
        self:SetNWString( "lambda_teamname", self.l_TeamName )

        local realTeams = LTS_GetRealTeams()
		local teamID = realTeams[ self.l_TeamName ]
        if teamID then self:SetTeam( teamID ) end

        if !self.l_TeamColor then return end
        self.l_TeamColor = Color( self.l_TeamColor.r, self.l_TeamColor.g, self.l_TeamColor.b )

        self:SetNW2Vector( "lambda_teamcolor", self.l_TeamColor:ToVector() )
        self:SetNWVector( "lambda_teamcolor", self.l_TeamColor:ToVector() )

        if self.l_PlyNoTeamColor and !TeamSystemEnabled() then
            self:SetPlyColor( self.l_PlyNoTeamColor )
        else
            self:SetPlyColor( self.l_TeamColor:ToVector() )
        end
    end

    local function LambdaOnRespawn( self )
        if !useSpawnpoints:GetBool() then return end
		
        local spawnPoint = LTS_SelectTeamSpawn( self.l_TeamName )
        if !IsValid( spawnPoint ) then return end

        self:SetPos( spawnPoint:GetPos() )
        self:SetAngles( spawnPoint:GetAngles() )
    end

	local function LTS_IsAliveSabotageActor( ent )
		if !IsValid( ent ) then return false end

		if ent.IsLambdaPlayer then
			return !ent:GetIsDead()
		end

		if ent:IsPlayer() then
			return ent:Alive()
		end

		return false
	end

	local function LTS_GetSabotagePos( ent )
		if !IsValid( ent ) then return nil end
		return ( ent.WorldSpaceCenter and ent:WorldSpaceCenter() ) or ent:GetPos()
	end

	local function LTS_FindSabotageThreat( site, myTeam, radius )
		if !IsValid( site ) then return nil end

		local sitePos = LTS_GetSabotagePos( site )
		local radiusSqr = radius * radius
		local nearest, nearestDist

		for _, ent in ipairs( ents_GetAll() ) do
			if !LTS_IsAliveSabotageActor( ent ) then continue end

			local entTeam = LambdaTeams:GetPlayerTeam( ent )
			if !entTeam or entTeam == "" or entTeam == myTeam then continue end

			local dist = ent:GetPos():DistToSqr( sitePos )
			if dist > radiusSqr then continue end

			if !nearestDist or dist < nearestDist then
				nearest = ent
				nearestDist = dist
			end
		end

		return nearest, nearestDist
	end

	local function LTS_CountFriendlySabotageCommitters( self, site )
		if !IsValid( site ) then return 0 end

		local count = 0
		for _, ent in ipairs( ents_GetAll() ) do
			if ent == self or !IsValid( ent ) or !ent.IsLambdaPlayer then continue end
			if ent:GetIsDead() then continue end
			if ent.l_TeamName != self.l_TeamName then continue end
			if ent.l_SAB_TargetEnt != site then continue end

			count = count + 1
		end

		return count
	end

	local function LTS_PickSabotageAttackSite( self )
		local state = LambdaTeams.Sabotage_State
		if !state or !state.Sites then
			return ( LambdaTeams.GetNearestEnemySabotageSite and LambdaTeams:GetNearestEnemySabotageSite( self.l_TeamName, self:GetPos() ) ) or nil
		end

		local myPos = self:GetPos()
		local bestSite, bestScore

		for teamName, site in pairs( state.Sites ) do
			if teamName == self.l_TeamName then continue end
			if !IsValid( site ) then continue end
			if site:GetNW2Bool( "LTS_SAB_Destroyed", site:GetNWBool( "LTS_SAB_Destroyed", false ) ) then continue end

			local score = myPos:DistToSqr( site:GetPos() )

			local _, enemyGuardDist = LTS_FindSabotageThreat( site, teamName, 450 )
			if enemyGuardDist then
				score = score + 180000
			end

			score = score + ( LTS_CountFriendlySabotageCommitters( self, site ) * 175000 )

			if !bestScore or score < bestScore then
				bestSite = site
				bestScore = score
			end
		end

		return bestSite
	end

	local WeightedPick, EnsureRole_AD, EnsureRole_CTF, EnsureRole_AS, EnsureRole_SR, ObjectiveStuckTick

    local function LTS_GetAggressionFrac()
        local val = ( teamAggression and teamAggression:GetFloat() or 50 )
        return math.Clamp( val, 0, 100 ) / 100
    end

    local function LTS_GetAOSSightRange()
        local frac = LTS_GetAggressionFrac()
        return math.floor( 900 + ( 2100 * frac ) )      -- 900 -> 3000
    end

    local function LTS_GetHuntRange()
        local frac = LTS_GetAggressionFrac()
        return math.floor( 1500 + ( 4500 * frac ) )     -- 1500 -> 6000
    end

    local function LTS_GetCommitTime()
        local frac = LTS_GetAggressionFrac()
        return ( 45 + ( 255 * frac ) )                  -- 45s -> 300s
    end

    local function LTS_GetRegroupDistance()
        local frac = LTS_GetAggressionFrac()
        return math.floor( 1400 - ( 700 * frac ) )      -- 1400 -> 700
    end

    local function LTS_HasObjectiveTarget( self )
        return (
            self.l_AD_TargetPos
            or self.l_CTF_TargetPos
            or self.l_KD_TargetPos
            or self.l_HQ_TargetPos
            or self.l_AS_TargetPos
            or self.l_SR_TargetPos
            or self.l_SAB_TargetPos
        ) != nil
    end

    local function LTS_IsAliveTeamActor( ent )
        if !IsValid( ent ) then return false end

        if ent.IsLambdaPlayer then
            return ( ent:Alive() and !ent:GetIsDead() )
        elseif ent:IsPlayer() then
            return ent:Alive()
        end

        return false
    end

    local function LTS_IsEnemyTeamTarget( self, ent )
        if ent == self or !LTS_IsAliveTeamActor( ent ) then return false end
        if !self:CanTarget( ent ) then return false end

        local myTeam = LambdaTeams:GetPlayerTeam( self )
        if !myTeam or myTeam == "" then return false end

        local entTeam = LambdaTeams:GetPlayerTeam( ent )

        if entTeam and entTeam != "" then
            if LambdaTeams:AreTeammates( self, ent ) then return false end
            if LambdaTeams:IsAOSExempt( myTeam, entTeam ) then return false end
            return true
        end

        -- GO FUCK YOURSELF LONEWOLVES
        return true
    end

    local function LTS_FindNearestEnemyTeamTarget( self, maxDist, requireLOS, requireFront )
        local myPos = self:WorldSpaceCenter()
        local myForward = self:GetForward()
        local maxDistSqr = ( maxDist * maxDist )

        local nearest, nearestDist
        for _, ent in ipairs( ents_GetAll() ) do
            if !LTS_IsEnemyTeamTarget( self, ent ) then continue end

            local entPos = ent:WorldSpaceCenter()
            local dist = myPos:DistToSqr( entPos )
            if dist > maxDistSqr then continue end

            if requireLOS and !self:CanSee( ent ) then continue end

            if requireFront then
                local los = entPos - myPos
                los.z = 0
                los:Normalize()

                if los:Dot( myForward ) < 0.2 then continue end
            end

            if !nearestDist or dist < nearestDist then
                nearest = ent
                nearestDist = dist
            end
        end

        return nearest, nearestDist
    end

    local function LTS_FindNearestTeammate( self, maxDist )
        local myPos = self:WorldSpaceCenter()
        local maxDistSqr = ( maxDist * maxDist )

        local nearest, nearestDist
        for _, ent in ipairs( ents_GetAll() ) do
            if ent == self then continue end
            if !LTS_IsAliveTeamActor( ent ) then continue end
            if LambdaTeams:AreTeammates( self, ent ) != true then continue end

            local dist = myPos:DistToSqr( ent:WorldSpaceCenter() )
            if dist > maxDistSqr then continue end

            if !nearestDist or dist < nearestDist then
                nearest = ent
                nearestDist = dist
            end
        end

        return nearest, nearestDist
    end

    local campWeaponCache = {}
    local campWeaponCacheRaw = ""

    local function LTS_GetCampWeaponSet()
        local raw = lower( ( specificCampWeapons and specificCampWeapons:GetString() ) or "" )
        if raw == campWeaponCacheRaw then return campWeaponCache end

        campWeaponCacheRaw = raw
        campWeaponCache = {}

        for wep in string.gmatch( raw, "([^,]+)" ) do
            wep = lower( string.Trim( wep ) )
            if wep != "" then
                campWeaponCache[ wep ] = true
            end
        end

        return campWeaponCache
    end

    local function LTS_ShouldCamp( self )
        if !self:InCombat() or self.l_HasMelee then return false end

        local enemy = self:GetEnemy()
        if !LTS_IsAliveTeamActor( enemy ) or !self:CanSee( enemy ) then return false end

        local wepName = lower( self:GetWeaponName() or self.l_Weapon or "" )
        if wepName == "" then return false end

        local allowed = LTS_GetCampWeaponSet()
        if !allowed[ wepName ] then return false end

        local attackRange = ( self.l_CombatAttackRange or 0 )
        if attackRange <= 0 then return false end

        local minHoldRange = math.max( 350, attackRange * 0.45 )

        return ( self:IsInRange( enemy, attackRange ) and !self:IsInRange( enemy, minHoldRange ) )
    end
	
	local function LambdaOnThink( self, wepent, isdead )
		if isdead or !TeamSystemEnabled() then return nil end
		
		ObjectiveStuckTick(self)
		
		local enemy = self:GetEnemy()
		if teamsEnabled:GetBool() and IsValid( enemy ) and LambdaTeams:AreTeammates( self, enemy ) then
			self:SetEnemy( nil )
			if self.CancelMovement then self:CancelMovement() end
		end

		if self.IsLambdaPlayer and self.l_TeamName
			and kdLambdaSeekTags and kdLambdaSeekTags:GetBool()
			and LambdaTeams and LambdaTeams.GetCurrentGamemodeID
			and ( LambdaTeams:GetCurrentGamemodeID() == 4 or LambdaTeams:GetCurrentGamemodeID() == 7 )
		then
			local canSeekNow = ( kdLambdaSeekInCombat and kdLambdaSeekInCombat:GetBool() ) or !self:InCombat()

			if canSeekNow then
				local now = CurTime()
				local nextSeek = ( self.l_NextKDTagSeekT or 0 )

				if now >= nextSeek then
					local interval = ( kdLambdaSeekInterval and kdLambdaSeekInterval:GetFloat() ) or 0.35
					if interval < 0.05 then interval = 0.05 end
					self.l_NextKDTagSeekT = now + interval

					local range = ( kdLambdaSeekRange and kdLambdaSeekRange:GetInt() ) or 1500
					if range < 200 then range = 200 end

					local myTeam = self.l_TeamName or ""
					local myPos  = self:WorldSpaceCenter()

					local bestConfirm, bestConfirmDist
					local bestDeny, bestDenyDist

					local tags = self:FindInSphere( nil, range, function( ent )
						if !IsValid( ent ) then return false end
						local class = ent:GetClass()
						return ( class == "lambda_kd_tag" or class == "lambda_salvage_tag" )
					end )

					if tags and #tags > 0 then
						for _, tag in ipairs( tags ) do
							if !IsValid( tag ) then continue end
							if tag.Collected then continue end

							local victimTeam = tag.VictimTeam
							if !victimTeam or victimTeam == "" then
								victimTeam = tag:GetNW2String( "LTS_KD_VictimTeam", "" )
								if victimTeam == "" then victimTeam = tag:GetNWString( "LTS_KD_VictimTeam", "" ) end
							end
							if victimTeam == "" then continue end

							local d = myPos:DistToSqr( tag:WorldSpaceCenter() )

							if victimTeam != myTeam then
								if !bestConfirmDist or d < bestConfirmDist then
									bestConfirm = tag
									bestConfirmDist = d
								end
							else
								if !bestDenyDist or d < bestDenyDist then
									bestDeny = tag
									bestDenyDist = d
								end
							end
						end
					end

					local chosen = bestConfirm or bestDeny
					if IsValid( chosen ) then
						self.l_KD_TargetTag = chosen
						self.l_KD_TargetPos = chosen:GetPos()

						if self.CancelMovement then self:CancelMovement() end
						self.l_NextEnemyTeamSearchT = now + 0.75

						return nil -- PLEASE DO NOT TOUCH THIS, IT IS HOW THE WORLD REVOLVES
					else
						self.l_KD_TargetTag = nil
						self.l_KD_TargetPos = nil
					end
				end
			end
		else
			self.l_KD_TargetTag = nil
			self.l_KD_TargetPos = nil
		end
		
		-- Are you tired of seeing lambdas doing other BULLSHIT rather than playing objectives? This is gonna rock your socks!
        local gmID = (LambdaTeams and LambdaTeams.GetCurrentGamemodeID and LambdaTeams:GetCurrentGamemodeID()) or 0

		if gmID == 1 and adBotObjective:GetBool() then
			if (self.l_ObjRetryAt or 0) > CurTime() then
				elseif (not adBotObjectiveInCombat:GetBool()) and self:InCombat() then
					else
				
				if (self.l_ObjCommitUntil or 0) > CurTime() then
					if IsValid(self.l_AD_TargetPoint) and self.l_AD_TargetPos then
					else
						self.l_ObjCommitUntil = 0
					end
				end

				if CurTime() >= (self.l_NextADObjectiveT or 0) and (self.l_ObjCommitUntil or 0) <= CurTime() then
					self.l_NextADObjectiveT = CurTime() + Rand(0.8, 1.8)

					local myTeam = self.l_TeamName or (LambdaTeams:GetPlayerTeam(self) or "")
					if myTeam ~= "" then
						EnsureRole_AD(self)
						local role = self.l_AD_Role

						local maxDist = adBotObjectiveRange:GetInt()
						local maxDistSqr = maxDist * maxDist
						local myPos = self:WorldSpaceCenter()

						local bestPoint, bestScore = nil, -math.huge

						for _, point in ipairs(ents.FindByClass("lambda_koth_point")) do
							if not IsValid(point) then continue end

							local ppos = point:WorldSpaceCenter()
							local distSqr = myPos:DistToSqr(ppos)
							if distSqr > maxDistSqr then continue end

							local captured = (point.GetIsCaptured and point:GetIsCaptured()) or false
							local capturer = (point.GetCapturerName and point:GetCapturerName()) or ""

							local contested = (point.IsContested and point:IsContested()) or false
							local capPct = (point.GetCapturePercent and point:GetCapturePercent()) or 100

							local score = -distSqr

							if captured and capturer == myTeam then
								if contested or capPct < 99.9 then
									score = score + 10000000
								else
									score = score + 250000
								end
							else
								if (not captured) or capturer == "" or capturer == "Neutral" then
									score = score + 8000000
								else
									score = score + 9500000
								end
							end

							if role == "defend" then
								if captured and capturer == myTeam then
									score = score + 9000000
								else
									score = score - 2500000
								end
							elseif role == "attack" then
								if (not captured) or capturer == "" or capturer == "Neutral" or capturer ~= myTeam then
									score = score + 9000000
								else
									score = score - 2000000
								end
							elseif role == "roam" then
								score = score - 1500000
							end
							
							local tgtCount = 0
							for _, lb in ipairs(GetLambdaPlayers()) do
								if lb ~= self and lb.l_AD_TargetPoint == point then
									tgtCount = tgtCount + 1
								end
							end
							score = score - (tgtCount * adBotStackPenalty:GetInt())

							if score > bestScore then
								bestScore = score
								bestPoint = point
							end
						end

						if IsValid(bestPoint) then
							self.l_AD_TargetPoint = bestPoint
							self.l_AD_TargetPos = bestPoint:GetPos()

							self.l_KOTH_Entity = bestPoint

							self.l_ObjCommitUntil = CurTime() + objCommitTime:GetFloat()

							if self.CancelMovement then self:CancelMovement() end
						end
					end
				end
			end
		else
			self.l_AD_TargetPoint = nil
			self.l_AD_TargetPos = nil
		end

		if gmID == 2 and ctfBotObjective:GetBool() then
			if (self.l_ObjRetryAt or 0) > CurTime() then
				elseif (not ctfBotObjectiveInCombat:GetBool()) and self:InCombat() then
			else
			
				if (self.l_ObjCommitUntil or 0) > CurTime() then
					if (IsValid(self.l_CTF_TargetEnt) and self.l_CTF_TargetPos) then
					else
						self.l_ObjCommitUntil = 0
					end
				end

				if CurTime() >= (self.l_NextCTFObjectiveT or 0) and (self.l_ObjCommitUntil or 0) <= CurTime() then
					self.l_NextCTFObjectiveT = CurTime() + Rand(0.8, 1.8)

					local myTeam = self.l_TeamName or (LambdaTeams:GetPlayerTeam(self) or "")
					if myTeam ~= "" then
						self.l_CTF_Team = myTeam

						local maxDist = ctfBotObjectiveRange:GetInt()
						local maxDistSqr = maxDist * maxDist
						local myPos = self:WorldSpaceCenter()

						local myFlag = nil
						local enemyFlags = {}

						for _, flag in ipairs(ents.FindByClass("lambda_ctf_flag")) do
							if not IsValid(flag) then continue end
							if flag:GetTeamName() == myTeam then
								myFlag = flag
							else
								enemyFlags[#enemyFlags + 1] = flag
							end
						end
						if not IsValid(myFlag) then return nil end

						local myFlagAtHome = myFlag:GetIsAtHome()

						EnsureRole_CTF(self, myFlagAtHome)
						local role = self.l_CTF_Role

						if myFlagAtHome then
							local defenderCount = 0
							for _, lb in ipairs(GetLambdaPlayers()) do
								if lb ~= self and lb.l_CTF_Team == myTeam and lb.l_CTF_Role == "defend" then
									defenderCount = defenderCount + 1
								end
							end

							if defenderCount < ctfMinDefenders:GetInt() then
								role = "defend"
								self.l_CTF_Role = "defend"
								self.l_CTF_RoleUntil = CurTime() + math.Rand(15, 30)
							end
						end

						local heldEnemyFlag = nil
						for _, ef in ipairs(enemyFlags) do
							if IsValid(ef) and ef:GetIsPickedUp() and ef:GetFlagHolderEnt() == self then
								heldEnemyFlag = ef
								break
							end
						end

						local targetEnt, targetPos

						if IsValid(heldEnemyFlag) then
							if not myFlagAtHome then
								local holder = myFlag:GetFlagHolderEnt()
								if IsValid(holder) then
									targetEnt = holder
									targetPos = holder:WorldSpaceCenter()
								else
									targetEnt = myFlag
									targetPos = myFlag:WorldSpaceCenter()
								end
							else
								targetEnt = myFlag
								targetPos = myFlag:WorldSpaceCenter()
							end
						else
							if role == "defend" then
								if myFlagAtHome then
									targetEnt = myFlag
									targetPos = myFlag:WorldSpaceCenter()
								else
									local holder = myFlag:GetFlagHolderEnt()
									targetEnt = IsValid(holder) and holder or myFlag
									targetPos = IsValid(holder) and holder:WorldSpaceCenter() or myFlag:WorldSpaceCenter()
								end

							elseif role == "hunt" then
								if not myFlagAtHome then
									local holder = myFlag:GetFlagHolderEnt()
									targetEnt = IsValid(holder) and holder or myFlag
									targetPos = IsValid(holder) and holder:WorldSpaceCenter() or myFlag:WorldSpaceCenter()
								end

							elseif role == "escort" then
								for _, ef in ipairs(enemyFlags) do
									local holder = IsValid(ef) and ef:GetFlagHolderEnt() or nil
									if IsValid(holder) then
										local holderTeam = LambdaTeams:GetPlayerTeam(holder) or ""
										if holderTeam == myTeam then
											targetEnt = holder
											targetPos = holder:WorldSpaceCenter()
											break
										end
									end
								end

							end

							if not targetPos then
								local bestScore, bestEnt, bestPos = -math.huge, nil, nil

								if not myFlagAtHome then
									local holder = myFlag:GetFlagHolderEnt()
									if IsValid(holder) then
										bestEnt = holder
										bestPos = holder:WorldSpaceCenter()
										bestScore = 999999999
									else
										bestEnt = myFlag
										bestPos = myFlag:WorldSpaceCenter()
										bestScore = 999999999
									end
								else
									for _, ef in ipairs(enemyFlags) do
										if not IsValid(ef) then continue end

										local distSqr = myPos:DistToSqr(ef:GetPos())
										if distSqr > maxDistSqr then continue end

										local score = -distSqr
										local isHome = ef:GetIsAtHome()
										local holder = ef:GetFlagHolderEnt()

										if IsValid(holder) then
											local holderTeam = LambdaTeams:GetPlayerTeam(holder) or ""
											if holderTeam == myTeam then
												score = score + 3000000
												if score > bestScore then
													bestScore, bestEnt, bestPos = score, holder, holder:WorldSpaceCenter()
												end
											else
												score = score + 8500000
												if score > bestScore then
													bestScore, bestEnt, bestPos = score, holder, holder:WorldSpaceCenter()
												end
											end
										else
											if not isHome then
												score = score + 9500000
												if score > bestScore then
													bestScore, bestEnt, bestPos = score, ef, ef:WorldSpaceCenter()
												end
											else
												score = score + 6500000
												if score > bestScore then
													bestScore, bestEnt, bestPos = score, ef, ef:WorldSpaceCenter()
												end
											end
										end
									end
								end

								targetEnt, targetPos = bestEnt, bestPos
							end
						end

						if targetPos then
							self.l_CTF_TargetEnt = targetEnt
							self.l_CTF_TargetPos = targetPos

							self.l_ObjCommitUntil = CurTime() + objCommitTime:GetFloat()

							if self.CancelMovement then self:CancelMovement() end
						end
					end
				end
			end
		else
			self.l_CTF_TargetEnt = nil
			self.l_CTF_TargetPos = nil
		end

		if gmID != 0 and CurTime() >= ( self.l_NextEnemyTeamSearchT or 0 ) then
			self.l_NextEnemyTeamSearchT = CurTime() + Rand( 0.1, 0.5 )

			local kothEnt = self.l_KOTH_Entity
			if ( self.l_TeamName and LambdaTeams:AreTeamsHostile() ) or IsValid( kothEnt ) then

				local myPos = self:WorldSpaceCenter()
				local myForward = self:GetForward()

				local validEnemy = ( self:InCombat() and IsValid( self:GetEnemy() ) )
				local eneDist = nil

				if validEnemy then
					local ene = self:GetEnemy()
					if IsValid( ene ) then
						eneDist = myPos:DistToSqr( ene:WorldSpaceCenter() )
					end
				end

				local dotView = ( validEnemy and 0.33 or 0.5 )

				local surroundings = self:FindInSphere( nil, 2000, function( ent )
					if !LambdaIsValid( ent ) then return false end

					local entPos = ent:WorldSpaceCenter()
					local los = entPos - myPos
					los.z = 0
					los:Normalize()

					if los:Dot( myForward ) < dotView then return false end
					if eneDist and myPos:DistToSqr( entPos ) >= eneDist then return false end
					if !self:CanTarget( ent ) or !self:CanSee( ent ) then return false end

					local myTeam  = self.l_TeamName or ""
					local entTeam = ent.l_TeamName or ""
					if myTeam != "" and entTeam != "" then
						if LambdaTeams:IsAOSExempt( myTeam, entTeam ) then
							return false
						end
					end

					local areTeammates = LambdaTeams:AreTeammates( self, ent )
					if areTeammates == false then return true end

					if areTeammates == nil and IsValid( kothEnt )
						and kothEnt == ent.l_KOTH_Entity
						and ent:IsInRange( kothEnt, 1000 )
					then
						return true
					end

					return false
				end )

				if surroundings and #surroundings > 0 then
					local pick = surroundings[ random( #surroundings ) ]
					if LambdaIsValid( pick ) then
						self:AttackTarget( pick )
					end
				end
			end
		end
		
		if gmID == 0 and CurTime() >= ( self.l_NextEnemyTeamSearchT or 0 ) then
            self.l_NextEnemyTeamSearchT = CurTime() + Rand( 0.25, 0.8 )

            local sawTarget = false

            if attackOthers:GetBool() then
                local target = LTS_FindNearestEnemyTeamTarget( self, LTS_GetAOSSightRange(), true, true )
                if IsValid( target ) then
                    self:AttackTarget( target )
                    self.l_combatendtime = math.max( self.l_combatendtime or 0, CurTime() + LTS_GetCommitTime() )
                    sawTarget = true
                end
            end

            if !sawTarget and huntDown:GetBool() and !self:InCombat() then
                local target = LTS_FindNearestEnemyTeamTarget( self, LTS_GetHuntRange(), false, false )
                if IsValid( target ) then
                    self:AttackTarget( target )
                    self.l_combatendtime = math.max( self.l_combatendtime or 0, CurTime() + LTS_GetCommitTime() )
                    sawTarget = true
                end
            end

            if stickTogether:GetBool() and !self:InCombat() and !LTS_HasObjectiveTarget( self ) then
                local regroupDist = LTS_GetRegroupDistance()
                local mate, dist = LTS_FindNearestTeammate( self, math.max( regroupDist * 2, 900 ) )

                if IsValid( mate ) and dist and dist >= ( regroupDist * regroupDist ) then
                    self.l_TeamMovePos = mate:GetPos() + VectorRand() * 120
                    if self.CancelMovement then self:CancelMovement() end
                else
                    self.l_TeamMovePos = nil
                end
            else
                self.l_TeamMovePos = nil
            end
        elseif gmID != 0 then
            self.l_TeamMovePos = nil
        end
		
        if gmID == 5 and hqBotObjective:GetBool() then
            if (self.l_ObjRetryAt or 0) <= CurTime() and ( (hqBotObjectiveInCombat:GetBool()) or (not self:InCombat()) ) then
                if (self.l_ObjCommitUntil or 0) > CurTime() then
                    if not self.l_HQ_TargetPos then self.l_ObjCommitUntil = 0 end
                end

                if CurTime() >= (self.l_NextHQObjectiveT or 0) and (self.l_ObjCommitUntil or 0) <= CurTime() then
                    self.l_NextHQObjectiveT = CurTime() + Rand(0.8, 1.8)

                    local obj = (LambdaTeams and LambdaTeams.GetHQObjective and LambdaTeams:GetHQObjective())
                    if IsValid( obj ) then
                        local myPos = self:WorldSpaceCenter()
                        local oPos = obj:WorldSpaceCenter()

                        local maxDist = hqBotObjectiveRange:GetInt()
                        if maxDist > 0 and myPos:DistToSqr( oPos ) <= ( maxDist * maxDist ) then
                            local stack = 0
                            for _, lb in ipairs( GetLambdaPlayers() ) do
                                if lb ~= self and lb.l_HQ_TargetEnt == obj then
                                    stack = stack + 1
                                end
                            end

                            self.l_HQ_TargetEnt = obj
                            self.l_HQ_TargetPos = obj:GetPos()
                            self.l_ObjCommitUntil = CurTime() + objCommitTime:GetFloat()

                            if stack > 0 then
                                self.l_ObjCommitUntil = self.l_ObjCommitUntil - math.min( 1.5, stack * 0.15 )
                            end

                            if self.CancelMovement then self:CancelMovement() end
                        end
                    else
                        self.l_HQ_TargetEnt = nil
                        self.l_HQ_TargetPos = nil
                    end
                end
            end
        else
            self.l_HQ_TargetEnt = nil
            self.l_HQ_TargetPos = nil
        end
		
		if gmID == 6 then
			if CurTime() >= ( self.l_NextASObjectiveT or 0 ) and ( self.l_ObjCommitUntil or 0 ) <= CurTime() then
				self.l_NextASObjectiveT = CurTime() + Rand( 0.8, 1.6 )

				EnsureRole_AS( self )

				local point
				if self.l_AS_Role == "defend" and LambdaTeams.GetAssaultDefensePoint then
					point = LambdaTeams:GetAssaultDefensePoint( self.l_TeamName )
				end
				if !IsValid( point ) and LambdaTeams.GetAssaultAttackPoint then
					point = LambdaTeams:GetAssaultAttackPoint( self.l_TeamName )
					self.l_AS_Role = "attack"
				end

				if IsValid( point ) then
					self.l_AS_TargetEnt = point
					self.l_AS_TargetPos = point:GetPos() + ( self.l_AS_Role == "defend" and VectorRand() * 120 or vector_origin )
					self.l_ObjCommitUntil = CurTime() + objCommitTime:GetFloat()

					if self.CancelMovement then self:CancelMovement() end
				else
					self.l_AS_TargetEnt = nil
					self.l_AS_TargetPos = nil
				end
			end
		else
			self.l_AS_TargetEnt = nil
			self.l_AS_TargetPos = nil
		end

        if gmID == 7 then
            local myTeam = self.l_TeamName or ( LambdaTeams:GetPlayerTeam( self ) or "" )

            if myTeam != "" then
                local now = CurTime()
                local carry = ( LambdaTeams.GetSalvageCarry and LambdaTeams:GetSalvageCarry( self ) ) or 0
                local allowCombatBank = ( salvageBankInCombat and salvageBankInCombat:GetBool() ) or false

                EnsureRole_SR( self )

                if carry > 0 and ( allowCombatBank or !self:InCombat() ) then
                    local bank = ( LambdaTeams.GetNearestSalvageBank and LambdaTeams:GetNearestSalvageBank( myTeam, self:GetPos() ) )
                    if IsValid( bank ) then
                        self.l_SR_TargetEnt = bank
                        self.l_SR_TargetPos = bank:GetPos()
                        self.l_ObjCommitUntil = now + objCommitTime:GetFloat()

                        if self.CancelMovement then self:CancelMovement() end
                    else
                        self.l_SR_TargetEnt = nil
                        self.l_SR_TargetPos = nil
                    end

                elseif salvageBankFirstCapture and salvageBankFirstCapture:GetBool()
                and LambdaTeams.TeamHasSalvageBank and !LambdaTeams:TeamHasSalvageBank( myTeam ) then
                    local point = ( LambdaTeams.GetBestSalvageCaptureBank and LambdaTeams:GetBestSalvageCaptureBank( myTeam, self:GetPos() ) )
                    if IsValid( point ) then
                        self.l_SR_TargetEnt = point
                        self.l_SR_TargetPos = point:GetPos()
                        self.l_ObjCommitUntil = now + objCommitTime:GetFloat()

                        if self.CancelMovement then self:CancelMovement() end
                    else
                        self.l_SR_TargetEnt = nil
                        self.l_SR_TargetPos = nil
                    end

                elseif salvageGuardBanks and salvageGuardBanks:GetBool()
                and self.l_SR_Role == "guard"
                and LambdaTeams.TeamHasSalvageBank and LambdaTeams:TeamHasSalvageBank( myTeam ) then
                    local bank = ( LambdaTeams.GetNearestSalvageBank and LambdaTeams:GetNearestSalvageBank( myTeam, self:GetPos() ) )
                    if IsValid( bank ) then
                        local bankPos = bank:GetPos()
                        local distSqr = self:GetPos():DistToSqr( bankPos )

                        self.l_SR_TargetEnt = bank
                        self.l_SR_TargetPos = ( distSqr <= ( 300 * 300 ) and ( bankPos + VectorRand() * 140 ) or bankPos )
                        self.l_ObjCommitUntil = now + math.min( 1.6, objCommitTime:GetFloat() )

                        if self.CancelMovement then self:CancelMovement() end
                    else
                        self.l_SR_TargetEnt = nil
                        self.l_SR_TargetPos = nil
                    end

                else
                    self.l_SR_TargetEnt = nil
                    self.l_SR_TargetPos = nil
                end
            else
                self.l_SR_TargetEnt = nil
                self.l_SR_TargetPos = nil
            end
        else
            self.l_SR_TargetEnt = nil
            self.l_SR_TargetPos = nil
        end

        if gmID == 8 then
            local now = CurTime()

            if now >= ( self.l_NextSABObjectiveT or 0 ) and ( self.l_ObjCommitUntil or 0 ) <= now then
                local ownSite = ( LambdaTeams.GetSabotageSite and LambdaTeams:GetSabotageSite( self.l_TeamName ) )
                local ownDestroyed = (
                    !IsValid( ownSite )
                    or ownSite:GetNW2Bool( "LTS_SAB_Destroyed", ownSite:GetNWBool( "LTS_SAB_Destroyed", false ) )
                )

                local ownArmed = (
                    IsValid( ownSite )
                    and !ownDestroyed
                    and ownSite:GetNW2Bool( "LTS_SAB_Armed", ownSite:GetNWBool( "LTS_SAB_Armed", false ) )
                )

                local defendThreat = (
                    IsValid( ownSite )
                    and !ownDestroyed
                    and LTS_FindSabotageThreat( ownSite, self.l_TeamName, 800 )
                ) or nil

                local target, targetPos, mode

                if ownArmed or IsValid( defendThreat ) then
                    target = ownSite
                    mode = "defend"

                    if IsValid( defendThreat ) then
                        targetPos = defendThreat:GetPos()

                        if self:CanTarget( defendThreat ) and ( self:IsInRange( defendThreat, 900 ) or self:CanSee( defendThreat ) ) then
                            self:AttackTarget( defendThreat )
                        end
                    else
                        targetPos = ownSite:GetPos() + VectorRand() * 64
                    end

                    self.l_NextSABObjectiveT = now + 0.25
                else
                    target = LTS_PickSabotageAttackSite( self )
                        or ( LambdaTeams.GetNearestEnemySabotageSite and LambdaTeams:GetNearestEnemySabotageSite( self.l_TeamName, self:GetPos() ) )

                    mode = "attack"

                    if IsValid( target ) then
                        local sitePos = target:GetPos()
                        local distSqr = self:GetPos():DistToSqr( sitePos )

                        if distSqr <= ( 325 * 325 ) then
                            targetPos = sitePos + VectorRand() * 90
                            self.l_NextSABObjectiveT = now + 0.35
                        else
                            targetPos = sitePos
                            self.l_NextSABObjectiveT = now + Rand( 0.8, 1.5 )
                        end
                    else
                        self.l_NextSABObjectiveT = now + 1.0
                    end
                end

                self.l_SAB_Mode = mode

                if IsValid( target ) then
                    self.l_SAB_TargetEnt = target
                    self.l_SAB_TargetPos = targetPos or target:GetPos()
                    self.l_ObjCommitUntil = now + ( mode == "defend" and min( 1.5, objCommitTime:GetFloat() ) or objCommitTime:GetFloat() )

                    if self.CancelMovement then self:CancelMovement() end
                else
                    self.l_SAB_TargetEnt = nil
                    self.l_SAB_TargetPos = nil
                end
            end
        else
            self.l_SAB_TargetEnt = nil
            self.l_SAB_TargetPos = nil
            self.l_SAB_Mode = nil
        end

		return nil -- DO NOT REMOVE THIS UNDER ANY CIRCUMSTANCE, WITHOUT IT = FUCKING DESTROY THE WHOLE ADDON
	end
	
	WeightedPick = function(weights)
		local total = 0
		for _, w in ipairs(weights) do total = total + math.max(0, w[2]) end
		if total <= 0 then return weights[1][1] end

		local roll = math.Rand(0, total)
		local acc = 0
		for _, w in ipairs(weights) do
			acc = acc + math.max(0, w[2])
			if roll <= acc then return w[1] end
		end
		return weights[#weights][1]
	end

	EnsureRole_AD = function(self)
		if self.l_AD_Role and (self.l_AD_RoleUntil or 0) > CurTime() then return end
		self.l_AD_RoleUntil = CurTime() + math.Rand(20, 45)

		self.l_AD_Role = WeightedPick({
			{ "defend", adRole_DefendWeight:GetInt() },
			{ "attack", adRole_AttackWeight:GetInt() },
			{ "roam",   adRole_RoamWeight:GetInt()   },
		})
	end

	EnsureRole_CTF = function( self, myFlagAtHome )
		if self.l_CTF_Role and ( self.l_CTF_RoleUntil or 0 ) > CurTime() then return end
		self.l_CTF_RoleUntil = CurTime() + math.Rand( 20, 45 )

		local defendW = ctfRole_DefendWeight:GetInt()
		local attackW = ctfRole_AttackWeight:GetInt()
		local escortW = ctfRole_EscortWeight:GetInt()
		local huntW   = ctfRole_HuntWeight:GetInt()

		local defendBoost = ( ctfDefendBoostWhenFlagTaken and ctfDefendBoostWhenFlagTaken:GetInt() ) or 0
		if !myFlagAtHome and defendBoost > 0 then
			defendW = defendW + defendBoost
		end

		self.l_CTF_Role = WeightedPick( {
			{ "defend", defendW },
			{ "attack", attackW },
			{ "escort", escortW },
			{ "hunt",   huntW   },
		} )
	end

	EnsureRole_AS = function( self )
		if self.l_AS_Role and ( self.l_AS_RoleUntil or 0 ) > CurTime() then return end
		self.l_AS_RoleUntil = CurTime() + math.Rand( 18, 38 )

		if assaultDefensiveRoles and assaultDefensiveRoles:GetBool() then
			self.l_AS_Role = WeightedPick( {
				{ "defend", 35 },
				{ "attack", 65 }
			} )
		else
			self.l_AS_Role = "attack"
		end
	end

	EnsureRole_SR = function( self )
		if self.l_SR_Role and ( self.l_SR_RoleUntil or 0 ) > CurTime() then return end
		self.l_SR_RoleUntil = CurTime() + math.Rand( 18, 38 )

		if salvageGuardBanks and salvageGuardBanks:GetBool() then
			self.l_SR_Role = WeightedPick( {
				{ "guard", 35 },
				{ "collect", 65 },
			} )
		else
			self.l_SR_Role = "collect"
		end
	end

	ObjectiveStuckTick = function(self)
		local tgt = self.l_AD_TargetPos
            or self.l_CTF_TargetPos
            or self.l_KD_TargetPos
            or self.l_HQ_TargetPos
			or self.l_AS_TargetPos
            or self.l_SR_TargetPos
            or self.l_SAB_TargetPos
		if not tgt then
			self.l_ObjLastPos = nil
			self.l_ObjStuckSince = nil
			return
		end

		local now = CurTime()
		local myPos = self:GetPos()

		if not self.l_ObjLastPos then
			self.l_ObjLastPos = myPos
			self.l_ObjStuckSince = now
			return
		end

		if now < (self.l_ObjNextStuckCheckT or 0) then return end
		self.l_ObjNextStuckCheckT = now + 0.5

		local moved = myPos:DistToSqr(self.l_ObjLastPos)
		local minMove = objStuckMove:GetInt()
		local minMoveSqr = minMove * minMove

		if moved >= minMoveSqr then
			self.l_ObjLastPos = myPos
			self.l_ObjStuckSince = now
			return
		end

		if (now - (self.l_ObjStuckSince or now)) >= objStuckTime:GetFloat() then
			self.l_AD_TargetPoint, self.l_AD_TargetPos = nil, nil
			self.l_CTF_TargetEnt,  self.l_CTF_TargetPos = nil, nil
            self.l_KD_TargetTag,  self.l_KD_TargetPos = nil, nil
            self.l_HQ_TargetEnt,  self.l_HQ_TargetPos = nil, nil
			self.l_AS_TargetEnt,  self.l_AS_TargetPos = nil, nil
            self.l_SR_TargetEnt,  self.l_SR_TargetPos = nil, nil
            self.l_SAB_TargetEnt, self.l_SAB_TargetPos = nil, nil

			self.l_ObjRetryAt = now + objRepathCooldown:GetFloat()
			self.l_ObjLastPos = nil
			self.l_ObjStuckSince = nil

			if self.CancelMovement then self:CancelMovement() end
		end
	end

	local function LambdaCanTarget( self, ent )
		if TeamSystemEnabled() and LambdaTeams:AreTeammates( self, ent ) then
			return false
		end
	end

    local function LambdaOnAttackTarget( self, ent )
        if LambdaTeams and LambdaTeams.GetCurrentGamemodeID and LambdaTeams:GetCurrentGamemodeID() == 8 then
            local obj = self.l_SAB_TargetEnt
            if IsValid( obj ) and IsValid( ent ) and ent.GetPos then
                if ent:GetPos():DistToSqr( obj:GetPos() ) <= ( 750 * 750 ) then
                    return true
                end
            end
        end

        if self.l_HasFlag and ent.IsLambdaPlayer and !ent.l_HasFlag 
        and ( !ent:InCombat() or ent:GetEnemy() != self or !ent:IsInRange( self, 768 ) ) then 
            return true 
        end
    end

    local function LambdaOnInjured( self, dmginfo )
        local attacker = dmginfo:GetAttacker()
        if attacker == self or !LambdaTeams:AreTeammates( self, attacker ) 
        or !teamsEnabled:GetBool() then return end

        if noFriendFire:GetBool() then return true end
    end

    local function LambdaOnOtherInjured( self, victim, dmginfo, tookDamage )
        if teamsEnabled:GetBool() and LambdaTeams and LambdaTeams.GetCurrentGamemodeID
        and LambdaTeams:GetCurrentGamemodeID() == 8 then
            local attacker = dmginfo:GetAttacker()
            local ownSite = ( LambdaTeams.GetSabotageSite and LambdaTeams:GetSabotageSite( self.l_TeamName ) )

            if IsValid( attacker ) and IsValid( ownSite ) and !ownSite:GetNW2Bool( "LTS_SAB_Destroyed", ownSite:GetNWBool( "LTS_SAB_Destroyed", false ) ) then
                local ownSitePos = ownSite:GetPos()
                local victimNearSite = (
                    IsValid( victim )
                    and victim.GetPos
                    and victim:GetPos():DistToSqr( ownSitePos ) <= ( 850 * 850 )
                )

                if victim == ownSite or victimNearSite then
                    self.l_SAB_TargetEnt = ownSite
                    self.l_SAB_TargetPos = ownSitePos
                    self.l_SAB_Mode = "defend"
                    self.l_ObjCommitUntil = CurTime() + 1.5
                    self.l_NextSABObjectiveT = CurTime() + 0.2

                    if self.CancelMovement then self:CancelMovement() end

                    if self:CanTarget( attacker ) and ( self:IsInRange( attacker, random( 450, 900 ) ) or self:CanSee( attacker ) ) then
                        self:AttackTarget( attacker )
                        return
                    end
                end
            end
        end

        if !tookDamage or self:InCombat() or !teamsEnabled:GetBool() then return end

        local attacker = dmginfo:GetAttacker()
        if attacker == self or !LambdaIsValid( attacker ) then return end

        if LambdaTeams:AreTeammates( self, victim ) 
        and self:CanTarget( attacker ) 
        and ( self:IsInRange( victim, random(400,700) ) or self:CanSee( victim ) ) then
            self:AttackTarget( attacker )
            return
        end

        if LambdaTeams:AreTeammates( self, attacker ) 
        and self:CanTarget( victim ) 
        and ( self:IsInRange( attacker, random(400,700) ) or self:CanSee( attacker ) ) then
            self:AttackTarget( victim )
            return
        end
    end
	
	local function LambdaOnBeginMove(self, pos, ...)

		if (self.l_ObjRetryAt or 0) > CurTime() then return end
		if not teamsEnabled:GetBool() then return end
		if not LambdaTeams or not LambdaTeams.GetCurrentGamemodeID then return end

		local gmID = LambdaTeams:GetCurrentGamemodeID()
		if LTS_ShouldCamp( self ) then
            return self:GetPos()
        end

		if gmID == 1 and adBotObjective:GetBool() and self.l_AD_TargetPos then
			if (not adBotObjectiveInCombat:GetBool()) and self:InCombat() then return end
			return self.l_AD_TargetPos
		end

		if gmID == 2 and ctfBotObjective:GetBool() and self.l_CTF_TargetPos then
			if (not ctfBotObjectiveInCombat:GetBool()) and self:InCombat() then return end
			return self.l_CTF_TargetPos
			end

		if gmID == 4 and kdLambdaSeekTags:GetBool() and self.l_KD_TargetPos then return self.l_KD_TargetPos 
		end
		
        if gmID == 5 and hqBotObjective:GetBool() and self.l_HQ_TargetPos then
            if (not hqBotObjectiveInCombat:GetBool()) and self:InCombat() then return end
            return self.l_HQ_TargetPos
        end
		
		if gmID == 6 and self.l_AS_TargetPos then
			return self.l_AS_TargetPos
		end

        if gmID == 7 and self.l_SR_TargetPos then
            return self.l_SR_TargetPos
        end

        if gmID == 8 and self.l_SAB_TargetPos then
            return self.l_SAB_TargetPos
        end
		
		if gmID == 0 and self.l_TeamMovePos and !self:InCombat() then
            return self.l_TeamMovePos
        end

	end

    local function OnPlayerSpawn( ply, transition )
        if transition or !tobool( ply:GetInfo( "lambdaplayers_teamsystem_plyusespawnpoints" ) ) then return end

        local plyTeam = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
        local spawnPoint = LTS_SelectTeamSpawn( plyTeam == "" and nil or plyTeam )
        if IsValid( spawnPoint ) then
            ply:SetPos( spawnPoint:GetPos() )
            ply:SetEyeAngles( spawnPoint:GetAngles() )
        end
    end

	local function LTS_ChatAll(...)
		if LambdaPlayers_ChatAdd then
			LambdaPlayers_ChatAdd(nil, ...)
			return
		end

		local out = {}
		for _, v in ipairs({...}) do
			if isstring(v) then out[#out + 1] = v end
		end
		if #out > 0 then PrintMessage(HUD_PRINTTALK, table.concat(out, "")) end
	end

	local function LTS_ForEachTeamName(fn)
		if LambdaTeams and istable(LambdaTeams.TeamPoints) then
			for teamName, _ in pairs(LambdaTeams.TeamPoints) do
				if isstring(teamName) and teamName ~= "" then fn(teamName) end
			end
			return
		end

		local seen = {}
		for _, ply in ipairs(player.GetAll()) do
			local t = ply.l_TeamName
			if isstring(t) and t ~= "" and not seen[t] then
				seen[t] = true
				fn(t)
			end
		end
	end

	function LambdaTeams:HQ_AnnounceCaptured(capturingTeam)
		LTS_ChatAll(color_white, "[LTS] ", Color(255, 220, 60), "Headquarters secured by ", color_white, tostring(capturingTeam), color_white, "!")

		LTS_ForEachTeamName(function(tn)
			if tn == capturingTeam then
				self:PlayConVarSound("lambdaplayers_teamsystem_hq_snd_oncaptured_friendly", tn)
			else
				self:PlayConVarSound("lambdaplayers_teamsystem_hq_snd_oncaptured_enemy", tn)
			end
		end)
	end

	function LambdaTeams:HQ_AnnounceDestroyed(destroyerTeam, oldOwnerTeam, reason)
		local msg = "Headquarters destroyed!"
		if isstring(destroyerTeam) and destroyerTeam ~= "" then
			msg = "Headquarters destroyed by " .. destroyerTeam .. "!"
		elseif reason == "timeout" then
			msg = "Headquarters timed out!"
		end

		LTS_ChatAll(color_white, "[LTS] ", Color(255, 120, 120), msg)

		LTS_ForEachTeamName(function(tn)
			if oldOwnerTeam and oldOwnerTeam ~= "" and tn == oldOwnerTeam then
				self:PlayConVarSound("lambdaplayers_teamsystem_hq_snd_ondestroyed_friendly", tn)
			else
				self:PlayConVarSound("lambdaplayers_teamsystem_hq_snd_ondestroyed_enemy", tn)
			end
		end)
	end

	local function LTS_IsSuperAdmin( ply )
		return !IsValid( ply ) or ply:IsSuperAdmin()
	end

	local function CreateKDPickup( victim )
		if CLIENT then return end
		if not IsValid( victim ) then return end

		local victimTeam = LambdaTeams:GetPlayerTeam( victim )
		if not victimTeam or victimTeam == "" then
			victimTeam = team.GetName( victim:Team() )
		end
		if not victimTeam or victimTeam == "" then return end

		local pickup = ents.Create( "lambda_kd_tag" )
		if not IsValid( pickup ) then return end

		pickup:SetPos( victim:GetPos() + Vector( 0, 0, 45 ) )
		pickup:SetAngles( Angle( 0, math.random( 0, 360 ), 0 ) )

		local pickupDelay = math.max( 0, ( kdPickupEnableDelay and kdPickupEnableDelay:GetFloat() ) or 0.25 )
		local pickupEnableAt = CurTime() + pickupDelay

		pickup.RemoveAt = CurTime() + kdRemoveTime:GetInt()
		pickup.VictimTeam = victimTeam
		pickup.VictimEntIndex = victim:EntIndex()
		pickup.PickupEnableAt = pickupEnableAt


		local mdl = kdCustomMdl:GetString()
		if mdl ~= "" then
			pickup.TagModel = mdl
		end

		pickup:Spawn()
		pickup:Activate()
		
		pickup:SetNW2String( "LTS_KD_VictimTeam", victimTeam )
		pickup:SetNWString( "LTS_KD_VictimTeam", victimTeam )
		pickup:SetNWInt( "LTS_KD_VictimEntIndex", victim:EntIndex() )
		pickup:SetNWFloat( "LTS_KD_PickupEnableAt", pickupEnableAt )

		local finalModel = ( mdl ~= "" and mdl or "models/props_lab/reciever01d.mdl" )
		if pickup:GetModel() ~= finalModel then
			pickup:SetModel( finalModel )
			pickup:SetModelScale( 0.85, 0 )
			pickup:PhysicsInit( SOLID_VPHYSICS )
			pickup:SetMoveType( MOVETYPE_VPHYSICS )
			pickup:SetSolid( SOLID_VPHYSICS )

			local phys = pickup:GetPhysicsObject()
			if IsValid( phys ) then phys:Wake() end
		end

	end

	local function CreateSalvagePickup( victim )
		if CLIENT then return end
		if not IsValid( victim ) then return end

		local victimTeam = LambdaTeams:GetPlayerTeam( victim )
		if not victimTeam or victimTeam == "" then
			victimTeam = team.GetName( victim:Team() )
		end
		if not victimTeam or victimTeam == "" then return end

		local pickupdos = ents.Create( "lambda_salvage_tag" )
		if not IsValid( pickupdos ) then return end

		pickupdos:SetPos( victim:GetPos() + Vector( 0, 0, 45 ) )
		pickupdos:SetAngles( Angle( 0, math.random( 0, 360 ), 0 ) )

		local pickupDelay = math.max( 0, ( salvagePickupEnableDelay and salvagePickupEnableDelay:GetFloat() ) or 0.25 )
		local pickupEnableAt = CurTime() + pickupDelay

		pickupdos.RemoveAt = CurTime() + salvageRemoveTime:GetInt()
		pickupdos.VictimTeam = victimTeam
		pickupdos.VictimEntIndex = victim:EntIndex()
		pickupdos.PickupEnableAt = pickupEnableAt


		local mdl = salvageCustomMdl:GetString()
		if mdl ~= "" then
			pickupdos.TagModel = mdl
		end

		pickupdos:Spawn()
		pickupdos:Activate()
		
		pickupdos:SetNW2String( "LTS_KD_VictimTeam", victimTeam )
		pickupdos:SetNWString( "LTS_KD_VictimTeam", victimTeam )
		pickupdos:SetNWInt( "LTS_KD_VictimEntIndex", victim:EntIndex() )
		pickupdos:SetNWFloat( "LTS_KD_PickupEnableAt", pickupEnableAt )

		local finalModel = ( mdl ~= "" and mdl or "models/props_lab/reciever01d.mdl" )
		if pickupdos:GetModel() ~= finalModel then
			pickupdos:SetModel( finalModel )
			pickupdos:SetModelScale( 0.85, 0 )
			pickupdos:PhysicsInit( SOLID_VPHYSICS )
			pickupdos:SetMoveType( MOVETYPE_VPHYSICS )
			pickupdos:SetSolid( SOLID_VPHYSICS )

			local phys = pickupdos:GetPhysicsObject()
			if IsValid( phys ) then phys:Wake() end
		end

	end

	local function LTS_SyncEnabledToClients()
		SetGlobalBool( "LambdaTeamSystem_Enabled", TeamSystemEnabled() )
	end

	LTS_SyncEnabledToClients()
	hook.Add( "Initialize", "LTS_SyncEnabled_Init", LTS_SyncEnabledToClients )

	cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_enable", "LTS_SyncEnabled_CVar" )
	cvars.AddChangeCallback( "lambdaplayers_teamsystem_enable", function()
		LTS_SyncEnabledToClients()
	end, "LTS_SyncEnabled_CVar" )

	hook.Add( "PlayerInitialSpawn", "Lambda_TeamSystem_PlayerInitialSpawnSync", function( ply )
		timer.Simple( 0, function()
			if IsValid( ply ) then
				LTS_ApplyPlayerLambdaTeam( ply )
			end
		end )
	end )
	
	hook.Add( "PlayerChangedTeam", "Lambda_TeamSystem_PlayerChangedTeamSync", function( ply )
        timer.Simple( 0, function()
            if IsValid( ply ) then
                LTS_ApplyPlayerLambdaTeam( ply )
            end
        end )
    end )

	hook.Add( "PlayerSpawn", "Lambda_TeamSystem_PlayerSpawnSync", function( ply )
		timer.Simple( 0, function()
			if IsValid( ply ) then
				LTS_ApplyPlayerLambdaTeam( ply )
			end
		end )
	end )

	hook.Add( "EntityTakeDamage", "Lambda_TeamSystem_NoFriendlyFireGlobal", function( target, dmginfo )
		if !TeamSystemEnabled() or !noFriendFire:GetBool() then return end
		if !IsValid( target ) then return end

		local attacker = dmginfo:GetAttacker()
		if !IsValid( attacker ) or attacker == target then return end

		if !LambdaTeams:AreTeammates( target, attacker ) then return end

		dmginfo:SetDamage( 0 )
		return true
	end )

    local function LambdaOnKilled( lambda, dmginfo )
		local gamemodeID = LambdaTeams:GetCurrentGamemodeID()
		
		if gamemodeID == 1 and GetGlobalBool( "LambdaTeamMatch_IsConquest", false ) then
			local cv = GetConVar( "lambdaplayers_teamsystem_conquest_killdrain" )
			local drain = ( cv and cv:GetInt() or 1 )

			if drain > 0 then
				local victimTeam = LambdaTeams:GetPlayerTeam( lambda )
				if victimTeam then LambdaTeams:AddTeamPoints( victimTeam, -drain ) end
			end
		end

		if gamemodeID == 3 then
			local attackerTeam = LambdaTeams:GetPlayerTeam( dmginfo:GetAttacker() )
			if attackerTeam then LambdaTeams:AddTeamPoints( attackerTeam, 1 ) end

		elseif gamemodeID == 4 then
			CreateKDPickup( lambda )

		elseif gamemodeID == 7 then
			CreateSalvagePickup( lambda )

			if LambdaTeams.OnSalvageCarrierKilled then
				LambdaTeams:OnSalvageCarrierKilled( lambda )
			end
		end
	end

	local function OnPlayerDeath( ply, inflictor, attacker )
		local gamemodeID = LambdaTeams:GetCurrentGamemodeID()
		
		if gamemodeID == 1 and GetGlobalBool( "LambdaTeamMatch_IsConquest", false ) then
			local cv = GetConVar( "lambdaplayers_teamsystem_conquest_killdrain" )
			local drain = ( cv and cv:GetInt() or 1 )

			if drain > 0 then
				local victimTeam = LambdaTeams:GetPlayerTeam( ply )
				if victimTeam then LambdaTeams:AddTeamPoints( victimTeam, -drain ) end
			end
		end


		if gamemodeID == 3 then
			local attackerTeam = LambdaTeams:GetPlayerTeam( attacker )
			if attackerTeam then LambdaTeams:AddTeamPoints( attackerTeam, 1 ) end

		elseif gamemodeID == 4 then
			CreateKDPickup( ply )

		elseif gamemodeID == 7 then
			CreateSalvagePickup( ply )

			if LambdaTeams.OnSalvageCarrierKilled then
				LambdaTeams:OnSalvageCarrierKilled( ply )
			end
		end
	end

    hook.Add( "PlayerSpawnedNPC", modulePrefix .. "OnPlayerSpawnedNPC", OnPlayerSpawnedNPC )
    hook.Add( "LambdaOnInitialize", modulePrefix .. "LambdaOnInitialize", LambdaOnInitialize )
    hook.Add( "LambdaPostRecreated", modulePrefix .. "LambdaPostRecreated", LambdaPostRecreated )
    hook.Add( "LambdaOnRespawn", modulePrefix .. "LambdaOnRespawn", LambdaOnRespawn )
    hook.Add( "LambdaOnThink", modulePrefix .. "OnThink", LambdaOnThink )
    hook.Add( "LambdaCanTarget", modulePrefix .. "OnCanTarget", LambdaCanTarget )
    hook.Add( "LambdaOnAttackTarget", modulePrefix .. "OnAttackTarget", LambdaOnAttackTarget )
    hook.Add( "LambdaOnInjured", modulePrefix .. "OnInjured", LambdaOnInjured )
    hook.Add( "LambdaOnKilled", modulePrefix .. "OnKilled", LambdaOnKilled )
    hook.Add( "LambdaOnOtherInjured", modulePrefix .. "OnOtherInjured", LambdaOnOtherInjured )
    hook.Add( "LambdaOnBeginMove", modulePrefix .. "OnBeginMove", LambdaOnBeginMove )
    hook.Add( "LambdaCanSwitchWeapon", modulePrefix .. "LambdaCanSwitchWeapon", LambdaCanSwitchWeapon )
    hook.Add( "PlayerSpawn", modulePrefix .. "OnPlayerSpawn", OnPlayerSpawn )
    hook.Add( "PlayerDeath", modulePrefix .. "OnPlayerDeath", OnPlayerDeath )

	end
