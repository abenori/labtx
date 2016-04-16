if LBibTeX == nil then LBibTeX = {} end

LBibTeX.Database = {}


--[[
LBibTeX.Database
  LBibTeX.Database.db: データベース
  LBibTeX.Database.conversions: fieldを変換する関数，function(str,extra_data)
  LBibTeX.Database.add_db(cites) citesは配列，各々にはkey,type,fields,extra_dataを定義しておく
  
Ciation (local)
  key,type,fields[],extra_data[]にアクセスできる
  Citation:clone()
  Citation:set_field(key,val): keyにvalを追加，cite.fields[key] = valでも同じ
  Citation:set_field(key,cite,key1): keyにcite.fields[key1]を追加
  Citation:delete_field(key): keyを消す
  Citation:get_raw_field(key): conversionが作用されていない生データを取得
  filedsへのアクセスは大文字小文字を無視する（格納は小文字，アクセス時には小文字に変換して処理）

metatableに__real_fieldsと__extra_fieldsを用意
__real_fieldsはdbとかのコピーのつもり．__extra_fieldsは構築後に変更されたフィールドを保持
__index，__newindexは書き換えてある，metatable.__conversionsを通した値を返す
metatable.__conversionsは親LBibTeX.Database.conversionsのコピー

LBibTeX.BibDatabase: LBibTeX.Databaseを継承
  macros[**]でマクロが設定できる
  LBibTeX.BibDatabase.read(file): fileを読む
]]

-- Citationクラス，key,type,fields[],extra_fields[],extra_data[]
local Citation = {}
-- extra_fields内に設定されていると，このフィールドは消されたものと見なす．
local nil_data = {}

local function fields_index(table,key)
	key = unicode.utf8.lower(key)
	local meta = getmetatable(table)
	local val = meta.__extra_fields[key]
	if val == nil_data then return nil end
	if val == nil then val = meta.__real_fields[key] end
	if val == nil then return nil end
	if meta.__conversions == nil then return val end
	for dummy,conv in ipairs(meta.__conversions) do
		val = conv(val,meta.__extra_data)
	end
	return val
end

local function fields_newindex(table,key,value)
	local meta = getmetatable(table)
	if value == nil then meta.__extra_fields[key] = nil_data
	else meta.__extra_fields[key] = value end
end
	
local function fields_enum(table,index)
	local meta = getmetatable(table)
	local val,newindex
	if index == nil or meta.__extra_fields[index] ~= nil then
		newindex = index
		repeat
			newindex,val = next(meta.__extra_fields,newindex)
		until val ~= nil_data or newindex == nil
	end
	if newindex == nil then
		if meta.__extra_fields[index] == nil then newindex = index end
		repeat
			newindex,val = next(meta.__real_fields,newindex)
		until newindex == nil or meta.__extra_fields[newindex] == nil
	end
	if val == nil then return nil,nil end
	if meta.__conversions == nil then return newindex,val end
	for dummy,conv in ipairs(meta.__conversions) do
		val = conv(val,meta.__extra_data)
	end
	return newindex,val
end

local function fields_pairs(table)
	return fields_enum,table,nil
end


function Citation.new(db,data)
	local obj = {}
	for k,v in pairs(data) do
		if k ~= "extra_data" then obj[k] = v end
	end
	obj.extra_data = data.extra_data
	obj.fields = {}
	local fields = data.fields
	if fields == nil then fields = {} end
	local extra_fields = data.extra_fields
	if extra_fields == nil then extra_fields = {} end
--	if obj.extra_data == nil then obj.extra_data = {} end
	setmetatable(obj.fields,{
		__index = fields_index,
		__newindex = fields_newindex,
		__real_fields = fields,
		__extra_fields = extra_fields,
		__conversions = db.conversions,
		__pairs = fields_pairs,
		__extra_data = obj.extra_data})
	return setmetatable(obj,{__index = Citation})
end

function Citation:clone()
	local meta = getmetatable(self)
	local obj = {fields = {},key = self.key,type = self.type, extra_data = self.extra_data}
	local extra_fields = {}
	for k,v in pairs(meta.__extra_fields) do extra_fields[unicode.utf8.lower(k)] = v end
	setmetatable(obj.fields,{
		__index = fields_index,
		__newindex = fields_newindex,
		__real_fields = meta.__real_fields,
		__extra_fields = extra_fields,
		__conversions = meta.conversions,
		__pairs = fields_pairs,
		__extra_data = obj.extra_data})
	return setmetatable(obj,{__index = Citation})
end

-- set_field(key,val)でkeyにvalを入れる
-- set_field(key,cite,key1)でkeyにcite.fields[key1]を入れる
function Citation:set_field(key,a,b)
	key = unicode.utf8.lower(key)
	local meta = getmetatable(self.fields)
	if b == nil then
		if a == nil then a = nil_data end
		meta.__extra_fields[key] = a
	else
		meta.__extra_fields[key] = a:get_raw_field(b)
	end
end

function Citation:delete_field(key)
	key = unicode.utf8.lower(key)
	local meta = getmetatable(self.fields)
	meta.__extra_fields[key] = nil_data
end

function Citation:get_raw_field(key)
	key = unicode.utf8.lower(key)
	local meta = getmetatable(self.fields)
	local val = meta.__extra_fields[key]
	if val == nil_data then return nil end
	if val == nil then val = meta.__real_fields[key] end
	return val
end

function LBibTeX.Database.new()
	local obj = {db = {},conversions = {}}
	return setmetatable(obj,{__index = LBibTeX.Database})
end

function LBibTeX.Database:add_db(data)
	for dummy,v in pairs(data) do
		self.db[v.key] = Citation.new(self,v)
	end
end

-- LBibTeX.BibDatabase
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
			local k = str:sub(p1,p1)
			if nest == 0 and k == "\"" then inquote = not inquote
			elseif not inquote and k == "{" then nest = nest + 1
			elseif not inquote and k == "}" then nest = nest - 1
			end
			p = p1 + 1
		end
	end
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

-- ファイル読み込み用ラッパ
local buffer = {}
function buffer.new(file,enc)
	if enc == nil then enc = "UTF-8" end
	local f,m = io.open(file,"r",enc)
	if f == nil then return nil,m end
	local obj = {fp = f,linenum = 0}
	return setmetatable(obj,{__index = buffer})
end

function buffer:read()
	self.linenum = self.linenum + 1
	return self.fp:read()
end

function buffer:close()
	return self.fp:close()
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
			local k = line:sub(q,q)
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
	local buf = buffer.new(file)
	if buf == nil then return nil,nil,nil end
	local preamble = ""
	local macros = {}
	local db = {}
	local line = buf:read()
	local number = 1
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
		local type
		local endbra
		r = 1
		while true do
			r = line:find("[{(]",r)
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

		local pre
		if type == "preamble" then
			pre,line = get_preamble(line,buf,endbra)
			if pre == nil then return nil,"searching preamble.. " .. line end
			preamble = preamble .. apply_macro_to_str(pre,{})
		elseif type == "comment" then
			pre,line = get_preamble(line,buf,endbra)
			if pre == nil then return nil,"searching comment.. " .. line end
		else
			local field,s
			field,s,line = get_entry(line,buf,endbra)
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
				local c = {}
				c.fields = {}
				c.extra_data = {}
				c.number = number
				number = number + 1
				repeat
					field,s,line = get_entry(line,buf,endbra)
					if field == nil then return nil,"searching entry.. " .. s end
					local k,v = getkeyval(field)
					if k ~= "" then c.fields[k:lower()] = v end
				until s ~= ","
				c.type = type
				c.key = key
				db[key] = c
			end
		end
	end
	return db,preamble,macros
end


LBibTeX.BibDatabase = {}
setmetatable(LBibTeX.BibDatabase,{__index = LBibTeX.Database})

function LBibTeX.BibDatabase:apply_macro_to_str(str,bib)
	local macros = {self.macros}
	if bib ~= nil and self.macros_from_db[bib] ~= nil then
		table.insert(macros,self.macros_from_db[bib])
	end
	return apply_macro_to_str(str,macros)
end

function LBibTeX.BibDatabase.new()
	local obj = LBibTeX.Database.new()
	obj.macros = {}
	obj.macros_from_db = {}
	obj.preamble = ""
	local conv = function(val,data) return LBibTeX.BibDatabase.apply_macro_to_str(obj,val,data.bib) end
	table.insert(obj.conversions,conv)
	return setmetatable(obj,{__index = LBibTeX.BibDatabase})
end

function LBibTeX.BibDatabase:read(file)
	-- load databse
	local c,p,m = read_database(file);
	if c == nil then return false end
	self.preamble = self.preamble .. p
	self.macros_from_db[file] = m
	for dummy,v in pairs(c) do
		v.extra_data.bib = file
	end
	self:add_db(c)
	return true
end

