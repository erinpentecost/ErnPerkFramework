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
local interfaces = require("openmw.interfaces")
local storage = require('openmw.storage')
local pself = require("openmw.self")
local types = require("openmw.types")
local log = require("scripts.ErnBurglary.log")
local settings = require("scripts.ErnPerkFramework.settings")

local version = 1

-- activePerksByID, in the order they were chosen.
local activePerksByID = {}

local function totalAllowedPoints()
    local level = types.Actor.stats.level(pself).current
    return math.floor(settings.perksPerLevel * level)
end

local function syncPerks()
    -- keep calling this until the number of perks stops going down.
    -- this handles perks that require other perks to exist.
    local currentCount = #activePerksByID
    local allowedCount = totalAllowedPoints()
    while true do
        local currentPerkNumber = 0
        local filteredPerks = {}
        for _, perkID in ipairs(activePerksByID) do
            local foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
            if (foundPerk ~= nil) and foundPerk.evaluateRequirements().satisfied then
                currentPerkNumber = currentPerkNumber + 1
                if currentPerkNumber > allowedCount then
                    log(nil, "Removing perk " .. perkID .. ", not enough points.")
                else
                    table.insert(filteredPerks, perkID)
                end
            else
                log(nil, "Removing perk " .. perkID .. ", invalid or missing.")
            end
        end
        activePerksByID = filteredPerks

        if currentCount == #activePerksByID then
            break
        end
    end
end

local function onActive()
    syncPerks()
end

local function onSave()
    return {
        version = version,
        activePerksByID = activePerksByID,
    }
end

local function onLoad(data)
    if (data == nil) then
        return
    end
    if (not data) or (not data.version) or (data.version ~= version) then
        print("Perks resetting. Mod version changed.")
        return
    end
    activePerksByID = data.activePerksByID
end

return {
    engineHandlers = {
        onActive = onActive,
        onSave = onSave,
        onLoad = onLoad
    }
}
