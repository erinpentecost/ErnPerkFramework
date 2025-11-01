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
local interfaces = require('openmw.interfaces')
local log = require("scripts.ErnPerkFramework.log")
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local pself = require("openmw.self")

local sectionName = "perks"

local function initStatsWindowIntegration()
    if interfaces.StatsWindow then
        log(nil, "StatsWindow found.")
        interfaces.StatsWindow.trackStat('SF_CustomSkills', function() return interfaces.SkillFramework.getRecords() end)

        local lineBuilder = function(perkId)
            local perkRecord = interfaces.ErnPerkFramework.getPerks()[perkId]
            return {
                label = perkRecord:name(),
                --[[value = function()
                    local skillStat = interfaces.SkillFramework.getLevel(perkId)
                    return { string = tostring(skillStat.value) }
                end,]]
                --[[tooltip = function()
                    local skillStat = interfaces.SkillFramework.getLevel(perkId)
                    return interfaces.StatsWindow.TooltipBuilders.SKILL({
                        iconBgr = skillRecord.props.bgr,
                        iconFgr = skillRecord.props.icon,
                        title = skillL10n(perkId),
                        description = skillL10n(perkId .. '_Desc'),
                        currentValue = skillStat.value,
                        progress = skillStat.xp / interfaces.SkillFramework.getLevelUpRequirement(perkId),
                        maxValue = skillRecord.props.maxValue,
                    })
                end,]]
                onClick = function()
                    pself:sendEvent(MOD_NAME .. "showPerkUI",
                        { visiblePerks = { perkId } })
                end,
            }
        end

        interfaces.StatsWindow.addSectionToBox(sectionName, interfaces.StatsWindow.DefaultBoxes.RIGHT_SCROLL_BOX, {
            l10n = MOD_NAME,
            placement = {
                type = interfaces.StatsWindow.Placement.AFTER,
                target = interfaces.StatsWindow.DefaultSections.BIRTHSIGN,
                priority = 1,
            },
            header = localization('perks'),
            indent = true,
            sort = interfaces.StatsWindow.Sort.LABEL_ASC,
            builder = function()
                for _, id in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
                    interfaces.StatsWindow.addLineToSection(id, sectionName, lineBuilder(id))
                end
            end,
        })
    else
        log(nil, "StatsWindow not found.")
    end
end



return {
    engineHandlers = {
        onInit = initStatsWindowIntegration,
        onLoad = initStatsWindowIntegration,
    }
}
