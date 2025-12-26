# Use Node.js LTS version
FROM node:20-alpine

# Install necessary build tools for native dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    curl

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Install dependencies
RUN yarn install --immutable

# Copy application source
COPY . .

# Build the application
RUN yarn build

# Create directory for auth data persistence
RUN mkdir -p /app/baileys_auth_info

# Expose port for API (if needed in future)
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production

# Run the example application by default
CMD ["yarn", "example"]
