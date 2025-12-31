.PHONY: help build up down logs restart clean verify shell

# Default target
help:
	@echo "Baileys Docker Commands"
	@echo "======================="
	@echo ""
	@echo "  make build     - Build the Docker image"
	@echo "  make up        - Start the container in detached mode"
	@echo "  make down      - Stop and remove the container"
	@echo "  make logs      - View container logs (follow mode)"
	@echo "  make restart   - Restart the container"
	@echo "  make clean     - Remove container, image, and volumes"
	@echo "  make verify    - Verify Docker build"
	@echo "  make shell     - Open a shell in the running container"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make build"
	@echo "  2. make up"
	@echo "  3. make logs"
	@echo ""

# Build the Docker image
build:
	@echo "Building Docker image..."
	docker compose build

# Start container in detached mode
up:
	@echo "Starting container..."
	docker compose up -d
	@echo "Container started. Use 'make logs' to view output."

# Stop and remove container
down:
	@echo "Stopping container..."
	docker compose down

# View logs
logs:
	@echo "Viewing logs (Ctrl+C to exit)..."
	docker compose logs -f baileys

# Restart container
restart:
	@echo "Restarting container..."
	docker compose restart

# Clean up everything
clean:
	@echo "Cleaning up containers, images, and volumes..."
	docker compose down -v
	docker rmi baileys-whatsapp 2>/dev/null || true
	@echo "Cleanup complete."

# Verify build
verify:
	@echo "Running build verification..."
	./verify-build.sh

# Open shell in running container
shell:
	@echo "Opening shell in container..."
	docker compose exec baileys sh
