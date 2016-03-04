if LBibTeX == nil then LBibTeX = {} end

require "lbt-database"

-- bblを表す構造
-- LBibTeX.LBibTeX.aux, LBibTeX.LBibTeX.style, LBibTeX.LBibTeX.cites, LBibTeX.LBibTeX.bibs, LBibTeX.LBibTeX.bbl (stream)

LBibTeX.LBibTeX = {}
setmetatable(LBibTeX.LBibTeX,{__index = LBibTeX.BibDatabase})

function LBibTeX.LBibTeX.new()
	local obj = LBibTeX.BibDatabase.new()
	obj.style = ""
	obj.aux = ""
	obj.cites = {}
	obj.bibs = {}
	obj.bbl = nil
	obj.blg = nil
	return setmetatable(obj,{__index = LBibTeX.LBibTeX})
end

local function includeskey(table,key)
	for i = 1, #table do
		if key == table[i].key then return true end
	end
	return false
end

function LBibTeX.read_aux(file)
	local aux = {}
	aux.citekeys = {}
	aux.database = {}
	aux.args = {}
	local fp,msg = io.open(file,"r","UTF-8")
	if fp == nil then return nil,msg end
	for line in fp:lines() do
		if line:sub(1,1) == "\\" then
			local p = line:find("[%[{%(]")
			local cs = ""
			if p == nil then
				cs = line
				line = ""
			else
				cs = line:sub(2,p - 1)
				line = line:sub(p)
			end
			if aux.args[cs] == nil then aux.args[cs] = {} end
			local args = {}
			while true do
				local op = line:sub(1,1)
				local cld = ""
				if op == "{" then cld = "}"
				elseif op == "(" then cld = ")"
				elseif op == "[" then cld = "]"
				else break end
				local p,q = line:find("%b" .. op .. cld)
				if p ~= nil then
					table.insert(args,{arg = line:sub(p + 1,q - 1),open = op, close = cld})
					line = line:sub(q + 1)
				else break end
			end
			table.insert(aux.args[cs],args)
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


function LBibTeX.LBibTeX:load_aux(file)
	local aux = LBibTeX.read_aux(file)
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
	for i = 1,#self.bibs do
		local bibfile = kpse.find_file(self.bibs[i],"bib")
		if bibfile == nil or self:read(bibfile) == false then
			self:dispose()
			return false,"Cannot find Database file " .. self.bibs[i]
		else
			self:message("Database file #" .. tostring(i) .. ": " .. self.bibs[i])
		end
	end
	if self.cites == nil then
		-- \cite{*}
		self.cites = {}
		for k,v in pairs(self.db) do
			self.cites[#self.cites + 1] = v
		end
	else
		local n = #self.cites
		local i = 1
		while i <= n do
			local k = self.cites[i].key
			if self.db[k] == nil then
				self:warning("I don't find a database entry for \"" .. k .. "\"")
				table.remove(self.cites,i)
				i = i - 1
				n = n - 1
			else
				self.cites[i] = self.db[k]
			end
			i = i + 1
		end
	end
	return true
end


local function table_connect(a,b)
	for i = 1,#b do
		table.insert(a,b[i])
	end
	return a
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
	local max_len_label = nil
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
	self.bbl:write(s)
end

function LBibTeX.LBibTeX:outputline(s)
	self.bbl:write(s .. "\n")
end

local function trim(str)
--	return str:gsub("^[ \n\t]*(.-)[ \n\t]*$","%1")
	return str:gsub("^[ \n\t]*",""):gsub("[ \n\t]*$","")
end


function LBibTeX.LBibTeX:outputcites(formatter)
	for i = 1, #self.cites do
		local t = self.cites[i].type
		if t ~= nil then
			local f = formatter[t]
			if f == nil then
				self:warning("no style is defined for " .. t)
				f = formatter[""]
				if f == nil then self:error("default style is not defined") end
			else
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
				self:outputline(trim(s:gsub("  +"," ")))
				self:outputline("")
			end
		end
	end
end

function LBibTeX.LBibTeX:outputthebibliography(formatter)
	local longest_label = self:get_longest_label()
	if longest_label == nil then longest_label = tostring(#self.cites) end
	self:outputline(self.preamble)
	self:outputline("")
	self:outputline("\\begin{thebibliography}{" .. longest_label .. "}")
	self:outputcites(formatter)
	self:outputline("\\end{thebibliography}")
end

-- key に = が入っていると失敗する．
local function getkeyval(str)
	local eq = str:find("=")
	if eq == nil then return str,nil end
	local key = trim(str:sub(1,eq-1))
	local val = trim(str:sub(eq+1))
	return key,val
end

function LBibTeX.LBibTeX:warning(s)
	self.warning_count = self.warning_count + 1
	print("LBibTeX warning: " .. s)
	if self.blg ~= nil then self.blg:write("LBibTeX warning: " .. s .. "\n") end
end

function LBibTeX.LBibTeX:error(s,exit_code)
	print("LBibTeX error: " .. s .. "\n")
	if self.blg ~= nil then self.blg:write("LBibTeX error: " .. s .. "\n") end
	if exit_code == nil then exit_code = 1 end
	self:dispose()
	os.exit(exit_code)
end

function LBibTeX.LBibTeX:log(s)
	if self.blg ~= nil then self.blg:write(s .. "\n") end
end

function LBibTeX.LBibTeX:message(s)
	print(s)
	if self.blg ~= nil then self.blg:write(s .. "\n") end
end

---------------------------------------------------
LBibTeX.debug = {}
function LBibTeX.debug.outputarray(a)
	print("array size = " .. tostring(#a) .. "\n")
	for i = 1, #a do
		print("i = " .. tostring(i) .. ", type = " .. type(a[i]) .. "\n" .. tostring(a[i]))
	end
end


