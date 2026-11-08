# PHP 8.5 from deb.sury.org on Debian bookworm, for timing apt-get install php8.5-grpc against building it.
FROM debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL -o /usr/share/keyrings/sury-php.gpg https://packages.sury.org/php/apt.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ bookworm main' > /etc/apt/sources.list.d/sury-php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends php8.5-cli \
    && rm -rf /var/lib/apt/lists/*
