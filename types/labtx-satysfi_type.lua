--[[
type latex
satysfi_type.init(bibtex)
-- bibtex: Coreオブジェクト
初期化する
bibtex.labelを設定する．

satysfi_type.load_aux(bibtex,file)
-- bibtex: Coreオブジェクト
-- file: ファイル名（文字列）
auxファイルfileを読み込む．失敗するとnil,msgを返す．ただしmsgはエラーメッセージ．成功すると次のテーブルを返す．
	cites = 引用されているエントリーのキーからなる配列,
	style = スタイル名,
	db = なんだっけ？,
	log = ログを吐き出すファイル名（blg）,
	out = 最終出力先（bbl）,
	type_data = {
		aux_args = auxにあったものたち,
	}

satysfi_type.output(bibtex,outputfunc)
-- bibtex: Coreオブジェクト
-- outputfunc: 出力を生成する関数
bblへの出力を行う．
]]

local satysfi_type = {name = "satysfi"}

local labtxdebug = require "labtx-debug"
local lpeg = require "lpeg"
local Template = require "labtx-template"
local Functions = require "labtx-funcs"
require "lualibs"
local json = utilities.json

function satysfi_type.init(bibtex)
end

function satysfi_type.load_aux(bibtex,f)
	if f:sub(-4,-1):lower() ~= ".satysfi-aux" then f = f .. ".satysfi-aux" end
	local file = kpse.find_file(f)
	if file == nil then file = f end

	local fp = io.open(file,'rb')
	local jsonstring = fp:read('*a')
	fp:close()
	local jsondata =  utilities.json.tolua(jsonstring)
	
	local rv = {file = file,cites = {},db = {},type_data = {}}
	
	local i = 0
	while true do
		local k = jsondata["cite_keys_" .. tostring(i)]
		if k == nil then break end
		local exist = false
		for _,c in ipairs(rv.cites) do
			if c.key == k then exist = true break end
		end
		if exist == false then table.insert(rv.cites,{key = k}) end
		i = i + 1
	end
	i = 0
	while true do
		local k = jsondata["bibliography_database_" .. tostring(i)]
		if k == nil then break end
		table.insert(rv.db,k)
		i = i + 1
	end
	
	local s = jsondata["bibliography_macro"]
	if s ~= nil then rv.type_data.macro = s end
	
	local r = file:find("%.[^./]*$")
	local bbl,blg
	if r == nil then
		rv.out = file .. ".satysfi-bbl.satyh"
		rv.log = file .. ".satysfi-blg"
	else
		rv.out = file:sub(1,r) .. "satysfi-bbl.satyh"
		rv.log = file:sub(1,r) .. "satysfi-blg"
	end
	
	return rv
end

function satysfi_type.output(bibtex,outputfunc)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(outputfunc,"outputfunc","function")
	end
	if bibtex.type_data.macro ~= nil then bibtex:outputline(bibtex.type_data.macro) end
	bibtex:outputline("let bibliography-data = [")
	for i = 1,#bibtex.cites do
		local item = outputfunc(bibtex.cites[i])
		if item == nil then bibtex:error("I can't make the entry for " .. bibtex.cites[i].key) end
		item = item
			:gsub("~"," ")
			:gsub("\\\"u","ü")
			:gsub("%-%-","–")
			:gsub("\\'{e}","é")
			:gsub("{%$(.*)%$}","${%1}")
			:gsub("%$(.*)%$","${%1}")
			:gsub("%${([^}]*){(%u)}(.*)}","${%1{\000%2\000}%3}") -- escaped with the null character
			:gsub("{(%u)}","%1")
			:gsub("\000","")
		bibtex:outputline("(`" .. bibtex.cites[i].key .. "`,`" .. bibtex.cites[i].label .. "`,{" .. item .. "});")
	end
	bibtex:outputline("]")
end

return satysfi_type
