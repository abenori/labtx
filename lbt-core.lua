local Core = {}

local debug = require "lbt-debug"

local BibDatabase = require "lbt-bibdb"
local CrossReference = require "lbt-crossref"
local Template = require "lbt-template"
local Functions = require "lbt-funcs"

local lpeg = require "lpeg"

-- bblを表す構造
-- Core.aux, Core.style, Core.cites, Core.bibs, Core.bbl (stream)

local lbibtex_default = require "lbt-default"

local stderr = io.stderr
local stdout = io.stdout
local exit = os.exit

function Core.new()
	local obj = {}
	obj.database = BibDatabase.new()
	obj.db = obj.database.db
	obj.preamble = obj.database.preamble
	obj.style = ""
	obj.aux = ""
	obj.cites = {}
	obj.bibs = {}
	obj.bbl = nil
	obj.blg = nil
	-- 以下アウトプット用設定
	obj.crossref = CrossReference.new()
	obj.crossref.templates = {}
	obj.blockseparator = {}
	obj.templates = {}
	obj.formatters = {}
	obj.sorting = {}
	obj.sorting.formatters = lbibtex_default.sorting.formatters
	obj.sorting.lessthan = lbibtex_default.sorting.lessthan
	obj.sorting.equal = lbibtex_default.sorting.equal
	obj.sorting.targets = lbibtex_default.sorting.targets
	obj.label = lbibtex_default.label -- obj.label.make, obj.label.add_suffix
	obj.modify_citations = nil
	return setmetatable(obj,{__index = Core})
end

local function includeskey(table,key)
	for i = 1, #table do
		if key == table[i].key then return true end
	end
	return false
end

function Core.read_aux(file)
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


function Core:load_aux(file)
	local aux = Core.read_aux(file)
	self.aux_contents = aux
	self.cites = aux.citekeys
	self.style = aux.style
	self.bibs = aux.database
	local r = file:find("%.[^./]*$")
	local bbl,blg
	if r == nil then
		bbl = file .. ".bbl"
		blg = file .. ".blg"
	else
		bbl = file:sub(1,r) .. "bbl"
		blg = file:sub(1,r) .. "blg"
	end
	self.bbl = io.open(bbl,"w")
	self.blg = io.open(blg,"w")
	self.warning_count = 0
end

function Core:read_db()
	for i = 1,#self.bibs do
		local bibfile = kpse.find_file(self.bibs[i],"bib")
		if bibfile == nil or self.database:read(bibfile) == false then
			self:dispose()
			return false,"Cannot find Database file " .. self.bibs[i]
		else
			self:message("Database file #" .. tostring(i) .. ": " .. self.bibs[i])
		end
	end
	if self.cites == nil then
		-- \cite{*}
		self.cites = {}
		for dummy,v in pairs(self.database.db) do
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

-- コントロールシークエンスとか無視している．
local function get_width(s)
	local width = 0
	for c in string.utfcharacters(s) do
		local w = char_width[c]
		if w == nil then width = width + 500
		else width = width + w end
	end
	return width
end

function Core:get_longest_label()
	local max_width = 0
	local max_width_label = nil
	for i = 1, #self.cites do
		local label
		if self.cites[i].label ~= nil then
			label = self.cites[i].label
			local width = get_width(label)
			if width > max_width then
				max_width = width
				max_width_label = label
			end
		end
	end
	return max_width_label
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


function Core:outputcites(formatter)
	for i = 1, #self.cites do
		local t = self.cites[i].type
		if t ~= nil then
			local f = formatter[t]
			if f == nil then
				self:warning("no style is defined for " .. t)
				f = formatter[""]
				if f == nil then self:error("default style is not defined") end
			end
			local s = "\\bibitem"
			local label = self.cites[i].label
			if label ~= nil then
				s = s .. "[" .. label .. "]"
			end
			local key = self.cites[i].key
			s = s .. "{" .. key .. "}"
			self:outputline(s)
			s = f(self.cites[i])
			s = tostring(s);
--			s = s:gsub("{([A-Z])}","%1")
			self:outputline(trim(s:gsub("  +"," ")))
			self:outputline("")
		end
	end
end

local function get_sorting_formatter(formatters,target)
	return formatters[target] or formatters[""]
end

local function generate_sortfunction(targets,formatters,equal,lessthan)
	return function(lhs,rhs)
		for dummy,target in ipairs(targets) do
			local l = get_sorting_formatter(formatters,target)
			if l == nil then l = lhs.fields[target]
			else l = l(formatters,lhs) end
			if l == nil then goto continue end
			local r = get_sorting_formatter(formatters,target)
			if r == nil then r = rhs.fields[target]
			else r = r(formatters,rhs) end
			if r ~= nil then
				if equal(l,r) == false then
					if debug.debug == true then
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

function Core:outputthebibliography()
	-- formatter生成
	local template = Template.new(self.blockseparator)
	local formatter,cross_formatter,msg
	formatter,msg = template:make(self.templates, self.formatters)
	if formatter == nil then self:error(msg) return end
	cross_formatter,msg = template:make(self.crossref.templates, self.formatters)
	if cross_formatter == nil then self:error(msg) return end
	formatter = self.crossref:make_formatter(formatter,cross_formatter)
	-- Cross Reference
	self.cites = self.crossref:modify_citations(self.cites,self)
	-- label生成
	if self.label.make ~= nil then
		for dummy,c in ipairs(self.cites) do
			c.label = self.label:make(c)
		end
	end
	-- sort
	if self.sorting ~= nil and self.sorting.targets ~= nil and #self.sorting.targets > 0 then
		local sort_formatter
		sort_formatter,msg = template:modify_functions(self.sorting.formatters)
		if sort_formatter == nil then self:error(msg) return end
		local sortfunc = generate_sortfunction(self.sorting.targets,sort_formatter,self.sorting.equal,self.sorting.lessthan)
		self.cites = Functions.stable_sort(self.cites, sortfunc)
	end
	-- label suffix
	if self.label.make ~= nil and self.label.add_suffix ~= nil then
		if type(self.label.add_suffix) ~= "function" then self:error("style file error: label.add_suffix is not a function") return end
		self.cites = self.label:add_suffix(self.cites)
	end
	
	local longest_label = self:get_longest_label()
	if longest_label == nil then longest_label = tostring(#self.cites) end

	-- check citations
	for dummy,v in pairs(Functions.citation_check_to_string_table(Functions.citation_check(self.cites))) do
		self:warning(v)
	end

	-- last modification
	if self.modify_citations ~= nil then
		if type(self.modify_citations) ~= "function" then self:error("style file error: modify_citations is not a function") return end
		self.cites = self:modify_citations(self.cites)
	end

	-- output
	self:outputline(self.preamble)
	self:outputline("")
	self:outputline("\\begin{thebibliography}{" .. longest_label .. "}")
	self:outputcites(formatter)
	self:outputline("\\end{thebibliography}")
end

function Core:warning(s)
	self.warning_count = self.warning_count + 1
	stdout:write("LBibTeX warning: " .. s .. "\n")
	if self.blg ~= nil then self.blg:write("LBibTeX warning: " .. s .. "\n") end
end

function Core:error(s,exit_code)
	stderr:write("LBibTeX error: " .. s .. "\n")
	if self.blg ~= nil then self.blg:write("LBibTeX error: " .. s .. "\n") end
	if exit_code == nil then exit_code = 1 end
	self:dispose()
	exit(exit_code)
end

function Core:log(s)
	if self.blg ~= nil then self.blg:write(s .. "\n") end
end

function Core:message(s)
	stdout:write(s .. "\n")
	if self.blg ~= nil then self.blg:write(s .. "\n") end
end


return Core
