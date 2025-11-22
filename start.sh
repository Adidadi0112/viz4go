#!/bin/bash

# Viz4GO Startup Script
# This script starts the Viz4GO application using Docker Compose

set -e

echo "=========================================="
echo "Starting Viz4GO Application"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed."
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo "❌ Error: Docker Compose is not installed."
    echo "Please install Docker Compose from: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running."
    echo "Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is installed and running"
echo ""

# Build and start containers
echo "Building and starting containers..."
echo "This may take a few minutes on first run..."
echo ""

docker-compose up --build -d

echo ""
echo "=========================================="
echo "✅ Viz4GO is starting!"
echo "=========================================="
echo ""
echo "📊 Backend API: http://localhost:5000"
echo "🌐 Frontend UI: http://localhost:8080"
echo ""
echo "Waiting for services to be ready..."

# Wait for backend to be ready
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:5000/api/go/term/GO:0008150 > /dev/null 2>&1; then
        echo "✅ Backend is ready!"
        break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo "⚠️  Backend is taking longer than expected to start."
        echo "   Check logs with: docker-compose logs backend"
    else
        sleep 2
    fi
done

echo ""
echo "=========================================="
echo "🚀 Application is ready!"
echo "=========================================="
echo ""
echo "Open your browser and go to: http://localhost:8080"
echo ""
echo "Useful commands:"
echo "  - View logs:     docker-compose logs -f"
echo "  - Stop app:      docker-compose down"
echo "  - Restart app:   docker-compose restart"
echo ""
