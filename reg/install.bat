@echo off
setlocal EnableDelayedExpansion

set "REPO=hefy2027/cf-manager"
set "RAW_URL=https://raw.githubusercontent.com/%REPO%/master/reg"
set "INSTALL_DIR=%CD%"
set "MIN_NODE_VERSION=20"

echo ==================================================
echo   Cloudflare Batch Registration Tool - Installer
echo ==================================================
echo.

REM -- Check Node.js --
echo [1/4] Checking Node.js...
where node >nul 2>&1
if errorlevel 1 (
    echo [ERR] Node.js not found. Please install Node.js ^>= %MIN_NODE_VERSION%
    echo       Visit: https://nodejs.org
    pause
    exit /b 1
)

for /f "tokens=1 delims=." %%v in ('node -v') do set "NODE_VER=%%v"
set "NODE_VER=%NODE_VER:v=%"
if %NODE_VER% LSS %MIN_NODE_VERSION% (
    echo [ERR] Node.js v%NODE_VER% is too old. Requires ^>= v%MIN_NODE_VERSION%
    echo       Visit: https://nodejs.org
    pause
    exit /b 1
)

echo [OK] Node.js v%NODE_VER% detected

REM -- Check npm --
echo [2/4] Checking npm...
where npm >nul 2>&1
if errorlevel 1 (
    echo [ERR] npm not found. Please reinstall Node.js
    pause
    exit /b 1
)
echo [OK] npm detected

REM -- Download / verify files --
echo [3/4] Preparing files...

if not exist "%INSTALL_DIR%\cf-reg.mjs" (
    echo        Downloading cf-reg.mjs...
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%RAW_URL%/cf-reg.mjs', '%INSTALL_DIR%\cf-reg.mjs')"
) else (
    echo        cf-reg.mjs already exists, skip download
)

if not exist "%INSTALL_DIR%\config.json" (
    echo        Downloading config.json...
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%RAW_URL%/config.example.json', '%INSTALL_DIR%\config.json')"
) else (
    echo        config.json already exists, skip download
)

REM -- Create cf-reg.cmd wrapper --
echo Creating cf-reg.cmd wrapper...
(
echo @echo off
echo node "%INSTALL_DIR%\cf-reg.mjs" %%*
) > "%INSTALL_DIR%\cf-reg.cmd"

echo [OK] Files ready in %INSTALL_DIR%

REM -- Install dependencies --
echo [4/4] Installing dependencies...
cd /d "%INSTALL_DIR%"
echo {"name":"cf-reg-local","version":"1.0.0","type":"module"} > package.json
call npm install --no-save cloakbrowser commander node-fetch playwright-core 2>nul
if errorlevel 1 (
    echo [WARN] Failed to install some dependencies. Run manually:
    echo        cd %INSTALL_DIR% ^&^& npm install cloakbrowser commander node-fetch playwright-core
) else (
    echo [OK] Dependencies installed
)

REM -- Pre-download Stealth Chromium for cloakbrowser --
echo [INFO] Pre-downloading Stealth Chromium (this may take a while)...

REM Create a temporary script to trigger Chromium download
(
echo import { launch } from 'cloakbrowser';
echo.
echo async function downloadChromium() {
echo     console.log('[Download] Starting Chromium download...');
echo     try {
echo         const browser = await launch({
echo             headless: true,
echo             args: ['--no-sandbox', '--disable-setuid-sandbox']
echo         });
echo         console.log('[Download] Chromium downloaded successfully!');
echo         await browser.close();
echo         process.exit(0);
echo     } catch (error) {
echo         console.error('[Download] Failed to pre-download Chromium:', error.message);
echo         console.log('[Download] Chromium will be downloaded on first use instead.');
echo         process.exit(0);
echo     }
echo }
echo.
echo downloadChromium();
) > "%INSTALL_DIR%\.download-chromium.mjs"

REM Run the download script
echo        Downloading... (see progress above)
node "%INSTALL_DIR%\.download-chromium.mjs" 2>&1 | findstr /v "^$"

REM Clean up
del "%INSTALL_DIR%\.download-chromium.mjs" 2>nul

echo [OK] Chromium pre-download step completed

echo.
echo ==================================================
echo   Installation complete!
echo ==================================================
echo.
echo Usage:
echo   cf-reg --help
echo   cf-reg --count 5
echo.
echo Config:
echo   Edit config.json to customize settings
echo.
echo CF Manager: https://github.com/%REPO%
echo.
pause
