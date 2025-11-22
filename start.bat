@echo off
REM Viz4GO Startup Script for Windows
REM This script starts the Viz4GO application using Docker Compose

echo ==========================================
echo Starting Viz4GO Application
echo ==========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not installed.
    echo Please install Docker from: https://docs.docker.com/get-docker/
    exit /b 1
)

REM Check if Docker daemon is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker daemon is not running.
    echo Please start Docker Desktop and try again.
    exit /b 1
)

echo Docker is installed and running
echo.

REM Build and start containers
echo Building and starting containers...
echo This may take a few minutes on first run...
echo.

docker-compose up --build -d

echo.
echo ==========================================
echo Viz4GO is starting!
echo ==========================================
echo.
echo Backend API: http://localhost:5000
echo Frontend UI: http://localhost:8080
echo.
echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo.
echo ==========================================
echo Application is ready!
echo ==========================================
echo.
echo Open your browser and go to: http://localhost:8080
echo.
echo Useful commands:
echo   - View logs:     docker-compose logs -f
echo   - Stop app:      docker-compose down
echo   - Restart app:   docker-compose restart
echo.
pause
