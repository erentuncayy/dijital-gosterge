@echo off
REM PC-Telemetri'yi arka planda (penceresiz) baslatir
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0PC-Telemetri.ps1"
