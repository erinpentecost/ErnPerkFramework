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

local function minimumSkillLevel(skillID, level)
    local skillRecord = core.stats.Skill.records[skillID]
    return {
        id = builtin .. 'minimumSkillLevel',
        localizedName = localization('req_minimumSkillLevel', { skill = skillRecord.name, level = level }),
        check = function()
            return types.NPC.stats.skills[skillID](pself).base >= level
        end
    }
end

local function minimumAttributeLevel(attributeID, level)
    local attributeRecord = core.stats.Attribute.records[attributeID]
    return {
        id = builtin .. 'minimumAttributeLevel',
        localizedName = localization('req_minimumAttributeLevel', { attribute = attributeRecord.name, level = level }),
        check = function()
            return types.Actor.stats.attributes[attributeID](pself).base >= level
        end
    }
end

local function atLeastRank(npc, factionID, rank)
    local inFaction = false
    for _, foundID in pairs(types.NPC.getFactions(npc)) do
        if foundID == factionID then
            inFaction = true
            break
        end
    end
    if inFaction == false then
        -- not a member
        return false
    end

    local selfRank = types.NPC.getFactionRank(npc, factionID)
    if selfRank == nil then
        return false
    elseif (rank == nil) then
        return true
    else
        return selfRank >= rank
    end
end

-- rank 0 is the first rank of a guild (this matches uesp.net)
local function minimumFactionRank(factionID, rank)
    local factionRecord = core.factions.records[factionID]
    local factionRankName = factionRecord.ranks[rank + 1].name

    return {
        id = builtin .. 'minimumFactionRank',
        localizedName = localization('req_minimumFactionRank',
            { factionName = factionRecord.name, factionRankName = factionRankName }),
        check = function()
            return atLeastRank(pself, factionID, rank + 1)
        end
    }
end

--[[
-- trash
local function race(raceID)
    -- Use the global variable instead of checking records so custom races can get these.
    -- https://en.uesp.net/wiki/Morrowind_Mod:PCRace
    local lookup = {
        [1] = types.NPC.races.records["argonian"],
        [2] = types.NPC.races.records["breton"],
        [3] = types.NPC.races.records["dark elf"],
        [4] = types.NPC.races.records["high elf"],
        [5] = types.NPC.races.records["imperial"],
        [6] = types.NPC.races.records["khajiit"],
        [7] = types.NPC.races.records["nord"],
        [8] = types.NPC.races.records["orc"],
        [9] = types.NPC.races.records["redguard"],
        [10] = types.NPC.races.records["woodelf"],
    }
    local pcRaceID = world.mwscript.getGlobalVariables(pself)["PCRace"]
    local raceRecord = core.stats.Attribute.records[attributeID]
    return {
        id = builtin .. 'minimumAttributeLevel',
        localizedName = localization('req_minimumAttributeLevel', { attribute = attributeRecord.name, level = level }),
        check = function()
            return types.NPC.races.records[raceID]
            return types.Actor.stats.attributes[attributeID](pself).base >= level
        end
    }
end
]]

local function werewolf(status)
    if status then
        return {
            id = builtin .. 'is_a_werewolf',
            localizedName = localization('req_is_a_werewolf', {}),
            check = function()
                return types.Player.isWerewolf(pself)
            end
        }
    else
        return {
            id = builtin .. 'is_not_a_werewolf',
            localizedName = localization('req_is_not_a_werewolf', {}),
            check = function()
                return not types.Player.isWerewolf(pself)
            end
        }
    end
end

local function isVampire()
    for _, spell in pairs(types.Actor.spells(pself)) do
        if spell.name == "Vampirism" then
            return true
        end
    end
    return false
end

local function vampire(status)
    if status then
        return {
            id = builtin .. 'is_a_vampire',
            localizedName = localization('req_is_a_vampire', {}),
            check = function()
                return isVampire()
            end
        }
    else
        return {
            id = builtin .. 'is_not_a_vampire',
            localizedName = localization('req_is_not_a_vampire', {}),
            check = function()
                return not isVampire()
            end
        }
    end
end




return {
    minimumLevel = minimumLevel,
    minimumSkillLevel = minimumSkillLevel,
    minimumAttributeLevel = minimumAttributeLevel,
    minimumFactionRank = minimumFactionRank,
    werewolf = werewolf,
    vampire = vampire,
}
