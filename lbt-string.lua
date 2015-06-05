local use_icu = true

if use_icu then
	local icu = {}
	icu.ustring = require "icu.ustring"
	icu.ufile = require "icu.ufile"
	icu.collator = require "icu.collator"
	return icu
end

local icu = {}
icu.ustring = {}
local function UAsFunction(self,x) return x end
setmetatable(icu.ustring,{__call = UAsFunction})
function icu.ustring.encode(s,t) return s end
function icu.ustring.decode(s,t) return s end
icu.ufile = io

icu.collator = {}
function icu.collator.open(s)
	obj = {}
	function obj:strength(s) return end
	function obj:equals(s,t) return s:lower() == t:lower() end
	function obj:lessthan(s,t) return s:lower() < t:lower() end
	return obj
end

return icu


