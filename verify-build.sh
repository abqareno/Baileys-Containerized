#!/bin/bash
# Build verification script for Docker setup

set -e

echo "======================================"
echo "Baileys Docker Build Verification"
echo "======================================"
echo ""

# Check Docker installation
echo "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi
echo "✓ Docker is installed: $(docker --version)"
echo ""

# Check Docker Compose installation
echo "Checking Docker Compose installation..."
if docker compose version &> /dev/null; then
    echo "✓ Docker Compose is installed: $(docker compose version)"
elif command -v docker-compose &> /dev/null; then
    echo "✓ Docker Compose is installed: $(docker-compose --version)"
else
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
echo ""

# Build the Docker image
echo "Building Docker image..."
echo "This may take a few minutes..."
docker build -t baileys:latest . || {
    echo "❌ Docker build failed."
    echo "Please check the error messages above."
    exit 1
}
echo "✓ Docker image built successfully"
echo ""

# Verify the image was created
echo "Verifying Docker image..."
if docker images | grep -q "baileys"; then
    echo "✓ Docker image 'baileys:latest' created successfully"
    docker images | grep "baileys"
else
    echo "❌ Docker image was not created"
    exit 1
fi
echo ""

echo "======================================"
echo "✓ Build verification successful!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Start the container: docker compose up -d"
echo "2. View logs: docker compose logs -f baileys"
echo "3. Scan the QR code to connect WhatsApp"
echo ""
echo "For more information, see DOCKER.md"
