#!/usr/bin/env bash

set -euo pipefail

SDL_PREFIX="${PWD}/.sdl3-wasm"
BUILD_ROOT="${PWD}/.sdl3-build"

SDL3_VERSION="3.4.10"
SDL3_IMAGE_VERSION="3.4.4"
SDL3_TTF_VERSION="3.2.2"
SDL3_MIXER_VERSION="3.2.4"

rm -rf "${SDL_PREFIX}" "${BUILD_ROOT}"
mkdir -p "${SDL_PREFIX}" "${BUILD_ROOT}"

export PKG_CONFIG_PATH="${SDL_PREFIX}/lib/pkgconfig"
export CMAKE_PREFIX_PATH="${SDL_PREFIX}"

cd "${BUILD_ROOT}"

clone_release() {
    local repo="$1"
    local version="$2"
    local dir="$3"

    echo "DEBUG: repo='${repo}'"
    echo "DEBUG: version='${version}'"
    echo "DEBUG: dir='${dir}'"
    echo "DEBUG: branch='release-${version}'"

    git clone --depth 1 \
        --branch "release-${version}" \
        "https://github.com/libsdl-org/${repo}.git" \
        "${dir}"
}

cmake_build_install() {
    local source="$1"
    local build="$2"
    shift 2

    emcmake cmake \
        -S "${source}" \
        -B "${build}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${SDL_PREFIX}" \
        -DBUILD_SHARED_LIBS=OFF \
        "$@"

    cmake --build "${build}" -j"$(nproc)"
    cmake --install "${build}"
}

#
# SDL3
#

echo "DEBUG: SDL3_VERSION='${SDL3_VERSION}'"
echo "DEBUG: clone args: SDL '${SDL3_VERSION}' sdl3"

clone_release SDL "${SDL3_VERSION}" sdl3

cmake_build_install sdl3 sdl3-build \
    -DSDL_TESTS=OFF \
    -DSDL_EXAMPLES=OFF

#
# SDL3_image
#
# Use the vendored dependencies. This is important for Emscripten:
# Ubuntu's native libpng/libjpeg/etc. cannot be linked into WASM.
#

clone_release SDL_image "${SDL3_IMAGE_VERSION}" sdl3_image

cmake_build_install sdl3_image sdl3-image-build \
    -DSDLIMAGE_TESTS=OFF \
    -DSDLIMAGE_SAMPLES=OFF \
    -DSDLIMAGE_VENDORED=ON \
    -DSDLIMAGE_AVIF=OFF \
    -DSDLIMAGE_JXL=OFF \
    -DSDLIMAGE_TIF=OFF \
    -DSDLIMAGE_WEBP=OFF

#
# SDL3_ttf
#

clone_release SDL_ttf "${SDL3_TTF_VERSION}" sdl3_ttf

cmake_build_install sdl3_ttf sdl3-ttf-build \
    -DSDLTTF_TESTS=OFF \
    -DSDLTTF_SAMPLES=OFF \
    -DSDLTTF_VENDORED=ON

#
# SDL3_mixer
#
# Again, use vendored codec dependencies so everything is built for WASM.
#

clone_release SDL_mixer "${SDL3_MIXER_VERSION}" sdl3_mixer

cmake_build_install sdl3_mixer sdl3-mixer-build \
    -DSDLMIXER_TESTS=OFF \
    -DSDLMIXER_SAMPLES=OFF \
    -DSDLMIXER_VENDORED=ON \
    -DSDLMIXER_DEPS_SHARED=OFF \
    -DSDLMIXER_FLAC=ON \
    -DSDLMIXER_FLAC_LIBFLAC=ON \
    -DSDLMIXER_FLAC_DRFLAC=OFF \
    -DSDLMIXER_MP3=ON \
    -DSDLMIXER_MP3_MPG123=ON \
    -DSDLMIXER_MP3_DRMP3=OFF \
    -DSDLMIXER_VORBIS_VORBISFILE=ON \
    -DSDLMIXER_VORBIS_STB=OFF \
    -DSDLMIXER_VORBIS_TREMOR=OFF \
    -DSDLMIXER_WAVPACK=ON \
    -DSDLMIXER_OPUS=OFF \
    -DSDLMIXER_MOD=OFF \
    -DSDLMIXER_MIDI=OFF \
    -DSDLMIXER_GME=OFF

cd "${OLDPWD}"

echo "SDL WASM libraries installed in ${SDL_PREFIX}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"

pkg-config --modversion sdl3
pkg-config --modversion sdl3-image
pkg-config --modversion sdl3-ttf
pkg-config --modversion sdl3-mixer

#
# CDDA
#

make -j"$(nproc)" \
    NATIVE=emscripten \
    TILES=1 \
    SOUND=1 \
    BACKTRACE=0 \
    TESTS=0 \
    RUNTESTS=0 \
    RELEASE=1 \
    LINTJSON=0 \
    cataclysm-tiles.js
