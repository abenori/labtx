# labtx

BibTeX by Lua.

## Installation
You need TeX Live or W32TeX. Copy *.lua in the directory where kpathsea can find the files. For example, in $TEXMF/scripts/labtx .
- UNIX: create a link to labtx.lua in bin directory.
- TeX Live on Windows: create a copy of bin/win32/runscript.exe as bin/win32/labtx.exe .
- W32TeX: create a copy of bin/runscr.exe as bin/labtx.exe .

## Usage
For sample.tex, run

    labtx sample

instead of ``bibtex sample''.
