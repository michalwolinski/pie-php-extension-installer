# The puzzle's Dockerfile. The lock directory is the one pie show -v printed in php:8.5.12 on arm64.
ARG BASE=php:8.5-cli-bookworm
FROM ${BASE}
RUN apt-get update && apt-get install -y --no-install-recommends unzip
COPY pie.json pie.lock /root/.pie/php8.5_daf413ac2c6373732eaa89ffb4a8bf81/
RUN --mount=type=bind,from=ghcr.io/php/pie:1.5.5-bin@sha256:3fca03c16df842d02b654dc382db3756058d9c128064f57cace14f8728779ce9,source=/pie,target=/usr/local/bin/pie \
    pie install --from-lock
