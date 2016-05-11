# lbibtex

BibTeX by Lua.

## Installation
You need TeX Live or W32TeX. Copy *.lua in the directory where kpathsea can find the files. For example, in $TEXMF/scripts/lbibtex .
- UNIX: create a link to lbibtex.lua in bin directory.
- TeX Live on Windows: create a copy of bin/win32/runscript.exe as bin/win32/lbibtex.exe .
- W32TeX: create a copy of bin/runscr.exe as bin/lbibtex.exe .

## Usage
For sample.tex, run

    lbibtex sample

instead of ``bibtex sample''.
