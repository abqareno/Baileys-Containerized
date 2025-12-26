# Docker Setup Testing Guide

This document provides comprehensive testing instructions for the Docker containerization setup.

## Pre-Build Verification

### 1. File Structure Check
Verify all Docker-related files are present:

```bash
# Check main Docker files
ls -la Dockerfile Dockerfile.alpine docker-compose.yml .dockerignore .env.example

# Check documentation
ls -la DOCKER.md QUICKSTART.md ARCHITECTURE.md

# Check build tools
ls -la Makefile verify-build.sh
```

Expected output: All files should exist and verify-build.sh should have executable permissions (rwxr-xr-x).

### 2. Syntax Validation

```bash
# Validate docker-compose.yml syntax
docker compose config

# Should show the parsed configuration without errors
```

### 3. Environment Setup

```bash
# Create .env file from example
cp .env.example .env

# Verify the content
cat .env
```

## Build Testing

### Option 1: Using Docker Compose (Recommended)

```bash
# Build the image
docker compose build

# Expected: Successful build with no errors
# Image size: ~500MB for main Dockerfile, ~400MB for Alpine
```

### Option 2: Using Makefile

```bash
# Build using make
make build

# View all available commands
make help
```

### Option 3: Using Verification Script

```bash
# Run build verification
./verify-build.sh

# Expected: 
# ✓ Docker is installed
# ✓ Docker Compose is installed  
# ✓ Docker image built successfully
# ✓ Build verification successful!
```

### Option 4: Direct Docker Build

```bash
# Build with main Dockerfile
docker build -t baileys:test .

# Build with Alpine Dockerfile
docker build -f Dockerfile.alpine -t baileys:alpine-test .
```

## Runtime Testing

### 1. Start Container

```bash
# Start in detached mode
docker compose up -d

# Check container status
docker compose ps

# Expected: Container should be running
```

### 2. View Logs

```bash
# View logs in real-time
docker compose logs -f baileys

# Expected output:
# - Baileys initialization messages
# - "using WA v..." message
# - QR code displayed in terminal (if using QR mode)
# - Or pairing code (if using pairing mode)
```

### 3. Container Health Check

```bash
# Check container is running
docker ps | grep baileys-whatsapp

# Inspect container
docker inspect baileys-whatsapp

# Check resource usage
docker stats baileys-whatsapp --no-stream

# Expected:
# - Container STATUS: Up
# - Memory usage: 200-400MB
# - CPU usage: Low when idle
```

### 4. Network Connectivity

```bash
# Test port exposure
curl -v http://localhost:3000

# Expected: Connection should succeed (even if no response)
# This confirms port 3000 is accessible
```

### 5. Volume Persistence

```bash
# Check volumes are created
ls -la baileys_auth_info logs

# After authentication, check auth files
ls -la baileys_auth_info/

# Expected:
# - baileys_auth_info/ should contain creds.json and other auth files
# - logs/ should contain log files
```

### 6. Interactive Mode Test

```bash
# Access container shell
docker compose exec baileys sh

# Inside container, check environment
whoami
node --version
yarn --version
ls -la /app

# Exit container
exit
```

## Platform-Specific Testing

### macOS (Docker Desktop)

```bash
# Check Docker Desktop is running
docker info | grep "Operating System"

# Build and run
docker compose up -d

# View logs for QR code
docker compose logs -f baileys

# Test on both Intel and Apple Silicon
```

### Windows (Docker Desktop with WSL2)

```powershell
# In PowerShell or CMD
docker info

# Build and run
docker compose up -d

# View logs
docker compose logs -f baileys

# Test path mappings work correctly
dir baileys_auth_info
dir logs
```

### Ubuntu/Linux

```bash
# Check Docker service
sudo systemctl status docker

# Run without sudo (after adding user to docker group)
docker compose up -d

# Check file permissions
ls -la baileys_auth_info logs

# If needed, fix permissions
chmod 755 baileys_auth_info logs
```

## Feature Testing

### 1. QR Code Authentication (Default)

```bash
# Start container with default command
docker compose up -d

# View QR code
docker compose logs -f baileys

# Scan QR code with WhatsApp mobile app
# Expected: Connection should establish, credentials saved
```

### 2. Pairing Code Authentication

```bash
# Edit docker-compose.yml, uncomment pairing code command
# Then restart
docker compose restart

# View pairing code
docker compose logs -f baileys

# Enter code in WhatsApp
# Expected: Connection should establish
```

### 3. Auto-Reply Feature

```bash
# Edit docker-compose.yml, uncomment --do-reply flag
docker compose restart

# Send a test message to the WhatsApp number
# Expected: Auto-reply sent
```

### 4. Session Persistence

```bash
# After successful authentication
docker compose down

# Start again
docker compose up -d

# Check logs
docker compose logs -f baileys

# Expected: Should reconnect without QR code
```

## Cleanup Testing

### 1. Graceful Shutdown

```bash
# Stop container
docker compose down

# Verify stopped
docker ps -a | grep baileys
```

### 2. Complete Cleanup

```bash
# Remove everything
make clean

# Or manually
docker compose down -v
docker rmi baileys-whatsapp
rm -rf baileys_auth_info logs

# Verify cleanup
docker images | grep baileys
ls -la baileys_auth_info logs
```

## Performance Testing

### 1. Build Time

```bash
# Time the build
time docker compose build

# Expected: 3-10 minutes depending on network and system
```

### 2. Startup Time

```bash
# Time container startup
time docker compose up -d

# Expected: 5-10 seconds
```

### 3. Resource Usage

```bash
# Monitor resources
docker stats baileys-whatsapp

# Expected:
# - Memory: 200-400MB
# - CPU: <5% when idle
# - Network: Varies with activity
```

## Troubleshooting Tests

### 1. Build Failures

```bash
# Check build logs
docker compose build --progress=plain

# Test with no cache
docker compose build --no-cache
```

### 2. Connection Issues

```bash
# Check container logs
docker compose logs baileys

# Check network
docker network inspect baileys-network

# Test connectivity
docker compose exec baileys ping -c 3 google.com
```

### 3. Permission Issues

```bash
# Check file ownership
ls -la baileys_auth_info

# Fix if needed
sudo chown -R $USER:$USER baileys_auth_info logs
```

## CI/CD Testing

### GitHub Actions

The repository includes a workflow that:
1. Checks out code
2. Sets up Docker Buildx
3. Builds the image
4. Tests the container

To test locally with Act:

```bash
# Install act (if not installed)
# brew install act  # macOS
# Or download from: https://github.com/nektos/act

# Run the workflow
act -j docker-build
```

## Expected Results Summary

### ✅ Successful Setup Should Show:

1. **Build Phase**:
   - No build errors
   - Image created (~500MB for Debian, ~400MB for Alpine)
   - All dependencies installed

2. **Runtime Phase**:
   - Container starts successfully
   - QR code or pairing code displays
   - No crash/restart loops
   - Port 3000 accessible

3. **Authentication Phase**:
   - QR scan or pairing code works
   - Credentials saved to baileys_auth_info/
   - Connection established to WhatsApp

4. **Persistence Phase**:
   - Container restart maintains session
   - No re-authentication needed
   - Data persists in volumes

### ❌ Common Issues and Solutions:

1. **Port already in use**: Change port in docker-compose.yml
2. **Permission denied**: Fix with `chmod 755` or `chown`
3. **Build timeout**: Increase Docker build timeout or use cached layers
4. **Network errors**: Check firewall/proxy settings

## Validation Checklist

- [ ] Docker and Docker Compose installed
- [ ] All files present and properly configured
- [ ] docker-compose.yml syntax valid
- [ ] Dockerfile builds without errors
- [ ] Container starts successfully
- [ ] Logs visible and readable
- [ ] QR code displays correctly
- [ ] Port 3000 accessible
- [ ] Volumes created and writable
- [ ] Authentication works
- [ ] Session persists across restarts
- [ ] Container restarts automatically on failure
- [ ] Graceful shutdown works
- [ ] Cleanup removes all resources

## Reporting Issues

If tests fail, gather this information:

```bash
# System information
docker version
docker compose version
uname -a

# Container logs
docker compose logs baileys > baileys-logs.txt

# Docker info
docker info > docker-info.txt

# Compose configuration
docker compose config > compose-config.txt
```

Then create an issue with these logs attached.
