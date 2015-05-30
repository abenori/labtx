kpse.set_program_name("pbibtex")
local U = require"icu.ustring"
require "lbt-core"

local f = arg[1]
if f == nil then print("no input file") os.exit(1) end
local file = kpse.find_file(f .. ".aux")
if file == nil then
	file = kpse.find_file(f)
end
if file == nil then
	print("can't open file `" .. f .. "'")
	os.exit(1)
end

BibTeX = LBibTeX.LBibTeX.new(file)

for i = 1,#BibTeX.bibs do
	local bib = kpse.find_file(U.encode(BibTeX.bibs[i],"Shift-JIS"),"bib")
	if bib == nil then 
		print("cannot find " .. BibTeX.bibs[i])
	else
		BibTeX.bibs[i] = U(bib,"Shift-JIS")
	end
end

local style = kpse.find_file(U.encode(BibTeX.style) .. "_bst.lua","lua")
if style == nil then 
	print("style " .. BibTeX.style .. " is not found")
	os.exit(3)
end

--local style_file_exec = loadfile(style,"t")
function style_file_exec()
	dofile(style)
end
xpcall(style_file_exec,function(e) print(debug.traceback(tostring(e))) os.exit(2) end)
BibTeX:dispose()
