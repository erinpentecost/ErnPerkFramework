--[[
ErnPerkFramework for OpenMW.
Copyright (C) 2025 Erin Pentecost and ownlyme

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME = "ErnPerkFramework"
local world = require('openmw.world')

local variablesToTrack = {
    "PCWerewolf"
}

local function updateMwVars()
    for _, player in ipairs(world.players) do
        local globalVars = world.mwscript.getGlobalVariables(player)
        local subset = {}
        for _, varName in ipairs(variablesToTrack) do
            subset[varName] = globalVars[varName]
        end
        player:sendEvent(MOD_NAME .. 'onUpdateMwVars', subset)
    end
end

local delta = 10
local function onUpdate(dt)
    delta = delta - dt
    if delta > 0 then
        return
    end
    delta = 10

    updateMwVars()
end

return {
    engineHandlers = {
        onPlayerAdded = updateMwVars,
        onUpdate = onUpdate,
    }
}
