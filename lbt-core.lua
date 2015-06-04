local U = require "icu.ustring"
local icu = {}
icu.ufile = require "icu.ufile"

LBibTeX = {}
local emptystr = U""

-- 個々の引用を表す
-- Citation.key, Citation.type, Citation.fields[], Citation.label
LBibTeX.Citation = {}
local function get_fields(table, key)
	local x = rawget(table,key)
	if x == nil and type(key) == "string" then x = rawget(table,U(key)) end
	return x
end

function LBibTeX.Citation.new()
	local obj = {fields = {},macro_applied = false}
	setmetatable(obj.fields,{__index = get_fields})
	return setmetatable(obj,{__index = Citation})
end


-- bblを表す構造
-- LBibTeX.LBibTeX.aux, LBibTeX.LBibTeX.style, LBibTeX.LBibTeX.cites, LBibTeX.LBibTeX.bibs, LBibTeX.LBibTeX.bbl (stream)
LBibTeX.LBibTeX = {}
local function getargument(str)
	local start = str:find(U"{")
	if start == nil then return nil end
	start = start + 1
	local r = start
	local nest = 0;
	while true do
		r = str:find(U"[{}]",r + 1)
		if r == nil then return nil end
		local s = str:sub(r,r)
		if s == "{" then
			nest = nest + 1;
		elseif s == U"}" then
			if nest == 0 then
				return str:sub(start,r - 1)
			else
				nest = nest - 1
			end
		end
	end
end

local function includeskey(table,key)
	for i = 1, #table do
		if key == table[i].key then return true end
	end
	return false
end


function LBibTeX.LBibTeX.new(file)
	local citation = {}
	local database = {}
	local bbl = {}
	local citeall = false
	local f
	local style
	if type(file) ~= "string" then f = U.encode(file)
	else f = file  file = U(file) end
	local fp,msg = io.open(f,"r")
	if fp == nil then return nil,msg end
	fp:close()
	for line in icu.ufile.lines(icu.ufile.open(f,"r","UTF-8")) do
		local r = line:find(U"\\citation{")
		if r ~= nil then
			local a = getargument(line:sub(r))
			if a == U"*" then
				citeall = true
			else
				if not includeskey(citation,a) then
					local c = LBibTeX.Citation.new()
					c.key = a
					table.insert(citation,c)
				end
			end
		end
		r = line:find(U"\\bibstyle{")
		if r ~= nil then
			style = getargument(line:sub(r))
		end
		r = line:find(U"\\bibdata{")
		if r ~= nil then
			local p = 1
			local a = getargument(line:sub(r))
			while true do
				local q = a:find(U",",p)
				if q == nil then
					table.insert(database,a:sub(p))
					break
				else
					table.insert(database,a:sub(p,q - 1))
				end
				p = q + 1;
			end
		end
	end
	
	local obj = {}
	obj.style = style
	local r = file:find(U"%.[^./]*$")
	local bbl,blg
	if r == nil then
		bbl = file .. U".bbl"
		blg = file .. U".blg"
	else
		bbl = file:sub(1,r) .. U"bbl"
		blg = file:sub(1,r) .. U"blg"
	end
	obj.aux = file
	if citeall then obj.cites = nil
	else obj.cites = citation end
	obj.bibs = database
	obj.preamble = emptystr
	obj.macros = {}
	obj.db = {}
	obj.warning_count = 0
	obj.converter = {}
	obj.bbl = icu.ufile.open(U.encode(bbl),"w")
	obj.blg = icu.ufile.open(U.encode(blg),"w")
	return setmetatable(obj,{__index = LBibTeX.LBibTeX})
end

local function table_connect(a,b)
	for i = 1,#b do
		table.insert(a,b[i])
	end
	return a
end

local function split_strings_nonestsep(str,sep)
	local a = {}
	local nest = 0
	local inquote = false
	local p = 1
	local startstr = 1
	while true do
		local p1 = str:find(U"[{}\"]",p)
		local p2
		if nest == 0 and not inquote then
			p2 = str:find(sep,p)
		end
		if p1 == nil and p2 == nil then
			table.insert(a,str:sub(startstr))
			return a
		elseif p2 ~= nil and (p1 == nil or p2 < p1) then
			table.insert(a,str:sub(startstr,p2 - 1))
			startstr = p2 + 1
			p = p2 + 1
		else
			k = str:sub(p1,p1)
			if nest == 0 and k == U"\"" then inquote = not inquote
			elseif not inquote and k == U"{" then nest = nest + 1
			elseif not inquote and k == U"}" then nest = nest - 1
			end
			p = p1 + 1
		end
	end
	return a
end

local trim_str1 = U"^[ \n\t]*"
local trim_str2 = U"[ \n\t]*$"
local function trim(str)
--	return str:gsub(U"^[ \n\t]*(.-)[ \n\t]*$",U"%1")
	return str:gsub(trim_str1,emptystr):gsub(trim_str2,emptystr)
end

local start_bracket_dquote = U"^[\"{}]"
local end_bracket_dquote = U"[\"{}]$"
local function del_dquote_bracket(str)
	return str:gsub(start_bracket_dquote,emptystr):gsub(end_bracket_dquote,emptystr)
end

function LBibTeX.LBibTeX.apply_macro_to_str(str,macros)
	if type(str) == "string" then str = U(str) end
	local a = split_strings_nonestsep(str,U"#")
	local r = emptystr
	for i = 1,#a do
		a[i] = trim(a[i])
		local s = macros[a[i]:lower()]
		if s == nil then s = macros[U.encode(a[i]:lower())] end
		if s ~= nil then
			if type(s) == "string" then
				s = U(s)
				macros[a[i]:lower()] = s
			end
			r = r .. s
		else
			r = r .. del_dquote_bracket(a[i])
		end
	end
	return trim(r)
end

function LBibTeX.LBibTeX:apply_macro(key)
	if self.db[key].macro_applied == true then return end
	local c = self.db[key]
	for k,v in pairs(c.fields) do
		local converter = self.converter[k]
		if converter == nil then
			converter = self.converter[U.encode(k)]
			self.converter[k] = converter
		end
		if converter == nil then c.fields[k] = LBibTeX.LBibTeX.apply_macro_to_str(v,self.macros)
		else c.fields[k] = converter(LBibTeX.LBibTeX.apply_macro_to_str(v,self.macros)) end
	end
	c.macro_applied = true
	self.db[key] = c
end

function LBibTeX.LBibTeX:add_to_citations(key,nocheckexist)
	if type(key) == "string" then key = U(key) end
	if nocheckexist ~= true then
		for i = 1,#self.cites do
			if self.cites[i].key == key:lower() then return false end
		end
	end
	self:apply_macro(key)
	table.insert(self.cites,self.db[key])
	return true
end

function LBibTeX.LBibTeX:get_db(key)
	if self.db[key] == nil then return nil end
	self:apply_macro(key)
	return self.db[key]
end

function LBibTeX.LBibTeX:set_db(key,c)
	c.macro_applied = true
	if c.key == nil or c.type == nil then return false end
	db[key] = c
	return true
end

function LBibTeX.LBibTeX:read()
	-- load databse
	local c,p,m
	preambles = {}
	for i = 1,#self.bibs do
		c,p,m = LBibTeX.LBibTeX.read_database(self.bibs[i])
		if c == nil then 
			self:message(U"error in " .. self.bibs[i])
			self:error(p)
		end
		self.preamble = self.preamble .. p

		for k,v in pairs(m) do
			self.macros[k] = v
		end
		for k,v in pairs(c) do
			self.db[k] = v
		end
	end
	
	if self.cites == nil then
		-- \cite{*}
		self.cites = {}
		for k,v in pairs(self.db) do
			self:add_to_citations(k,true)
		end
	else
		for i = 1,#self.cites do
			local k = self.cites[i].key
			self:apply_macro(k)
			self.cites[i] = self.db[k]
		end
	end
end

function LBibTeX.LBibTeX:dispose()
	if self.warning_count == 1 then self:message("(There was a warning.)")
	elseif self.warning_count > 0 then self:message("(There were " .. tostring(self.warning_count) .. " warnings.)")
	end
	if self.bbl ~= nil then self.bbl:close() self.bbl = nil end
	if self.blg ~= nil then self.blg:close() self.blg = nil end
end

function LBibTeX.LBibTeX:get_longest_label()
	local max_len = 0
	local max_len_label = emptystr
	for i = 1, #self.cites do
		local label
		if self.cites[i].label ~= nil then
			label = self.cites[i].label
			if label:len() > max_len then
				max_len = label:len()
				max_len_label = label
			end
		end
	end
	return max_len_label
end

function LBibTeX.LBibTeX:output(s)
	if type(s) == "string" then s = U(s) end
	self.bbl:write(s)
end

function LBibTeX.LBibTeX:outputline(s)
	if type(s) == "string" then s = U(s) end
	self.bbl:write(s .. U"\n")
end

function LBibTeX.LBibTeX:outputcites(formatter)
	for i = 1, #self.cites do
		local t = self.cites[i].type
		if t ~= nil then
			local f = formatter[t]
			if f == nil then f = formatter[tostring(t)] end
			if f == nil then
				self:warning(U"no style is defined for " .. t)
				f = formatter[U""]
				if f == nil then f = formatter[""] end
				if f == nil then self:error(U"default style is not defined") end
			else
				local s = U"\\bibitem"
				local label = self.cites[i].label
				if label ~= nil then
					if type(label) == "string" then label = U(label) end
					s = s .. U"[" .. label .. U"]"
				end
				local key = self.cites[i].key
				if type(key) == "string" then key = U(key) end
				s = s .. U"{" .. key .. U"}"
				self:outputline(s)
				s = f(self.cites[i])
				if type(s) == "string" then s = U(s)
				elseif s.toustring ~= nil then s = s:toustring()
				end
				self:outputline(trim(s:gsub(U"  +",U" ")))
				self:outputline(emptystr)
			end
		end
	end
end

local equal = U"="

-- key に = が入っていると失敗する．
local function getkeyval(str)
	local eq = str:find(equal)
	if eq == nil then return str,nil end
	local key = trim(str:sub(1,eq-1))
	local val = trim(str:sub(eq+1))
	return key,val
end

local buffer = {}
function buffer.new(file,enc)
	if enc == nil then enc = "UTF-8" end
	local f,m = icu.ufile.open(U.encode(file),"r",enc)
	if f == nil then return nil end
	obj = {fp = f,linenum = 0}
	return setmetatable(obj,{__index = buffer})
end

function buffer:read()
	self.linenum = self.linenum + 1
	return self.fp:read()
end

function buffer:close()
	return self.fp:close()
end

local yenstar_bracket_dquote_paren_comma = U"\\*[{}\"),]"
local yenstar_bracket_dquote_comma = U"\\*[{}\",]"
local comma = U","
local closebra = U"}"
local openbra = U"{"
local dquote = U"\""
local closeparen = U")"

-- 次のunnestedな,か)}まで得る
-- return (得たもの),(最後の区切り（カンマまたはendbra））,lineの残り
local function get_entry(line,buf,endbra)
	local ptn
	if endbra == closeparen then ptn = yenstar_bracket_dquote_paren_comma
	else ptn = yenstar_bracket_dquote_comma end
	local rv = emptystr
	local startline = buf.linenum
	local nest = 0
	local inquote = false
	repeat
		local r = 1
		while true do
			local q = r
			while true do
				local p1,p2 = line:find(ptn,q)
				if p1 == nil then
					q = nil
					break
				elseif (p2 - p1) % 2 == 1 then
					q = p2 + 1
				else
					q = p2
					break
				end
			end
			if q == nil then
				rv = rv .. line:sub(r)
				break
			else
				local k = line:sub(q,q)
--				print("[" .. line .. "], nest = " .. tostring(nest) .. ", inquote = " .. tostring(inquote) .. ", k = (" ..  k .. ")" .. ", endbra = " .. endbra)
				if (k == endbra or k == comma) and nest == 0 and (not inquote) then
					rv = rv .. line:sub(r,q - 1)
					line = line:sub(q + 1)
					return rv,k,line
				elseif k == openbra then nest = nest + 1
				elseif k == closebra then nest = nest - 1
				elseif k == dquote then inquote = not inquote
				end
				rv = rv .. line:sub(r,q)
				r = q + 1
			end
		end
		line = buf:read()
	until line == nil
	return nil,U"cannot find fields started from line: " .. U(tostring(startline))
end

local yenstar_bracket_parent = U"\\*[{})]"
local yenstar_bracket = U"\\*[{}]"

local function get_preamble(line,buf,endbra)
	local ptn
	if endbra == closeparen then ptn = yenstar_bracket_parent
	else ptn = yenstar_bracket end
	local rv = emptystr
	local startline = buf.linenum
	local nest = 0
	repeat
		local r = 1
		while true do
			local q = r
			while true do
				local p1,p2 = line:find(ptn,q)
				if p1 == nil then
					q = nil
					break
				elseif (p2 - p1) % 2 == 1 then
					q = p2 + 1
				else
					q = p2
					break
				end
			end
			if q == nil then
				rv = rv .. line
				break
			end
			k = line:sub(q,q)
			if k == endbra and nest == 0 then
				rv = rv .. line:sub(1,q - 1)
				line = line:sub(q + 1)
				return rv,line
			elseif k == openbra then nest = nest + 1
			elseif k == closebra then nest = nest - 1
			end
			r = q + 1
		end
		line = buf:read()
	until line == nil
end

local open_bra_paren = U"[{(]"
local preamble_str = U"preamble"
local comment_str = U"comment"
local string_str = U"string"
local atmark = U"@"

-- return db,preamble,macros
function LBibTeX.LBibTeX.read_database(file)
	if type(file) == "string" then file = U(file) end
	buf = buffer.new(file)
	if buf == nil then return nil,nil,nil end
	local preamble = emptystr
	local macros = {}
	local db = {}
	line = buf:read()
	while line ~= nil do
		local r = nil
		while line ~= nil do
			r = line:find(atmark)
			if r ~= nil then break
			else line = buf:read()
			end
		end
		if line == nil then break end
		line = line:sub(r + 1)
		-- 区切り文字を探す．
		local type = nil
		local endbra
		local startline = buf.linenum
		r = 1
		while true do
			local r = line:find(open_bra_paren,r)
			if r ~= nil then
				local k = line:sub(r,r)
				type = trim(line:sub(1,r - 1)):lower()
				if k == openbra then endbra = closebra
				else endbra = closeparen end
				line = line:sub(r + 1)
				break
			end
			line = buf:read()
			if line == nil then return nil end
		end

		if type == preamble_str then
			local pre,line = get_preamble(line,buf,endbra)
			if pre == nil then return nil,U"searching preamble.. " .. line end
			preamble = preamble .. LBibTeX.LBibTeX.apply_macro_to_str(pre,{})
		elseif type == comment_str then
			local pre,line = get_preamble(line,buf,endbra)
			if pre == nil then return nil,U"searching comment.. " .. line end
		else
			local field,s,line = get_entry(line,buf,endbra)
			if field == nil then break end
			local key = trim(field)
			if type == string_str then
				local k,v = getkeyval(field)
				if k ~= emptystr then macros[k:lower()] = del_dquote_bracket(v) end
				while s == comma do
					field,s,line = get_entry(line,buf,endbra)
					if field == nil then return nil,U"searching entry.. " .. s end
					k,v = getkeyval(field)
					if k ~= emptystr then macros[k:lower()] = del_dquote_bracket(v) end
				end
			else
				c = LBibTeX.Citation.new()
				local s,field
				repeat
					field,s,line = get_entry(line,buf,endbra)
					if field == nil then return nil,U"searching entry.. " .. s end
					local k,v = getkeyval(field)
					if k ~= emptystr then c.fields[k:lower()] = v end
				until s ~= comma
				c.type = type
				c.key = key
				db[key] = c
			end
		end
	end
	return db,preamble,macros
end

function LBibTeX.LBibTeX:warning(s)
	self.warning_count = self.warning_count + 1
	if type(s) == "string" then s = U(s) end
	print(U"LBibTeX warning: " .. s)
	if self.blg ~= nil then self.blg:write(U"LBibTeX warning: " .. s .. U"\n") end
end

function LBibTeX.LBibTeX:error(s,exit_code)
	if type(s) == "string" then s = U(s) end
	print(U"LBibTeX error: " .. s .. U"\n")
	if self.blg ~= nil then self.blg:write(U"LBibTeX error: " .. s .. U"\n") end
	if exit_code == nil then exit_code = 1 end
	self:dispose()
	os.exit(exit_code)
end

function LBibTeX.LBibTeX:log(s)
	if type(s) == "string" then s = U(s) end
	if self.blg ~= nil then self.blg:write(s .. U"\n") end
end

function LBibTeX.LBibTeX:message(s)
	print(s)
	if type(s) == "string" then s = U(s) end
	if self.blg ~= nil then self.blg:write(s .. U"\n") end
end

---------------------------------------------------
LBibTeX.debug = {}
function LBibTeX.debug.outputarray(a)
	print("array size = " .. tostring(#a) .. "\n")
	for i = 1, #a do
		print("i = " .. tostring(i) .. ", type = " .. type(a[i]) .. "\n" .. tostring(a[i]))
	end
end


