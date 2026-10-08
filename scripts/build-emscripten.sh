#!/bin/bash

set -exo pipefail

CCACHE=${CCACHE:-0}

SDL3_VERSION=3.4.10
SDL3_IMAGE_VERSION=3.4.4
SDL3_TTF_VERSION=3.2.2
SDL3_MIXER_VERSION=3.2.4

SDL_PREFIX="${PWD}/.sdl3-wasm"

# Emscripten is installed by the GitHub Actions workflow.
emcc --version

rm -rf "$SDL_PREFIX"
mkdir -p "$SDL_PREFIX"

BUILD_ROOT="$(mktemp -d)"
trap 'rm -rf "$BUILD_ROOT"' EXIT

cd "$BUILD_ROOT"

build_cmake_project() {
    local source="$1"
    local build="$2"
    shift 2

    cmake -S "$source" -B "$build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$SDL_PREFIX" \
        -DCMAKE_C_COMPILER=emcc \
        -DCMAKE_CXX_COMPILER=em++ \
        -DCMAKE_AR=emar \
        -DCMAKE_RANLIB=emranlib \
        -DBUILD_SHARED_LIBS=OFF \
        "$@"

    cmake --build "$build" -j"$(nproc)"
    cmake --install "$build"
}

# SDL3
git clone --depth 1 \
    --branch "release-${SDL3_VERSION}" \
    https://github.com/libsdl-org/SDL.git sdl3

build_cmake_project sdl3 sdl3_build

# SDL3_image
git clone --depth 1 \
    --branch "release-${SDL3_IMAGE_VERSION}" \
    https://github.com/libsdl-org/SDL_image.git sdl3_image

build_cmake_project sdl3_image sdl3_image_build \
    -DSDLIMAGE_VENDORED=OFF \
    -DSDLIMAGE_DEPS_SHARED=OFF \
    -DSDLIMAGE_PNG=ON \
    -DSDLIMAGE_PNG_LIBPNG=ON \
    -DSDLIMAGE_JPG=ON \
    -DSDLIMAGE_AVIF=OFF \
    -DSDLIMAGE_JXL=OFF \
    -DSDLIMAGE_TIF=OFF \
    -DSDLIMAGE_WEBP=OFF

# SDL3_ttf
git clone --depth 1 \
    --branch "release-${SDL3_TTF_VERSION}" \
    https://github.com/libsdl-org/SDL_ttf.git sdl3_ttf

build_cmake_project sdl3_ttf sdl3_ttf_build \
    -DSDLTTF_VENDORED=OFF \
    -DSDLTTF_PLUTOSVG=OFF

# SDL3_mixer
git clone --depth 1 \
    --branch "release-${SDL3_MIXER_VERSION}" \
    https://github.com/libsdl-org/SDL_mixer.git sdl3_mixer

build_cmake_project sdl3_mixer sdl3_mixer_build \
    -DSDLMIXER_VENDORED=OFF \
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

cd "$OLDPWD"

export PKG_CONFIG_PATH="${SDL_PREFIX}/lib/pkgconfig"
export CMAKE_PREFIX_PATH="$SDL_PREFIX"

# Build CDDA.
make -j"$(nproc)" \
    NATIVE=emscripten \
    BACKTRACE=0 \
    TILES=1 \
    SOUND=1 \
    TESTS=0 \
    RUNTESTS=0 \
    RELEASE=1 \
    CCACHE="$CCACHE" \
    LINTJSON=0 \
    cataclysm-tiles.js
