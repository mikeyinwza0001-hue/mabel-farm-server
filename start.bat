@echo off
title Rice Farm Server

:: ─── Java Configuration ──────────────────────────────────────────────────────
set JAVA_EXE=java
if exist "jre\bin\java.exe" (
    set JAVA_EXE="jre\bin\java.exe"
    echo [!] Using bundled JRE...
)

:: ─── Start Server ────────────────────────────────────────────────────────────
%JAVA_EXE% -Xms2G -Xmx4G -jar paper.jar --nogui

if %ERRORLEVEL% neq 0 (
    echo.
    echo [!] Server exited with error code %ERRORLEVEL%
    echo [!] Please make sure you have Java 17 or higher installed.
    echo [!] You can download it from: https://adoptium.net/
    pause
)