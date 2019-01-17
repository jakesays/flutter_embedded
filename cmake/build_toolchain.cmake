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

option(BUILD_TOOLCHAIN "Build toolchain" ON)

if(NOT ANDROID)

    if(NOT TOOLCHAIN_DIR AND NOT BUILD_TOOLCHAIN)
        message(FATAL_ERROR "No toolchain specified and build toolchain not enabled, cannot continue.")
    endif()
    
endif()

if(BUILD_TOOLCHAIN)

    include(toolchain_config)

    set(CXX_LIB_COPY_CMD 
        ${CMAKE_COMMAND} -E copy ${TOOLCHAIN_DIR}/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1.0 ${CMAKE_BINARY_DIR}/target/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
        ${CMAKE_COMMAND} -E copy ${TOOLCHAIN_DIR}/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1.0 ${CMAKE_BINARY_DIR}/target/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
        chmod +x ${CMAKE_BINARY_DIR}/target/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
        chmod +x ${CMAKE_BINARY_DIR}/target/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1)

    set(LLVM_SRC_DIR ${CMAKE_BINARY_DIR}/llvm)

    if(NOT LLVM_TARGETS_TO_BUILD)
        set(LLVM_TARGETS_TO_BUILD ARM|AArch64|X86)
    endif()

    #
    # built for host
    #
    #TODO: add LLD?
    option(BUILD_LLDB "Checkout and build lldb host and target" OFF)
    option(BUILD_COMPILER_RT "Checkout and build compiler-rt" ON)
    option(BUILD_LIBCXXABI "Checkout and build libcxxabi for target" ON)
    option(BUILD_LIBUNWIND "Checkout and build libunwind for  target" ON)
    option(BUILD_LIBCXX "Checkout and build libcxx for target" ON)

    set(LLVM_CHECKOUT
        cd ${CMAKE_BINARY_DIR} &&
        svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm &&
        cd ${LLVM_SRC_DIR}/tools &&
        svn co http://llvm.org/svn/llvm-project/cfe/trunk clang)

    if(BUILD_LLDB)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
        cd ${LLVM_SRC_DIR}/tools &&
        svn co http://llvm.org/svn/llvm-project/lldb/trunk lldb)
    else()
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
            cd ${LLVM_SRC_DIR}/tools && rm -rf lldb)
    endif()

    if(BUILD_COMPILER_RT)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
            cd ${LLVM_SRC_DIR}/projects &&
            svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt)
    else()
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
            cd ${LLVM_SRC_DIR}/projects && rm -rf compiler-rt)
    endif()

    if(BUILD_LIBUNWIND)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
            cd ${CMAKE_BINARY_DIR} &&
            svn co http://llvm.org/svn/llvm-project/libunwind/trunk libunwind)
    else()
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
            cd ${CMAKE_BINARY_DIR} && rm -rf libunwind)
    endif()

    if(BUILD_LIBCXXABI)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
            cd ${LLVM_SRC_DIR}/projects &&
            svn co http://llvm.org/svn/llvm-project/libcxxabi/trunk libcxxabi)
    else()
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
            cd ${LLVM_SRC_DIR}/projects && rm -rf libcxxabi)
    endif()

    if(BUILD_LIBCXX)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
            cd ${LLVM_SRC_DIR}/projects &&
            svn co http://llvm.org/svn/llvm-project/libcxx/trunk libcxx)
    else()
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
            cd ${LLVM_SRC_DIR}/projects && rm -rf libcxx)
    endif()

    ExternalProject_Add(clang
        DOWNLOAD_COMMAND ${LLVM_CHECKOUT}
        SOURCE_DIR ${LLVM_SRC_DIR}
        UPDATE_COMMAND ""
        BUILD_IN_SOURCE 0
        LIST_SEPARATOR |
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE}
            -DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}
    )

    # create app toolchain file
    add_custom_command(TARGET clang POST_BUILD
        COMMAND ${CMAKE_COMMAND}
            -DTARGET_ARCH=${TARGET_ARCH}
            -DTARGET_SYSROOT=${TARGET_SYSROOT}
            -DTARGET_TRIPLE=${TARGET_TRIPLE}
            -DTOOLCHAIN_DIR=${TOOLCHAIN_DIR}
            -DSRC=${CMAKE_SOURCE_DIR}
            -DDST=${CMAKE_BINARY_DIR}
            -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
            -P ${CMAKE_SOURCE_DIR}/cmake/create.app.toolchain.cmake
    )

    ExternalProject_Add(binutils
        URL http://ftp.gnu.org/gnu/binutils/binutils-2.31.tar.gz
        URL_MD5 2a14187976aa0c39ad92363cfbc06505
        BUILD_IN_SOURCE 1
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ./configure
            --prefix=${TOOLCHAIN_DIR}
            --target=${TARGET_TRIPLE}
            --enable-gold
            --enable-ld
            --enable-lto
    )
    add_dependencies(binutils clang)

    #
    # cross compile for target
    #

    configure_file(cmake/clang.toolchain.cmake.in ${CMAKE_BINARY_DIR}/toolchain.cmake @ONLY)

    if(BUILD_COMPILER_RT)
        ExternalProject_Add(compiler-rt
            DOWNLOAD_COMMAND ""
            PATCH_COMMAND cd ${LLVM_SRC_DIR}/projects/compiler-rt && 
                svn revert cmake/config-ix.cmake && svn patch ${CMAKE_SOURCE_DIR}/cmake/patches/compiler-rt.patch
            BUILD_IN_SOURCE 0
            UPDATE_COMMAND ""
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/projects/compiler-rt
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}/lib/clang/8.0.0
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
                -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
                -DCOMPILER_RT_STANDALONE_BUILD=ON
                -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE}
                -DCOMPILER_RT_HAS_FPIC_FLAG=ON
                -DCOMPILER_RT_BUILD_XRAY=ON
                -DCOMPILER_RT_BUILD_SANITIZERS=ON
        )
        add_dependencies(compiler-rt clang binutils)
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
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
                -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}
                -DLIBCXXABI_SYSROOT=${TARGET_SYSROOT}
                -DLIBCXXABI_TARGET_TRIPLE=${TARGET_TRIPLE}
                -DLIBCXXABI_ENABLE_SHARED=ON
                -DLIBCXXABI_USE_COMPILER_RT=${BUILD_COMPILER_RT}
                -DLIBCXXABI_USE_LLVM_UNWINDER=${BUILD_LIBUNWIND}
        )
        add_dependencies(libcxxabi clang binutils)
        if(BUILD_COMPILER_RT)
            add_dependencies(libcxxabi compiler-rt)
        endif()
    endif()

    if(BUILD_LIBUNWIND)
        ExternalProject_Add(libunwind
            DOWNLOAD_COMMAND ""
            BUILD_IN_SOURCE 0
            UPDATE_COMMAND ""
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_BINARY_DIR}/libunwind
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
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
        add_dependencies(libunwind clang binutils)
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
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
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
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_CROSSCOMPILING=ON
                -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
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
endif(BUILD_TOOLCHAIN)