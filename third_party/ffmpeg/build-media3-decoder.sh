#!/usr/bin/env bash
# Audio decoder of Solea's Android player: AndroidX Media3 decoder_ffmpeg (Apache 2.0) with FFmpeg built from the
# unmodified source, audio decoders only, without GPL or non-free components (LGPL 2.1 or later), statically linked
# into libffmpegJNI.so.
#
# Usage (Linux, Android NDK and JDK 17 installed): ANDROID_NDK_HOME=... ./build-media3-decoder.sh
#   -> out/lib-decoder-ffmpeg-release.aar
set -euo pipefail

MEDIA3_VERSION=1.11.1   # Media3 version used by the app
FFMPEG_BRANCH=release/6.0
API=24
DECODERS=(vorbis opus flac alac pcm_mulaw pcm_alaw mp3 mp2 amrnb amrwb aac ac3 eac3 dca mlp truehd)
NDK=${ANDROID_NDK_HOME:?ANDROID_NDK_HOME missing}
ROOT=$(cd "$(dirname "$0")" && pwd)
WORK=$ROOT/work
mkdir -p "$WORK" "$ROOT/out"
cd "$WORK"

[ -d media ] || git clone --depth 1 --branch "$MEDIA3_VERSION" https://github.com/androidx/media.git
[ -d ffmpeg ] || git clone --depth 1 --branch "$FFMPEG_BRANCH" https://git.ffmpeg.org/ffmpeg.git

MODULE=$WORK/media/libraries/decoder_ffmpeg/src/main
ln -sfn "$WORK/ffmpeg" "$MODULE/jni/ffmpeg"
(cd "$MODULE/jni" && ./build_ffmpeg.sh "$MODULE" "$NDK" linux-x86_64 "$API" "${DECODERS[@]}")

# License check: no GPL or non-free part enabled.
if grep -rqE '^#define CONFIG_(GPL|NONFREE) 1' "$WORK/ffmpeg"/config*.h 2>/dev/null; then
  echo "FFmpeg configured with a GPL or non-free option: refused" >&2
  exit 1
fi

(cd "$WORK/media" && ./gradlew --no-daemon :lib-decoder-ffmpeg:assembleRelease)
cp "$WORK/media/libraries/decoder_ffmpeg/buildout/outputs/aar/lib-decoder-ffmpeg-release.aar" "$ROOT/out/"
echo "OK : $ROOT/out/lib-decoder-ffmpeg-release.aar"
