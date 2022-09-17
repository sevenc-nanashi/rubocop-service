@echo off
cd %DIRECTORY%
set RUBOCOP_SERVICE_SERVER_PROCESS=true
rubocop --start-server
