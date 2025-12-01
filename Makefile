# Variables
MODE ?= dev
SERVICE ?= backend
ARGS ?=

# Docker Compose Files
COMPOSE_DEV = docker/compose.development.yaml
COMPOSE_PROD = docker/compose.production.yaml

# Determine which compose file to use based on MODE
ifeq ($(MODE),prod)
	COMPOSE_FILE = $(COMPOSE_PROD)
else
	COMPOSE_FILE = $(COMPOSE_DEV)
endif

# Colors
GREEN = \033[0;32m
NC = \033[0m # No Color

.PHONY: help up down build logs restart shell ps dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps prod-up prod-down prod-build prod-logs prod-restart backend-shell gateway-shell mongo-shell db-reset db-backup clean clean-all clean-volumes status health

# Help
help:
	@echo "Docker Services:"
	@echo "  up - Start services (use: make up [service...] or make up MODE=prod, ARGS=\"--build\" for options)"
	@echo "  down - Stop services (use: make down [service...] or make down MODE=prod, ARGS=\"--volumes\" for options)"
	@echo "  build - Build containers (use: make build [service...] or make build MODE=prod)"
	@echo "  logs - View logs (use: make logs [service] or make logs SERVICE=backend, MODE=prod for production)"
	@echo "  restart - Restart services (use: make restart [service...] or make restart MODE=prod)"
	@echo "  shell - Open shell in container (use: make shell [service] or make shell SERVICE=gateway, MODE=prod, default: backend)"
	@echo "  ps - Show running containers (use MODE=prod for production)"
	@echo ""
	@echo "Convenience Aliases (Development):"
	@echo "  dev-up - Alias: Start development environment"
	@echo "  dev-down - Alias: Stop development environment"
	@echo "  dev-build - Alias: Build development containers"
	@echo "  dev-logs - Alias: View development logs"
	@echo "  dev-restart - Alias: Restart development services"
	@echo "  dev-shell - Alias: Open shell in backend container"
	@echo "  dev-ps - Alias: Show running development containers"
	@echo "  backend-shell - Alias: Open shell in backend container"
	@echo "  gateway-shell - Alias: Open shell in gateway container"
	@echo "  mongo-shell - Open MongoDB shell"
	@echo ""
	@echo "Convenience Aliases (Production):"
	@echo "  prod-up - Alias: Start production environment"
	@echo "  prod-down - Alias: Stop production environment"
	@echo "  prod-build - Alias: Build production containers"
	@echo "  prod-logs - Alias: View production logs"
	@echo "  prod-restart - Alias: Restart production services"
	@echo ""
	@echo "Database:"
	@echo "  db-reset - Reset MongoDB database (WARNING: deletes all data)"
	@echo "  db-backup - Backup MongoDB database"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean - Remove containers and networks (both dev and prod)"
	@echo "  clean-all - Remove containers, networks, volumes, and images"
	@echo "  clean-volumes - Remove all volumes"
	@echo ""
	@echo "Utilities:"
	@echo "  status - Alias for ps"
	@echo "  health - Check service health"

# Core Docker Commands
up:
	@echo "${GREEN}Starting services in $(MODE) mode...${NC}"
	docker compose -f $(COMPOSE_FILE) up -d $(ARGS)

down:
	@echo "${GREEN}Stopping services in $(MODE) mode...${NC}"
	docker compose -f $(COMPOSE_FILE) down $(ARGS)

build:
	@echo "${GREEN}Building services in $(MODE) mode...${NC}"
	docker compose -f $(COMPOSE_FILE) build $(ARGS)

logs:
	@echo "${GREEN}Viewing logs for $(SERVICE) in $(MODE) mode...${NC}"
	docker compose -f $(COMPOSE_FILE) logs -f $(SERVICE)

restart:
	@echo "${GREEN}Restarting services in $(MODE) mode...${NC}"
	docker compose -f $(COMPOSE_FILE) restart $(ARGS)

shell:
	@echo "${GREEN}Opening shell in $(SERVICE) container ($(MODE) mode)...${NC}"
	docker compose -f $(COMPOSE_FILE) exec $(SERVICE) sh

ps:
	@echo "${GREEN}Listing containers in $(MODE) mode...${NC}"
	docker compose -f $(COMPOSE_FILE) ps

# Development Aliases
dev-up:
	@$(MAKE) up MODE=dev

dev-down:
	@$(MAKE) down MODE=dev

dev-build:
	@$(MAKE) build MODE=dev

dev-logs:
	@$(MAKE) logs MODE=dev SERVICE=$(SERVICE)

dev-restart:
	@$(MAKE) restart MODE=dev

dev-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	@$(MAKE) ps MODE=dev

backend-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

gateway-shell:
	@$(MAKE) shell MODE=dev SERVICE=gateway

mongo-shell:
	@echo "${GREEN}Opening MongoDB shell...${NC}"
	docker compose -f $(COMPOSE_DEV) exec mongo mongosh -u ${MONGO_INITDB_ROOT_USERNAME} -p ${MONGO_INITDB_ROOT_PASSWORD}

# Production Aliases
prod-up:
	@$(MAKE) up MODE=prod

prod-down:
	@$(MAKE) down MODE=prod

prod-build:
	@$(MAKE) build MODE=prod

prod-logs:
	@$(MAKE) logs MODE=prod SERVICE=$(SERVICE)

prod-restart:
	@$(MAKE) restart MODE=prod

# Database Management
db-reset:
	@echo "${GREEN}WARNING: This will delete all data in the development database. Are you sure? [y/N]${NC}"
	@read -r answer; \
	if [ "$$answer" = "y" ]; then \
		docker compose -f $(COMPOSE_DEV) down -v; \
		echo "${GREEN}Database reset complete.${NC}"; \
	else \
		echo "Aborted."; \
	fi

db-backup:
	@echo "${GREEN}Creating database backup...${NC}"
	@mkdir -p backups
	docker compose -f $(COMPOSE_DEV) exec mongo mongodump -u ${MONGO_INITDB_ROOT_USERNAME} -p ${MONGO_INITDB_ROOT_PASSWORD} --out /dump
	docker compose -f $(COMPOSE_DEV) cp mongo:/dump ./backups/dump_$(shell date +%Y%m%d_%H%M%S)
	@echo "${GREEN}Backup saved to ./backups directory.${NC}"

# Cleanup
clean:
	@echo "${GREEN}Cleaning up containers and networks...${NC}"
	docker compose -f $(COMPOSE_DEV) down --remove-orphans
	docker compose -f $(COMPOSE_PROD) down --remove-orphans

clean-volumes:
	@echo "${GREEN}Cleaning up volumes...${NC}"
	docker compose -f $(COMPOSE_DEV) down -v
	docker compose -f $(COMPOSE_PROD) down -v

clean-all: clean clean-volumes
	@echo "${GREEN}Cleaning up images...${NC}"
	docker system prune -f

# Utilities
status: ps

health:
	@echo "${GREEN}Checking service health...${NC}"
	@echo "Gateway Health:"
	@curl -s http://localhost:5921/health || echo "Gateway not reachable"
	@echo "\nBackend Health (via Gateway):"
	@curl -s http://localhost:5921/api/health || echo "Backend not reachable"
