#!/usr/bin/env bash
# FFmpeg as a separate program for Solea on Android (audio conversion for Chromecast: Dolby / DTS to AAC, video
# copied). Shipped in the APK as lib/<abi>/libsoleaffmpeg.so: Android only allows executing files from the app's
# native library folder.
#
# License: FFmpeg under the GNU LGPL 2.1 or later (no --enable-gpl, no --enable-nonfree). FFmpeg source is unmodified:
# https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz . This script is the complete build recipe.
#
# Usage (Linux, Android NDK installed): ANDROID_NDK_HOME=... ./build.sh  → out/<abi>/libsoleaffmpeg.so
set -euo pipefail

FFMPEG_VERSION=7.1.1
API=24
NDK=${ANDROID_NDK_HOME:?ANDROID_NDK_HOME missing}
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
ROOT=$(cd "$(dirname "$0")" && pwd)
OUT=$ROOT/out
WORK=$ROOT/work

mkdir -p "$WORK" "$OUT"
cd "$WORK"
if [ ! -d "ffmpeg-$FFMPEG_VERSION" ]; then
  curl -fsSL "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz" | tar xJ
fi
cd "ffmpeg-$FFMPEG_VERSION"

# Only what the relays need: read MKV / MP4 / TS over HTTP, decode audio, encode AAC, write fragmented MP4
# (served over HTTP with -listen) or HLS with MP4 segments.
COMPONENTS=(
  --disable-everything
  --enable-protocol=file,http,tcp,pipe
  --enable-demuxer=matroska,mov,mpegts,aac,ac3,eac3,dts,truehd,mp3,flac,ogg,wav
  --enable-decoder=ac3,eac3,dca,truehd,mlp,aac,aac_latm,mp3,mp2,opus,flac,vorbis,pcm_s16le,pcm_s24le,pcm_s16be,pcm_bluray,pcm_dvd
  --enable-encoder=aac
  --enable-parser=aac,aac_latm,ac3,dca,mlp,mpegaudio,opus,flac,vorbis,h264,hevc,av1,vp9,mpeg4video,mpegvideo
  --enable-bsf=aac_adtstoasc,h264_mp4toannexb,hevc_mp4toannexb,extract_extradata,vp9_superframe,av1_frame_split
  --enable-muxer=mp4,mov,ipod,hls,mpegts,adts
  --enable-filter=aformat,aresample,volume,alimiter,anull,atrim,asetpts,pan,channelmap,format,null
)

build() {
  local abi=$1 arch=$2 cpu=$3 triple=$4
  shift 4
  make distclean >/dev/null 2>&1 || true
  ./configure \
    --target-os=android --arch="$arch" --cpu="$cpu" --enable-cross-compile \
    --cc="$TOOLCHAIN/bin/${triple}${API}-clang" \
    --cxx="$TOOLCHAIN/bin/${triple}${API}-clang++" \
    --nm="$TOOLCHAIN/bin/llvm-nm" --ar="$TOOLCHAIN/bin/llvm-ar" --ranlib="$TOOLCHAIN/bin/llvm-ranlib" \
    --strip="$TOOLCHAIN/bin/llvm-strip" \
    --sysroot="$TOOLCHAIN/sysroot" \
    --enable-static --disable-shared --enable-pic \
    --disable-doc --disable-ffplay --disable-ffprobe --disable-debug --disable-autodetect \
    --enable-ffmpeg --enable-swresample --enable-avfilter \
    --extra-cflags="-O2 -fPIE" --extra-ldflags="-pie -Wl,-z,max-page-size=16384" \
    "${COMPONENTS[@]}" "$@"
  make -j"$(nproc)" ffmpeg
  mkdir -p "$OUT/$abi"
  "$TOOLCHAIN/bin/llvm-strip" -o "$OUT/$abi/libsoleaffmpeg.so" ffmpeg
  ls -l "$OUT/$abi/libsoleaffmpeg.so"
}

build arm64-v8a aarch64 armv8-a aarch64-linux-android --enable-neon
build armeabi-v7a arm armv7-a armv7a-linux-androideabi --enable-neon --enable-thumb
build x86_64 x86_64 x86-64 x86_64-linux-android --disable-asm
