# PIE, the PECL replacement, tested in Docker

By [Michał Woliński](https://wolinski.com). Companion repository for the article
[PIE Replaces PECL: Installing PHP Extensions in Docker, Measured](https://wolinski.com/blog/pie-php-extension-installer.html).

PIE, the PHP Installer for Extensions, is what PHP now recommends instead of `pecl install`. This repository checks
what changes when a Dockerfile moves from PECL to PIE: the tools PIE needs, how many compiler jobs it runs, what it
verifies about prebuilt binaries, what it does when an installed extension does not load, how it picks packages for
a project, and how `pie.lock` behaves in a Docker build.

Everything runs in the official PHP 8.5.12 images for Debian bookworm and Alpine, with PIE 1.5.5 and 1.6.0-rc.1
mounted from `ghcr.io/php/pie`, every image pinned by digest.

## Run it

```sh
./run.sh            # all checks, about 20 minutes, needs network access to Packagist and GitHub
./run.sh 03 07      # only some checks, by number
./timings/run.sh    # the grpc build timings, one build at a time, well over an hour
```

`run.sh` prints `claim <name> <value>` lines from each check into `runs/claims.txt`, compares them with
`expectations.txt`, and exits with 1 if any differ. `timings/run.sh` writes a timeline per build to `timings/out/`
(seconds, anonymous memory of the container in MiB, load average), and `python3 timings/chart.py` draws the memory
chart from those timelines.

`timings/out/results.txt` keeps every run, failures included: the `pie-j8` row with `rc=255` and the `pecl` rows
with `rc=1` after one or two seconds are attempts made while the network was down (and, for `pecl`, one asking for
grpc 1.85.1, which PECL does not have). The `no-libtool` run shared the machine with `./run.sh`, so only its result,
not its time, is used.

Run the timings on an otherwise idle Docker and keep the machine awake: other containers change both the time and
whether the build fits in memory, and a sleeping machine stretches the time.

## What is checked

| Claim in the article | Where |
|---|---|
| The official image lacks `unzip` and `libtoolize`; PIE names both, prints the `apt-get` line and exits with 1; with `unzip` alone it warns about `libtoolize` and still builds and loads redis | `checks/01-bare-image.sh` |
| `pecl` runs plain `make`; PIE runs `make -j` with the CPUs it may use, and respects `--cpus` and `--cpuset-cpus` although `nproc` does not | `checks/02-make-jobs.sh` |
| A prebuilt binary that does not load (Alpine without `libstdc++`): PIE warns, leaves the ini file, exits with 0; `php --ri` exits with 1; same in 1.6.0-rc.1 | `checks/03-binary-missing-library.sh` |
| PIE prints that HTTPS is the only integrity check for prebuilt binaries; `pie.lock` records the source zipball with an empty `shasum` | `checks/04-binary-integrity.sh` |
| A configure option makes PIE compile a package that ships binaries | `checks/05-configure-option-with-binary.sh` |
| `pie install` in a project: 1.5.5 needs `--select` without a terminal, 1.6.0-rc.1 picks the standard packages | `checks/06-project-install.sh` |
| `--from-lock` installs the locked version from PIE's directory, fails with `No lockfile found` elsewhere, and the directory changes with the PHP patch version and the architecture | `checks/07-lock-file.sh` |
| The recommended Dockerfile builds, its extensions load, its `php --ri` line fails the build when an extension is missing, `--no-cache` leaves no Composer cache; its `redis.so` loads on PHP 8.5.11 and, unsupported, on Alpine | `checks/08-example-dockerfile.sh`, `examples/Dockerfile` |
| The puzzle: the same Dockerfile and `pie.lock` build on PHP 8.5.12 and fail with `No lockfile found` on 8.5.11 | `checks/09-puzzle.sh`, `examples/puzzle/` |
| A GitHub token passed as a BuildKit secret reaches PIE: an invalid one fails the build with `Could not authenticate against github.com` | `checks/10-github-token.sh`, `examples/token/Dockerfile` |
| grpc build time and memory for `pecl`, PIE with `-j2`, `-j4`, `-j8`, a prebuilt binary and Sury's package; grpc without `libtool`; redis with `pecl` and PIE | `timings/run.sh`, `timings/out/results.txt` |

## Versions

PIE 1.5.5 and 1.6.0-rc.1, PHP 8.5.12, Debian bookworm and Alpine images from Docker Hub, grpc 1.85.1 from Packagist
(1.85.0 from PECL, which had no 1.85.1), redis 6.3.0, pcov 1.0.12, apcu 5.1.27. Timings were taken on Docker
Desktop on an Apple silicon Mac, 8 CPUs and 7.6 GiB of memory for Docker.

## Author

Michał Woliński, [wolinski.com](https://wolinski.com). MIT licence, see `LICENSE`.
