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

-- A content list can contain both Elements and Layouts.
-- Elements are what you get when you call ui.create().
-- Elements are passed by reference, so you can update them without needing to
-- mess with parent layouts that use them.
--
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
    content = ui.content {}
}

local activePerks = {}
local remainingPoints = 0

-- index of the selected perk, by the full perk list
local selectedPerkIndex = 1
local function getSelectedPerk()
    local selectedPerkID = interfaces.ErnPerkFramework.getPerkIDs()[selectedPerkIndex]
    return interfaces.ErnPerkFramework.getPerks()[selectedPerkID]
end

local function closeUI()
    --interfaces.UI.setMode()
    if menu ~= nil then
        menu:destroy()
    end
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
    closeUI()
end

local pickButtonElement = ui.create {}
pickButtonElement.layout = myui.createTextButton(
    pickButtonElement,
    localization('pickButton'),
    'normal',
    'pickButton',
    {},
    util.vector2(129, 17),
    pickPerk)
pickButtonElement:update()

local function viewPerk(perkID, idx)
    local foundPerk = perkID
    if type(perkID) == "string" then
        foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
    end
    if foundPerk == nil then
        error("bad perk: " .. tostring(perkID))
        return
    end
    selectedPerkIndex = idx

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
                        props = {
                            horizontal = true,
                            autoSize = false,
                            size = ui.screenSize() * 0.75,
                        },
                        content = ui.content {
                            perkListElement,
                            {
                                template = interfaces.MWUI.verticalLineThick,
                            },
                            {
                                -- detail page
                                name = 'interactiveFlex',
                                type = ui.TYPE.Flex,
                                props = {
                                    arrange = ui.ALIGNMENT.End,
                                },
                                content = ui.content {
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

local function perkNameElement(perkObj, idx)
    -- this is the perk name as it appears in the selection list.
    local met = perkObj:evaluateRequirements().satisfied
    local color = 'normal'
    if met == false then
        color = 'disabled'
    end

    local selectButton = ui.create {}
    selectButton.layout = myui.createTextButton(
        selectButton,
        perkObj:name(),
        color,
        'selectButton_' .. perkObj:id(),
        {},
        util.vector2(129, 17),
        viewPerk,
        { perkObj:id(), idx })
    selectButton:update()
    return selectButton
end

local function drawPerkList()
    local perkIDs = interfaces.ErnPerkFramework.getPerkIDs()
    for _, old in ipairs(perkListElement.layout.content) do
        old:destroy()
    end
    perkListElement.layout.content = ui.content {}
    for idx, perkID in ipairs(perkIDs) do
        log(nil, "Making button for " .. tostring(perkID))
        local newName = perkNameElement(interfaces.ErnPerkFramework.getPerks()[perkID], idx)
        table.insert(perkListElement.layout.content, newName)
    end
    perkListElement:update()
end

local function redraw()
    drawPerkList()
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
        interfaces.UI.setMode('Interface', { windows = {} })
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
    },
    engineHandlers = {
        onFrame = myui.processButtonAction,
    }
}
