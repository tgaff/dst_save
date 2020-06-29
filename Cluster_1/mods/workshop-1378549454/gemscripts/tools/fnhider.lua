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

local MakeGemFunction, DeleteGemFunction = gemrun("gemfunctionmanager")

local hiddenfns = {}

local function hidefn(functionname, fn_to_hide, real_fn)
    hiddenfns[fn_to_hide] = real_fn
end

local _debug_getinfo = debug.getinfo
function debug.getinfo(...)
    local args = {...}
    local fnidx = (#args == 3 or (#args == 2 and type(args[2]) ~= "string")) and 2 or 1
    local fn = args[fnidx]
    if type(fn) ~= "function" then
        local stack_count, current, traversed = fn + 1, 2, 1
        if fn > 0 then
            --jump over this function replacement.
            fn = fn + 1
        end
        while traversed < stack_count do
            if hiddenfns[(_debug_getinfo(current, "f") or {}).func] then
                fn = fn + 1
            else
                traversed = traversed + 1
            end
            current = current + 1
        end
        args[fnidx] = fn
    else
        args[fnidx] = hiddenfns[fn] or fn
    end
    return _debug_getinfo(unpack(args))
end

local _debug_getupvalue = debug.getupvalue
function debug.getupvalue(fn, ...)
    return _debug_getupvalue(hiddenfns[fn] or fn, ...)
end

local _debug_setupvalue = debug.setupvalue
function debug.setupvalue(fn, ...)
    return _debug_setupvalue(hiddenfns[fn] or fn, ...)
end

local _debug_getlocal = debug.getlocal
function debug.getlocal(...)
    local args = {...}
    local fnidx = #args == 3 and 2 or 1
    local fn = args[fnidx]
    if type(fn) ~= "function" then
        local stack_count, current, traversed = fn + 1, 2, 1
        if fn > 0 then
            --jump over this function replacement.
            fn = fn + 1
        end
        while traversed < stack_count do
            if hiddenfns[(_debug_getinfo(current, "f") or {}).func] then
                fn = fn + 1
            else
                traversed = traversed + 1
            end
            current = current + 1
        end
        args[fnidx] = fn
    else
        args[fnidx] = hiddenfns[fn] or fn
    end
    return _debug_getlocal(unpack(args))
end

local _debug_setlocal = debug.setlocal
function debug.setlocal(...)
    local args = {...}
    local fnidx = #args == 4 and 2 or 1
    local fn = args[fnidx]
    if type(fn) ~= "function" then
        local stack_count, current, traversed = fn + 1, 2, 1
        if fn > 0 then
            --jump over this function replacement.
            fn = fn + 1
        end
        while traversed < stack_count do
            if hiddenfns[(_debug_getinfo(current, "f") or {}).func] then
                fn = fn + 1
            else
                traversed = traversed + 1
            end
            current = current + 1
        end
        args[fnidx] = fn
    else
        args[fnidx] = hiddenfns[fn] or fn
    end
    return _debug_setlocal(unpack(args))
end

local _debug_getfenv = debug.getfenv
function debug.getfenv(fn, ...)
    return _debug_getfenv(hiddenfns[fn] or fn, ...)
end

local _debug_setfenv = debug.setfenv
function debug.setfenv(fn, ...)
    return _debug_setfenv(hiddenfns[fn] or fn, ...)
end

local _getfenv = getfenv
function getfenv(fn, ...)
    if fn == nil then
        fn = 2
    elseif type(fn) ~= "function" then
        local stack_count, current, traversed = fn + 1, 2, 1
        if fn > 0 then
            --jump over this function replacement.
            fn = fn + 1
        end
        while traversed < stack_count do
            if hiddenfns[(_debug_getinfo(current, "f") or {}).func] then
                fn = fn + 1
            else
                traversed = traversed + 1
            end
            current = current + 1
        end
    else
        fn = hiddenfns[fn] or fn
    end
    return _getfenv(fn, ...)
end

local _setfenv = setfenv
function setfenv(fn, ...)
    if type(fn) ~= "function" then
        local stack_count, current, traversed = fn + 1, 2, 1
        if fn > 0 then
            --jump over this function replacement.
            fn = fn + 1
        end
        while traversed < stack_count do
            if hiddenfns[(_debug_getinfo(current, "f") or {}).func] then
                fn = fn + 1
            else
                traversed = traversed + 1
            end
            current = current + 1
        end
    else
        fn = hiddenfns[fn] or fn
    end
    return _setfenv(fn, ...)
end

MakeGemFunction("hidefn", hidefn, true)

gemrun("hidefn", hidefn, function() end)
gemrun("hidefn", debug.getinfo, _debug_getinfo)
gemrun("hidefn", debug.getupvalue, _debug_getupvalue)
gemrun("hidefn", debug.setupvalue, _debug_setupvalue)
gemrun("hidefn", debug.getlocal, _debug_getlocal)
gemrun("hidefn", debug.setlocal, _debug_setlocal)
gemrun("hidefn", debug.getfenv, _debug_getfenv)
gemrun("hidefn", debug.setfenv, _debug_setfenv)
gemrun("hidefn", getfenv, _getfenv)
gemrun("hidefn", setfenv, _setfenv)