@echo off
chcp 65001 > nul
title Rhythm / VibeFlow Remote Server
cd /d "%~dp0backend"
python run_remote_server.py
pause
