include(ExternalProject)

set(Onnxruntime_VERSION 1.13.1)

string(REPLACE ";" "$<SEMICOLON>" CMAKE_OSX_ARCHITECTURES_
               "${CMAKE_OSX_ARCHITECTURES}")

if(MSVC)
  set(Onnxruntime_LIB_PREFIX ${CMAKE_BUILD_TYPE})
else()
  set(Onnxruntime_LIB_PREFIX "")
endif()

if(OS_WINDOWS)
  set(Onnxruntime_PLATFORM_OPTIONS --cmake_generator ${CMAKE_GENERATOR})
  set(Onnxruntime_NSYNC_BYPRODUCT "")
  set(Onnxruntime_NSYNC_INSTALL "")
  set(Onnxruntime_PROTOBUF_PREFIX lib)
  set(Onnxruntime_CMAKE_BINARY_DIR <BINARY_DIR>/${CMAKE_BUILD_TYPE})

  set(Onnxruntime_BUILD_BYPRODUCTS <INSTALL_DIR>/lib/onnxruntime.lib
                                   <INSTALL_DIR>/lib/onnxruntime.dll)
elseif()
  set(Onnxruntime_PLATFORM_OPTIONS
      --apple_deploy_target ${CMAKE_OSX_DEPLOYMENT_TARGET} --osx_arch
      ${CMAKE_OSX_ARCHITECTURES_})
  set(Onnxruntime_NSYNC_BYPRODUCT
      <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}nsync_cpp${CMAKE_STATIC_LIBRARY_SUFFIX}
  )
  set(Onnxruntime_NSYNC_BINARY
      <BINARY_DIR>/${Onnxruntime_LIB_PREFIX}/external/nsync/${Onnxruntime_LIB_PREFIX}/${CMAKE_STATIC_LIBRARY_PREFIX}nsync_cpp${CMAKE_STATIC_LIBRARY_SUFFIX}
  )
  set(Onnxruntime_PROTOBUF_PREFIX ${CMAKE_STATIC_LIBRARY_PREFIX})
  set(Onnxruntime_CMAKE_BINARY_DIR <BINARY_DIR>)

  set(Onnxruntime_BUILD_BYPRODUCTS
      <INSTALL_DIR>/lib/${CMAKE_SHARED_LIBRARY_PREFIX}onnxruntime.${Onnxruntime_VERSION}${CMAKE_SHARED_LIBRARY_SUFFIX}
  )
endif()

find_package(Python3)

ExternalProject_Add(
  Ort
  GIT_REPOSITORY https://github.com/microsoft/onnxruntime.git
  GIT_TAG v1.13.1
  CONFIGURE_COMMAND ""
  BUILD_COMMAND
    ${Python3_EXECUTABLE} <SOURCE_DIR>/tools/ci_build/build.py --build_dir
    <BINARY_DIR> --config ${CMAKE_BUILD_TYPE} --parallel --skip_tests
    ${Onnxruntime_PLATFORM_OPTIONS} --build_shared_lib --cmake_extra_defines
    onnxruntime_BUILD_UNIT_TESTS=OFF
  BUILD_BYPRODUCTS ${Onnxruntime_BUILD_BYPRODUCTS}
  INSTALL_COMMAND
    ${CMAKE_COMMAND} --install
    ${Onnxruntime_CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE} --config
    ${CMAKE_BUILD_TYPE} --prefix <INSTALL_DIR>)

ExternalProject_Get_Property(Ort INSTALL_DIR)

add_library(Onnxruntime INTERFACE)
add_dependencies(Onnxruntime Ort)
target_include_directories(
  Onnxruntime
  INTERFACE ${INSTALL_DIR}/include
            ${INSTALL_DIR}/include/onnxruntime/core/session
            ${INSTALL_DIR}/include/onnxruntime/core/providers/cpu)
if(OS_MACOS)
  target_link_libraries(Onnxruntime INTERFACE "-framework Foundation")
endif()

add_library(Onnxruntime::Onnxruntime SHARED IMPORTED)
if(OS_WINDOWS)
  set_target_properties(
    Onnxruntime::Onnxruntime PROPERTIES IMPORTED_LOCATION
                                        ${INSTALL_DIR}/lib/onnxruntime.dll)
  set_target_properties(
    Onnxruntime::Onnxruntime PROPERTIES IMPORTED_IMPLIB
                                        ${INSTALL_DIR}/lib/onnxruntime.lib)
else()
  set_target_properties(
    Onnxruntime::Onnxruntime
    PROPERTIES
      IMPORTED_LOCATION
      ${INSTALL_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}onnxruntime.${Onnxruntime_VERSION}${CMAKE_SHARED_LIBRARY_SUFFIX}
  )
endif()
target_link_libraries(Onnxruntime INTERFACE Onnxruntime::Onnxruntime)
