#!/usr/bin/env texlua

local start_time = os.clock()
kpse.set_program_name("texlua","bibtex")
local LBibTeX = require "lbt-core"

local option = (require "lbt-options").new()
local mincrossrefs = 2
local function show_help(options_msg)
	local msg = "Usage: lbibtex [option] auxfile"
	msg = msg .. "\n " .. options_msg:gsub("\n","\n ") .. "\n"
	io.stdout:write(msg)
end

option.options = {
   {"min-crossrefs=","include item after <NUM> cross-refs; default 2",function(n) mincrossrefs = n end,"number"},
   {"help","display this message and exit",function() show_help(option:helps()) os.exit(0) end}
}

local files,msg = option:parse(arg)
if files == nil then io.stderr:write("LBibTeX error: " .. msg) os.exit(1) end
if #files == 0 then io.stderr:write("no input file") os.exit(1) end

local first = true
for dummy,f in ipairs(files) do
	if f:sub(1,1) == "-" then goto continue end
	if first == true then first = false else io.stdout:write("\n") end
	if f:sub(-4,-1):lower() ~= ".aux" then f = f .. ".aux" end
	local file = kpse.find_file(f)
	if file == nil then
		io.stderr:write("can't open file `" .. f .. "'")
		goto continue
	end

	local function get_filename(fullpath)
		local r = fullpath:find("[^/]*$")
		if r == nil then return fullpath
		else return fullpath:sub(r) end
	end

	BibTeX = LBibTeX.new()
	BibTeX.crossref.mincrossrefs = mincrossrefs
	local b
	b,msg = BibTeX:load_aux(file)
	if b == false then io.stdout:write(msg .. "\n") os.exit(1) end
	BibTeX:message("The top-level auxiliary file: " .. get_filename(file))
	local style = kpse.find_file("lbt-" .. BibTeX.style .. "_bst.lua","lua")
	if style == nil then
		BibTeX:error("style " .. BibTeX.style .. " is not found")
		os.exit(3)
	end
	BibTeX:message("The style file: " .. get_filename(style))
	BibTeX:read_db()

	--local style_file_exec = loadfile(style,"t")
	local backup = {io = io,os = os}
	local function style_file_exec()
		io = nil
		os = nil
		dofile(style)
		io = backup.io
		os = backup.os
	end
	xpcall(style_file_exec,function(e) backup.io.stderr:write(debug.traceback(tostring(e)) .. "\n") backup.os.exit(2) end)
	BibTeX:dispose()
	::continue::
end
io.stdout:write("total time: " .. tostring(os.clock() - start_time) .. " sec\n")

