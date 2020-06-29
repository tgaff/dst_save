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
local args = {...}
local modulename = args[1]
local modname = args[2]
assert(KnownModIndex:DoesModExistAnyVersion(modname), "modname "..modname.." must refer to a valid mod!")

global("GemFrontendReplacedFunctions")
global("GemFrontendDoOnce")
global("GemFrontendDoOnceUID")

GemFrontendReplacedFunctions = GemFrontendReplacedFunctions or {}
GemFrontendReplacedFunctions[modname] = GemFrontendReplacedFunctions[modname] or setmetatable({}, {__mode = "k"})

GemFrontendDoOnce = GemFrontendDoOnce or {}
GemFrontendDoOnce[modname] = GemFrontendDoOnce[modname] or setmetatable({}, {__mode = "k"})

GemFrontendDoOnceUID = GemFrontendDoOnceUID or {}
GemFrontendDoOnceUID[modname] = GemFrontendDoOnceUID[modname] or setmetatable({}, {__mode = "k"})

local MakeGemFunction = gemrun("gemfunctionmanager")
MakeGemFunction(modulename, nil, true)

local function IsModLoaded(_modname)
    return KnownModIndex:IsModEnabled(_modname) or KnownModIndex:IsModForceEnabled(_modname)
end

local FrontendHelper = {}

function FrontendHelper.ReplaceFunction(tbl, replace, patchfn)
    if GemFrontendReplacedFunctions[modname][tbl] == nil or not GemFrontendReplacedFunctions[modname][tbl][replace] then
        local _fn = tbl[replace]
        tbl[replace] = function(...)
            if IsModLoaded(modname) then
                return patchfn(_fn, ...)
            else
                return _fn(...)
            end
        end
        GemFrontendReplacedFunctions[modname][tbl] = GemFrontendReplacedFunctions[modname][tbl] or {}
        GemFrontendReplacedFunctions[modname][tbl][replace] = true
    end
end

function FrontendHelper.DoOnce(fn, ...)
    local info = debug.getinfo(2, "Sl")
    local checkstr = info.short_src..info.currentline
    if not GemFrontendDoOnce[modname][checkstr] then
        fn(...)
        GemFrontendDoOnce[modname][checkstr] = true
    end
end

function FrontendHelper.DoOnceUID(UID, fn, ...)
    if not GemFrontendDoOnceUID[modname][UID] then
        fn(...)
        GemFrontendDoOnceUID[modname][UID] = true
    end
end

return FrontendHelper