@echo off
chcp 65001 >nul
title 定时关机助手（按时间）
color 0A

:menu
cls
echo ==============================
echo         定时关机助手
echo ==============================
echo 1. 设置定时关机（输入具体时间，格式 HH:MM，例如 22:00）
echo 2. 取消已设定的定时关机
echo 3. 退出
echo ==============================
set /p choice=请选择（1/2/3）: 

if "%choice%"=="1" goto set_shutdown_time
if "%choice%"=="2" goto cancel_shutdown
if "%choice%"=="3" exit
echo 输入无效，请重新选择！
pause
goto menu

:set_shutdown_time
cls
echo 请输入要关机的具体时间（24小时制，格式 HH:MM，例如 22:00）：
set /p target_time=

:: 验证输入格式：HH:MM，且HH 00-23，MM 00-59
echo %target_time%|findstr /r "^[0-2][0-9]:[0-5][0-9]$" >nul
if errorlevel 1 (
    echo 输入格式错误！请确保输入为 HH:MM 格式，且小时00-23，分钟00-59。
    pause
    goto set_shutdown_time
)

:: 解析输入的小时和分钟
set "input_hh=%target_time:~0,2%"
set "input_mm=%target_time:~3,2%"
:: 去除前导零（防止被当作八进制）
set /a input_hh=1%input_hh% - 100
set /a input_mm=1%input_mm% - 100

:: 获取当前系统时间（通过wmic，24小时制）
setlocal enabledelayedexpansion
for /f "skip=1 tokens=*" %%a in ('wmic os get localtime 2^>nul') do (
    set "localtime=%%a"
    goto :got_time
)
:got_time
if not defined localtime (
    echo 无法获取系统时间，请稍后重试或检查 wmic 命令是否可用。
    pause
    goto menu
)
set "datetime=!localtime:~0,14!"
set "current_hh=!datetime:~8,2!"
set "current_mm=!datetime:~10,2!"
set /a current_hh=1!current_hh! - 100
set /a current_mm=1!current_mm! - 100

:: 计算当前时间和目标时间的分钟数（从午夜开始）
set /a current_total=current_hh*60 + current_mm
set /a target_total=input_hh*60 + input_mm

:: 如果目标时间小于当前时间，则视为明天
if %target_total% leq %current_total% (
    set /a target_total+=24*60
)

:: 计算时间差（秒）
set /a diff_seconds=(target_total - current_total)*60

echo 当前时间：!current_hh!:!current_mm!
echo 目标时间：%input_hh%:%input_mm%
echo 将在 %diff_seconds% 秒后（约 %diff_seconds% 秒）关机。

:: 设置定时关机
shutdown /s /t %diff_seconds% /c "定时关机已设置，将在 %input_hh%:%input_mm% 关闭电脑。"

echo 定时关机已设定。
echo.
pause
goto menu

:cancel_shutdown
cls
shutdown /a
if errorlevel 1 (
    echo 没有找到正在进行的定时关机任务，或取消失败。
) else (
    echo 已成功取消定时关机。
)
echo.
pause
goto menu