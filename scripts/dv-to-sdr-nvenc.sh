#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
dv-to-sdr-nvenc.sh: Transcode Dolby Vision (often Profile 5 / DV-only) to SDR for Kodi-safe playback.

Fast path: OpenCL tonemap -> NVENC encode (requires NVIDIA + OpenCL + NVENC).
Fallback: CPU zscale+tonemap -> libx265 (slow, but works when GPU path fails).

Usage:
  dv-to-sdr-nvenc.sh -i INPUT.mkv [-o OUTPUT.mkv] [--codec hevc|h264] [--cq N] [--preset P] [--peak NITS] [--yes]

Examples:
  dv-to-sdr-nvenc.sh -i "Movie (DV).mkv" --codec hevc --cq 22 --yes
  dv-to-sdr-nvenc.sh -i "Episode.mkv" -o "Episode SDR.mkv"

Notes:
  - This script keeps all audio/subtitle streams: -c:a copy -c:s copy
  - Output is SDR BT.709.
EOF
}

in=""
out=""
codec="hevc"    # hevc_nvenc or h264_nvenc
preset="p5"
peak="1000"
yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input) in="${2:-}"; shift 2;;
    -o|--output) out="${2:-}"; shift 2;;
    --codec) codec="${2:-}"; shift 2;;
    --cq) cq="${2:-}"; shift 2;;
    --preset) preset="${2:-}"; shift 2;;
    --peak) peak="${2:-}"; shift 2;;
    -y|--yes) yes=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2;;
  esac
done

if [[ -z "${in}" ]]; then
  echo "Missing -i/--input" >&2
  usage
  exit 2
fi
if [[ ! -f "${in}" ]]; then
  echo "Input not found: ${in}" >&2
  exit 2
fi

if [[ "${codec}" != "hevc" && "${codec}" != "h264" ]]; then
  echo "--codec must be 'hevc' or 'h264' (got: ${codec})" >&2
  exit 2
fi

if [[ -z "${out}" ]]; then
  base="${in##*/}"
  stem="${base%.*}"
  if [[ "${codec}" == "hevc" ]]; then
    out="${stem} SDR NVENC HEVC.mkv"
  else
    out="${stem} SDR NVENC H264.mkv"
  fi
fi

if [[ "${codec}" == "hevc" ]]; then
  vcodec="hevc_nvenc"
  : "${cq:=22}"
else
  vcodec="h264_nvenc"
  : "${cq:=19}"
fi

overwrite=()
if [[ "${yes}" -eq 1 ]]; then
  overwrite=(-y)
fi

echo "Input:  ${in}"
echo "Output: ${out}"
echo "Video:  ${vcodec} preset=${preset} cq=${cq} peak=${peak}"

probe_dovi() {
  nix shell nixpkgs#ffmpeg -c ffprobe -hide_banner -loglevel error \
    -select_streams v:0 -show_streams "$in" 2>/dev/null | \
    grep -E "side_data_type=DOVI|dv_profile=" || true
}

dovi="$(probe_dovi || true)"
if [[ -n "${dovi}" ]]; then
  echo "Detected Dolby Vision metadata:"
  echo "${dovi}" | sed 's/^/  /'
else
  echo "No Dolby Vision metadata detected by ffprobe (still proceeding)."
fi

# GPU path: OpenCL tonemap (on whatever OpenCL platform is default) + NVENC encode.
vf_opencl="setparams=color_primaries=bt2020:color_trc=smpte2084:colorspace=bt2020nc,format=p010le,hwupload,tonemap_opencl=tonemap=hable:format=nv12:primaries=bt709:transfer=bt709:matrix=bt709:range=tv:peak=${peak},hwdownload,format=nv12"

set +e
nix shell nixpkgs#ffmpeg -c ffmpeg -hide_banner -stats "${overwrite[@]}" \
  -init_hw_device opencl=ocl -filter_hw_device ocl \
  -i "$in" \
  -map 0 -map_metadata 0 -map_chapters 0 \
  -vf "${vf_opencl}" \
  -c:v "${vcodec}" -preset "${preset}" -cq "${cq}" -b:v 0 \
  -c:a copy -c:s copy -max_muxing_queue_size 4096 \
  "$out"
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  echo "Done (GPU): ${out}"
  exit 0
fi

echo "GPU path failed (exit ${rc}); falling back to CPU tone-map + libx265 (slow)." >&2

# CPU fallback: explicitly set in/out colorspaces because DV files are often untagged.
vf_cpu="zscale=primariesin=bt2020:transferin=smpte2084:matrixin=bt2020nc:rangein=tv:primaries=bt2020:transfer=smpte2084:matrix=bt2020nc:range=tv,format=gbrpf32le,zscale=transfer=linear:npl=100,tonemap=tonemap=hable:desat=0,zscale=primaries=bt709:transfer=bt709:matrix=bt709:range=tv,format=yuv420p"

nix shell nixpkgs#ffmpeg -c ffmpeg -hide_banner -stats "${overwrite[@]}" \
  -i "$in" \
  -map 0 -map_metadata 0 -map_chapters 0 \
  -vf "${vf_cpu}" \
  -c:v libx265 -preset medium -crf 20 \
  -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
  -c:a copy -c:s copy -max_muxing_queue_size 4096 \
  "$out"

echo "Done (CPU fallback): ${out}"

