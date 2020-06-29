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

local ENCODING = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local BinaryPosition = Class(function(self, position, binarydata)
    self.position = position or 0
    self.binarydata = binarydata

    function self:ReadByte()
        local bytegroupindex, byteindex = math.floor(self.position / 4) + 1, math.abs(self.position % 4 - 3)
        if not self.binarydata[bytegroupindex] then
            return nil
        end
        return bit.band(0xFF, bit.rshift(self.binarydata[bytegroupindex], byteindex * 8))
    end

    function self:WriteByte(byte)
        local bytegroupindex, byteindex = math.floor(self.position / 4) + 1, math.abs(self.position % 4 - 3)
        self.binarydata[bytegroupindex] = bit.bor(bit.band(self.binarydata[bytegroupindex] or 0, bit.bnot(bit.lshift(0xFF, byteindex * 8), 32)), bit.lshift(bit.band(0xFF, byte), byteindex * 8))
    end
end)

function BinaryPosition:__add(rhs)
    self.position = self.position + rhs
    return self
end

function BinaryPosition:__sub(rhs)
    self.position = self.position + rhs
    return self
end

function BinaryPosition:__tostring()
    return "(position: "..self.position..", bytegroupindex: .."..(math.floor(self.position / 4) + 1)..", byteindex: "..math.abs(self.position % 4 - 3)..")"
end

local BinaryString = Class(function(self, binarypackedstring, debugoutput)
    local binarydata
    local position = BinaryPosition(nil, binarydata)
    local size

    function self:SetString(binarypackedstring)
        assert(type(binarypackedstring) == "string", "BinaryString:SetString must be passed a binary packed string")
        binarydata = {}
        position = BinaryPosition(0, binarydata)

        --Zarklord: if you need to understand what im doing here, contact me on discord @ Zarklord#1337
        --The reason this is so compact, is that we need really fast String <-> Numbers since these tile map's are huge
        local function GetValuesFromString(vals)
            local value = (string.find(ENCODING, string.sub(vals, 1, 1)) - 1)*0x40000 +
            (string.find(ENCODING, string.sub(vals, 2, 2)) - 1)*0x1000 +
            ((string.find(ENCODING, string.sub(vals, 3, 3)) - 1) or 0)*0x40 +
            (string.find(ENCODING, string.sub(vals, 4, 4)) - 1) or 0
            return (value - (value % 0x10000)) / 0x10000, ((value - (value % 0x100)) / 0x100) % 0x100, value % 0x100
        end

        string.gsub(binarypackedstring, "([%w+/][%w+/][%w+/=][%w+/=])", function(match)
            local match = string.sub(match, 1, (string.find(match, "=") or 5) - 1)
            local bytes = {GetValuesFromString(match)}
            for i, byte in pairs((#match == 4 and bytes) or (#match == 2 and {bytes[1]}) or ({bytes[1], bytes[2]})) do
                position:WriteByte(byte)
                position = position + 1
            end
            return match
        end)
        size = position.position - 1
        position.position = 0
    end

    function self:GetAsString()
        local function CreateStringFromValues(val1, val2, val3)
            local value = val1*0x10000 + (val2 or 0)*0x100 + (val3 or 0)
            local encode1 = (value - (value % 0x40000))/0x40000 + 1
            local encode2 = ((value - (value % 0x1000))/0x1000 % 0x40) + 1
            local encode3 = ((value - (value % 0x40))/0x40 % 0x40) + 1
            local encode4 = (value % 0x40) + 1
            return string.sub(ENCODING, encode1, encode1)..
                string.sub(ENCODING, encode2, encode2)..
                string.sub(ENCODING, encode3, encode3)..
                string.sub(ENCODING, encode4, encode4)
        end

        local writepos = BinaryPosition(0, binarydata)
        local strs = {}
        local vals = {}
        while writepos.position < size do
            table.insert(vals, writepos:ReadByte())
            writepos = writepos + 1
            if #vals == 3 then
                table.insert(strs, CreateStringFromValues(unpack(vals)))
                vals = {}
            end
        end
        if #vals ~= 0 then
            table.insert(strs, string.sub(CreateStringFromValues(vals[1], vals[2] or 0, 0), 1, (#vals == 1 and 2) or (3))..((#vals == 1 and "==") or ("=")))
        end
        return table.concat(strs)
    end

    local function TableReadBytes(count, pos, updateposition)
        local _position = pos.position
        local value = {}

        for i = 1, count do
            local byte = pos:ReadByte()
            if not byte then break end
            table.insert(value, byte)
            pos = pos + 1
        end
        pos.position = _position

        if updateposition ~= false then
            pos = pos + count
        end

        return value
    end

    local function ValueReadBytes(count, signed, pos, updateposition)
        local value

        for i, byte in ipairs(TableReadBytes(count, pos, updateposition)) do
            value = (value or 0) + bit.lshift(byte, (i - 1) * 8)
        end

        if signed and value and bit.rshift(value, count * 8 - 1) == 1 then
            value = -bit.bnot(value, count * 8) - 1
        end

        return value
    end

    local function TableWriteBytes(value, pos, updateposition)
        local _position = pos.position
        for i, byte in ipairs(value) do
            pos:WriteByte(byte)
            pos = pos + 1
        end

        if pos.position > size then
            size = pos.position
        end

        if updateposition == false then
            pos.position = _position
        end
    end

    local function ValueWriteBytes(count, value, pos, updateposition)
        if type(value) == "number" then
            if value < 0 then
                value = bit.bnot(-value + 1, count * 8)
            end
            local _value = {}
            for i = count, 1, -1 do
                table.insert(_value, bit.band(0xFF, value))
                value = bit.lshift(value, 8)
            end
            value = _value
        end
        TableWriteBytes(value, pos, updateposition)
    end

    function self:ReadByte(signed)
        return ValueReadBytes(1, signed, position)
    end

    function self:ReadShort(signed)
        return ValueReadBytes(2, signed, position)
    end

    function self:ReadInt(signed)
        return ValueReadBytes(4, signed, position)
    end

    function self:ReadLong(signed)
        return ValueReadBytes(8, signed, position)
    end

    function self:WriteByte(byte)
        ValueWriteBytes(1, byte, position)
    end

    function self:WriteShort(short)
        ValueWriteBytes(2, short, position)
    end

    function self:WriteInt(int)
        ValueWriteBytes(4, int, position)
    end

    function self:WriteLong(long)
        ValueWriteBytes(8, long, position)
    end

    function self:CopyTo(dest, start, length, deststart)
        dest:DirectWrite(TableReadBytes(length, BinaryPosition(start, binarydata), false), deststart)
    end

    function self:DirectWrite(values, start)
        position.position = start or position.position
        TableWriteBytes(values, position)
    end

    function self:Fill(values, amount, start)
        position.position = start or position.position
        for j = 1, amount do
            TableWriteBytes(values, position)
        end
    end

    function self:Loop(start, startlimit, endlimit, step, readsize, fn)
        local current = BinaryPosition(start or 0, binarydata)
        startlimit = math.max(startlimit or 0, 0)
        endlimit = math.min(endlimit or size, size)
        step = step or 1
        readsize = readsize or 1

        return coroutine.wrap(function()
            while startlimit <= current.position and current.position <= endlimit do
                local values = TableReadBytes(readsize, current, false)
                table.insert(values, function(...)
                    local writevals = {...}
                    assert(#writevals <= #values - 1, "BinaryString:Loop writing more write values than read values is not allowed!")
                    TableWriteBytes(writevals, current, false)
                end)
                coroutine.yield(unpack(values))
                current = current + 1
            end
        end)
    end

    function self:Seek(pos, seektype)
        if seektype == self.SeekType.Begin then
            position.position = pos
        elseif seektype == self.SeekType.Current or seektype == nil then
            position = position + pos
        elseif seektype == self.SeekType.End then
            position.position = size + pos
        end
    end

    function self:Tell()
        return position.position
    end

    function self:Size()
        return size
    end

    --[[
    self:SetString("")

    print(self:Size())
    self:WriteInt(0x82323212)
    self:Seek(0, self.SeekType.Begin)
    print(self:Size())

    self:Seek(0, self.SeekType.Begin)

    print(self:ReadInt())
    self:Seek(0, self.SeekType.Begin)
    print(self:ReadInt(true))
    assert(false)
    --]]
    self:SetString(binarypackedstring or "")

    if debugoutput then
        local f = assert(io.open(MODS_ROOT.."GemCore/"..debugoutput..".txt", "w"))

        local writepos = BinaryPosition(0, binarydata)
        while writepos.position < size do
            f:write(string.format("%02X ", writepos:ReadByte()))
            writepos = writepos + 1
        end
        f:close()
    end
    --assert(false)
end)

BinaryString.SeekType = {
    Begin = 1,
    Current = 2,
    End = 3,
}

function BinaryString:__iterator(...)
    return self:Loop(...)
end

return BinaryString