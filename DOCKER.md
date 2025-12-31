# Baileys Docker Setup

This directory contains Docker configuration for running Baileys (WhatsApp Web API) in a containerized environment.

## Prerequisites

- Docker Desktop (for macOS and Windows) or Docker Engine (for Ubuntu/Linux)
- Docker Compose v2.0 or higher
- At least 2GB of free disk space
- Active internet connection

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Baileys-Containerized
```

### 2. Build and Run with Docker Compose

```bash
# Build and start the container
docker compose up -d

# View logs and QR code
docker compose logs -f baileys
```

### 3. Scan QR Code

When the container starts, it will display a QR code in the logs. Scan this QR code with WhatsApp on your phone:
1. Open WhatsApp on your phone
2. Go to Settings → Linked Devices
3. Click "Link a Device"
4. Scan the QR code from the Docker logs

### 4. Using Pairing Code (Alternative)

If you prefer using a pairing code instead of QR:

```bash
# Edit docker compose.yml and uncomment the pairing code command line
# Then restart the container
docker compose down
docker compose up -d

# View logs to see the pairing code
docker compose logs -f baileys
```

## Platform-Specific Instructions

### macOS (Docker Desktop)

```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Then run:
docker compose up -d
docker compose logs -f
```

### Windows (Docker Desktop)

```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Then run in PowerShell or CMD:
docker compose up -d
docker compose logs -f
```

### Ubuntu/Linux

```bash
# Install Docker and Docker Compose
sudo apt-get update
sudo apt-get install docker.io docker compose
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Run the application
docker compose up -d
docker compose logs -f
```

## Configuration

### Environment Variables

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` to configure:
- `NODE_ENV`: Set to `production` or `development`
- `TZ`: Your timezone (e.g., `America/New_York`)

### Persistent Data

The following directories are mounted as volumes for data persistence:
- `./baileys_auth_info`: WhatsApp authentication session data
- `./logs`: Application logs

**Important Notes:**
- Don't delete `baileys_auth_info` folder if you want to keep your session active!
- These directories will be created automatically by Docker Compose on first run
- On Linux, ensure proper permissions: `chmod 755 baileys_auth_info logs` if needed

## Common Docker Commands

```bash
# Start the container
docker compose up -d

# Stop the container
docker compose down

# View logs
docker compose logs -f baileys

# Restart the container
docker compose restart

# Rebuild the container (after code changes)
docker compose up -d --build

# Access container shell
docker compose exec baileys sh

# Remove all data and start fresh
docker compose down -v
rm -rf baileys_auth_info logs
docker compose up -d
```

## Accessing the Application

The container exposes port 3000, which can be used for:
- Future API implementations
- Health checks
- Custom integrations

To access from host machine: `http://localhost:3000`

## Troubleshooting

### Container exits immediately
Check logs: `docker compose logs baileys`

### QR code not appearing
Make sure you have `tty: true` and `stdin_open: true` in docker compose.yml

### Authentication issues
1. Stop container: `docker compose down`
2. Remove auth data: `rm -rf baileys_auth_info`
3. Start fresh: `docker compose up -d`

### Port already in use
Change the port mapping in `docker compose.yml`:
```yaml
ports:
  - "3001:3000"  # Use 3001 on host instead of 3000
```

### Permission issues (Linux)
```bash
# Fix ownership of volume directories
sudo chown -R $USER:$USER baileys_auth_info logs
```

## Development Mode

To run in development mode with live code reloading:

```bash
# Modify docker compose.yml to mount source code
# Add under volumes:
# - ./src:/app/src
# - ./Example:/app/Example

# Then run
docker compose up -d --build
```

## Building Custom Images

```bash
# Build with a custom tag
docker build -t my-baileys:latest .

# Run custom image
docker run -it --rm \
  -v $(pwd)/baileys_auth_info:/app/baileys_auth_info \
  -v $(pwd)/logs:/app/logs \
  -p 3000:3000 \
  my-baileys:latest
```

## Security Considerations

1. **Never commit** `baileys_auth_info` folder to version control
2. **Keep** `.env` file private and don't share credentials
3. **Use** network isolation in production
4. **Update** dependencies regularly: `docker compose build --no-cache`

## Architecture

```
┌─────────────────────────────────────┐
│    Docker Container (Node.js 20)    │
│  ┌────────────────────────────────┐ │
│  │     Baileys Application        │ │
│  │  (WhatsApp Web API Client)     │ │
│  └────────────────────────────────┘ │
│                                     │
│  Volumes:                           │
│  • /app/baileys_auth_info ←────────┼─→ ./baileys_auth_info
│  • /app/logs              ←────────┼─→ ./logs
│                                     │
│  Network:                           │
│  • Port 3000              ←────────┼─→ Host:3000
└─────────────────────────────────────┘
```

## Support

For issues related to:
- **Baileys library**: See main README.md or visit https://github.com/WhiskeySockets/Baileys
- **Docker setup**: Create an issue in this repository
- **WhatsApp API**: Check WhatsApp Web documentation

## License

This Docker setup follows the same MIT license as Baileys.
