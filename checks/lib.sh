# Shared helpers for the checks. Each check prints "claim <name> <value>" lines; run.sh compares them with
# expectations.txt. Images are built once per PIE version and tagged pie-article:<target>-<version>.
PIE_155='ghcr.io/php/pie:1.5.5-bin@sha256:3fca03c16df842d02b654dc382db3756058d9c128064f57cace14f8728779ce9'
PIE_160='ghcr.io/php/pie:1.6.0-rc.1-bin@sha256:e49352b56eb2ac2234a85d9ff5ab2493e0ee33c0429339f087da601e07d86d95'

image() { # image <target> <1.5.5|1.6.0-rc.1>
    local target=$1 version=$2 pie
    case $version in 1.5.5) pie=$PIE_155 ;; 1.6.0-rc.1) pie=$PIE_160 ;; esac
    local tag="pie-article:$target-$version"
    # On a failed build print nothing, so the check runs against no image rather than an old one.
    docker build -q --build-arg PIE_IMAGE="$pie" --target "$target" -t "$tag" docker >/dev/null || return 1
    echo "$tag"
}

claim() { echo "claim $1 $2"; }
