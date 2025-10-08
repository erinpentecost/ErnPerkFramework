-- Import required modules
local makeBorder = require("scripts.ErnPerkFramework.ui.makeBorder")
local core = require('openmw.core')
local util = require('openmw.util')
local ui = require('openmw.ui')
local v2 = util.vector2
local async = require('openmw.async')

-- Configuration from main window
local textSize = 24
local spacer = 5
local borderOffset = 1
local borderFile = "thin"

-- Colors (should match main window)
local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
    if not result then
        return util.color.rgb(1, 1, 1)
    end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        print("UNEXPECTED COLOR: rgb of size=", #rgb)
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local function darkenColor(color, mult)
    return util.color.rgb(color.r * mult, color.g * mult, color.b * mult)
end

-- Texture cache
local textureCache = {}
local function getTexture(path)
    if not textureCache[path] then
        textureCache[path] = ui.texture { path = path }
    end
    return textureCache[path]
end

-- Color setup
local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")
local background = ui.texture { path = 'black' }

-- Border templates
local borderTemplate = makeBorder(borderFile, util.color.rgb(0.5, 0.5, 0.5), borderOffset, {
    type = ui.TYPE.Image,
    props = {
        relativeSize = v2(1, 1),
        alpha = 0.5,
    }
}).borders


-- makeButton v4.0
local function makeButton(label, props, func, highlightColor, parent)
    local creationTime = core.getRealTime()
    local uniqueButtonId = "" .. math.random()
    local box = ui.create {
        name = uniqueButtonId,
        type = ui.TYPE.Widget,
        props = props,
        content = ui.content {}
    }

    local buttonBackground = {
        name = 'background',
        --template = borderTemplate,
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1, 1),
            resource = getTexture('white'),
            color = util.color.rgb(0, 0, 0),
            alpha = 0.1,
        },
    }
    box.layout.content:add(buttonBackground)

    local buttonBorder = {
        name = 'background',
        template = borderTemplate,
        props = {
            relativeSize = v2(1, 1),
            alpha = 0,
        },
    }
    box.layout.content:add(buttonBorder)

    --- any content here
    local text = {
        name = 'text',
        type = ui.TYPE.Text,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            text = tostring(label),
            textColor = textColor,
            textShadow = true,
            textShadowColor = util.color.rgb(0, 0, 0),
            textSize = textSize,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
    box.layout.content:add(text)

    local clickbox = {
        name = 'clickbox',
        props = {
            relativeSize = v2(1, 1),
        },
        userData = {
            focus = false,
            pressed = false,
            selected = false,
            --applyColor = func
        },
    }

    local function applyColor(elem)
        elem = elem or clickbox
        --if renameWindow then -- HARDCODED
        if elem.userData.pressed then
            buttonBackground.props.color = highlightColor or morrowindGold
            buttonBackground.props.alpha = 0.7
            buttonBorder.props.alpha = 1
        elseif elem.userData.focus then
            buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.1)
            buttonBackground.props.alpha = 0.7
            buttonBorder.props.alpha = 1
        elseif elem.userData.selected then
            buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.1)
            buttonBackground.props.alpha = 0.5
            buttonBorder.props.alpha = 0.8
        else
            buttonBackground.props.color = util.color.rgb(0, 0, 0)
            buttonBackground.props.alpha = 0.1
            buttonBorder.props.alpha = 0
        end
        box:update()
        --end
    end
    clickbox.userData.applyColor = applyColor
    local s = { box = box, clickbox = clickbox, applyColor = applyColor }

    clickbox.events = {
        mouseRelease = async:callback(function(_, elem)
            elem.userData.pressed = false
            onFrameFunctions[uniqueButtonId] = function()
                --if renameWindow then
                if elem.userData.focus and core.getRealTime() > creationTime + 0.4 then
                    func(elem)
                end
                applyColor(elem)
                --end
                onFrameFunctions[uniqueButtonId] = nil
            end
        end),
        focusGain = async:callback(function(_, elem)
            elem.userData.focus = true
            applyColor(elem)
        end),
        focusLoss = async:callback(function(_, elem)
            elem.userData.focus = false
            elem.userData.pressed = false
            applyColor(elem)
        end),
        mousePress = async:callback(function(_, elem)
            elem.userData.focus = true
            elem.userData.pressed = true
            applyColor(elem)
        end),
    }
    box.layout.content:add(clickbox)
    return s
end





return makeButton
