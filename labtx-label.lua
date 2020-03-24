--[[
ラベル生成用
label = require "labtx-label"

label.new(): オブジェクト生成
  デフォルトの
  obj.templates
  obj.formatters
  obj:suffix
  obj:add_suffix
  などが生成される．
  
label.make_label(bibtex,c)
  bibtex: labtx-coreオブジェクト
  c: Citation
  ラベルを作って戻り値として返す

label.make_all_labels(bibtex)
  bibtex.citesのラベルを全て設定する．

]]

local Template = require "labtx-template"
local Functions = require "labtx-funcs"
local labtxdebug = require "labtx-debug"


local latex_label = {}

local function get_label_formatter(style)
	local template = Template.new(style.blockseparator)
	local label_formatter
	if type(style.label.make) == "function" then
		label_formatter = function(c)
			local l = c.language
			if l == nil or style.languages[l] == nil or style.languages[l].label == nil or style.languages[l].label.make == nil then
				return style.label:make(c)
			else
				if type(style.languages[l].label.make) ~= "function" then return nil,"languages.label.make should be a function when label.make is a function" end
				return style.languages[l].label:make(c)
			end
		end
	else
		local default_label_field_formatters = template:modify_formatters(style.label.formatters)
		local lang_label_field_formatters = {}
		for langname,lang in pairs(style.languages) do
			if lang.label ~= nil and lang.label.formatters ~= nil then
				lang_label_field_formatters[langname] = template:modify_formatters(lang.label.formatters)
			end
		end
		local label_field_formatters = {}
		for key,val in pairs(default_label_field_formatters) do
			label_field_formatters[key] = function(obj,c)
				local l = c.language
				if l == nil or lang_label_field_formatters[l] == nil or lang_label_field_formatters[l][key] == nil then
					return default_label_field_formatters[key](default_label_field_formatters,c)
				else
					return lang_label_field_formatters[l][key](lang_label_field_formatters[l],c)
				end
			end
		end
		
		local default_label_formatters = {}
		local lang_label_formatters = {}
		for key,val in pairs(style.label.templates) do
			local f,msg
			if type(val) == "string" then
				f,msg = template:make(val,label_field_formatters)
				if f == nil then return nil,msg .. " in label.templates" end
				default_label_formatters[key] = f
			else
				default_label_formatters[key] = val
			end
			for langname,lang in pairs(style.languages) do
				if lang.label ~= nil and lang.label.templates ~= nil and lang.label.templates[key] ~= nil then
					lang_label_formatters[key] = {}
					if type(lang.label.templates[key]) == "string" then
						f,msg = template:make(lang.label.template[key],lang_field_formatters)
						if f == nil then return nil,msg .. " in label.templates" end
						lang_label_formatters[key][langname] = f
					end
				end
			end
			local label_formatter_sub = function(ctype,lang)
				if lang_label_formatters[ctype] == nil or lang == nil or lang_label_formatters[cype][lang] == nil then
					return default_label_formatters[ctype]
				else
					return lang_label_formatters[ctype][lang]
				end
			end
			label_formatter = function(c)
				local l = c.language
				local f = label_formatter_sub(c.type,l)
				if f == nil then
					f = label_formatter_sub("",l)
					if f == nil then return nil,"Cannot generate label for the type " .. c.type end
				end
				return f(c)
			end
		end
	end
	return label_formatter
end

-- いちいちラベル用関数を作るので効率が悪い
function latex_label.make_label(bibtex,c)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(bibtex.label,"BibTeX.label","table")
		labtxdebug.typecheck(bibtex.label.make,"BibTeX.label.make",{"function","boolean"},true)
	end
	if bibtex.label.make ~= nil and bibtex.label.make ~= false then
		local label_formatter = get_label_formatter(bibtex)
		return label_formatter(c)
	else return nil end
end

function latex_label.make_all_labels(style,cites)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(style.label,"label","table")
		labtxdebug.typecheck(style.label.make,"label.make",{"function","boolean"},true)
	end
	if style.label.make ~= nil and style.label.make ~= false then
		local label_formatter,msg = get_label_formatter(style)
		if label_formatter == nil then return nil,msg end
		for i = 1,#cites do
			cites[i].label = label_formatter(cites[i])
			if cites[i].label == nil then
				bibtex:warning("cannot generate the label of " .. cites[i].key)
			end
		end
		if style.label.add_suffix ~= nil then
			cites = style.label:add_suffix(cites)
		end
	end
	return cites
end


function latex_label.new()
	local obj = {}
	local function purify(s) return s:gsub("\\[a-zA-Z]*",""):gsub("[ -/:-@%[-`{-~]","") end

	obj = {}

	obj.templates = {}
	obj.formatters = {}
	obj.templates["book"] = "$<shorthand|($<author|editor|key|entry_key>$<year>)>"
	obj.templates["inbook"] = obj.templates["book"]
	obj.templates["proceedings"] = "$<shorthand|($<editor|key|organization|entry_key>$<year>)>"
	obj.templates["manual"] = "$<shorthand|($<author|key|organization|entry_key>$<year>)>"
	obj.templates[""] = "$<shorthand|($<author|key|entry_key>$<year>)>"

	local function makelabelfromname(s)
		if s == nil then return nil end
		local a = Functions.split_names(s)
		local label = ""
		if #a > 4 then label = "{\\etalchar{+}}" end
		local n = #a
		for dummy = 1,n - 5 do table.remove(a) end
		label = Functions.make_name_list(a,"{v{}}{l{}}",{""},"{\\etalchar{+}}") .. label
		if #a > 1 then return label
		else
			if Functions.text_length(label) > 1 then return label
			else return Functions.text_prefix(Functions.format_name(s,"{ll}"),3) end
		end
	end

	function obj.formatters:author(c)
		return makelabelfromname(c.fields["author"])
	end

	function obj.formatters:editor(c)
		return makelabelfromname(c.fields["editor"])
	end

	function obj.formatters:organization(c)
		local s = c.fields["organization"]
		if s ~= nil then return Functions.text_prefix(s:gsub("^The",""),3)
		else return nil end
	end

	function obj.formatters:key(c)
		local s = c.fields["key"]
		if s ~= nil then return Functions.text_prefix(s,3) end
	end

	function obj.formatters:entry_key(c)
		return Functions.text_prefix(c.key,3)
	end

	function obj.formatters:year(c)
		local year
		if c.fields["year"] == nil then year = ""
		else year = purify(c.fields["year"]) end
		return year:sub(-2,-1)
	end

	function obj:suffix_alphabet(i)
		if i <= 26 then return string.char(string.byte("a") + i - 1)
		else return "" end
	end

	obj.suffix = obj.suffix_alphabet

	obj.make = true

	function obj:add_suffix(cites)
		if self.suffix == nil then return cites end
		local changed = false
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
	
	return obj
end

return latex_label
