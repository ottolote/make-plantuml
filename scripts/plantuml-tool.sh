#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"
FORMATS="${FORMATS:-svg,png}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

log() {
    printf '[plantuml-tool] %s\n' "$*"
}

usage() {
    cat <<'EOF'
Usage: plantuml-tool <command>

Commands:
  render   Render all *.pu files in the workspace
  watch    Render once, then re-render on *.pu changes
  help     Show this help text
EOF
}

ensure_workspace() {
    if [ ! -d "$WORKSPACE" ]; then
        echo "Error: workspace '$WORKSPACE' does not exist." >&2
        exit 1
    fi

    WORKSPACE="$(cd "$WORKSPACE" && pwd)"
}

collect_sources() {
    find "$WORKSPACE" \
        -path "$WORKSPACE/$OUTPUT_DIR" -prune -o \
        -type f -name '*.pu' -print0 | sort -z
}

render_one() {
    local src="$1"
    local relative="${src#$WORKSPACE/}"
    local base="${relative%.pu}"
    local format dest

    IFS=',' read -r -a formats <<< "$FORMATS"

    for format in "${formats[@]}"; do
        format="${format// /}"
        [ -n "$format" ] || continue
        dest="$WORKSPACE/$OUTPUT_DIR/$base.$format"
        mkdir -p "$(dirname "$dest")"
        log "Rendering $relative -> ${OUTPUT_DIR}/$base.$format"
        java -jar /opt/plantuml.jar "-t$format" -pipe < "$src" > "$dest"
    done
}

render_all() {
    ensure_workspace

    log "Running make all..."
    make -f /opt/Makefile -C "$WORKSPACE" all OUTPUT_DIR="$OUTPUT_DIR" FORMATS="$FORMATS"
}

watch_loop() {
    ensure_workspace

    if ! command -v entr >/dev/null 2>&1; then
        echo "Error: entr is required for watch mode." >&2
        exit 1
    fi

    trap 'log "Stopping watch mode"; exit 0' INT TERM

    render_all

    while true; do
        local files=()
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(collect_sources)

        if [ "${#files[@]}" -eq 0 ]; then
            log "Waiting for .pu files in $WORKSPACE"
            sleep "$POLL_INTERVAL"
            continue
        fi

        log "Watching ${#files[@]} PlantUML source file(s)"

        if ! printf '%s\n' "${files[@]}" | entr -d -n env WORKSPACE="$WORKSPACE" OUTPUT_DIR="$OUTPUT_DIR" "$SELF_PATH" render; then
            sleep 1
        fi
    done
}

command="${1:-render}"

case "$command" in
    render)
        render_all
        ;;
    watch)
        watch_loop
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        exec "$@"
        ;;
esac
