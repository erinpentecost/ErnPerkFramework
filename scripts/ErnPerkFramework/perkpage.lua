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
local perkDetailElement = ui.create {
    name = "detailLayout",
    type = ui.TYPE.Flex,
}
local perkListElement = ui.create {
    -- list o' perks
    name = 'perkList',
    type = ui.TYPE.Flex,
    props = {
        horizontal = false,
    },
}

local activePerks = {}
local remainingPoints = 0

-- index of the selected perk, by the full perk list
local selectedPerkIndex = 1
local function getSelectedPerk()
    local selectedPerkID = interfaces.ErnPerkFramework.getPerkIDs()[selectedPerkIndex]
    return interfaces.ErnPerkFramework.getPerks()[selectedPerkID]
end


local function pickPerk()
    log(nil, "pickPerk() started")
    local selectedPerk = getSelectedPerk()
    if selectedPerk ~= nil then
        log(nil, "Picked perk " .. selectedPerk:id())
        -- TODO: also close the window
        pself:sendEvent(MOD_NAME .. "addPerk",
            { perkID = selectedPerk:id() })
    end
    if menu ~= nil then
        menu:destroy()
    end
end

local pickButtonElement = ui.create {}
pickButtonElement.layout = myui.createTextButton(pickButtonElement, localization('pickButton'), 'normal', 'autoButton',
    {},
    util.vector2(129, 17),
    pickPerk)

local function viewPerk(perkID)
    local foundPerk = perkID
    if type(perkID) == "string" then
        foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
    end
    if foundPerk == nil then
        error("bad perk: " .. tostring(perkID))
        return
    end

    log(nil, "Showing detail for perk " .. foundPerk:name())
    perkDetailElement.layout = foundPerk:detailLayout()
    perkDetailElement:update()
end

local function menuLayout()
    return {
        layer = 'Windows',
        name = 'menuContainer',
        type = ui.TYPE.Container,
        template = interfaces.MWUI.templates.boxTransparentThick,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            --size = ui.screenSize() * 0.75,
            --autoSize = false,
        },
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
                            {
                                type = ui.TYPE.Text,
                                template = interfaces.MWUI.templates.textNormal,
                                props = { text = "debug-mainFlex" }
                            },
                            perkListElement,
                            {
                                template = interfaces.MWUI.verticalLineThick,
                            },
                            {
                                -- detail page
                                name = 'interactiveFlex',
                                type = ui.TYPE.Flex,
                                props = { arrange = ui.ALIGNMENT.End },
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Text,
                                        template = interfaces.MWUI.templates.textNormal,
                                        props = { text = "debug-interactiveFlex" }
                                    },
                                    perkDetailElement,
                                    pickButtonElement
                                }
                            }
                        }
                    }
                }
            }
        }
    }
end

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


local function redraw()
    viewPerk(getSelectedPerk())

    if menu ~= nil then
        menu:update()
    end
end

local function showPerkUI(data)
    local allPerkIDs = interfaces.ErnPerkFramework.getPerkIDs()
    if #allPerkIDs == 0 then
        log(nil, "No perks found.")
        return
    end
    if menu == nil then
        log(nil, "Showing Perk UI...")
        activePerks = data.active
        remainingPoints = data.remainingPoints

        selectedPerkIndex = 1

        menu = ui.create(menuLayout())
        redraw()
    end
end


return {
    eventHandlers = {
        [MOD_NAME .. "showPerkUI"] = showPerkUI,
    }
}
