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
local util = require('openmw.util')
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local ui = require('openmw.ui')
--local ui = require('openmw.interfaces').UI
local myui = require('scripts.ErnPerkFramework.pcp.myui')
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)

-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/widgets/widget.html#properties
-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/openmw_ui.html##(Template)

local menu = nil
local perkDetail = ui.content {}
local perkList = ui.content {
    -- list o' perks
    name = 'perkList',
    type = ui.TYPE.Flex,
    props = {
        horizontal = false,
    },
}

local activePerks = {}
local remainingPoints = 0
local selectedPerkID = nil

-- index of the selected perk, by the full perk list
local selectedPerkIndex = 1


local function pickPerk()
    if selectedPerkID ~= nil then
        log(nil, "Picked perk " .. selectedPerkID)
        -- TODO: also close the window
        pself:sendEvent(settings.MOD_NAME .. "addPerk",
            { perkID = selectedPerkID })
    end
end

local pickButton = ui.create {}
pickButton.layout = myui.createTextButton(pickButton, localization('pickButton'), 'normal', 'autoButton', {},
    util.vector2(129, 17),
    pickPerk)

local function viewPerk(perkID)
    local foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
    if foundPerk == nil then
        error("bad perk: " .. foundPerk)
        return
    end

    selectedPerkID = perkID
    perkDetail.layout = foundPerk.detailLayout()
    perkDetail:update()
end

local menuLayout = {
    layer = 'Windows',
    name = 'menuContainer',
    type = ui.TYPE.Container,
    template = interfaces.MWUI.templates.boxTransparentThick,
    props = { anchor = util.vector2(0.5, 0.5), relativePosition = util.vector2(0.5, 0.5) },
    content = ui.content {
        {
            name = 'padding',
            type = ui.TYPE.Container,
            template = myui.padding(8, 8),
            content = ui.content {
                {
                    name = 'mainFlex',
                    type = ui.TYPE.Flex,
                    props = { horizontal = true },
                    content = ui.content {
                        perkList,
                        {
                            template = interfaces.MWUI.verticalLineThick,
                        },
                        {
                            -- detail page
                            name = 'interactiveFlex',
                            type = ui.TYPE.Flex,
                            props = { arrange = ui.ALIGNMENT.End },
                            content = ui.content {
                                perkDetail,
                                pickButton
                            }
                        }
                    }
                }
            }
        }
    }
}

local function perkNameLayout(perkObj)
    -- this is the perk name as it appears in the selection list.
    local selectButton = ui.create {}
    selectButton.layout = myui.createTextButton(selectButton, perkObj.name(), 'normal', 'selectButton', {},
        util.vector2(129, 17),
        function()
            viewPerk(perkObj.id())
        end)
    return selectButton
end


local function perkListLayout()

end

local function showPerkUI(data)
    log(nil, "Showing Perk UI...")
    activePerks = data.active
    remainingPoints = data.remainingPoints
    selectedPerkID = nil

    menu = ui.create(menuLayout)
end


return {
    eventHandlers = {
        [settings.MOD_NAME .. "showPerkUI"] = showPerkUI,
    }
}
