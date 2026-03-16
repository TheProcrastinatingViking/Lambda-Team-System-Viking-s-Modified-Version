AddCSLuaFile()

local ENT = {}
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Lambda Sabotage Site"
ENT.Category = "Lambda Players"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local SITE_MODEL = "models/props_wasteland/horizontalcoolingtank04.mdl"
local BOMB_MODEL = "models/Combine_Helicopter/helicopter_bomb01.mdl"

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "SiteTeam" )
    self:NetworkVar( "String", 1, "ArmingTeam" )
    self:NetworkVar( "String", 2, "DestroyedBy" )

    self:NetworkVar( "Bool", 0, "IsArmed" )
    self:NetworkVar( "Bool", 1, "IsDestroyed" )

    self:NetworkVar( "Float", 0, "ArmProgress" )
    self:NetworkVar( "Float", 1, "DefuseProgress" )
    self:NetworkVar( "Float", 2, "DetonateAt" )
end

local function SetCompatString( ent, key, val )
    ent:SetNW2String( key, val )
    ent:SetNWString( key, val )
end

local function SetCompatBool( ent, key, val )
    ent:SetNW2Bool( key, val )
    ent:SetNWBool( key, val )
end

if SERVER then
    local CurTime = CurTime
    local IsValid = IsValid
    local ipairs = ipairs
    local FindInSphere = ents.FindInSphere
    local color_white = color_white or Color( 255, 255, 255 )
    local color_glacier = Color( 130, 164, 192 )

    local function GetLivingTeam( ent )
        if !IsValid( ent ) then return nil end
        if !( ent:IsPlayer() or ent.IsLambdaPlayer ) then return nil end

        if ent.IsLambdaPlayer then
            if ent:GetIsDead() then return nil end
        elseif !ent:Alive() then
            return nil
        end

        if !LambdaTeams or !LambdaTeams.GetPlayerTeam then return nil end

        local teamName = LambdaTeams:GetPlayerTeam( ent )
        if !teamName or teamName == "" then return nil end

        return teamName
    end

    local function IsSiteInteractor( ent )
        if !IsValid( ent ) then return false end

        if ent.IsLambdaPlayer then
            return true
        end

        if ent:IsPlayer() then
            return ent:KeyDown( IN_USE )
        end

        return false
    end

    local function AreFriendlyTeams( teamA, teamB )
        if !teamA or !teamB or teamA == "" or teamB == "" then return false end
        if teamA == teamB then return true end

        local allies = LambdaTeams and LambdaTeams.AlliedTeams and LambdaTeams.AlliedTeams[ teamA ]
        return ( allies and allies[ teamB ] ) or false
    end

    local function GetResolvedSiteTeam( self )
        local teamName = self:GetSiteTeam()

        if !teamName or teamName == "" then
            teamName = self.LTS_SabotageTeam or self:GetNW2String( "LTS_SAB_Team", self:GetNWString( "LTS_SAB_Team", "" ) )
            if teamName and teamName != "" then
                self:SetSiteTeam( teamName )
            end
        end

        return teamName or ""
    end

    local function GetInteractionState( self, radius )
        local ownerTeam = GetResolvedSiteTeam( self )
        local defenderTeams = {}
        local attackerTeams = {}

        for _, ent in ipairs( FindInSphere( self:GetPos(), radius ) ) do
            local entTeam = GetLivingTeam( ent )
            if !entTeam or !IsSiteInteractor( ent ) then continue end

            if AreFriendlyTeams( ownerTeam, entTeam ) then
                defenderTeams[ entTeam ] = true
            else
                attackerTeams[ entTeam ] = true
            end
        end

        local defenderTeam, defenderCount = nil, 0
        for teamName in pairs( defenderTeams ) do
            defenderCount = defenderCount + 1
            defenderTeam = teamName
        end

        local attackerTeam, attackerCount = nil, 0
        for teamName in pairs( attackerTeams ) do
            attackerCount = attackerCount + 1
            attackerTeam = teamName
            if attackerCount > 1 then break end
        end

        local defendersPresent = ( defenderCount > 0 )
        local contested = ( attackerCount > 1 or ( defendersPresent and attackerCount > 0 ) )

        return defendersPresent, defenderTeam or ownerTeam, attackerTeam, contested
    end

    function ENT:ResetSite( teamName )
        if teamName != nil then
            self:SetSiteTeam( teamName )
        end

        self:SetArmingTeam( "" )
        self:SetDestroyedBy( "" )

        if self.SetDefusingTeam then
            self:SetDefusingTeam( "" )
        end

        self:SetIsArmed( false )
        self:SetIsDestroyed( false )

        self:SetArmProgress( 0 )
        self:SetDefuseProgress( 0 )
        self:SetDetonateAt( 0 )

        self.LTS_SabotageDestroyed = false
        self.LTS_SabotageResolved = false
        self.LTS_SabotageDestroyedBy = nil

        SetCompatString( self, "LTS_SAB_Team", self:GetSiteTeam() )
        SetCompatString( self, "LTS_SAB_DestroyedBy", "" )
        SetCompatString( self, "LTS_SAB_DefusingTeam", "" )
        SetCompatBool( self, "LTS_SAB_Armed", false )
        SetCompatBool( self, "LTS_SAB_Destroyed", false )

        self:RemoveBombProp()
        self:SetColor( color_white )
    end

    function ENT:Initialize()
        self:SetModel( SITE_MODEL )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetUseType( SIMPLE_USE )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:Wake()
            phys:EnableMotion( false )
        end

        self:ResetSite( self.SpawnTeam or "" )
        self.NextLogicT = CurTime() + 0.1
    end

    function ENT:CreateBombProp()
        if IsValid( self.BombProp ) then return end

        local bomb = ents.Create( "prop_dynamic" )
        if !IsValid( bomb ) then return end

        bomb:SetModel( BOMB_MODEL )
        bomb:SetPos( self:GetPos() + self:GetUp() * 55 )
        bomb:SetAngles( self:GetAngles() )
        bomb:SetParent( self )
        bomb:SetMoveType( MOVETYPE_NONE )
        bomb:SetSolid( SOLID_NONE )
        bomb:Spawn()

        self.BombProp = bomb
    end

    function ENT:RemoveBombProp()
        if IsValid( self.BombProp ) then
            self.BombProp:Remove()
        end
        self.BombProp = nil
    end

    function ENT:ArmSite( teamName )
        local ownerTeam = GetResolvedSiteTeam( self )
        if self:GetIsDestroyed() or self:GetIsArmed() then return end
        if !teamName or teamName == "" then return end
        if AreFriendlyTeams( ownerTeam, teamName ) then return end

        local detonateTime = 10.0
        local cv = GetConVar( "lambdaplayers_teamsystem_sabotage_detonatetime" )
        if cv then detonateTime = math.max( 1.0, cv:GetFloat() ) end

        self:SetIsArmed( true )
        self:SetArmingTeam( teamName )
        self:SetDetonateAt( CurTime() + detonateTime )
        self:SetArmProgress( 100 )
        self:SetDefuseProgress( 0 )

        if self.SetDefusingTeam then
            self:SetDefusingTeam( "" )
        end

        SetCompatBool( self, "LTS_SAB_Armed", true )
        SetCompatString( self, "LTS_SAB_DefusingTeam", "" )

        self:CreateBombProp()
        self:EmitSound( "buttons/button17.wav", 75 )

        local ownerClr = LambdaTeams:GetTeamColor( ownerTeam, true ) or color_white
        local armClr = LambdaTeams:GetTeamColor( teamName, true ) or color_white

        LambdaPlayers_ChatAdd(
            nil,
            color_white, "[LTS] ",
            color_glacier, "Sabotage site for ",
            ownerClr, ownerTeam,
            color_glacier, " has been armed by ",
            armClr, teamName,
            color_white, "!"
        )
    end

    function ENT:DisarmSite()
        if !self:GetIsArmed() or self:GetIsDestroyed() then return end

        local ownerTeam = GetResolvedSiteTeam( self )

        self:SetIsArmed( false )
        self:SetArmingTeam( "" )
        self:SetDetonateAt( 0 )
        self:SetArmProgress( 0 )
        self:SetDefuseProgress( 0 )

        if self.SetDefusingTeam then
            self:SetDefusingTeam( "" )
        end

        SetCompatBool( self, "LTS_SAB_Armed", false )
        SetCompatString( self, "LTS_SAB_DefusingTeam", "" )

        self:RemoveBombProp()
        self:EmitSound( "buttons/button19.wav", 75 )

        local ownerClr = LambdaTeams:GetTeamColor( ownerTeam, true ) or color_white
        LambdaPlayers_ChatAdd(
            nil,
            color_white, "[LTS] ",
            ownerClr, ownerTeam,
            color_glacier, " defended and disarmed their sabotage site!"
        )
    end

    function ENT:DestroySite( destroyerTeam )
        if self:GetIsDestroyed() then return end

        destroyerTeam = destroyerTeam or self:GetArmingTeam() or ""

        self:SetIsDestroyed( true )
        self:SetDestroyedBy( destroyerTeam )
        self:SetIsArmed( false )
        self:SetDetonateAt( 0 )
        self:SetArmProgress( 0 )
        self:SetDefuseProgress( 0 )

        if self.SetDefusingTeam then
            self:SetDefusingTeam( "" )
        end

        SetCompatBool( self, "LTS_SAB_Destroyed", true )
        SetCompatBool( self, "LTS_SAB_Armed", false )
        SetCompatString( self, "LTS_SAB_DestroyedBy", destroyerTeam )
        SetCompatString( self, "LTS_SAB_DefusingTeam", "" )

        self.LTS_SabotageDestroyed = true
        self.LTS_SabotageDestroyedBy = destroyerTeam

        self:RemoveBombProp()
        self:EmitSound( "ambient/explosions/explode_4.wav", 90 )

        local fx = EffectData()
        fx:SetOrigin( self:GetPos() + self:GetUp() * 45 )
        util.Effect( "Explosion", fx, true, true )

        self:SetColor( Color( 70, 70, 70 ) )
    end

    function ENT:Think()
        if !LambdaTeams or !LambdaTeams.GetCurrentGamemodeID or LambdaTeams:GetCurrentGamemodeID() != 8 then
            self:NextThink( CurTime() + 0.1 )
            return true
        end

        if CurTime() < ( self.NextLogicT or 0 ) then
            self:NextThink( CurTime() + 0.05 )
            return true
        end
        self.NextLogicT = CurTime() + 0.1

        local ownerTeam = GetResolvedSiteTeam( self )
        if ownerTeam == "" then
            self:NextThink( CurTime() + 0.1 )
            return true
        end

        local compatDestroyed = self:GetNW2Bool( "LTS_SAB_Destroyed", self:GetNWBool( "LTS_SAB_Destroyed", false ) )
        if compatDestroyed != self:GetIsDestroyed() then
            self:SetIsDestroyed( compatDestroyed )
        end

        local compatArmed = self:GetNW2Bool( "LTS_SAB_Armed", self:GetNWBool( "LTS_SAB_Armed", false ) )
        if compatArmed != self:GetIsArmed() then
            self:SetIsArmed( compatArmed )
        end

        if self:GetIsDestroyed() then
            self:NextThink( CurTime() + 0.1 )
            return true
        end

        local useRange = 140
        local useRangeCV = GetConVar( "lambdaplayers_teamsystem_sabotage_userange" )
        if useRangeCV then useRange = math.max( 50, useRangeCV:GetInt() ) end

        local plantTime = 3.0
        local plantCV = GetConVar( "lambdaplayers_teamsystem_sabotage_planttime" )
        if plantCV then plantTime = math.max( 0.5, plantCV:GetFloat() ) end

        local defuseEnabled = false
        local defuseEnabledCV = GetConVar( "lambdaplayers_teamsystem_sabotage_defuseenabled" )
        if defuseEnabledCV then defuseEnabled = defuseEnabledCV:GetBool() end

        local defuseTime = 4.0
        local defuseCV = GetConVar( "lambdaplayers_teamsystem_sabotage_defusetime" )
        if defuseCV then defuseTime = math.max( 0.5, defuseCV:GetFloat() ) end

        local defendersPresent, defenderTeam, attackerTeam, contested = GetInteractionState( self, useRange )
        local thinkDelay = 0.1
        local armStep = ( 100 / plantTime ) * thinkDelay
        local defuseStep = ( 100 / defuseTime ) * thinkDelay

        if self:GetIsArmed() then
            if CurTime() >= self:GetDetonateAt() then
                self:DestroySite( self:GetArmingTeam() )
                self:NextThink( CurTime() + thinkDelay )
                return true
            end

            if defuseEnabled and defendersPresent and !attackerTeam and !contested then
                if self.SetDefusingTeam then
                    self:SetDefusingTeam( defenderTeam or ownerTeam )
                end
                SetCompatString( self, "LTS_SAB_DefusingTeam", defenderTeam or ownerTeam )

                local defuseProg = math.min( 100, self:GetDefuseProgress() + defuseStep )
                self:SetDefuseProgress( defuseProg )
                self:SetArmProgress( math.max( 0, 100 - defuseProg ) )

                if defuseProg >= 100 then
                    self:DisarmSite()
                end
            else
                if self.SetDefusingTeam then
                    self:SetDefusingTeam( "" )
                end
                SetCompatString( self, "LTS_SAB_DefusingTeam", "" )
                self:SetDefuseProgress( math.max( 0, self:GetDefuseProgress() - 10 ) )
            end

            self:NextThink( CurTime() + thinkDelay )
            return true
        end

        if self.SetDefusingTeam then
            self:SetDefusingTeam( "" )
        end
        SetCompatString( self, "LTS_SAB_DefusingTeam", "" )

        if attackerTeam and !defendersPresent and !contested and !AreFriendlyTeams( ownerTeam, attackerTeam ) then
            if self:GetArmingTeam() != attackerTeam then
                self:SetArmingTeam( attackerTeam )
                self:SetArmProgress( 0 )
            end

            local armProg = math.min( 100, self:GetArmProgress() + armStep )
            self:SetArmProgress( armProg )
            self:SetDefuseProgress( 0 )

            if armProg >= 100 then
                self:ArmSite( attackerTeam )
            end
        else
            local armProg = math.max( 0, self:GetArmProgress() - 10 )
            self:SetArmProgress( armProg )
            self:SetDefuseProgress( 0 )

            if armProg <= 0 then
                self:SetArmingTeam( "" )
            end
        end

        self:NextThink( CurTime() + thinkDelay )
        return true
    end
end

if CLIENT then
    local color_white = color_white or Color( 255, 255, 255 )
    local color_red = Color( 255, 90, 90 )
    local color_yellow = Color( 255, 220, 100 )
    local color_shadow = Color( 0, 0, 0, 220 )
    local floor = math.floor
    local ceil = math.ceil

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

        if !LambdaTeams or !LambdaTeams.GetCurrentGamemodeID then return end
        if LambdaTeams:GetCurrentGamemodeID() != 8 then return end

        local lp = LocalPlayer()
        if !IsValid( lp ) then return end
        if lp:EyePos():DistToSqr( self:GetPos() ) > ( 5000 * 5000 ) then return end

        local teamName = self:GetNW2String( "LTS_SAB_Team", self:GetNWString( "LTS_SAB_Team", self:GetSiteTeam() ) )
        local armed = self:GetNW2Bool( "LTS_SAB_Armed", self:GetNWBool( "LTS_SAB_Armed", false ) )
		local defusingTeam = self:GetNW2String( "LTS_SAB_DefusingTeam", self:GetNWString( "LTS_SAB_DefusingTeam", "" ) )
        local destroyed = self:GetNW2Bool( "LTS_SAB_Destroyed", self:GetNWBool( "LTS_SAB_Destroyed", false ) )

        local ownerClr = ( LambdaTeams.GetTeamColor and LambdaTeams:GetTeamColor( teamName, true ) ) or color_white
        local statusText = "INTACT"
        local statusClr = ownerClr

        if destroyed then
            statusText = "DESTROYED"
            statusClr = color_red
        elseif armed then
            statusText = "ARMED"
            statusClr = color_yellow
        end

        local pos = self:GetPos() + Vector( 0, 0, 112 )
        local ang = Angle( 0, EyeAngles().y - 90, 90 )

        cam.Start3D2D( pos, ang, 0.18 )
            draw.SimpleTextOutlined( string.upper( teamName ) .. " SITE", "Trebuchet24", 0, -18, ownerClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_shadow )
            draw.SimpleTextOutlined( statusText, "Trebuchet18", 0, 8, statusClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_shadow )

            if !destroyed then
			if armed then
				local defuseProg = self:GetDefuseProgress()
				local timeLeft = math.max( 0, ceil( self:GetDetonateAt() - CurTime() ) )

				DrawBar( -120, 28, 240, 24, defuseProg / 100, color_yellow, "DEFUSE: " .. floor( defuseProg ) .. "%" )
				draw.SimpleTextOutlined( "Detonates in " .. timeLeft .. "s", "Trebuchet18", 0, 62, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_shadow )

				if defusingTeam != "" then
					local defuseClr = ( LambdaTeams.GetTeamColor and LambdaTeams:GetTeamColor( defusingTeam, true ) ) or ownerClr
					draw.SimpleTextOutlined( "DEFUSING: " .. string.upper( defusingTeam ), "Trebuchet18", 0, 84, defuseClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_shadow )
				end
			else
                    local armingTeam = self:GetArmingTeam()
                    local armProg = self:GetArmProgress()

                    if armingTeam != "" and armProg > 0 then
                        local armClr = ( LambdaTeams.GetTeamColor and LambdaTeams:GetTeamColor( armingTeam, true ) ) or color_white
                        DrawBar( -120, 28, 240, 24, armProg / 100, armClr, "ARMING: " .. floor( armProg ) .. "%" )
                    end
                end
            end
        cam.End3D2D()
    end
end

scripted_ents.Register( ENT, "lambda_sabotage_site" )