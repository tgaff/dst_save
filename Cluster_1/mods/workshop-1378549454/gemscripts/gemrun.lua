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
local env = env
GLOBAL.setfenv(1, GLOBAL)

local gempackage = {
    loaders = {},
    preload = {},
    loaded = {},
    reload = {}
}

table.insert(gempackage.loaders, function(functionname)
    if gempackage.preload[functionname] ~= nil then
        return gempackage.preload[functionname]
    else
        return string.format("\n\tno field gempackage.preload['%s']", functionname)
    end
end)

table.insert(gempackage.loaders, function(functionname)
    local filename = env.MODROOT.."gemscripts/"..functionname..".lua"
    local result = kleiloadlua(filename)
    if type(result) == "string" then
        error(string.format("error loading gemrun module '%s' from file '%s':\n\t%s", functionname, filename, result))
    elseif type(result) == "function" then
        setfenv(result, _G)
    elseif result == nil then
        return "\n\tno file '"..filename.."'"
    end
    return result
end)

function env.gemrun(functionname, ...)
    if gempackage.loaded[functionname] then
        return unpack(gempackage.loaded[functionname])
    end
    local result, errormessageaccumulator, i = nil, "", 1
    while true do
        local loader = gempackage.loaders[i]
        if not loader then
            error(string.format("gemrun function '%s' not found:%s", functionname, errormessageaccumulator))
        end
        result = loader(functionname)
        if type(result) == "function" then
            break
        elseif type(result) == "string" then
            errormessageaccumulator = errormessageaccumulator..result
        end
        i = i + 1
    end
    local modresult = {result(functionname, ...)}
    if not gempackage.reload[functionname] then
        if modresult ~= nil then
            gempackage.loaded[functionname] = modresult
        else
            gempackage.loaded[functionname] = true
        end
    end
    return unpack(modresult)
end

local function MakeGemFunction(functionname, preload, reload)
    gempackage.preload[functionname] = preload
    gempackage.reload[functionname] = reload
    gempackage.loaded[functionname] = nil
end

local function DeleteGemFunction(functionname)
    gempackage.preload[functionname] = function() end
    gempackage.reload[functionname] = false
    gempackage.loaded[functionname] = nil
end

DeleteGemFunction("gemrun")
MakeGemFunction("gemfunctionmanager", function(functionname, ...)
    return MakeGemFunction, DeleteGemFunction
end)