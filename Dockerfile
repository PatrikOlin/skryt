FROM erlang:27.1.1.0-alpine AS build
COPY --from=ghcr.io/gleam-lang/gleam:v1.12.0-erlang-alpine /bin/gleam /bin/gleam

# Install build dependencies for native compilation
RUN apk add --no-cache gcc musl-dev make

COPY . /app/
RUN cd /app && gleam export erlang-shipment

FROM erlang:27.1.1.0-alpine
RUN \
  addgroup --system webapp && \
  adduser --system webapp -g webapp

# Create data directory for SQLite before switching user
RUN mkdir -p /app/data && chown webapp:webapp /app/data

USER webapp
COPY --from=build /app/build/erlang-shipment /app
WORKDIR /app

# Expose port
EXPOSE 8000

# The issue might be that we need to adjust the function name to match the entrypoint
# Let's see what functions are actually exported by looking at the .app file
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
