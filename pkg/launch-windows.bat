@ECHO OFF

cd %~dp0

:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
bin\win64\colorful.exe %*
GOTO END

:32BIT
bin\win32\colorful.exe %*
GOTO END

:END
