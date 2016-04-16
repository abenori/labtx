if LBibTeX == nil then LBibTeX = {} end
if LBibTeX.LBibTeX == nil then LBibTeX.LBibTeX = {} end

-- 三つの状態がある
-- nestレベル=0: 1
-- {}内，頭の文字はcsから始まる: 2
-- {}内，頭の文字は普通の文字から: 3
-- とりあえずこれで区切って返すのを考えてみる．
local function split_str_asin_bibtex(str)
	local byteindex = 1
	return function()
		if byteindex > str:len() then return nil end
		local r = str:find("{",byteindex)
		local start = byteindex
		if r == nil then
			byteindex = str:len() + 1
			return str:sub(start),1
		elseif r == byteindex then
			local r1,r2 = str:find("%b{}",byteindex)
			if r1 == nil then
				r1 = byteindex
				r2 = str:len()
			end
			byteindex = r2 + 1
			if str:sub(r1 + 1,r1 + 1) == "\\" then
				return str:sub(start,r2),2
			else
				return str:sub(start,r2),3
			end
		else
			byteindex = r
			return str:sub(start,r - 1),1
		end
	end
end

local function fix_nest(str)
	local nest = 0
	for c in string.utfcharacters(str) do
		if c == "{" then nest = nest + 1
		elseif c == "}" and nest > 0 then nest = nest - 1
		end
	end
	local r = str
	while nest > 0 do
		r = r .. "}"
		nest = nest - 1
	end
	return r
end

-- not compatible with text.prefix$ (at least at this point)
-- strから頭numバイトをとる．ただし，文字を途中で切るようなことはしない．
-- text_prefix("aあい",2)は"aあ"となるようにする．
function LBibTeX.text_prefix(str,num)
	local index = 1
	local r = ""
	for s,n in split_str_asin_bibtex(str) do
		if n == 2 then
			r = r .. s
			index = index + 1
		else
			for c in string.utfcharacters(s) do
				r = r .. c
				if c ~= "{" and c ~= "}" then index = index + c:len() end
				if index > num then return fix_nest(r) end
			end
		end
		if index > num then return fix_nest(r) end
	end
	return fix_nest(r)
end

-- とりあず普通にバイト数で数えるやつ
function LBibTeX.text_length(str)
	local r = 0
	for s,n in split_str_asin_bibtex(str) do
		if n == 2 then r = r + 1
		else r = r + s:gsub("[{}]",""):len()
		end
	end
	return r
end

-- 検索関数funcによるsplit
-- funcは見付かった最初と最後を返す（バイト数）
-- 戻り値：aXbYcで[XY]を検索した場合{a,b,c},{X,Y}
function LBibTeX.string_split(str,func)
	local array = {}
	local separray = {}
	local r = 1
	while true do
		local r1,r2 = func(str:sub(r))
		if r1 == nil then
			table.insert(array,str:sub(r))
			return array,separray
		else
			r1 = r1 + r - 1
			r2 = r2 + r - 1
			table.insert(array,str:sub(r,r1 - 1))
			table.insert(separray,str:sub(r1,r2))
			r = r2 + 1;
		end
	end
end

local function findUnEscapedBracket(str,pos)
	local r = pos
	while true do
		local q1,q2 = str:find("\\*[{}]",r)
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
		local k = str:sub(p,p)
		if k == "{" then
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
			if str:sub(q,q) == "{" then
				nest = nest + 1
			else
				nest = nest - 1
			end
			r = q + 1
		end
	end
end

function LBibTeX.split_names(names,seps)
	if seps == nil then seps = {" [aA][nN][dD] "} end
	local f = function(str)
		local r1,r2,t = nil
		for i = 1,#seps do
			local sep = seps[i]
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
	local r = name:find("[a-zA-Z]")
	local b = findUnEscapedBracket(name)
	if r == nil then return false
	elseif b == nil or b > r then
		return r == name:find("[a-z]")
	else
		b = b + 1
		local p1,p2 = name:find("\\[a-zA-Z]+",b)
		if b ~= p1 then return false
		else
			local k = name:sub(p1 + 1,p2)
			return (k == "i" or k == "j" or k == "oe" or k == "aa" or k == "o" or k == "l" or k == "ss")
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
	local von = {}
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
	von = InsertFromseparray(array,separray,from,von_end)
	return von,last
end

-- **.partsに名前を入れて，***.sepsに区切り文字を入れる
function LBibTeX.get_name_parts(name)
	-- analyzing name
	local first,last,von,jr
	first = {} first.parts = {} first.seps = {}
	last = {} last.parts = {} last.seps = {}
	jr = {} jr.parts = {} jr.seps = {}
	von = {} von.parts = {} von.seps = {}
	
	-- BibTeXではカンマ，white_space={" ","\t"}，sep_char={"~","-"}で区切る
	local array,separray = LBibTeX.string_split(name:gsub("^[ ,\t~]*",""):gsub("[ ,\t~]*$",""),function(s) return LBibTeX.find_nonnested(s,function(t) return t:find("([ ,~\t%-]+)") end)end)
	local comma1 = nil
	local comma2 = nil
	for i = 1,#separray do
		if separray[i]:sub(1,1) == "," then comma1 = i break end
	end
	if comma1 ~= nil then
		for i = comma1 + 1,#separray do
			if separray[i]:sub(1,1) == "," then comma2 = i break end
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
				if separray[i]:sub(1,1) ~= "-" then
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
		else
		-- 3. von Last, Jr, First
			jr = InsertFromseparray(array,separray,comma1 + 1, comma2)
			first = InsertFromseparray(array,separray,comma2 + 1,#array)
		end
	end
	return {first = first,jr = jr,last = last,von = von}
end

function LBibTeX.format_name_by_parts(nameparts,format)
	local nmpts = {}
	for k,v in pairs(nameparts) do
		nmpts[k] = v
	end
	local r = 1
	local formatted = ""
	local lvjfsearch = function(s) return s:find("[lvjf]") end
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
			if k == "l" then target = nmpts.last
			elseif k == "v" then target = nmpts.von
			elseif k == "f" then target = nmpts.first
			elseif k == "j" then target = nmpts.jr
			end
			if #target.parts ~= 0 then
				local thispart = ""
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
						if i ~= #target.parts and sep == nil then name = name  .. "." end
					end
					if i ~= 1 then
						-- 本当のseparatorの決定
						local realsep = sep
						-- " "を入れるか"~"を入れるか
						if realsep == nil then
							if target.seps[i - 1] == "-" then realsep = "-"
							else realsep = " " end
							local sepistie = (i == #target.parts or (i == 2 and (not full or target.parts[1]:len() <= 2)))
							if realsep:sub(realsep:len()) == " " and sepistie then
								realsep = realsep:sub(1,realsep:len() - 1) .. "~"
							end
						end
						thispart = thispart .. realsep
					end
					thispart = thispart .. name
				end
				if (LBibTeX.text_length(thispart) + LBibTeX.text_length(after)) > 3 and after:sub(after:len()) == "~" then
					after = after:sub(1,after:len() - 1)
					if after:sub(after:len(),after:len()) ~= "~" then
						after = after .. " "
					end
				end
				formatted = formatted .. thispart .. after
			end
		end
	end
end

function LBibTeX.format_name(name,format)
	return LBibTeX.format_name_by_parts(LBibTeX.get_name_parts(name),format)
end

-- str "t" change.case$ の結果
-- A {\TeX B} --> A {\TeX b}
-- A {X \TeX B} --> A {X \TeX B}
-- {X \TeX B} --> {X \TeX B}
-- {\TeX B} --> {\TeX B}
-- A: {\\TeX B} -> A: {\\TeX B}
-- とりあえず実装．もっとシンプルになりそうだけど……
function LBibTeX.change_case(str,t)
	t = t:lower()
	local func
	if t == "u" then func = unicode.utf8.upper
	else func = unicode.utf8.lower end
	
	local incs = false
	local isfirst = true
	local isnewfirst = false
	local nest = 0
	local r = ""
	local brafirst = false
	local applyfunc = true -- {}内を調べているとき，これにfuncを作用させないとならないかどうか
	for c in string.utfcharacters(str) do
		if c == "\\" then
			if brafirst == true then applyfunc = true end
			brafirst = false
			incs = true
			r = r .. c
		elseif c == "{" then
			if nest == 0 then
				brafirst = true
				applyfunc = false
			end
			nest = nest + 1
			r = r .. c
		elseif c == "}" then
			if nest > 0 then nest = nest - 1 end
			if nest == 0 then
				applyfunc = true
				isfirst = false
				isnewfirst = false
			end
			brafirst = false
			r = r .. c
		elseif t == "t" and c == ":" and nest == 0 then
			isnewfirst = true
			brafirst = false
			r = r .. c
		elseif c == " " then
			if nest == 0 then isfirst = false end
			incs = false
			brafirst = false
			r = r .. c
		else
			brafirst = false
			if nest > 0 then
				if incs == true or applyfunc == false then r = r .. c
				elseif t == "t" and (isfirst == true or isnewfirst == true) then r = r .. c
				else r = r .. func(c)
				end
			else
				if t == "t" and (isfirst == true or isnewfirst == true) then r = r .. c
				else r = r .. func(c) end
				isnewfirst = false
				isfirst = false
			end
		end
	end
	return r
end

function LBibTeX.make_name_list(namearray, format, separray, etalstr)
	if #separray == 0 then separray = {", "} end
	
	local r = ""
	for i = 1, #namearray do
		local name = namearray[i]
		if name ~= "others" then
			if type(format) == "function" then
				name = format(name,i,#namearray)
			else
				name = LBibTeX.format_name(name,format)
			end
		end
		if i == #namearray and name == "others" and etalstr ~= nil then
			name = etalstr
			separray[#separray] = ""
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
	return s:gsub("\\[a-zA-Z]+",""):gsub("\\.",""):gsub("[{}]","")
end

local default_required = {}
default_required["article" ] = {required = {"author", "title", "journal", "year"}, optional = {"volume", "number", "pages", "month", "note"}}
default_required["book"] = {required = {{"author","editor"}, "title", "publisher", "year"}, optional = {{"volume","number"}, "series", "address", "edition", "month", "note"}}
default_required["booklet"] = {required = {"title"}, optional = {"titleauthor", "howpublished", "address", "month", "year", "note"}}
default_required["inbook"] = {required = {{"author","editor"}, "title", "chapter","pages", "publisher", "year"}, optional = {{"volume","number"}, "series", "type", "address", "edition", "month", "note"}}
default_required["incollection"] = {required = {"author", "title", "booktitle", "publisher", "year"}, optional = {"editor", {"volume", "number"}, "series", "type", "chapter", "pages", "address", "edition", "month", "note"}}
default_required["inproceedings"] = {required = {"author", "title", "booktitle", "year"}, optional = {"editor", {"volume", "number"}, "series", "pages", "address", "month", "organization", "publisher", "note"}}
default_required["manual"] = {required = {"title"}, optional = {"author", "organization", "address", "edition", "month", "year", "note"}}
default_required["mastersthesis"] = {required = {"author", "title", "school", "year"}, optional = {"type", "address","month", "note"}}
default_required["misc"] = {required = {}, optional = {"author", "title", "howpublished", "month", "year", "note"}}
default_required["phdthesis"] = {required = {"author", "title", "school", "year"}, optional = {"type", "address", "month", "note"}}
default_required["proceedings"] = {required = {"title", "year"}, optional = {"editor", {"volume", "number"}, "series", "address", "month", "organization", "publisher", "note"}}
default_required["techreport"] = {required = {"author", "title", "institution", "year" }, optional = {"type", "number", "address", "month", "note"}}
default_required["unpublished"] = {required = {"author", "title", "note"}, optional = {"month", "year"}}
default_required["conference"] = default_required["incollection"]

-- required[type] = {required = {...},optional = {...}}
-- optional is ignored (at this point)
function LBibTeX.citation_check(citations,required)
	if required == nil then required = default_required end
	local r = {}
	for dummy,v in pairs(citations) do
		local tocheck = required[v.type]
		if tocheck ~= nil then
			for i = 1,#tocheck.required do
				local req = tocheck.required[i]
				if type(req) ~= "table" then req = {req} end
				local check = false
				for j = 1,#req do
					if v.fields[req[j]] ~= nil then check = true break end
				end
				if not check then
					if r[v.key] == nil then r[v.key] = {} end
					local req_clone = {}
					for j = 1,#req do
						table.insert(req_clone,req[j])
					end
					table.insert(r[v.key],req_clone)
				end
			end
		end
	end
	return r
end

function LBibTeX.LBibTeX:output_citation_check(citation_check)
	for k,v in pairs(citation_check) do
		local r = "missing "
		for i = 1,#v do
			if i > 1 then r = r .. ", " end
			if #v[i] > 1 then r = r .. "(" end
			r = r .. v[i][1]
			for j = 2,#v[i] do
				r = r .. " or " .. v[i][j]
			end
			if #v[i] > 1 then r = r .. ")" end
		end
		r = r .. " in " .. k
		self:warning(r)
	end
end

-- [from,to]をソートする．
local function merge_sort(list,from,to,comp)
	local tmplist = {}
	if to - from > 1 then
		local mid = math.floor((to + from)/2)
		merge_sort(list,from,mid,comp)
		merge_sort(list,mid+1,to,comp)
		local left = from
		local right = mid + 1
		local i = 1
		while left <= mid or right <= to do
			if left > mid then
				tmplist[i] = list[right]
				right = right + 1
			elseif right > to then
				tmplist[i] = list[left]
				left = left + 1
			elseif comp(list[right],list[left]) == true then
				tmplist[i] = list[right]
				right = right + 1
			else
				tmplist[i] = list[left]
				left = left + 1
			end
			i = i + 1
		end
		for j = from,to do
			list[j] = tmplist[j - from + 1]
		end
	elseif to - from == 1 then
		if comp(list[to],list[from]) then
			list[to],list[from] = list[from],list[to]
		end
	end
	return list
end

function LBibTeX.stable_sort(list,comp)
	if comp == nil then comp = function(a,b) return a < b end end
	return merge_sort(list,1,#list,comp)
end
