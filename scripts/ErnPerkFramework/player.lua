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
local log = require("scripts.ErnPerkFramework.log")
local settings = require("scripts.ErnPerkFramework.settings")
local UI = require('openmw.interfaces').UI

settings.init()
local version = interfaces.ErnPerkFramework.version

local function totalAllowedPoints()
    local level = types.Actor.stats.level(pself).current
    return math.floor(settings.perksPerLevel * level)
end

local function currentSpentPoints()
    local total = 0
    for _, foundID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        total = total + interfaces.ErnPerkFramework.getPerks()[foundID]:cost()
    end
    return total
end

local function hasPerk(id)
    for _, foundID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        if foundID == id then
            return true
        end
    end
    return false
end

local function shouldShowUI()
    local remainingPoints = totalAllowedPoints() - currentSpentPoints()
    -- now we have to see if there is at least one perk that we could buy
    for id, perk in pairs(interfaces.ErnPerkFramework.getPerks()) do
        if (not hasPerk(id)) and perk:evaluateRequirements().satisfied and perk:cost() <= remainingPoints then
            return true
        end
    end
    return false
end

local function syncPerks()
    log("syncPerks", "syncPerks() started.")
    -- keep calling this until the number of perks stops going down.
    -- this handles perks that require other perks to exist.
    local snapshot = interfaces.ErnPerkFramework.getPlayerPerks()
    local currentCount = #snapshot
    local allowedPoints = totalAllowedPoints()
    for i = 1, 1000 do
        local currentPerksTotalCost = 0
        local filteredPerks = {}
        -- iterate from oldest to newest.
        for _, perkID in ipairs(snapshot) do
            local foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
            if (foundPerk == nil) then
                -- Maybe don't do this, so late-registering providers aren't deleted.
                log(nil, "Removing perk " .. perkID .. ", missing.")
            elseif foundPerk:evaluateRequirements().satisfied then
                if currentPerksTotalCost + foundPerk:cost() > allowedPoints then
                    log(nil, "Removing perk " .. perkID .. ", not enough points.")
                    foundPerk:onRemove()
                else
                    currentPerksTotalCost = currentPerksTotalCost + foundPerk:cost()
                    table.insert(filteredPerks, perkID)
                end
            else
                log(nil, "Removing perk " .. perkID .. ", don't meet requirements.")
                foundPerk:onRemove()
            end
        end
        snapshot = filteredPerks

        if currentCount == #snapshot then
            -- there were no changes, so stop.
            break
        end
    end
    -- now that we're done removing them, apply them.
    interfaces.ErnPerkFramework.setPlayerPerks(snapshot)
    for _, perkID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        log(nil, "Adding perk " .. perkID .. "!")
        local foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
        foundPerk:onAdd()
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
    if UI.getMode() ~= nil and UI.getMode() ~= "" then
        remainingDT = 10
        return
    end

    -- sync often in case we drop requirements somehow
    -- TODO: break this up across multiple frames
    syncPerks()
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
    if foundPerk:evaluateRequirements().satisfied then
        local totalAllowed = totalAllowedPoints()
        if currentSpentPoints() + foundPerk:cost() <= totalAllowed then
            local activePerksByID = interfaces.ErnPerkFramework.getPlayerPerks()
            table.insert(activePerksByID, data.perkID)
            interfaces.ErnPerkFramework.setPlayerPerks(activePerksByID)
            foundPerk:onAdd()
        else
            log(nil,
                "Perk " ..
                tostring(data.perkID) ..
                " point cost can't be paid. Can't add it.")
        end
    else
        log(nil, "Perk " .. tostring(data.perkID) .. " requirements are not met. Can't add it.")
    end
end

local function removePerk(data)
    if (data == nil) or (not data.perkID) then
        error("removePerk() called with invalid data.")
        return
    end
    local foundPerk = interfaces.ErnPerkFramework.getPerks()[data.perkID]
    if foundPerk == nil then
        error("removePerk(" .. tostring(data.perkID) .. ") called with bad perkID.")
        return
    end
    local activePerksByID = interfaces.ErnPerkFramework.getPlayerPerks()
    for i, p in ipairs(activePerksByID) do
        if p == data.perkID then
            table.remove(activePerksByID, i)
            break
        end
    end
    interfaces.ErnPerkFramework.setPlayerPerks(activePerksByID)
    foundPerk:onRemove()
end


local function onConsoleCommand(mode, command, selectedObject)
    local function getSuffixForCmd(prefix)
        if string.sub(command:lower(), 1, string.len(prefix)) == prefix then
            return string.sub(command, string.len(prefix) + 1)
        else
            return nil
        end
    end
    local add = getSuffixForCmd("lua addperk ")
    local show = getSuffixForCmd("lua perks")

    if add ~= nil then
        pself:sendEvent(settings.MOD_NAME .. "addPerk",
            { perkID = add })
    elseif show ~= nil then
        local remainingPoints = totalAllowedPoints() - currentSpentPoints()
        pself:sendEvent(settings.MOD_NAME .. "showPerkUI",
            { remainingPoints = remainingPoints })
    end
end

local function UiModeChanged(data)
    -- spawn perk UI after the levelup UI.
    if (data.newMode == nil) and (data.oldMode == 'LevelUp') then
        if shouldShowUI() then
            local remainingPoints = totalAllowedPoints() - currentSpentPoints()
            pself:sendEvent(settings.MOD_NAME .. "showPerkUI",
                {
                    remainingPoints = remainingPoints
                })
        end
    elseif (data.newMode == nil) then
        pself:sendEvent(settings.MOD_NAME .. "closePerkUI", {})
    end
end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        [settings.MOD_NAME .. "addPerk"] = addPerk,
        [settings.MOD_NAME .. "removePerk"] = removePerk,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = onActive,
        onConsoleCommand = onConsoleCommand,
    }
}
