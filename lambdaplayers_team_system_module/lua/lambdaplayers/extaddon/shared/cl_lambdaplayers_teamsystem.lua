if ( CLIENT ) then

    local LocalPlayer = LocalPlayer
    local GetConVar = GetConVar
    local surface = surface
    local PlayClientSound = surface.PlaySound
    local file_Find = file.Find
    local string_Replace = string.Replace
    local string_EndsWith = string.EndsWith
    local FormattedTime = string.FormattedTime
    local SimpleTextOutlined = draw.SimpleTextOutlined
    local DrawText = draw.DrawText
    local ScrW = ScrW
    local ScrH = ScrH
    local TraceLine = util.TraceLine
    local table_IsEmpty = table.IsEmpty
    local AddHalo = halo.Add
    local LerpVector = LerpVector
    local vec_white = Vector( 1, 1, 1 )
    local CreateFont = surface.CreateFont
    local table_Add = table.Add
	
	local random = math.random
	local table_Empty = table.Empty
	local ents_FindByClass = ents.FindByClass
	local player_GetAll = player.GetAll
	
    local modulePrefix = "Lambda_TeamSystem_"

    local playerTeam, drawTeamName, drawHalo, drawTeamNameMaxDist, drawHaloMaxDist, hudScoreRefresh
    local kothIconEnabled, kothIconDrawVisible, kothIconFadeStartDist, kothIconFadeEndDist
    local ctfIconEnabled, ctfIconDrawVisible, ctfIconFadeStartDist, ctfIconFadeEndDist
    local kdPickupSounds, kdDrawWorldText, kdWorldTextDist, kdDrawHalo
	local hqIconEnabled, hqIconDrawVisible, hqIconFadeStartDist, hqIconFadeEndDist
	local assaultIconEnabled, assaultIconDrawVisible, assaultIconFadeStartDist, assaultIconFadeEndDist
	local assaultDrawWorldText, assaultWorldTextDist, assaultDrawHalo
    local uiScale

    local function RefreshClientConVars()
        playerTeam = playerTeam or GetConVar( "lambdaplayers_teamsystem_playerteam" )
        drawTeamName = drawTeamName or GetConVar( "lambdaplayers_teamsystem_drawteamname" )
        drawHalo = drawHalo or GetConVar( "lambdaplayers_teamsystem_drawhalo" )
        drawTeamNameMaxDist = drawTeamNameMaxDist or GetConVar( "lambdaplayers_teamsystem_drawteamname_maxdist" )
        drawHaloMaxDist = drawHaloMaxDist or GetConVar( "lambdaplayers_teamsystem_drawhalo_maxdist" )
        hudScoreRefresh = hudScoreRefresh or GetConVar( "lambdaplayers_teamsystem_hud_score_refresh" )

        kothIconEnabled = kothIconEnabled or GetConVar( "lambdaplayers_teamsystem_koth_icon_enabled" )
        kothIconDrawVisible = kothIconDrawVisible or GetConVar( "lambdaplayers_teamsystem_koth_icon_alwaysdraw" )
        kothIconFadeStartDist = kothIconFadeStartDist or GetConVar( "lambdaplayers_teamsystem_koth_icon_fadeinstartdist" )
        kothIconFadeEndDist = kothIconFadeEndDist or GetConVar( "lambdaplayers_teamsystem_koth_icon_fadeinenddist" )

        ctfIconEnabled = ctfIconEnabled or GetConVar( "lambdaplayers_teamsystem_ctf_icon_enabled" )
        ctfIconDrawVisible = ctfIconDrawVisible or GetConVar( "lambdaplayers_teamsystem_ctf_icon_alwaysdraw" )
        ctfIconFadeStartDist = ctfIconFadeStartDist or GetConVar( "lambdaplayers_teamsystem_ctf_icon_fadeinstartdist" )
        ctfIconFadeEndDist = ctfIconFadeEndDist or GetConVar( "lambdaplayers_teamsystem_ctf_icon_fadeinenddist" )

        kdPickupSounds = kdPickupSounds or GetConVar( "lambdaplayers_teamsystem_kd_pickupsounds" )
        kdDrawWorldText = kdDrawWorldText or GetConVar( "lambdaplayers_teamsystem_kd_worldtext" )
        kdWorldTextDist = kdWorldTextDist or GetConVar( "lambdaplayers_teamsystem_kd_worldtextdist" )
        kdDrawHalo = kdDrawHalo or GetConVar( "lambdaplayers_teamsystem_kd_halo" )

        hqIconEnabled = hqIconEnabled or GetConVar( "lambdaplayers_teamsystem_hq_icon_enabled" )
        hqIconDrawVisible = hqIconDrawVisible or GetConVar( "lambdaplayers_teamsystem_hq_icon_alwaysdraw" )
        hqIconFadeStartDist = hqIconFadeStartDist or GetConVar( "lambdaplayers_teamsystem_hq_icon_fadeinstartdist" )
        hqIconFadeEndDist = hqIconFadeEndDist or GetConVar( "lambdaplayers_teamsystem_hq_icon_fadeinenddist" )

        assaultIconEnabled = assaultIconEnabled or GetConVar( "lambdaplayers_teamsystem_assault_icon_enabled" )
        assaultIconDrawVisible = assaultIconDrawVisible or GetConVar( "lambdaplayers_teamsystem_assault_icon_alwaysdraw" )
        assaultIconFadeStartDist = assaultIconFadeStartDist or GetConVar( "lambdaplayers_teamsystem_assault_icon_fadeinstartdist" )
        assaultIconFadeEndDist = assaultIconFadeEndDist or GetConVar( "lambdaplayers_teamsystem_assault_icon_fadeinenddist" )
        assaultDrawWorldText = assaultDrawWorldText or GetConVar( "lambdaplayers_teamsystem_assault_worldtext" )
		assaultWorldTextDist = assaultWorldTextDist or GetConVar( "lambdaplayers_teamsystem_assault_worldtextdist" )
        assaultDrawHalo = assaultDrawHalo or GetConVar( "lambdaplayers_teamsystem_assault_halo" )
		
        uiScale = uiScale or GetConVar( "lambdaplayers_uiscale" )
    end

    RefreshClientConVars()

    local function UpdateFont()
        RefreshClientConVars()
        local scale = ( uiScale and uiScale:GetFloat() ) or 1

        CreateFont( "lambda_teamsystem_matchtimer", {
            font = "ChatFont",
            extended = false,
            size = LambdaScreenScale( 15 + scale ),
            weight = 500,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = false,
        } )
		
        CreateFont( "lambda_teamsystem_assault_objective", {
            font = "ChatFont",
            extended = false,
            size = LambdaScreenScale( 14 + scale ),
            weight = 650,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = false,
        } )

        CreateFont( "lambda_teamsystem_assault_objective_small", {
            font = "ChatFont",
            extended = false,
            size = LambdaScreenScale( 10 + scale ),
            weight = 550,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = false,
        } )
    end

    UpdateFont()
    cvars.AddChangeCallback( "lambdaplayers_uiscale", UpdateFont, "lambda_teamsystem_updatefonts" )

    local nameTrTbl = {}
    local hudTrTbl = { filter = function( ent ) if ent:IsWorld() then return true end end }

    local gamemodeCompetitors = {}
    local nextScoreUpdateT = 0

    local ctfFlagCircle = Material( "lambdaplayers/icon/team_flag_circle.png" )
    local kothFlagCircle = Material( "lambdaplayers/icon/team_flag_square.png" )

    local color_assaultAttack = Color( 255, 175, 60 )

    local function LTS_ObjectiveAlpha( dist, fadeInStart, fadeOutEnd )
        if fadeInStart <= 0 then return 255 end
        if fadeOutEnd > fadeInStart then fadeOutEnd = fadeInStart end

        if dist < fadeInStart and dist > fadeOutEnd then
            local norm = ( 1 / math.max( 1, ( fadeInStart - fadeOutEnd ) ) * ( dist - fadeInStart ) + 1 )
            return math.Clamp( ( ( 1 - norm ) * 255 ), 0, 255 )
        elseif dist < fadeOutEnd then
            return 255
        end

        return 0
    end

    local function LTS_DrawAssaultEdgeIcon( ply, eyePos, iconPos, size )
        local scrW, scrH = ScrW(), ScrH()

        local angDiff = math.AngleDifference(
            ply:GetAimVector():GetNormalized():Angle().y,
            ( iconPos - eyePos ):GetNormalized():Angle().y
        )
        if angDiff < 0 then angDiff = 180 + ( angDiff + 180 ) end
        angDiff = angDiff - 90

        local offsetSize = 45
        local x = ( scrW / 2 ) + ( ( ( scrW - offsetSize ) / 2 ) * math.cos( math.rad( angDiff ) ) )
        local y = ( scrH / 2 ) + ( ( ( scrH - ( offsetSize * 1.4 ) ) / 2 ) * math.sin( math.rad( angDiff ) ) )

        local screenPos = iconPos:ToScreen()
        if screenPos.x < x and screenPos.x < ( scrW - x ) or screenPos.x > x and screenPos.x > ( scrW - x ) then
            screenPos.x = x
        end
        if screenPos.y < y or screenPos.y > scrH then
            screenPos.y = y
        elseif screenPos.y > ( scrH - y ) and screenPos.y < scrH then
            screenPos.y = ( scrH - y )
        end

        surface.DrawTexturedRect( screenPos.x, screenPos.y, size, size )
    end

	local function LTS_DrawAssaultWorldLabel( pointEnt, title, titleClr )
		if !IsValid( pointEnt ) then return end

		local textPos = pointEnt:WorldSpaceCenter() + Vector( 0, 0, 52 )
		local drawPos = textPos:ToScreen()

		local pointName = ( pointEnt.GetPointName and pointEnt:GetPointName() ) or ""
		local ownerName = ( pointEnt.GetCapturerName and pointEnt:GetCapturerName() ) or "Neutral"
		local contestName = ( pointEnt.GetContesterTeam and pointEnt:GetContesterTeam() ) or ""
		local capPerc = math.floor( ( pointEnt.GetCapturePercent and pointEnt:GetCapturePercent() ) or 0 )

		local progressText = ( contestName != "" and contestName != ownerName )
			and ( contestName .. " - " .. capPerc .. "%" )
			or ( "Progress: " .. capPerc .. "%" )

		local lines = {
			{ text = title, font = "lambda_teamsystem_assault_objective", color = ( titleClr or color_white ) },
		}

		if pointName != "" then
			lines[ #lines + 1 ] = {
				text = pointName,
				font = "lambda_teamsystem_assault_objective_small",
				color = color_white
			}
		end

		lines[ #lines + 1 ] = {
			text = "Owner: " .. ownerName,
			font = "lambda_teamsystem_assault_objective_small",
			color = color_white
		}

		lines[ #lines + 1 ] = {
			text = progressText,
			font = "lambda_teamsystem_assault_objective_small",
			color = ( titleClr or color_white )
		}

		local lineGap = 3
		local totalH = 0

		for i, line in ipairs( lines ) do
			surface.SetFont( line.font )
			local _, textH = surface.GetTextSize( line.text )
			line.h = math.max( textH, 10 )
			totalH = totalH + line.h

			if i != #lines then
				totalH = totalH + lineGap
			end
		end

		local y = math.floor( drawPos.y - totalH )

		for _, line in ipairs( lines ) do
			SimpleTextOutlined(
				line.text,
				line.font,
				drawPos.x,
				y,
				line.color,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP,
				1,
				color_black
			)

			y = y + line.h + lineGap
		end
	end
	
    local clientSnds = {}

    net.Receive( "lambda_teamsystem_playclientsound", function()
		RefreshClientConVars()
        local plyTeam = ( playerTeam and playerTeam:GetString() ) or ""
        local targetTeam = net.ReadString()
        if targetTeam != "" and targetTeam != "all" and plyTeam != targetTeam then return end

        local cvarName = net.ReadString()
        if !cvarName or cvarName == "" then return end
		
		if kdPickupSounds and !kdPickupSounds:GetBool() then
			if cvarName == "lambdaplayers_teamsystem_kd_snd_confirm"
			or cvarName == "lambdaplayers_teamsystem_kd_snd_deny" then
				return
			end
		end

        local cvar = GetConVar( cvarName )
        if !cvar then return end

        local sndPath = cvar:GetString()
        if sndPath == "" then return end

        if string_EndsWith( sndPath, "*" ) then
            local dirFiles = file_Find( "sound/" .. sndPath, "GAME" )
            sndPath = string_Replace( sndPath .. dirFiles[ random( #dirFiles ) ], "*", "" )
        end

        local snd = CreateSound( Entity( 0 ), sndPath )
        snd:SetSoundLevel( 0 )
        snd:Play()

        local sndList = clientSnds[ cvarName ]
        if !sndList then
            sndList = {}
            clientSnds[ cvarName ] = sndList
        end
        sndList[ #sndList + 1 ] = snd
    end )

    net.Receive( "lambda_teamsystem_stopclientsound", function()
        local cvarName = net.ReadString()
        if !cvarName or cvarName == "" then return end

        local sndList = clientSnds[ cvarName ]
        if !sndList or #sndList == 0 then return end

        for _, snd in ipairs( sndList ) do
            snd:Stop()
        end
    end )
	
	net.Receive( "lambda_teamsystem_sendupdateddata", function()
		if LambdaTeams and LambdaTeams.UpdateData then
			LambdaTeams:UpdateData()
		end
	end )
	
	net.Receive( "lambda_teamsystem_kd_feedback", function()
		RefreshClientConVars()
		local plyTeam = ( playerTeam and playerTeam:GetString() ) or ""
		local targetTeam = net.ReadString()
		if targetTeam ~= "" and targetTeam ~= "all" and plyTeam ~= targetTeam then return end

		local isConfirm = net.ReadBool()
		notification.AddLegacy( isConfirm and "CONFIRMED!" or "DENIED!", NOTIFY_GENERIC, 1.2 )
	end )


	local function LTS_SendPlayerLambdaTeam( teamName )
		RefreshClientConVars()

		local ply = LocalPlayer()
		if !IsValid( ply ) then return end

		net.Start( "lambda_teamsystem_setplayerteam" )
			net.WriteString( teamName or ( playerTeam and playerTeam:GetString() ) or "" )
		net.SendToServer()
	end

	local function OnPlayerLambdaTeamChanged( name, oldVal, newVal )
		LTS_SendPlayerLambdaTeam( newVal )
	end

	hook.Add( "InitPostEntity", modulePrefix .. "InitialPlayerTeamSync", function()
		timer.Simple( 0.5, function()
			RefreshClientConVars()

			local ply = LocalPlayer()
			if IsValid( ply ) then
				LTS_SendPlayerLambdaTeam( ( playerTeam and playerTeam:GetString() ) or "" )
			end
		end )
	end )
    
	cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_playerteam", modulePrefix .. "OnPlayerLambdaTeamChanged" )
    cvars.AddChangeCallback( "lambdaplayers_teamsystem_playerteam", OnPlayerLambdaTeamChanged, modulePrefix .. "OnPlayerLambdaTeamChanged" )

    local function GetLambdaTeamColor( self )
        local colorvec = self:GetNW2Vector( "lambda_teamcolor", false )
        if !colorvec then colorvec = self:GetNWVector( "lambda_teamcolor" ) end
        return colorvec:ToColor()
    end

    local function LambdaGetDisplayColor( self )
        local teamName = LambdaTeams:GetPlayerTeam( self )
        if teamName and GetGlobalBool("LambdaTeamSystem_Enabled", false) then
			return LambdaTeams:GetTeamColor(teamName, true)
		end

    end

	local function OnPreDrawHalos()
		RefreshClientConVars()
		if !GetGlobalBool( "LambdaTeamSystem_Enabled", false ) then return end

		local ply = LocalPlayer()
		if !IsValid( ply ) then return end

		local plyTeamName = ( playerTeam and playerTeam:GetString() ) or ""
		if plyTeamName == "" then return end

		local eyePos = ply:EyePos()
		local haloMaxDist = ( drawHaloMaxDist and drawHaloMaxDist:GetFloat() ) or 0
		local haloMaxDistSqr = ( haloMaxDist > 0 and ( haloMaxDist * haloMaxDist ) or 0 )

		if drawHalo and drawHalo:GetBool() then
			for _, ent in ipairs( GetLambdaPlayers() ) do
				local entTeam = LambdaTeams:GetPlayerTeam( ent )
				if entTeam and entTeam == plyTeamName and !ent:GetIsDead() and ent:IsBeingDrawn() then
					if haloMaxDistSqr != 0 and eyePos:DistToSqr( ent:WorldSpaceCenter() ) > haloMaxDistSqr then continue end
					AddHalo( { ent }, LambdaTeams:GetTeamColor( entTeam, true ), 3, 3, 1, true, false )
				end
			end
		end

		if assaultDrawHalo and assaultDrawHalo:GetBool() and LambdaTeams:GetCurrentGamemodeID() == 6 and LambdaTeams.GetAssaultObjectivePoints then
			local attackPoint, defendPoint = LambdaTeams:GetAssaultObjectivePoints( plyTeam )

			local attackTeamName = ( LambdaTeams.GetAssaultAttackTeam and LambdaTeams:GetAssaultAttackTeam() ) or nil
			local defendTeamName = ( LambdaTeams.GetAssaultDefendTeam and LambdaTeams:GetAssaultDefendTeam() ) or nil

			local attackTeamClr = ( attackTeamName and LambdaTeams:GetTeamColor( attackTeamName, true ) ) or color_assaultAttack
			local defendTeamClr = ( defendTeamName and LambdaTeams:GetTeamColor( defendTeamName, true ) ) or color_white

			local objDist = ( assaultWorldTextDist and assaultWorldTextDist:GetFloat() ) or 3500
			local objDistSqr = ( objDist > 0 and ( objDist * objDist ) or 0 )

			local activePoints = {}
			if IsValid( attackPoint ) then activePoints[ attackPoint ] = attackTeamClr end
			if IsValid( defendPoint ) then activePoints[ defendPoint ] = defendTeamClr end

			for _, pointEnt in ipairs( ents_FindByClass( "lambda_assault_point" ) ) do
				if !IsValid( pointEnt ) then continue end
				if objDistSqr != 0 and eyePos:DistToSqr( pointEnt:WorldSpaceCenter() ) > objDistSqr then continue end

				local haloClr = activePoints[ pointEnt ]
				if haloClr then
					AddHalo( { pointEnt }, haloClr, 4, 4, 1, true, false )
				elseif pointEnt:GetIsCaptured() then
					local pointClr = pointEnt:GetCapturerColor()
					pointClr = ( isvector( pointClr ) and pointClr:ToColor() or defendTeamClr )
					AddHalo( { pointEnt }, pointClr, 2, 2, 1, true, false )
				end
			end
		end
	end
	
	local function OnHUDPaint()
		RefreshClientConVars()
		if !GetGlobalBool( "LambdaTeamSystem_Enabled", false ) then return end

		local ply = LocalPlayer()
		if !IsValid( ply ) then return end

		local scrW, scrH = ScrW(), ScrH()
		local scale = ( uiScale and uiScale:GetFloat() ) or 1

		local traceEnt = ply:GetEyeTrace().Entity
		if LambdaIsValid( traceEnt ) and traceEnt.IsLambdaPlayer then
			local entTeam = LambdaTeams:GetPlayerTeam( traceEnt )
			if entTeam then
				local friendTbl = traceEnt.l_friends
				local height = ( ( friendTbl and !table_IsEmpty( friendTbl ) ) and 1.68 or 1.78 )

				DrawText(
					"Team: " .. entTeam,
					"lambdaplayers_displayname",
					( scrW / 2 ),
					( scrH / height ) + LambdaScreenScale( 1 + scale ),
					LambdaTeams:GetTeamColor( entTeam, true ),
					TEXT_ALIGN_CENTER
				)
			end
		end

		local PANEL = {}

		local gamemodeID = LambdaTeams:GetCurrentGamemodeID()
		if gamemodeID != 0 then
			local timeRemain = GetGlobalInt( "LambdaTeamMatch_TimeRemaining", 0 )
			if timeRemain != -1 then
				local ft = string.FormattedTime( timeRemain )
				local timeFormatted = string.format( "%02i:%02i:%02i", ft.h, ft.m, ft.s )

				SimpleTextOutlined(
					"Time Left: " .. timeFormatted,
					"lambda_teamsystem_matchtimer",
					( scrW / 2 ),
					( scrH / 50 ) + LambdaScreenScale( 1 + scale ),
					color_white,
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_TOP,
					1,
					color_black
				)
			end

			local pointsName = "Total Points"
			if gamemodeID == 1 and GetGlobalBool( "LambdaTeamMatch_IsConquest", false ) then
				pointsName = "Tickets Remaining"
			elseif gamemodeID == 2 then
				pointsName = "Flags Captured"
			elseif gamemodeID == 3 then
				pointsName = "Total Kills"
			elseif gamemodeID == 4 then
				pointsName = "Kills Confirmed"
			elseif gamemodeID == 5 then
				pointsName = "HQ Score"
			elseif gamemodeID == 6 then
				pointsName = "Sectors Captured"
			elseif gamemodeID == 7 then
				pointsName = "Salvage Delivered"
			elseif gamemodeID == 8 then
				pointsName = "Sites Destroyed"
			end

			local drawWidth = ( scrW / 45 )
			local drawHeight = ( ( scrH / 2 ) + LambdaScreenScale( 1 + scale ) )

			SimpleTextOutlined(
				pointsName .. ":",
				"ChatFont",
				drawWidth,
				( drawHeight - 20 ),
				color_white,
				TEXT_ALIGN_LEFT,
				TEXT_ALIGN_TOP,
				1,
				color_black
			)

			if CurTime() >= nextScoreUpdateT then
				table_Empty( gamemodeCompetitors )

				for _, ply in ipairs( table_Add( GetLambdaPlayers(), player_GetAll() ) ) do
					local plyTeam = LambdaTeams:GetPlayerTeam( ply )
					if !plyTeam then continue end

					local entry = gamemodeCompetitors[ plyTeam ]
					if entry then
						entry[ 3 ] = entry[ 3 ] + 1
					else
						gamemodeCompetitors[ plyTeam ] = {
							LambdaTeams:GetTeamPoints( plyTeam ),
							LambdaTeams:GetTeamColor( plyTeam, true ),
							1
						}
					end
				end

				local refreshTime = math.max( 0.05, ( hudScoreRefresh and hudScoreRefresh:GetFloat() ) or 0.25 )
				nextScoreUpdateT = ( CurTime() + refreshTime )
			end

			local scoreIndex = 0
			for teamName, teamData in pairs( gamemodeCompetitors ) do
				SimpleTextOutlined(
					teamName .. " (" .. ( teamData[ 3 ] or 0 ) .. "): " .. teamData[ 1 ],
					"ChatFont",
					drawWidth,
					( drawHeight + ( 20 * scoreIndex ) ),
					teamData[ 2 ],
					TEXT_ALIGN_LEFT,
					TEXT_ALIGN_TOP,
					1,
					color_black
				)

				scoreIndex = ( scoreIndex + 1 )
			end
		end

		local plyTeam = ( playerTeam and playerTeam:GetString() ) or ""
		if plyTeam == "" then return end

		local eyePos = ply:EyePos()

		if drawTeamName and drawTeamName:GetBool() then
			nameTrTbl.start = eyePos
			nameTrTbl.filter = ply

			local nameMaxDist = ( drawTeamNameMaxDist and drawTeamNameMaxDist:GetFloat() ) or 2000
			local nameMaxDistSqr = ( nameMaxDist > 0 and ( nameMaxDist * nameMaxDist ) or 0 )

			for _, ent in ipairs( GetLambdaPlayers() ) do
				local entTeam = LambdaTeams:GetPlayerTeam( ent )
				if entTeam and entTeam == plyTeam and !ent:GetIsDead() and ent:IsBeingDrawn() then
					local textPos = ( ent:GetPos() + ent:GetUp() * 96 )

					if nameMaxDistSqr != 0 and eyePos:DistToSqr( textPos ) > nameMaxDistSqr then continue end

					nameTrTbl.endpos = textPos

					local nameTr = TraceLine( nameTrTbl )
					if !nameTr.Hit or nameTr.Entity == ent then
						local drawPos = textPos:ToScreen()
						DrawText(
							entTeam .. "'s Member",
							"lambdaplayers_displayname",
							drawPos.x,
							drawPos.y,
							LambdaTeams:GetTeamColor( entTeam, true ),
							TEXT_ALIGN_CENTER
						)
					end
				end
			end
		end

		if LambdaTeams:GetCurrentGamemodeID() != 6 and kothIconEnabled and kothIconEnabled:GetBool() then
			local fadeInStart = ( kothIconFadeStartDist and kothIconFadeStartDist:GetInt() ) or 2500
			local fadeOutEnd = ( kothIconFadeEndDist and kothIconFadeEndDist:GetInt() ) or 1000

			for _, pointEnt in ipairs( ents_FindByClass( "lambda_koth_point" ) ) do
				if !IsValid( pointEnt ) then continue end

				local iconPos = pointEnt:WorldSpaceCenter()

				hudTrTbl.start = eyePos
				hudTrTbl.endpos = iconPos

				if ( kothIconDrawVisible and kothIconDrawVisible:GetBool() ) or TraceLine( hudTrTbl ).Hit then
					surface.SetMaterial( kothFlagCircle )

					local iconClr = pointEnt:GetCapturerColor()
					local capPerc = pointEnt:GetCapturePercent()

					if !pointEnt:GetIsCaptured() then
						iconClr = LerpVector( ( capPerc / 100 ), iconClr, pointEnt:GetContesterColor() )
					else
						iconClr = LerpVector( ( ( 100 - capPerc ) / 100 ), iconClr, vec_white )
					end

					local drawAlpha = 0
					local dist = eyePos:Distance( iconPos )
					if dist < fadeInStart and dist > fadeOutEnd then
						local norm = ( 1 / ( fadeInStart - fadeOutEnd ) * ( dist - fadeInStart ) + 1 )
						drawAlpha = ( ( 1 - norm ) * 255 )
					elseif dist < fadeOutEnd then
						drawAlpha = 255
					end

					iconClr = iconClr:ToColor()
					surface.SetDrawColor( iconClr.r, iconClr.g, iconClr.b, drawAlpha )

					local angDiff = math.AngleDifference(
						ply:GetAimVector():GetNormalized():Angle().y,
						( iconPos - eyePos ):GetNormalized():Angle().y
					)
					if angDiff < 0 then angDiff = 180 + ( angDiff + 180 ) end
					angDiff = angDiff - 90

					local offsetSize = 45
					local x = ( scrW / 2 ) + ( ( ( scrW - offsetSize ) / 2 ) * math.cos( math.rad( angDiff ) ) )
					local y = ( scrH / 2 ) + ( ( ( scrH - ( offsetSize * 1.4 ) ) / 2 ) * math.sin( math.rad( angDiff ) ) )

					local screenPos = iconPos:ToScreen()
					if screenPos.x < x and screenPos.x < ( scrW - x ) or screenPos.x > x and screenPos.x > ( scrW - x ) then
						screenPos.x = x
					end
					if screenPos.y < y or screenPos.y > scrH then
						screenPos.y = y
					elseif screenPos.y > ( scrH - y ) and screenPos.y < scrH then
						screenPos.y = ( scrH - y )
					end

					surface.DrawTexturedRect( screenPos.x, screenPos.y, 32, 32 )
				end
			end
		end

		if LambdaTeams:GetCurrentGamemodeID() == 6 and LambdaTeams.GetAssaultObjectivePoints then
			local attackPoint, defendPoint = LambdaTeams:GetAssaultObjectivePoints( plyTeam )

			local attackTeamName = ( LambdaTeams.GetAssaultAttackTeam and LambdaTeams:GetAssaultAttackTeam() ) or nil
			local defendTeamName = ( LambdaTeams.GetAssaultDefendTeam and LambdaTeams:GetAssaultDefendTeam() ) or nil

			local attackTeamClr = ( attackTeamName and LambdaTeams:GetTeamColor( attackTeamName, true ) ) or color_assaultAttack
			local defendTeamClr = ( defendTeamName and LambdaTeams:GetTeamColor( defendTeamName, true ) ) or color_white

			local fadeInStart = ( assaultIconFadeStartDist and assaultIconFadeStartDist:GetInt() ) or 2500
			local fadeOutEnd = ( assaultIconFadeEndDist and assaultIconFadeEndDist:GetInt() ) or 700

			local worldTextMaxDist = ( assaultWorldTextDist and assaultWorldTextDist:GetFloat() ) or 3500
			local worldTextMaxDistSqr = ( worldTextMaxDist > 0 and ( worldTextMaxDist * worldTextMaxDist ) or 0 )

			local attackName = ( IsValid( attackPoint ) and attackPoint.GetPointName and attackPoint:GetPointName() ) or ""
			local defendName = ( IsValid( defendPoint ) and defendPoint.GetPointName and defendPoint:GetPointName() ) or ""

			local attackClr = attackTeamClr
			if IsValid( attackPoint ) then
				local attackOwner = ( attackPoint.GetCapturerName and attackPoint:GetCapturerName() ) or ""
				if attackOwner != "" and attackOwner != "Neutral" and attackOwner == defendTeamName then
					attackClr = defendTeamClr
				end
			end

			local assaultHudY = ( scrH / 50 ) + LambdaScreenScale( 18 + scale )

			surface.SetFont( "lambda_teamsystem_assault_objective_small" )
			local _, assaultLineH = surface.GetTextSize( "Capture: " .. ( attackName != "" and attackName or "W" ) )
			local assaultLineGap = math.max( assaultLineH + 4, LambdaScreenScale( 16 ) )

			if attackName != "" then
				SimpleTextOutlined(
					"Capture: " .. attackName,
					"lambda_teamsystem_assault_objective_small",
					( scrW / 2 ),
					assaultHudY,
					attackClr,
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_TOP,
					1,
					color_black
				)
			end

			if defendName != "" then
				SimpleTextOutlined(
					"Defend: " .. defendName,
					"lambda_teamsystem_assault_objective_small",
					( scrW / 2 ),
					( assaultHudY + assaultLineGap ),
					defendTeamClr,
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_TOP,
					1,
					color_black
				)
			end

			local function DrawAssaultObjective( pointEnt, title, titleClr )
				if !IsValid( pointEnt ) then return end
				titleClr = titleClr or color_white

				local iconPos = pointEnt:WorldSpaceCenter()
				local dist = eyePos:Distance( iconPos )

				hudTrTbl.start = eyePos
				hudTrTbl.endpos = iconPos
				local tr = TraceLine( hudTrTbl )

				if assaultIconEnabled and assaultIconEnabled:GetBool() then
					local drawAlpha = LTS_ObjectiveAlpha( dist, fadeInStart, fadeOutEnd )
					if drawAlpha > 0 and ( ( assaultIconDrawVisible and assaultIconDrawVisible:GetBool() ) or !tr.Hit ) then
						surface.SetMaterial( kothFlagCircle )
						surface.SetDrawColor( titleClr.r, titleClr.g, titleClr.b, drawAlpha )
						LTS_DrawAssaultEdgeIcon( ply, eyePos, iconPos, 32 )
					end
				end

				if assaultDrawWorldText and assaultDrawWorldText:GetBool() then
					if worldTextMaxDistSqr == 0 or eyePos:DistToSqr( iconPos ) <= worldTextMaxDistSqr then
						if ( assaultIconDrawVisible and assaultIconDrawVisible:GetBool() ) or !tr.Hit then
							LTS_DrawAssaultWorldLabel( pointEnt, title, titleClr )
						end
					end
				end
			end

			DrawAssaultObjective( attackPoint, "CAPTURE", attackClr )
			DrawAssaultObjective( defendPoint, "DEFEND", defendTeamClr )
		end
		
		if ctfIconEnabled and ctfIconEnabled:GetBool() then
			local fadeInStart = ( ctfIconFadeStartDist and ctfIconFadeStartDist:GetInt() ) or 2500
			local fadeOutEnd = ( ctfIconFadeEndDist and ctfIconFadeEndDist:GetInt() ) or 1000

			for _, flag in ipairs( ents_FindByClass( "lambda_ctf_flag" ) ) do
				if IsValid( flag ) then
					local isHome = flag:GetIsAtHome()
					if isHome or !flag:IsDormant() then
						local holder = flag:GetFlagHolderEnt()
						if holder != ply and ( ( !isHome and !flag:GetIsPickedUp() and flag:GetTeamName() == plyTeam ) or ( IsValid( holder ) and LambdaTeams:GetPlayerTeam( holder ) == plyTeam ) ) then
							local iconPos = flag:WorldSpaceCenter()

							hudTrTbl.start = eyePos
							hudTrTbl.endpos = iconPos

							if ( ctfIconDrawVisible and ctfIconDrawVisible:GetBool() ) or TraceLine( hudTrTbl ).Hit then
								surface.SetMaterial( ctfFlagCircle )

								local drawAlpha = 0
								local dist = eyePos:Distance( iconPos )
								if dist < fadeInStart and dist > fadeOutEnd then
									local norm = ( 1 / ( fadeInStart - fadeOutEnd ) * ( dist - fadeInStart ) + 1 )
									drawAlpha = ( ( 1 - norm ) * 255 )
								elseif dist < fadeOutEnd then
									drawAlpha = 255
								end

								local iconClr = flag:GetTeamColor():ToColor()
								surface.SetDrawColor( iconClr.r, iconClr.g, iconClr.b, drawAlpha )

								local angDiff = math.AngleDifference(
									ply:GetAimVector():GetNormalized():Angle().y,
									( iconPos - eyePos ):GetNormalized():Angle().y
								)
								if angDiff < 0 then angDiff = 180 + ( angDiff + 180 ) end
								angDiff = angDiff - 90

								local offsetSize = 45
								local x = ( scrW / 2 ) + ( ( ( scrW - offsetSize ) / 2 ) * math.cos( math.rad( angDiff ) ) )
								local y = ( scrH / 2 ) + ( ( ( scrH - ( offsetSize * 1.4 ) ) / 2 ) * math.sin( math.rad( angDiff ) ) )

								local screenPos = iconPos:ToScreen()
								if screenPos.x < x and screenPos.x < ( scrW - x ) or screenPos.x > x and screenPos.x > ( scrW - x ) then
									screenPos.x = x
								end
								if screenPos.y < y or screenPos.y > scrH then
									screenPos.y = y
								elseif screenPos.y > ( scrH - y ) and screenPos.y < scrH then
									screenPos.y = ( scrH - y )
								end

								surface.DrawTexturedRect( screenPos.x, screenPos.y, 32, 32 )
							end
						end
					end
				end
			end
		end
	end

    hook.Add( "HUDPaint", modulePrefix .. "OnHUDPaint", OnHUDPaint )
    hook.Add( "PreDrawHalos", modulePrefix .. "OnPreDrawHalos", OnPreDrawHalos )
    hook.Add( "LambdaGetDisplayColor", modulePrefix .. "LambdaGetDisplayColor", LambdaGetDisplayColor )

    ---
    
    local CreateVGUI = vgui.Create
    local spairs = SortedPairs
    local DermaMenu = DermaMenu
    local table_insert = table.insert
    local AddNotification = notification.AddLegacy
    local GetAllValidPlayerModels = player_manager.AllValidModels
    local TranslateToPlayerModelName = player_manager.TranslateToPlayerModelName
    local string_len = string.len
    local Round = math.Round
    local table_Merge = table.Merge

    local function OpenLambdaTeamPanel( ply )
        if !ply:IsSuperAdmin() then 
            AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
            PlayClientSound( "buttons/button10.wav" ) 
            return 
        end

        local frame = LAMBDAPANELS:CreateFrame( "Lambda Team Editor", 550, 550 )

        local leftpanel = LAMBDAPANELS:CreateBasicPanel( frame )
        leftpanel:SetSize( 225, 200 )
        leftpanel:Dock( LEFT )

        local teamlist = CreateVGUI( "DListView", leftpanel )
        teamlist:Dock( FILL )
        teamlist:AddColumn( "Teams", 1 )

        local CompileSettings
        local ImportTeam
        local teams = {}

        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/teamlist.json", "json", function( data ) 
            if !data then return end

            table_Merge( teams, data )

            for name, data in spairs( data ) do
                local line = teamlist:AddLine( name )
                line:SetSortValue( 1, data )
            end
        end )

        local function UpdateTeamLine( teamname, newinfo )
            for _, line in ipairs( teamlist:GetLines() ) do
                local info = line:GetSortValue( 1 )
                if info.name == teamname then line:SetSortValue( 1, newinfo ) return end
            end

            local line = teamlist:AddLine( teamname )
            line:SetSortValue( 1, newinfo )
        end

        function teamlist:DoDoubleClick( id, line )
            ImportTeam( line:GetSortValue( 1 ) )
            PlayClientSound( "buttons/button15.wav" )
        end

        function teamlist:OnRowRightClick( id, line )
            local conmenu = DermaMenu( false, leftpanel )
            local info = line:GetSortValue( 1 )

            conmenu:AddOption( "Delete " .. info.name .. "?", function()
                chat.AddText( "Deleted " .. info.name .. " from the team list.")
                PlayClientSound( "buttons/button15.wav" )
                teamlist:RemoveLine( id )
                
                LAMBDAPANELS:RemoveVarFromKVFile( "lambdaplayers/teamlist.json", info.name, "json" ) 
                net.Start( "lambda_teamsystem_updatedata" ); net.SendToServer()
                net.Receive( "lambda_teamsystem_sendupdateddata", LambdaTeams.UpdateData )
            end )
            conmenu:AddOption( "Cancel", function() end )
        end

        local rightpanel = LAMBDAPANELS:CreateBasicPanel( frame, RIGHT )
        rightpanel:SetSize( 310, 200 )

        local mainscroll = LAMBDAPANELS:CreateScrollPanel( rightpanel, false, FILL )
        
        LAMBDAPANELS:CreateButton( rightpanel, BOTTOM, "Validate Teams", function()
            local hasissue = false
            
            for name, data in pairs( teams ) do
                local mdls = data.playermdls
                if mdls and #mdls > 0 then
                    for _, mdl in ipairs( mdls ) do
                        if file_Exists( mdl, "GAME" ) then continue end
                        hasissue = true; print( "Lambda Team Validation: Team " .. name .. " has an invalid playermodel! (" .. mdl .. ")" )
                    end
                end
            end

            chat.AddText( "Team Validation complete." .. ( hasissue and " Some issues were found. Check console for more details." or " No issues were found." ) )
        end )

        LAMBDAPANELS:CreateButton( rightpanel, BOTTOM, "Save Team", function()
            local compiledinfo = CompileSettings()
            if !compiledinfo then return end

            local alreadyexists = false
            for _, line in ipairs( teamlist:GetLines() ) do
                local info = line:GetSortValue( 1 )
                if info.name == compiledinfo.name then 
                    line:SetSortValue( 1, compiledinfo ) 
                    chat.AddText( "Edited team " .. compiledinfo.name .. "'s data." )
                    alreadyexists = true; break 
                end
            end
            if !alreadyexists then
                local line = teamlist:AddLine( compiledinfo.name )
                line:SetSortValue( 1, compiledinfo )
                chat.AddText( "Saved " .. compiledinfo.name .. " to the team list." )
            end

            PlayClientSound( "buttons/button15.wav" )
            LAMBDAPANELS:UpdateKeyValueFile( "lambdaplayers/teamlist.json", { [ compiledinfo.name ] = compiledinfo }, "json" )

            net.Start( "lambda_teamsystem_updatedata" ); net.SendToServer()
        end )

        --

        LAMBDAPANELS:CreateLabel( "Team Name", mainscroll, TOP )
        local teamname = LAMBDAPANELS:CreateTextEntry( mainscroll, TOP, "Enter the team's name here" )

        LAMBDAPANELS:CreateLabel( "Team Color", mainscroll, TOP )
        local teamcolor = LAMBDAPANELS:CreateColorMixer( mainscroll, TOP )

        LAMBDAPANELS:CreateLabel( "Team Playermodels", mainscroll, TOP )
        local teampmlist = CreateVGUI( "DListView", mainscroll )
        teampmlist:SetSize( 250, 150 )
        teampmlist:Dock( TOP )
        teampmlist:AddColumn( "", 1 )

        function teampmlist:DoDoubleClick( id )
            teampmlist:RemoveLine( id )
            PlayClientSound( "buttons/button15.wav" )
        end

        local mdlPreviewAng = Angle()

        LAMBDAPANELS:CreateButton( mainscroll, TOP, "Add Playermodel", function()
            local modelframe = LAMBDAPANELS:CreateFrame( "Team Playermodels", 800, 500 )
            
            local modelpanel = LAMBDAPANELS:CreateBasicPanel( modelframe, RIGHT )
            modelpanel:SetSize( 350, 200 )

            local modelpreview = CreateVGUI( "DModelPanel", modelframe )
            modelpreview:SetSize( 400, 100 )
            modelpreview:Dock( LEFT )

            modelpreview:SetModel( "" )

            function modelpreview:LayoutEntity( Entity )
                mdlPreviewAng[ 2 ] = ( RealTime() * 20 % 360 )
                Entity:SetAngles( mdlPreviewAng )
            end

            local modelscroll = LAMBDAPANELS:CreateScrollPanel( modelpanel, false, FILL )
            local pmlist = CreateVGUI( "DIconLayout", modelscroll )
            pmlist:Dock( FILL )
            pmlist:SetSpaceY( 12 )
            pmlist:SetSpaceX( 12 )

            LAMBDAPANELS:CreateButton( modelpanel, BOTTOM, "Select Model", function()
                local selectedmodel = modelpreview:GetModel()

                if !selectedmodel or selectedmodel == "" then
                    AddNotification( "You didn't select any playermodel!", 1, 4 )
                    PlayClientSound( "buttons/button10.wav" )
                    return
                end
                for _, line in ipairs( teampmlist:GetLines() ) do
                    if line:GetValue( 1 ) == selectedmodel then
                        AddNotification( "Selected playermodel is already on the list!", 1, 4 )
                        PlayClientSound( "buttons/button10.wav" )
                        return
                    end
                end

                AddNotification( "Added " .. TranslateToPlayerModelName( selectedmodel ) ..  " to the playermodel list!", 0, 4 )
                PlayClientSound( "buttons/button15.wav" )

                teampmlist:AddLine( selectedmodel )
            end )

            local manualMdl = LAMBDAPANELS:CreateTextEntry( modelpanel, BOTTOM, "Enter here if you want to use a non-playermodel model" )

            function manualMdl:OnChange()
                local mdlPath = manualMdl:GetText()
                
                if file_Exists( mdlPath, "GAME" ) then
                    modelpreview:SetModel( mdlPath )
                    local mdlEnt = modelpreview:GetEntity()
                    if IsValid( mdlEnt ) then modelpreview:GetEntity().GetPlayerColor = function() return teamcolor:GetVector() end end
                end
            end

            for _, mdl in spairs( GetAllValidPlayerModels() ) do
                local modelbutton = pmlist:Add( "SpawnIcon" )
                modelbutton:SetModel( mdl )

                function modelbutton:DoClick()
                    manualMdl:SetValue( modelbutton:GetModelName() )
                    manualMdl:OnChange()
                end
            end
        end )

        local spawnhealth = LAMBDAPANELS:CreateNumSlider( mainscroll, TOP, 100, "Team Health", 1, 10000, 0 )
        local spawnarmor = LAMBDAPANELS:CreateNumSlider( mainscroll, TOP, 0, "Team Armor", 0, 10000, 0 )

        LAMBDAPANELS:CreateLabel( "Team Voice Profile", mainscroll, TOP )
        local voiceprofiletbl = { [ "No Voice Profile" ] = "/NIL" }
        for vp, _ in pairs( LambdaVoiceProfiles ) do voiceprofiletbl[ vp ] = vp end
        local voiceprofile = LAMBDAPANELS:CreateComboBox( mainscroll, TOP, voiceprofiletbl )

        local teamweaponrestrictions = {}
        LAMBDAPANELS:CreateLabel( "Team Weapon Restrictions", mainscroll, TOP )
        LAMBDAPANELS:CreateButton( mainscroll, TOP, "Edit Weapon Restrictions", function()
            local weppermframe = LAMBDAPANELS:CreateFrame( "Weapon Restrictions", 800, 400 )
            local weppermscroll = LAMBDAPANELS:CreateScrollPanel( weppermframe, true, FILL )

            LAMBDAPANELS:CreateLabel( "Here you can mark weapons that the team will only be allowed to use.", weppermframe, TOP )
            LAMBDAPANELS:CreateLabel( "Leaving all weapons un-checked will disable team weapon restrictions.", weppermframe, TOP )

            local weaponcheckboxes = {}
            for weporigin, _ in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do
                local weppermscroll2 = LAMBDAPANELS:CreateScrollPanel( weppermscroll, false, LEFT )
                weppermscroll2:SetSize( 250, 350 )
                weppermscroll:AddPanel( weppermscroll2 )

                LAMBDAPANELS:CreateLabel( "------ " .. weporigin .. " ------ ", weppermscroll2, TOP )

                local togglestate = false
                weaponcheckboxes[ weporigin ] = {}

                LAMBDAPANELS:CreateButton( weppermscroll2, TOP, "Toggle " .. weporigin .. " Weapons", function()
                    togglestate = !togglestate
                    for _, check in ipairs( weaponcheckboxes[ weporigin ] ) do
                        check[1]:SetChecked( togglestate )
                    end
                end )

                for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
                    if data.origin == weporigin and name != "none" and name != "physgun" then
                        local weprettyname = string_Replace( data.prettyname, "[" .. weporigin .. "] ", "" )
                        local weppermcheckbox = LAMBDAPANELS:CreateCheckBox( weppermscroll2, TOP, ( teamweaponrestrictions[ name ] or false ), weprettyname )
                        table_insert( weaponcheckboxes[ weporigin ], { weppermcheckbox, name } )
                    end
                end
            end

            LAMBDAPANELS:CreateButton( weppermscroll, BOTTOM, "Done", function()
                table_Empty( teamweaponrestrictions )

                for _, v in pairs( weaponcheckboxes ) do
                    for _, j in ipairs( v ) do
                        if !j[ 1 ]:GetChecked() then continue end
                        teamweaponrestrictions[ j[ 2 ] ] = true
                    end
                end

                AddNotification( "Updated team's weapon restrictions!", 0, 4 )
                PlayClientSound( "buttons/button15.wav" )

                weppermframe:Close()
            end )
        end )

        CompileSettings = function()
            local name = teamname:GetText()
            if name == "" then 
                AddNotification( "No team name is set for this team!", 1, 4 )
                PlayClientSound( "buttons/button10.wav" )
                return 
            end

            local playermdls
            local pmlist = teampmlist:GetLines()
            if #pmlist > 0 then
                playermdls = {}
                for _, list in ipairs( pmlist ) do playermdls[ #playermdls + 1 ] = list:GetValue( 1 ) end
            end

            local health = Round( spawnhealth:GetValue(), 0 )
            if health == 100 then health = nil end

            local armor = Round( spawnarmor:GetValue(), 0 )
            if armor == 0 then armor = nil end

            local _, vp = voiceprofile:GetSelected()

            local infotable = {
                name = name,
                color = teamcolor:GetVector(),
                spawnhealth = health,
                spawnarmor = armor,
                playermdls = playermdls,
                weaponrestrictions = ( !table_IsEmpty( teamweaponrestrictions ) and teamweaponrestrictions or nil ),
                voiceprofile = ( vp != "/NIL" and vp )
            }

            return infotable
        end

        ImportTeam = function( infotable )
            teamname:SetText( infotable.name or "" )
            teamcolor:SetVector( infotable.color or vec_white )
            
            spawnhealth:SetValue( infotable.spawnhealth or 100 )
            spawnarmor:SetValue( infotable.spawnarmor or 0 )

            teampmlist:Clear()
            local mdls = infotable.playermdls
            if mdls then for _, mdl in ipairs( mdls ) do teampmlist:AddLine( mdl ) end end

            local vp = infotable.voiceprofile
            voiceprofile:SelectOptionByKey( vp and vp or "/NIL" ) 

            teamweaponrestrictions = infotable.weaponrestrictions or {}
        end
    end

    RegisterLambdaPanel( "LambdaTeam", "Opens a panel that allows you to create and edit lambda teams. You must be a Super Admin to use this panel. Make sure to refresh the team list after adding or deleting a team.", OpenLambdaTeamPanel )
end