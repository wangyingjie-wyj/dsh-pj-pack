@echo off
chcp 936 >nul 2>nul
title DSH / CODEX 破甲包 一键卸载
cd /d "%~dp0"
echo ============================================================
echo   DSH / CODEX 破甲包 - 一键卸载
echo   只删除本包写入的内容，不会动你自己的配置
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Action uninstall -Target both
echo.
echo 完成。重启 DSH / Codex 后生效。
echo.
pause
