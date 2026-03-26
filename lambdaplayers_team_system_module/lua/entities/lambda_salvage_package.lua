AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Lambda Salvage Package"
ENT.Category = "Lambda Players"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.IsLambdaSalvagePackage = true

local packageModels = {
    "models/props_junk/cardboard_box001b.mdl",
    "models/props_junk/cardboard_box002a.mdl",
    "models/props_junk/cardboard_box003a.mdl",
    "models/props_junk/cardboard_box004a.mdl"
}

if SERVER then
    local function SR_PackageHealth()
        local cv = GetConVar( "lambdaplayers_teamsystem_salvagerun_packages_health" )
        return math.max( 1, ( cv and cv:GetInt() ) or 40 )
    end

    local function SR_PackageYield()
        local minCV = GetConVar( "lambdaplayers_teamsystem_salvagerun_packages_yield_min" )
        local maxCV = GetConVar( "lambdaplayers_teamsystem_salvagerun_packages_yield_max" )

        local minYield = math.max( 1, ( minCV and minCV:GetInt() ) or 1 )
        local maxYield = math.max( minYield, ( maxCV and maxCV:GetInt() ) or 2 )

        return math.random( minYield, maxYield )
    end

    function ENT:Initialize()
        self:SetModel( self.PackageModel or packageModels[ math.random( #packageModels ) ] )

        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetUseType( SIMPLE_USE )

        self:SetHealth( self.PackageHealth or SR_PackageHealth() )
        self:SetMaxHealth( self:Health() )

        self.LTS_Broken = false

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:Wake()
            phys:SetMass( 20 )
        end
    end

    function ENT:OnTakeDamage( dmginfo )
        if self.LTS_Broken then return end

        if LambdaTeams and LambdaTeams.GetCurrentGamemodeID and LambdaTeams:GetCurrentGamemodeID() != 7 then
            return
        end

        self:TakePhysicsDamage( dmginfo )

        local newHealth = ( self:Health() - math.max( 1, dmginfo:GetDamage() ) )
        self:SetHealth( newHealth )

        if newHealth > 0 then return end

        self.LTS_Broken = true

        local dropAmount = self.PackageYield or SR_PackageYield()
        local dropPos = self:GetPos() + Vector( 0, 0, 12 )

        if LambdaTeams and LambdaTeams.SpawnPackageSalvage then
            LambdaTeams:SpawnPackageSalvage( dropPos, dropAmount )
        elseif LambdaTeams and LambdaTeams.SpawnGeneratorSalvage then
            LambdaTeams:SpawnGeneratorSalvage( dropPos, dropAmount )
        end

        self:EmitSound( "Wood_Crate.Break", 75, math.random( 95, 105 ) )

        local ed = EffectData()
        ed:SetOrigin( self:WorldSpaceCenter() )
        util.Effect( "GlassImpact", ed, true, true )

        self:Remove()
    end
else
    local color_white = color_white or Color( 255, 255, 255 )
    local color_shadow = Color( 0, 0, 0, 220 )
    local color_yellow = Color( 255, 210, 80 )

    local function DrawPackagePanel( pos, ang )
        cam.Start3D2D( pos, ang, 0.12 )
            draw.SimpleTextOutlined( "SALVAGE PACKAGE", "Trebuchet24", 0, -8, color_yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_shadow )
            draw.SimpleTextOutlined( "Destroy to spill salvage", "Trebuchet18", 0, 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_shadow )
        cam.End3D2D()
    end

    function ENT:Draw()
        self:DrawModel()

        if !LambdaTeams or !LambdaTeams.GetCurrentGamemodeID or LambdaTeams:GetCurrentGamemodeID() != 7 then return end

        local lp = LocalPlayer()
        if !IsValid( lp ) then return end
        if lp:EyePos():DistToSqr( self:GetPos() ) > ( 3500 * 3500 ) then return end

        local pos = self:LocalToWorld( Vector( 0, 0, self:OBBMaxs().z + 10 ) )

        local toEye = lp:EyePos() - pos
        toEye.z = 0

        local ang
        if toEye:LengthSqr() > 0.001 then
            toEye:Normalize()
            pos = pos + ( toEye * 4 )
            ang = Angle( 0, toEye:Angle().y - 90, 90 )
        else
            ang = Angle( 0, lp:EyeAngles().y - 90, 90 )
        end

        DrawPackagePanel( pos, ang )
        DrawPackagePanel( pos, Angle( ang.p, ang.y + 180, ang.r ) )
    end
end

scripted_ents.Register( ENT, "lambda_salvage_package" )