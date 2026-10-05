# FFmpeg in Solea

Solea uses [FFmpeg](https://ffmpeg.org) 7.1.1, licensed under the
[GNU Lesser General Public License 2.1 or later](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).

- **Android**: FFmpeg runs as a separate program (`lib/<abi>/libsoleaffmpeg.so` in the APK) to convert audio for
  Chromecast. It is built from the unmodified FFmpeg source with [build.sh](build.sh), without GPL or non-free
  components.
- **Android player**: the audio decoder of the player (`lib/<abi>/libffmpegJNI.so`, AndroidX Media3
  `decoder_ffmpeg`, Apache 2.0) contains FFmpeg 6.0 (branch `release/6.0`, https://git.ffmpeg.org/ffmpeg.git), audio
  decoders only, built without GPL or non-free components with
  [build-media3-decoder.sh](build-media3-decoder.sh).
- **Other platforms**: through [ffmpeg-kit](https://github.com/sk3llo/ffmpeg_kit_flutter) (LGPL build), and through
  [libmpv](https://github.com/media-kit) for playback (LGPL build).

FFmpeg source code: https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz

Questions or written requests: contact@solea.tv
