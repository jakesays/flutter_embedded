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

set(LLVM_CONFIG_PATH ${TOOLCHAIN_DIR}/bin/llvm-config CACHE PATH "llvm-config path")

configure_file(cmake/clang.toolchain.cmake.in ${CMAKE_BINARY_DIR}/clang.toolchain.cmake @ONLY)

if(BUILD_COMPILER_RT)
    ExternalProject_Add(compiler-rt
        DOWNLOAD_COMMAND ""
        PATCH_COMMAND cd ${LLVM_SRC_DIR}/projects/compiler-rt && 
            svn revert cmake/config-ix.cmake && svn patch ${CMAKE_SOURCE_DIR}/cmake/patches/compiler-rt.patch
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/projects/compiler-rt
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/clang.toolchain.cmake
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}/lib/clang/9.0.0
            -DCMAKE_BUILD_TYPE=MinSizeRel
            -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
            -DCOMPILER_RT_STANDALONE_BUILD=ON
            -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE}
            -DCOMPILER_RT_HAS_FPIC_FLAG=ON
            -DCOMPILER_RT_BUILD_XRAY=ON
            -DCOMPILER_RT_BUILD_SANITIZERS=ON
    )
    add_dependencies(compiler-rt llvm)
endif()

if(BUILD_LIBCXXABI)
    configure_file(cmake/patches/libcxxabi.patch.in ${CMAKE_BINARY_DIR}/libcxxabi.patch @ONLY)
    ExternalProject_Add(libcxxabi
        DOWNLOAD_COMMAND ""
        PATCH_COMMAND cd ${LLVM_SRC_DIR}/projects/libcxxabi && 
            svn revert cmake/config-ix.cmake && svn patch ${CMAKE_BINARY_DIR}/libcxxabi.patch
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/projects/libcxxabi
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/clang.toolchain.cmake
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=MinSizeRel
            -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
            -DLIBCXXABI_SYSROOT=${TARGET_SYSROOT}
            -DLIBCXXABI_TARGET_TRIPLE=${TARGET_TRIPLE}
            -DLIBCXXABI_ENABLE_SHARED=ON
            -DLIBCXXABI_USE_COMPILER_RT=${BUILD_COMPILER_RT}
            -DLIBCXXABI_USE_LLVM_UNWINDER=${BUILD_LIBUNWIND}
    )
    add_dependencies(libcxxabi llvm)
    if(BUILD_COMPILER_RT)
        add_dependencies(libcxxabi compiler-rt)
    endif()
endif()

if(BUILD_LIBUNWIND)
    ExternalProject_Add(libunwind
        DOWNLOAD_COMMAND ""
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ${THIRD_PARTY_DIR}/libunwind
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/clang.toolchain.cmake
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=MinSizeRel
            -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
            -DLIBUNWIND_STANDALONE_BUILD=ON
            -DLIBUNWIND_TARGET_TRIPLE=${TARGET_TRIPLE}
            -DLIBUNWIND_SYSROOT=${TARGET_SYSROOT}
            -DLIBUNWIND_USE_COMPILER_RT=${BUILD_COMPILER_RT}
            -DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF
            -DLIBUNWIND_ENABLE_STATIC=ON
            -DLIBUNWIND_ENABLE_SHARED=OFF
            -DLIBUNWIND_ENABLE_THREADS=ON
    )
    add_dependencies(libunwind llvm)
    if(BUILD_COMPILER_RT)
        add_dependencies(libunwind compiler-rt)
    endif()
    if(BUILD_LIBCXXABI AND BUILD_LIBUNWIND)
        add_dependencies(libcxxabi libunwind)
    endif()
endif()

if(BUILD_LIBCXX)
    ExternalProject_Add(libcxx
        DOWNLOAD_COMMAND ""
        PATCH_COMMAND cd ${LLVM_SRC_DIR}/projects/libcxx && 
            svn revert cmake/config-ix.cmake && svn patch ${CMAKE_SOURCE_DIR}/cmake/patches/libcxx.patch
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/projects/libcxx
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/clang.toolchain.cmake
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=MinSizeRel
            -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
            -DLIBCXX_SYSROOT=${TARGET_SYSROOT}
            -DLIBCXX_TARGET_TRIPLE=${TARGET_TRIPLE}
            -DLIBCXX_USE_COMPILER_RT=${BUILD_COMPILER_RT}
            -DLIBCXX_ENABLE_SHARED=ON
    )
    add_dependencies(libcxx libcxxabi)
    if(BUILD_COMPILER_RT)
        add_dependencies(libcxx compiler-rt)
    endif()
endif()


# Currently cross compiling lldb requires a cross compiled clang, even though it's not really used.
# I'm currently only building Clang for host, so disable until work is done on lldb.
if(FALSE)
    ExternalProject_Add(lldb_target
        DOWNLOAD_COMMAND ""
        UPDATE_COMMAND ""
        BUILD_IN_SOURCE 0
        LIST_SEPARATOR |
        CONFIGURE_COMMAND set(ENV{PATH} ${TOOLCHAIN_DIR}/bin:ENV{PATH}) && 
            ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/tools/lldb
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/clang.toolchain.cmake
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=MinSizeRel
            -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
            -DLLVM_HOST_TRIPLE=${TARGET_TRIPLE}
            -DLLVM_TABLEGEN=${TOOLCHAIN_DIR}/bin/llvm-tblgen
            -DCLANG_TABLEGEN=${CMAKE_BINARY_DIR}/clang-prefix/src/clang-build/bin/clang-tblgen
            -DLLDB_DISABLE_PYTHON=ON
            -DLLDB_DISABLE_LIBEDIT=ON
            -DLLDB_DISABLE_CURSES=ON
            -DLLVM_ENABLE_TERMINFO=OFF
    )
    add_dependencies(lldb_target libcxx)
endif()
