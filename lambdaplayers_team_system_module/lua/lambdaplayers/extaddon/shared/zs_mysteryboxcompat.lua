if not SERVER then return end

local function CreateCompatConVar(name, default, desc, min, max, settings)
    if CreateLambdaConvar then
        return CreateLambdaConvar(name, default, true, false, false, desc, min or 0, max or 1, settings or {})
    end

    return CreateConVar(name, tostring(default), FCVAR_ARCHIVE, desc, min, max)
end

local cv_enabled = CreateCompatConVar( "lambdaplayers_mysterybox_enabled", 1, "If enabled, Lambda Players will be allowed to use the Mystery Box Entity (Sandbox/TTT) (2023 Update).", 0, 1, { name = "Enable Mystery Box Compat", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_box_radius = CreateCompatConVar( "lambdaplayers_mysterybox_box_radius", 90, "Distance for Lambdas to use nearby mystery boxes (putting it higher than 100 will make it look freaky).", 1, 500, { name = "Box Use Radius", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_reward_radius = CreateCompatConVar( "lambdaplayers_mysterybox_reward_radius", 100, "Distance for Lambdas to claim nearby mystery box rewards.", 1, 500, { name = "Reward Pickup Radius", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_scan_interval = CreateCompatConVar( "lambdaplayers_mysterybox_scan_interval", 0.33, "How often Lambda Players search for boxes and rewards (Lower values will cause slight performance decreases).", 0.05, 2.0, { name = "Search Interval", type = "Slider", decimals = 2, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_require_outofcombat = CreateCompatConVar( "lambdaplayers_mysterybox_require_outofcombat", 1, "If enabled, Lambda Players will only use mystery boxes while out of combat.", 0, 1, { name = "Use Mystery Box Out Of Combat", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )

local cv_skip_owned = CreateCompatConVar( "lambdaplayers_mysterybox_skip_owned", 1, "If enabled, Lambda Players will not collect weapons from the Mystery Box that they already have.", 0, 1, { name = "Skip Current Weapon", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_guard_enabled = CreateCompatConVar( "lambdaplayers_mysterybox_guard_enabled", 0, "If enabled, some Lambda Players near mystery boxes may stay and guard the area around it.", 0, 1, { name = "Guard Nearby Boxes", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_guard_chance = CreateCompatConVar( "lambdaplayers_mysterybox_guard_chance", 30, "Chance that a Lambda Player will guard a mystery box.", 0, 100, { name = "Guard Chance", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_guard_radius = CreateCompatConVar( "lambdaplayers_mysterybox_guard_radius", 250, "How close a guarding Lambda should remain to the box.", 64, 1000, { name = "Guard Radius", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_guard_time_min = CreateCompatConVar( "lambdaplayers_mysterybox_guard_time_min", 8, "Minimum time a Lambda Player will guard a mystery box.", 1, 120, { name = "Guard Time Min", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_guard_time_max = CreateCompatConVar( "lambdaplayers_mysterybox_guard_time_max", 18, "Maximum time a Lambda Player will guard near mystery box.", 1, 120, { name = "Guard Time Max", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_uses_min = CreateCompatConVar( "lambdaplayers_mysterybox_uses_min", 1, "Minimum times Lambda Players can use mystery boxes.", 0, 20, { name = "Min Box Uses", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_uses_max = CreateCompatConVar( "lambdaplayers_mysterybox_uses_max", 3, "Maximum times Lambda Players can use mystery boxes.", 0, 20, { name = "Max Box Uses", type = "Slider", decimals = 0, category = "Team System - Zombie Survival - Mystery Box Addon" } )
local cv_debug = CreateCompatConVar( "lambdaplayers_mysterybox_debug", 0, "Print debugging information for the compatibility patches between Lambda Players & the Mystery Box Entity.", 0, 1, { name = "Debug Logging", type = "Bool", category = "Team System - Zombie Survival - Mystery Box Addon" } )

local MysteryBoxToLambda = {
    m9k_acr = "m9k_ar_acr",
    m9k_ak47 = "m9k_ar_ak47",
    m9k_ak74 = "m9k_ar_ak74",
    m9k_an94 = "m9k_ar_an94",
    m9k_amd65 = "m9k_ar_amd65",
    m9k_asval = "m9k_ar_asval",
    m9k_f2000 = "m9k_ar_f2000",
    m9k_fal = "m9k_ar_fal",
    m9k_famas = "m9k_ar_famas",
    m9k_g36 = "m9k_ar_g36c",
    m9k_hk416 = "m9k_ar_hk416",
    m9k_m4a1 = "m9k_ar_m4a1",
    m9k_m14sp = "m9k_ar_m14",
    m9k_m16a4_acog = "m9k_ar_m16a1",
    m9k_scar = "m9k_ar_scar",
    m9k_tar21 = "m9k_ar_tar21",
    m9k_vikhr = "m9k_ar_vikhr",
    m9k_winchester73 = "m9k_ar_winchester_rifle",

    m9k_colt1911 = "m9k_pistol_colt1911",
    m9k_deagle = "m9k_pistol_deagle",
    m9k_hk45 = "m9k_pistol_hk45",
    m9k_luger = "m9k_pistol_luger",
    m9k_m29satan = "m9k_pistol_satan",
    m9k_m92beretta = "m9k_pistol_m92beretta",
    m9k_model3russian = "m9k_pistol_model3russian",
    m9k_mp412rex = "m9k_pistol_mp412rex",
    m9k_python = "m9k_pistol_python",
    m9k_remington1858 = "m9k_pistol_remington1858",
    m9k_ragingbull = "m9k_pistol_ragingb",
    m9k_sig_p229r = "m9k_pistol_sigp229",
    m9k_model500 = "m9k_pistol_sw500",
    m9k_model627 = "m9k_pistol_sw627",
    m9k_usp = "m9k_pistol_usp",

    m9k_bizonp19 = "m9k_smg_bizon",
    m9k_honeybadger = "m9k_smg_honeybadger",
    m9k_kac_pdw = "m9k_smg_pdw",
    m9k_magpulpdr = "m9k_smg_pdr",
    m9k_mp5 = "m9k_smg_mp5",
    m9k_mp5sd = "m9k_smg_mp5sd",
    m9k_mp7 = "m9k_smg_mp7",
    m9k_mp9 = "m9k_smg_mp9",
    m9k_p90 = "m9k_smg_p90",
    m9k_sten = "m9k_smg_sten",
    m9k_tec9 = "m9k_smg_tec9",
    m9k_thompson = "m9k_smg_tommygun",
    m9k_uzi = "m9k_smg_uzi",
    m9k_ump45 = "m9k_smg_ump45",
    m9k_vector = "m9k_smg_vector",
    m9k_usc = "m9k_smg_usc",

    m9k_1887winchester = "m9k_hvy_1887winchester",
    m9k_barret_m82 = "m9k_hvy_barret_m82",
    m9k_browningauto5 = "m9k_hvy_browningauto5",
    m9k_m24 = "m9k_hvy_m24",
    m9k_m249lmg = "m9k_hvy_m249",
    m9k_m3 = "m9k_hvy_benellim3",
    m9k_m60 = "m9k_hvy_m60",
    m9k_mossberg590 = "m9k_hvy_mossberg590",
    m9k_pkm = "m9k_hvy_pkm",
    m9k_psg1 = "m9k_hvy_psg1",
    m9k_remington870 = "m9k_hvy_remington870",
    m9k_spas12 = "m9k_hvy_spas12",
    m9k_svu = "m9k_hvy_dragunovsvu",
    m9k_svt40 = "m9k_hvy_svt40",
    m9k_usas = "m9k_hvy_usas",
}

local function CompatEnabled() return cv_enabled:GetBool() end
local function BoxRadius() return math.max(cv_box_radius:GetInt(), 1) end
local function RewardRadius() return math.max(cv_reward_radius:GetInt(), 1) end
local function ScanInterval() return math.max(cv_scan_interval:GetFloat(), 0.05) end
local function RequireOutOfCombat() return cv_require_outofcombat:GetBool() end
local function DebugEnabled() return cv_debug:GetBool() end
local function SkipOwnedWeapons() return cv_skip_owned:GetBool() end
local function GuardEnabled() return cv_guard_enabled:GetBool() end
local function GuardChance() return math.Clamp(cv_guard_chance:GetInt(), 0, 100) end
local function GuardRadius() return math.max(cv_guard_radius:GetInt(), 64) end

local function GuardTimeMin()
    return math.max(cv_guard_time_min:GetFloat(), 1)
end

local function GuardTimeMax()
    return math.max(cv_guard_time_max:GetFloat(), GuardTimeMin())
end

local function MysteryBoxUsesMin()
    return math.max(cv_uses_min:GetInt(), 0)
end

local function MysteryBoxUsesMax()
    return math.max(cv_uses_max:GetInt(), MysteryBoxUsesMin())
end

local function DebugPrint(msg)
    if DebugEnabled() then
        print("[Lambda MysteryBox] " .. tostring(msg))
    end
end

local nextScanTime = 0

local function CompatEnabled()
    return cv_enabled:GetBool()
end

local function BoxRadius()
    return math.max(cv_box_radius:GetInt(), 1)
end

local function RewardRadius()
    return math.max(cv_reward_radius:GetInt(), 1)
end

local function ScanInterval()
    return math.max(cv_scan_interval:GetFloat(), 0.05)
end

local function RequireOutOfCombat()
    return cv_require_outofcombat:GetBool()
end

local function DebugEnabled()
    return cv_debug:GetBool()
end

local function DebugPrint(msg)
    if DebugEnabled() then
        print("[Lambda MysteryBox] " .. tostring(msg))
    end
end

local function IsLambda(ent)
    return IsValid(ent) and ent.IsLambdaPlayer == true
end

local function LambdaIsDead(ent)
    if not IsLambda(ent) then return true end
    if ent.GetIsDead and ent:GetIsDead() then return true end
    return ent:Health() <= 0
end

local function GetAllLambdas()
    if GetLambdaPlayers then return GetLambdaPlayers() end

    local lambdas = {}
    for _, ent in ipairs(ents.GetAll()) do
        if IsLambda(ent) then
            lambdas[#lambdas + 1] = ent
        end
    end
    return lambdas
end

local function TeamAllowsWeapon(lambda, lambdaClass)
    if not IsLambda(lambda) then return true end

    local restricts = lambda.l_TeamWepRestrictions
    if not restricts then return true end

    return restricts[lambdaClass] == true
end

local function ResolveLambdaWeaponClass(boxClass)
    if not isstring(boxClass) or boxClass == "" then return nil end
    if not _LAMBDAPLAYERSWEAPONS then return nil end

    if _LAMBDAPLAYERSWEAPONS[boxClass] then
        return boxClass
    end

    local aliased = MysteryBoxToLambda[boxClass]
    if aliased and _LAMBDAPLAYERSWEAPONS[aliased] then
        return aliased
    end

    local suffix = string.match(boxClass, "^m9k_(.+)$")
    if suffix then
        local guesses = {
            "m9k_ar_" .. suffix,
            "m9k_pistol_" .. suffix,
            "m9k_smg_" .. suffix,
            "m9k_hvy_" .. suffix
        }

        for _, guess in ipairs(guesses) do
            if _LAMBDAPLAYERSWEAPONS[guess] then
                DebugPrint("Heuristic alias matched " .. boxClass .. " -> " .. guess)
                return guess
            end
        end
    end

    DebugPrint("Missing alias for reward class: " .. boxClass)
    return nil
end

local function LambdaCanTakeBoxReward(lambda, rewardEnt)
    if not CompatEnabled() then return false end
    if not IsLambda(lambda) then return false end
    if not IsValid(rewardEnt) or rewardEnt:GetClass() ~= "zombies_box_weapon" then return false end
    if not rewardEnt:GetNWBool("CanTake", false) then return false end

    local boxClass = rewardEnt:GetNWString("weapon_class", "")
    if boxClass == "" or boxClass == "zombies_teddybear" then return false end
    if string.StartWith(boxClass, "zombies_perk_") then return false end

    local lambdaClass = ResolveLambdaWeaponClass(boxClass)
    if not lambdaClass then return false end
    if not lambda.WeaponDataExists or not lambda:WeaponDataExists(lambdaClass) then
        DebugPrint("Lambda weapon data missing for resolved class: " .. tostring(lambdaClass))
        return false
    end
	
	if SkipOwnedWeapons() and lambda.l_Weapon == lambdaClass then
		DebugPrint("Blocked duplicate weapon: " .. tostring(lambdaClass))
		return false
	end

    if not TeamAllowsWeapon(lambda, lambdaClass) then
        DebugPrint("Team restriction blocked weapon: " .. tostring(lambdaClass))
        return false
    end

    return true, lambdaClass, boxClass
end

local function RollMysteryBoxUseCount()
    local minUses = MysteryBoxUsesMin()
    local maxUses = MysteryBoxUsesMax()

    if maxUses < minUses then
        maxUses = minUses
    end

    return math.random(minUses, maxUses)
end

local function ResetMysteryBoxSession(lambda)
    lambda.l_MB_BoxEntIndex = nil
    lambda.l_MB_UsesRemaining = nil
end

local function UpdateMysteryBoxSession(lambda)
    local entIndex = lambda.l_MB_BoxEntIndex
    if not entIndex then return end

    local box = Entity(entIndex)
    if not IsValid(box) then
        ResetMysteryBoxSession(lambda)
        return
    end

    local leaveDist = BoxRadius() + 128
    if lambda:GetPos():DistToSqr(box:GetPos()) > (leaveDist * leaveDist) then
        ResetMysteryBoxSession(lambda)
    end
end

local function EnsureMysteryBoxSession(lambda, box)
    local entIndex = box:EntIndex()

    if lambda.l_MB_BoxEntIndex ~= entIndex then
        lambda.l_MB_BoxEntIndex = entIndex
        lambda.l_MB_UsesRemaining = RollMysteryBoxUseCount()
        DebugPrint("New box session: " .. tostring(lambda.l_MB_UsesRemaining) .. " uses")
    elseif lambda.l_MB_UsesRemaining == nil then
        lambda.l_MB_UsesRemaining = RollMysteryBoxUseCount()
    end

    return lambda.l_MB_UsesRemaining or 0
end

local function ConsumeMysteryBoxUse(lambda)
    local uses = lambda.l_MB_UsesRemaining or 0
    lambda.l_MB_UsesRemaining = math.max(uses - 1, 0)
    DebugPrint("Box uses remaining: " .. tostring(lambda.l_MB_UsesRemaining))
end

local function PatchBoxReward()
    local stored = scripted_ents.GetStored("zombies_box_weapon")
    if not stored or not stored.t then return end

    local ENT = stored.t
    if ENT._LambdaMysteryBoxRewardPatched then return end
    ENT._LambdaMysteryBoxRewardPatched = true

    local oldUse = ENT.Use

    function ENT:Use(activator, caller)
        if not IsValid(self) then return end

        if CompatEnabled() and IsLambda(activator) then
            local canTake, lambdaClass, boxClass = LambdaCanTakeBoxReward(activator, self)
            if not canTake then
                DebugPrint("Lambda could not use reward: " .. tostring(self:GetNWString("weapon_class", "")))
                return
            end

            self:SetNWBool("CanTake", false)

            activator:SwitchWeapon(lambdaClass, true, true)

            self:EmitSound("hoff/mysterybox/bo2/buy_00.wav")
            activator:EmitSound("hoff/mysterybox/bo2/accept_00.wav")

            if IsValid(self.BoxRef) then
                self.BoxRef:CloseBox()
            end

            DebugPrint("Lambda took reward " .. tostring(boxClass) .. " as " .. tostring(lambdaClass))

            self:Remove()
            return
        end

        if oldUse then
            return oldUse(self, activator, caller)
        end
    end
end

local function StartMysteryBoxGuard(lambda, box)
    if not GuardEnabled() then return end
    if not IsValid(box) then return end
    if math.random(1, 100) > GuardChance() then return end

    lambda.l_MB_GuardBox = box
    lambda.l_MB_GuardUntil = CurTime() + math.Rand(GuardTimeMin(), GuardTimeMax())

    DebugPrint("Started guarding box for " .. tostring(lambda.l_MB_GuardUntil - CurTime()) .. " seconds")
end

local function HandleMysteryBoxGuard(lambda)
    if not GuardEnabled() then return false end

    local box = lambda.l_MB_GuardBox
    local guardUntil = lambda.l_MB_GuardUntil or 0

    if not IsValid(box) or CurTime() >= guardUntil then
        lambda.l_MB_GuardBox = nil
        lambda.l_MB_GuardUntil = nil
        return false
    end

    local radius = GuardRadius()
    if lambda:GetPos():DistToSqr(box:GetPos()) > (radius * radius) then
        lambda.l_MB_GuardBox = nil
        lambda.l_MB_GuardUntil = nil
        return false
    end

    if not (lambda.InCombat and lambda:InCombat()) then
        if lambda.CancelMovement then
            lambda:CancelMovement()
        end

        lambda.l_NextMysteryBoxUseT = CurTime() + 0.5
    end

    return true
end

local function ShouldLambdaBox(lambda)
    if not CompatEnabled() then return false end
    if not IsLambda(lambda) or LambdaIsDead(lambda) then return false end
    if (lambda.l_NextMysteryBoxUseT or 0) > CurTime() then return false end

    if RequireOutOfCombat() and lambda.InCombat and lambda:InCombat() then
        return false
    end

    return true
end

local function ForceLambdaUseNearbyBox(lambda)
    UpdateMysteryBoxSession(lambda)

    if HandleMysteryBoxGuard(lambda) then
        return true
    end

    local pos = lambda:WorldSpaceCenter()

    for _, ent in ipairs(ents.FindInSphere(pos, RewardRadius())) do
        if ent:GetClass() == "zombies_box_weapon" then
            local canTake = LambdaCanTakeBoxReward(lambda, ent)
            if canTake then
                if lambda.CancelMovement then
                    lambda:CancelMovement()
                end

                ent:Use(lambda, lambda)
                lambda.l_NextMysteryBoxUseT = CurTime() + 1.5
                return true
            end
        end
    end

    for _, ent in ipairs(ents.FindInSphere(pos, BoxRadius())) do
        if ent:GetClass() == "zombies_mysterybox" and ent:GetNWBool("CanUse", false) then
            local usesRemaining = EnsureMysteryBoxSession(lambda, ent)

            if usesRemaining <= 0 then
                StartMysteryBoxGuard(lambda, ent)
                return false
            end

            if lambda.CancelMovement then
                lambda:CancelMovement()
            end

            ent:Use(lambda, lambda)
            ConsumeMysteryBoxUse(lambda)

            if (lambda.l_MB_UsesRemaining or 0) <= 0 then
                StartMysteryBoxGuard(lambda, ent)
            end

            lambda.l_NextMysteryBoxUseT = CurTime() + 2.0
            return true
        end
    end

    return false
end

hook.Add("InitPostEntity", "LambdaMysteryBox_MergedPatch", function()
    PatchBoxReward()
end)

hook.Add("OnReloaded", "LambdaMysteryBox_MergedPatchReload", function()
    timer.Simple(0, PatchBoxReward)
end)

hook.Add("Think", "LambdaMysteryBox_ForcedUseThink", function()
    if CurTime() < nextScanTime then return end
    nextScanTime = CurTime() + ScanInterval()

    if not CompatEnabled() then return end

    for _, lambda in ipairs(GetAllLambdas()) do
        if not ShouldLambdaBox(lambda) then continue end
        ForceLambdaUseNearbyBox(lambda)
    end
end)