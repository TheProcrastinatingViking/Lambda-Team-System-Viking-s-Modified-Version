local TEAMSYS_CL = "lambdaplayers/extaddon/shared/cl_lambdaplayers_teamsystem.lua"
local TEAMSYS_SH = "lambdaplayers/extaddon/shared/sh_lambdaplayers_teamsystem.lua"
local TEAMSYS_SV = "lambdaplayers/extaddon/shared/sv_lambdaplayers_teamsystem.lua"

if SERVER then
    AddCSLuaFile( TEAMSYS_CL )
    AddCSLuaFile( TEAMSYS_SH )
end

include( TEAMSYS_SH )

if SERVER then
    include( TEAMSYS_SV )
else
    include( TEAMSYS_CL )
end