AddCSLuaFile()

local ENT = {}
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "KD Tag"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if SERVER then
    local function GetVictimTeam(self)
        local vt = self:GetNW2String("LTS_KD_VictimTeam", "")
        if vt == "" then
            vt = self:GetNWString("LTS_KD_VictimTeam", "")
        end
        if vt == "" then
            vt = self.VictimTeam or ""
        end
        return vt
    end

    local function ResolvePickerTeam(ent)
        if LambdaTeams and LambdaTeams.GetPlayerTeam then
            local t = LambdaTeams:GetPlayerTeam(ent)
            if t and t ~= "" then return t end
        end

        -- hard fallback: actual gmod team name
        local tname = team.GetName(ent:Team())
        if tname and tname ~= "" then return tname end

        return nil
    end

    function ENT:Initialize()
        local mdl = self.TagModel or "models/props_lab/reciever01d.mdl"
        self:SetModel(mdl)
        self:SetModelScale(0.85, 0)

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        -- allow StartTouch to fire
        self:SetTrigger(true)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(5)
        end

        self.NextPickupCheck = 0
        self.Collected = false
        self.RemoveAt = self.RemoveAt or (CurTime() + 20)
    end

    local function TryCollect(self, ent)
        if self.Collected then return false end
        if not IsValid(ent) then return false end
        if not (ent:IsPlayer() or ent.IsLambdaPlayer) then return false end

        if not LambdaTeams or not LambdaTeams.GetCurrentGamemodeID then return false end

        local gmID = LambdaTeams:GetCurrentGamemodeID()
        if gmID ~= 4 and gmID ~= 7 then return false end
		
		-- Don't allow instant pickup right on spawn
		local enableAt = self.PickupEnableAt or self:GetNWFloat("LTS_KD_PickupEnableAt", 0)
		if enableAt ~= 0 and CurTime() < enableAt then return false end

		-- Prevent the victim entity from picking up its own tag immediately
		local victimIdx = self.VictimEntIndex or self:GetNWInt("LTS_KD_VictimEntIndex", -1)
		if victimIdx ~= -1 and ent:EntIndex() == victimIdx then return false end


        local victimTeam = GetVictimTeam(self)
        if victimTeam == "" then return false end

        local pickerTeam = ResolvePickerTeam(ent)
        if not pickerTeam or pickerTeam == "" then return false end

        local isConfirm = ( pickerTeam ~= victimTeam )

        if gmID == 7 then
            if LambdaTeams.OnSalvageCollected then
                LambdaTeams:OnSalvageCollected( ent, victimTeam, self )
            end

            self.Collected = true
            self:Remove()
            return true
        end

        if isConfirm then
            LambdaTeams:AddTeamPoints( pickerTeam, 1 )
        end
		
		if SERVER and LambdaTeams and LambdaTeams.PlayConVarSound then
			LambdaTeams:PlayConVarSound(
				isConfirm and "lambdaplayers_teamsystem_kd_snd_confirm" or "lambdaplayers_teamsystem_kd_snd_deny",
				pickerTeam
			)

			net.Start( "lambda_teamsystem_kd_feedback" )
				net.WriteString( pickerTeam )
				net.WriteBool( isConfirm )
			net.Broadcast()
		end

		self.Collected = true
		self:Remove()
		return true
		end

		function ENT:StartTouch(ent)
			TryCollect(self, ent)
		end

		function ENT:Think()
			if self.Collected then return end

			if CurTime() >= (self.RemoveAt or 0) then
				self:Remove()
				return
			end

			if CurTime() < (self.NextPickupCheck or 0) then return end
			self.NextPickupCheck = CurTime() + 0.15

			-- Backup collection method (works even if physics/touch is weird)
			local pos = self:GetPos()
			for _, ent in ipairs(ents.FindInSphere(pos, 60)) do
				if TryCollect(self, ent) then return end
			end
		end
	end

if CLIENT then
    local colConfirm = Color(80, 255, 80)
    local colDeny    = Color(80, 160, 255)
    local colShadow  = Color(0, 0, 0, 220)

    local function GetVictimTeamCL(self)
        local vt = self:GetNW2String("LTS_KD_VictimTeam", "")
        if vt == "" then
            vt = self:GetNWString("LTS_KD_VictimTeam", "")
        end
        return vt
    end

	function ENT:Draw()
		self:DrawModel()

		if not LambdaTeams or not LambdaTeams.GetCurrentGamemodeID then return end
		local gmID = LambdaTeams:GetCurrentGamemodeID()
		if gmID ~= 4 and gmID ~= 7 then return end

		local lp = LocalPlayer()
		if not IsValid(lp) then return end

		-- World text toggle
		local cvText = GetConVar("lambdaplayers_teamsystem_kd_worldtext")
		if cvText and not cvText:GetBool() then return end

		-- Distance limit from convar
		local maxDist = 2500
		local cvDist = GetConVar("lambdaplayers_teamsystem_kd_worldtextdist")
		if cvDist then maxDist = cvDist:GetInt() end

		local distSqr = lp:GetPos():DistToSqr(self:GetPos())
		if distSqr > (maxDist * maxDist) then return end

		local myTeam = LambdaTeams:GetPlayerTeam(lp)
		if not myTeam or myTeam == "" then return end

		local victimTeam = GetVictimTeamCL(self)
		if victimTeam == "" then return end

		local isConfirm = (myTeam ~= victimTeam)
		local label = isConfirm and "CONFIRM" or "DENY"
		local clr = isConfirm and colConfirm or colDeny

		local pos = self:GetPos() + Vector(0, 0, 18)
		local ang = Angle(0, EyeAngles().y - 90, 90)

		cam.Start3D2D(pos, ang, 0.10)
			draw.SimpleTextOutlined(label, "Trebuchet24", 0, 0, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, colShadow)
		cam.End3D2D()
	end


    hook.Add("PreDrawHalos", "LTS_KDTagHalos", function()
		local cvHalo = GetConVar("lambdaplayers_teamsystem_kd_halo")
		if cvHalo and !cvHalo:GetBool() then return end

        if not LambdaTeams or not LambdaTeams.GetCurrentGamemodeID then return end
        local gmID = LambdaTeams:GetCurrentGamemodeID()
        if gmID ~= 4 and gmID ~= 7 then return end

        local lp = LocalPlayer()
        if not IsValid(lp) then return end

        local myTeam = LambdaTeams:GetPlayerTeam(lp)
        if not myTeam or myTeam == "" then return end

        local confirmEnts, denyEnts = {}, {}

        for _, ent in ipairs(ents.FindByClass("lambda_kd_tag")) do
            local victimTeam = GetVictimTeamCL(ent)
            if victimTeam == "" then continue end

            if myTeam ~= victimTeam then
                confirmEnts[#confirmEnts + 1] = ent
            else
                denyEnts[#denyEnts + 1] = ent
            end
        end

        if #confirmEnts > 0 then
            halo.Add(confirmEnts, colConfirm, 2, 2, 1, true, true)
        end
        if #denyEnts > 0 then
            halo.Add(denyEnts, colDeny, 2, 2, 1, true, true)
        end
    end)
end

scripted_ents.Register(ENT, "lambda_kd_tag")
