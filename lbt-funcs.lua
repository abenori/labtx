require "lbt-core"
local U = require "icu.ustring"

-- not compatible with text.prefix$ (at least at this point)
function LBibTeX.text_prefix(str,num)
	if type(str) == "string" then str = U(str) end
	local r = 1
	local rv = U""
	for i = 1,num do
		if str:sub(r,r) ~= U"{" then
			rv = rv .. str:sub(r,r)
			r = r + 1
		else
			local p1,p2 = str:find(U"%b{}",r)
			if p1 == nil then return rv end
			rv = rv .. str:sub(p1,p2)
			r = p2 + 1
		end
	end
	return rv
end

function LBibTeX.text_length(str)
	if type(str) == "string" then str = U(str) end
	local len = 0
	local r = 1
	local strlen = str:len()
	while r <= strlen do
		if str:sub(r,r) ~= U"{" then
			r = r + 1
		else
			local p1,p2 = str:find(U"%b{}",r)
			if p1 == nil then return len + 1 end
			r = p2 + 1
		end
		len = len + 1
	end
	return len
end

-- 検索関数funcによるsplit
-- funcは見付かった最初と最後を返す
-- 二つ目には分割していた文字を返す．
function LBibTeX.string_split(str,func)
	if type(str) == "string" then str = U(str) end
	local array = {}
	local separray = {}
	local r = init
	if r == nil then r = 1 end
	local start = 0
	while true do
		local r1,r2,s = func(str:sub(r))
		if r1 == nil then
			table.insert(array,str:sub(start))
			return array,separray
		else
			r1 = r1 + r - 1
			r2 = r2 + r - 1
			table.insert(array,str:sub(start,r1 - 1))
			table.insert(separray,s)
			start = r2 + 1
			r = r2 + 1;
		end
	end
end

local function findUnEscapedBracket(str,pos)
	local r = pos
	while true do
		local q1,q2 = str:find(U"\\*[{}]",r)
		if q1 == nil then return nil
		elseif (q2 - q1) %2 == 0 then return q2
		else r = q2 + 1
		end
	end
end

-- 対応のとれている括弧{}の位置を検索して返す．
local function getBracketInside(str,pos)
	local r = pos
	if r == nil then r = 1 end
	local nest = 0
	local start
	while true do
		local p = findUnEscapedBracket(str,r)
		if p == nil then return nil end
		k = str:sub(p,p)
		if k == U"{" then
			if nest == 0 then start = p end
			nest = nest + 1
		else
			if nest == 1 then return start,p end
			nest = nest - 1
		end
		r = p + 1
	end
end


-- {}によるネストレベルが0のものを検索する．素の検索にはfuncを使う．
-- {}は\によるエスケープも考慮する．
function LBibTeX.find_nonnested(str,func,init)
	if type(str) == "string" then str = U(str) end
	local nest = 0
	local r = init
	if r == nil then r = 1 end
	while true do
		local p1,p2,s = func(str:sub(r))
		local q = findUnEscapedBracket(str,r)
		if p1 ~= nil then
			p1 = p1 + r - 1
			p2 = p2 + r - 1
		end
		if p1 == nil and q == nil then return nil,nil,nil
		elseif p1 ~= nil and (q == nil or p1 < q) then
			if nest == 0 then return p1,p2,s end
			r = p2 + 1
		elseif q ~= nil then
			if str:sub(q,q) == U"{" then
				nest = nest + 1
			else
				nest = nest - 1
			end
			r = q + 1
		end
	end
end

function LBibTeX.split_names(names,seps)
	if type(names) == "string" then names = U(names) end
	if seps == nil then seps = {U" [aA][nN][dD] "} end
	f = function(str)
		local r1,r2,t = nil
		for i = 1,#seps do
			local sep = seps[i]
			if type(sep) == "string" then sep = U(sep) end
			local p1,p2,s = str:find(sep)
			if p1 ~= nil and (r1 == nil or p1 < r1) then
				r1 = p1
				r2 = p2
				t = s
			end
		end
		return r1,r2,t
	end
	return LBibTeX.string_split(names,f)
end

-- debug用
--local function dumpTarget(target)
--	print("dump starts")
--	for i = 1,#target.parts do
--		print(target.parts[i])
--		local s = ""
--		if target.seps[i] ~= nil then s = target.seps[i] end
--		if i ~= #target.parts then print("[" .. s .. "]") end
--	end
--	print("dump ends")
--end

-- 398あたりのコード．
-- control_seq_illkは339か？（117ページ）
-- {\の時，コントロールシークエンスを探す．
-- それが\i,\j,\oe,\aa,\o,\l,\ssならばvonと判断
-- そうでない場合，この{}内に小文字が最初に現れたらvonと判断
-- ちょっといい加減に……
local function Isvon(name)
	local r = name:find(U"[a-zA-Z]")
	local b = findUnEscapedBracket(name)
	if r == nil then return false
	elseif b == nil or b > r then
		return r == name:find(U"[a-z]")
	else
		b = b + 1
		p1,p2 = name:find(U"\\[a-zA-Z]+",b)
		if b ~= p1 then return false
		else
			k = name:sub(p1 + 1,p2)
			return (k == U"i" or k == U"j" or k == U"oe" or k == U"aa" or k == U"o" or k == U"l" or k == U"ss")
		end
	end
end

local function InsertFromseparray(array,separray,from,to)
	local r = {}
	r.parts = {} r.seps = {}
	for i = from,to do
		table.insert(r.parts,array[i])
		if i ~= to then table.insert(r.seps,separray[i]) end
	end
	return r
end

-- return von,last
local function SplitvonLast(array,separray,from,to)
	local last = {}
	last.parts = {} last.seps = {}
	local von_end = from - 1
	if #array == 0 then return von,last end
	table.insert(last.parts,array[to])
	for i = to - 1, from, -1 do
		if Isvon(array[i]) then
			von_end = i
			break
		end
		table.insert(last.seps,1,separray[i])
		table.insert(last.parts,1,array[i])
	end
	local von = InsertFromseparray(array,separray,from,von_end)
	return von,last
end

-- **.partsに名前を入れて，***.sepsに区切り文字を入れる
function LBibTeX.get_name_parts(name)
	if type(name) == "string" then name = U(name) end
	-- analyzing name
	local first,last,von,jr
	first = {} first.parts = {} first.seps = {}
	last = {} last.parts = {} last.seps = {}
	jr = {} jr.parts = {} jr.seps = {}
	von = {} von.parts = {} von.seps = {}
	
	-- BibTeXではカンマ，white_space={" ","\t"}，sep_char={"~","-"}で区切る
	local array,separray = LBibTeX.string_split(name:gsub(U"^[ ,\t~]*",U""):gsub(U"[ ,\t~]*$",U""),function(s) return LBibTeX.find_nonnested(s,function(t) return t:find(U"([ ,~\t%-]+)") end)end)
	local comma1 = nil
	local comma2 = nil
	for i = 1,#separray do
		if separray[i]:sub(1,1) == U"," then comma1 = i break end
	end
	if comma1 ~= nil then
		for i = comma1 + 1,#separray do
			if separray[i]:sub(1,1) == U"," then comma2 = i break end
		end
	end
	if comma1 == nil then
		-- 1. First von Last
		local von_start = nil
		for i = 1,#array - 1 do
			if Isvon(array[i]) then
				von_start = i
				break
			end
		end
		if von_start == nil then
			local first_end = 0
			last = {}
			last.parts = {}last.seps = {}
			for i = #array - 1,1,-1 do
				table.insert(last.parts,1,array[i + 1])
				if separray[i]:sub(1,1) ~= U"-" then
					first_end = i
					break
				end
				table.insert(last.seps,1,separray[i])
			end
			if first_end == 0 then table.insert(last.parts,1,array[1])
			else first = InsertFromseparray(array,separray,1,first_end) end
		else
			first = InsertFromseparray(array,separray,1,von_start - 1)
			von,last = SplitvonLast(array,separray,von_start,#array)
		end
	else
		-- von Last, ***
		von,last = SplitvonLast(array,separray,1,comma1)
		if comma2 == nil then
		-- 2. von Last, First
			first = InsertFromseparray(array,separray,comma1 + 1,#array)
		-- 3. von Last, Jr, First
		else
			jr = InsertFromseparray(array,separray,comma1 + 1, comma2)
			first = InsertFromseparray(array,separray,comma2 + 1,#array)
		end
	end
	return {first = first,jr = jr,last = last,von = von}
end

function LBibTeX.forat_name_by_parts(nameparts,format)
	if type(format) == "string" then format = U(format) end
	local nmpts = {}
	for k,v in pairs(nameparts) do
		nmpts[k] = v
		for i = 1,#v.parts do
			if type(nmpts[k].parts[i]) == "string" then nmpts[k].parts[i] = U(nmpts[k].parts[i]) end
		end
		for i = 1,#v.seps do
			if type(nmpts[k].seps[i]) == "string" then nmpts[k].seps[i] = U(nmpts[k].seps[i]) end
		end
	end
	local r = 1
	formatted = U""
	local lvjfsearch = function(s) return s:find(U"[lvjf]") end
	while true do
		-- {}を探して中身を処理する．
		local p,q = getBracketInside(format,r)
		if p == nil then return formatted .. format:sub(r) end
		formatted = formatted .. format:sub(r,p - 1)
		r = q + 1
		local str = format:sub(p + 1,q - 1)
		local subptn = LBibTeX.find_nonnested(str,lvjfsearch)
		if subptn == nil then
			formatted = formatted .. str
		else
			-- lvjfがあった．
			local k = str:sub(subptn,subptn):lower()
			local target
			if k == U"l" then target = nmpts.last
			elseif k == U"v" then target = nmpts.von
			elseif k == U"f" then target = nmpts.first
			elseif k == U"j" then target = nmpts.jr
			end
			if #target.parts ~= 0 then
				local thispart = U""
				thispart = thispart .. str:sub(1,subptn - 1)
				local full,after
				if str:sub(subptn + 1,subptn + 1) == k then
					full = true
					after = str:sub(subptn + 2)
				else
					full = false
					after = str:sub(subptn + 1)
				end
				-- 最後の{}内を探してそれをsepに代入
				local sep = nil
				local rr = 1
				local x1,x2,a1,a2
				while true do
					x1,x2 = getBracketInside(after,rr)
					if x1 == nil then break end
					a1 = x1
					a2 = x2
					sep = after:sub(a1 + 1,a2 - 1)
					rr = a1 + 1
				end
				if sep ~= nil then
					after = after:sub(1,a1 - 1) .. after:sub(a2 + 1)
				end
				for i = 1,#target.parts do
					local name
					if full then name = target.parts[i]
					else
						name = LBibTeX.text_prefix(target.parts[i],1)
						if i ~= #target.parts and sep == nil then name = name  .. U"." end
					end
					if i ~= 1 then
						-- 本当のseparatorの決定
						local realsep = sep
						-- " "を入れるか"~"を入れるか
						if realsep == nil then
							if target.seps[i - 1] == U"-" then realsep = U"-"
							else realsep = U" " end
							local sepistie = (i == #target.parts or (i == 2 and (not full or target.parts[1]:len() <= 2)))
							if realsep:sub(realsep:len()) == U" " and sepistie then
								realsep = realsep:sub(1,realsep:len() - 1) .. U"~"
							end
						end
						thispart = thispart .. realsep
					end
					thispart = thispart .. name
				end
				if (thispart:len() + after:len()) > 3 and after:sub(after:len()) == U"~" then
					after = after:sub(1,after:len() - 1)
					if after:sub(after:len(),after:len()) ~= U"~" then
						after = after .. U" "
					end
				end
				formatted = formatted .. thispart .. after
			end
		end
	end
end

function LBibTeX.format_name(name,format)
	return LBibTeX.forat_name_by_parts(LBibTeX.get_name_parts(name),format)
end

local function apply_function_to_nonnested_str(str,func,pos)
	local nest = 0
	local p = pos
	if p == nil then p = 1 end
	local r = str:sub(1,p-1)	
	while true do
		local p1,p2 = getBracketInside(str,p)
		if p1 == nil then
			r = r .. func(str:sub(p))
			return r
		end
		r = r .. func(str:sub(p,p1 - 1)) .. str:sub(p1,p2)
		p = p2 + 1
	end
end

function LBibTeX.change_case(s,t)
	t = t:lower()
	if type(t) == "string" then t = U(t) end
	if type(s) == "string" then s = U(s) end
	if t == U"t" then
		local f = function(s)
			local r = U""
			local p = 0
			while true do
				local p1 = s:find(U": *.",p)
				if p1 == nil then
					return r .. s:sub(p):lower()
				else
					r = r .. s:sub(p,p1 - 1):lower() .. s:sub(p1,p1 + 2)
					p = p1 + 3
				end
			end
		end
		local start = 2
		if s:sub(1,1) == U"{" then start = 1 end
		return apply_function_to_nonnested_str(s,f,start)
	elseif t == U"u" then
		return apply_function_to_nonnested_str(s,U.upper)
	elseif t == U"l" then
		return apply_function_to_nonnested_str(s,U.lower)
	else return nil
	end
end

function LBibTeX.make_name_list(namearray, format, separray, etalstr)
	if type(etalstr) == "string" then etalstr = U(etalstr) end
	for i = 1, #separray do
		if type(separray[i]) == "string" then separray[i] = U(separray[i]) end
	end
	if #separray == 0 then separray = {U", "} end
	if type(format) == "string" then format = U(format) end
	
	local r = U""
	for i = 1, #namearray do
		local name
		if type(namearray[i]) == "string" then name = U(namearray[i])
		else name = namearray[i] end
		if name ~= "others" then
			if type(format) == "function" then
				name = format(name,i,#namearray)
			else
				name = LBibTeX.format_name(name,format)
			end
		end
		if i == #namearray and name == U"others" and etalstr ~= nil then
			name = etalstr
			separray[#separray] = U""
		end
		
		if i ~= 1 then
			if i < #namearray - #separray + 1 then
				r = r .. separray[1]
			else
				r = r .. separray[i - #namearray + #separray]
			end
		end
		r = r .. name
	end
	return r
end

-- とりあえず適当な実装
function LBibTeX.remove_TeX_cs(s)
	return s:gsub(U"\\[a-zA-Z]+",U""):gsub(U"\\.",U""):gsub(U"[{}]",U"")
end
