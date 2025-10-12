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
for i = 1, 50, 1 do
    local id = ns .. "_dummy_" .. tostring(i)
    local requirements = {
        interfaces.ErnPerkFramework.requirements().minimumLevel(i * i),
    }
    if i == 1 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        minimumFactionRank('thieves guild', 0))
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        vampire(false))
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        werewolf(false))
    elseif i == 2 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        minimumSkillLevel('sneak', 40))
    elseif i == 3 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        minimumAttributeLevel('strength', 50))
    end

    interfaces.ErnPerkFramework.registerPerk({
        id = id,
        requirements = requirements,
        localizedName = "Example " .. tostring(i),
        localizedDescription = "perk description " .. tostring(i),
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

-- perks with nonstandard costs
interfaces.ErnPerkFramework.registerPerk({
    id = ns .. "_dummy_" .. "penalty",
    requirements = {},
    localizedName = "Negative Cost",
    art = "textures\\levelup\\knight",
    cost = -1,
    localizedDescription = "This perk has a negative cost, so it could be used as a handicap.",
    onAdd = function()
        local logLine = "Negative Cost perk added!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
    onRemove = function()
        local logLine = "Negative Cost perk added!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
})
interfaces.ErnPerkFramework.registerPerk({
    id = ns .. "_dummy_" .. "expensive",
    requirements = {},
    localizedName = "Expensive Cost",
    art = "textures\\levelup\\healer",
    cost = 2,
    localizedDescription = "This perk costs extra points, so it could be extra powerful.",
    onAdd = function()
        local logLine = "Expensive Cost perk added!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
    onRemove = function()
        local logLine = "Expensive Cost perk added!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
})
