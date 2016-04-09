-- デフォルト設定
require "lbt-funcs"
require "lbt-template"
local default = {}

-- sort設定
-- default.sorting.formatters["name_format"]
-- default.sorting.targets
-- を上書きで微調整する

local function purify(s) return s:gsub("\\[a-zA-Z]*",""):gsub("[ -/:-@%[-`{-~]","") end
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

function default.sorting.formatters:name_format(c) return "{vv{ } }{ll{ }}{  ff{ }}{  jj{ }}" end

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
		local array = LBibTeX.split_names(s)
		return purify(LBibTeX.make_name_list(array,self:name_format(c),{"     "},"et al"))
	end
end
function default.sorting.formatters:entry_key(c) return c.key end
function default.sorting.formatters:label(c) return c.label end
function default.sorting.formatters:title(c)
	title = c.fields["title"]
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


default.label = {}

default.label.templates = {}
default.label.formatters = {}
default.label.templates["book"] = "$<shorthand|($<author|editor|key|entry_key>$<year>)>"
default.label.templates["inbook"] = default.label.templates["book"]
default.label.templates["proceedings"] = "$<shorthand|($<editor|key|organization|entry_key>$<year>)>"
default.label.templates["manual"] = "$<shorthand|($<author|key|organization|entry_key>$<year>)>"
default.label.templates[""] = "$<shorthand|($<author|key|entry_key>$<year>)>"

local function makelabelfromname(s)
	if s == nil then return nil end
	local a = LBibTeX.split_names(s)
	local label = ""
	if #a > 4 then label = "{\\etalchar{+}}" end
	local n = #a
	for i = 1,n - 5 do table.remove(a) end
	label = LBibTeX.make_name_list(a,"{v{}}{l{}}",{""},"{\\etalchar{+}}") .. label
	if #a > 1 then return label
	else
		if LBibTeX.text_length(label) > 1 then return label
		else return LBibTeX.text_prefix(LBibTeX.format_name(s,"{ll}"),3) end
	end
end

function default.label.formatters:author(c)
	return makelabelfromname(c.fields["author"])
end

function default.label.formatters:editor(c)
	return makelabelfromname(c.fields["editor"])
end

function default.label.formatters:organization(c)
	local s = c.fields["organization"]
	if s ~= nil then return LBibTeX.text_prefix(s:gsub("^The",""),3)
	else return nil end
end

function default.label.formatters:key(c)
	local s = c.fields["key"]
	if s ~= nil then return LBibTeX.text_prefix(s,3) end
end

function default.label.formatters:entry_key(c)
	return LBibTeX.text_prefix(c.key,3)
end

function default.label.formatters:year(c)
	local yearp
	if c.fields["year"] == nil then year = ""
	else year = purify(c.fields["year"]) end
	return year:sub(-2,-1)
end

function default.label:suffix_alphabet(i)
	if i <= 26 then return string.char(string.byte("a") + i - 1)
	else return "" end
end

default.label.suffix = default.label.suffix_alphabet

function default.label:make(c)
	if self.makelabelfunctions == nil then
		local template = LBibTeX.Template.new()
		self.makelabelfunctions = template:make(self.templates,self.formatters)
	end
	local func = self.makelabelfunctions[c.type] or self.makelabelfunctions[""]
	if func ~= nil then return func(c)
	else return nil end
end

function default.label:add_suffix(cites)
	if self.suffix == nil then return cites end
	local changed = false
	local lastname = nil
	local lastindex = 0
	for i = 1,#cites - 1 do
		if purify(cites[i].label) == purify(cites[i + 1].label) then
			lastindex = lastindex + 1
			cites[i].label = cites[i].label .. self:suffix(lastindex)
			changed = true
		else
			if changed then
				lastindex = lastindex + 1
				cites[i].label = cites[i].label .. self:suffix(lastindex)
			end
			lastindex = 0
			changed = false
		end
	end
	if lastindex > 0 then cites[#cites].label = cites[#cites].label .. self:suffix(lastindex + 1) end
	return cites
end

return default
