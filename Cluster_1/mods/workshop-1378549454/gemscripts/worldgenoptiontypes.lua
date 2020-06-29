--[[
Copyright (C) 2019 Zarklord

This file is part of Gem Core.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details 
The source codes does not come with any warranty including
the implied warranty of merchandise. 
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to 
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

local CustomizationList = require("widgets/redux/worldcustomizationlist")
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local TextEdit = require("widgets/textedit")
local TEMPLATES = require("widgets/redux/templates")
local FrontendHelper = gemrun("tools/frontendhelper", GEMENV.modname)

FrontendHelper.DoOnce(function()
    local _Disable = TextEdit.Disable
    function TextEdit:Disable(...)
        TextEdit._base.Disable(self, ...)
        self:SetEditing(false)
        self:DoIdleImage()
        if _Disable then
            _Disable(self, ...)
        end
    end

    local _OnControl = TextEdit.OnControl
    function TextEdit:OnControl(...)
        if not self:IsEnabled() then return end
        return _OnControl(self, ...)
    end

    local _DoHoverImage = TextEdit.DoHoverImage
    function TextEdit:DoHoverImage(...)
        if not self:IsEnabled() then return end
        return _DoHoverImage(self, ...)
    end
end)

-- from ServerCreationScreen
local dialog_size_x = 830
local dialog_width = dialog_size_x + (60*2) -- nineslice sides are 60px each

local num_columns = 2
local end_spacing = 10
local item_height = 70
local multiplier = 315/40
local padded_height = item_height + end_spacing
local padded_width = dialog_width/num_columns * 0.95
local padded_width_wide = padded_width*num_columns
local item_width = padded_width - end_spacing*2
local item_width_wide = padded_width_wide - end_spacing*2
local textentry_width = item_width - item_height - end_spacing*2
local widetextentry_width = item_width_wide - item_height - end_spacing*2
local textentry_height = textentry_width/multiplier
local widetextentry_height = item_height
local font_size = 25

local ShouldHackScrollingGrid = false
local customizationlist = nil
local options = nil
FrontendHelper.ReplaceFunction(TEMPLATES, "ScrollingGrid", function(_ScrollingGrid, items, opts, ...)
    if ShouldHackScrollingGrid then
        local self = customizationlist
        local function CreateWideTextExtry()
            local opt = Widget("opt_widetextentry")
            local opt_root = opt:AddChild(Widget("opt_widetextentry_root"))
            opt_root:SetPosition(padded_width * (num_columns-1)/2, 0)
            opt.bg = opt_root:AddChild(TEMPLATES.ListItemBackground_Static(padded_width_wide, padded_height))

            local image_parent = opt_root:AddChild(Widget("imageparent"))
            opt.image = image_parent:AddChild(Image())
            opt.icon_txt = image_parent:AddChild(Text(NEWFONT_OUTLINE, 20))

            local widetextentry = opt_root:AddChild(TEMPLATES.StandardSingleLineTextEntry(nil, widetextentry_width, widetextentry_height, NEWFONT, 28/0.8))
            widetextentry.textbox:SetRegionSize(widetextentry_width-50--[[normally 30, 50 makes it better]], widetextentry_height) -- this needs to be slightly narrower than the BG because we don't have margins
            widetextentry.textbox:SetTextPrompt("", UICOLOURS.GREY)
            widetextentry.textbox:SetHAlign(ANCHOR_MIDDLE)
            widetextentry.textbox.prompt:SetHAlign(ANCHOR_MIDDLE)
            -- Only the widetextentry shows focus.
            opt.focus_forward = widetextentry
            opt_root.focus_forward = widetextentry
            opt.image.focus_forward = widetextentry
            opt.bg.focus_forward = widetextentry

            widetextentry.textbox.OnTextInputted = function()
                local selection = widetextentry.textbox:GetLineEditString()
                opt.data.selection = selection
                if self.spinnerCB then
                    self.spinnerCB(opt.data.option.name, selection)
                end
            end

            widetextentry:SetPosition((item_width_wide/2)-(widetextentry_width/2)-end_spacing, 0)
            image_parent:SetPosition((-item_width_wide/2)+(item_height/2), 0)

            widetextentry.SetEditable = function(_, is_editable) 
                if is_editable then
                    widetextentry.textbox:Enable()
                else
                    widetextentry.textbox:Disable()
                end
            end

            widetextentry.SetPrompt = function(_, prompt_text) 
                if prompt_text then
                    widetextentry.textbox.prompt:SetString(prompt_text)
                else
                    widetextentry.textbox.prompt:SetString("")
                end
                textentry.textbox:_TryUpdateTextPrompt()
            end

            widetextentry.SetSelected = function(_, text)
                widetextentry.textbox:SetString(text)
            end

            opt.widetextentry = widetextentry

            return opt
        end
        local function CreateTextExtry()
            local opt = Widget("opt_textentry")
            opt.bg = opt:AddChild(TEMPLATES.ListItemBackground_Static(padded_width, padded_height))

            local image_parent = opt:AddChild(Widget("imageparent"))
            opt.image = image_parent:AddChild(Image())
            opt.icon_txt = image_parent:AddChild(Text(NEWFONT_OUTLINE, 20))

            local textentry = opt:AddChild(TEMPLATES.StandardSingleLineTextEntry(nil, textentry_width, textentry_height, NEWFONT, 28/0.8, ""))
            textentry.textbox:SetHAlign(ANCHOR_MIDDLE)
            textentry.textbox.prompt:SetHAlign(ANCHOR_MIDDLE)
            --textentry.textbox:SetRegionSize(textentry_width-50--[[normally 30, 50 makes it better]], textentry_height) -- this needs to be slightly narrower than the BG because we don't have margins
            -- Only the textentry shows focus.
            opt.focus_forward = textentry
            opt.image.focus_forward = textentry
            opt.bg.focus_forward = textentry

            textentry.textbox.OnTextInputted = function()
                local selection = textentry.textbox:GetLineEditString()
                opt.data.selection = selection
                if self.spinnerCB then
                    self.spinnerCB(opt.data.option.name, selection)
                end
            end

            textentry:SetPosition((item_width/2)-(textentry_width/2)-end_spacing, 0)
            image_parent:SetPosition((-item_width/2)+(item_height/2), 0)

            textentry.SetEditable = function(_, is_editable) 
                if is_editable then
                    textentry.textbox:Enable()
                else
                    textentry.textbox:Disable()
                end
            end

            textentry.SetPrompt = function(_, prompt_text) 
                if prompt_text then
                    textentry.textbox.prompt:SetString(prompt_text)
                else
                    textentry.textbox.prompt:SetString("")
                end
                textentry.textbox:_TryUpdateTextPrompt()
            end

            textentry.SetSelected = function(_, text)
                textentry.textbox:SetString(text)
            end

            opt.textentry = textentry

            return opt
        end

        local OPTIONS_REMAP = UpvalueHacker.GetUpvalue(opts.apply_fn, "OPTIONS_REMAP")

        local location_name = STRINGS.UI.SANDBOXMENU.LOCATION[string.upper(self.location)] or STRINGS.UI.SANDBOXMENU.LOCATION.UNKNOWN
        local lastgroup = nil
        for i,v in ipairs(options) do

            -- Insert text headings between groups
            if v.group ~= lastgroup then

                -- Combining multiple column items and cross-column titles in one
                -- grid, so we need to pad out previous sections with empty if they
                -- aren't full and insert an empties after the header to fill the
                -- rest of the row.
                local wrapped_index = #items % num_columns
                if wrapped_index > 0 then
                    for col=wrapped_index+1,num_columns do
                        table.insert(items, {
                            is_empty = true,
                        })
                    end
                end

                table.insert(items, {
                    heading_text = string.format("%s %s", location_name, v.grouplabel)
                })

                for col = 2, num_columns do
                    table.insert(items, {
                        is_empty = true,
                    })
                end

                lastgroup = v.group
            end

            table.insert(items, {
                option = v,
                selection = v.default,
            })

            if v.options_remap then
                OPTIONS_REMAP[v.name] = v.options_remap
            end

            if v.widget_type == "widetextentry" then
                for col = 2, num_columns do
                    table.insert(items, {
                        is_empty = true,
                    })
                end
            end
        end

        local ScrollWidgetsCtor = opts.item_ctor_fn
        function opts.item_ctor_fn(context, i, ...)
            local item = ScrollWidgetsCtor(context, i, ...)
            item.opt_textentry = item:AddChild(CreateTextExtry())
            item.opt_widetextentry = item:AddChild(CreateWideTextExtry())
            return item
        end
        local ApplyDataToWidget = opts.apply_fn
        function opts.apply_fn(context, widget, data, index, ...)
            widget.opt_textentry:Hide()
            widget.opt_widetextentry:Hide()

            if not data or data.is_empty then
                return ApplyDataToWidget(context, widget, data, index, ...)
            end

            if data.heading_text then
                return ApplyDataToWidget(context, widget, data, index, ...)
            end

            local v = data.option
            assert(v)

            if v.widget_type == "textentry" then
                data.is_empty = true
                local rets = {ApplyDataToWidget(context, widget, data, index, ...)}
                data.is_empty = nil

                local opt = widget.opt_textentry
                widget.focus_forward = opt
                opt:Show()
                opt.data = data

                local icon_image = v.image
                local icon_txt = nil
                -- TODO(petera): Test text looks good on Rail
                if PLATFORM == "WIN32_RAIL" and OPTIONS_REMAP[v.name] then
                    --~ print( v.image, v.name )
                    icon_image = OPTIONS_REMAP[v.name].img
                    icon_txt = STRINGS.UI.CUSTOMIZATIONSCREEN.ICON_TITLES[string.upper(v.name)]
                end
                opt.image:SetTexture(v.atlas or "images/customisation.xml", icon_image)
                opt.image:SetSize(item_height, item_height)
                opt.icon_txt:SetString(icon_txt)

                opt.textentry:SetSelected(opt.data.selection)

                opt.textentry:SetPrompt(STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(v.name)])

                if data.option.neveredit then
                    opt.textentry:SetEditable(false)
                else
                    opt.textentry:SetEditable(self.allowEdit or data.option.alwaysedit)
                end
                return unpack(rets)
            elseif v.widget_type == "widetextentry" then
                data.is_empty = true
                local rets = {ApplyDataToWidget(context, widget, data, index, ...)}
                data.is_empty = nil

                local opt = widget.opt_widetextentry
                widget.focus_forward = opt
                opt:Show()
                opt.data = data

                local icon_image = v.image
                local icon_txt = nil
                -- TODO(petera): Test text looks good on Rail
                if PLATFORM == "WIN32_RAIL" and OPTIONS_REMAP[v.name] then
                    --~ print( v.image, v.name )
                    icon_image = OPTIONS_REMAP[v.name].img
                    icon_txt = STRINGS.UI.CUSTOMIZATIONSCREEN.ICON_TITLES[string.upper(v.name)]
                end
                opt.image:SetTexture(v.atlas or "images/customisation.xml", icon_image)
                opt.image:SetSize(item_height, item_height)
                opt.icon_txt:SetString(icon_txt)

                opt.widetextentry:SetSelected(opt.data.selection)

                opt.widetextentry:SetPrompt(STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(v.name)])

                if data.option.neveredit then
                    opt.widetextentry:SetEditable(false)
                else
                    opt.widetextentry:SetEditable(self.allowEdit or data.option.alwaysedit)
                end
                return unpack(rets)

            elseif v.widget_type == "optionsspinner" then
                return ApplyDataToWidget(context, widget, data, index, ...)
            end
        end
    end
    return _ScrollingGrid(items, opts, ...)
end)


FrontendHelper.ReplaceFunction(CustomizationList, "MakeOptionSpinners", function(_MakeOptionSpinners, self, ...)
    ShouldHackScrollingGrid = true
    customizationlist = self
    options = self.options
    self.options = {}
    local rets = {_MakeOptionSpinners(self, ...)}
    self.options = options
    options = nil
    customizationlist = nil
    ShouldHackScrollingGrid = false
    return unpack(rets)
end)

--HELPER FUNCTIONS
local function GetServerCreationScreen()
    for _, screen_in_stack in pairs(TheFrontEnd.screenstack) do
        if screen_in_stack.name == "ServerCreationScreen" then
            return screen_in_stack
        end
    end
end

local function RefreshWorldTabs()
    local servercreationscreen = GetServerCreationScreen()
    if servercreationscreen then
        for k, v in pairs(servercreationscreen.world_tabs) do
            v:Refresh()
        end
    end
end
RefreshWorldTabs()