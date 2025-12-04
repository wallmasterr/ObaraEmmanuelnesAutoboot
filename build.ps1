# Build script for ObaraEmmanuelnes emulator
# This script automates the CMake build process

Write-Host "Building ObaraEmmanuelnes emulator..." -ForegroundColor Green

# Check if CMake is available
$cmakePath = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmakePath) {
    Write-Host "Error: CMake is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install CMake from https://cmake.org/download/" -ForegroundColor Yellow
    exit 1
}

# Get the script directory (project root)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Create build directory if it doesn't exist
$buildDir = Join-Path $scriptDir "build"
if (-not (Test-Path $buildDir)) {
    Write-Host "Creating build directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Set-Location $buildDir

# Configure with CMake
Write-Host "Configuring project with CMake..." -ForegroundColor Cyan
$cmakeArgs = @("..")
$cmakeArgs += "-DCMAKE_BUILD_TYPE=Release"

# Try to detect Visual Studio
$vsPath = Get-ChildItem "C:\Program Files\Microsoft Visual Studio\" -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match "2022|2019|2017" } | 
    Sort-Object Name -Descending | 
    Select-Object -First 1

if ($vsPath) {
    Write-Host "Detected Visual Studio, using Visual Studio generator..." -ForegroundColor Cyan
    $vsVersion = if ($vsPath.Name -match "2022") { "Visual Studio 17 2022" }
                 elseif ($vsPath.Name -match "2019") { "Visual Studio 16 2019" }
                 elseif ($vsPath.Name -match "2017") { "Visual Studio 15 2017" }
                 else { "Visual Studio 17 2022" }
    $cmakeArgs += "-G"
    $cmakeArgs += $vsVersion
    $cmakeArgs += "-A"
    $cmakeArgs += "x64"
} else {
    Write-Host "No Visual Studio detected, using default generator..." -ForegroundColor Yellow
}

$configureResult = & cmake $cmakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake configuration failed!" -ForegroundColor Red
    exit 1
}

# Build the project
Write-Host "Building project..." -ForegroundColor Cyan
if ($vsPath) {
    $buildResult = & cmake --build . --config Release
} else {
    $buildResult = & cmake --build .
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild completed successfully!" -ForegroundColor Green

# Find the executable
$exePath = $null
if ($vsPath) {
    $exePath = Get-ChildItem -Path . -Filter "nes.exe" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.DirectoryName -match "Release|Debug" } | 
        Select-Object -First 1
} else {
    $exePath = Get-ChildItem -Path . -Filter "nes.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
}

if ($exePath) {
    Write-Host "Executable location: $($exePath.FullName)" -ForegroundColor Green
    Write-Host "`nTo run the emulator:" -ForegroundColor Cyan
    Write-Host "  $($exePath.FullName) path\to\game.nes" -ForegroundColor Yellow
} else {
    Write-Host "`nBuild completed, but executable not found in expected location." -ForegroundColor Yellow
    Write-Host "Please check the build directory manually." -ForegroundColor Yellow
}

Set-Location $scriptDir

