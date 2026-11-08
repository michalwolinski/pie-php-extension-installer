#!/usr/bin/env bash
# Does a token passed as a BuildKit secret reach PIE? A deliberately invalid one has to make the build fail with an
# authentication error; without the secret the same Dockerfile builds. No real token is needed or used.
source "$(dirname "$0")/lib.sh"
out=$(COMPOSER_AUTH='{"github-oauth": {"github.com": "not-a-real-token"}}' \
    docker build --no-cache --progress=plain --secret id=composer_auth,env=COMPOSER_AUTH examples/token 2>&1)
claim token.invalid.build-fails "$(grep -q 'failed to solve' <<<"$out" && echo yes || echo no)"
claim token.invalid.auth-error "$(grep -q 'Could not authenticate against github.com' <<<"$out" && echo yes || echo no)"
claim token.none.builds "$(docker build --no-cache -q examples/token > /dev/null 2>&1 && echo yes || echo no)"
