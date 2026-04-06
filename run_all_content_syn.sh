#!/usr/bin/env bash
# Run Design Compiler synthesis (make syn) for every module in README "Contents" order.
# Each module's RTL/Makefile target `syn` runs dc_shell with syn.tcl (see per-module RTL/Makefile).
#
# Requires Synopsys DC in PATH (dc_shell) and any libraries/scripts referenced by syn.tcl.
# This does not run C, simulation, or compare.py — only `make syn` under each */RTL.
#
# Usage:
#   ./run_all_content_syn.sh
#   ./run_all_content_syn.sh --only binarization
#   ./run_all_content_syn.sh --help

set -u

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

ONLY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      shift
      [[ $# -ge 1 ]] || { echo "error: --only requires a module directory name"; exit 2; }
      ONLY="$1"
      ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $1"; exit 2 ;;
  esac
  shift
done

if [[ -n "$ONLY" && ! -d "$REPO_ROOT/$ONLY" ]]; then
  echo "error: module directory not found: $ONLY"
  exit 2
fi

failures=0
FAIL_LIST=()
log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }

record_fail() {
  local msg="$1"
  failures=$((failures + 1))
  FAIL_LIST+=("$msg")
  echo "FAIL: $msg"
}

run_syn_one() {
  local dir="$1"
  if [[ -n "$ONLY" && "$dir" != "$ONLY" ]]; then
    return 0
  fi
  local rtl="$REPO_ROOT/$dir/RTL"
  if [[ ! -d "$rtl" ]]; then
    record_fail "$dir — missing RTL directory"
    return
  fi
  log "[$dir] RTL: make syn"
  if ! ( cd "$rtl" && make syn ); then
    record_fail "$dir — make syn"
    return
  fi
  echo "OK: $dir"
}

echo "Repository: $REPO_ROOT"
echo "Running: make syn in each module's RTL/ (Design Compiler)"

while IFS= read -r dir; do
  [[ -z "${dir:-}" || "${dir#\#}" != "$dir" ]] && continue
  run_syn_one "$dir"
done <<'MODULES'
load_bmp_image
raw_to_bgr
raw_to_gray
image_downscaling
planar_bgr
planar_gray
bgr_to_gray
binarization
image_vertical_flip
image_horizontal_flip
image_dilation
image_erosion
connected_components
image_histogram
histogram_equalization
mean_filter
median_filter
gaussian_blur_filter
sobel_filter
laplacian_filter
MODULES

echo ""
if [[ "$failures" -gt 0 ]]; then
  echo "Done: $failures step(s) failed."
  echo "Failed ($failures):"
  for item in "${FAIL_LIST[@]}"; do
    echo "  - $item"
  done
  exit 1
fi
if [[ -n "$ONLY" ]]; then
  echo "Done: make syn for module '$ONLY' passed."
else
  echo "Done: all modules passed (make syn)."
fi
exit 0
