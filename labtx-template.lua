local Template = {}

local Block = require "labtx-block"

--[[
書式をあたえるとスタイルを生成してくれるようにする．
こんな感じ．
[**:**:**]：ブロック．あたえられた結合文字列を使って結合される．空文字列は無視される．ネスト可能．Template.blockseparator[nest]で結合部分/最後の文字列をどうにかできる．ピリオドは連続しないように処理される．:@S<***>とするとそこの区切り文字を***に変更する．
<(LEFT)|(STR)|(RIGHT)>：STR != ""ならば(LEFT)(STR)(RIGHT)を出す，STR==""ならば空文字列
$<A|B|C|...>：関数Aが呼び出され，その値が空ならばBが呼び出され……となり，最初に空でないものが出力される．関数Aが見付からない場合は名前がAのfieldが呼ばれる．（例えば，$<title>は関数 titleが定義されていなければタイトルそのものがでる．）Aの代わりに(A)とするとAはテンプレートとして解釈される．
全ては%でエスケープできる．
]]

--[[
中間データは文字列の配列で表す．
* block生成の時に配列をblockと解釈
* 文字列連結の時は，最初と最後を文字列つぃて連結する
とすればよいだろうか．

ユーザ定義関数は配列を渡すことで，ブロックの区切りを明示することができる．


Template.new(separators)
separators: 文字列からなる配列．
戻り値: Template
新しいオブジェクトを返す．ブロックのセパレータはseparatorsが使われる．

Template:make(template,formatters)
template: 文字列
formatters: 関数からなるテーブル
戻り値: 関数

templateにはtemplate = "[$<author>:$<title>:...]"のような文字列を与える．
これに対して，戻り値funcには整形関数が入る．これはbibフィールドを与えると文字列を返す関数である．

templatesで指定できる書式は以下の通り．
-- [**:**:**]：ブロック．あたえられた結合文字列を使って結合される．空文字列は無視される．ネスト可能．Template.blockseparator[nest]で結合部分/最後の文字列をどうにかできる．ピリオドは連続しないように処理される．:@S<***>とするとそこの区切り文字を***に変更する．
-- <(LEFT)|(STR)|(RIGHT)>：STR != ""ならば(LEFT)(STR)(RIGHT)を出す，STR==""ならば空文字列
-- $<A|B|C|...>：formatters:Aが呼び出され，その値が空ならばformatters:Bが呼び出され……となり，最初に空でないものが出力される．関数formatters:Aが見付からない場合は名前がAのfieldが呼ばれる．（例えば，$<title>は関数formatters:titleが定義されていなければタイトルそのものがでる．）Aの代わりに(A)とするとAはテンプレートとして解釈される．
全ては%でエスケープできる．

formattersには各々の項目を整形する関数を指定する．その書式は以下の通り．
formatters:<field>(cite)
cite: 文献データ
戻り値: 文字列
]]

local function isempty(array)
	for i = 1,#array do
		if array[i] ~= nil and array[i] ~= "" then return false end
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
		p1,p2 = str:find("%%*[" .. chars .. "]",p2)
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
	if s == nil or s == "" then return {""}
	else return {s} end
end

local function array_to_string(a)
	local r = ""
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
	if sep ~= nil then search = (beg .. en .. sep):gsub("[%[%]]","%%%1")
	else search = (beg .. en):gsub("[%[%]]","%%%1") end
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

-- [A:B:C:...]
function Template:MakeBlockFunction(array,funcs,blocknest)
	local f = {}
	local seps = {}
	for i = 1,#array do
		if i > 1 then
			if array[i]:sub(1,1) == "@" then
				if array[i]:sub(2,2) == "S" then 
					local a,r = GetArrayOfBlocks(array[i],"<",">",nil,4)
					if a == nil then return nil end
					seps[i] = self:MakeTemplateImpl(a[1],funcs,blocknest + 1)
					array[i] = array[i]:sub(r)
				end
			end
		end
		local ff = self:MakeTemplateImpl(array[i],funcs,blocknest + 1)
		if ff == nil then return nil end
		table.insert(f,ff)
	end
	return function(c)
		local block = Block.new(self.blockseparator[blocknest])
		local sepnumber = 1
		for i = 1, #f do
			local a = f[i](c)
			block:addarrayitem(a)
			if i > 1 and seps[i] ~= nil then block:setseparator(sepnumber,array_to_string(seps[i](c))) end
			sepnumber = sepnumber + #a
		end
		return {block:tostring()}
	end
end

-- <A|B|C>
function Template:MakeStringFunction(array,funcs,blocknest)
	local f1 = self:MakeTemplateImpl(array[1],funcs,blocknest)
	local f2 = self:MakeTemplateImpl(array[2],funcs,blocknest)
	local f3 = self:MakeTemplateImpl(array[3],funcs,blocknest)
	if f1 == nil or f2 == nil or f3 == nil then return nil end
	return function(c)
		local x = ""
		local t2 = f2(c)
		for i = 1,#t2 do
			x = x .. t2[i]
		end
		if not isempty(t2) then
			return table_connect(table_connect(f1(c),t2),f3(c))
		else
			return {""}
		end
	end
end

-- $<A|B|C|...>
function Template:MakeFormatFunction(array,funcs,blocknest)
	local ff = {}
	for i = 1,#array do
		if array[i]:sub(1,1) == "(" and array[i]:sub(-1) == ")" then
			local f = self:MakeTemplateImpl(array[i]:sub(2,-2),funcs,blocknest)
			if f == nil then return nil end
			ff[i] = function(dummy,c)
				return f(c)
			end
		else
			if array[i]:sub(1,2) == "%(" then array[i] = array[i]:sub(2) end
			if array[i]:sub(-2,-1) == "%)" then array[i] = array[i]:sub(1,-3) .. ")" end
			local f = funcs[array[i]]
			if type(f) ~= "function" then
				ff[i] = function(dummy,c)
					local r = c.fields[array[i]]
					if r == nil then return nil
					else return tostring(r) end
				end
			else
				ff[i] = f
			end
		end
	end
	return function(c)
		for i = 1,#ff do
			local s = ff[i](funcs,c)
			if s ~= nil then
				if type(s) == "table" then
					if not isempty(s) then return s end
				else
					if s ~= "" then return {s} end
				end
			end
		end
		return {""}
	end
end

local function UnEscape(str)
	return str:gsub("%%(.)","%1")
end

Template.MakeTemplateImpl = function(self,templ,funcs,blocknest)
	local bra = findUnescaped(templ,"%[<",1)
	if bra == nil then
		return function(dummy) return string_to_array(UnEscape(templ)) end
	end
	if templ:sub(bra,bra) == "[" then
		-- [A:B:...]
		local array,r = GetArrayOfBlocks(templ,"[","]",":",bra + 1)
		if r == nil then ------------------ syntax error
			Template.LastMsg = "template error in " .. templ
			return nil
		end
		local f1 = self:MakeBlockFunction(array,funcs,blocknest)
		local f2 = self:MakeTemplateImpl(templ:sub(r),funcs,blocknest)
		if f1 == nil then 
			Template.LastMsg = "template error in " .. table.concat(array," ")
			return nil
		end
		if f2 == nil then return nil end
		return function(c) return table_connect(table_connect(string_to_array(UnEscape(templ:sub(1,bra - 1))),f1(c)),f2(c)) end
	else
		local r1
		local r2 = 0
		while r2 ~= bra and r2 ~= nil do
			r1,r2 = templ:find("%%*$<",r2 + 1)
		end
		if r1 == nil or (r2 - r1) % 2 == 0 then
			-- <A|B|C>
			local array,r = GetArrayOfBlocks(templ,"<",">","|",bra + 1)
			if r == nil then ------------------ syntax error
				Template.LastMsg = "template error in " .. templ
				return nil
			end
			if #array ~= 3 then ------------------ syntax error
				Template.LastMsg = "template error in " .. templ
				return nil
			end
			local f1 = self:MakeStringFunction(array,funcs,blocknest)
			local f2 = self:MakeTemplateImpl(templ:sub(r),funcs,blocknest)
			if f1 == nil then 
				Template.LastMsg = "template error in " .. table.concat(array," ")
				return nil
			end
			if f2 == nil then return nil end
			return function(c) return table_connect(table_connect(string_to_array(UnEscape(templ:sub(1,bra - 1))),f1(c)),f2(c)) end
		else
			-- $<A|B|...>
			local array,r = GetArrayOfBlocks(templ,"<",">","|",bra + 1)
			if r == nil then ------------------ syntax error
				Template.LastMsg = "template error in " .. templ
				return nil
			end
			local f1 = self:MakeFormatFunction(array,funcs,blocknest)
			local f2 = self:MakeTemplateImpl(templ:sub(r),funcs,blocknest)
			if f1 == nil then 
				Template.LastMsg = "template error in " .. table.concat(array," ")
				return nil
			end
			if f2 == nil then return nil end
			return function(c) return table_connect(table_connect(string_to_array(UnEscape(templ:sub(1,bra - 2))),f1(c)),f2(c)) end
		end
	end
end


Template.LastMsg = ""


function Template:modify_formatters(funcs)
	if type(funcs) ~= "table" then 
		return nil,"Template.make: type error, type(formatters) = " .. type(funcs)
	end
	local ff = {}
	while true do
		local changed = false
		for k,v in pairs(funcs) do
			if type(v) ~= "function" then
				local f = self:make_from_str(v,funcs)
				if f ~= nil then
					ff[k] = function(dummy,c) return f(c) end
					changed = true
				else
					return nil,Template.LastMsg
				end
			else ff[k] = v end
		end
		if not changed then break end
		funcs = ff
		ff = {}
	end
	return ff
--	local r = {}
--	for k,v in pairs(ff) do
--		r[k] = v
--	end
--	for k,v in pairs(r) do
--		ff[k] = v
--	end
end

function Template:make_from_str(templ,funcs)
	Template.LastMsg = ""
	local f = self:MakeTemplateImpl(templ,funcs,1)
	if f == nil then
		return nil,Template.LastMsg
	end
	return function(c)
		return array_to_string(f(c))
	end
end

function Template:make(templ,funcs)
	if type(templ) ~= "string" or type(funcs) ~= "table" then
		return nil,"Template.make: type error, type(templates) = " .. type(templ) .. ", type(formatters) = " .. type(funcs)
	end
	return self:make_from_str(templ,funcs)
end

function Template.new(separators)
	local obj = {blockseparator = {}}
	if separators ~= nil then obj.blockseparator = separators end
	return setmetatable(obj,{__index = Template})
end

return Template

--local blocknest = 1
--
--function Template:make_block(table)
--	return function(c)
--		local block = Block.new(self.blockseparator[blocknest])
--		local sepnumber = 1
--		for i = 0, #table / 2 - 1 do
--			local a = table[2*i + 1](c)
--			block:addarrayitem(a)
--			if i > 1 and table[2 * i] ~= nil then block:setseparator(sepnumber,array_to_string(table[2*i](c))) end
--			sepnumber = sepnumber + #a
--		end
--		return {block:tostring()}
--	end
--end
--
--function Template:make_format(table)
--	local ff = {}
--	for i,func in ipairs(table) do
--		local f = self.formatters[table[i]]
--		if type(f) ~= "function" then
--			ff[i] = function(dummy,c)
--				local r = c.fields[table[i]]
--				if r == nil then return nil
--				else return tostring(r) end
--			end
--		else
--			ff[i] = f
--		end
--	end
--	return function(c)
--		for i = 1,#table do
--			local s = ff[i](self.formatters,c)
--			if s ~= nil then
--				if type(s) == "table" then
--					if not isempty(s) then return s end
--				else
--					if s ~= "" then return {s} end
--				end
--			end
--		end
--		return {""}
--	end
--end
--
--local template = lpeg.V("template")
--local block = lpeg.V("block")
--local blocksep = lpeg.V("blocksep")
--local format = lpeg.V("func")
--local isempty = lpeg.V("isempty")
--local funcname = lpeg.C((1 - lpeg.S("|>"))^1)
--local str = lpeg.Cf((lpeg.C((1 - lpeg.S("[]|%:<>") - lpeg.P("$<"))^1) + ("%" * lpeg.C(lpeg.S("[]|%:<>"))) + ("%$" * lpeg.C("<")))^1,function(a,b) return a .. b end)
--
--local p = lpeg.P{
--	"main";
--	main = template * (1 * lpeg.Cc(nil))^(-1),
--	template = lpeg.Ct((block + format + isempty + (str / function(s) return function(c) return s end end))^0) / Template.make_template,
--	block = (lpeg.Carg(1) * lpeg.Ct("[" * template * (":" * blocksep * template)^0 * "]")) / Template.make_block,
--	blocksep = ("@<" * lpeg.C(str) * ">") + lpeg.Cc(nil),
--	format = (lpeg.Carg(1) * lpeg.Ct("$<" * (funcname * "|")^0 * funcname * ">")) / Template.make_format,
--	isempty = (lpeg.Carg(1) * "<" * template * "|" * template * "|" * template * ">") / Template.make_threeargtemplate
--}
