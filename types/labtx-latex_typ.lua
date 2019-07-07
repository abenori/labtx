local latex_type = {name = "latex"}

local labtxdebug = require "labtx-debug"
local lpeg = require "lpeg"
local Template = require "labtx-template"
local Functions = require "labtx-funcs"

local latex_label = {}
local function purify(s) return s:gsub("\\[a-zA-Z]*",""):gsub("[ -/:-@%[-`{-~]","") end
latex_label = {}

latex_label.templates = {}
latex_label.formatters = {}
latex_label.templates["book"] = "$<shorthand|($<author|editor|key|entry_key>$<year>)>"
latex_label.templates["inbook"] = latex_label.templates["book"]
latex_label.templates["proceedings"] = "$<shorthand|($<editor|key|organization|entry_key>$<year>)>"
latex_label.templates["manual"] = "$<shorthand|($<author|key|organization|entry_key>$<year>)>"
latex_label.templates[""] = "$<shorthand|($<author|key|entry_key>$<year>)>"

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

function latex_label.formatters:author(c)
	return makelabelfromname(c.fields["author"])
end

function latex_label.formatters:editor(c)
	return makelabelfromname(c.fields["editor"])
end

function latex_label.formatters:organization(c)
	local s = c.fields["organization"]
	if s ~= nil then return Functions.text_prefix(s:gsub("^The",""),3)
	else return nil end
end

function latex_label.formatters:key(c)
	local s = c.fields["key"]
	if s ~= nil then return Functions.text_prefix(s,3) end
end

function latex_label.formatters:entry_key(c)
	return Functions.text_prefix(c.key,3)
end

function latex_label.formatters:year(c)
	local year
	if c.fields["year"] == nil then year = ""
	else year = purify(c.fields["year"]) end
	return year:sub(-2,-1)
end

function latex_label:suffix_alphabet(i)
	if i <= 26 then return string.char(string.byte("a") + i - 1)
	else return "" end
end

latex_label.suffix = latex_label.suffix_alphabet

latex_label.make = true

function latex_label:add_suffix(cites)
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

local makesortinglabelfunctions = {}
local template = Template.new()
for key,val in pairs(latex_label.templates) do
	makesortinglabelfunctions[key] = template:make(val,latex_label.formatters)
end


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
	bibtex.sorting.formatters.label = function(self,c)
		local func = makesortinglabelfunctions[c.type] or makesortinglabelfunctions[""]
		if func == nil then return nil end
		local year = c:get_raw_field("year")
		c.fields["year"] = nil
		local l = func(c)
		c.fields["year"] = year
		return l
	end
end

function latex_type.load_aux(bibtex,file)
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

local function make_label(bibtex)
	if labtxdebug.debugmode then
		labtxdebug.typecheck(bibtex.label,"BibTeX.label","table")
		labtxdebug.typecheck(bibtex.label.make,"BibTeX.label.make",{"function","boolean"},true)
	end
	local template = Template.new(bibtex.blockseparator)
	if bibtex.label.make ~= nil and bibtex.label.make ~= false then
		local label_formatter
		if type(bibtex.label.make) == "function" then
			label_formatter = function(c)
				local l = c.language
				if l == nil or bibtex.languages[l] == nil or bibtex.languages[l].label == nil or bibtex.languages[l].label.make == nil then
					return bibtex.label:make(c)
				else
					if type(bibtex.languages[l].label.make) ~= "function" then bibtex:error("languages.label.make should be a function when label.make is a function") return nil end
					return bibtex.languages[l].label:make(c)
				end
			end
		else
			local default_label_field_formatters = template:modify_formatters(bibtex.label.formatters)
			local lang_label_field_formatters = {}
			for langname,lang in pairs(bibtex.languages) do
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
			for key,val in pairs(bibtex.label.templates) do
				local f,msg
				if type(val) == "string" then
					f,msg = template:make(val,label_field_formatters)
					if f == nil then bibtex:error(msg .. " in label.templates") return end
					default_label_formatters[key] = f
				else
					default_label_formatters[key] = val
				end
				for langname,lang in pairs(bibtex.languages) do
					if lang.label ~= nil and lang.label.templates ~= nil and lang.label.templates[key] ~= nil then
						lang_label_formatters[key] = {}
						if type(lang.label.templates[key]) == "string" then
							f,msg = template:make(lang.label.template[key],lang_field_formatters)
							if f == nil then bibtex:error(msg .. " in label.templates") return end
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
						if f == nil then bibtex:error("Cannot generate label for the type " .. c.type,1) return nil end
					end
					return f(c)
				end
			end
		end
	
		for i = 1,#bibtex.cites do
			bibtex.cites[i].label = label_formatter(bibtex.cites[i])
			if bibtex.cites[i].label == nil then
				bibtex:warning("cannot generate the label of " .. bibtex.cites[i].key)
			end
		end
		if bibtex.label.add_suffix ~= nil then
			bibtex.cites = bibtex.label:add_suffix(bibtex.cites)
		end
	end
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
		s = s .. "{" .. bibtex.cites[i].key .. "} "
		bibtex:outputline(s)
		local item = outputfunc(bibtex.cites[i])
		if item == nil then bibtex:error("can't make an item for " .. bibtex.cites[i].key) end
		bibtex:outputline(item)
		bibtex:outputline("")
	end
	bibtex:outputline("\\end{thebibliography}")
end

return latex_type
