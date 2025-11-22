.PHONY: help build start stop restart logs clean dev test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Docker images
	docker-compose build

start: ## Start the application
	docker-compose up -d
	@echo ""
	@echo "✅ Viz4GO is starting!"
	@echo "Frontend: http://localhost:8080"
	@echo "Backend:  http://localhost:5000"

stop: ## Stop the application
	docker-compose down

restart: ## Restart the application
	docker-compose restart

logs: ## View application logs
	docker-compose logs -f

logs-backend: ## View backend logs only
	docker-compose logs -f backend

logs-frontend: ## View frontend logs only
	docker-compose logs -f frontend

clean: ## Stop and remove all containers, networks, and volumes
	docker-compose down -v

clean-all: clean ## Remove everything including images
	docker-compose down -v --rmi all

dev: ## Start in development mode with hot-reload
	docker-compose -f docker-compose.dev.yml up

rebuild: ## Rebuild and restart everything
	docker-compose up --build --force-recreate -d

status: ## Show container status
	docker-compose ps

shell-backend: ## Open shell in backend container
	docker-compose exec backend /bin/sh

shell-frontend: ## Open shell in frontend container
	docker-compose exec frontend /bin/sh

test-backend: ## Run backend tests (if available)
	@echo "Backend tests not yet implemented"

install: build start ## Build and start the application (first time setup)
	@echo ""
	@echo "Installation complete! Access the app at http://localhost:8080"
