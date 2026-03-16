AddCSLuaFile()

local ENT = {}
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Salvage Tag"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if SERVER then
    local function GetVictimTeam( self )
        local vt = self:GetNW2String( "LTS_KD_VictimTeam", "" )
        if vt == "" then
            vt = self:GetNWString( "LTS_KD_VictimTeam", "" )
        end
        if vt == "" then
            vt = self.VictimTeam or ""
        end
        return vt
    end

    local function ResolvePickerTeam( ent )
        if LambdaTeams and LambdaTeams.GetPlayerTeam then
            local t = LambdaTeams:GetPlayerTeam( ent )
            if t and t ~= "" then return t end
        end

        local tname = team.GetName( ent:Team() )
        if tname and tname ~= "" then return tname end

        return nil
    end

    function ENT:Initialize()
        local mdl = self.TagModel or "models/props_lab/reciever01d.mdl"
        self:SetModel( mdl )
        self:SetModelScale( 0.85, 0 )

        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
        self:SetTrigger( true )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:Wake()
            phys:SetMass( 5 )
        end

        self.NextPickupCheck = 0
        self.Collected = false
        self.RemoveAt = self.RemoveAt or ( CurTime() + 20 )
    end

    local function TryCollect( self, ent )
        if self.Collected then return false end
        if !IsValid( ent ) then return false end
        if !( ent:IsPlayer() or ent.IsLambdaPlayer ) then return false end

        if !LambdaTeams or !LambdaTeams.GetCurrentGamemodeID then return false end
        if LambdaTeams:GetCurrentGamemodeID() != 7 then return false end

        local enableAt = self.PickupEnableAt or self:GetNWFloat( "LTS_KD_PickupEnableAt", 0 )
        if enableAt ~= 0 and CurTime() < enableAt then return false end

        local victimIdx = self.VictimEntIndex or self:GetNWInt( "LTS_KD_VictimEntIndex", -1 )
        if victimIdx ~= -1 and ent:EntIndex() == victimIdx then return false end

        local victimTeam = GetVictimTeam( self )
        if victimTeam == "" then return false end

        local pickerTeam = ResolvePickerTeam( ent )
        if !pickerTeam or pickerTeam == "" then return false end

        if LambdaTeams.OnSalvageCollected then
            LambdaTeams:OnSalvageCollected( ent, victimTeam, self )
        end

        self.Collected = true
        self:Remove()
        return true
    end

    function ENT:StartTouch( ent )
        TryCollect( self, ent )
    end

    function ENT:Think()
        if self.Collected then return end

        if CurTime() >= ( self.RemoveAt or 0 ) then
            self:Remove()
            return
        end

        if CurTime() < ( self.NextPickupCheck or 0 ) then return end
        self.NextPickupCheck = CurTime() + 0.15

        local pos = self:GetPos()
        for _, ent in ipairs( ents.FindInSphere( pos, 60 ) ) do
            if TryCollect( self, ent ) then return end
        end
    end
else
    local colSalvage = Color( 255, 210, 80 )
    local colShadow = Color( 0, 0, 0, 220 )

    function ENT:Draw()
        self:DrawModel()

        if !LambdaTeams or !LambdaTeams.GetCurrentGamemodeID then return end
        if LambdaTeams:GetCurrentGamemodeID() != 7 then return end

        local lp = LocalPlayer()
        if !IsValid( lp ) then return end

        local cvText = GetConVar( "lambdaplayers_teamsystem_salvagerun_worldtext" )
        if cvText and !cvText:GetBool() then return end

        local maxDist = 2500
        local cvDist = GetConVar( "lambdaplayers_teamsystem_salvagerun_worldtextdist" )
        if cvDist then maxDist = cvDist:GetInt() end

        if lp:GetPos():DistToSqr( self:GetPos() ) > ( maxDist * maxDist ) then return end

        local pos = self:GetPos() + Vector( 0, 0, 18 )
        local ang = Angle( 0, EyeAngles().y - 90, 90 )

        cam.Start3D2D( pos, ang, 0.10 )
            draw.SimpleTextOutlined( "SALVAGE", "Trebuchet24", 0, 0, colSalvage, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, colShadow )
        cam.End3D2D()
    end
end

scripted_ents.Register( ENT, "lambda_salvage_tag" )