@echo off
set PATH=C:\app\lua\bin;%PATH%
@echo on
luacheck --std lua52 labtx.lua labtx-core.lua labtx-crossref.lua labtx-database.lua labtx-default.lua labtx-funcs.lua labtx-item.lua labtx-options.lua labtx-template.lua --globals BibTeX kpse unicode
