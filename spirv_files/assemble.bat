@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: %0 input_file.spvasm
    exit /b 1
)

set "input=%~1"
set "output=%~dpn1.spv"

spirv-as --target-env vulkan1.1 "%input%" -o "%output%"

if %errorlevel% neq 0 (
    echo Compilation failed.
) 
