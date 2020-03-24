--[[
labtx-crossref
function lbt.crossref.new()
戻り値: labtx-crossrefオブジェクト

変数:
  inherit, override: doc参照
  allは何だっけ……？

function CrossReference:modify_citations(cites,db)
  クロスリファレンスの情報に基づき，文献データベースを改変する．
-- cites: Citation (in labtx-database)．改変対象の文献データ．
-- db: 参照するデータベース．
]]

local CrossReference = {}
CrossReference.all_type = ""
CrossReference.reference_key_name = "crossref"

local labtxdebug = require "labtx-debug"

--[[
reference_key_name, override, all, mincrossrefs

CrossReference.inherit["article"]["book"] = {
{"title","booktitle"},
{{"author","editor"},"editor},
{"A",{"B","C"}}
}
... みたいにしてみよう．

CrossReference.all["article"]["book"] = true
CrossReference.override["article"]["book"] = {
	{"title","booktitle",true}
	{"author","editor",false}
]]

function CrossReference.new()
	local obj = {override = {},inherit = {},all = {},mincrossrefs=2}
	local function no_return_nil(table,key)
		local x = rawget(table,key)
		if x == nil then
			local t = {}
			rawset(table,key,t)
			return t
		else return x
		end
	end
	setmetatable(obj.inherit,{__index = no_return_nil})
	setmetatable(obj.override,{__index = no_return_nil})
	setmetatable(obj.all,{__index = no_return_nil})
	obj.override[CrossReference.all_type][CrossReference.all_type] = {
		{CrossReference.all_type,CrossReference.all_type,false}
	}
	obj.all[CrossReference.all_type][CrossReference.all_type] = true
	return setmetatable(obj,{__index = CrossReference})
end

-- table[source_type][target_type][source_key] = {target_keyの配列}という形にしておく．
local function modify_table(oldtable)
	local t = {}
	for source_type,vv in pairs(oldtable) do
		if type(source_type) == "string" then source_type = source_type:lower() end
		t[source_type] = {}
		for target_type,v in pairs(vv) do
			if type(target_type) == "string" then target_type = target_type:lower() end
			t[source_type][target_type] = {}
--			if type(v) ~= "table" then print("TYPE" .. type(v)) return nil end
			for _,array in ipairs(v) do
--				if type(array) ~= "table" then print("TYPE" .. type(array)) return nil end
				local source_keys = array[1]
				local target_keys = array[2]
				if type(source_keys) ~= "table" then source_keys = {source_keys} end
				if type(target_keys) ~= "table" then target_keys = {target_keys} end
				local extra = nil
				if #array > 2 then extra = {table.unpack(array,3)} end
				for _,from in ipairs(source_keys) do
					if type(from) == "string" then from = from:lower() end
					if t[source_type][target_type][from] == nil then
						t[source_type][target_type][from] = {}
					end
					for _,to in pairs(target_keys) do
						to = to:lower()
						if extra ~= nil then 
							to = {to}
							for _,ext in ipairs(extra) do table.insert(to,ext) end
						end
						table.insert(t[source_type][target_type][from],to)
					end
				end
			end
		end
	end
	return t
end

-- 各々のtable1[k]とtable2[k]を結合する（どちらも配列が入っているとする）
local function concat_array_in_table(table1,table2)
	if table1 == nil and table2 == nil then return {} end
	if table1 == nil then return table2 end
	if table2 == nil then return table1 end
	local t = {}
	for k,v in pairs(table1) do
		t[k] = {}
		for i,x in ipairs(v) do
			t[k][i] = x
		end
	end
	for k,v in pairs(table2) do
		if t[k] == nil then
			t[k] = {}
			for i,x in ipairs(v) do
				t[k][i] = x
			end
		else
			for dummy,x in ipairs(v) do
				table.insert(t[k],x)
			end
		end
	end
	return t
end

-- all_typeもあわせた配列を作る．
local function get_fields(table,source_type,target_type)
	local src_type_table
	if table[source_type] ~= nil then
		src_type_table = concat_array_in_table(table[source_type][target_type],
				table[source_type][CrossReference.all_type])
	end
	local all_type_table
	if table[CrossReference.all_type] ~= nil then
		all_type_table = concat_array_in_table(table[CrossReference.all_type][target_type],
				table[CrossReference.all_type][CrossReference.all_type])
	end
	return concat_array_in_table(src_type_table,all_type_table)
end


function CrossReference:modify_citations(cites,db)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(cites,"cites","table")
		labtxdebug.typecheck(db,"db","table")
	end
--	local obj = {reference_key_name = "crossref",override = {},inherit = {}, except = {},all = {},mincrossrefs=1}
	local all_type = CrossReference.all_type
	local inherit_table = modify_table(self.inherit)
	local override_table
	if type(self.override) ~= "table" then 
		override_table = {}
		override_table[all_type] = {}
		override_table[all_type][all_type] = {}
		override_table[all_type][all_type][all_type] = {{all_type,self.override}}
	else override_table = modify_table(self.override) end
	local reffered = {}
	for i,cite in ipairs(cites) do
		local key = cite.fields[self.reference_key_name]
		if key ~= nil then 
			key = unicode.utf8.lower(key)
			if db.db[key] ~= nil then
				if reffered[key] == nil then
					reffered[key] = {i}
				else
					table.insert(reffered[key],i)
				end
			end
		end
	end

	for parent_key,child_keys in pairs(reffered) do
		local parent = db.db[parent_key]
		for dummy,child_number in ipairs(child_keys) do
			local child = cites[child_number]
			local inherit = get_fields(inherit_table,parent.type,child.type)
			local override = get_fields(override_table,parent.type,child.type)
--			print(table.unpack(override[all_type]))
			
			local allwrite = (self.all[all_type][all_type] == true or self.all[all_type][child.type] == true or self.all[parent.type][all_type] == true or self.all[parent.type][child.type] == true)
			for key,dummy in pairs(parent.fields) do
				local target_field_keys = inherit[key]
				if target_field_keys == nil then target_field_keys = inherit[all_type] end
				if target_field_keys == nil then
					if allwrite == true then target_field_keys = {key}
					else goto continue end
				end
				for dummy,target_field_key in ipairs(target_field_keys) do
					local isoverride = nil
					if child.fields[target_field_key] == nil then isoverride = true
					-- override[key]の中身は{{"title",true},...}
					elseif override[key] ~= nil then
						for dummy,x in ipairs(override[key]) do
							if x[1] == all_type or x[1] == target_field_key then 
								isoverride = x[2]
								break
							end
						end
					elseif override[all_type] ~= nil then
						for dummy,x in ipairs(override[all_type]) do
							if x[1] == all_type or x[1] == target_field_key then 
								isoverride = x[2]
								break
							end
						end
					end
--					print("add field(" .. tostring(isoverride) .. "): from " .. target_field_key .. " in " .. parent.key .. " to " .. key .. " in " .. child.key .. ", value = " .. parent.fields[target_field_key])
					if isoverride == true then
						child:set_field(target_field_key,parent,key)
					end
				end
				::continue::
			end
		end
		if #child_keys >= self.mincrossrefs then
			local insert = true
			for dummy,c in ipairs(cites) do
				if c.key == parent.key then
					insert = false
					break
				end
			end
			if insert == true then table.insert(cites,parent:clone()) end
		end
	end
	-- 引用されていない文献のcrossrefは消す
	for dummy,c in ipairs(cites) do
		local del_crossref = true
		for dummy,cc in ipairs(cites) do
			if c.fields[self.reference_key_name] ~= nil and cc.key == unicode.utf8.lower(c.fields[self.reference_key_name]) then
				del_crossref = false
				break
			end
		end
		if del_crossref == true then c:set_field(self.reference_key_name,nil) end
	end
	return cites
end


function CrossReference.make_formatter(orig_formatter,crossref_formatter,reference_key_name)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(orig_formatter,"orig_formatter","function")
		labtxdebug.typecheck(crossref_formatter,"crossref_formatter","function",true)
		labtxdebug.typecheck(reference_key_name,"reference_key_name","string",true)
	end
	if crossref_formatter == nil then return orig_formatter
	else
		if reference_key_name == nil then reference_key_name = "crossref" end
		return function(c)
			if c.fields[reference_key_name] == nil then return orig_formatter(c)
			else
				local rv = crossref_formatter(c)
				if rv == nil then return orig_formatter(c)
				else return rv end
			end
		end
	end
end

return CrossReference
