FROM erlang:27.1.1.0-alpine AS build
COPY --from=ghcr.io/gleam-lang/gleam:v1.12.0-erlang-alpine /bin/gleam /bin/gleam
# Install build dependencies for native compilation
RUN apk add --no-cache \
    gcc \
    musl-dev \
    make
COPY . /app/
RUN cd /app && gleam export erlang-shipment

FROM erlang:27.1.1.0-alpine
RUN \
  addgroup --system webapp && \
  adduser --system webapp -g webapp
USER webapp
COPY --from=build /app/build/erlang-shipment /app
# Create data directory for SQLite
RUN mkdir -p /app/data && chown webapp:webapp /app/data
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
