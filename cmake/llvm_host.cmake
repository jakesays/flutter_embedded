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

if(NOT LLVM_TARGETS_TO_BUILD)
    set(LLVM_TARGETS_TO_BUILD ARM|AArch64|X86)
endif()

ExternalProject_Add(llvm
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

if(BUILD_BINUTILS)
    ExternalProject_Add(binutils
        URL http://ftp.gnu.org/gnu/binutils/binutils-2.31.tar.gz
        URL_MD5 2a14187976aa0c39ad92363cfbc06505
        SOURCE_DIR ${THIRD_PARTY_DIR}/binutils
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${THIRD_PARTY_DIR}/binutils/configure
            --prefix=${TOOLCHAIN_DIR}
            --target=${TARGET_TRIPLE}
            --enable-gold
            --enable-ld
            --enable-lto
    )
    add_dependencies(binutils llvm)
endif()
