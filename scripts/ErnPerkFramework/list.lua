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
local pself = require("openmw.self")
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local myui = require('scripts.ErnPerkFramework.pcp.myui')

local ListFunctions = {}
ListFunctions.__index = ListFunctions

function NewList(renderer, props)
    if type(renderer) ~= "function" then
        error("renderer must be a function")
    end
    local new = {
        topIndex = 1,
        selectedIndex = 1,
        displayCount = 14,
        totalCount = 1,
        renderer = renderer,
        containerElement = ui.create {
            name = 'listRoot',
            type = ui.TYPE.Flex,
            props = props or { horizontal = false },
            content = ui.content {}
        }
    }
    setmetatable(new, ListFunctions)
    return new
end

function ListFunctions.clamp(self, index)
    return ((index - 1) % self.totalCount) + 1
end

function ListFunctions.destroy(self)
    for _, old in ipairs(self.containerElement.layout.content) do
        old:destroy()
    end
    self.containerElement.layout.content = ui.content {}
end

function ListFunctions.update(self)
    -- delete all old content
    for _, old in ipairs(self.containerElement.layout.content) do
        old:destroy()
    end
    self.containerElement.layout.content = ui.content {}

    -- just wrap around infinitely
    self.topIndex = self:clamp(self.topIndex)
    self.selectedIndex = self:clamp(self.selectedIndex)

    -- if selectedIndex is outside our window, adjust the window.
    if self.selectedIndex < self.topIndex then
        self.topIndex = self.selectedIndex
    elseif self.selectedIndex > self.topIndex + self.displayCount then
        self.topIndex = self:clamp(self.selectedIndex - self.displayCount)
    end

    -- make element items and insert them.
    -- we can show fewer items if the total count is less than display count
    for i = self.topIndex, self.topIndex + math.min(self.displayCount, self.totalCount) do
        local modI = self:clamp(i)
        local entryElement = self.renderer(modI, modI == self.selectedIndex)
        table.insert(self.containerElement.layout.content, entryElement)
    end
    self.containerElement:update()
end

function ListFunctions.setTotal(self, total)
    if type(total) ~= "number" then
        error("total must be a number")
    end
    self.totalCount = total
    self.selectedIndex = self:clamp(self.selectedIndex)
end

function ListFunctions.setSelectedIndex(self, idx)
    self.selectedIndex = self:clamp(idx)
end

-- scroll 'step' indices. negative number is up. you want to call update afterward.
function ListFunctions.scroll(self, step)
    self.selectedIndex = self:clamp(self.selectedIndex + step)
end

return { NewList = NewList }
