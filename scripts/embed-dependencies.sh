#!/usr/bin/env bash

set -euo pipefail

echo "=== Installing embedded yt-dlp and ffmpeg ==="

: "${INSTALL_DIR:?Clickable must provide INSTALL_DIR}"
: "${ARCH:?Clickable must provide ARCH}"
: "${ARCH_TRIPLET:?Clickable must provide ARCH_TRIPLET}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$INSTALL_DIR"
ffmpeg_bin_dir="$target_dir/lib/$ARCH_TRIPLET/bin"
ffmpeg_lib_dir="$target_dir/lib/$ARCH_TRIPLET"
ffmpeg_version="8.0.1"
ffmpeg_archive="/tmp/ffmpeg-${ffmpeg_version}.tar.xz"
ffmpeg_build_dir="/tmp/ffmpeg-build"

mkdir -p "$ffmpeg_bin_dir" "$ffmpeg_lib_dir"

# Standalone CPython for targets whose system Python yt-dlp no longer supports.
# Pinned with checksums from the python-build-standalone release, because this
# code ends up inside the published package.
runtime_release="20261026"
runtime_python_version="3.13.18"
runtime_tarball() {
  echo "cpython-${runtime_python_version}+${runtime_release}-$1-install_only_stripped.tar.gz"
}
runtime_sha256() {
  case "$1" in
    x86_64-unknown-linux-gnu) echo "df15fe60d3ff55bf9dcf25824b5572756bb8816ff93865a273d3301d7066a8b7" ;;
    aarch64-unknown-linux-gnu) echo "578d9da1983463ffb0c8c98ab0da2f18177f44069328eb0af847860c1eb05c3e" ;;
    armv7-unknown-linux-gnueabihf) echo "9d05f8079bcfe0d1286208925c7990ae59179e99e28c9ea310ede2a45c990818" ;;
    *) echo "No Python runtime known for $1" >&2; return 1 ;;
  esac
}
fetch_runtime() {
  local triple="$1" destination="$2" archive sha
  archive="/tmp/$(runtime_tarball "$triple")"
  sha="$(runtime_sha256 "$triple")"
  wget -q --tries=5 --timeout=60 -O "$archive" \
    "https://github.com/astral-sh/python-build-standalone/releases/download/${runtime_release}/$(runtime_tarball "$triple" | sed 's/+/%2B/')"
  echo "$sha  $archive" | sha256sum -c -
  rm -rf "$destination"
  mkdir -p "$destination"
  tar --no-same-owner -xzf "$archive" -C "$destination" --strip-components=1
  rm -f "$archive"
}

# The UI runs yt-dlp inside the system Python through PyOtherSide whenever
# yt-dlp supports that Python. The build image has the Python of its target
# system, so its version decides.
ytdlp_download_dir="/tmp/ytdlp-package"
rm -rf "$ytdlp_download_dir"

if python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)'; then
  echo "Embedding yt-dlp for the system $(python3 --version)"
  pip3 install \
    --target="$ytdlp_download_dir" \
    --no-compile \
    --no-cache-dir \
    --no-warn-script-location \
    yt-dlp
  PYTHONPATH="$ytdlp_download_dir" \
    python3 -c 'import yt_dlp; print("Embedded yt-dlp version: " + yt_dlp.version.__version__)'

  # yt-dlp is about 1,800 small modules. As one zip archive of bytecode it
  # takes a fraction of the space. The sources stay in the archive, so a later
  # Python on the device can still run it.
  mkdir -p "$target_dir/lib/python3"
  python3 "$script_dir/pack-python.py" "$ytdlp_download_dir/yt_dlp" \
    "$target_dir/lib/python3/yt_dlp.zip" --prefix yt_dlp --with-source
  du -h "$target_dir/lib/python3/yt_dlp.zip"
else
  # The current yt-dlp cannot run on this system Python, and pip would quietly
  # settle for a release that is years old. Bundle a runtime that can run it;
  # src/ytdlp_bridge.py drives it as a child process.
  echo "System $(python3 --version) is too old for yt-dlp; bundling Python ${runtime_python_version}"
  case "$ARCH" in
    arm64) runtime_triple="aarch64-unknown-linux-gnu" ;;
    armhf) runtime_triple="armv7-unknown-linux-gnueabihf" ;;
    amd64) runtime_triple="x86_64-unknown-linux-gnu" ;;
    *) echo "Unsupported Clickable architecture: $ARCH" >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) build_triple="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) build_triple="aarch64-unknown-linux-gnu" ;;
    *) echo "Unsupported build host: $(uname -m)" >&2; exit 1 ;;
  esac

  runtime_dir="$ffmpeg_lib_dir/ytdlp-runtime"
  build_python_dir="/tmp/ytdlp-build-python"
  build_python="$build_python_dir/bin/python3"
  python_minor="${runtime_python_version%.*}"
  stdlib_dir="$runtime_dir/lib/python${python_minor}"

  # yt-dlp is pure Python, so a Python for the build host can install it for
  # any target, and pip resolves against a version it actually supports.
  fetch_runtime "$build_triple" "$build_python_dir"
  fetch_runtime "$runtime_triple" "$runtime_dir"

  "$build_python" -m pip install \
    --target="$ytdlp_download_dir" \
    --no-compile \
    --no-cache-dir \
    --no-warn-script-location \
    yt-dlp
  PYTHONPATH="$ytdlp_download_dir" \
    "$build_python" -c 'import yt_dlp; print("Embedded yt-dlp version: " + yt_dlp.version.__version__)'

  # Drop everything the runtime does not need to run yt-dlp. bin/python3 has
  # the interpreter linked in, so the shared libpython beside it goes too.
  rm -rf "$runtime_dir/include" "$runtime_dir/share" "$runtime_dir/lib/pkgconfig" \
    "$runtime_dir"/lib/libpython3* \
    "$runtime_dir"/lib/itcl* "$runtime_dir"/lib/tcl* "$runtime_dir"/lib/tk* \
    "$runtime_dir"/lib/libtcl* "$runtime_dir"/lib/libtk* "$runtime_dir"/lib/thread* \
    "$stdlib_dir/test" "$stdlib_dir/idlelib" "$stdlib_dir/tkinter" \
    "$stdlib_dir/turtledemo" "$stdlib_dir/ensurepip" "$stdlib_dir/site-packages" \
    "$stdlib_dir/pydoc_data" "$stdlib_dir"/config-* "$stdlib_dir"/lib-dynload/_tkinter*
  find "$runtime_dir/bin" -mindepth 1 ! -name python3 ! -name "python${python_minor}" -delete

  # The standard library and yt-dlp, each as one zip archive of bytecode.
  # Python finds lib/pythonXY.zip by itself. os.py stays where it was, as the
  # landmark from which Python finds its installation.
  "$build_python" "$script_dir/pack-python.py" "$stdlib_dir" \
    "$runtime_dir/lib/python${python_minor/./}.zip"
  find "$stdlib_dir" -mindepth 1 -maxdepth 1 ! -name lib-dynload ! -name os.py -exec rm -rf {} +
  mkdir -p "$runtime_dir/site-packages"
  "$build_python" "$script_dir/pack-python.py" "$ytdlp_download_dir/yt_dlp" \
    "$runtime_dir/site-packages/yt_dlp.zip" --prefix yt_dlp
  rm -rf "$build_python_dir"

  file "$(readlink -f "$runtime_dir/bin/python3")"
  du -sh "$runtime_dir"
fi
rm -rf "$ytdlp_download_dir"

case "$ARCH" in
  arm64)
    ffmpeg_arch_args=(--arch=aarch64 --enable-cross-compile --cross-prefix=aarch64-linux-gnu- --target-os=linux)
    ;;
  armhf)
    # ARMv7-A is an instruction architecture, not a GCC -mcpu model.
    ffmpeg_arch_args=(--arch=arm "--extra-cflags=-march=armv7-a -mfpu=vfpv3-d16" --enable-cross-compile --cross-prefix=arm-linux-gnueabihf- --target-os=linux)
    ;;
  amd64)
    ffmpeg_arch_args=(--arch=x86_64)
    ;;
  *)
    echo "Unsupported Clickable architecture: $ARCH" >&2
    exit 1
    ;;
esac

echo "Downloading and compiling ffmpeg ${ffmpeg_version} for ${ARCH}"
wget -q -O "$ffmpeg_archive" "https://ffmpeg.org/releases/ffmpeg-${ffmpeg_version}.tar.xz"
rm -rf "$ffmpeg_build_dir"
mkdir -p "$ffmpeg_build_dir"
tar --no-same-owner -xJf "$ffmpeg_archive" -C "$ffmpeg_build_dir" --strip-components=1

pushd "$ffmpeg_build_dir" >/dev/null
./configure \
  --prefix="$target_dir" \
  --bindir="$ffmpeg_bin_dir" \
  --libdir="$ffmpeg_lib_dir" \
  "${ffmpeg_arch_args[@]}" \
  --enable-shared \
  --enable-gpl \
  --enable-small \
  --disable-doc \
  --disable-htmlpages \
  --disable-manpages \
  --disable-podpages \
  --disable-txtpages \
  --disable-debug \
  --disable-static \
  --disable-programs \
  --enable-ffmpeg \
  --enable-ffprobe \
  --disable-avdevice \
  --disable-indevs \
  --disable-outdevs \
  --disable-encoders \
  --enable-encoder=aac,mov_text,srt,subrip,ass,ssa,webvtt \
  --disable-filters \
  --enable-filter=null,anull,format,aformat,aresample,copy,acopy,trim,atrim \
  --disable-protocols \
  --enable-protocol=file,pipe,concat,crypto,data,subfile,cache,http,tcp,hls,httpproxy
make -j"$(nproc)"
make install
popd >/dev/null

# Headers and build files are for developers, not for the app.
rm -rf "$target_dir/include" "$target_dir/share/ffmpeg" "$ffmpeg_lib_dir/pkgconfig"

test -x "$ffmpeg_bin_dir/ffmpeg"
file "$ffmpeg_bin_dir/ffmpeg"

# Execute the runtime check only when the host can run the target binary.
# armhf is built for ARMv7, so an ARMv6 host is not compatible.
host_arch="$(uname -m)"
case "$ARCH:$host_arch" in
  amd64:x86_64|amd64:amd64|arm64:aarch64|arm64:arm64|armhf:armv7l|armhf:armhf)
    LD_LIBRARY_PATH="$ffmpeg_lib_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      "$ffmpeg_bin_dir/ffmpeg" -version
    ;;
  *)
    echo "Skipping ffmpeg runtime check for target ${ARCH} on host ${host_arch}"
    ;;
esac

rm -rf "$ffmpeg_build_dir" "$ffmpeg_archive"
echo "=== Embedded dependencies installed ==="
