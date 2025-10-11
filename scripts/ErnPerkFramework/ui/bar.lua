-- scripts/ErnPerkFramework/ui/ui_scroll_list.lua
-- Scrollbar + list helper for OpenMW UI
-- Constructor: ScrollList.new(totalSize, opts)
-- - Exposes: .scrollbarContainer (widget) and .listContainer (flex that holds item elements)
-- - Accepts an itemFactory callback (opts.itemFactory or setItemFactory) that returns a UI element
--   for a given index. The returned object can be either:
--     * a UI element that can be added directly to layout.content:add(...)
--     * or an object with a `.box` field (like many button factories) in which case `.box` is used.
-- - Does NOT provide an index-change callback API (per request).

local ui           = require('openmw.ui')
local util         = require('openmw.util')
local async        = require('openmw.async')
local v2           = util.vector2

local ScrollList   = {}
ScrollList.__index = ScrollList

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- totalSize (number), opts (table, optional)
-- opts.itemFactory(index) -> UI element or { box = uiElement }
-- opts.visibleCount (number)
-- opts.scrollHeight (pixels)
-- opts.scrollbarWidth
-- opts.listWidth
-- opts.thumbColor, opts.bgColor (util.color.rgb)
-- opts.pageAmount (how many indices to move on background click; default = visibleCount)
function ScrollList.new(totalSize, opts)
    assert(type(totalSize) == "number", "ScrollList.new expects totalSize (number)")
    opts                    = opts or {}

    local self              = setmetatable({}, ScrollList)

    -- core state
    self.totalSize          = math.max(0, math.floor(totalSize))
    self.visibleCount       = opts.visibleCount and math.max(1, math.floor(opts.visibleCount)) or 10
    self.currentIndex       = clamp(opts.startIndex and math.floor(opts.startIndex) or 1, 1,
        math.max(1, self.totalSize - self.visibleCount + 1))

    -- visuals / layout config
    self.scrollHeight       = opts.scrollHeight or 600
    self.scrollbarWidth     = opts.scrollbarWidth or 20
    self.listWidth          = opts.listWidth or 300
    self.thumbColor         = opts.thumbColor or util.color.rgb(0.792157, 0.647059, 0.376471)
    self.bgColor            = opts.bgColor or util.color.rgb(0, 0, 0)
    self.pageAmount         = opts.pageAmount or self.visibleCount

    -- callback that creates items for indexes
    self.itemFactory        = opts.itemFactory -- may be nil initially; user can call :setItemFactory(fn)

    -- keep track of visible item objects returned by itemFactory so we can destroy them if needed
    self.visibleItems       = {}

    -- -------------------- UI ELEMENTS (public) --------------------
    -- widget for the scrollbar (user should add this into their layout)
    self.scrollbarContainer = ui.create {
        type = ui.TYPE.Widget,
        props = {
            size = v2(self.scrollbarWidth, 0),
            relativeSize = v2(0, 1),
        },
        content = ui.content {},
    }

    -- flex that will contain list items (user should add this into their layout)
    self.listContainer      = ui.create {
        type = ui.TYPE.Flex,
        name = "ScrollListItems",
        props = {
            horizontal = false,
            size = v2(self.listWidth, self.scrollHeight),
            autoSize = false,
        },
        content = ui.content {},
    }

    -- internal visual elements added to scrollbarContainer
    self._background        = {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'white' },
            relativePosition = v2(0, 0),
            relativeSize = v2(1, 1),
            alpha = 0.625,
            color = self.bgColor,
        },
    }

    self._thumb             = {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'white' },
            relativePosition = v2(0, 0),
            relativeSize = v2(1, 0),
            alpha = 0.4,
            color = self.thumbColor,
        },
    }

    local me                = self

    -- -------------------- scrollbar background events --------------------
    self._background.events = {
        mousePress = async:callback(function(data)
            if me.totalSize <= me.visibleCount then return end
            local clickY = data.offset.y
            local containerH = me.scrollHeight
            local thumbHeightPx = me._thumb.props.relativeSize.y * containerH
            local thumbYpx = me._thumb.props.relativePosition.y * containerH

            local newIndex
            if clickY < thumbYpx then
                newIndex = math.max(1, me.currentIndex - me.pageAmount)
            else
                newIndex = math.min(me:maxIndex(), me.currentIndex + me.pageAmount)
            end

            me:setIndex(newIndex)
        end),

        focusGain = async:callback(function(_, elem)
            print("_background.focusGain start")
            elem.props.alpha = 0.1
            elem.props.color = me.thumbColor
            me.scrollbarContainer:update()
            print("_background.focusGain end")
        end),

        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.625
            elem.props.color = me.bgColor
            me.scrollbarContainer:update()
        end),
    }

    -- -------------------- thumb events (dragging) --------------------
    self._thumb.events      = {
        mousePress = async:callback(function(data, elem)
            if data.button == 1 then
                if not elem.userData then elem.userData = {} end
                elem.userData.isDragging = true
                elem.userData.dragStartY = data.position.y
                elem.userData.dragStartThumbY = elem.props.relativePosition.y * me.scrollHeight
            end
        end),

        mouseRelease = async:callback(function(_, elem)
            if elem.userData then elem.userData.isDragging = false end
        end),

        mouseMove = async:callback(function(data, elem)
            if not (elem.userData and elem.userData.isDragging) then return end
            if me.totalSize <= me.visibleCount then return end

            local containerH = me.scrollHeight
            local thumbHeightPx = elem.props.relativeSize.y * containerH
            local availablePx = containerH - thumbHeightPx
            if availablePx <= 0 then return end

            local deltaY = data.position.y - elem.userData.dragStartY
            local newThumbYpx = math.max(0, math.min(availablePx, elem.userData.dragStartThumbY + deltaY))

            elem.props.relativePosition = v2(0, newThumbYpx / containerH)

            local newScrollFrac = newThumbYpx / availablePx
            local maxIdx = me:maxIndex()
            local newIndex
            if maxIdx <= 1 then
                newIndex = 1
            else
                newIndex = math.floor(newScrollFrac * (maxIdx - 1) + 0.5) + 1
            end

            me:setIndex(newIndex)
        end),

        focusGain = async:callback(function(_, elem)
            print("_thumb.focusGain start")
            elem.props.alpha = 0.8
            me.scrollbarContainer:update()
            print("_thumb.focusGain end")
        end),

        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.4
            me.scrollbarContainer:update()
        end),
    }

    -- add visuals
    self.scrollbarContainer.layout.content:add(self._background)
    self.scrollbarContainer.layout.content:add(self._thumb)

    -- initialize thumb and visible items
    self:updateThumb()
    -- populate initial visible items (if itemFactory provided)
    if self.itemFactory then
        self:rebuild()
    end

    return self
end

-- Maximum valid starting index (so that visibleCount items fit)
function ScrollList:maxIndex()
    return math.max(1, math.max(0, self.totalSize - self.visibleCount + 1))
end

-- Update the thumb size & position
function ScrollList:updateThumb()
    print("updateThumb start")
    local total = self.totalSize
    if total <= self.visibleCount or total == 0 then
        self._thumb.props.relativeSize = v2(1, 0)
        self._thumb.props.relativePosition = v2(0, 0)
    else
        local thumbHeight = self.visibleCount / total
        local availableFrac = 1 - thumbHeight
        local maxIdx = self:maxIndex()
        local idxRatio = (maxIdx <= 1) and 0 or (self.currentIndex - 1) / (maxIdx - 1)
        local scrollPos = availableFrac * idxRatio
        self._thumb.props.relativeSize = v2(1, thumbHeight)
        self._thumb.props.relativePosition = v2(0, scrollPos)
    end
    self.scrollbarContainer:update()
    print("updateThumb end")
end

-- Safely destroy previously visible items (if they implement :destroy())
local function safeDestroyItem(item)
    if not item then return end
    if type(item) == "table" then
        if type(item.destroy) == "function" then
            pcall(item.destroy, item)
            return
        end
        -- if it's a wrapper with .box
        if item.box and type(item.box.destroy) == "function" then
            pcall(item.box.destroy, item.box)
            return
        end
    end
end

-- Clear listContainer content and destroy previously created items
function ScrollList:clearVisibleItems()
    for _, item in ipairs(self.visibleItems) do
        safeDestroyItem(item)
    end
    self.visibleItems = {}
    -- reset the UI content object
    self.listContainer.layout.content = ui.content {}
end

-- Rebuild visible items from currentIndex (if itemFactory exists)
function ScrollList:rebuild()
    print("rebuild start")
    if not self.itemFactory then
        -- nothing to populate
        self:clearVisibleItems()
        return
    end

    local total = self.totalSize
    if total == 0 then
        self:clearVisibleItems()
        self:updateThumb()
        return
    end

    self.currentIndex = clamp(self.currentIndex, 1, self:maxIndex())

    -- clear old
    self:clearVisibleItems()

    local lastIndex = math.min(total, self.currentIndex + self.visibleCount - 1)
    for i = self.currentIndex, lastIndex do
        print("building item at index " .. i)
        local itemObj = self.itemFactory(i)
        if itemObj then
            local toAdd = (itemObj.box and itemObj.box) or itemObj
            self.listContainer.layout.content:add(toAdd)
            table.insert(self.visibleItems, itemObj)
        end
    end

    -- update visuals
    self.listContainer:update()
    self:updateThumb()
    print("rebuild end")
end

-- Set current index and rebuild visible items
function ScrollList:setIndex(newIndex)
    print("setIndex start")
    local n = clamp(math.floor(newIndex or 1), 1, self:maxIndex())
    if n == self.currentIndex then
        -- still ensure visuals are in sync
        self:updateThumb()
        return
    end
    self.currentIndex = n
    self:rebuild()
    print("setIndex end")
end

-- Set total size (e.g., when data changes) and refresh
function ScrollList:setTotalSize(n)
    self.totalSize = math.max(0, math.floor(n or 0))
    self.currentIndex = clamp(self.currentIndex, 1, self:maxIndex())
    self:rebuild()
end

-- Set visible count and refresh
function ScrollList:setVisibleCount(n)
    self.visibleCount = math.max(1, math.floor(n or 1))
    self.pageAmount = self.pageAmount or self.visibleCount
    self.currentIndex = clamp(self.currentIndex, 1, self:maxIndex())
    self:rebuild()
end

-- Provide / change the item factory used to create item Elements
-- itemFactory(index) -> UI element or { box = uiElement }
function ScrollList:setItemFactory(fn)
    assert(type(fn) == "function" or fn == nil, "setItemFactory expects function or nil")
    self.itemFactory = fn
    self:rebuild()
end

-- Mouse wheel behavior (positive/negative ints)
function ScrollList:onMouseWheel(direction)
    if self.totalSize <= self.visibleCount then return end
    -- keep previous behavior where wheel was multiplied by 2
    local step = (direction or 0) * 2
    local newIndex = self.currentIndex - step
    self:setIndex(newIndex)
end

return ScrollList
