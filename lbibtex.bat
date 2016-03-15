@echo off
for /F "usebackq" %%i in (`kpsewhich lbibtex.lua`) do (
    set LBIBTEXLUA="%%i"
)
texlua %LBIBTEXLUA% %*
