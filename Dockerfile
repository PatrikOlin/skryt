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

# Debug: List what was built
RUN find /app/build/erlang-shipment -type f -name "*.beam" | head -20
RUN ls -la /app/build/erlang-shipment/

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

# Debug: Check what we copied
RUN ls -la /app/
RUN find /app -name "*.beam" | head -10
RUN cat /app/entrypoint.sh || echo "No entrypoint.sh found"

# Create data directory for SQLite
RUN mkdir -p /app/data && chown app:app /app/data

# Switch to app user
USER app

# Expose port
EXPOSE 8000

# Set environment variables
ENV PORT=8000

# Use the original entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
