# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of Alpine to avoid DNS resolution issues.
FROM elixir:1.15-slim AS builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# compile assets
COPY assets assets
COPY priv priv
# Since we don't have tailwind, we compile esbuild assets directly
RUN mix assets.deploy

# Compile the release
COPY lib lib
RUN mix compile

# Changes to config/runtime.exs require rebuilding the release
RUN mix release

# Start a new image for the runner
FROM debian:bookworm-slim AS runner

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libssl3 ca-certificates curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
ENV LANG=C.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# Only copy the final release from the builder stage
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/enterprise_shop ./

USER nobody

# If using Phoenix v1.8+, the release contains a script start/stop/migrate
ENV PORT=4000
EXPOSE 4000

CMD ["/app/bin/enterprise_shop", "start"]
