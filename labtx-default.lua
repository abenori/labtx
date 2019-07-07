-- デフォルト設定
local Functions = require "labtx-funcs"
local Template = require "labtx-template"
local default = {}

local function purify(s) return s:gsub("\\[a-zA-Z]*",""):gsub("[ -/:-@%[-`{-~]","") end

-- sort設定
-- default.sorting.formatters["name_format"]
-- default.sorting.targets
-- を上書きで微調整する

default.sorting = {}
default.sorting.lessthan = function(a,b) return unicode.utf8.lower(purify(a)) < unicode.utf8.lower(purify(b)) end
default.sorting.equal = function(a,b) return unicode.utf8.lower(purify(a)) == unicode.utf8.lower(purify(b)) end
default.sorting.formatters = {}
local function remove_article(s)
	if s:sub(1,4) == "The " then s = s:sub(5)
	elseif s:sub(1,3) == "An " then s = s:sub(4)
	elseif s:sub(1,2) == "A " then  s = s:sub(3)
	end
	return s
end

function default.sorting.formatters:name_format(dummy) return "{vv{ } }{ll{ }}{  ff{ }}{  jj{ }}" end

function default.sorting.formatters:name(c)
	local s
	if c.type == "book" or c.type == "inbook" then s = c.fields["author"] or c.fields["editor"]
	elseif c.type == "proceedings" then s = c.fields["editor"]
	else s = c.fields["author"]
	end
	if s == nil then
		if c.type == "proceedings" or c.type == "manual" then
			s =  c.fields["organization"] or c.fields["key"]
		else s = c.fields["key"] end
		if s ~= nil then return purify(remove_article(s))
		else return nil end
	else
		local array = Functions.split_names(s)
		return purify(Functions.make_name_list(array,self:name_format(c),{"     "},"et al"))
	end
end
function default.sorting.formatters:entry_key(c) return c.key end

function default.sorting.formatters:title(c)
	local title = c.fields["title"]
	if title ~= nil then return remove_article(title) end
	return nil	
end
function default.sorting.formatters:number(c) return c.number end

default.sorting.targets = {}
--biblatex
-- datelabel = year
-- labelalpha = false
-- maxalphanames = 3
-- minalphanames = 1


return default
