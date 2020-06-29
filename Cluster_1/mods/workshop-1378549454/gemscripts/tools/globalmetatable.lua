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
local secret = {
    __index = {},
    __newindex = {},
    __blacklist = {},
}

local _rawget = rawget
function rawget(t, n)
    if t == _G and secret.__index[n] then
        local ret = secret.__index[n]
        if type(ret) == "function" then
            return ret(t, n)
        else
            return ret
        end
    end
    return _rawget(t, n)
end

local _rawset = rawset
function rawset(t, n, v)
    if t == _G and secret.__newindex[n] then
        return secret.__newindex[n](t, n, v)
    end
    return _rawset(t, n, v)
end

local function AddGetSet(name, get, set, blacklist)
    assert(not secret.__blacklist[name], "ERROR! can't set blacklisted GetSet!")
    assert(type(name) == "string", "ERROR! name must be a string!")
    assert(secret.__index[name] == nil and secret.__newindex[name] == nil, "ERROR! AddingGetSet for already existing GetSet: "..name..".")
    set = set or function() end
    assert(type(get) == "function", "ERROR! get must be a function!")
    assert(type(set) == "function", "ERROR! set must be a function!")
    secret.__index[name] = get 
    secret.__newindex[name] = set
    secret.__blacklist[name] = blacklist
    global(name)
end

local function RemoveGetSet(name)
    assert(not secret.__blacklist[name], "ERROR! cant remove blacklisted GetSet!")
    secret.__index[name] = nil 
    secret.__newindex[name] = nil
end

return AddGetSet, RemoveGetSet