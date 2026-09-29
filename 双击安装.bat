@echo off
chcp 936 >nul 2>nul
title DSH / CODEX 破甲包 一键安装
cd /d "%~dp0"
echo ============================================================
echo   DSH / CODEX 破甲包 - 一键安装
echo   渠道: DSH 预设 + Codex 全局指令
echo ============================================================
echo.
echo 现在执行安装（已存在的内容会先备份，不会静默覆盖）...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Action install -Target both
echo.
echo ============================================================
echo  完成。请务必【完全退出并重启】DSH / Codex（关窗口不算），
echo  然后新建会话，发送 hi 验证是否生效。
echo ============================================================
echo.
pause
