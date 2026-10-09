#!/usr/bin/env bash
set -euo pipefail

SDL_PREFIX="${PWD}/.sdl3-wasm"
SDL_BUILD_ROOT="${PWD}/.sdl3-build"
SDL_SOURCE_ROOT="${PWD}/.sdl3-source"

SDL3_VERSION="3.4.10"
SDL3_IMAGE_VERSION="3.4.4"
SDL3_TTF_VERSION="3.2.2"
SDL3_MIXER_VERSION="3.2.4"

rm -rf "${SDL_PREFIX}" "${SDL_BUILD_ROOT}" "${SDL_SOURCE_ROOT}"
mkdir -p "${SDL_PREFIX}" "${SDL_BUILD_ROOT}" "${SDL_SOURCE_ROOT}"

export PKG_CONFIG_PATH="${SDL_PREFIX}/lib/pkgconfig"
export CMAKE_PREFIX_PATH="${SDL_PREFIX}"

clone_release() {
    local repo="$1"
    local version="$2"
    local dir="$3"
    local target="${SDL_SOURCE_ROOT}/${dir}"

    if [[ -d "${target}/.git" ]]; then
        echo "Using cached ${repo} ${version}: ${target}"
        return
    fi

    echo "Cloning ${repo} ${version}..."

    git clone \
        --depth 1 \
        --recurse-submodules \
        --shallow-submodules \
        --branch "release-${version}" \
        "https://github.com/libsdl-org/${repo}.git" \
        "${target}"
}

cmake_build_install() {
    local source="$1"
    local build="$2"
    shift 2

    local source_dir="${SDL_SOURCE_ROOT}/${source}"
    local build_dir="${SDL_BUILD_ROOT}/${build}"

    mkdir -p "${build_dir}"

    emcmake cmake \
        -S "${source_dir}" \
        -B "${build_dir}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${SDL_PREFIX}" \
        -DCMAKE_PREFIX_PATH="${SDL_PREFIX}" \
        "$@"

    cmake --build "${build_dir}" -j"$(nproc)"
    cmake --install "${build_dir}"
}

#
# SDL3
#

clone_release SDL "${SDL3_VERSION}" sdl3

cmake_build_install sdl3 sdl3-build \
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
    -DBUILD_SHARED_LIBS=OFF

# Setup config stuff
SDL3_CMAKE_DIR="${SDL_PREFIX}/lib/cmake/SDL3"

test -f "${SDL3_CMAKE_DIR}/SDL3Config.cmake"

#
# SDL3_image
#
# Use the vendored dependencies. This is important for Emscripten:
# Ubuntu's native libpng/libjpeg/etc. cannot be linked into WASM.
#

clone_release SDL_image "${SDL3_IMAGE_VERSION}" sdl3_image

cmake_build_install sdl3_image sdl3-image-build \
    -DSDL3_DIR="${SDL3_CMAKE_DIR}" \
    -DSDLIMAGE_TESTS=OFF \
    -DSDLIMAGE_SAMPLES=OFF \
    -DSDLIMAGE_VENDORED=ON \
    -DSDLIMAGE_DEPS_SHARED=OFF \
    -DSDLIMAGE_PNG=ON \
    -DSDLIMAGE_PNG_LIBPNG=ON \
    -DSDLIMAGE_JPG=ON \
    -DSDLIMAGE_AVIF=OFF \
    -DSDLIMAGE_JXL=OFF \
    -DSDLIMAGE_TIF=OFF \
    -DSDLIMAGE_WEBP=OFF \
    -DBUILD_SHARED_LIBS=OFF

#
# SDL3_ttf
#

clone_release SDL_ttf "${SDL3_TTF_VERSION}" sdl3_ttf

cmake_build_install sdl3_ttf sdl3-ttf-build \
    -DSDL3_DIR="${SDL3_CMAKE_DIR}" \
    -DSDLTTF_TESTS=OFF \
    -DSDLTTF_SAMPLES=OFF \
    -DSDLTTF_VENDORED=ON \
    -DSDLTTF_PLUTOSVG=OFF \
    -DSDLTTF_HARFBUZZ=ON \
    -DSDLTTF_FREETYPE=ON \
    -DBUILD_SHARED_LIBS=OFF

#
# SDL3_mixer
#
# Again, use vendored codec dependencies so everything is built for WASM.
#

clone_release SDL_mixer "${SDL3_MIXER_VERSION}" sdl3_mixer

cmake_build_install sdl3_mixer sdl3-mixer-build \
    -DSDL3_DIR="${SDL3_CMAKE_DIR}" \
    -DSDLMIXER_TESTS=OFF \
    -DSDLMIXER_EXAMPLES=OFF \
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
    -DSDLMIXER_GME=OFF \
    -DSDLMIXER_STRICT=ON \
    -DBUILD_SHARED_LIBS=OFF

echo "SDL WASM libraries installed in ${SDL_PREFIX}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"

pkg-config --modversion sdl3
pkg-config --modversion sdl3-image
pkg-config --modversion sdl3-ttf
pkg-config --modversion sdl3-mixer

#
# CDDA
#

#
# Expose SDL_ttf's vendored FreeType headers to the CDDA build.
#

# FreeType should be installed with SDL_ttf in the prefix
FREETYPE_INCLUDE_DIR="${SDL_PREFIX}/include"

# Look for ftconfig.h in the build directory or prefix
FREETYPE_CONFIG_DIR="$(find \
    "${SDL_BUILD_ROOT}/sdl3-ttf-build" \
    -type f \
    -name ftconfig.h \
    -printf '%h\n' \
    -quit
)" || FREETYPE_CONFIG_DIR="${SDL_PREFIX}/include"

# Alternative: Check if headers exist at the standard SDL_ttf vendored location
if [[ -d "${SDL_BUILD_ROOT}/sdl3-ttf-build/external/freetype/include" ]]; then
    FREETYPE_INCLUDE_DIR="${SDL_BUILD_ROOT}/sdl3-ttf-build/external/freetype/include"
fi

# Debug info to help diagnose header layout mismatches.
for candidate in \
    "${SDL_BUILD_ROOT}/sdl3-ttf-build" \
    "${SDL_BUILD_ROOT}/sdl3-ttf-build/external" \
    "${SDL_BUILD_ROOT}/sdl3-ttf-build/external/freetype" \
    "${SDL_BUILD_ROOT}/sdl3-ttf-build/external/freetype/include" \
    "${SDL_PREFIX}/include"; do
    echo "DEBUG candidate: ${candidate}"
    if [[ -d "${candidate}" ]]; then
        find "${candidate}" -maxdepth 3 \( -name 'ft2build.h' -o -name 'ftconfig.h' \) -print | sort
    else
        echo "DEBUG missing directory: ${candidate}"
    fi
done

FREETYPE_HEADER_PATH=""
if [[ -f "${FREETYPE_INCLUDE_DIR}/freetype/ft2build.h" ]]; then
    FREETYPE_HEADER_PATH="${FREETYPE_INCLUDE_DIR}/freetype/ft2build.h"
elif [[ -f "${FREETYPE_INCLUDE_DIR}/ft2build.h" ]]; then
    FREETYPE_HEADER_PATH="${FREETYPE_INCLUDE_DIR}/ft2build.h"
fi

if [[ -z "${FREETYPE_HEADER_PATH}" ]]; then
    echo "ERROR: Could not locate FreeType headers at ${FREETYPE_INCLUDE_DIR}"
    echo "Searching for FreeType headers in SDL_ttf build..."
    find "${SDL_BUILD_ROOT}/sdl3-ttf-build" \( -name ft2build.h -o -name ftconfig.h \) -print
    exit 1
fi

if [[ -f "${FREETYPE_CONFIG_DIR}/ftconfig.h" ]]; then
    echo "DEBUG found ftconfig.h in ${FREETYPE_CONFIG_DIR}"
else
    echo "DEBUG missing ftconfig.h in ${FREETYPE_CONFIG_DIR}"
fi

echo "FreeType headers: ${FREETYPE_INCLUDE_DIR}"
echo "FreeType header path: ${FREETYPE_HEADER_PATH}"
echo "FreeType config:  ${FREETYPE_CONFIG_DIR}"

echo "DEBUG include dir contents:"
find "${FREETYPE_INCLUDE_DIR}" -maxdepth 2 -print | head -200

export CXXFLAGS="${CXXFLAGS:-} -isystem ${FREETYPE_INCLUDE_DIR} -isystem ${FREETYPE_CONFIG_DIR}"
export CFLAGS="${CFLAGS:-} -isystem ${FREETYPE_INCLUDE_DIR} -isystem ${FREETYPE_CONFIG_DIR}"


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
