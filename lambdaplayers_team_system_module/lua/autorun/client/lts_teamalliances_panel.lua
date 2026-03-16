hook.Add("AddToolMenuCategories", "LTS_CreateCategory", function()
    spawnmenu.AddToolCategory("Utilities", "Lambda Players", "Lambda Players")
end)


net.Receive("LTS_SendAllianceData", function()
    local allied = net.ReadTable()
    local teamData = net.ReadTable()

    if IsValid(LTS_AlliancePanel) then
        LTS_AlliancePanel:PopulatePanel(allied, teamData)
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
    self.TeamACombo:SetValue("Select Team A")

    self.TeamBCombo = vgui.Create("DComboBox", self)
    self.TeamBCombo:Dock(TOP)
    self.TeamBCombo:SetTall(28)
    self.TeamBCombo:SetValue("Select Team B")

    self.AddBtn = vgui.Create("DButton", self)
    self.AddBtn:Dock(TOP)
    self.AddBtn:SetTall(32)
    self.AddBtn:SetText("Create Alliance")
    self.AddBtn.DoClick = function()
        if self.teamA ~= "" and self.teamB ~= "" and self.teamA ~= self.teamB then
            net.Start("LTS_AddAlliance")
                net.WriteString(self.teamA)
                net.WriteString(self.teamB)
            net.SendToServer()

            timer.Simple(0.2, function() self:RequestUpdate() end)
        end
    end

    self.AllAlliesBtn = vgui.Create("DButton", self)
    self.AllAlliesBtn:Dock(TOP)
    self.AllAlliesBtn:SetTall(32)
    self.AllAlliesBtn:SetText("Make ALL Teams Allied")
    self.AllAlliesBtn:SetTooltip("Automatically allies every team with every other team.")
    self.AllAlliesBtn.DoClick = function()

        Derma_Query(
            "Are you sure? This will ally EVERY team with each other.",
            "Confirm",
            "Yes", function()
                net.Start("LTS_AllAllies")
                net.SendToServer()
                timer.Simple(0.3, function() self:RequestUpdate() end)
            end,
            "Cancel"
        )
    end

    self.ClearAllBtn = vgui.Create("DButton", self)
    self.ClearAllBtn:Dock(TOP)
    self.ClearAllBtn:SetTall(32)
    self.ClearAllBtn:SetText("Clear ALL Alliances")
    self.ClearAllBtn:SetTooltip("Removes all alliances between all teams.")

    self.ClearAllBtn.DoClick = function()
        Derma_Query(
            "Are you SURE you want to remove EVERY alliance?",
            "Confirm",
            "Yes", function()
                net.Start("LTS_ClearAllAllies")
                net.SendToServer()
                timer.Simple(0.3, function() self:RequestUpdate() end)
            end,
            "Cancel"
        )
    end

    self.Scroll = vgui.Create("DScrollPanel", self)
    self.Scroll:Dock(FILL)

    self:RequestUpdate()
end

function PANEL:RequestUpdate()
    net.Start("LTS_RequestAllianceData")
    net.SendToServer()
end

function PANEL:PopulatePanel(allied, teamData)

    self.TeamACombo:Clear()
    self.TeamBCombo:Clear()

    for teamName, _ in pairs(teamData) do
        self.TeamACombo:AddChoice(teamName)
        self.TeamBCombo:AddChoice(teamName)
    end

    self.TeamACombo.OnSelect = function(_, _, val)
        self.teamA = val
    end

    self.TeamBCombo.OnSelect = function(_, _, val)
        self.teamB = val
    end

    self.Scroll:Clear()

    for teamA, tbl in pairs(allied) do
        for teamB, _ in pairs(tbl) do

            if teamA < teamB then
                local pnl = vgui.Create("DPanel", self.Scroll)
                pnl:Dock(TOP)
                pnl:SetTall(36)
                pnl:DockMargin(0, 0, 0, 4)

                pnl.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35))
                    draw.SimpleText(teamA .. "  <->  " .. teamB,
                        "DermaDefaultBold", 10, h/2,
                        color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                local btn = vgui.Create("DButton", pnl)
                btn:Dock(RIGHT)
                btn:SetWide(120)
                btn:SetText("Remove")
                btn.DoClick = function()
                    net.Start("LTS_RemoveAlliance")
                        net.WriteString(teamA)
                        net.WriteString(teamB)
                    net.SendToServer()

                    timer.Simple(0.2, function() self:RequestUpdate() end)
                end
            end
        end
    end
end

vgui.Register("LTS_AlliancePanel", PANEL, "DPanel")


hook.Add("PopulateToolMenu", "LTS_AddAllianceMenu", function()
    spawnmenu.AddToolMenuOption(
        "Utilities",
        "Lambda Players",
        "TeamAlliances",
        "Team Alliances",
        "",
        "",
        function(panel)
            LTS_AlliancePanel = vgui.Create("LTS_AlliancePanel")
            panel:AddItem(LTS_AlliancePanel)
        end
    )
end)

net.Receive("LTS_ClearAllAllies", function()
    notification.AddLegacy("All alliances have been cleared!", NOTIFY_ERROR, 4)
    surface.PlaySound("buttons/button15.wav")
end)

net.Receive("LTS_AllAllies", function()
    notification.AddLegacy("All teams are now allied!", NOTIFY_GENERIC, 4)
    surface.PlaySound("buttons/button9.wav")
end)

net.Receive("LTS_AddAlliance", function()
    notification.AddLegacy("Alliance created.", NOTIFY_GENERIC, 3)
    surface.PlaySound("buttons/button14.wav")
end)

net.Receive("LTS_RemoveAlliance", function()
    notification.AddLegacy("Alliance removed.", NOTIFY_CLEANUP, 3)
    surface.PlaySound("buttons/button19.wav")
end)
