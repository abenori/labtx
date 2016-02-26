require "lbt-core"

local function addperiod(s)
	if s:find("%.[ ~]*$") == nil then return s .. "."
	else return s end
end

LBibTeX.bibitem = {}
function LBibTeX.bibitem.new(ref,label)
	local obj = {ref = ref, label = label}
	return setmetatable(obj,{__index = LBibTeX.bibitem, __tostring = LBibTeX.bibitem.tostring})
end

function LBibTeX.bibitem:toustring()
	local r = "\\bibitem"
	if self.label ~= nil then r = r .. "[" .. self.label .. "]" end
	return r .. "{" .. self.ref .. "}"
end

function LBibTeX.bibitem:tostring()
	return tostring(self:toustring())
end

LBibTeX.block = {}
function LBibTeX.block.new(sep, las, c)
	local obj = {defaultseparator = sep, last = las, contents = c, separators={}}
	if obj.defaultseparator == nil then obj.defaultseparator = "" end
	if obj.last == nil then obj.last = "" end
	if obj.contents == nil then obj.contents = {} end
	return setmetatable(obj,{__index = LBibTeX.block, __tostring = LBibTeX.block.tostring});
end

function LBibTeX.block:additem(c)
	table.insert(self.contents,c)
end

function LBibTeX.block:addarrayitem(c)
	for i = 1,#c do
		self:additem(c[i])
	end
end

function LBibTeX.block:setseparator(i,s)
	self.separators[i] = s
end

function LBibTeX.block:tostring()
	return tostring(self:toustring())
end

function LBibTeX.block:toustring()
	local r = ""
	for i = 1,#self.contents do
		local sep
		if self.separators[i] == nil then sep = self.defaultseparator
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
	if self.last:sub(1,1) == "." then
		r = addperiod(r) .. self.last:sub(2)
	else
		r = r .. self.last
	end
	return r
end


