#!/usr/bin/env texlua

local start_time = os.clock()
kpse.set_program_name("texlua","bibtex")
local labtx = require "labtx-core"
local labtxdebug = require "labtx-debug"

local option = (require "labtx-options").new()
local mincrossrefs = 2
local function show_help(options_msg)
	local msg = "Usage: labtx [option] auxfile[.aux]"
	msg = msg .. "\n " .. options_msg:gsub("\n","\n ") .. "\n"
	io.stdout:write(msg)
end

local doctypename = "latex"
local defstyle = nil

option.options = {
   {"min-crossrefs=","include item after <NUM> cross-refs; default 2",function(n) mincrossrefs = n end,"number"},
   {"help","display this message and exit",function() show_help(option:helps()) os.exit(0) end},
   {"type=",function(s) doctypename = s end,"string"},
   {"style=","specify the style",function(s) defstyle = s end,"string"},
   {"debug",function() labtxdebug.debugmode = true end}
}

local files,msg = option:parse(arg)
if files == nil then io.stderr:write("labtx error: " .. msg .. "\n") os.exit(1) end

local doctype = require ("labtx-" .. doctypename .. "_type")
if doctype == nil then
	io.stderr:write("can't find the document type " .. doctypename .. "\n")
	os.exit(1)
end

local function get_filename(fullpath)
	local r = fullpath:find("[^/]*$")
	if r == nil then return fullpath
	else return fullpath:sub(r) end
end

local first = true
for _,f in ipairs(files) do
	if f:sub(1,1) == "-" then goto continue end
	if first == true then first = false else io.stdout:write("\n") end

	BibTeX = labtx.new(doctype)
	local b,msg = BibTeX:load_aux(f)
	if b == false then io.stderr:write(msg .. "\n") goto continue end
	BibTeX:message("The top-level auxiliary file: " .. get_filename(BibTeX.aux_file))
--	BibTeX.crossref.mincrossrefs = mincrossrefs
	if defstyle ~= nil then BibTeX.style = defstyle end
	if BibTeX.style == nil then BibTeX:error("style is not specified") goto continue end
	local style = kpse.find_file("labtx-" .. BibTeX.style .. "_bst.lua","lua")
	if style == nil then
		BibTeX:error("style " .. BibTeX.style .. " is not found",3)
		goto continue 
	end
	BibTeX:message("The style file: " .. get_filename(style))
	local b,m = BibTeX:read_db()
	if b == false then BibTeX:error(m .. "\n",1) end
	BibTeX.mode = 0

	--local style_file_exec = loadfile(style,"t")
	local backup = {io = io,os = os}
	local function style_file_exec()
--		io = nil
--		os = nil
		local sty = dofile(style)
		if BibTeX.mode == 0 then BibTeX:outputthebibliography(sty) end
		io = backup.io
		os = backup.os
	end
	xpcall(style_file_exec,function(e) backup.io.stderr:write(debug.traceback(tostring(e),2) .. "\n") io = backup.io os = backup.os end)
	BibTeX:dispose()
	::continue::
end
if first == true then io.stderr:write("no input file\n") os.exit(1) end
io.stdout:write("total time: " .. tostring(os.clock() - start_time) .. " sec\n")


