--[[
Copyright (C) 2019, 2020 Zarklord

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

--Global Pause Patches
if not TheNet:IsDedicated() then
    --This patch properly "pauses" sound
    local Mixer = require("mixer")

    function Mixer.Mixer:DeleteMix(mixname)
        local top = self.stack[1]
        for k, v in ipairs(self.stack) do
            if mixname == v.name then
                table.remove(self.stack, k)
                if top ~= self.stack[1] then
                    self.stack[1]:Apply()
                end
                break
            end
        end
    end

    local amb = "set_ambience/ambience"
    local cloud = "set_ambience/cloud"
    local music = "set_music/soundtrack"
    local voice = "set_sfx/voice"
    local movement ="set_sfx/movement"
    local creature ="set_sfx/creature"
    local player ="set_sfx/player"
    local HUD ="set_sfx/HUD"
    local sfx ="set_sfx/sfx"
    local slurp ="set_sfx/everything_else_muted"

    TheMixer:AddNewMix("globalpause", 0, 2147483647,
    {
        [amb] = 0,
        [cloud] = 0,
        [music] = 0,
        [voice] = 0,
        [movement] = 0,
        [creature] = 0,
        [player] = 0,
        [HUD] = 1,
        [sfx] = 0,
        [slurp] = 0,
    })

    GEMENV.AddComponentPostInit("globalpause", function(self)
        self.inst:ListenForEvent("pausestatedirty", function(net_world)
            --i am fairly certain no explosions will go off from checking TheWorld.ispaused, since the OnPauseStateDirty function runs first right?
            if TheWorld.ispaused then
                TheMixer:PushMix("globalpause")
            else
                TheMixer:DeleteMix("globalpause")
            end
        end)
    end)
end

if TheNet:GetIsServer() then
    --this patch makes pausing work properly when c_spawned() characters exist.
    GEMENV.AddComponentPostInit("globalpause", function(self)
        local inst = self.inst
        local _ReportPaused = inst.event_listening["ms_reportpaused"][TheWorld][1]
        UpvalueHacker.SetUpvalue(_ReportPaused, function()
            --this table gets reset all the time, so grab the upvalue right before checking it
            local _pausedlist = UpvalueHacker.GetUpvalue(_ReportPaused, "_pausedlist")
            for i, v in ipairs(AllPlayers) do
                if v.userid ~= "" and not _pausedlist[v] then
                    return false
                end
            end
            return true
        end, "AllPlayersPaused")
    end)
end

--this patch fixes the game not unpausing when using a controller sometimes.
if TheNet:GetIsServerAdmin() then
    local autopaused = false

    local function GetPlayerCount()
        local ClientObjs = TheNet:GetClientTable()
        if ClientObjs == nil then
            return #{}
        elseif TheNet:GetServerIsClientHosted() then
            return #ClientObjs
        end

        --remove dedicate host from player list
        for i, v in ipairs(ClientObjs) do
            if v.performance ~= nil then
                table.remove(ClientObjs, i)
                break
            end
        end
        return #ClientObjs
    end

    local MapScreen = require("screens/mapscreen")

    local _MapScreen_OnBecomeActive = MapScreen.OnBecomeActive
    function MapScreen:OnBecomeActive(...)
        if rawget(_G, "GLOBALPAUSE") and GLOBALPAUSE.AUTOPAUSEENABLED and GLOBALPAUSE.AUTOPAUSEMAP and GetPlayerCount() == 1 then
            if not TheWorld.ispaused then
                TheWorld:SetPause(true)
                autopaused = true
            end
        end
        return _MapScreen_OnBecomeActive(self, ...)
    end

    local _MapScreen_OnBecomeInactive = MapScreen.OnBecomeInactive
    function MapScreen:OnBecomeInactive(...)
        if autopaused then
            TheWorld:SetPause(false)
        end
        autopaused = false
        return _MapScreen_OnBecomeInactive(self, ...)
    end

    local ConsoleScreen = require("screens/consolescreen")

    local _ConsoleScreen_OnBecomeActive = ConsoleScreen.OnBecomeActive
    function ConsoleScreen:OnBecomeActive(...)
        if rawget(_G, "GLOBALPAUSE") and GLOBALPAUSE.AUTOPAUSEENABLED and GLOBALPAUSE.AUTOPAUSECONSOLE and GetPlayerCount() == 1 then
            if not TheWorld.ispaused then
                TheWorld:SetPause(true)
                autopaused = true
            end
        end
        return _ConsoleScreen_OnBecomeActive(self, ...)
    end

    local _ConsoleScreen_OnBecomeInactive = ConsoleScreen.OnBecomeInactive
    function ConsoleScreen:OnBecomeInactive(...)
        if autopaused then
            TheWorld:SetPause(false)
        end
        autopaused = false
        return _ConsoleScreen_OnBecomeInactive(self, ...)
    end
end