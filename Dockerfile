FROM ghcr.io/gleam-lang/gleam:v1.12.0-elixir-alpine
RUN mix local.hex --force

# Install build dependencies for SQLite
RUN apk add --no-cache gcc musl-dev make

COPY . /build/
RUN cd /build && gleam export erlang-shipment
RUN mv /build/build/erlang-shipment /app && rm -r /build

# Create data directory for SQLite
RUN mkdir -p /app/data

EXPOSE 8000
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
