--[[
Copyright (C) 2018 Zarklord

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

if CurrentRelease.GreaterOrEqualTo("R14_FARMING_REAPWHATYOUSOW") then
	return bit
else
	local bit = {}

	function bit.bor(m, n)
		local out = 0
		local iter = 1
		while iter <= m or iter <= n do
			if ((m % (iter*2)) - (m % iter)) == iter or ((n % (iter*2)) - (n % iter)) == iter then
				out = out + iter
			end
			iter = iter * 2
		end
		return out
	end

	function bit.band(m, n)
		local out = 0
		local iter = 1
		while iter <= m and iter <= n do
			if ((m % (iter*2)) - (m % iter)) == iter and ((n % (iter*2)) - (n % iter)) == iter then
				out = out + iter
			end
			iter = iter * 2
		end
		return out
	end

	function bit.bnot(n, width)
		local out = 0
		local iter = 1
	    width = 2^(width or 0) - 1
		while iter <= n or iter <= width do
			if ((n % (iter*2)) - (n % iter)) == 0 then
				out = out + iter
			end
			iter = iter * 2
		end
		return out
	end

	function bit.xor(m, n)
		local out = 0
		local iter = 1
		while iter <= m or iter <= n do
			if ((m % (iter*2)) - (m % iter)) ~= ((n % (iter*2)) - (n % iter)) then
				out = out + iter
			end
			iter = iter * 2
		end
		return out
	end

	function bit.rshift(n, bits)
		return math.floor(n/(2^bits))
	end

	function bit.lshift(n, bits)
		return n*(2^bits)
	end

	return bit
end