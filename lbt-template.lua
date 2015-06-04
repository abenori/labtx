require "lbt-core"
require "lbt-item"
local U = require "icu.ustring"

--[[
書式をあたえるとスタイルを生成してくれるようにする．
こんな感じ．
[**:**:**]：ブロック．あたえられた結合文字列を使って結合される．空文字列は無視される．ネスト可能．LBibTeX.Template.blockseparator[nest], LBibTeX.Template.blocklast[nest]で結合部分/最後の文字列をどうにかできる．ピリオドは連続しないように処理される．:@S<***>とするとそこの区切り文字を***に変更する．
<(LEFT)|(STR)|(RIGHT)>：STR != ""ならば(LEFT)(STR)(RIGHT)を出す，STR==""ならば空文字列
$<A|B|C|...>：関数Aが呼び出され，その値が空ならばBが呼び出され……となり，最初に空でないものが出力される．関数Aが見付からない場合は名前がAのfieldが呼ばれる．（例えば，$<title>は関数 titleが定義されていなければタイトルそのものがでる．）
全ては%でエスケープできる．
]]

--[[
中間データは文字列の配列で表す．
* block生成の時に配列をblockと解釈
* 文字列連結の時は，最初と最後を文字列つぃて連結する
とすればよいだろうか．

ユーザ定義関数は配列を渡すことで，ブロックの区切りを明示することができる．
]]

LBibTeX.Template = {}

local function isempty(array)
	for i = 1,#array do
		if array[i] ~= nil and array[i] ~= U"" then return false end
	end
	return true
end

local function table_connect(a,b)
	local rv = {}
	if #a == 0 then return b
	elseif #b == 0 then return a
	else
		for i = 1,#a do rv[i] = a[i] end
		rv[#rv] = rv[#rv] .. b[1]
		for i = 2,#b do
			table.insert(rv,b[i])
		end
	end
	return rv
end

local function findUnescaped(str,chars,pos)
	local p1,p2
	p2 = pos
	while true do
		p1,p2 = str:find(U"%%*[" .. chars .. U"]",p2)
		if p1 == nil then
			return nil
		elseif (p2 - p1) % 2 == 0 then
			return p2
		else
			p2 = p2 + 1
		end
	end
end

local function string_to_array(s)
	if s == nil or s == U"" then return {U""}
	else return {s} end
end

local function array_to_string(a)
	local r = U""
	for i = 1,#a do r = r .. a[i] end
	return r
end

-- block等の切り出し．return array,r で，sepで区切った結果がarray，rは[***](ココ)
-- 失敗したらreturn nil,nil
local function GetArrayOfBlocks(str,beg,en,sep,pos)
	local nest = 0
	local array = {}
	local r = pos
	local blockstart = pos
	local search
	if sep ~= nil then search = (beg .. en .. sep):gsub(U"[%[%]]",U"%%%1")
	else search = (beg .. en):gsub(U"[%[%]]",U"%%%1") end
	while true do
		r = findUnescaped(str,search,r)
		if r == nil then
			return nil,nil
		end
		local k = str:sub(r,r)
		if k == sep and nest == 0 then
			table.insert(array,str:sub(blockstart,r - 1))
			blockstart = r + 1
			r = r + 1
		else
			if k == beg then nest = nest + 1
			elseif k == en then
				if nest == 0 then
					table.insert(array,str:sub(blockstart,r - 1))
					return array,r + 1
				else nest = nest - 1
				end
			end
			r = r + 1
		end
	end
end



-- ブロックの区切りに|を使った時のもの．<>のネストも考慮しないとならないためコードが少し複雑になる．
--local function GetArrayOfBlocks(str,en,pos)
--	local search = "%[%]<>|"
--	local nest = {}
--	nest["]"] = 0
--	nest[">"] = 0
--	local r = pos
--	local array = {}
--	local blockstart = pos
--	while true do
--		r = findUnescaped(str,search,r)
--		if r == nil then
--			return nil,nil
--		end
--		if str:sub(r,r) == "|" and nest["]"] == 0 and nest[">"] == 0 then
--			table.insert(array,str:sub(blockstart,r - 1))
--			blockstart = r + 1
--			r = r + 1
--		else
--			k = str:sub(r,r)
--			if k == en and nest[k] == 0 then
--				table.insert(array,str:sub(blockstart,r - 1))
--				return array,r + 1
--			elseif k == "[" then 
--				nest["]"] = nest["]"] + 1
--			elseif k == "<" then
--				nest[">"] = nest[">"] + 1
--			elseif k == "]" then
--				nest["]"] = nest["]"] - 1
--			elseif k == ">" then
--				nest[">"] = nest[">"] - 1
--			end
--			r = r + 1
--		end
--	end
--end

local MakeTemplateImpl

-- [A:B:C:...]
local function MakeBlockFunction(array,funcs,blocknest)
	local f = {}
	local seps = {}
	for i = 1,#array do
		if array[i]:sub(1,1) == U"@" then
			if array[i]:sub(2,2) == U"S" then 
				local a,r = GetArrayOfBlocks(array[i],U"<",U">",nil,4)
				if a == nil then return nil end
				seps[i] = MakeTemplateImpl(a[1],funcs,blocknest + 1)
				array[i] = array[i]:sub(r)
			end
		end
		local ff = MakeTemplateImpl(array[i],funcs,blocknest + 1)
		if ff == nil then return nil end
		table.insert(f,ff)
	end
	return function(c)
		local block = LBibTeX.block.new(LBibTeX.Template.blockseparator[blocknest],LBibTeX.Template.blocklast[blocknest])
		local sepnumber = 1
		for i = 1, #f do
			local a = f[i](c)
			block:addarrayitem(a)
			if seps[i] ~= nil then block:setseparator(sepnumber,array_to_string(seps[i](c))) end
			sepnumber = sepnumber + #a
		end
		return {block:toustring()}
	end
end

-- <A|B|C>
local function MakeStringFunction(array,funcs,bocknest)
	local f1 = MakeTemplateImpl(array[1],funcs,blocknest)
	local f2 = MakeTemplateImpl(array[2],funcs,blocknest)
	local f3 = MakeTemplateImpl(array[3],funcs,blocknest)
	if f1 == nil or f2 == nil or f3 == nil then return nil end
	return function(c)
		local x = U""
		for i = 1,#f2(c) do
			x = x .. f2(c)[i]
		end
		if not isempty(f2(c)) then
			return table_connect(table_connect(f1(c),f2(c)),f3(c))
		else
			return {U""}
		end
	end
end

-- $<A|B|C|...>
local function MakeFormatFunction(array,funcs)
	local ff = {}
	for i = 1,#array do
		local f = funcs[array[i]]
		if f == nil then
			ff[i] = function(f,c)
				local r = c.fields[array[i]]
				if r == nil then return nil
				elseif r.toustring ~= nil then return r:toustring()
				elseif type(r) == "string" then return U(r)
				else return r end
			end
		elseif type(f) ~= "function" then
			return nil
		else
			ff[i] = f
		end
	end
	return function(c)
		for i = 1,#ff do
			local s = ff[i](funcs,c)
			if s ~= nil then
				if type(s) == "table" then
					for i = 1,#s do
						if type(s[i]) == "string" then s[i] = U(s[i])
						elseif s[i].toustring ~= nil then s[i] = s[i]:toustring()
						end
					end
					if not isempty(s) then return s end
				else
					if type(s) == "string" then s = U(s)
					elseif s.toustring ~= nil then s = s:toustring()
					end
					if s ~= U"" then return {s} end
				end
			end
		end
		return {U""}
	end
end

function UnEscape(str)
	return str:gsub(U"%%(.)",U"%1")
end

MakeTemplateImpl = function(templ,funcs,blocknest)
	local bra = findUnescaped(templ,U"%[<",1)
	if bra == nil then
		return function(c) return string_to_array(UnEscape(templ)) end
	end
	if templ:sub(bra,bra) == U"[" then
		-- [A:B:...]
		local array,r = GetArrayOfBlocks(templ,U"[",U"]",U":",bra + 1)
		if r == nil then ------------------ syntax error
			LBibTeX.Template.LastMsg = U"template error found in " .. templ
			return nil
		end
		local f1 = MakeBlockFunction(array,funcs,blocknest)
		local f2 = MakeTemplateImpl(templ:sub(r),funcs,blocknest)
		if f1 == nil or f2 == nil then return nil end
		return function(c) return table_connect(table_connect(string_to_array(UnEscape(templ:sub(1,bra - 1))),f1(c)),f2(c)) end
	else
		local r1
		local r2 = 0
		while r2 ~= bra and r2 ~= nil do
			r1,r2 = templ:find(U"%%*$<",r2 + 1)
		end
		if r1 == nil or (r2 - r1) % 2 == 0 then
			-- <A|B|C>
			local array,r = GetArrayOfBlocks(templ,U"<",U">",U"|",bra + 1)
			if r == nil then ------------------ syntax error
				LBibTeX.Template.LastMsg = U"template error found in " .. templ
				return nil
			end
			if #array ~= 3 then ------------------ syntax error
				LBibTeX.Template.LastMsg = U"template error found in " .. templ
				return nil
			end
			local f1 = MakeStringFunction(array,funcs,blocknest)
			local f2 = MakeTemplateImpl(templ:sub(r),funcs,blocknest)
			if f1 == nil or f2 == nil then return nil end
			return function(c) return table_connect(table_connect(string_to_array(UnEscape(templ:sub(1,bra - 1))),f1(c)),f2(c)) end
		else
			-- $<A|B|...>
			local array,r = GetArrayOfBlocks(templ,U"<",U">",U"|",bra + 1)
			if r == nil then ------------------ syntax error
				LBibTeX.Template.LastMsg = U"template error found in " .. templ
				return nil
			end
			local f1 = MakeFormatFunction(array,funcs)
			local f2 = MakeTemplateImpl(templ:sub(r),funcs,blocknest)
			if f1 == nil or f2 == nil then return nil end
			return function(c) return table_connect(table_connect(string_to_array(UnEscape(templ:sub(1,bra - 2))),f1(c)),f2(c)) end
		end
	end
end


LBibTeX.Template.blockseparator = {}
LBibTeX.Template.blocklast = {}
LBibTeX.Template.LastMsg = U""

local function ModifyFunctions(funcs)
	local funcs_u = {}
	for k,v in pairs(funcs) do
		local kk
		if type(k) == "string" then kk = U(k) else kk = k end
		funcs_u[kk] = v
	end
	
	local ff = {}
	while true do
		local changed = false
		for k,v in pairs(funcs_u) do
			if type(v) ~= "function" then
				local f = LBibTeX.Template.make_from_str(v,funcs_u)
				if f ~= nil then
					ff[k] = function(dummy,c) return f(c) end
					changed = true
				else ff[k] = v end
			else ff[k] = v end
		end
		if not changed then break end
		funcs_u = ff
		ff = {}
	end
	local r = {}
	for k,v in pairs(ff) do
		r[U.encode(k)] = v
	end
	for k,v in pairs(r) do
		ff[k] = v
	end
	return ff
end

function LBibTeX.Template.make_from_str(templ,funcs)
	LBibTeX.Template.LastMsg = U""
	if type(templ) == "string" then templ = U(templ) end
	local f = MakeTemplateImpl(templ,funcs,1)
	if f == nil then
		print(LBibTeX.Template.LastMsg)
		return nil
	end
	return function(c)
		return array_to_string(f(c))
	end
end

function LBibTeX.Template.make(templs,funcs)
	local f = {}
	local ff
	local funcs_f = ModifyFunctions(funcs)
	for k,v in pairs(templs) do
		ff = LBibTeX.Template.make_from_str(v,funcs_f)
		if ff == nil then return nil end
		f[k] = ff
	end
	return f
end

