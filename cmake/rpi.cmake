#
# MIT License
#
# Copyright (c) 2018 Joel Winarske
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

include (ExternalProject)

# create app toolchain file
set(PKG_CONFIG_PATH ${TARGET_SYSROOT}/opt/vc/lib/pkgconfig)
configure_file(${CMAKE_SOURCE_DIR}/cmake/app.clang.toolchain.cmake.in ${CMAKE_BINARY_DIR}/app.toolchain.cmake @ONLY)


option(BUILD_PI_USERLAND "Build Pi userland repo - !!replaces sysroot/opt/vc!!" OFF)
if(BUILD_PI_USERLAND)

    ExternalProject_Add(pi_userland
        GIT_REPOSITORY https://github.com/jwinarske/userland.git
        GIT_TAG vidtext_fix
        SOURCE_DIR ${THIRD_PARTY_DIR}/userland
        BUILD_IN_SOURCE 0
        PATCH_COMMAND rm -rf ${TARGET_SYSROOT}/opt/vc
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${TARGET_SYSROOT}
            -DVMCS_INSTALL_PREFIX=${TARGET_SYSROOT}/opt/vc
    )
    if(BUILD_TOOLCHAIN)
        add_dependencies(pi_userland llvm)
    endif()
    if(BUILD_COMPILER-RT)
        add_dependencies(pi_userland compiler-rt)
    endif()  

endif()

option(BUILD_HELLO_PI "Build the apps in /opt/vc/src/hello_pi" ON)
if(BUILD_HELLO_PI)

    # These are C apps...
    ExternalProject_Add(hello_pi
        PATCH_COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_SOURCE_DIR}/cmake/hello_pi.cmake
            ${TARGET_SYSROOT}/opt/vc/src/hello_pi/CMakeLists.txt
        SOURCE_DIR ${TARGET_SYSROOT}/opt/vc/src/hello_pi
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
    )
    if(BUILD_TOOLCHAIN)
        add_dependencies(hello_pi llvm)
    endif()
    if(BUILD_COMPILER_RT)
        add_dependencies(hello_pi compiler-rt)
    endif()
    if(BUILD_PI_USERLAND)
        add_dependencies(hello_pi pi_userland)
    endif()

endif()

option(BUILD_SDL2 "Build SDL2 library" OFF)
if(BUILD_SDL2)

    # These are C apps...
    ExternalProject_Add(sdl2
        URL https://www.libsdl.org/release/SDL2-2.0.9.tar.gz
        URL_MD5 f2ecfba915c54f7200f504d8b48a5dfe
        SOURCE_DIR ${THIRD_PARTY_DIR}/sdl2
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
            -DSDL_AUDIO=OFF
            -DVIDEO_DUMMY=OFF
            -DVIDEO_RPI=ON
            -DVIDEO_KMSDRM=OFF
            -DVIDEO_VULKAN=ON
    )
    if(BUILD_TOOLCHAIN)
        add_dependencies(sdl2 llvm)
    endif()
    if(BUILD_COMPILER_RT)
        add_dependencies(sdl2 compiler-rt)
    endif()
    if(BUILD_PI_USERLAND)
        add_dependencies(sdl2 pi_userland)
    endif()

endif()

option(BUILD_TSLIB "Checkout and build tslib for target" ON)
if(BUILD_TSLIB AND NOT ANDROID)
    ExternalProject_Add(tslib
        GIT_REPOSITORY https://github.com/kergoth/tslib.git
        GIT_TAG 1.18
        SOURCE_DIR ${THIRD_PARTY_DIR}/tslib
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
        -DCMAKE_INSTALL_PREFIX=${TARGET_SYSROOT}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
    )
    if(BUILD_TOOLCHAIN)
        add_dependencies(tslib llvm)
    endif()
    if(BUILD_COMPILER_RT)
        add_dependencies(tslib compiler-rt)
    endif()
endif()


#
# build flutter executable
#
set(FLUTTER_TARGET_NAME "Raspberry Pi")
ExternalProject_Add(rpi_flutter
    GIT_REPOSITORY https://github.com/jwinarske/flutter_from_scratch.git
    GIT_TAG clang_fixes
    PATCH_COMMAND ""
    SOURCE_DIR ${THIRD_PARTY_DIR}/rpi_flutter
    BUILD_IN_SOURCE 0
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
        -DENGINE_INCLUDE_DIR=${ENGINE_INCLUDE_DIR}
        -DENGINE_LIBRARIES_DIR=${ENGINE_LIBRARIES_DIR}
)
add_dependencies(rpi_flutter engine)
