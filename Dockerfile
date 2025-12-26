# Multi-stage build for smaller final image
# Stage 1: Build stage
FROM node:20-slim AS builder

# Install necessary build tools for native dependencies
RUN apt-get update && \
    apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Update CA certificates and enable Corepack for Yarn 4
RUN update-ca-certificates && corepack enable

# Set working directory
WORKDIR /app

# Copy package files for dependency installation
COPY package.json yarn.lock .yarnrc.yml ./

# Copy source files needed for the build (required by prepare script)
COPY src ./src
COPY WAProto ./WAProto
COPY tsconfig.json ./
COPY tsconfig.build.json ./
COPY engine-requirements.js ./
COPY eslint.config.mts ./
COPY .prettierrc ./
COPY .prettierignore ./

# Install all dependencies (including dev dependencies for build)
# The prepare script will run automatically and build the project
RUN yarn install --frozen-lockfile

# Copy remaining application files
COPY . .

# Explicitly build the application to ensure lib directory is created
RUN yarn build

# Stage 2: Production stage
FROM node:20-slim

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Enable Corepack for Yarn 4
RUN update-ca-certificates && corepack enable

WORKDIR /app

# Copy package files
COPY --from=builder /app/package.json /app/yarn.lock /app/.yarnrc.yml ./

# Install production dependencies only
RUN yarn install --production --frozen-lockfile

# Copy built application from builder stage
COPY --from=builder /app/lib ./lib
COPY --from=builder /app/WAProto ./WAProto
COPY --from=builder /app/Example ./Example
COPY --from=builder /app/engine-requirements.js ./

# Create directory for auth data persistence
RUN mkdir -p /app/baileys_auth_info

# Expose port for API (if needed in future)
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production

# Run the example application by default
CMD ["yarn", "example"]
