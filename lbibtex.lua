local start_time = os.clock()
kpse.set_program_name("bibtex")
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
	local r = fullpath:find("[^/]*$")
	if r == nil then return fullpath
	else return fullpath:sub(r) end
end

BibTeX = LBibTeX.LBibTeX.new()
local b,msg = BibTeX:load_aux(file)
if b == false then print(msg) os.exit(1) end
BibTeX:message("The top-level auxiliary file: " .. get_filename(file))
local style = kpse.find_file("lbt-" .. BibTeX.style .. "_bst.lua","lua")
if style == nil then 
	BibTeX:error("style " .. BibTeX.style .. " is not found")
	os.exit(3)
end
BibTeX:message("The style file: " .. get_filename(style))

--local style_file_exec = loadfile(style,"t")
function style_file_exec()
	dofile(style)
end
xpcall(style_file_exec,function(e) print(debug.traceback(tostring(e))) os.exit(2) end)
BibTeX:dispose()
print("total time: " .. tostring(os.clock() - start_time) .. " sec")

