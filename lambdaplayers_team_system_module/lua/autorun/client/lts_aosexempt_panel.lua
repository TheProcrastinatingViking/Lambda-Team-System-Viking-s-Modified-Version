print("[LTS] AOS Exempt panel client file LOADED")

hook.Add("AddToolMenuCategories", "LTS_AOS_CreateCategory", function()
    spawnmenu.AddToolCategory("Utilities", "Lambda Players", "Lambda Players")
end)


net.Receive("LTS_SendAOSExemptData", function()
    local exempt = net.ReadTable()
    local teamData = net.ReadTable()

    if IsValid(LTS_AOSPanel) then
        LTS_AOSPanel:PopulatePanel(exempt, teamData)
    end
end)

local PANEL = {}

function PANEL:Init()

    self:SetSize(500, 500)
    self:Dock(FILL)

    self.teamA = ""
    self.teamB = ""

    self.TeamACombo = vgui.Create("DComboBox", self)
    self.TeamACombo:Dock(TOP)
    self.TeamACombo:SetTall(28)
    self.TeamACombo:SetValue("Team A (ignores)")

    self.TeamBCombo = vgui.Create("DComboBox", self)
    self.TeamBCombo:Dock(TOP)
    self.TeamBCombo:SetTall(28)
    self.TeamBCombo:SetValue("Team B")

    self.AddBtn = vgui.Create("DButton", self)
    self.AddBtn:Dock(TOP)
    self.AddBtn:SetTall(32)
    self.AddBtn:SetText("Add AOS Exemption")
    self.AddBtn.DoClick = function()
        if self.teamA ~= "" and self.teamB ~= "" and self.teamA ~= self.teamB then
            net.Start("LTS_AddAOSExempt")
                net.WriteString(self.teamA)
                net.WriteString(self.teamB)
            net.SendToServer()

            timer.Simple(0.25, function() self:RequestUpdate() end)
        end
    end

    self.ClearBtn = vgui.Create("DButton", self)
    self.ClearBtn:Dock(TOP)
    self.ClearBtn:SetTall(32)
    self.ClearBtn:SetText("Clear ALL AOS Exemptions")
    self.ClearBtn:SetTooltip("Removes ALL Attack-On-Sight exemptions")
    self.ClearBtn.DoClick = function()
        Derma_Query(
            "Remove ALL AOS exemptions?",
            "Confirm",
            "Yes", function()
                net.Start("LTS_ClearAOSExempt")
                net.SendToServer()
                timer.Simple(0.35, function() self:RequestUpdate() end)
            end,
            "Cancel"
        )
    end

    self.Scroll = vgui.Create("DScrollPanel", self)
    self.Scroll:Dock(FILL)

    self:RequestUpdate()
end

function PANEL:RequestUpdate()
    net.Start("LTS_RequestAOSExemptData")
    net.SendToServer()
end

function PANEL:PopulatePanel(exempt, teamData)

    -- Repopulate dropdowns
    self.TeamACombo:Clear()
    self.TeamBCombo:Clear()

	self.TeamACombo:AddChoice("ALL TEAMS")

	for name, _ in pairs(teamData) do
		self.TeamACombo:AddChoice(name)
	end

	self.TeamBCombo:AddChoice("ALL TEAMS")

	for name, _ in pairs(teamData) do
		self.TeamBCombo:AddChoice(name)
	end

    self.TeamACombo.OnSelect = function(_,_,val)
        self.teamA = val
    end

    self.TeamBCombo.OnSelect = function(_,_,val)
        self.teamB = val
    end

    -- Clear scroll
    self.Scroll:Clear()

    -- Display entries
    for teamA, tbl in pairs(exempt) do
        for teamB, _ in pairs(tbl) do

            local pnl = vgui.Create("DPanel", self.Scroll)
            pnl:Dock(TOP)
            pnl:SetTall(36)
            pnl:DockMargin(0, 0, 0, 4)

            pnl.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(35,35,35))
                draw.SimpleText(teamA .. " ignores " .. teamB,
                    "DermaDefaultBold",
                    10, h/2,
                    color_white,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )
            end

            -- Remove button
            local btn = vgui.Create("DButton", pnl)
            btn:Dock(RIGHT)
            btn:SetWide(120)
            btn:SetText("Remove")
            btn.DoClick = function()
                net.Start("LTS_RemoveAOSExempt")
                    net.WriteString(teamA)
                    net.WriteString(teamB)
                net.SendToServer()

                timer.Simple(0.25, function() self:RequestUpdate() end)
            end
        end
    end
end

vgui.Register("LTS_AOSPanel", PANEL, "DPanel")

hook.Add("PopulateToolMenu", "LTS_AddAOSPanel", function()
    spawnmenu.AddToolMenuOption(
        "Utilities",
        "Lambda Players",
        "TeamAOSExempt",
        "AOS Exemptions",
        "",
        "",
        function(panel)
            LTS_AOSPanel = vgui.Create("LTS_AOSPanel")
            panel:AddItem(LTS_AOSPanel)
        end
    )
end)

net.Receive("LTS_AddAOSExempt", function()
    notification.AddLegacy("AOS exemption added.", NOTIFY_GENERIC, 3)
    surface.PlaySound("buttons/button14.wav")
end)

net.Receive("LTS_RemoveAOSExempt", function()
    notification.AddLegacy("AOS exemption removed.", NOTIFY_CLEANUP, 3)
    surface.PlaySound("buttons/button19.wav")
end)

net.Receive("LTS_ClearAOSExempt", function()
    notification.AddLegacy("All AOS exemptions cleared!", NOTIFY_ERROR, 4)
    surface.PlaySound("buttons/button15.wav")
end)
