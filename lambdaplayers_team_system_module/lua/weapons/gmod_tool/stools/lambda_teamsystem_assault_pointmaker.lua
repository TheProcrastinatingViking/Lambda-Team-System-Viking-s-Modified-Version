AddCSLuaFile()

if ( CLIENT ) then

	TOOL.Information = {
		{ name = "left" },
		{ name = "right" }
	}

	language.Add( "tool.lambda_teamsystem_assault_pointmaker", "Assault Point Maker" )
	language.Add( "tool.lambda_teamsystem_assault_pointmaker.name", "Assault Point Maker" )
	language.Add( "tool.lambda_teamsystem_assault_pointmaker.desc", "Marks a spot for an Assault point" )
	language.Add( "tool.lambda_teamsystem_assault_pointmaker.left", "Fire onto a surface to mark an Assault point" )
	language.Add( "tool.lambda_teamsystem_assault_pointmaker.right", "Fire near an Assault point to remove it" )

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambda_teamsystem_assault_pointmaker"
TOOL.ClientConVar = {
	[ "pointname" ] = ""
}

local ents_Create = ( SERVER and ents.Create )
local undo = undo
local FindInSphere = ents.FindInSphere
local IsValid = IsValid
local ipairs = ipairs

function TOOL:LeftClick( tr )
	if ( SERVER ) then
		local assaultPoint = ents_Create( "lambda_assault_point" )
		if !IsValid( assaultPoint ) then return false end

		assaultPoint:SetPos( tr.HitPos )

		local pointName = self:GetClientInfo( "pointname" )
		assaultPoint.CustomName = ( pointName != "" and pointName )

		assaultPoint:Spawn()

		local owner = self:GetOwner()
		local undoName = "Lambda Assault Point" .. ( pointName != "" and ( " " .. pointName ) or "" )

		undo.Create( undoName )
			undo.SetPlayer( owner )
			undo.AddEntity( assaultPoint )
		undo.Finish( undoName )

		owner:AddCleanup( "sents", assaultPoint )
	end

	return true
end

function TOOL:RightClick( tr )
	if ( SERVER ) then
		for _, ent in ipairs( FindInSphere( tr.HitPos, 5 ) ) do
			if IsValid( ent ) and ent.IsLambdaAssault then
				ent:Remove()
				break
			end
		end
	end

	return true
end

function TOOL.BuildCPanel( panel )
	panel:TextEntry( "Point Name", "lambda_teamsystem_assault_pointmaker_pointname" )
	panel:ControlHelp( "The name of this Assault point. Leave empty to use a generated sector name." )
end