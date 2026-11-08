FROM php:8.5.12-cli-bookworm@sha256:050713ce008e2360ea9dc96e1f9a075690132388d917fc3552806f7a7be6f2a0

# PIE is mounted only for this step, so it never becomes part of the image. unzip is the one tool the official
# image lacks; it is removed again in the same layer.
RUN --mount=type=bind,from=ghcr.io/php/pie:1.5.5-bin@sha256:3fca03c16df842d02b654dc382db3756058d9c128064f57cace14f8728779ce9,source=/pie,target=/usr/local/bin/pie \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends unzip; \
    pie install --no-cache phpredis/phpredis:6.3.0; \
    pie install --no-cache pecl/pcov:1.0.12; \
    apt-get purge -y --auto-remove unzip; \
    rm -rf /var/lib/apt/lists/* /root/.pie; \
    # PIE exits with 0 even when an extension it installed does not load. Check last, after the purge,
    # so a library the purge took away fails the build too.
    php --ri redis > /dev/null; \
    php --ri pcov > /dev/null
