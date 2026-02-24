@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
for %%i in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fi"
set "DB_DIR=%ROOT_DIR%\db"
set "COMPOSE_FILE=%DB_DIR%\docker-compose.yml"
set "ENV_FILE=%DB_DIR%\.env"
set "SERVICE_NAME=postgres"
set "POSTGRES_USER=cc_user"
set "POSTGRES_DB=witcher_cc"

if exist "%ENV_FILE%" (
  for /f "usebackq tokens=1* delims==" %%A in ("%ENV_FILE%") do (
    set "key=%%~A"
    set "value=%%~B"
    for /f "tokens=* delims= " %%K in ("!key!") do set "key=%%K"
    if defined key (
      if "!key:~0,1!" NEQ "#" (
        for /f "tokens=* delims= " %%V in ("!value!") do set "value=%%V"
        set "value=!value:"=!"
        if /I "!key!"=="POSTGRES_USER" set "POSTGRES_USER=!value!"
        if /I "!key!"=="POSTGRES_DB" set "POSTGRES_DB=!value!"
      )
    )
  )
)

call :detect_compose || exit /b 1
call :ensure_db || exit /b 1
call :wait_db_ready || exit /b 1
call :seed_db || exit /b 1
call :ensure_dependencies || exit /b 1
call :stop_dev_servers

start "Witcher API" cmd /K "cd /d %ROOT_DIR% && npm run dev:legacy-api"
start "Witcher Web" cmd /K "cd /d %ROOT_DIR% && npm run dev:legacy-web"
exit /b 0

:detect_compose
docker compose version >nul 2>&1
if %errorlevel%==0 (
  set "COMPOSE_MODE=plugin"
  goto :eof
)
docker-compose version >nul 2>&1
if %errorlevel%==0 (
  set "COMPOSE_MODE=legacy"
  goto :eof
)
echo [start-dev] Docker Compose is not installed.
exit /b 1

:compose
if "%COMPOSE_MODE%"=="plugin" (
  docker compose %*
) else (
  docker-compose %*
)
exit /b %errorlevel%

:ensure_db
call :compose -f "%COMPOSE_FILE%" ps --status running %SERVICE_NAME% | findstr /I "running" >nul 2>&1
if %errorlevel%==0 (
  echo [start-dev] Database container already running.
  goto :eof
)
echo [start-dev] Starting database containers (PostgreSQL and PGAdmin)...
call :compose -f "%COMPOSE_FILE%" up -d
exit /b %errorlevel%

:wait_db_ready
echo [start-dev] Waiting for database readiness...
set "READY="
for /L %%i in (1,1,30) do (
  call :compose -f "%COMPOSE_FILE%" exec -T %SERVICE_NAME% pg_isready -U %POSTGRES_USER% -d %POSTGRES_DB% >nul 2>&1
  if !errorlevel! == 0 (
    set "READY=1"
    goto :ready_ok
  )
  timeout /t 1 /nobreak >nul
)
:ready_ok
if not defined READY (
  echo [start-dev] Database failed to become ready within 30 seconds.
  exit /b 1
)
echo [start-dev] Database is ready.
exit /b 0

:seed_db
if not exist "%DB_DIR%\seed.sh" (
  echo [start-dev] seed.sh not found, skipping.
  goto :eof
)
pushd "%DB_DIR%" >nul
where bash >nul 2>&1
if %errorlevel%==0 (
  bash ./seed.sh
  if errorlevel 1 (
    popd >nul
    exit /b 1
  )
) else (
  echo [start-dev] bash not found. Please install Git Bash or run seed.sh manually.
  popd >nul
  exit /b 1
)
popd >nul
exit /b 0

:ensure_dependencies
echo [start-dev] Checking dependencies...
if not exist "%ROOT_DIR%\node_modules" (
  echo [start-dev] node_modules not found. Installing dependencies...
  pushd "%ROOT_DIR%" >nul
  call npm install
  if errorlevel 1 (
    echo [start-dev] Failed to install dependencies.
    popd >nul
    exit /b 1
  )
  popd >nul
) else (
  if not exist "%ROOT_DIR%\node_modules\.bin\tsx.cmd" (
    echo [start-dev] Dependencies incomplete. Installing...
    pushd "%ROOT_DIR%" >nul
    call npm install
    if errorlevel 1 (
      echo [start-dev] Failed to install dependencies.
      popd >nul
      exit /b 1
    )
    popd >nul
  )
)
echo [start-dev] Dependencies are ready.
exit /b 0

:stop_dev_servers
echo [start-dev] Stopping existing dev server windows (if any)...
taskkill /FI "WINDOWTITLE eq Witcher API" /T /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq Witcher Web" /T /F >nul 2>&1
exit /b 0
