# lbibtex

BibTeX by Lua.

## Install
Of course, you need TeX distribution. (TeXLive is recommended.)
You also need [ICU4Lua]<https://github.com/duncanc/icu4lua>. A Windows binary can be downloaded from [here]<http://1drv.ms/1SZia0m>. It is build with the patch icu4lua.patch and this is for Lua 5.2. (The same as used in TeXLive 2014.)

1. Put ICU4Lua at bin directory of TeX distribution.
2. Put *.lua at the directory where kpathsea can find the files. For example, under $TEXMF/scripts/lbibtex .

## Usage
For sample.tex, run
 texlua <path to lbibtex.lua> sample
instead of ``bibtex sample''. On Windows, it is convenient to save the following .bat at a directory in the PATH environment variable.

 @echo off
 for /F "usebackq" %%i in (`kpsewhich lbibtex.lua`) do (
     set LBIBTEXLUA="%%i"
 )
 texlua %LBIBTEXLUA% %1 %2 %3 %4 %5 %6 %7 %8 %9



