local start_time = os.clock()
kpse.set_program_name("pbibtex")
local icu = require "lbt-string"
local U = icu.ustring
require "lbt-core"

local f = arg[1]
if f == nil then print("no input file") os.exit(1) end
if f:sub(-4,-1):lower() ~= ".aux" then f = f .. ".aux" end
local file = kpse.find_file(f)
if file == nil then
	print("can't open file `" .. f .. "'")
	os.exit(1)
end

local function get_filename(fullpath)
	if type(fullpath) == "string" then fullpath = U(fullpath) end
	local r = fullpath:find(U"[^/]*$")
	if r == nil then return fullpath
	else return fullpath:sub(r) end
end

BibTeX,msg = LBibTeX.LBibTeX.new(file)
if BibTeX == nil then print(msg) os.exit(1) end
BibTeX:message(U"The top-level auxiliary file: " .. get_filename(file))
local style = kpse.find_file(U.encode(BibTeX.style) .. "_bst.lua","lua")
if style == nil then 
	BibTeX:error(U"style " .. BibTeX.style .. U" is not found")
	os.exit(3)
end
BibTeX:message(U"The style file: " .. get_filename(style))

for i = 1,#BibTeX.bibs do
	local bib = kpse.find_file(U.encode(BibTeX.bibs[i],"Shift-JIS"),"bib")
	if bib == nil then 
		BibTeX:error(U"cannot find " .. BibTeX.bibs[i])
	else
		BibTeX.bibs[i] = U(bib,"Shift-JIS")
		BibTeX:message(U"Database file #" .. U(tostring(i)) .. U": " .. get_filename(BibTeX.bibs[i]))
	end
end

--local style_file_exec = loadfile(style,"t")
function style_file_exec()
	dofile(style)
end
xpcall(style_file_exec,function(e) print(debug.traceback(tostring(e))) os.exit(2) end)
BibTeX:dispose()
print("total time: " .. (os.clock() - start_time))

