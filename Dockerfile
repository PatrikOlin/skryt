FROM node:22-alpine AS tailwind-generation
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN ./node_modules/.bin/tailwindcss -i assets/css/app.css -o priv/static/css/app.css --minify

FROM ghcr.io/gleam-lang/gleam:v1.12.0-elixir-alpine
RUN mix local.hex --force

# Install build dependencies for SQLite
RUN apk add --no-cache gcc musl-dev make

COPY . /build/
RUN cd /build && gleam export erlang-shipment
RUN mv /build/build/erlang-shipment /app && rm -r /build
COPY ./priv /app/priv/
COPY --from=tailwind-generation /src/priv/static/css/app.css /app/priv/static/css/

# Create data directory for SQLite
RUN mkdir -p /app/data

EXPOSE 8000
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
