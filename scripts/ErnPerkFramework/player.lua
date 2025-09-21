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
local UI = require('openmw.interfaces').UI

local version = interfaces.ErnPerkFramework.version

-- activePerksByID, in the order they were chosen.
local activePerksByID = {}
-- map of id -> true to indicate if we're already applied the perk this session.
local addedByID = {}

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
            if (foundPerk == nil) then
                log(nil, "Removing perk " .. perkID .. ", missing.")
            elseif foundPerk.evaluateRequirements().satisfied then
                currentPerkNumber = currentPerkNumber + 1
                if currentPerkNumber > allowedCount then
                    log(nil, "Removing perk " .. perkID .. ", not enough points.")
                    addedByID[perkID] = false
                    foundPerk.onRemove()
                else
                    log(nil, "Adding perk " .. perkID .. "!")
                    table.insert(filteredPerks, perkID)
                end
            else
                log(nil, "Removing perk " .. perkID .. ", don't meet requirements.")
                addedByID[perkID] = false
                foundPerk.onRemove()
            end
        end
        activePerksByID = filteredPerks

        if currentCount == #activePerksByID then
            break
        end
    end
    -- now that we're done removing them, apply them.
    for _, perkID in ipairs(activePerksByID) do
        if addedByID[perkID] ~= true then
            local foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
            foundPerk.onAdd()
            addedByID[perkID] = true
        end
    end
end

local function onActive()
    syncPerks()
end

-- Detect when we need to add or remove perks
local remainingDT = 10
local function onUpdate(dt)
    -- don't call this all the time
    remainingDT = remainingDT - dt
    if remainingDT > 0 then
        return
    end
    remainingDT = 10

    -- don't do anything if we are in the UI.
    if UI.getMode() == nil or UI.getMode() == "" then
        remainingDT = 10
        return
    end

    -- sync often in case we drop requirements somehow
    -- TODO: break this up across multiple frames
    syncPerks()

    -- we have points available. spawn UI.
    local remainingPoints = totalAllowedPoints() - #activePerksByID
    if remainingPoints > 0 then
        pself:sendEvent(settings.MOD_NAME .. "showPerkUI",
            { active = activePerksByID, remainingPoints = remainingPoints })
    end
end

local function addPerk(data)
    if (data == nil) or (not data.perkID) then
        error("addPerk() called with invalid data.")
        return
    end
    local foundPerk = interfaces.ErnPerkFramework.getPerks()[data.perkID]
    if foundPerk == nil then
        error("addPerk(" .. tostring(data.perkID) .. ") called with bad perkID.")
        return
    end
    table.insert(activePerksByID, data.perkID)
    foundPerk.onAdd()
    addedByID[data.perkID] = true
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
        log(nil, "Perks resetting. Mod version changed.")
        return
    end
    activePerksByID = data.activePerksByID
end

return {
    eventHandlers = {
        [settings.MOD_NAME .. "addPerk"] = addPerk,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = onActive,
        onSave = onSave,
        onLoad = onLoad
    }
}
