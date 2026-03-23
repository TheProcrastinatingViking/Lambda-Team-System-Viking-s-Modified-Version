if ( CLIENT ) then

    local GetConVar = GetConVar
    local pairs = pairs
    local ipairs = ipairs
    local SortedPairs = SortedPairs
    local string_lower = string.lower
    local string_gmatch = string.gmatch
    local string_Trim = string.Trim
    local table_sort = table.sort
    local AddNotification = notification.AddLegacy
    local PlaySound = surface.PlaySound
    local IsValid = IsValid
    local max = math.max

    local campWeaponsCvarName = "lambdaplayers_teamsystem_specificcampweapons"

    local function LTS_GetCampWeaponCvar()
        return GetConVar( campWeaponsCvarName )
    end

    local function LTS_ParseCampWeapons( raw )
        local result = {}

        raw = string_lower( raw or "" )
        for wep in string_gmatch( raw, "([^,]+)" ) do
            wep = string_Trim( string_lower( wep ) )
            if wep != "" then
                result[ wep ] = true
            end
        end

        return result
    end

    local function LTS_OpenCampWeaponPanel( ply )
        if !ply:IsSuperAdmin() then
            AddNotification( "You must be a Super Admin in order to use this!", NOTIFY_ERROR, 4 )
            PlaySound( "buttons/button10.wav" )
            return
        end

        local campCvar = LTS_GetCampWeaponCvar()
        if !campCvar then
            AddNotification( "WARNING: The camp weapon convar was not found!", NOTIFY_ERROR, 4 )
            PlaySound( "buttons/button10.wav" )
            return
        end

        if !_LAMBDAPLAYERSWEAPONS or !_LAMBDAPLAYERSWEAPONORIGINS then
            AddNotification( "Lambda weapon data is not available yet!", NOTIFY_ERROR, 4 )
            PlaySound( "buttons/button10.wav" )
            return
        end

        local currentSet = LTS_ParseCampWeapons( campCvar:GetString() )

        local frame = LAMBDAPANELS:CreateFrame( "Team System - Camp Weapons", 900, 500 )
        local mainScroll = LAMBDAPANELS:CreateScrollPanel( frame, true, FILL )

        LAMBDAPANELS:CreateLabel(
            "Toggle Camping Weapons",
            frame,
            TOP
        )

        local originPanels = {}
        local weaponCheckboxes = {}

        for weporigin, _ in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do
            weaponCheckboxes[ weporigin ] = {}

            local originPanel = LAMBDAPANELS:CreateBasicPanel( mainScroll, LEFT )
            originPanel:SetSize( 220, 400 )
            mainScroll:AddPanel( originPanel )
            originPanels[ #originPanels + 1 ] = originPanel

            local originScroll = LAMBDAPANELS:CreateScrollPanel( originPanel, false, FILL )
            local sortedWeapons = {}
            local toggleState = false

            LAMBDAPANELS:CreateButton( originPanel, TOP, "Toggle " .. weporigin, function()
                toggleState = !toggleState

                for _, data in ipairs( weaponCheckboxes[ weporigin ] ) do
                    data[ 1 ]:SetChecked( toggleState )
                end
            end )

            for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
                if name == "none" then continue end
                if name == "physgun" then continue end
                if data.origin != weporigin then continue end
                if data.cantbeselected then continue end

                sortedWeapons[ data.notagprettyname or name ] = name
            end

            for prettyName, className in SortedPairs( sortedWeapons ) do
                local checkbox, checkpanel = LAMBDAPANELS:CreateCheckBox(
                    originScroll,
                    TOP,
                    currentSet[ string_lower( className ) ] == true,
                    prettyName
                )

                checkpanel:DockMargin( 2, 2, 0, 2 )
                weaponCheckboxes[ weporigin ][ #weaponCheckboxes[ weporigin ] + 1 ] = { checkbox, className }
            end

            if #weaponCheckboxes[ weporigin ] == 0 then
                originPanel:Remove()
                originPanels[ #originPanels ] = nil
            end
        end

        function frame:OnSizeChanged( width )
            local validPanels = {}

            for _, pnl in ipairs( originPanels ) do
                if IsValid( pnl ) then
                    validPanels[ #validPanels + 1 ] = pnl
                end
            end

            if #validPanels == 0 then return end

            local columnWidth = max( 220, ( width - 10 ) / #validPanels )
            for _, pnl in ipairs( validPanels ) do
                pnl:SetWidth( columnWidth )
            end
        end
        frame:OnSizeChanged( frame:GetWide() )

        LAMBDAPANELS:CreateButton( frame, BOTTOM, "Clear All", function()
            for _, originData in pairs( weaponCheckboxes ) do
                for _, data in ipairs( originData ) do
                    data[ 1 ]:SetChecked( false )
                end
            end
        end )

        LAMBDAPANELS:CreateButton( frame, BOTTOM, "Save", function()
            local selected = {}

            for _, originData in pairs( weaponCheckboxes ) do
                for _, data in ipairs( originData ) do
                    if !data[ 1 ]:GetChecked() then continue end
                    selected[ #selected + 1 ] = data[ 2 ]
                end
            end

            table_sort( selected, function( a, b ) return a < b end )

            RunConsoleCommand( campWeaponsCvarName, table.concat( selected, ", " ) )

            AddNotification( "Updated camping weapons!", NOTIFY_GENERIC, 4 )
            PlaySound( "buttons/button15.wav" )
            frame:Close()
        end )
    end

    CreateLambdaConsoleCommand(
        "lambdaplayers_teamsystem_opencampweaponpanel",
        LTS_OpenCampWeaponPanel,
        true,
        "Opens a panel that allows you to toggle which weapons can be used by Lambda Players for camping.",
        { name = "Edit Camp Weapons", category = "Team System" }
    )
end