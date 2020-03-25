local Core = {}

local labtxdebug = require "labtx-debug"

local BibDatabase = require "labtx-bibdb"
local CrossReference = require "labtx-crossref"
local Template = require "labtx-template"
local Functions = require "labtx-funcs"
local Label = require "labtx-label"

local lpeg = require "lpeg"

-- bblを表す構造
-- Core.aux, Core.style, Core.cites, Core.bibs, Core.bbl (stream)

local labtx_default = require "labtx-default"

local stderr = io.stderr
local stdout = io.stdout
local exit = os.exit

local function find(array,key)
	for i,k in ipairs(array) do
		if k == key then return i end
	end
	return nil
end

function Core.new(doctype)
	local obj = {}
	obj.database = BibDatabase.new()
	-- obj.databaseに回すキー名
	local inherit_table_keys = {"preamble","key","db","macros"}
	-- 以下アウトプット用設定
	obj.doctype = doctype
	obj.modify_citations = nil
	obj.warning_count = 0
	obj.default_style = {
		languages = {},
		crossref = CrossReference.new(),
		blockseparator = {},
		templates = {},
		formatters = {},
		label = Label.new(),
		sorting = {
			formatters = labtx_default.sorting.formatters,
			lessthan = labtx_default.sorting.lessthan,
			equal = labtx_default.sorting.equal,
			targets = labtx_default.sorting.targets
		},
		modify_citations = nil,
		macros = {},
		preamble = "",
	}
	obj.default_style.crossref.templates = {}
	function obj.default_style.sorting.formatters:label(c)
		local y = c.fields["year"]
		c.fields["year"] = nil
		local rv = Label.make_label(obj.default_style,c)
		c.fields["year"] = y
		return rv
	end
	local rv = setmetatable(obj,{
	__index = 
		function(table,key)
			if find(inherit_table_keys,key) ~= nil then return table.database[key]
			else return Core[key] end
		end,
	__newindex = 
		function(table,key,value)
			if find(inherit_table_keys,key) ~= nil then table.database[key] = value
			else Core[key] = value end
		end
	})
	doctype.init(rv)
	return rv
end

local function clone_table(t)
	local r = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			r[k] = clone_table(v)
		else
			r[k] = v
		end
	end
	local meta = getmetatable(t)
	if meta then setmetatable(r,meta) end
	return r
end

function Core:get_default_style()
	return clone_table(self.default_style)
end

function Core:set_default_style(st)
	self.default_style = clone_table(st)
end

function Core:load_aux(file)
	local aux,msg = self.doctype.load_aux(self,file)
	if aux == nil then return false,msg end
	self.bbl,msg = io.open(aux.out,"w")
	if self.bbl == nil then return false,msg end
	self.blg,msg = io.open(aux.log,"w")
	if self.blg == nil then return false,msg end
	self.aux_file = aux.file
	self.style_name = aux.style
	self.cites = aux.cites
	self.bibs = aux.db
	self.type_data = aux.type_data
	return true
end


local function get_language(style,c)
	for key,val in pairs(style.languages) do
		if val.is ~= nil then
			if val.is(c) == true then return key end
		else
			if c.fields["langid"] == key then return key end
		end
	end
	return nil
end


function Core:read_db()
	for i = 1,#self.bibs do
		local bibfile = kpse.find_file(self.bibs[i],"bib")
		if bibfile == nil then 
			return false,"Cannot find Database file " .. self.bibs[i]
		end
		local b,m = self.database:read(bibfile)
		if b == false then
			return false,m .. " in Databse " .. self.bibs[i]
		else
			self:message("Database file #" .. tostring(i) .. ": " .. self.bibs[i])
			for _,msg in ipairs(m) do
				self:warning(msg .. " in " .. self.bibs[i] .. ", ignored")
			end
		end
	end
	if self.cites == nil then
		-- \cite{*}
		self.cites = {}
		for _,v in pairs(self.database.db) do
			self.cites[#self.cites + 1] = v
		end
	else
		local n = #self.cites
		local i = 1
		while i <= n do
			local k = self.cites[i].key
			if self.database.db[k] == nil then
				self:warning("I don't find a database entry for \"" .. k .. "\"")
				table.remove(self.cites,i)
				i = i - 1
				n = n - 1
			else
				self.cites[i] = self.database.db[k]
			end
			i = i + 1
		end
	end
	return true
end

function Core:dispose()
	if self.warning_count == 1 then self:message("(There was a warning.)")
	elseif self.warning_count > 0 then self:message("(There were " .. tostring(self.warning_count) .. " warnings.)")
	end
	if self.bbl ~= nil then self.bbl:close() self.bbl = nil end
	if self.blg ~= nil then self.blg:close() self.blg = nil end
end


function Core:output(s)
	self.bbl:write(s)
end

function Core:outputline(s)
	self.bbl:write(s .. "\n")
end

local function trim(str)
--	return str:gsub("^[ \n\t]*(.-)[ \n\t]*$","%1")
	return str:gsub("^[ \n\t]*",""):gsub("[ \n\t]*$","")
end

local function get_sorting_formatter(formatters,target)
	return formatters[target] or formatters[""]
end

local function generate_sortfunction(targets,formatters,equal,lessthan)
	return function(lhs,rhs)
		for _,target in ipairs(targets) do
			local l = get_sorting_formatter(formatters,target)
			if l == nil then l = lhs.fields[target]
			else l = l(formatters,lhs) end
			if l == nil then goto continue end
			local r = get_sorting_formatter(formatters,target)
			if r == nil then r = rhs.fields[target]
			else r = r(formatters,rhs) end
			if r ~= nil then
				if equal(l,r) == false then
					if labtxdebug.debugmode == true then
						print("for comparing " .. lhs.key .. " and " .. rhs.key .. ", " .. target .. " is used, the values are:")
						print(l)
						print(r)
					end
					return lessthan(l,r)
				else
				end
			end
			::continue::
		end
--		print(lhs.key .. " and " .. rhs.key .. " are not distinguished.")
		return false
	end
end

function Core:get_item_formatter(style)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(style.blockseparator,"style.blockseparator","table")
		labtxdebug.typecheck(style.templates,"style.templates","table")
		labtxdebug.typecheck(style.formatters,"style.formatters","table")
		labtxdebug.typecheck(style.crossref,"style.crossref","table")
		labtxdebug.typecheck(style.crossref.templates,"style.crossref.templates","table")
	end
	
	-- formatter生成
	local template = Template.new(style.blockseparator)
	-- 各フィールドを整形する関数を用意．
	local default_field_formatters = template:modify_formatters(style.formatters)
	local lang_field_formatters = {}
	for langname,lang in pairs(style.languages) do
		if lang.formatters ~= nil then
			lang_field_formatters[langname] = template:modify_formatters(lang.formatters)
		end
	end
	local field_formatters = {}
	for key,val in pairs(default_field_formatters) do
		field_formatters[key] = function(obj,c)
			local l = get_language(style,c)
			if l == nil or lang_field_formatters[l] == nil or lang_field_formatters[l][key] == nil then
				return default_field_formatters[key](default_field_formatters,c)
			else
				return lang_field_formatters[l][key](lang_field_formatters[l],c)
			end
		end
	end
	-- 整形関数用意
	local default_entry_formatters = {} -- 整形関数のテーブルを入れる
	local lang_entry_formatters = {} -- 言語ごとの整形関数のテーブルを入れる．
	for key,val in pairs(style.templates) do
		local f,msg
		if type(val) == "string" then
			f,msg = template:make(val,field_formatters)
			if f == nil then self:error(msg,1) return end
			default_entry_formatters[key] = f
		else default_entry_formatters[key] = val end
		for langname,lang in pairs(style.languages) do
			if lang.templates ~= nil and lang.templates[key] ~= nil then
				lang_entry_formatters[key] = {}
				if type(lang.templates[key]) == "string" then
					f,msg = template:make(lang.templates[key],field_formatters)
					if f == nil then self:error(msg,1) return end
					lang_entry_formatters[key][langname] = f
				else lang_entry_formatters[key][langname] = lang.templates[key] end
			end
		end
	end
	local entry_formatter_sub = function(c,ctype,lang)
		if lang_entry_formatters[ctype] == nil or lang == nil or lang_entry_formatters[ctype][lang] == nil then
			return default_entry_formatters[ctype]
		else
			return lang_entry_formatters[ctype][lang]
		end
	end
	local entry_formatter = function(c)
		local l = get_language(style,c)
		local f = entry_formatter_sub(c,c.type,l)
		if f == nil then
			self:warning("No template for the entry " .. c.type)
			f = entry_formatter_sub(c,"",l)
			if f == nil then self:error("Cannot generated an item for the entry " .. c.type,1) return nil end
			return f(c)
		else return f(c) end
	end

	-- CrossReferenceにも同じことをする．
	local default_crossref_entry_formatters = {}
	local lang_crossref_entry_formatters = {}
	for key,val in pairs(style.crossref.templates) do
		if type(val) == "string" then
			local f,msg = template:make(val,field_formatters)
			if f == nil then self:error(msg,1) return end
			default_crossref_entry_formatters[key] = f
		else default_crossref_entry_formatters[key] = val end
		for langname,lang in pairs(style.languages) do
			if lang.crossref ~= nil and lang.crossref.templates ~= nil and lang.crossref.templates[key] ~= nil then
				lang_crossref_entry_formatters[key] = {}
				if type(lang.crossref.templates[key]) == "string" then
					local f,msg = template:make(lang.crossref.templates[key],field_formatters)
					if f == nil then self:error(msg,1) return end
					lang_crossref_entry_formatters[key][langname] = f
				else lang_crossref_entry_formatters[key][langname] = lang.crossref.templates[key] end
			end
		end
	end
	local crossref_entry_formatter_sub = function(c,ctype,lang)
		if lang_crossref_entry_formatters[ctype] == nil or lang == nil or lang_crossref_entry_formatters[ctype][lang] == nil then
			return default_crossref_entry_formatters[ctype]
		else
			return lang_crossref_entry_formatters[ctype][lang]
		end
	end
	local crossref_entry_formatter = function(c)
		local l = get_language(style,c)
		local f = crossref_entry_formatter_sub(c,c.type,l)
		if f == nil then
			f = entry_formatter_sub(c,"",l)
			if f == nil then return nil end
			return f(c)
		else return f(c) end
	end
	return CrossReference.make_formatter(entry_formatter,crossref_entry_formatter)
end

local function apply_cross_reference_modifications(self,style)
	self.cites = style.crossref:modify_citations(self.cites,self.database)
end

local function sort_cites(self,style)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(style.blockseparator,"style.blockseparator","table")
		if style.sorting ~= nil then
			labtxdebug.typecheck(style.sorting.targets,"stylee.sorting.targets","table",true)
			labtxdebug.typecheck(style.sorting.formatters,"style.sorting.formatters","table",true)
		end
	end
	if style.sorting ~= nil and style.sorting.targets ~= nil and #style.sorting.targets > 0 then
		local template = Template.new(style.blockseparator)
		local sort_formatter
		sort_formatter,msg = template:modify_formatters(style.sorting.formatters)
		if sort_formatter == nil then self:error(msg,1) return end
		local sortfunc = generate_sortfunction(style.sorting.targets,sort_formatter,style.sorting.equal,style.sorting.lessthan)
		self.cites = Functions.stable_sort(self.cites, sortfunc)
	end
end


function Core:outputthebibliography(style)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(style.blockseparator,"style.blockseparator","table")
		labtxdebug.typecheck(style.sorting,"style.sorting","table",true)
		if style.sorting ~= nil then
			labtxdebug.typecheck(style.sorting.targets,"style.sorting.targets","table",true)
			labtxdebug.typecheck(style.sorting.formatters,"style.sorting.formatters","table",true)
		end
		labtxdebug.typecheck(style.modify_citations,"style.modify_citations","function",true)
	end
	BibTeX.macros = style.macros
	BibTeX.preamble = BibTeX.preamble .. style.preamble
	local output_cite_function = self:get_item_formatter(style)
	-- Cross Reference
	apply_cross_reference_modifications(self,style)
	-- sort
	sort_cites(self,style)
	-- set language
	for i = 1,#self.cites do
		self.cites[i].language = get_language(style,self.cites[i])
	end
	-- make label
	local c,msg = Label.make_all_labels(style,self.cites)
	if c == nil then error(msg) end
	self.cites = c
	-- check citations
	for _,v in pairs(Functions.citation_check_to_string_table(Functions.citation_check(self.cites))) do
		self:warning(v)
	end

	-- last modification
	if self.modify_citations ~= nil then
		self.cites = self:modify_citations(self.cites)
	end
	-- output
	self.doctype.output(self,output_cite_function)
end

function Core:warning(s)
	if labtxdebug.debugmode then labtxdebug.typecheck(s,"s","string") end
	self.warning_count = self.warning_count + 1
	stdout:write("labtx warning: " .. s .. "\n")
	if self.blg ~= nil then self.blg:write("labtx warning: " .. s .. "\n") end
end

function Core:error(s,exit_code)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(s,"s","string")
		labtxdebug.typecheck(exit_code,"exit_code","number")
	end
	stderr:write("labtx error: " .. s .. "\n")
	if self.blg ~= nil then self.blg:write("labtx error: " .. s .. "\n") end
	if exit_code ~= nil then
		self:dispose()
		exit(exit_code)
	end
end

function Core:log(s)
	if labtxdebug.debugmode then labtxdebug.typecheck(s,"s","string") end
	if self.blg ~= nil then self.blg:write(s .. "\n") end
end

function Core:message(s)
	if labtxdebug.debugmode then labtxdebug.typecheck(s,"s","string") end
	stdout:write(s .. "\n")
	if self.blg ~= nil then self.blg:write(s .. "\n") end
end


return Core
