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

local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local async = require('openmw.async')
local v2 = util.vector2
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local input = require('openmw.input')
local types = require('openmw.types')
local pself = require("openmw.self")
local myui = require('scripts.ErnPerkFramework.pcp.myui')
local ambient = require("openmw.ambient")

local ScrollListFunctions = {}
ScrollListFunctions.__index = ScrollListFunctions

-- renderer is a function that takes in an index and returns a UI element.
-- the UI element should define a non-relative vertical size.
function NewScrollList(height, width, renderer)
    local listElement = ui.create {
        name = 'list',
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            -- relativePosition can be used to scroll the perks list up and down
            --relativePosition = util.vector2(0, -0.5),
            relativePosition = util.vector2(0, 0),
        },
        content = ui.content {}
    }

    local scrollbarElement = ui.create {
        type = ui.TYPE.Widget,
        props = {
            size = v2(20, 0),
            relativeSize = v2(0, 1),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                name = 'background',
                props = {
                    resource = ui.texture { path = 'white' },
                    relativePosition = v2(0, 0),
                    relativeSize = v2(1, 1),
                    alpha = 0.625,
                    color = util.color.rgb(0, 0, 0),
                },
            },
            {
                type = ui.TYPE.Image,
                name = 'thumb',
                props = {
                    resource = ui.texture { path = 'white' },
                    relativePosition = v2(0, 0),
                    relativeSize = v2(1, 0),
                    alpha = 0.4,
                    color = myui.interactiveTextColors.normal.default,
                },
            }
        }
    }



    local scrollbarThumb = {
        type = ui.TYPE.Image,
        name = 'thumb',
        props = {
            resource = ui.texture { path = 'white' },
            relativePosition = v2(0, 0),
            relativeSize = v2(1, 0),
            alpha = 0.4,
            color = myui.interactiveTextColors.normal.default,
        },
    }



    local new = {
        currentIndex = 1,
        height = height,
        renderer = renderer,
        rootLayout = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(height, width),
            },
            content = ui.content {
                perkListElement
            }
        }
    }
    setmetatable(new, ScrollListFunctions)
    return new
end
