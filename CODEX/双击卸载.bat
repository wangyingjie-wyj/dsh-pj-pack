@echo off
chcp 936 >nul
title AI-PJ v1.1 - Codex 一键卸载
cd /d "%~dp0"
echo ============================================
echo   AI-PJ v1.1 · Codex 一键卸载
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -Path '.\install.ps1' -ErrorAction SilentlyContinue } catch {}; & '.\install.ps1' -Action uninstall"
echo.
echo ============================================
echo   卸载完成。原有文件已自动备份
echo   （*.bak-aipj-*），需要时可还原。
echo ============================================
echo.
pause
