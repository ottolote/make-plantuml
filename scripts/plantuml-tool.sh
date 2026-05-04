#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
OUTPUT_DIR="${OUTPUT_DIR:-}"
FORMATS="${FORMATS:-svg,png}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

log() {
    printf '[plantuml-tool] %s\n' "$*"
}

usage() {
    cat <<'EOF'
Usage: plantuml-tool [options] <command>

Options:
  -o, --output <dir>   Set output directory relative to workspace (overrides OUTPUT_DIR)

Commands:
  render   Render all *.pu and *.puml files in the workspace
  watch    Render once, then re-render on *.pu/*.puml changes
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
    if [ -n "$OUTPUT_DIR" ]; then
        find "$WORKSPACE" \
            -path "$WORKSPACE/$OUTPUT_DIR" -prune -o \
            -type f \( -name '*.pu' -o -name '*.puml' \) -print0 | sort -z
    else
        find "$WORKSPACE" \
            -type f \( -name '*.pu' -o -name '*.puml' \) -print0 | sort -z
    fi
}

render_all() {
    local force="${1:-false}"
    ensure_workspace

    if [ "$force" = "true" ]; then
        log "Running make all (force re-render)..."
        make -B -f /opt/Makefile -C "$WORKSPACE" all OUTPUT_DIR="$OUTPUT_DIR" FORMATS="$FORMATS"
    else
        log "Running make all..."
        make -f /opt/Makefile -C "$WORKSPACE" all OUTPUT_DIR="$OUTPUT_DIR" FORMATS="$FORMATS"
    fi
}

watch_loop() {
    ensure_workspace

    if ! command -v entr >/dev/null 2>&1; then
        echo "Error: entr is required for watch mode." >&2
        exit 1
    fi

    trap 'log "Stopping watch mode"; exit 0' INT TERM

    render_all false

    while true; do
        local files=()
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(collect_sources)

        if [ "${#files[@]}" -eq 0 ]; then
            log "Waiting for .pu or .puml files in $WORKSPACE"
            sleep "$POLL_INTERVAL"
            continue
        fi

        log "Watching ${#files[@]} PlantUML source file(s)"

        if ! printf '%s\n' "${files[@]}" | entr -d -n env WORKSPACE="$WORKSPACE" OUTPUT_DIR="$OUTPUT_DIR" "$SELF_PATH" render-incremental; then
            sleep 1
        fi
    done
}

COMMAND=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            export OUTPUT_DIR="$2"
            shift 2
            ;;
        render|render-incremental|watch|help|-h|--help)
            if [ -z "$COMMAND" ]; then
                COMMAND="$1"
            else
                ARGS+=("$1")
            fi
            shift
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

if [ "$COMMAND" = "help" ] || [ "$COMMAND" = "-h" ] || [ "$COMMAND" = "--help" ]; then
    usage
    exit 0
fi

if [ -n "$COMMAND" ]; then
    case "$COMMAND" in
        render)
            render_all true
            ;;
        render-incremental)
            render_all false
            ;;
        watch)
            watch_loop
            ;;
    esac
else
    if [ ${#ARGS[@]} -eq 0 ]; then
        render_all true
    else
        exec "${ARGS[@]}"
    fi
fi
