# Build stage
FROM ghcr.io/gleam-lang/gleam:v1.12.0-erlang-alpine AS builder

# Install build dependencies for native compilation
RUN apk add --no-cache \
    gcc \
    musl-dev \
    make

# Set working directory
WORKDIR /app

# Copy project files
COPY gleam.toml manifest.toml ./
COPY src/ ./src/
COPY test/ ./test/

# Build the project
RUN gleam export erlang-shipment

# Runtime stage
FROM erlang:27-alpine AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    libstdc++ \
    ncurses-libs

# Create app user
RUN addgroup -g 1000 app && \
    adduser -D -s /bin/sh -u 1000 -G app app

# Set working directory
WORKDIR /app

# Copy the built application from builder stage
COPY --from=builder --chown=app:app /app/build/erlang-shipment/ ./

# Create custom entrypoint script (as root, before switching to app user)
RUN echo '#!/bin/sh' > /app/custom_entrypoint.sh && \
    echo 'set -eu' >> /app/custom_entrypoint.sh && \
    echo 'BASE=$(dirname "$0")' >> /app/custom_entrypoint.sh && \
    echo 'erl -pa "$BASE"/*/ebin' >> /app/custom_entrypoint.sh && \
    chmod +x /app/custom_entrypoint.sh && \
    chown app:app /app/custom_entrypoint.sh

# Create data directory for SQLite
RUN mkdir -p /app/data && chown app:app /app/data

# Add this debug step before USER app
RUN find /app/skryt -name "*.beam" -ls
RUN ls -la /app/skryt/ebin/ || echo "No skryt/ebin directory"

# Switch to app user
USER app

# Expose port
EXPOSE 8000

# Set environment variables
ENV PORT=8000

# Use the custom entrypoint
ENTRYPOINT ["/app/custom_entrypoint.sh"]
CMD []
