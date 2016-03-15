# lbibtex

BibTeX by Lua.

## Install
First you insall some TeX system. (TeX Live is recommended.)
Put *.lua at the directory where kpathsea can find the files. For example, under $TEXMF/scripts/lbibtex .

## Usage
For sample.tex, run

    texlua <path to lbibtex.lua> sample

instead of ``bibtex sample''. You can also use a shell script lbibtex (or batch file lbibtex.bat if you are using Windows). Put it at some directory in PATH and run

    lbibtex sample

