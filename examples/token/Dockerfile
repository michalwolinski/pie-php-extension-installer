# A GitHub token for PIE's downloads, passed as a BuildKit secret so it never lands in a layer:
#   docker build --secret id=composer_auth,env=COMPOSER_AUTH .
# with COMPOSER_AUTH='{"github-oauth": {"github.com": "<token>"}}' in the environment of the build.
FROM php:8.5.12-cli-bookworm@sha256:050713ce008e2360ea9dc96e1f9a075690132388d917fc3552806f7a7be6f2a0
RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/*
RUN --mount=type=bind,from=ghcr.io/php/pie:1.5.5-bin@sha256:3fca03c16df842d02b654dc382db3756058d9c128064f57cace14f8728779ce9,source=/pie,target=/usr/local/bin/pie \
    --mount=type=secret,id=composer_auth,env=COMPOSER_AUTH \
    pie install --no-cache phpredis/phpredis:6.3.0 \
    && php --ri redis > /dev/null
