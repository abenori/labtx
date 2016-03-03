# lbibtex

BibTeX by Lua.

## Install
Of course, you need a TeX distribution. (TeXLive is recommended.)
Put *.lua at the directory where kpathsea can find the files. For example, under $TEXMF/scripts/lbibtex .

## Usage
For sample.tex, run

    texlua <path to lbibtex.lua> sample

instead of ``bibtex sample''. On Windows, it is convenient to save the following .bat at a directory in the PATH environment variable.

    @echo off
    for /F "usebackq" %%i in (`kpsewhich lbibtex.lua`) do (
        set LBIBTEXLUA="%%i"
    )
    texlua %LBIBTEXLUA% %1 %2 %3 %4 %5 %6 %7 %8 %9


