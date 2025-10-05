--[[
ErnPerkFramework for OpenMW.
Copyright (C) 2025 Erin Pentecost

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

-- This file contains some common requirements builders that could be re-used by lots of stuff.

local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local pself = require("openmw.self")
local types = require("openmw.types")

local builtin = MOD_NAME .. '_builtin_'

local function minimumLevel(level)
    return {
        id = builtin .. 'minimumLevel',
        localizedName = localization('req_minimumLevel', { level = level }),
        check = function()
            return types.Actor.stats.level(pself).current >= level
        end
    }
end



return {
    minimumLevel = minimumLevel,
}
