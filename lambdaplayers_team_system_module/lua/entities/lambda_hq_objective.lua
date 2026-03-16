AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Lambda HQ Objective"
ENT.Category = "Lambda Players"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.IsLambdaHQ = true

local vec_white = Vector( 1, 1, 1 )

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "Active" )      
    self:NetworkVar( "Bool", 1, "Arming" )     
    self:NetworkVar( "Bool", 2, "IsCaptured" )    
    self:NetworkVar( "Float", 0, "CapturePercent" )
    self:NetworkVar( "String", 0, "CapturerName" ) 
    self:NetworkVar( "String", 1, "ContesterName" )
    self:NetworkVar( "Vector", 0, "CapturerColor" )
    self:NetworkVar( "Vector", 1, "ContesterColor" )
end

if SERVER then
    local IsValid = IsValid
    local ipairs = ipairs
    local Clamp = math.Clamp
    local FindInSphere = ents.FindInSphere
    local ignorePlys = GetConVar( "ai_ignoreplayers" )
    local aiDisabled = GetConVar( "ai_disabled" )

	-- THIS NEEDS TO EXIST IN THE TEAM SYSTEM IF THIS IS GOING TO WORK HERE, SO DONT MESS WITH ANY OF WHAT YOU SEE HERE IN THERE
    local cvCapRate       = GetConVar( "lambdaplayers_teamsystem_hq_capturerate" )
    local cvCapRange      = GetConVar( "lambdaplayers_teamsystem_hq_capturerange" )
    local cvScoreTime     = GetConVar( "lambdaplayers_teamsystem_hq_scoregaintime" )
    local cvScoreAmount   = GetConVar( "lambdaplayers_teamsystem_hq_scoregainamount" )

    local function CVFloat( cv, def )
        if not cv then return def end
        return cv:GetFloat()
    end

    local function CVInt( cv, def )
        if not cv then return def end
        return cv:GetInt()
    end

    local function IsAliveTeamActor( ent )
        if not IsValid( ent ) then return false end
        if ent.IsLambdaPlayer then
            return ( not ent:GetIsDead() )
        end
        if ent:IsPlayer() then
            if ignorePlys and ignorePlys:GetBool() then return false end
            return ent:Alive()
        end
        return false
    end

    function ENT:Initialize()
        self:SetModel( "models/props_lab/workspace004.mdl" )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_NONE )
        self:SetSolid( SOLID_VPHYSICS )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:EnableMotion( false )
            phys:Wake()
        end

        self:ResetHQ()
    end

    function ENT:ResetHQ()
        self:SetActive( false )
        self:SetArming( false )

        self:SetIsCaptured( false )
        self:SetCapturePercent( 0 )

        self:SetCapturerName( "Neutral" )
        self:SetContesterName( "Neutral" )

        self:SetCapturerColor( vec_white )
        self:SetContesterColor( vec_white )

        self.HQ_Destroyed = false
        self.HQ_DestroyReason = nil 
        self.HQ_DestroyedBy = nil    
        self.HQ_NextScoreT = 0
    end

    function ENT:ForceDestroyHQ()
        if self.HQ_Destroyed then return end

        self.HQ_Destroyed = true
        self.HQ_DestroyReason = "time"
        self.HQ_DestroyedBy = nil

        self:SetActive( false )
        self:SetArming( false )

        self:SetIsCaptured( false )
        self:SetCapturePercent( 0 )
        self:SetCapturerName( "Neutral" )
        self:SetContesterName( "Neutral" )
        self:SetCapturerColor( vec_white )
        self:SetContesterColor( vec_white )
    end

    function ENT:GetTeamNameForEnt( ent )
        local teamName = LambdaTeams:GetPlayerTeam( ent )
        if not teamName or teamName == "" then return nil end
        return teamName
    end

    function ENT:GetTeamColorByName( teamName )
        return LambdaTeams:GetTeamColor( teamName, false ) or vec_white
    end

    function ENT:Think()
        if not cvCapRate then cvCapRate = GetConVar( "lambdaplayers_teamsystem_hq_capturerate" ) end
        if not cvCapRange then cvCapRange = GetConVar( "lambdaplayers_teamsystem_hq_capturerange" ) end
        if not cvScoreTime then cvScoreTime = GetConVar( "lambdaplayers_teamsystem_hq_scoregaintime" ) end
        if not cvScoreAmount then cvScoreAmount = GetConVar( "lambdaplayers_teamsystem_hq_scoregainamount" ) end

        if GetGlobalInt( "LambdaTeamMatch_GameID", 0 ) ~= 5 or self.HQ_Destroyed or not self:GetActive() then
            self:NextThink( CurTime() + 0.25 )
            return true
        end

        if aiDisabled and aiDisabled:GetBool() then
            self:NextThink( CurTime() + 0.25 )
            return true
        end

        local capRate  = CVFloat( cvCapRate, 2.0 )
        local capRange = CVInt( cvCapRange, 500 )
        if capRate < 0.01 then capRate = 0.01 end
        if capRange < 1 then capRange = 1 end

        local teamsHere = {}
        local pos = self:GetPos()

        for _, ent in ipairs( FindInSphere( pos, capRange ) ) do
            if not IsAliveTeamActor( ent ) then continue end
            if not self:Visible( ent ) then continue end

            local tname = self:GetTeamNameForEnt( ent )
            if not tname then continue end

            teamsHere[ tname ] = ( teamsHere[ tname ] or 0 ) + 1
        end

        local uniqueTeams = 0
        local soleTeam = nil
        for tname, _ in pairs( teamsHere ) do
            uniqueTeams = uniqueTeams + 1
            soleTeam = tname
            if uniqueTeams > 1 then break end
        end

        if uniqueTeams ~= 1 then
            local pct = self:GetCapturePercent()
            if self:GetIsCaptured() then
                if pct < 100 then
                    pct = Clamp( pct + ( capRate * 0.5 ), 0, 100 )
                    self:SetCapturePercent( pct )
                end
            else
                if pct > 0 then
                    pct = Clamp( pct - ( capRate * 0.5 ), 0, 100 )
                    self:SetCapturePercent( pct )
                end
            end

            self:SetContesterName( "" )
            self:SetContesterColor( vec_white )

            self:NextThink( CurTime() + 0.1 )
            return true
        end

        local tname = soleTeam
        local tclr = self:GetTeamColorByName( tname )

        local pct = self:GetCapturePercent()
        local captured = self:GetIsCaptured()
        local owner = self:GetCapturerName()

        if not captured then
            if self:GetContesterName() ~= tname then
                self:SetContesterName( tname )
                self:SetContesterColor( tclr )
                pct = 0
            end

            pct = Clamp( pct + capRate, 0, 100 )
            self:SetCapturePercent( pct )

            if pct >= 100 then
                self:SetIsCaptured( true )
                self:SetCapturerName( tname )
                self:SetCapturerColor( tclr )

                self:SetContesterName( "" )
                self:SetContesterColor( vec_white )

                self.HQ_NextScoreT = CurTime() + CVFloat( cvScoreTime, 5 )
            end
        else
            if owner == tname then
                pct = Clamp( pct + capRate, 0, 100 )
                self:SetCapturePercent( pct )
                self:SetContesterName( "" )
                self:SetContesterColor( vec_white )
            else
                self:SetContesterName( tname )
                self:SetContesterColor( tclr )

                pct = Clamp( pct - capRate, 0, 100 )
                self:SetCapturePercent( pct )

                if pct <= 0 then
                    self.HQ_Destroyed = true
                    self.HQ_DestroyReason = "captured"
                    self.HQ_DestroyedBy = tname

                    self:SetActive( false )
                    self:SetArming( false )

                    self:SetIsCaptured( false )
                    self:SetCapturePercent( 0 )
                    self:SetCapturerName( "Neutral" )
                    self:SetContesterName( "Neutral" )
                    self:SetCapturerColor( vec_white )
                    self:SetContesterColor( vec_white )
                end
            end
        end

        if self:GetIsCaptured() then
            local now = CurTime()
            if now >= ( self.HQ_NextScoreT or 0 ) then
                local amt = CVInt( cvScoreAmount, 5 )
                if amt < 1 then amt = 1 end

                local teamName = self:GetCapturerName()
                if teamName and teamName ~= "" and teamName ~= "Neutral" then
                    LambdaTeams:AddTeamPoints( teamName, amt )
                end

                self.HQ_NextScoreT = now + CVFloat( cvScoreTime, 5 )
            end
        end

        self:NextThink( CurTime() + 0.1 )
        return true
    end
end

if CLIENT then
    local cam = cam
    local DrawText = draw.DrawText
    local tostring = tostring
    local CurTime = CurTime
    local angAxisVec = Vector( 0, 0, 1 )
    local drawAng = Angle( 0, 0, 90 )
    local drawVec = Vector( 0, 0, 0 )
    local floor = math.floor
    local LerpVector = LerpVector

    function ENT:Draw3DText( text, pos, ang, scale )
        local color = self:GetCapturerColor()
        local capPerc = self:GetCapturePercent()

        if self:GetArming() and not self:GetActive() then
            color = vec_white
        elseif not self:GetIsCaptured() then
            color = LerpVector( ( capPerc / 100 ), color, self:GetContesterColor() )
        else
            color = LerpVector( ( ( 100 - capPerc ) / 100 ), color, vec_white )
        end

        color = color:ToColor()

        cam.Start3D2D( pos, ang, scale )
            DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
        cam.End3D2D()

        ang:RotateAroundAxis( angAxisVec, 180 )

        cam.Start3D2D( pos, ang, scale )
            DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
        cam.End3D2D()
    end

    function ENT:Draw()
        local myPos = self:GetPos()
        drawAng[ 2 ] = ( CurTime() * 20 % 360 )

        local topLine
        if self:GetArming() and not self:GetActive() then
            topLine = "[HQ] ACTIVATING..."
        elseif self:GetActive() then
            topLine = "[HQ] " .. ( self:GetIsCaptured() and self:GetCapturerName() or ( self:GetContesterName() ~= "" and self:GetContesterName() or "Neutral" ) )
        else
            topLine = "[HQ] INACTIVE"
        end

        drawVec.z = 100
        self:Draw3DText( topLine, myPos + drawVec, drawAng, 0.5 )

        drawVec.z = 110
        self:Draw3DText( tostring( floor( self:GetCapturePercent() ) ), myPos + drawVec, drawAng, 0.5 )

        self:DrawModel()
    end
end
