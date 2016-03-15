@echo off
for /F "usebackq" %%i in (`kpsewhich lbibtex.lua`) do (
    set LBIBTEXLUA="%%i"
)
texlua %LBIBTEXLUA% %1 %2 %3 %4 %5 %6 %7 %8 %9
