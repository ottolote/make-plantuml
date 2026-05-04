#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-local/make-plantuml:dev}"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES="$TEST_DIR/fixtures"

echo "Running tests against image: $IMAGE"

# Determine runtime and default user flags
DOCKER_CMD="docker"
USER_FLAGS=("--user" "$(id -u):$(id -g)")
if command -v podman >/dev/null 2>&1 && docker --help | grep -qi podman; then
    # When running under Podman, --user causes uid mapping issues without keep-id
    USER_FLAGS=("--userns=keep-id")
    DOCKER_CMD="podman"
fi

# Helper to set up a clean workspace for a test
setup_workspace() {
    local ws="$1"
    rm -rf "$ws"
    mkdir -p "$ws"
    cp -r "$FIXTURES/src/"* "$ws/"
}

fail() {
    echo "❌ FAIL: $*" >&2
    exit 1
}

pass() {
    echo "✅ PASS: $1"
}

# --- Tests ---

test_default_render() {
    echo "--- Test: Default Render ---"
    local ws="$TEST_DIR/tmp/default"
    setup_workspace "$ws"

    $DOCKER_CMD run --rm "${USER_FLAGS[@]}" -v "$ws:/workspace:z" "$IMAGE" render

    [[ -f "$ws/test.svg" ]] || fail "test.svg not generated side-by-side"
    [[ -f "$ws/test.png" ]] || fail "test.png not generated side-by-side"
    
    # Ownership check
    if [[ "$(stat -c '%u' "$ws/test.svg")" != "$(id -u)" ]]; then
        fail "test.svg is not owned by the current user"
    fi
    pass "Default render generated SVG and PNG side-by-side with correct permissions"
}

test_custom_format() {
    echo "--- Test: Custom Format (svg only) ---"
    local ws="$TEST_DIR/tmp/format"
    setup_workspace "$ws"

    $DOCKER_CMD run --rm "${USER_FLAGS[@]}" -e FORMATS=svg -v "$ws:/workspace:z" "$IMAGE" render

    [[ -f "$ws/test.svg" ]] || fail "test.svg not generated"
    [[ ! -f "$ws/test.png" ]] || fail "test.png should not have been generated"
    pass "Custom format respected (only SVG generated)"
}

test_output_dir_env() {
    echo "--- Test: Output Dir (ENV) ---"
    local ws="$TEST_DIR/tmp/outdir_env"
    setup_workspace "$ws"

    $DOCKER_CMD run --rm "${USER_FLAGS[@]}" -e OUTPUT_DIR=artifacts -v "$ws:/workspace:z" "$IMAGE" render

    [[ -f "$ws/artifacts/test.svg" ]] || fail "artifacts/test.svg not generated"
    [[ ! -f "$ws/test.svg" ]] || fail "test.svg should not be at root"
    pass "OUTPUT_DIR environment variable respected"
}

test_output_dir_flag() {
    echo "--- Test: Output Dir (Flag) ---"
    local ws="$TEST_DIR/tmp/outdir_flag"
    setup_workspace "$ws"

    $DOCKER_CMD run --rm "${USER_FLAGS[@]}" -v "$ws:/workspace:z" "$IMAGE" render -o artifacts

    [[ -f "$ws/artifacts/test.svg" ]] || fail "artifacts/test.svg not generated"
    [[ ! -f "$ws/test.svg" ]] || fail "test.svg should not be at root"
    pass "Output directory flag (-o) respected"
}

# --- Run ---

rm -rf "$TEST_DIR/tmp"
mkdir -p "$TEST_DIR/tmp"

test_default_render
test_custom_format
test_output_dir_env
test_output_dir_flag

echo "🎉 All tests passed!"
