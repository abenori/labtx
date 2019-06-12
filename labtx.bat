@echo off
for /F "usebackq" %%i in (`kpsewhich labtx.lua`) do (
    set LABTXLUA="%%i"
)
texlua %LABTXLUA% %*
