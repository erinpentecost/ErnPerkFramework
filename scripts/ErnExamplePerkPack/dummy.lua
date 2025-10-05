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
local ns = require("scripts.ErnExamplePerkPack.namespace")
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')

-- Test in-game with console command:
-- lua addperk ErnExamplePerkPack_dummy_1
for i = 1, 4, 1 do
    local id = ns .. "_dummy_" .. tostring(i)
    interfaces.ErnPerkFramework.registerPerk({
        id = id,
        requirements = {
            interfaces.ErnPerkFramework.requirements().minimumLevel(i * i),
        },
        onAdd = function()
            local logLine = id .. " perk added!"
            ui.showMessage(logLine, {})
            print(logLine)
        end,
        onRemove = function()
            local logLine = id .. " perk removed!"
            ui.showMessage(logLine, {})
            print(logLine)
        end,
    })
end
