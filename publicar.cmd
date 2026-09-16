@echo off
rem Doble clic para publicar/actualizar el portafolio en GitHub Pages.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publicar.ps1" %*
pause
