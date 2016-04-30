local Block = {}
-- separatorは二つの配列{A,B}からなる
-- A,Bが配列の時，searatorは前からA[1],A[2],...,A[#A],A[#A],...,B[1],...,B[#B]
-- 長さが足りないときはAが削られる
-- AやBが文字列の時は長さ1の配列と同じ扱い．

local function addperiod(s)
	if s:find("%.[ ~]*$") == nil then return s .. "."
	else return s end
end

function Block.new(sep, c)
	local obj = {defaultseparator = sep, contents = c, separators={}}
	if obj.defaultseparator == nil then obj.defaultseparator = {"",""} end
	if obj.contents == nil then obj.contents = {} end
	return setmetatable(obj,{__index = Block, __tostring = Block.tostring});
end

function Block:additem(c)
	table.insert(self.contents,c)
end

function Block:addarrayitem(c)
	for i = 1,#c do
		self:additem(c[i])
	end
end

function Block:setseparator(i,s)
	self.separators[i] = s
end

local function get_separator(seps,index,length)
	local a = seps[1]
	local b = seps[2]
	if type(a) ~= "table" then a = {tostring(a)} end
	if type(b) ~= "table" then b = {tostring(b)} end
	if index + #b > length then return b[#b + index - length]
	elseif index < #a then return a[index]
	else return a[#a]
	end
end

function Block:tostring()
	local r = ""
	for i = 1,#self.contents do
		local sep
		if self.separators[i] == nil then sep = get_separator(self.defaultseparator,i - 1,#self.contents)
		else sep = self.separators[i] end
		sep = tostring(sep);
		local periodfirst = false
		if sep ~= "" then
			if sep:sub(1,1) == "." then
				periodfirst = true
				sep = sep:sub(2)
			elseif sep:sub(1,1) == "\\" then
				sep = sep:sub(2)
			end
		end
		local c = self.contents[i]
		local s
		s = tostring(c)
		if s ~= "" then
			if r == "" then
				r = s
			else
				if periodfirst then
					r = addperiod(r) .. sep .. s
				else
					r = r .. sep .. s
				end
			end
		end
	end
	if r == "" then return "" end
	local last = get_separator(self.defaultseparator,#self.contents,#self.contents)
	if last:sub(1,1) == "." then
		r = addperiod(r) .. last:sub(2)
	else
		r = r .. last
	end
	return r
end

return Block
