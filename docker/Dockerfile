# Images the checks run in. Every base is pinned by digest, and PIE is copied from its official binary-only image.
#   bare:   the official PHP image as it is, plus PIE
#   tools:  plus everything PIE asked for in the bare image (unzip, libtool; only unzip turned out to be needed) and zlib for grpc
#   alpine: the official Alpine PHP image plus unzip, for the prebuilt binary checks
#   alpine-build, ipe, ipe-alpine: see below
ARG PIE_IMAGE=ghcr.io/php/pie:1.5.5-bin@sha256:3fca03c16df842d02b654dc382db3756058d9c128064f57cace14f8728779ce9

FROM ${PIE_IMAGE} AS pie

FROM php:8.5.12-cli-bookworm@sha256:050713ce008e2360ea9dc96e1f9a075690132388d917fc3552806f7a7be6f2a0 AS bare
COPY --from=pie /pie /usr/local/bin/pie

FROM bare AS tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip libtool zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

FROM php:8.5.12-cli-alpine@sha256:d1fbbe78850d1eb9aa8f7da652ec5db61eb4c9377c8215cf5e23f3b528ed4f2b AS alpine
RUN apk add --no-cache unzip
COPY --from=pie /pie /usr/local/bin/pie

# alpine-build: the Alpine image plus what compiling grpc there needs: the official image's own PHPIZE_DEPS
# (compilers and autoconf), the Linux headers and zlib, and the C++ runtime grpc links against.
FROM alpine AS alpine-build
RUN apk add --no-cache $PHPIZE_DEPS linux-headers zlib-dev libstdc++

# install-php-extensions by mlocati, for comparison, in the bookworm and the Alpine image.
FROM ghcr.io/mlocati/php-extension-installer:2.13.2@sha256:4fd45396c16685266d32bf147a24ecd5e81029d3820295895bf4a90131190ac9 AS ipe-script

FROM php:8.5.12-cli-bookworm@sha256:050713ce008e2360ea9dc96e1f9a075690132388d917fc3552806f7a7be6f2a0 AS ipe
COPY --from=ipe-script /usr/bin/install-php-extensions /usr/local/bin/

FROM php:8.5.12-cli-alpine@sha256:d1fbbe78850d1eb9aa8f7da652ec5db61eb4c9377c8215cf5e23f3b528ed4f2b AS ipe-alpine
COPY --from=ipe-script /usr/bin/install-php-extensions /usr/local/bin/
