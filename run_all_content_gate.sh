#!/usr/bin/env bash
# Run all modules listed in README "Contents" in order: build and run C, gate-level simulation
# (make vcs_gate or irun_gate per module RTL/Makefile), then compare C vs gate output with compare.py.
#
# Same input file requirements as run_all_content_rtl.sh (lena256.bmp, raw files, median noise, etc.).
#
# Usage:
#   ./run_all_content_gate.sh                    # default RTL_TOOL=vcs (make vcs_gate)
#   ./run_all_content_gate.sh --rtl-tool irun  # make irun_gate
#   ./run_all_content_gate.sh --rtl-tool=vcs
#   RTL_TOOL=irun ./run_all_content_gate.sh
#   ./run_all_content_gate.sh --skip-rtl       # C only
#   ./run_all_content_gate.sh --only median_filter
#   RUN_RTL=0 ./run_all_content_gate.sh
#
# RTL_TOOL must be vcs or irun (no Icarus gate target in this repo).
#
# laplacian_filter has no compare.py; C and simulation still run, comparison is skipped.

set -u

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

SKIP_RTL=0
ONLY=""
RTL_TOOL="${RTL_TOOL:-vcs}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-rtl) SKIP_RTL=1 ;;
    --only)
      shift
      [[ $# -ge 1 ]] || { echo "error: --only requires a module directory name"; exit 2; }
      ONLY="$1"
      ;;
    --rtl-tool)
      shift
      [[ $# -ge 1 ]] || { echo "error: --rtl-tool requires vcs or irun"; exit 2; }
      RTL_TOOL="$1"
      ;;
    --rtl-tool=*)
      RTL_TOOL="${1#*=}"
      ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $1"; exit 2 ;;
  esac
  shift
done

[[ -n "${RUN_RTL:-}" && "$RUN_RTL" == "0" ]] && SKIP_RTL=1

case "$RTL_TOOL" in
  vcs|irun) ;;
  *)
    echo "error: gate RTL_TOOL must be vcs or irun (got: $RTL_TOOL)"
    exit 2
    ;;
esac

if [[ -n "$ONLY" && ! -d "$REPO_ROOT/$ONLY" ]]; then
  echo "error: module directory not found: $ONLY"
  exit 2
fi

need_file() {
  local f="$1"
  local msg="$2"
  if [[ ! -f "$f" ]]; then
    echo "error: missing file: $f"
    echo "       $msg"
    return 1
  fi
  return 0
}

failures=0
FAIL_LIST=()
log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }

record_fail() {
  local msg="$1"
  failures=$((failures + 1))
  FAIL_LIST+=("$msg")
  echo "FAIL: $msg"
}

gate_make_target() {
  case "$RTL_TOOL" in
    vcs)  echo vcs_gate ;;
    irun) echo irun_gate ;;
  esac
}

run_one() {
  local dir="$1"
  local exe="$2"
  local c_args="$3"
  local has_compare="$4"
  local mk_gate
  mk_gate="$(gate_make_target)"

  if [[ -n "$ONLY" && "$dir" != "$ONLY" ]]; then
    return 0
  fi

  log "[$dir] C: make + ./$exe $c_args"
  if ! ( cd "$REPO_ROOT/$dir/C" && make ); then
    record_fail "$dir — C make"
    return
  fi
  if ! ( cd "$REPO_ROOT/$dir/C" && eval "./$exe $c_args" ); then
    record_fail "$dir — C run"
    return
  fi

  if [[ "$SKIP_RTL" -eq 1 ]]; then
    log "[$dir] skipping gate simulation (--skip-rtl)"
    return 0
  fi

  log "[$dir] gate: make $mk_gate (tool=$RTL_TOOL, may take several minutes)"
  if ! ( cd "$REPO_ROOT/$dir/RTL" && make "$mk_gate" ); then
    record_fail "$dir — gate make $mk_gate ($RTL_TOOL)"
    return
  fi

  if [[ "$has_compare" != "1" ]]; then
    log "[$dir] no compare.py, skipping comparison"
    return 0
  fi

  log "[$dir] python3 compare.py"
  if ! ( cd "$REPO_ROOT/$dir" && python3 compare.py ); then
    record_fail "$dir — compare.py"
    return
  fi

  echo "OK: $dir"
}

ensure_median_noise() {
  local noise="$REPO_ROOT/median_filter/lena256_noise.bmp"
  local src="$REPO_ROOT/median_filter/lena256.bmp"
  [[ -f "$noise" ]] && return 0
  need_file "$src" "median_filter needs lena256.bmp to generate lena256_noise.bmp (or add the noise file yourself)" || return 1
  log "Generating median_filter/lena256_noise.bmp (add_noise.py)"
  ( cd "$REPO_ROOT/median_filter" && python3 add_noise.py -i "$src" -o ./lena256_noise.bmp )
}

echo "Repository: $REPO_ROOT"
echo "Gate simulator: $RTL_TOOL (make $(gate_make_target))"

check_prereqs() {
  if [[ -n "$ONLY" ]]; then
    case "$ONLY" in
      raw_to_bgr)
        need_file "$REPO_ROOT/raw_to_bgr/lena256_rgb.raw" "required for raw_to_bgr" || return 1
        ;;
      raw_to_gray)
        need_file "$REPO_ROOT/raw_to_gray/lena256_gray.raw" "required for raw_to_gray" || return 1
        ;;
      median_filter)
        need_file "$REPO_ROOT/median_filter/lena256.bmp" "required for add_noise / median_filter" || return 1
        ensure_median_noise || return 1
        ;;
      *)
        need_file "$REPO_ROOT/$ONLY/lena256.bmp" "required for this module (put lena256.bmp inside the module folder)" || return 1
        ;;
    esac
    return 0
  fi
  need_file "$REPO_ROOT/raw_to_bgr/lena256_rgb.raw" "put lena256_rgb.raw inside raw_to_bgr/" || return 1
  need_file "$REPO_ROOT/raw_to_gray/lena256_gray.raw" "put lena256_gray.raw inside raw_to_gray/" || return 1
  ensure_median_noise || return 1
  return 0
}

check_prereqs || exit 1

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required"
  exit 1
fi

while IFS='|' read -r dir exe c_args has_compare; do
  [[ -z "${dir:-}" || "${dir#\#}" != "$dir" ]] && continue
  run_one "$dir" "$exe" "$c_args" "$has_compare"
done <<'MODULES'
load_bmp_image|load_bmp_image.o|../lena256.bmp|1
raw_to_bgr|raw_to_bgr.o|../lena256_rgb.raw|1
raw_to_gray|raw_to_gray.o|../lena256_gray.raw|1
bgr_to_gray|bgr2gray.o|../lena256.bmp|1
binarization|binarization.o|../lena256.bmp|1
image_vertical_flip|vertical_flip.o|../lena256.bmp|1
image_horizontal_flip|horizontal_flip.o|../lena256.bmp|1
image_dilation|image_dilation.o|../lena256.bmp|1
image_erosion|image_erosion.o|../lena256.bmp|1
connected_components|connected_components.o|../lena256.bmp|1
image_histogram|image_histogram.o|../lena256.bmp|1
histogram_equalization|histogram_equalization.o|../lena256.bmp|1
mean_filter|mean_filter.o|../lena256.bmp|1
median_filter|median_filter.o|../lena256_noise.bmp|1
gaussian_blur_filter|gaussian_blur.o|../lena256.bmp|1
sobel_filter|sobel_filter.o|../lena256.bmp|1
laplacian_filter|laplacian_filter.o|../lena256.bmp|1
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
if [[ "$SKIP_RTL" -eq 1 ]]; then
  echo "Done: C stages only (gate and compare skipped)."
else
  echo "Done: all modules passed (gate, $RTL_TOOL)."
fi
exit 0
