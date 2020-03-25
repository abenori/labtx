local Database = {}

local labtxdebug = require "labtx-debug"

--[[
Database
  Database.db: データベース
  Database.conversions: fieldを変換する関数，function(str,extra_data)
  Database.add_db(cites) citesは配列，各々にはkey,type,fields,extra_dataを定義しておく
  
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
metatable.__conversionsは親Database.conversionsのコピー
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
	for _,conv in ipairs(meta.__conversions) do
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
	for _,conv in ipairs(meta.__conversions) do
		val = conv(val,meta.__extra_data)
	end
	return newindex,val
end

local function fields_pairs(table)
	return fields_enum,table,nil
end


function Citation.new(db,data)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(db,"db","table")
		labtxdebug.typecheck(data,"data","table")
	end
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
	if labtxdebug.debugmode then labtxdebug.typecheck(key,"key","string") end
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
	if labtxdebug.debugmode then labtxdebug.typecheck(key,"key","string") end
	key = unicode.utf8.lower(key)
	local meta = getmetatable(self.fields)
	meta.__extra_fields[key] = nil_data
end

function Citation:get_raw_field(key)
	if labtxdebug.debugmode then labtxdebug.typecheck(key,"key","string") end
	key = unicode.utf8.lower(key)
	local meta = getmetatable(self.fields)
	local val = meta.__extra_fields[key]
	if val == nil_data then return nil end
	if val == nil then val = meta.__real_fields[key] end
	return val
end

function Database.new()
	local obj = {db = {},conversions = {}}
	return setmetatable(obj,{__index = Database})
end

function Database:add_db(c)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(c,"c","table")
		labtxdebug.typecheck(c.key,"c.key","string")
	end
	if self.db[c.key] == nil then
		self.db[c.key] = Citation.new(self,c)
		return true
	else
		return false,"Repeated entry: " .. c.key
	end
end

return Database
