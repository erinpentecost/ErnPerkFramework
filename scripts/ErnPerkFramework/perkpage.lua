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
local log = require("scripts.ErnBurglary.log")
local settings = require("scripts.ErnPerkFramework.settings")
local UI = require('openmw.interfaces').UI

-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/widgets/widget.html#properties
-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/openmw_ui.html##(Template)

local function showPerkUI(data)
    log(nil, "Showing Perk UI...")
end


return {
    eventHandlers = {
        [settings.MOD_NAME .. "showPerkUI"] = showPerkUI,
    }
}
