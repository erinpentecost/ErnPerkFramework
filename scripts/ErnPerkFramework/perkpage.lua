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
local input = require("openmw.input")
local log = require("scripts.ErnPerkFramework.log")
local util = require('openmw.util')
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local settings = require("scripts.ErnPerkFramework.settings")
local ui = require('openmw.ui')
--local ui = require('openmw.interfaces').UI
local myui = require('scripts.ErnPerkFramework.pcp.myui')
local list = require('scripts.ErnPerkFramework.list')
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
local perkList = nil
local perkDetailElement = ui.create {
    name = "detailLayout",
    type = ui.TYPE.Flex,
    --[[ props = {
        relativePosition = util.vector2(0, 0.5),
        anchor = util.vector2(0, 0.5) }]]
}

-- index of the selected perk, by the full perk list
local function getSelectedIndex()
    if perkList ~= nil then
        return perkList.selectedIndex
    end
    return 1
end
local function getSelectedPerk()
    local selectedPerkID = interfaces.ErnPerkFramework.getPerkIDs()[getSelectedIndex()]
    return interfaces.ErnPerkFramework.getPerks()[selectedPerkID]
end

-- viewPerk shows the perk details after a click on a button or redraw
local function viewPerk(perkID, idx)
    if type(idx) ~= "number" then
        error("idx must be a number")
    end
    log(nil, "viewPerk start")
    local foundPerk = perkID
    if type(perkID) == "string" then
        foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
    end
    if foundPerk == nil then
        error("bad perk: " .. tostring(perkID))
        return
    end
    if perkList ~= nil then
        perkList.selectedIndex = idx
    end

    log(nil, "Showing detail for perk " .. foundPerk:name())
    perkDetailElement.layout = foundPerk:detailLayout()
    perkDetailElement:update()
    log(nil, "viewPerk end")
    if perkList ~= nil then
        perkList:setSelectedIndex(idx)
        perkList:update()
    end
end

-- perkNameElement renders a perk button in a list
local function perkNameElement(perkObj, idx)
    print("making Element for " .. perkObj:id() .. " at idx " .. idx)
    -- this is the perk name as it appears in the selection list.
    local color = 'normal'
    if idx == getSelectedIndex() then
        color = 'active'
    elseif perkObj:evaluateRequirements().satisfied == false then
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

perkList = list.NewList(
    function(idx)
        if type(idx) ~= "number" then
            error("idx must be a number")
        end
        local perkIDs = interfaces.ErnPerkFramework.getPerkIDs()
        return perkNameElement(interfaces.ErnPerkFramework.getPerks()[perkIDs[idx]], idx)
    end
)
--perkList.root.layout['external'] = { grow = 0, stretch = 0.5 }

local activePerks = {}
local remainingPoints = 0

local function closeUI()
    if menu ~= nil then
        log(nil, "closing ui")
        menu:destroy()
        menu = nil

        perkList:destroy()

        perkDetailElement = ui.create {
            name = "detailLayout",
            type = ui.TYPE.Flex,
        }
        interfaces.UI.removeMode('Interface')
    end
end


local function pickPerk()
    local selectedPerk = getSelectedPerk()
    if selectedPerk ~= nil then
        log(nil, "Picked perk " .. selectedPerk:id())
        local met = selectedPerk:evaluateRequirements().satisfied
        if met == true then
            closeUI()
            log(nil, "Adding perk " .. selectedPerk:id())
            pself:sendEvent(MOD_NAME .. "addPerk",
                { perkID = selectedPerk:id() })
        end
    end
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

local cancelButtonElement = ui.create {}
cancelButtonElement.layout = myui.createTextButton(
    cancelButtonElement,
    localization('cancelButton'),
    'normal',
    'cancelButton',
    {},
    util.vector2(129, 17),
    closeUI)
cancelButtonElement:update()

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
                            size = util.vector2(800, 480) --* settings.uiScale,
                        },
                        content = ui.content {
                            perkList.root,
                            myui.padWidget(8, 0),
                            {
                                -- detail page section
                                type = ui.TYPE.Widget,
                                props = {
                                    arrange = ui.ALIGNMENT.Center,
                                    relativeSize = util.vector2(1, 1),
                                    --relativePosition = util.vector2(0.5, 0),
                                },
                                external = { grow = 0.667 },
                                content = ui.content {
                                    perkDetailElement,
                                    --myui.padWidget(0, 8),
                                    {
                                        name = 'footer',
                                        type = ui.TYPE.Flex,
                                        props = {
                                            horizontal = true,
                                            relativePosition = util.vector2(0, 1),
                                            anchor = util.vector2(0, 1)
                                        },
                                        content = ui.content {
                                            pickButtonElement,
                                            myui.padWidget(8, 0),
                                            cancelButtonElement
                                        },
                                    },

                                }
                            }
                        }
                    }
                }
            }
        }
    }
end

local function drawPerksList()
    local perkIDs = interfaces.ErnPerkFramework.getPerkIDs()
    perkList:setTotal(#perkIDs)
    perkList:update()
end

local function redraw()
    log(nil, "redraw start")
    drawPerksList()
    viewPerk(getSelectedPerk(), getSelectedIndex())

    if menu ~= nil then
        menu:update()
    end
    log(nil, "redraw end")
end

local function showPerkUI(data)
    log(nil, "showPerkUI start")
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

        perkList.selectedIndex = 1

        menu = ui.create(menuLayout())
        redraw()
    end
    log(nil, "showPerkUI end")
end


local function onMouseWheel(direction)
    if direction < 0 then
        perkList:scroll(-1)
    else
        perkList:scroll(1)
    end
    redraw()
end

local debounce = 0
local function onFrame(dt)
    myui.processButtonAction(dt)

    if debounce > 0 then
        debounce = debounce - 1
        return
    end

    if input.isKeyPressed(input.KEY.DownArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown) then
        log(nil, "Down key")
        perkList:scroll(1)
        debounce = 5
        redraw()
    end
    if input.isKeyPressed(input.KEY.UpArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp) then
        log(nil, "Up key")
        perkList:scroll(-1)
        debounce = 5
        redraw()
    end
end

return {
    eventHandlers = {
        [MOD_NAME .. "showPerkUI"] = showPerkUI,
        [MOD_NAME .. "closePerkUI"] = closeUI,
    },
    engineHandlers = {
        onFrame = onFrame,
        onMouseWheel = onMouseWheel,
    }
}
