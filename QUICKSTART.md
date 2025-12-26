# Quick Start Guide - Docker

## Prerequisites
- Docker Desktop (macOS/Windows) or Docker Engine (Linux)
- At least 2GB free disk space

## Quick Start (3 steps)

### 1. Build the Container
```bash
docker compose build
```
Or if using Makefile:
```bash
make build
```

### 2. Start the Container
```bash
docker compose up -d
```
Or:
```bash
make up
```

### 3. View Logs and Scan QR Code
```bash
docker compose logs -f baileys
```
Or:
```bash
make logs
```

Look for the QR code in the logs and scan it with WhatsApp on your phone:
1. Open WhatsApp → Settings → Linked Devices
2. Tap "Link a Device"
3. Scan the QR code

## Using Pairing Code Instead

Edit `docker-compose.yml` and change the command line:
```yaml
command: yarn example --use-pairing-code
```

Then restart:
```bash
docker compose restart
docker compose logs -f baileys
```

## Common Commands

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start container |
| `docker compose down` | Stop container |
| `docker compose logs -f` | View logs |
| `docker compose restart` | Restart container |
| `docker compose exec baileys sh` | Access container shell |

## Using Makefile (Optional)

If you have `make` installed:

```bash
make help     # Show all commands
make build    # Build image
make up       # Start container
make logs     # View logs
make restart  # Restart container
make down     # Stop container
make shell    # Access container shell
make clean    # Remove everything
```

## Persistent Data

Authentication data is stored in `./baileys_auth_info` on your host machine.

**Important:** Don't delete this folder if you want to stay logged in!

## Troubleshooting

### Container exits immediately
```bash
docker compose logs baileys
```

### Port already in use
Edit `docker-compose.yml` and change:
```yaml
ports:
  - "3001:3000"  # Use different port
```

### Fresh start (logout)
```bash
docker compose down
rm -rf baileys_auth_info
docker compose up -d
```

## Full Documentation

See [DOCKER.md](DOCKER.md) for complete documentation.
