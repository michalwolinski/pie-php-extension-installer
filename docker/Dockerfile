# Images the checks run in. Every base is pinned by digest, and PIE is copied from its official binary-only image.
#   bare:   the official PHP image as it is, plus PIE
#   tools:  plus everything PIE asked for in the bare image (unzip, libtool; only unzip turned out to be needed) and zlib for grpc
#   alpine: the official Alpine PHP image plus unzip, for the prebuilt binary checks
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
