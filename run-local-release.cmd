@echo off
pwsh -NoProfile -File "%~dp0run-local-release.ps1" %*
exit /b %ERRORLEVEL%
