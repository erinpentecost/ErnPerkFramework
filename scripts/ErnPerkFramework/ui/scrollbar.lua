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

local ScrollbarFunctions = {}
ScrollbarFunctions.__index = ScrollbarFunctions

-- renderer is a function takes in an index and returns a UI element.
function NewScrollbar(count, renderer)
    local new = {
        currentIndex = 1,
        totalCount = count,
        shownCount = 10,
        renderer = renderer,
        scrollbarElement = ui.create {},
        listElement = ui.create {
            type = ui.TYPE.Flex,
            name = "listColumn",
            props = {
                horizontal = false,
                size = v2(300, 600),
                autoSize = false,
            },
            content = ui.content {},
        }
    }
    setmetatable(new, ScrollbarFunctions)
    return new
end

function ScrollbarFunctions.thumb(self)
    return self.scrollbarElement.layout.content.thumb
end

function ScrollbarFunctions.background(self)
    return self.scrollbarElement.layout.content.background
end

function ScrollbarFunctions.updateScrollbar(self)
    local totalItems = self.totalCount
    if totalItems <= self.shownCount then
        self:thumb().props.relativeSize = v2(1, 0)
        self:thumb().props.relativePosition = v2(0, 0)
    else
        local thumbHeight = self.shownCount / totalItems
        local scrollPosition = (1 - thumbHeight) * (self.currentIndex - 1) / (totalItems - self.shownCount - 1)
        self:thumb().relativeSize = v2(1, thumbHeight)
        self:thumb().relativePosition = v2(0, scrollPosition)
    end
    self.scrollbarElement:update()
end

function ScrollbarFunctions.rebuildList(self, newIndex)
    --if newIndex == currentIndex then return end
    print("rebuildList", newIndex, self.currentIndex)
    if newIndex < self.currentIndex then
        for i = self.currentIndex - 1, newIndex, -1 do
            -- delete elements out of view
            local tempDestroy = self.listElement.layout.content[#self.listElement.layout.content]
            self.listElement.layout.content[#self.listElement.layout.content] = nil
            tempDestroy:destroy()
            -- insert new elements
            self.listElement.layout.content:insert(1, self.renderer(i))
        end
    elseif newIndex > self.currentIndex then
        for i = self.currentIndex + 1, newIndex do
            local tempDestroy = self.listElement.layout.content[1]
            table.remove(self.listElement.layout.content, 1)
            local buttonIndex = i + self.shownCount
            self.listElement.layout.content:add(self.renderer(buttonIndex))
            tempDestroy:destroy()
        end
    end

    self.currentIndex = newIndex
    self.listElement:update()
    self:updateScrollbar()
end

function ScrollbarFunctions.Element(self)
    return self.scrollbarElement
end

function ScrollbarFunctions.BuildElement(self)
    self.scrollbarElement = ui.create {
        type = ui.TYPE.Widget,
        props = {
            size = v2(20, 0),
            relativeSize = v2(0, 1),
        },
        content = ui.content {}
    }

    local scrollbarBackground = {
        type = ui.TYPE.Image,
        name = 'background',
        props = {
            resource = ui.texture { path = 'white' },
            relativePosition = v2(0, 0),
            relativeSize = v2(1, 1),
            alpha = 0.625,
            color = util.color.rgb(0, 0, 0),
        },
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

    scrollbarBackground.events = {
        mousePress = async:callback(function(data, elem)
            local totalItems = self.totalCount
            if totalItems <= self.shownCount then return end
            local scrollAmount = 10

            local scrollContainerHeight = 600
            local thumbHeight = scrollbarThumb.props.relativeSize.y * scrollContainerHeight
            local currentThumbY = scrollbarThumb.props.relativePosition.y * scrollContainerHeight
            local clickY = data.offset.y

            -- compute how many entries we want to scroll (always scrollAmount)
            local pageAmount = scrollAmount
            local newIndex

            if clickY < currentThumbY then
                -- scroll up one page
                newIndex = math.max(1, self.currentIndex - pageAmount)
            else
                -- scroll down one page
                newIndex = math.min(totalItems - self.shownCount, self.currentIndex + pageAmount)
            end

            self:rebuildList(newIndex)
        end),

        focusGain = async:callback(function(_, elem)
            elem.props.alpha = 0.1
            elem.props.color = myui.interactiveTextColors.normal.default
            self.scrollbarElement:update()
        end),

        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.625
            elem.props.color = util.color.rgb(0, 0, 0)
            self.scrollbarElement:update()
        end),
    }

    scrollbarThumb.events = {
        mousePress = async:callback(function(data, elem)
            if data.button == 1 then
                if not elem.userData then elem.userData = {} end
                elem.userData.isDragging = true
                elem.userData.dragStartY = data.position.y
                elem.userData.dragStartThumbY = elem.props.relativePosition.y * 600
            end
        end),

        mouseRelease = async:callback(function(_, elem)
            if elem.userData then
                elem.userData.isDragging = false
            end
        end),

        mouseMove = async:callback(function(data, elem)
            if elem.userData and elem.userData.isDragging then
                local totalItems = self.totalCount
                if totalItems <= self.shownCount then return end

                local scrollContainerHeight = 600
                local thumbHeight = elem.props.relativeSize.y * scrollContainerHeight
                local availableScrollDistance = scrollContainerHeight - thumbHeight
                if availableScrollDistance <= 0 then return end

                local deltaY = data.position.y - elem.userData.dragStartY
                local newThumbY = math.max(0, math.min(
                    availableScrollDistance,
                    elem.userData.dragStartThumbY + deltaY
                ))

                elem.props.relativePosition = v2(0, newThumbY / scrollContainerHeight)

                local newScrollPosition = newThumbY / availableScrollDistance
                local maxScrollIndex = math.max(1, totalItems - self.shownCount)
                local newIndex = math.floor(newScrollPosition * (maxScrollIndex - 1) + 0.5) + 1

                self:rebuildList(newIndex)
            end
        end),

        focusGain = async:callback(function(_, elem)
            elem.props.alpha = 0.8
            self.scrollbarElement:update()
        end),

        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.4
            self.scrollbarElement:update()
        end),
    }
    self.scrollbarElement.layout.content:add(scrollbarBackground)
    self.scrollbarElement.layout.content:add(scrollbarThumb)

    self:updateScrollbar()

    return self.scrollbarElement
end

return {
    NewScrollbar = NewScrollbar,
}
