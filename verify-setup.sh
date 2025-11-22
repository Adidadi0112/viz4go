#!/bin/bash

# Viz4GO Docker Setup Verification Script

set -e

echo "=========================================="
echo "Viz4GO Docker Setup Verification"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker
echo -n "Checking Docker installation... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
    docker --version
else
    echo -e "${RED}✗${NC}"
    echo "Docker is not installed. Please install from: https://docs.docker.com/get-docker/"
    exit 1
fi

echo ""

# Check Docker Compose
echo -n "Checking Docker Compose... "
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose --version
    else
        docker compose version
    fi
else
    echo -e "${RED}✗${NC}"
    echo "Docker Compose is not installed."
    exit 1
fi

echo ""

# Check Docker daemon
echo -n "Checking Docker daemon... "
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Docker daemon is not running. Please start Docker."
    exit 1
fi

echo ""

# Check required files
echo "Checking required files:"
required_files=(
    "docker-compose.yml"
    "Dockerfile.backend"
    "Dockerfile.frontend"
    "requirements.txt"
    "viz4go_backend/app.py"
    "viz4go_frontend/pubspec.yaml"
)

all_files_present=true
for file in "${required_files[@]}"; do
    echo -n "  $file... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        all_files_present=false
    fi
done

if [ "$all_files_present" = false ]; then
    echo ""
    echo -e "${RED}Some required files are missing!${NC}"
    exit 1
fi

echo ""

# Check ports
echo "Checking if required ports are available:"
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "  Port $port... ${YELLOW}⚠ Already in use${NC}"
        echo "    (You may need to stop the service using this port or change the port in docker-compose.yml)"
    else
        echo -e "  Port $port... ${GREEN}✓ Available${NC}"
    fi
}

check_port 5000
check_port 8080

echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}✓ All checks passed!${NC}"
echo "=========================================="
echo ""
echo "You can now start Viz4GO with:"
echo "  ./start.sh"
echo ""
echo "Or manually with:"
echo "  docker-compose up --build"
echo ""
