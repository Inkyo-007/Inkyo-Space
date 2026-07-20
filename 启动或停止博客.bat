@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

rem ===== 双击此文件：未运行则启动博客，已运行则停止博客 =====

set "ROOT=%~dp0"
set "PORT=4321"
set "RUNNING=0"

rem ----- 检测服务器是否在运行（PID 文件 + 端口双重判断） -----
if exist ".dev-server.pid" (
    set /p SERVER_PID=<".dev-server.pid"
    tasklist /FI "PID eq !SERVER_PID!" /NH 2>nul | findstr /C:"!SERVER_PID!" >nul && set "RUNNING=1"
)
netstat -ano | findstr /C:":%PORT% " | findstr /C:"LISTENING" >nul && set "RUNNING=1"

if "%RUNNING%"=="1" goto stop_server

:start_server
echo ============================================
echo   正在后台启动博客开发服务器...
echo ============================================
if not exist "logs" mkdir "logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root = $env:ROOT; $port = [int]$env:PORT; $p = Start-Process -FilePath 'pnpm.cmd' -ArgumentList 'dev' -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $root 'logs/dev-server.log') -RedirectStandardError (Join-Path $root 'logs/dev-server.err.log') -PassThru; Set-Content (Join-Path $root '.dev-server.pid') $p.Id; $ok = $false; for ($i = 0; $i -lt 30; $i++) { Start-Sleep -Seconds 1; if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) { $ok = $true; break }; if ($p.HasExited) { break } }; if ($ok) { Write-Host ('开发服务器已启动 (PID: ' + $p.Id + ')'); Write-Host ('访问地址: http://localhost:' + $port); Write-Host '日志文件: logs/dev-server.log' } else { Write-Host '服务器未能就绪，请查看 logs 目录下的日志文件' }"
goto end

:stop_server
echo ============================================
echo   正在停止博客开发服务器...
echo ============================================
if exist ".dev-server.pid" (
    set /p SERVER_PID=<".dev-server.pid"
    taskkill /PID !SERVER_PID! /T /F >nul 2>&1
    del ".dev-server.pid" >nul 2>&1
)
rem ----- 兜底：结束仍占用端口的残留进程 -----
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:":%PORT% " ^| findstr /C:"LISTENING"') do (
    taskkill /PID %%a /T /F >nul 2>&1
)
echo 开发服务器已停止。

:end
echo.
pause
