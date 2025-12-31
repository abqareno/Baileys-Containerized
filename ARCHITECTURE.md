# Baileys Containerized - Architecture Overview

## Application Overview

**Baileys** is a WebSocket-based TypeScript library for interacting with the WhatsApp Web API. This containerized version packages the application for easy deployment across different platforms.

## What This Application Does

- **WhatsApp Web Client**: Connects to WhatsApp Web API without requiring a browser
- **Multi-Device Support**: Works with WhatsApp's multi-device feature
- **Message Handling**: Send/receive messages, media, and manage chats
- **Session Management**: Persistent authentication across container restarts

## Docker Container Structure

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Host                          │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Baileys Container (Node.js 20)             │ │
│  │                                                     │ │
│  │  ┌───────────────────────────────────────────────┐ │ │
│  │  │    Application Layer                          │ │ │
│  │  │  - Baileys Library (TypeScript/JavaScript)    │ │ │
│  │  │  - Example Application                        │ │ │
│  │  │  - WhatsApp Protocol Implementation           │ │ │
│  │  └───────────────────────────────────────────────┘ │ │
│  │                                                     │ │
│  │  ┌───────────────────────────────────────────────┐ │ │
│  │  │    Runtime Environment                        │ │ │
│  │  │  - Node.js 20 (Debian Slim)                   │ │ │
│  │  │  - Yarn 4 (via Corepack)                      │ │ │
│  │  │  - libsignal (native crypto library)          │ │ │
│  │  └───────────────────────────────────────────────┘ │ │
│  │                                                     │ │
│  │  Port: 3000 ←──────────────────────────────────────┼─┼─→ Host:3000
│  │                                                     │ │
│  │  Volumes:                                           │ │
│  │  /app/baileys_auth_info ←──────────────────────────┼─┼─→ ./baileys_auth_info
│  │  /app/logs              ←──────────────────────────┼─┼─→ ./logs
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Network: baileys-network (bridge)                      │
└─────────────────────────────────────────────────────────┘
```

### Components

#### 1. Docker Image (Multi-Stage Build)
- **Stage 1 - Builder**:
  - Base: `node:20-slim` (Debian)
  - Build tools: Python3, Make, G++, Git
  - Compiles native dependencies (libsignal)
  - Builds TypeScript to JavaScript

- **Stage 2 - Runtime**:
  - Base: `node:20-slim` (Debian)
  - Minimal runtime dependencies
  - Production-ready environment
  - ~300MB smaller than builder

#### 2. Data Persistence
- **Authentication State** (`./baileys_auth_info`):
  - WhatsApp session credentials
  - Device registration info
  - Encryption keys
  
- **Logs** (`./logs`):
  - Application logs
  - Debug information

#### 3. Network Configuration
- **Exposed Port 3000**:
  - Reserved for future API implementations
  - Accessible from host machine
  - Can be mapped to any host port

## File Structure

```
Baileys-Containerized/
├── Dockerfile                    # Main Dockerfile (Debian-based)
├── Dockerfile.alpine             # Alternative Alpine-based image
├── docker-compose.yml            # Docker Compose configuration
├── .dockerignore                 # Files to exclude from build
├── .env.example                  # Environment variables template
├── Makefile                      # Convenient make commands
├── verify-build.sh               # Build verification script
├── DOCKER.md                     # Complete Docker documentation
├── QUICKSTART.md                 # Quick start guide
├── README.md                     # Main readme (updated)
├── .github/
│   └── workflows/
│       └── docker-build.yml      # CI/CD for Docker builds
├── src/                          # TypeScript source code
├── Example/
│   └── example.ts                # Example application
├── WAProto/                      # WhatsApp protocol definitions
└── baileys_auth_info/            # Session data (created at runtime)
```

## How It Works

### 1. Build Process
```bash
docker compose build
```
- Pulls Node.js 20 Debian Slim base image
- Installs system dependencies (Python, G++, Make, Git)
- Enables Corepack and uses Yarn 4
- Installs npm dependencies
- Compiles TypeScript to JavaScript
- Creates production image with minimal runtime

### 2. Runtime Process
```bash
docker compose up -d
```
- Creates Docker network (`baileys-network`)
- Starts container with persistent volumes
- Runs `yarn example` command
- Displays QR code for WhatsApp authentication
- Maintains WebSocket connection to WhatsApp

### 3. Authentication Flow
1. Container starts and generates QR code
2. User scans QR with WhatsApp mobile app
3. Session credentials saved to `baileys_auth_info/`
4. On restart, uses saved credentials (no re-scan needed)

## Cross-Platform Compatibility

### macOS (Docker Desktop)
- ✅ Full support
- Native Apple Silicon (M1/M2) and Intel
- GUI for easy management
- Shared volumes work seamlessly

### Windows (Docker Desktop)
- ✅ Full support
- WSL2 backend recommended
- PowerShell and CMD support
- Path mappings handled automatically

### Ubuntu/Linux (Docker Engine)
- ✅ Full support
- Native performance
- No overhead from virtualization
- Systemd integration available

## Security Considerations

1. **Session Data**: Never commit `baileys_auth_info/` to version control
2. **Environment Variables**: Use `.env` for sensitive configuration
3. **Network Isolation**: Container runs in isolated network
4. **Minimal Attack Surface**: Production image contains only runtime essentials
5. **Regular Updates**: Keep base image and dependencies updated

## Extensibility

### Adding API Server
The container exposes port 3000 for future API implementations:
```typescript
// Add to Example/example.ts or create new API file
import express from 'express'
const app = express()

app.post('/send-message', async (req, res) => {
  const { to, message } = req.body
  await sock.sendMessage(to, { text: message })
  res.json({ success: true })
})

app.listen(3000, '0.0.0.0')
```

### Custom Scripts
Mount custom scripts via volumes:
```yaml
volumes:
  - ./custom-scripts:/app/custom
```

### Environment Configuration
Set environment variables in `docker-compose.yml`:
```yaml
environment:
  - CUSTOM_VAR=value
```

## Maintenance

### Updates
```bash
# Pull latest code
git pull

# Rebuild image
docker compose build --no-cache

# Restart container
docker compose up -d
```

### Backup
```bash
# Backup authentication
tar -czf baileys-backup.tar.gz baileys_auth_info/

# Restore
tar -xzf baileys-backup.tar.gz
```

### Cleanup
```bash
# Remove everything
make clean

# Or manually
docker compose down -v
docker rmi baileys-whatsapp
rm -rf baileys_auth_info logs
```

## Troubleshooting

See [DOCKER.md](DOCKER.md) for comprehensive troubleshooting guide.

## Performance

- **Image Size**: ~500MB (multi-stage optimized)
- **Memory Usage**: ~200-400MB (depends on activity)
- **CPU Usage**: Low (event-driven architecture)
- **Startup Time**: ~5-10 seconds

## License

This Docker configuration follows the same MIT license as Baileys.
