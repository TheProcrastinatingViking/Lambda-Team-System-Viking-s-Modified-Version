AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Lambda Salvage Generator"
ENT.Category = "Lambda Players"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.IsLambdaSalvageGenerator = true

local generatorModels = {
    "models/props_lab/workspace003.mdl",
    "models/props_lab/servers.mdl"
}

local generatorOffsets = {
	[ "models/props_lab/workspace003.mdl" ] = {
		panel = Vector( 12, 118, 0 ),
		output = Vector( 42, 42, 28 )
	},
    [ "models/props_lab/servers.mdl" ] = {
        panel = Vector( 0, 0, 0 ),
        output = Vector( 36, 0, 28 )
    }
}

local function GetGeneratorOffsets( ent )
    return generatorOffsets[ string.lower( ent:GetModel() or "" ) ] or generatorOffsets[ "models/props_lab/servers.mdl" ]
end

function ENT:SetupDataTables()
    self:NetworkVar( "Float", 0, "Progress" )
    self:NetworkVar( "Float", 1, "NextGenerateAt" )
    self:NetworkVar( "String", 0, "WorkingTeam" )
end

if SERVER then
    local function SR_Enabled()
        local cv = GetConVar( "lambdaplayers_teamsystem_salvagerun_generator_enabled" )
        return ( cv and cv:GetBool() ) or false
    end

    local function SR_GamemodeActive()
        return LambdaTeams and LambdaTeams.GetCurrentGamemodeID and LambdaTeams:GetCurrentGamemodeID() == 7
    end

    local function SR_UseRange()
        local cv = GetConVar( "lambdaplayers_teamsystem_salvagerun_generator_userange" )
        return math.max( 50, ( cv and cv:GetInt() ) or 140 )
    end

    local function SR_HumanTime()
        local cv = GetConVar( "lambdaplayers_teamsystem_salvagerun_generator_humantime" )
        return math.max( 0.25, ( cv and cv:GetFloat() ) or 2.0 )
    end

    local function SR_LambdaTime()
        local cv = GetConVar( "lambdaplayers_teamsystem_salvagerun_generator_lambdatime" )
        return math.max( 0.25, ( cv and cv:GetFloat() ) or 2.5 )
    end

    local function SR_Cooldown()
        local cv = GetConVar( "lambdaplayers_teamsystem_salvagerun_generator_cooldown" )
        return math.max( 0.0, ( cv and cv:GetFloat() ) or 4.0 )
    end

    local function SR_Yield()
        local cv = GetConVar( "lambdaplayers_teamsystem_salvagerun_generator_yield" )
        return math.max( 1, math.floor( ( cv and cv:GetInt() ) or 2 ) )
    end

    local function GetEntTeamName( ent )
        if !IsValid( ent ) then return nil end

        if LambdaTeams and LambdaTeams.GetPlayerTeam then
            local teamName = LambdaTeams:GetPlayerTeam( ent )
            if teamName and teamName != "" then return teamName end
        end

        if ent:IsPlayer() then
            local tname = team.GetName( ent:Team() )
            if tname and tname != "" then return tname end
        end

        return nil
    end

    local function IsValidWorker( ent )
        if !IsValid( ent ) then return false end

        if ent.IsLambdaPlayer then
            return LambdaIsValid( ent ) and !ent:GetIsDead()
        end

        if ent:IsPlayer() then
            return ent:Alive()
        end

        return false
    end

    function ENT:Initialize()
        self:SetModel( generatorModels[ math.random( #generatorModels ) ] )
        self:SetMoveType( MOVETYPE_NONE )
        self:SetSolid( SOLID_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetUseType( CONTINUOUS_USE )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:Wake()
            phys:EnableMotion( false )
        end

        self:SetProgress( 0 )
        self:SetNextGenerateAt( 0 )
        self:SetWorkingTeam( "" )

        self._HumanUseEnt = nil
        self._HumanUseUntil = 0
    end

    function ENT:Use( activator )
        if !SR_Enabled() or !SR_GamemodeActive() then return end
        if !IsValidWorker( activator ) or !activator:IsPlayer() then return end
        if !GetEntTeamName( activator ) then return end
        if activator:GetPos():DistToSqr( self:GetPos() ) > ( SR_UseRange() * SR_UseRange() ) then return end

        self._HumanUseEnt = activator
        self._HumanUseUntil = CurTime() + 0.2
    end

	function ENT:ProduceSalvage( teamName )
		if !LambdaTeams or !LambdaTeams.SpawnGeneratorSalvage then return end

		local offsets = GetGeneratorOffsets( self )
		local outPos = self:LocalToWorld( offsets.output )
		LambdaTeams:SpawnGeneratorSalvage( outPos, SR_Yield() )

		self:SetProgress( 0 )
		self:SetWorkingTeam( teamName or "" )
		self:SetNextGenerateAt( CurTime() + SR_Cooldown() )
		self:EmitSound( "buttons/button17.wav", 70, 105 )
	end

    function ENT:Think()
        if !SR_Enabled() or !SR_GamemodeActive() then
            self:SetProgress( 0 )
            self:SetWorkingTeam( "" )
            self:NextThink( CurTime() + 0.2 )
            return true
        end

        if CurTime() < self:GetNextGenerateAt() then
            self:NextThink( CurTime() + 0.05 )
            return true
        end

        local worker, neededTime

        if IsValid( self._HumanUseEnt ) and CurTime() <= ( self._HumanUseUntil or 0 ) and self._HumanUseEnt:GetPos():DistToSqr( self:GetPos() ) <= ( SR_UseRange() * SR_UseRange() ) then
            worker = self._HumanUseEnt
            neededTime = SR_HumanTime()
        else
            self._HumanUseEnt = nil

            for _, ent in ipairs( ents.FindInSphere( self:GetPos(), SR_UseRange() ) ) do
                if !IsValidWorker( ent ) or !ent.IsLambdaPlayer then continue end
                if !GetEntTeamName( ent ) then continue end

                worker = ent
                neededTime = SR_LambdaTime()
                break
            end
        end

        if !IsValid( worker ) then
            self:SetProgress( math.max( 0, self:GetProgress() - 0.04 ) )
            if self:GetProgress() <= 0 then
                self:SetWorkingTeam( "" )
            end

            self:NextThink( CurTime() + 0.05 )
            return true
        end

        local teamName = GetEntTeamName( worker ) or ""
        if teamName == "" then
            self:SetProgress( 0 )
            self:SetWorkingTeam( "" )
            self:NextThink( CurTime() + 0.05 )
            return true
        end

        if self:GetWorkingTeam() != "" and self:GetWorkingTeam() != teamName then
            self:SetProgress( 0 )
        end

        self:SetWorkingTeam( teamName )
        self:SetProgress( math.min( 1, self:GetProgress() + ( FrameTime() / neededTime ) ) )

        if self:GetProgress() >= 1 then
            self:ProduceSalvage( teamName )
        end

        self:NextThink( CurTime() + 0.05 )
        return true
    end

	else
    local color_white = color_white or Color( 255, 255, 255 )
    local color_shadow = Color( 0, 0, 0, 220 )
    local color_yellow = Color( 255, 210, 80 )
    local color_idle = Color( 220, 220, 220 )
    local color_cooldown = Color( 255, 140, 80 )
    local floor = math.floor
    local ceil = math.ceil
    local CurTime = CurTime

    local function DrawBar( x, y, w, h, frac, fillClr, text )
        surface.SetDrawColor( 0, 0, 0, 180 )
        surface.DrawRect( x, y, w, h )

        surface.SetDrawColor( 40, 40, 40, 220 )
        surface.DrawOutlinedRect( x, y, w, h, 2 )

        surface.SetDrawColor( fillClr.r, fillClr.g, fillClr.b, 240 )
        surface.DrawRect( x + 3, y + 3, math.max( 0, ( w - 6 ) * math.Clamp( frac, 0, 1 ) ), h - 6 )

        draw.SimpleTextOutlined( text, "Trebuchet18", x + ( w / 2 ), y + ( h / 2 ), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_shadow )
    end

	function ENT:Draw()
		self:DrawModel()

		if !LambdaTeams or !LambdaTeams.GetCurrentGamemodeID or LambdaTeams:GetCurrentGamemodeID() != 7 then return end

		local lp = LocalPlayer()
		if !IsValid( lp ) then return end
		if lp:EyePos():DistToSqr( self:GetPos() ) > ( 5000 * 5000 ) then return end

		local offsets = GetGeneratorOffsets( self )
		local pos = self:LocalToWorld( Vector( 0, 0, self:OBBMaxs().z + 12 ) + offsets.panel )

		local toEye = lp:EyePos() - pos
		toEye.z = 0

		local ang
		if toEye:LengthSqr() > 0.001 then
			toEye:Normalize()
			pos = pos + ( toEye * 10 ) -- push text outward so it does not sit inside the model
			ang = Angle( 0, toEye:Angle().y - 90, 90 )
		else
			ang = Angle( 0, lp:EyeAngles().y - 90, 90 )
		end

		local function DrawGeneratorPanel( drawAng )
			local teamName = self:GetWorkingTeam()
			local progress = self:GetProgress()
			local nextGenerateAt = self:GetNextGenerateAt()
			local cooldownLeft = math.max( 0, ceil( nextGenerateAt - CurTime() ) )

			cam.Start3D2D( pos, drawAng, 0.12 )
				draw.SimpleTextOutlined( "SALVAGE GENERATOR", "Trebuchet24", 0, -18, color_yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_shadow )

				if cooldownLeft > 0 then
					draw.SimpleTextOutlined( "COOLDOWN", "Trebuchet18", 0, 8, color_cooldown, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_shadow )
					draw.SimpleTextOutlined( "Ready in " .. cooldownLeft .. "s", "Trebuchet18", 0, 34, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_shadow )

				elseif teamName != "" and progress > 0 then
					local teamClr = ( LambdaTeams.GetTeamColor and LambdaTeams:GetTeamColor( teamName, true ) ) or color_yellow

					draw.SimpleTextOutlined( string.upper( teamName ), "Trebuchet18", 0, 8, teamClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_shadow )
					DrawBar( -120, 28, 240, 24, progress, teamClr, "GENERATING: " .. floor( progress * 100 ) .. "%" )

				else
					draw.SimpleTextOutlined( "IDLE", "Trebuchet18", 0, 8, color_idle, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_shadow )
					draw.SimpleTextOutlined( "Hold +USE to Generate Salvage", "Trebuchet18", 0, 34, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_shadow )
				end
			cam.End3D2D()
		end

		DrawGeneratorPanel( ang )
		DrawGeneratorPanel( Angle( ang.p, ang.y + 180, ang.r ) )
	end
end

scripted_ents.Register( ENT, "lambda_salvage_generator" )