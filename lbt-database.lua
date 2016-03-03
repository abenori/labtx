if LBibTeX == nil then LBibTeX = {} end

-- 個々の引用を表す
-- Citation.key, Citation.type, Citation.fields[], Citation.label
LBibTeX.Citation = {}
function LBibTeX.Citation.new()
	local obj = {fields = {},type = "",key = "",bib = ""}
	return setmetatable(obj,{__index = LBibTeX.Citation})
end

LBibTeX.Database = {} -- データベースを表す 一覧/マクロ
function LBibTeX.Database.new()
	local obj = {preamble = "", macros_from_db = {}, db = {}, macros = {}, converter = {}};
	return setmetatable(obj,{__index = LBibTeX.Database})
end

-- ファイル読み込み用ラッパ
local buffer = {}
function buffer.new(file,enc)
	if enc == nil then enc = "UTF-8" end
	local f,m = io.open(file,"r",enc)
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

-- ヘルパ関数
local function split_strings_nonestsep(str,sep)
	local a = {}
	local nest = 0
	local inquote = false
	local p = 1
	local startstr = 1
	while true do
		local p1 = str:find("[{}\"]",p)
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
			if nest == 0 and k == "\"" then inquote = not inquote
			elseif not inquote and k == "{" then nest = nest + 1
			elseif not inquote and k == "}" then nest = nest - 1
			end
			p = p1 + 1
		end
	end
	return a
end

local function del_dquote_bracket(str)
	return str:gsub("^[\"{}]",""):gsub("[\"{}]$","")
end

local function trim(str)
--	return str:gsub("^[ \n\t]*(.-)[ \n\t]*$","%1")
	return str:gsub("^[ \n\t]*",""):gsub("[ \n\t]*$","")
end

-- マクロを施す関数
local function apply_macro_to_str(str,macros)
	local a = split_strings_nonestsep(str,"#")
	local r = ""
	for i = 1,#a do
		a[i] = trim(a[i])
		local s
		for j = 1,#macros do
			s = macros[j][a[i]:lower()]
			if s ~= nil then break end
		end
		if s ~= nil then
			r = r .. s
		else
			r = r .. del_dquote_bracket(a[i])
		end
	end
	return trim(r)
end


-- データベース読み込み用の関数たち

-- 次のunnestedな,か)}まで得る
-- return (得たもの),(最後の区切り（カンマまたはendbra））,lineの残り
local function get_entry(line,buf,endbra)
	local ptn
	if endbra == ")" then ptn = "\\*[{}\"),]"
	else ptn = "\\*[{}\",]" end
	local rv = ""
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
				if (k == endbra or k == ",") and nest == 0 and (not inquote) then
					rv = rv .. line:sub(r,q - 1)
					line = line:sub(q + 1)
					return rv,k,line
				elseif k == "{" then nest = nest + 1
				elseif k == "}" then nest = nest - 1
				elseif k == "\"" then inquote = not inquote
				end
				rv = rv .. line:sub(r,q)
				r = q + 1
			end
		end
		line = buf:read()
	until line == nil
	return nil,"cannot find fields started from line: " .. tostring(startline)
end

-- key に = が入っていると失敗する．
local function getkeyval(str)
	local eq = str:find("=")
	if eq == nil then return str,nil end
	local key = trim(str:sub(1,eq-1))
	local val = trim(str:sub(eq+1))
	return key,val
end

local function get_preamble(line,buf,endbra)
	local ptn
	if endbra == ")" then ptn = "\\*[{})]"
	else ptn = "\\*[{}]" end
	local rv = ""
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
				rv = rv .. line .. "\n"
				break
			end
			k = line:sub(q,q)
			if k == endbra and nest == 0 then
				rv = rv .. line:sub(1,q - 1)
				line = line:sub(q + 1)
				return rv,line
			elseif k == "{" then nest = nest + 1
			elseif k == "}" then nest = nest - 1
			end
			r = q + 1
		end
		line = buf:read()
	until line == nil
end


-- return db,preamble,macros
local function read_database(file)
	buf = buffer.new(kpse.find_file(file))
	if buf == nil then return nil,nil,nil end
	local preamble = ""
	local macros = {}
	local db = {}
	line = buf:read()
	while line ~= nil do
		local r = nil
		while line ~= nil do
			r = line:find("@")
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
			local r = line:find("[{(]",r)
			if r ~= nil then
				local k = line:sub(r,r)
				type = trim(line:sub(1,r - 1)):lower()
				if k == "{" then endbra = "}"
				else endbra = ")" end
				line = line:sub(r + 1)
				break
			end
			line = buf:read()
			if line == nil then return nil end
		end

		if type == "preamble" then
			local pre,line = get_preamble(line,buf,endbra)
			if pre == nil then return nil,"searching preamble.. " .. line end
			preamble = preamble .. apply_macro_to_str(pre,{})
		elseif type == "comment" then
			local pre,line = get_preamble(line,buf,endbra)
			if pre == nil then return nil,"searching comment.. " .. line end
		else
			local field,s,line = get_entry(line,buf,endbra)
			if field == nil then break end
			local key = trim(field)
			if type == "string" then
				local k,v = getkeyval(field)
				if k ~= "" then macros[k:lower()] = del_dquote_bracket(v) end
				while s == "," do
					field,s,line = get_entry(line,buf,endbra)
					if field == nil then return nil,"searching entry.. " .. s end
					k,v = getkeyval(field)
					if k ~= "" then macros[k:lower()] = del_dquote_bracket(v) end
				end
			else
				c = LBibTeX.Citation.new()
				local s,field
				repeat
					field,s,line = get_entry(line,buf,endbra)
					if field == nil then return nil,"searching entry.. " .. s end
					local k,v = getkeyval(field)
					if k ~= "" then c.fields[k:lower()] = v end
				until s ~= ","
				c.type = type
				c.key = key
				c.bib = file
				db[key] = c
			end
		end
	end
	return db,preamble,macros
end

local function Database_fields__index(table, key)
	local meta = getmetatable(table)
	local conv = meta.__parent_database.converter[key]
	if conv ~= nil then
		local d = {}
		for v,k in pairs(meta.__data) do
			d[v] = k
		end
		d.fields = meta.__real_fields
		return conv(d)
	else
		local x = rawget(meta.__real_fields,key)
		if x == nil then return nil end
		return meta.__parent_database:apply_macro_to_str(x,meta.__data.bib)
	end
end

local function Database_fields__next(table,index)
	local meta = getmetatable(table)
	local a,b = next(meta.__real_fields,index)
	if b == nil then return a,b
	else
		local conv = meta.__parent_database.converter[a]
		if conv ~= nil then
			local d = {}
			for v,k in pairs(meta.__data) do
				d[v] = k
			end
			d.fields = meta.__real_fields
			return a,conv(d)
		end
		return a,meta.__parent_database:apply_macro_to_str(b,meta.__data.bib)
	end
end

local function Database_fields__pairs(t)
	return Database_fields__next,t,nil
end

function LBibTeX.Database:add_db(cite)
	local real_fields = cite.fields
	local key = cite.key
	cite.fields = {}
	setmetatable(cite.fields,{__index = Database_fields__index,__real_fields = real_fields,__parent_database = self, __data = cite,__pairs = Database_fields__pairs});
	self.db[key] = cite
end

function LBibTeX.Database:read(file)
	-- load databse
	local c,p,m = read_database(file);
	if c == nil then return false end
	self.preamble = self.preamble .. p
	self.macros_from_db[file] = m
	for k,v in pairs(c) do
		self:add_db(v)
	end
	return true
end

function LBibTeX.Database:apply_macro_to_str(str,bib)
	local macros = {self.macros}
	if bib ~= nil and self.macros_from_db[bib] ~= nil then
		table.insert(macros,self.macros_from_db[bib])
	end
	return apply_macro_to_str(str,macros)
end

function LBibTeX.Database:apply_macro(data,key)
	local meta = getmetatable(data.fields)
	if meta ~= nil and meta.__real_fields ~= nil then return self:apply_macro_to_str(rawget(meta.__real_fields,key),data.bib) end
	return self:apply_macro_to_str(data.fields[key],data.bib)
end

