--[[
type latex
latex_type.init(bibtex)
-- bibtex: Coreオブジェクト
初期化する
bibtex.labelを設定する．

latex_type.load_aux(bibtex,file)
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
		char_width = 各文字の長さ,
	}

latex_type.output(bibtex,outputfunc)
-- bibtex: Coreオブジェクト
-- outputfunc: 出力を生成する関数
bblへの出力を行う．
]]

local latex_type = {name = "latex"}

local labtxdebug = require "labtx-debug"
local lpeg = require "lpeg"
local Template = require "labtx-template"
local Functions = require "labtx-funcs"

local latex_label = (require "labtx-label").new()
local make_label = latex_label.make_label
-- from bibtex.web
local char_width = {}
char_width[" "] = 278
char_width["!"] = 278
char_width["\""] = 500
char_width["#"] = 833
char_width["$"] = 500
char_width["%"] = 833
char_width["&"] = 778
char_width["'"] = 278
char_width["("] = 389
char_width[")"] = 389
char_width["*"] = 500
char_width["+"] = 778
char_width[","] = 278
char_width["-"] = 333
char_width["."] = 278
char_width["/"] = 500
char_width["0"] = 500
char_width["1"] = 500
char_width["2"] = 500
char_width["3"] = 500
char_width["4"] = 500
char_width["5"] = 500
char_width["6"] = 500
char_width["7"] = 500
char_width["8"] = 500
char_width["9"] = 500
char_width[":"] = 278
char_width[";"] = 278
char_width["<"] = 278
char_width["="] = 778
char_width[">"] = 472
char_width["?"] = 472
char_width["@"] = 778
char_width["A"] = 750
char_width["B"] = 708
char_width["C"] = 722
char_width["D"] = 764
char_width["E"] = 681
char_width["F"] = 653
char_width["G"] = 785
char_width["H"] = 750
char_width["I"] = 361
char_width["J"] = 514
char_width["K"] = 778
char_width["L"] = 625
char_width["M"] = 917
char_width["N"] = 750
char_width["O"] = 778
char_width["P"] = 681
char_width["Q"] = 778
char_width["R"] = 736
char_width["S"] = 556
char_width["T"] = 722
char_width["U"] = 750
char_width["V"] = 750
char_width["W"] =1028
char_width["X"] = 750
char_width["Y"] = 750
char_width["Z"] = 611
char_width["["] = 278
char_width["\\"] = 500
char_width["]"] = 278
char_width["^"] = 500
char_width["_"] = 278
char_width["`"] = 278
char_width["a"] = 500
char_width["b"] = 556
char_width["c"] = 444
char_width["d"] = 556
char_width["e"] = 444
char_width["f"] = 306
char_width["g"] = 500
char_width["h"] = 556
char_width["i"] = 278
char_width["j"] = 306
char_width["k"] = 528
char_width["l"] = 278
char_width["m"] = 833
char_width["n"] = 556
char_width["o"] = 500
char_width["p"] = 556
char_width["q"] = 528
char_width["r"] = 392
char_width["s"] = 394
char_width["t"] = 389
char_width["u"] = 556
char_width["v"] = 528
char_width["w"] = 722
char_width["x"] = 528
char_width["y"] = 528
char_width["z"] = 444
char_width["{"] = 500
char_width["|"] =1000
char_width["}"] = 500
char_width["~"] = 500

local function includeskey(table,key)
	for i = 1, #table do
		if key == table[i].key then return true end
	end
	return false
end

local function read_aux(file)
	if labtxdebug.debugmode then labtxdebug.typecheck(file,"file","string") end
	local aux = {}
	aux.citekeys = {}
	aux.database = {}
	aux.args = {}
	local fp,msg = io.open(file,"r","UTF-8")
	if fp == nil then return nil,msg end
	local grammar = lpeg.P{
		"start";
		start = lpeg.Ct(lpeg.V("cs") * lpeg.V("args")),
		cs = "\\" * lpeg.C((1 - lpeg.S("{(["))^0),
		args = lpeg.Ct(((lpeg.V("arg1") + lpeg.V("arg2") + lpeg.V("arg3")) / function(a,b,c) return {open = a,arg = b,close = c} end)^0),
		arg1 = lpeg.C("{") * lpeg.C((1 - lpeg.S("{}" ) + lpeg.V("inbra"))^0) * lpeg.C("}"),
		arg2 = lpeg.C("(") * lpeg.C((1 - lpeg.S("{})") + lpeg.V("inbra"))^0) * lpeg.C(")"),
		arg3 = lpeg.C("[") * lpeg.C((1 - lpeg.S("{}]") + lpeg.V("inbra"))^0) * lpeg.C("]"),
		inbra = "{" * (((1 - lpeg.S("{}")) + lpeg.V("inbra"))^0) * "}"
	}

	for line in fp:lines() do
		local p = grammar:match(line)
		if p ~= nil then
			local cs = p[1]
			if aux.args[cs] == nil then aux.args[cs] = {} end
			table.insert(aux.args[cs],p[2])
		end
	end
	fp:close()
	
	local citeall = false
	if aux.args["citation"] ~= nil then
		for i = 1,#aux.args["citation"] do
			if aux.args["citation"][i][1] ~= nil then
				if aux.args["citation"][i][1].arg == "*" then
					citeall = true
					break
				else
					if not includeskey(aux.citekeys,aux.args["citation"][i][1].arg) then
						local c = {}
						c.key = aux.args["citation"][i][1].arg
						table.insert(aux.citekeys,c)
					end
				end
			end
		end
	end
	if citeall == true then aux.citekeys = nil end

	if aux.args["bibstyle"] ~= nil then
		if aux.args["bibstyle"][1] ~= nil then
			if aux.args["bibstyle"][1][1] ~= nil then
				aux.style = aux.args["bibstyle"][1][1].arg
			end
		end
	end
	if aux.args["bibdata"] ~= nil then
		for i = 1,#aux.args["bibdata"] do
			if aux.args["bibdata"][i][1] ~= nil then
				local p = 0
				while true do
					local q = aux.args["bibdata"][i][1].arg:find(",",p)
					if q == nil then
						table.insert(aux.database,aux.args["bibdata"][i][1].arg:sub(p))
						break
					else
						table.insert(aux.database,aux.args["bibdata"][i][1].arg:sub(p,q - 1))
					end
					p = q + 1;
				end
			end
		end
	end
	return aux
end

function latex_type.init(bibtex)
	bibtex.label = latex_label
end

function latex_type.load_aux(bibtex,f)
	if f:sub(-4,-1):lower() ~= ".aux" then f = f .. ".aux" end
	local file = kpse.find_file(f)
	if file == nil then
		return nil,"can't find file `" .. f .. "'\n"
	end

	local aux,msg = read_aux(file)
	if aux == nil then return nil,msg end
	local r = file:find("%.[^./]*$")
	local bbl,blg
	if r == nil then
		bbl = file .. ".bbl"
		blg = file .. ".blg"
	else
		bbl = file:sub(1,r) .. "bbl"
		blg = file:sub(1,r) .. "blg"
	end
	return{
		file = file,
		cites = aux.citekeys,
		style = aux.style,
		db = aux.database,
		log = blg,
		out = bbl,
		type_data = {
			aux_args = aux.args,
			char_width = char_width,
		}
	}
end


local function get_width(s,cws)
	local width = 0
	local nest = 0
	for c in string.utfcharacters(s) do
		if c == "{" then nest = nest + 1
		elseif c == "}" then nest = nest - 1
		end
		if nest == 0 then
			local w = cws[c]
			if w == nil then width = width + 500
			else width = width + w end
		end
	end
	return width
end

local function get_longest_label(cites,cws)
	local max_width = 0
	local max_width_label = nil
	for i = 1, #cites do
		local label
		if cites[i].label ~= nil then
			label = cites[i].label
			local width = get_width(label,cws)
			if width > max_width then
				max_width = width
				max_width_label = label
			end
		end
	end
	return max_width_label
end

function latex_type.output(bibtex,outputfunc)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(outputfunc,"outputfunc","function")
	end
	make_label(bibtex)
	local longest_label = get_longest_label(bibtex.cites,bibtex.type_data.char_width)
	if longest_label == nil then longest_label = tostring(#bibtex.cites) end
	bibtex:outputline(bibtex.preamble)
	if bibtex.type_data.preamble ~= nil then bibtex:outputline(bibtex.type_data.preamble) end
	bibtex:outputline("\\begin{thebibliography}{" .. longest_label .. "}")
	for i = 1,#bibtex.cites do
		local item = outputfunc(bibtex.cites[i])
		if item == nil then bibtex:error("can't make an item for " .. bibtex.cites[i].key) end
		local s = "\\bibitem"
		if bibtex.cites[i].label ~= nil then s = s .. "[" .. bibtex.cites[i].label .. "]" end
		s = s .. "{" .. bibtex.cites[i].key .. "}"
		bibtex:outputline(s)
		local item = outputfunc(bibtex.cites[i])
		if item == nil then bibtex:error("I can't make the entry for " .. bibtex.cites[i].key) end
		bibtex:outputline(item)
		bibtex:outputline("")
	end
	bibtex:outputline("\\end{thebibliography}")
end

return latex_type
