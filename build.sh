#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# --- NEW: Define defaults at the top so the help menu can see them ---
DEFAULT_TARGETS=("ijon_max_example" "ijon_set_example")

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TARGETS...]

Compiles AFL++ targets with plain AFL and IJON, and generates fuzzing helper scripts.

Options:
  -h, --help    Show this help message and exit

Arguments:
  TARGETS       List of target directory names in src/ to compile.
                If none are provided, defaults to: ${DEFAULT_TARGETS[*]}

Example:
  $(basename "$0")                  # Builds default targets
  $(basename "$0") custom_target    # Builds src/custom_target/example.c
EOF
}

targets=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            targets+=("$1")
            shift
            ;;
    esac
done

# --- FIX: Use the shared defaults array here ---
if [[ ${#targets[@]} -eq 0 ]]; then
    targets=("${DEFAULT_TARGETS[@]}")
fi

# --- Absolute Path Resolution ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
SRC_DIR="${PROJECT_ROOT}/src"
HELPER_DIR="${PROJECT_ROOT}/helper_scripts"
OUT_DIR="${PROJECT_ROOT}/afl_out"
IN_DIR="${PROJECT_ROOT}/in"
TEMPLATE_FILE="${PROJECT_ROOT}/fuzz_template.sh"

# --- Pre-flight Checks ---
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file '$TEMPLATE_FILE' not found." >&2
    exit 1
fi

afl_compiler="afl-clang-fast"
export FUZZER="afl-fuzz" 

for tool in "$afl_compiler" "$FUZZER" "envsubst"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: Required tool '$tool' not found in PATH." >&2
        exit 1
    fi
done

# --- Setup Directories ---
mkdir -p "$BUILD_DIR" "$HELPER_DIR" "$OUT_DIR" "$IN_DIR"

if [[ -z "$(ls -A "$IN_DIR")" ]]; then
    echo "R" > "${IN_DIR}/seed.txt" # Create a dummy seed
fi

export IN_DIR="$IN_DIR"

echo "Building targets: ${targets[*]}"
echo "----------------------------------------"

for t in "${targets[@]}"; do
    src_file="${SRC_DIR}/${t}/example.c"
    
    target_plain="${t}_plain_afl"
    target_ijon="${t}_ijon_afl"

    if [[ ! -f "$src_file" ]]; then
        echo "Error: Source file $src_file not found. Skipping $t..." >&2
        continue
    fi

    echo "Compiling $t with plain AFL++."
    "$afl_compiler" "$src_file" -o "${BUILD_DIR}/$target_plain"
    echo "Compiling $t with IJON."
    AFL_LLVM_IJON=1 "$afl_compiler" "$src_file" -o "${BUILD_DIR}/$target_ijon"
    
    echo "Creating helper scripts for $t..."
    
    # Generate Script 1: Plain AFL
    export OUT_DIR_FULL="${OUT_DIR}/${target_plain}_out"
    export TARGET_BIN="${BUILD_DIR}/${target_plain}"
    
    plain_script="${HELPER_DIR}/run_${target_plain}_fuzzing.sh"
    envsubst < "$TEMPLATE_FILE" > "$plain_script"
    chmod +x "$plain_script"

    # Generate Script 2: IJON
    export OUT_DIR_FULL="${OUT_DIR}/${target_ijon}_out"
    export TARGET_BIN="${BUILD_DIR}/${target_ijon}"
    
    ijon_script="${HELPER_DIR}/run_${target_ijon}_fuzzing.sh"
    envsubst < "$TEMPLATE_FILE" > "$ijon_script"
    chmod +x "$ijon_script"

    echo "Done with $t."
    echo "----------------------------------------"
done

echo "All builds and helper scripts generated successfully in $PROJECT_ROOT."