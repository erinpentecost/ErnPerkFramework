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
local self = require("openmw.self")
local ambient = require("openmw.ambient")

onFrameFunctions = {}
local makeBorder = require("scripts.ErnPerkFramework.ui.makeBorder")
local makeButton = require("scripts.ErnPerkFramework.ui.makeButton")
local selectedButton = nil
local selectedIndex = nil
local listSize = 19
local currentIndex = 1

local morrowindGold = util.color.rgb(0.792157, 0.647059, 0.376471)
local morrowindLight = util.color.rgb(0.87451, 0.788235, 0.623529)

local exampleData = {}
for i = 1, 100 do
    table.insert(exampleData, "" .. math.floor(math.random() * 100000))
end

local scrollbarBackground
local scrollbarThumb
local currentScrollbarWidth = 0

-- UI elements
local root
local flex_V_H_V1
local flex_V_H_V2

local function updateScrollbar()
    local totalItems = #exampleData
    if totalItems <= listSize then
        scrollbarThumb.props.relativeSize = v2(1, 0)
        scrollbarThumb.props.relativePosition = v2(0, 0)
    else
        local thumbHeight = listSize / totalItems
        local scrollPosition = (1 - thumbHeight) * (currentIndex - 1) / (totalItems - listSize - 1)
        scrollbarThumb.props.relativeSize = v2(1, thumbHeight)
        scrollbarThumb.props.relativePosition = v2(0, scrollPosition)
    end
    flex_V_H_V1:update()
end


local function rebuildList(newIndex)
    --if newIndex == currentIndex then return end
    print("rebuildList", newIndex, selectedIndex)
    if newIndex < currentIndex then
        for i = currentIndex - 1, newIndex, -1 do
            local tempDestroy = flex_V_H_V2.layout.content[#flex_V_H_V2.layout.content]
            flex_V_H_V2.layout.content[#flex_V_H_V2.layout.content] = nil
            tempDestroy:destroy()
            local buttonIndex = i
            local button
            button = makeButton("Confirm" .. buttonIndex, { size = v2(300, 30) }, function()
                ui.showMessage("Confirm" .. buttonIndex .. "clicked")
                if selectedButton then
                    selectedButton.clickbox.userData.selected = false
                    selectedButton.applyColor()
                end
                button.clickbox.userData.selected = true
                selectedButton = button
                selectedIndex = buttonIndex
            end, morrowindGold, root)
            if buttonIndex == selectedIndex then
                selectedButton = button
                button.clickbox.userData.selected = true
                button.applyColor()
            end
            flex_V_H_V2.layout.content:insert(1, button.box)
        end
    elseif newIndex > currentIndex then
        for i = currentIndex + 1, newIndex do
            local tempDestroy = flex_V_H_V2.layout.content[1]
            table.remove(flex_V_H_V2.layout.content, 1)
            local buttonIndex = i + listSize
            local button
            button = makeButton("Confirm" .. buttonIndex, { size = v2(300, 30) }, function()
                ui.showMessage("Confirm" .. buttonIndex .. "clicked")
                if selectedButton then
                    selectedButton.clickbox.userData.selected = false
                    selectedButton.applyColor()
                end
                button.clickbox.userData.selected = true
                selectedButton = button
                selectedIndex = buttonIndex
            end, morrowindGold, root)
            if buttonIndex == selectedIndex then
                selectedButton = button
                button.clickbox.userData.selected = true
                button.applyColor()
            end
            flex_V_H_V2.layout.content:add(button.box)
            tempDestroy:destroy()
        end
    end

    currentIndex = newIndex
    flex_V_H_V2:update()
    updateScrollbar()
end

-- ============================================= UI CREATION =============================================
local function onLoad(data)
    local borderOffset = 3
    local borderFile = "thin"
    local template = makeBorder(borderFile, util.color.rgb(0.5, 0.5, 0.5), borderOffset, {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'black' },
            relativeSize = v2(1, 1),
            alpha = 0.8,
        }
    }).borders

    root = ui.create {
        type = ui.TYPE.Container,
        layer = 'Modal',
        name = "root",
        template = template,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            autoSize = true,
            size = v2(800, 600)
        },
        content = ui.content {},
    }

    local flex_V = {
        type = ui.TYPE.Flex,
        name = "mainFlexV",
        props = { horizontal = false },
        content = ui.content {},
    }
    root.layout.content:add(flex_V)

    -- Header
    flex_V.content:add {
        name = 'text',
        type = ui.TYPE.Text,
        props = {
            text = "Welcome to level 3",
            textColor = morrowindGold,
            textShadow = true,
            textShadowColor = util.color.rgb(0, 0, 0),
            textSize = 24,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
    flex_V.content:add { props = { size = v2(1, 1) * 5 } }

    local flex_V_H = {
        type = ui.TYPE.Flex,
        name = "horizontalFlex",
        props = { horizontal = true },
        content = ui.content {},
    }
    flex_V.content:add(flex_V_H)
    flex_V.content:add { props = { size = v2(1, 1) * 5 } }

    -- Scrollbar column
    flex_V_H_V1 = ui.create {
        type = ui.TYPE.Widget,
        props = {
            size = v2(20, 0),
            relativeSize = v2(0, 1),
        },
        content = ui.content {}
    }
    flex_V_H.content:add(flex_V_H_V1)

    -- List column
    flex_V_H_V2 = ui.create {
        type = ui.TYPE.Flex,
        name = "listColumn",
        props = {
            horizontal = false,
            size = v2(300, 600),
            autoSize = false,
        },
        content = ui.content {},
    }
    flex_V_H.content:add(flex_V_H_V2)

    -- Right column
    local flex_V_H_V3 = ui.create {
        type = ui.TYPE.Flex,
        name = "rightColumn",
        props = {
            horizontal = false,
            size = v2(480, 600),
            autoSize = false,
        },
        content = ui.content {},
    }
    flex_V_H.content:add(flex_V_H_V3)

    -- ============================================= SCROLLBAR =============================================
    scrollbarBackground = {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'white' },
            relativePosition = v2(0, 0),
            relativeSize = v2(1, 1),
            alpha = 0.625,
            color = util.color.rgb(0, 0, 0),
        },
    }

    scrollbarThumb = {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'white' },
            relativePosition = v2(0, 0),
            relativeSize = v2(1, 0),
            alpha = 0.4,
            color = morrowindGold,
        },
    }
    -- =============================================
    -- Scrollbar Background (click + highlight)
    -- =============================================
    scrollbarBackground.events = {
        mousePress = async:callback(function(data, elem)
            local totalItems = #exampleData
            if totalItems <= listSize then return end
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
                newIndex = math.max(1, currentIndex - pageAmount)
            else
                -- scroll down one page
                newIndex = math.min(totalItems - listSize, currentIndex + pageAmount)
            end

            rebuildList(newIndex)
        end),

        focusGain = async:callback(function(_, elem)
            elem.props.alpha = 0.1
            elem.props.color = morrowindGold
            flex_V_H_V1:update()
        end),

        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.625
            elem.props.color = util.color.rgb(0, 0, 0)
            flex_V_H_V1:update()
        end),
    }

    -- =============================================
    -- Scrollbar Thumb (drag + highlight)
    -- =============================================
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
                local totalItems = #exampleData
                if totalItems <= listSize then return end

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
                local maxScrollIndex = math.max(1, totalItems - listSize)
                local newIndex = math.floor(newScrollPosition * (maxScrollIndex - 1) + 0.5) + 1

                rebuildList(newIndex)
            end
        end),

        focusGain = async:callback(function(_, elem)
            elem.props.alpha = 0.8
            flex_V_H_V1:update()
        end),

        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.4
            flex_V_H_V1:update()
        end),
    }
    flex_V_H_V1.layout.content:add(scrollbarBackground)
    flex_V_H_V1.layout.content:add(scrollbarThumb)

    -- ============================================= LIST POPULATION =============================================
    for i = currentIndex, math.min(#exampleData, currentIndex + listSize) do
        local button
        button = makeButton("Confirm" .. i, { size = v2(300, 30) }, function()
            ui.showMessage("Confirm" .. i .. "clicked")
            if selectedButton then
                selectedButton.clickbox.userData.selected = false
                selectedButton.applyColor()
            end
            button.clickbox.userData.selected = true
            selectedButton = button
            selectedIndex = i
        end, morrowindGold, root)
        flex_V_H_V2.layout.content:add(button.box)
    end




    updateScrollbar()
end

-- ============================================= SCROLL & FRAME =============================================



local function onMouseWheel(direction)
    direction = direction * 2
    local newIndex = math.max(1, math.min(#exampleData - listSize, currentIndex - direction))
    rebuildList(newIndex)
end

local function onFrame(dt)
    for _, onFrameFunction in pairs(onFrameFunctions) do
        onFrameFunction(dt)
    end
end

return {
    engineHandlers = {
        onInit = onLoad,
        onLoad = onLoad,
        onFrame = onFrame,
        onMouseWheel = onMouseWheel,
    },
    eventHandlers = {}
}
