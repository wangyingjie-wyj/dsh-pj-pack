@echo off
chcp 936 >nul 2>nul
title 把破甲包推送到我的 GitHub
cd /d "%~dp0"
echo ============================================================
echo   推送到 GitHub
echo   需要: 仓库地址 + Personal Access Token (勾选 repo 权限)
echo   Token 生成: https://github.com/settings/tokens
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0push-to-github.ps1"
