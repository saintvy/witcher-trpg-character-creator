@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
for %%i in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fi"
set "AWS_PROFILE_NAME=pal-iamic-admin"

call :check_tools || exit /b 1
call :ensure_dependencies || exit /b 1
call :build_cloud || exit /b 1
call :ensure_sso || exit /b 1
call :deploy_cloud || exit /b 1

echo [start-prod] Done.
exit /b 0

:check_tools
where npm >nul 2>&1
if errorlevel 1 (
  echo [start-prod] npm is not available in PATH.
  exit /b 1
)
where aws >nul 2>&1
if errorlevel 1 (
  echo [start-prod] AWS CLI is not available in PATH.
  exit /b 1
)
exit /b 0

:ensure_dependencies
echo [start-prod] Checking dependencies...
if not exist "%ROOT_DIR%\node_modules" (
  echo [start-prod] node_modules not found. Installing...
  pushd "%ROOT_DIR%" >nul
  call npm install
  if errorlevel 1 (
    popd >nul
    echo [start-prod] npm install failed.
    exit /b 1
  )
  popd >nul
)
exit /b 0

:build_cloud
echo [start-prod] Building app artifacts...
pushd "%ROOT_DIR%" >nul
call npm run build
if errorlevel 1 (
  popd >nul
  echo [start-prod] npm run build failed.
  exit /b 1
)
call npm --workspace @wcc/infra run build
if errorlevel 1 (
  popd >nul
  echo [start-prod] infra build failed.
  exit /b 1
)
popd >nul
exit /b 0

:ensure_sso
echo [start-prod] Checking AWS SSO session for profile %AWS_PROFILE_NAME%...
aws sts get-caller-identity --profile %AWS_PROFILE_NAME% >nul 2>&1
if %errorlevel%==0 (
  echo [start-prod] Active SSO session found.
  exit /b 0
)

echo [start-prod] No active session. Running aws sso login...
aws sso login --profile %AWS_PROFILE_NAME%
if errorlevel 1 (
  echo [start-prod] aws sso login failed.
  exit /b 1
)

aws sts get-caller-identity --profile %AWS_PROFILE_NAME% >nul 2>&1
if errorlevel 1 (
  echo [start-prod] Unable to verify AWS identity after login.
  exit /b 1
)
echo [start-prod] SSO session is ready.
exit /b 0

:deploy_cloud
echo [start-prod] Deploying to AWS...
pushd "%ROOT_DIR%" >nul
call npm run deploy
if errorlevel 1 (
  popd >nul
  echo [start-prod] Deployment failed.
  exit /b 1
)
popd >nul
exit /b 0
