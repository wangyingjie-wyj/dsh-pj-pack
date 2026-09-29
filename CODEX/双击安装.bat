@echo off
chcp 936 >nul
title AI-PJ v1.1 - Codex 一键安装
cd /d "%~dp0"
echo ============================================
echo   AI-PJ v1.1 · Codex 一键安装
echo   （双击即装，无需输入任何命令）
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Unblock-File -Path '.\install.ps1','.\ai-pj-v1.0-codex.md' -ErrorAction SilentlyContinue } catch {}; & '.\install.ps1' -Action install"
echo.
echo ============================================
echo   安装完成。接下来只需三步：
echo   1. 完全退出并重启 Codex
echo   2. 打开一个新会话
echo   3. 发送：hi
echo   看到「AI-PJ v1.0 已就绪」即生效！
echo ============================================
echo.
pause
