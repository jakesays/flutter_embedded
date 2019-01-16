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

#
# Build Options
#
option(BUILD_LLDB "Checkout and build lldb for host" ON)
option(BUILD_LLD "Checkout and build lld for host" ON)
option(BUILD_COMPILER_RT "Checkout and build compiler-rt for host and target" ON)
option(BUILD_LIBCXXABI "Checkout and build libcxxabi for host and target" ON)
option(BUILD_LIBUNWIND "Checkout and build libunwind for target" ON)
option(BUILD_LIBCXX "Checkout and build libcxx for host and target" ON)

#
# Gold/LTO
#
option(BUILD_BINUTILS "Download and build binutils with gold and lto for host" ON)

#
# Checkout sequence
#
set(LLVM_SRC_DIR ${THIRD_PARTY_DIR}/llvm)

set(LLVM_CHECKOUT
    cd ${THIRD_PARTY_DIR} &&
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

if(BUILD_LLD)
    set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
        cd ${LLVM_SRC_DIR}/projects &&
        svn co http://llvm.org/svn/llvm-project/lld/trunk lld)
else()
    set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
    cd ${LLVM_SRC_DIR}/projects && rm -rf lld)
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
        cd ${THIRD_PARTY_DIR} &&
        svn co http://llvm.org/svn/llvm-project/libunwind/trunk libunwind)
else()
    set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
        cd ${THIRD_PARTY_DIR} && rm -rf libunwind)
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


set(CXX_LIB_COPY_CMD 
    ${CMAKE_COMMAND} -E copy ${TOOLCHAIN_DIR}/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1.0 ${CMAKE_BINARY_DIR}/target/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
    ${CMAKE_COMMAND} -E copy ${TOOLCHAIN_DIR}/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1.0 ${CMAKE_BINARY_DIR}/target/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
    chmod +x ${CMAKE_BINARY_DIR}/target/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
    chmod +x ${CMAKE_BINARY_DIR}/target/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1)
