include (ExternalProject)

if(NOT ENGINE_REPO)
    set(ENGINE_REPO https://github.com/flutter/engine.git)
endif()

set(ENGINE_SRC_PATH ${CMAKE_BINARY_DIR}/engine-prefix/src/engine)
configure_file(cmake/engine.gclient.in ${ENGINE_SRC_PATH}/.gclient @ONLY)
include(engine_options)

set(ENGINE_INCLUDE_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})
set(ENGINE_LIBRARIES_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})


# update patch file with toolchain dirs
configure_file(cmake/patches/engine_compiler_build.patch.in ${CMAKE_BINARY_DIR}/engine_compiler_build.patch @ONLY)

find_program(gclient REQUIRED)
ExternalProject_Add(engine
    DOWNLOAD_COMMAND cd ${ENGINE_SRC_PATH} && gclient sync
    PATCH_COMMAND
        cd src && git checkout build/config/compiler/BUILD.gn && git apply ${CMAKE_BINARY_DIR}/engine_compiler_build.patch &&
        cd third_party/dart && git checkout runtime/BUILD.gn && git apply ${CMAKE_SOURCE_DIR}/cmake/patches/dart.patch &&
        cd ../../..
    UPDATE_COMMAND ""
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND src/flutter/tools/gn ${ENGINE_FLAGS}
    BUILD_COMMAND autoninja -C src/${ENGINE_OUT_DIR}
    INSTALL_COMMAND
        ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/target/lib &&
        ${CMAKE_COMMAND} -E copy ${ENGINE_LIBRARIES_DIR}/icudtl.dat ${CMAKE_BINARY_DIR}/target/bin &&
        ${CMAKE_COMMAND} -E copy ${ENGINE_LIBRARIES_DIR}/libflutter_engine${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_BINARY_DIR}/target/lib &&
        ${CXX_LIB_COPY_CMD}
)
if(BUILD_LIBCXX)
    add_dependencies(engine libcxx)
endif()

include_directories(${ENGINE_INCLUDE_DIR})
link_directories(${ENGINE_LIBRARIES_DIR})
