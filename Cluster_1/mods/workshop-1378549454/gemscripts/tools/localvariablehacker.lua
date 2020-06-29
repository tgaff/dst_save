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

local LocalVariableHacker = {} 
function LocalVariableHacker.GetLocalVariable(stacklevel, name)
    stacklevel = stacklevel + 1
    if debug.getinfo(stacklevel, "n") == nil then return nil end
    local i = 1
    while debug.getlocal(stacklevel, i) and debug.getlocal(stacklevel, i) ~= name do
        i = i + 1
    end
    local name, value = debug.getlocal(stacklevel, i)
    stacklevel = stacklevel - 1
    return value, i
end
 
function LocalVariableHacker.SetLocalVariable(stacklevel, name, newval)
    stacklevel = stacklevel + 1
    local _val, _val_i = LocalVariableHacker.GetLocalVariable(stacklevel, name)
    debug.setlocal(stacklevel, _val_i, newval)
    stacklevel = stacklevel - 1
end

return LocalVariableHacker