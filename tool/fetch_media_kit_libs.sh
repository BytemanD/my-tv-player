#!/usr/bin/env bash
# Pre-download the libmpv Android jars that media_kit_libs_android_video fetches
# from GitHub releases. GitHub is often unreachable from mainland China and the
# plugin aborts with an MD5 error when a download is truncated.
#
# Usage: tool/fetch_media_kit_libs.sh
# The jars are cached in ~/.cache/luma/media-kit/v1.1.7 and copied into the
# Gradle build directory automatically by ~/.gradle/init.d/aliyun-mirrors.gradle.

set -euo pipefail

VERSION="v1.1.7"
CACHE="${HOME}/.cache/luma/media-kit/${VERSION}"
BASE="https://github.com/media-kit/libmpv-android-video-build/releases/download/${VERSION}"
MIRRORS=(
  "https://gh-proxy.com/${BASE}"
  "https://ghfast.top/${BASE}"
  "${BASE}"
)

declare -A MD5=(
  [default-arm64-v8a.jar]=83df25b61193af8fa815e373143ac9af
  [default-armeabi-v7a.jar]=22e21526fefc0a2b8f17adbec9f57590
  [default-x86_64.jar]=6fa26bf0459b11f1c0b0dbc29e5b940d
  [default-x86.jar]=0d742b756dc9d1fcd84ea271d8b68f32
)

mkdir -p "${CACHE}"

for file in "${!MD5[@]}"; do
  expected="${MD5[$file]}"
  if [[ -f "${CACHE}/${file}" ]] && [[ "$(md5sum "${CACHE}/${file}" | cut -d' ' -f1)" == "${expected}" ]]; then
    echo "cached  ${file}"
    continue
  fi

  rm -f "${CACHE}/${file}"
  for mirror in "${MIRRORS[@]}"; do
    echo "fetch   ${file} <- ${mirror%%/github.com*}"
    if curl -fL --retry 2 --retry-delay 2 --connect-timeout 15 \
        --speed-limit 1024 --speed-time 30 \
        "${mirror}/${file}" -o "${CACHE}/${file}"; then
      actual="$(md5sum "${CACHE}/${file}" | cut -d' ' -f1)"
      if [[ "${actual}" == "${expected}" ]]; then
        echo "ok      ${file}"
        break
      fi
      echo "md5     ${file}: expected ${expected}, got ${actual}"
    fi
    rm -f "${CACHE}/${file}"
  done

  if [[ ! -f "${CACHE}/${file}" ]]; then
    echo "error   could not download ${file}" >&2
    exit 1
  fi
done

echo "All media_kit jars ready in ${CACHE}"
