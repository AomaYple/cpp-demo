cmake_minimum_required(VERSION 4.1 FATAL_ERROR)

project(cpp-demo VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_FIND_REQUIRED ON)

option(NATIVE "Enable native optimization")
option(SCCACHE "Enable sccache")

set(LINKER "" CACHE STRING "Choose linker (empty = default, or select: LLD/MOLD)")
set_property(CACHE LINKER PROPERTY STRINGS "LLD" "MOLD")
if (NOT LINKER STREQUAL "" AND NOT LINKER MATCHES "^(LLD|MOLD)$")
    message(FATAL_ERROR "LINKER must be empty, 'LLD' or 'MOLD', got: ${LINKER}")
endif ()

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/CommonConfig.cmake)

add_library(${PROJECT_NAME} SHARED)

set_common_properties(${PROJECT_NAME})
set_common_compile_options(${PROJECT_NAME})
set_common_link_options(${PROJECT_NAME})
set_common_build_tools(${PROJECT_NAME})
set_hidden_visibility(${PROJECT_NAME})

set_target_properties(${PROJECT_NAME}
    PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
)

file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS
    src/*.cpp
)

target_sources(${PROJECT_NAME}
    PRIVATE
    ${SOURCES}
)

target_include_directories(${PROJECT_NAME}
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

configure_package_config_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in
    ${PROJECT_NAME}Config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

write_basic_package_version_file(${PROJECT_NAME}ConfigVersion.cmake
    COMPATIBILITY SameMinorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake

    DESTINATION
    ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(FILES LICENSE
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/licenses/${PROJECT_NAME}
)

install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

add_subdirectory(test)
