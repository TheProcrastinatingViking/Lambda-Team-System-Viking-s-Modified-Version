AddCSLuaFile()

if ( CLIENT ) then

    TOOL.Information = {
        { name = "left" },
        { name = "right" }
    }

    language.Add( "tool.lambda_teamsystem_salvagerun_pointmaker", "Salvage Run Point Maker" )
    language.Add( "tool.lambda_teamsystem_salvagerun_pointmaker.name", "Salvage Run Point Maker" )
    language.Add( "tool.lambda_teamsystem_salvagerun_pointmaker.desc", "Marks a spot for a Salvage Run bank" )
    language.Add( "tool.lambda_teamsystem_salvagerun_pointmaker.left", "Fire onto a surface to place a Salvage Run bank" )
    language.Add( "tool.lambda_teamsystem_salvagerun_pointmaker.right", "Fire near a Salvage Run bank to remove it" )

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambda_teamsystem_salvagerun_pointmaker"
TOOL.ClientConVar = {
    [ "pointname" ] = "",
    [ "startteam" ] = ""
}

local ents_Create = ( SERVER and ents.Create )
local undo = undo
local FindInSphere = ents.FindInSphere
local IsValid = IsValid
local pairs = pairs
local ipairs = ipairs
local vgui_Create = ( CLIENT and vgui.Create )

function TOOL:LeftClick( tr )
    if ( SERVER ) then
        local bank = ents_Create( "lambda_salvage_bank" )

        local pointName = self:GetClientInfo( "pointname" )
        bank.CustomName = ( pointName != "" and pointName )

        local startTeam = self:GetClientInfo( "startteam" )
        bank.SpawnTeam = ( startTeam != "" and startTeam )

        bank:Spawn()
        bank:Activate()

        local mins = bank:OBBMins()
        bank:SetPos( tr.HitPos + tr.HitNormal * math.abs( mins.z ) )

        local owner = self:GetOwner()
        undo.Create( "Lambda Salvage Bank " .. pointName )
            undo.SetPlayer( owner )
            undo.AddEntity( bank )
        undo.Finish( "Lambda Salvage Bank " .. pointName )

        owner:AddCleanup( "sents", bank )
    end

    return true
end

function TOOL:RightClick( tr )
    if ( SERVER ) then
        for _, ent in ipairs( FindInSphere( tr.HitPos, 5 ) ) do
            if IsValid( ent ) and ent.IsLambdaSalvageBank then
                ent:Remove()
                break
            end
        end
    end

    return true
end

function TOOL.BuildCPanel( panel )
    panel:TextEntry( "Point Name", "lambda_teamsystem_salvagerun_pointmaker_pointname" )
    panel:ControlHelp( "The name of this Salvage Run bank. Leave empty to use a default name." )

    local combo = panel:ComboBox( "Start Team", "lambda_teamsystem_salvagerun_pointmaker_startteam" )
    for k, v in pairs( LambdaTeams.TeamOptions ) do combo:AddChoice( k, v ) end
    panel:ControlHelp( "The team that this bank should be assigned to after spawning." )

    local refresh = vgui_Create( "DButton" )
    panel:AddItem( refresh )
    refresh:SetText( "Refresh Team List" )

    function refresh:DoClick()
        combo:Clear()
        local teamData = LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" )
        teamData[ "None" ] = ""
        for k, _ in pairs( teamData ) do combo:AddChoice( k, k ) end
    end
end