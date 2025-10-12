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
local interfaces = require("openmw.interfaces")

local function resolve(field)
    if type(field) == 'function' then
        return field()
    else
        return field
    end
end

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

local function orList(items)
    local out = ""
    if #items == 1 then
        return items[1]
    end

    for i, item in ipairs(items) do
        if i == 1 then
            out = items[1]
        elseif i == #items then
            out = localization('list_join_or',
                { prevList = out, nextItem = item })
        else
            out = localization('list_join',
                { prevList = out, nextItem = item })
        end
    end

    return out
end

local function andList(items)
    local out = ""
    if #items == 1 then
        return items[1]
    end

    for i, item in ipairs(items) do
        if i == 1 then
            out = items[1]
        elseif i == #items then
            out = localization('list_join_and',
                { prevList = out, nextItem = item })
        else
            out = localization('list_join',
                { prevList = out, nextItem = item })
        end
    end

    if #items > 1 then
        out = localization('list_group', { list = out })
    end

    return out
end

-- specify one or more perks by id. if any match, the requirement will be met.
local function hasPerk(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'perk',
        localizedName = function()
            local perkNames = {}
            for _, id in ipairs(args) do
                table.insert(perkNames, interfaces.ErnPerkFramework.getPerks()[id]:name())
            end
            return orList(perkNames)
        end,
        check = function()
            for _, foundPerk in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
                for _, checkPerk in ipairs(args) do
                    if checkPerk == foundPerk then
                        return true
                    end
                end
            end
            return false
        end
    }
end

-- specify one or more races. if any match, the requirement will be met.
local function race(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'race',
        localizedName = function()
            local raceNames = {}
            for _, id in ipairs(args) do
                table.insert(raceNames, types.NPC.races.records[id].name)
            end
            return orList(raceNames)
        end,
        check = function()
            local actualRaceID = types.NPC.record(pself).race
            for _, testRace in ipairs(args) do
                if testRace == actualRaceID then
                    return true
                end
            end
            return false
        end
    }
end

-- pass in multiple requirements to OR them together.
local function orGroup(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'or',
        localizedName = function()
            local reqNames = {}
            for _, req in ipairs(args) do
                table.insert(reqNames, resolve(req.localizedName))
            end
            return orList(reqNames)
        end,
        check = function()
            for _, req in ipairs(args) do
                if req.check() then
                    return true
                end
            end
            return false
        end
    }
end

-- pass in multiple requirements to AND them together.
-- You usually don't need to do this, since all top-level requirements are ANDed.
local function andGroup(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'and',
        localizedName = function()
            local reqNames = {}
            for _, req in ipairs(args) do
                table.insert(reqNames, resolve(req.localizedName))
            end
            return andList(reqNames)
        end,
        check = function()
            for _, req in ipairs(args) do
                if not req.check() then
                    return false
                end
            end
            return true
        end
    }
end

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
    race = race,
    hasPerk = hasPerk,
    orGroup = orGroup,
    andGroup = andGroup,
}
