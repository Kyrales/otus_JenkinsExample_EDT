@echo off
pwsh -NoProfile -File "%~dp0run-local-pipeline.ps1" %*
exit /b %ERRORLEVEL%
