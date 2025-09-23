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
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local perkUtil = require("scripts.ErnPerkFramework.perk")

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- manifest of registered perks. This is a map of ID -> perk record.
local perkTable = {}
-- list of all perk IDs.
local perkIDs = {}

-- Every requirement must have these fields:
-- A unique ID. This is used for localization.
-- A check function that returns true if the requirement is satisfied.
local function validateRequirement(requirement)
    if (not requirement) or (type(requirement) ~= "table") then
        error("validateRequirement() argument is not a table.", 3)
        return false
    end
    if (not requirement.id) or (type(requirement.id) ~= "string") then
        error("validateRequirement() requirement data is missing a string 'id' field.", 3)
        return false
    end
    if (not requirement.check) or (type(requirement.check) ~= "function") then
        error("validateRequirement() requirement data is missing a function 'check' field.", 3)
        return false
    end
    if (requirement.localizedName ~= nil) then
        if (type(requirement.localizedName) ~= "function") then
            error(
                "validateRequirement() requirement data has a 'localizedName' field, which must be a function that returns a string.",
                3)
            return false
        end
    end
    return true
end

-- Perks must have these fields:
-- id, which must be unique.
-- requirements, which is a list of requirements. These are called on the player context.
-- onAdd, which is the function called when a player adds/picks the perk. This is called on the player context. This must be idempotent. This will be called during player Activation.
-- onRemove, which is the function called when the perk is removed through either respec or invalid requirements. This is called on the player context. This must be idempotent. It is possible that onRemove will be called before onAdd.
local function registerPerk(data)
    if (not data) or (type(data) ~= "table") then
        error("validateRequirement() argument is not a table.", 2)
        return false
    end
    if (not data.id) or (type(data.id) ~= "string") then
        error("registerPerk() perk data is missing a string 'id' field.", 2)
        return false
    end
    if (not data.requirements) or (type(data.requirements) ~= "table") then
        error("registerPerk(" .. tostring(data.id) .. ") perk data is missing a table 'requirements' field.", 2)
        return false
    end
    if (not data.onAdd) or (type(data.onAdd) ~= "function") then
        error("registerPerk(" .. tostring(data.id) .. ") perk data is missing a function 'onAdd' field.", 2)
        return false
    end
    if (not data.onRemove) or (type(data.onRemove) ~= "function") then
        error("registerPerk(" .. tostring(data.id) .. ") perk data is missing a function 'onRemove' field.", 2)
        return false
    end
    if (data.localizedName ~= nil) then
        if (type(data.localizedName) ~= "function") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has a 'localizedName' field, which must be a function that returns a string.", 2)
            return false
        end
    end
    if (data.localizedDescription ~= nil) then
        if (type(data.localizedDescription) ~= "function") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has a 'localizedDescription' field, which must be a function that returns a string.", 2)
            return false
        end
    end
    if (data.art ~= nil) then
        if (type(data.art) ~= "function") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has an 'art' field, which must be a function that returns a texture path.",
                2)
            return false
        end
    end
    if (data.hidden ~= nil) then
        if (type(data.hidden) ~= "boolean") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has a 'hidden' field, which must be a function that returns a boolean.",
                2)
            return false
        end
    end

    for i, r in ipairs(data.requirements) do
        if not validateRequirement(r) then
            error("registerPerk(" .. tostring(data.id) .. ") perk data has a bad requirement at index " .. tostring(i), 2)
            return false
        end
    end

    -- check if we have an id collision.
    -- we want to allow this so perk mods can patch eachother.
    if perkTable[data.id] ~= nil then
        print("registerPerk(" .. tostring(data.id) .. ") is replacing an existing perk.")
        -- TODO: call onRemove for any player that registered the old one previously?
    else
        -- didn't previously exist
        print("registerPerk(" .. tostring(data.id) .. ") completed.")
        table.insert(perkIDs, data.id)
    end

    perkTable[data.id] = perkUtil.NewPerk(data)
end

local function getPerks()
    return perkTable
end

local function getPerkIDs()
    return perkIDs
end

return {
    interfaceName = MOD_NAME,
    interface = {
        version = 1,
        registerPerk = registerPerk,
        getPerks = getPerks,
        getPerkIDs = getPerkIDs,
    }
}
