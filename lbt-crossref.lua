require "lbt-core"
local icu = require "lbt-string"
local U = icu.ustring

LBibTeX.CrossReference = {}
LBibTeX.CrossReference.all_type = {}

function LBibTeX.CrossReference.new()
	local obj = {reference_key_name = U"crossref",override = false,inherit = {}, except = {},all = true,mincrossrefs=1}
	return setmetatable(obj,{__index = LBibTeX.CrossReference})
end

local function array_add(a,b)
	if a == nil then return b end
	if b == nil then return a end
	for i = 1,#b do
		table.insert(a,b[i])
	end
	table.sort(a)
	local numb = #a
	local n = 1
	for i = 2,#a do
		if a[i] ~= a[i - 1] then 
			n = n + 1
			a[n] = a[i]
		end
	end
	for i = n + 1,numb do table.remove(a) end
	return a
end

local function modify_tableindex(index)
	if index == LBibTeX.CrossReference.all_type then return {index} end
	if type(index) ~= "table" then index = {index} end
	for i = 1,#index do
		if type(index[i]) == "string" then index[i] = U(index[i]) end
	end
	return index
end

local function add_to_table_of_CrossReference(table,source_type,target_type,source_key,target_key)
	source_type = modify_tableindex(source_type)
	target_type = modify_tableindex(target_type)
	source_key  = modify_tableindex(source_key )
	target_key  = modify_tableindex(target_key )
	for i = 1,#source_type do
		for j = 1,#target_type do
			for k = 1,#source_key do
				if table[source_type[i]] == nil then table[source_type[i]] = {} end
				if table[source_type[i]][target_type[j]] == nil then table[source_type[i]][target_type[j]] = {} end
				table[source_type[i]][target_type[j]][source_key[k]] = array_add(table[source_type[i]][target_type[j]][source_key[k]],target_key)
			end
		end
	end
--	for stk,stv in pairs(table) do
--		for ttk,ttv in pairs(stv) do
--			for skk,skv in pairs(ttv) do
--				print(U(tostring(stk)) .. U":" .. ttk .. U":" .. skk)
--				for i = 1,#skv do
--					print(U"  " .. skv[i])
--				end
--			end
--		end
--	end
	
	return table
end

function LBibTeX.CrossReference:add_inherit(source_type,target_type,source_key,target_key)
	self.inherit = add_to_table_of_CrossReference(self.inherit,source_type,target_type,source_key,target_key)
end

function LBibTeX.CrossReference:add_except(source_type,target_type,source_key,target_key)
	self.except = add_to_table_of_CrossReference(self.except,source_type,target_type,source_key,target_key)
end

local function table_clone(table)
	r = {}
	for k,v in pairs(table) do r[k] = v end
	return r
end

local function inherit_array_add(table1,table2)
	if table1 == nil then return table2 end
	if table2 == nil then return table1 end
	table1 = table_clone(table1)
	for k,v in table1 do
		table1[k] = array_add(table1[k],table2[k])
	end
	return table1
end

local function get_fields(table,source_type,target_type)
	local src_type_table
	if table[source_type] ~= nil then
		src_type_table = inherit_array_add(table[source_type][target_type],
				table[source_type][LBibTeX.CrossReference.all_type])
	end
	local all_type_table
	if table[LBibTeX.CrossReference.all_type] ~= nil then
		all_type_table = inherit_array_add(table[LBibTeX.CrossReference.all_type][target_type],
				table[LBibTeX.CrossReference.all_type][LBibTeX.CrossReference.all_type])
	end
	return inherit_array_add(src_type_table,all_type_table)
end

local function table_include(array,val)
	if array == nil then return false end
	for k,v in pairs(array) do
		if v == val then return true end
	end
	return false
end

function LBibTeX.CrossReference:modify_citations(cites,db)
	if type(self.reference_key_name) == "string" then self.reference_key_name = U(self.reference_key_name) end
	local referred_table = {}
	local referred_num = {}
	for i = 1,#cites do
		local key = cites[i].fields[self.reference_key_name]
		if key ~= nil then
			key = key:lower()
			local referred = db.db[key]
			if referred == nil then
				cites[i].fields[self.reference_key_name] = nil
			else
				if referred_table[key] == nil then
					referred_table[key] = referred
					referred_num[key] = 1
				else
					referred_num[key] = referred_num[key] + 1
				end
				local inherit = get_fields(self.inherit,referred.type,cites[i].type)
				local except = get_fields(self.except,referred.type,cites[i].type)
				local ruled_keys = {}
				if inherit ~= nil then
					for k,v in pairs(inherit) do
						table.insert(ruled_keys,k)
						ruled_keys = array_add(ruled_keys,v)
					end
				end
				for k,v in pairs(referred.fields) do
					local except_array
					if except ~= nil then 
						except_array = array_add(except[k],except[LBibTeX.CrossReference.all_type])
					end
					if not table_include(except_array,LBibTeX.CrossReference.all_type) then
						if inherit ~= nil and inherit[k] ~= nil then
							local array = array_add(inherit[k],inherit[LBibTeX.CrossReference.all_type])
							for j = 1,#array do
								if not table_include(except_array,array[j]) and (override or cites[i].fields[array[j]] == nil) then
									cites[i].fields[array[j]] = referred.fields[k]
								end
							end
						else
							if self.all and (self.override or cites[i].fields[k] == nil) and (not table_include(ruled_keys,k) and not table_include(except_array,k)) then
								cites[i].fields[k] = referred.fields[k]
							end
						end
					end
				end
			end
		end
	end
	for k,v in pairs(referred_table) do
		if referred_num[k] >= self.mincrossrefs then
			table.insert(cites,db.db[k])
		end
	end
	return cites
end

function LBibTeX.CrossReference:make_formatter(orig_formatter,crossref_formatter)
	local f = {}
	for k,v in pairs(orig_formatter) do
		if crossref_formatter[k] == nil then
			f[k] = v
		else
			f[k] = function(c)
				if c.fields[self.reference_key_name] == nil then return v(c)
				else return crossref_formatter[k](c) end
			end
		end
	end
	return f
end

