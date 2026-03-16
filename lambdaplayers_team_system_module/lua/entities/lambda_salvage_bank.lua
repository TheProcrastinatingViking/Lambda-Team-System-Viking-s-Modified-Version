AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Lambda Salvage Bank"
ENT.Category = "Lambda Players"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.IsLambdaSalvageBank = true

local vec_white = Vector( 1, 1, 1 )

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "IsCaptured" )

    self:NetworkVar( "String", 0, "PointName" )
    self:NetworkVar( "String", 1, "CapturerName" )
    self:NetworkVar( "String", 2, "ContesterTeam" )

    self:NetworkVar( "Vector", 0, "CapturerColor" )
    self:NetworkVar( "Vector", 1, "ContesterColor" )

    self:NetworkVar( "Float", 0, "CapturePercent" )
end

if SERVER then
    local random = math.random
    local IsValid = IsValid
    local ipairs = ipairs
    local FindInSphere = ents.FindInSphere
    local Clamp = math.Clamp
    local Rand = math.Rand
    local keynames = { "A", "B", "C", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
    local color_glacier = Color( 130, 164, 192 )

    local captureRate = GetConVar( "lambdaplayers_teamsystem_koth_capturerate" )
    local captureRange = GetConVar( "lambdaplayers_teamsystem_koth_capturerange" )

    function ENT:Initialize()
        self:SetModel( "models/props_lab/reciever_cart.mdl" )
        self:SetMoveType( MOVETYPE_NONE )
        self:SetSolid( SOLID_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:Wake()
            phys:EnableMotion( false )
        end

        self.OldColor = vec_white
        self.OldCapturer = "Neutral"
        self.IsNonTeamCaptured = false

        self:SetPointName( self.CustomName or ( "Bank " .. keynames[ random( #keynames ) ] .. self:GetCreationID() ) )
        self:SetIsCaptured( false )
        self:SetCapturerName( "Neutral" )
        self:SetCapturePercent( 0 )
        self:SetCapturerColor( vec_white )
        self:SetContesterTeam( "" )
        self:SetContesterColor( vec_white )

        local startTeam = self.SpawnTeam
        if startTeam and startTeam != "" then
            local teamClr = LambdaTeams and LambdaTeams.GetTeamColor and LambdaTeams:GetTeamColor( startTeam ) or vec_white

            self:SetIsCaptured( true )
            self:SetCapturerName( startTeam )
            self:SetCapturerColor( teamClr or vec_white )
            self:SetCapturePercent( 100 )
            self.IsNonTeamCaptured = false
        end
    end

    function ENT:GetCapturerTeamName( ent )
        if !IsValid( ent ) then return nil, true end

        local teamName = LambdaTeams:GetPlayerTeam( ent )
        if teamName and teamName != "" then
            return teamName, false
        end

        if ent:IsPlayer() then
            local tname = team.GetName( ent:Team() )
            if tname and tname != "" and LambdaTeams.RealTeams[ tname ] then
                return tname, false
            end
        end

        return nil, true
    end

    function ENT:GetCapturerTeamColor( ent )
        local teamName = self:GetCapturerTeamName( ent )
        local color = LambdaTeams:GetTeamColor( teamName )
        if !color then
            if ent:IsPlayer() then
                local plyClr = string.Explode( " ", ent:GetInfo( "cl_playercolor" ) )
                return Vector( plyClr[ 1 ], plyClr[ 2 ], plyClr[ 3 ] )
            end
            return ent:GetPlyColor()
        end
        return color
    end

    function ENT:IsValidSalvageCapturer( ent )
        if !IsValid( ent ) then return false end

        if ent.IsLambdaPlayer then
            return LambdaIsValid( ent ) and !ent:GetIsDead()
        end

        if ent:IsPlayer() then
            return ent:Alive()
        end

        return false
    end

    function ENT:IsContested()
        local curTeam = nil

        for _, ent in ipairs( FindInSphere( self:GetPos(), captureRange:GetInt() ) ) do
            if !self:IsValidSalvageCapturer( ent ) or !self:Visible( ent ) then continue end

            local entTeam = self:GetCapturerTeamName( ent )
            if !entTeam or entTeam == "" then continue end

            if !curTeam then
                curTeam = entTeam
                continue
            end

            if entTeam != curTeam then return true end
        end

        return false
    end

    function ENT:BecomeNeutral()
        self:EmitSound( "lambdaplayers/koth/pointneutral.mp3", 70 )
        self:SetIsCaptured( false )
        self:SetCapturePercent( 0 )
        self:SetCapturerName( "Neutral" )
        self:SetCapturerColor( vec_white )
        self:SetContesterTeam( "" )
        self:SetContesterColor( vec_white )
        self.IsNonTeamCaptured = false
    end

    function ENT:Think()
        self:SetContesterTeam( "" )
        self:SetContesterColor( vec_white )

        if !LambdaTeams or !LambdaTeams.GetCurrentGamemodeID or LambdaTeams:GetCurrentGamemodeID() != 7 then
            self:NextThink( CurTime() + 0.1 )
            return true
        end

        local capName = self:GetCapturerName()

        if !self:IsContested() then
            local capRate = captureRate:GetFloat()

            for _, ent in ipairs( FindInSphere( self:GetPos(), captureRange:GetInt() ) ) do
                if !self:IsValidSalvageCapturer( ent ) or !self:Visible( ent ) then continue end

                local entTeam, isNick = self:GetCapturerTeamName( ent )
                if !entTeam or entTeam == "" then continue end

                local capPerc = self:GetCapturePercent()

                if self:GetIsCaptured() then
                    if entTeam != capName then
                        self:SetCapturePercent( Clamp( capPerc - capRate, 0, 100 ) )

                        if capPerc <= 0 then
                            self.OldCapturer = capName
                            self:BecomeNeutral()
                        end
                    else
                        self:SetCapturePercent( Clamp( capPerc + capRate, 0, 100 ) )
                    end

                elseif entTeam != capName then
                    local capTeamClr = self:GetCapturerTeamColor( ent )

                    self:SetContesterTeam( entTeam )
                    self:SetContesterColor( capTeamClr )

                    if capPerc < 100 then
                        self:SetCapturePercent( Clamp( capPerc + capRate, 0, 100 ) )
                    else
                        for _, lambda in ipairs( GetLambdaPlayers() ) do
                            if lambda:GetIsDead() or self:GetCapturerTeamName( lambda ) != entTeam or ( ent != lambda and random( 1, 100 ) > lambda:GetVoiceChance() / 2 ) then continue end
                            lambda:SimpleTimer( Rand( 0.1, 1.0 ), function()
                                if IsValid( lambda ) then
                                    lambda:PlaySoundFile( lambda:GetVoiceLine( "kill" ) )
                                end
                            end )
                        end

                        self:EmitSound( "lambdaplayers/koth/pointcap.mp3", 70 )

                        self:SetIsCaptured( true )
                        self:SetCapturePercent( 100 )
                        self:SetCapturerName( entTeam )
                        self:SetCapturerColor( capTeamClr )
                        self.IsNonTeamCaptured = isNick

                        LambdaPlayers_ChatAdd(
                            nil,
                            color_white, "[LTS] ",
                            color_glacier, "[",
                            capTeamClr:ToColor(), self:GetPointName(),
                            color_glacier, "]",
                            " has been captured by ",
                            capTeamClr:ToColor(), entTeam,
                            ( entTeam != ent:Nick() and " (" .. ent:Nick() .. ")" or "" )
                        )

                        self.OldColor = self:GetCapturerColor()
                    end
                end
            end
        end

        self:NextThink( CurTime() + 0.05 )
        return true
    end
end

if ( CLIENT ) then

    local cam = cam
    local DrawText = draw.DrawText
    local CurTime = CurTime
    local angAxisVec = Vector( 0, 0, 1 )
    local drawAng = Angle( 0, 0, 90 )
    local floor = math.floor
    local string_upper = string.upper
    local LerpVector = LerpVector

    function ENT:Draw3DText( text, pos, ang, scale )
        local color = self:GetCapturerColor()
        local capPerc = self:GetCapturePercent()

        if !self:GetIsCaptured() then
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
        self:DrawModel()

        drawAng[ 2 ] = ( CurTime() * 20 % 360 )

        local titlePos = self:LocalToWorld( Vector( 0, 0, self:OBBMaxs().z + 18 ) )
        local percentPos = self:LocalToWorld( Vector( 0, 0, self:OBBMaxs().z + 26 ) )

        self:Draw3DText( "[BANK " .. string_upper( self:GetPointName() ) .. "] " .. self:GetCapturerName(), titlePos, drawAng, 0.35 )
        self:Draw3DText( floor( self:GetCapturePercent() ), percentPos, drawAng, 0.35 )
    end

end