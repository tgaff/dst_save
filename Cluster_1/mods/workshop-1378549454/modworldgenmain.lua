--[[
Copyright (C) 2018, 2019 Zarklord

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
if CurrentRelease.GreaterOrEqualTo("R15_QOL_WORLDSETTINGS") then
	local _G = GLOBAL
	local require = _G.require

	_G.GEMENV = env

	if not (_G.rawget(_G, "TheFrontEnd") and _G.rawget(_G, "IsInFrontEnd") and _G.IsInFrontEnd()) then
	    require("backendmainloader")
	end
else
	local _G = GLOBAL
	local require = _G.require

	_G.GEMENV = env

	if _G.rawget(_G, "TheFrontEnd") and _G.rawget(_G, "IsInFrontEnd") and _G.IsInFrontEnd() then
	    local stacklevel = 2
	    local info = _G.debug.getinfo(stacklevel, "n")
	    _G.IsSaveSlotLoading = false
	    while info ~= nil do
	        if info.name == "SetSaveSlot" then
	            _G.IsSaveSlotLoading = true
	            break
	        elseif info.name == "OnConfirmEnable" then
	            _G.IsSaveSlotLoading = false
	            break
	        end
	        stacklevel = stacklevel + 1
	        info = _G.debug.getinfo(stacklevel, "n")
	    end
	    print("IsSaveSlotLoading", _G.IsSaveSlotLoading)

	    require("frontendmainloader")
	else
	    require("backendmainloader")
	end

	_G.IsSaveSlotLoading = nil
end