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
local pself = require("openmw.self")
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local settings = require("scripts.ErnPerkFramework.settings")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)
local myui = require('scripts.ErnPerkFramework.pcp.myui')

local PerkFunctions = {}
PerkFunctions.__index = PerkFunctions


-- NewPerk makes a new perk from a record
function NewPerk(data)
    local new = {
        record = data
    }
    setmetatable(new, PerkFunctions)
    return new
end

function PerkFunctions.onAdd(self)
    return self.record.onAdd()
end

function PerkFunctions.onRemove(self)
    return self.record.onRemove()
end

function PerkFunctions.name(self)
    local name = self.record.id
    if self.record.localizedName == nil then
        name = self.record.localizedName()
    end
    return name
end

function PerkFunctions.id(self)
    return self.record.id
end

function PerkFunctions.description(self)
    local description = self.record.id .. " description"
    if self.record.localizedDescription == nil then
        description = self.record.localizedDescription()
    end
    return description
end

-- returns:
-- {
-- requirements={list of requirements info, with fields id, name, satisfied, hidden}
-- satisfied={true if all met}
-- }
function PerkFunctions.evaluateRequirements(self)
    local reqs = {}
    local allMet = true
    for i, r in ipairs(self.record.requirements) do
        local satisfied = r.check()
        if not satisfied then
            allMet = false
        end
        local name = r.id
        if r.localizedName == nil then
            name = r.localizedName()
        end

        table.insert(reqs, { id = r.id, name = name, satisfied = satisfied, hidden = (r.hidden and (not satisfied)) })
    end

    -- sort reqs by name
    table.sort(reqs, function(a, b) return string.lower(a.name) < string.lower(b.name) end)

    return {
        requirements = reqs,
        satisfied = allMet,
    }
end

function PerkFunctions.artLayout(self)
    -- These texture dimensions are derived from the Class icon textures.
    -- That way people that don't want to make art can just supply "archer"
    -- or whatever and it will fit.
    local path = "perk_placeholder"
    if self.record.art ~= nil then
        path = self.record.art()
    end
    return {
        type = ui.TYPE.Image,
        alignment = ui.ALIGNMENT.Start,
        props = {
            resource = ui.texture {
                path = path
            },
            size = util.vector2(256, 128)
        },
        size = util.vector2(256, 128)
    }
end

function PerkFunctions.requirementsLayout(self)
    local vFlexLayout = {
        name = "vflex",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
            horizontal = false,
        },
        content = ui.content {},
    }

    local reqs = self.evaluateRequirements()
    if #reqs == 0 then
        local reqLayout = {
            template = interfaces.MWUI.templates.textNormal,
            type = ui.TYPE.Text,
            alignment = ui.ALIGNMENT.End,
            props = {
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0, 0.5),
                text = localization("noRequirement", {}),
            },
        }
        vFlexLayout.content:add(reqLayout)
    end
    for i, req in ipairs(reqs.requirements) do
        local reqLayout = {
            template = interfaces.MWUI.templates.textNormal,
            type = ui.TYPE.Text,
            alignment = ui.ALIGNMENT.End,
            props = {
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0, 0.5),
                text = req.name,
            },
        }
        if not req.satisfied then
            reqLayout.props.textColor = myui.textColors.negative
        end
        if req.hidden then
            reqLayout.props.text = localization("hiddenRequirement", {})
        end

        vFlexLayout.content:add(reqLayout)
    end

    return vFlexLayout
end

function PerkFunctions.detailLayout(self)
    local vFlexLayout = {
        name = "vflex",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
            horizontal = false,
        },
        content = ui.content {},
    }

    local requirementsHeader = {
        template = interfaces.MWUI.templates.textHeader,
        type = ui.TYPE.Text,
        alignment = ui.ALIGNMENT.End,
        props = {
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0, 0.5),
            text = localization("requirements", {}),
        },
    }

    local nameHeader = {
        template = interfaces.MWUI.templates.textHeader,
        type = ui.TYPE.Text,
        alignment = ui.ALIGNMENT.End,
        props = {
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0, 0.5),
            text = self.description(),
        },
    }

    local detailText = {
        template = interfaces.MWUI.templates.textHeader,
        type = ui.TYPE.Text,
        alignment = ui.ALIGNMENT.End,
        props = {
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0, 0.5),
            text = localization("requirements", {}),
        },
    }

    vFlexLayout.content:add(self.artLayout())
    vFlexLayout.content:add(myui.padWidget(4, 0))
    vFlexLayout.content:add(requirementsHeader)
    vFlexLayout.content:add(self.requirementsLayout())
    vFlexLayout.content:add(myui.padWidget(4, 0))
    vFlexLayout.content:add(nameHeader)
    vFlexLayout.content:add(detailText)
end

return {
    NewPerk = NewPerk
}
