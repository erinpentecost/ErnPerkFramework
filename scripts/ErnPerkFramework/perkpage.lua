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
local perkDetail = ui.create {
    name = 'perkDetail',
    type = ui.TYPE.Flex,
}
local perkList = {
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
    log(nil, "pickPerk() started")
    if selectedPerkID ~= nil then
        log(nil, "Picked perk " .. selectedPerkID)
        -- TODO: also close the window
        pself:sendEvent(MOD_NAME .. "addPerk",
            { perkID = selectedPerkID })
    end
    if menu ~= nil then
        menu:destroy()
    end
end

local pickButton = ui.create {}
pickButton.layout = myui.createTextButton(pickButton, localization('pickButton'), 'normal', 'autoButton', {},
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

    selectedPerkID = perkID
    perkDetail.layout = foundPerk:detailLayout()
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
    local allPerkIDs = interfaces.ErnPerkFramework.getPerkIDs()
    -- uh
    viewPerk(interfaces.ErnPerkFramework.getPerks()[allPerkIDs[1]])
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
        selectedPerkID = nil

        perkListLayout()

        menu = ui.create(menuLayout)
    end
end


return {
    eventHandlers = {
        [MOD_NAME .. "showPerkUI"] = showPerkUI,
    }
}
