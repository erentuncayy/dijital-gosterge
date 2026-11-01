@echo off
REM Bilgisayar her acildiginda PC-Telemetri otomatik baslasin
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Startup')+'\PC-Telemetri.lnk'); $s.TargetPath='%~dp0Baslat.bat'; $s.WorkingDirectory='%~dp0'; $s.WindowStyle=7; $s.Save()"
echo.
echo PC-Telemetri baslangica eklendi. Simdi de baslatiliyor...
call "%~dp0Baslat.bat"
echo Tamam. Bu pencereyi kapatabilirsin.
pause
