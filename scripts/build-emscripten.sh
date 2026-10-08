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
        -DCMAKE_PREFIX_PATH="${SDL_PREFIX}" \
        "$@"

    cmake --build "${build}" -j"$(nproc)"
    cmake --install "${build}"

    echo "SDL_PREFIX=${SDL_PREFIX}"
    echo "CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
    
    find "${SDL_PREFIX}" -maxdepth 5 -type f | sort
    
}

#
# SDL3
#

echo "DEBUG: SDL3_VERSION='${SDL3_VERSION}'"
echo "DEBUG: clone args: SDL '${SDL3_VERSION}' sdl3"

clone_release SDL "${SDL3_VERSION}" sdl3

cmake_build_install sdl3 sdl3-build \
    -DCMAKE_BUILD_TYPE=Release \
    -DSDL_DEPS_SHARED=ON \
    -DSDL_TESTS=OFF \
    -DSDL_AUDIO=ON \
    -DSDL_ALSA=ON \
    -DSDL_ALSA_SHARED=ON \
    -DSDL_DBUS=ON \
    -DSDL_GPU=ON \
    -DSDL_IBUS=ON \
    -DSDL_KMSDRM=ON \
    -DSDL_KMSDRM_SHARED=ON \
    -DSDL_LIBUDEV=ON \
    -DSDL_OPENGL=ON \
    -DSDL_OPENGLES=ON \
    -DSDL_PIPEWIRE=ON \
    -DSDL_PIPEWIRE_SHARED=ON \
    -DSDL_PULSEAUDIO=ON \
    -DSDL_PULSEAUDIO_SHARED=ON \
    -DSDL_RENDER=ON \
    -DSDL_RENDER_GPU=ON \
    -DSDL_RENDER_VULKAN=ON \
    -DSDL_VIDEO=ON \
    -DSDL_VULKAN=ON \
    -DSDL_WAYLAND=ON \
    -DSDL_WAYLAND_SHARED=ON \
    -DSDL_WAYLAND_LIBDECOR=ON \
    -DSDL_WAYLAND_LIBDECOR_SHARED=ON \
    -DSDL_X11=ON \
    -DSDL_X11_SHARED=ON \
    -DBUILD_SHARED_LIBS=ON

# Setup config stuff
SDL3_CMAKE_DIR="${SDL_PREFIX}/lib/cmake/SDL3"

test -f "${SDL3_CMAKE_DIR}/SDL3Config.cmake"

if [[ ! -f "${SDL3_CMAKE_DIR}/SDL3Config.cmake" ]]; then
    echo "ERROR: SDL3Config.cmake was not installed where expected:"
    echo "       ${SDL3_CMAKE_DIR}/SDL3Config.cmake"
    find "${SDL_PREFIX}" -name 'SDL3Config.cmake' -o -name 'sdl3-config.cmake'
    exit 1
fi


#
# SDL3_image
#
# Use the vendored dependencies. This is important for Emscripten:
# Ubuntu's native libpng/libjpeg/etc. cannot be linked into WASM.
#

clone_release SDL_image "${SDL3_IMAGE_VERSION}" sdl3_image

cmake_build_install sdl3_image sdl3-image-build \
    -DCMAKE_BUILD_TYPE=Release \
    -DSDL3_DIR="${SDL3_CMAKE_DIR}" \
    -DSDLIMAGE_TESTS=OFF \
    -DSDLIMAGE_SAMPLES=OFF \
    -DSDLIMAGE_VENDORED=OFF \
    -DSDLIMAGE_DEPS_SHARED=OFF \
    -DSDLIMAGE_PNG=ON \
    -DSDLIMAGE_PNG_LIBPNG=ON \
    -DSDLIMAGE_JPG=ON \
    -DSDLIMAGE_AVIF=OFF \
    -DSDLIMAGE_JXL=OFF \
    -DSDLIMAGE_TIF=OFF \
    -DSDLIMAGE_WEBP=OFF \
    -DBUILD_SHARED_LIBS=ON
#
# SDL3_ttf
#

clone_release SDL_ttf "${SDL3_TTF_VERSION}" sdl3_ttf

cmake_build_install sdl3_ttf sdl3-ttf-build \
    -DCMAKE_BUILD_TYPE=Release \
    -DSDL3_DIR="${SDL3_CMAKE_DIR}" \
    -DSDLTTF_TESTS=OFF \
    -DSDLTTF_SAMPLES=OFF \
    -DSDLTTF_VENDORED=OFF \
    -DSDLTTF_STRICT=ON \
    -DSDLTTF_PLUTOSVG=OFF \
    -DBUILD_SHARED_LIBS=ON

#
# SDL3_mixer
#
# Again, use vendored codec dependencies so everything is built for WASM.
#

clone_release SDL_mixer "${SDL3_MIXER_VERSION}" sdl3_mixer

cmake_build_install sdl3_mixer sdl3-mixer-build \
    -DCMAKE_BUILD_TYPE=Release \
    -DSDL3_DIR="${SDL3_CMAKE_DIR}" \
    -DSDLMIXER_TESTS=OFF \
    -DSDLMIXER_SAMPLES=OFF \
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
    -DSDLMIXER_GME=OFF \
    -DSDLMIXER_STRICT=ON \
    -DBUILD_SHARED_LIBS=ON
    


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
