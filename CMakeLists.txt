cmake_minimum_required(VERSION 4.1 FATAL_ERROR)

project(cpp-demo VERSION 1.0.0 LANGUAGES CXX)

add_library(${PROJECT_NAME} SHARED)

set(CMAKE_FIND_REQUIRED ON)

set_target_properties(${PROJECT_NAME}
    PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    CXX_STANDARD ${CMAKE_CXX_STANDARD_LATEST}
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
    COMPILE_WARNING_AS_ERROR ON
    LINK_WARNING_AS_ERROR ON
    INTERPROCEDURAL_OPTIMIZATION_RELEASE ON
)
if (${CMAKE_BUILD_TYPE} STREQUAL "Release")
    set_target_properties(${PROJECT_NAME}
        PROPERTIES
        CXX_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN ON
    )
endif ()

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

option(NATIVE "Enable native optimization")
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
    CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
    CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    target_compile_options(${PROJECT_NAME}
        PRIVATE
        -Wall -Wextra -Wpedantic

        $<$<CONFIG:Debug>:
        -g3
        $<IF:$<CXX_COMPILER_ID:GNU>,-ggdb3,-glldb>
        -Og
        -fsanitize=address -fsanitize=leak -fsanitize=undefined
        >

        $<$<CONFIG:Release>:$<IF:$<CXX_COMPILER_ID:GNU>,-Ofast,-O3 -ffast-math>>

        $<$<AND:$<CONFIG:Release>,$<BOOL:${NATIVE}>>:-march=native>
    )
    target_link_options(${PROJECT_NAME}
        PRIVATE
        $<$<CONFIG:Debug>:-fsanitize=address -fsanitize=leak -fsanitize=undefined>

        $<$<CONFIG:Release>:
        $<IF:$<CXX_COMPILER_ID:GNU>,-Ofast,-O3 -ffast-math>
        -ffunction-sections -fdata-sections
        >

        LINKER:--warn-common,--warn-once,--as-needed,--no-undefined
        $<$<CONFIG:Debug>:LINKER:--compress-debug-sections=zstd>
        $<$<CONFIG:Release>:LINKER:--gc-sections,-s,--icf=all,--ignore-data-address-equality,--pack-dyn-relocs=relr,-z,now>
    )
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(${PROJECT_NAME}
        PRIVATE
        /permissive- /utf-8 /W4 /MP
        $<$<CONFIG:Debug>:/sdl /fsanitize=address>
        $<$<CONFIG:Release>:/Ob3 /GT /Gy /fp:fast>
    )
    target_link_options(${PROJECT_NAME}
        PRIVATE
        $<$<CONFIG:Release>:/OPT:REF,ICF /LTCG:incremental>
    )
endif ()

option(SCCACHE "Enable sccache")
if (SCCACHE)
    find_program(SCCACHE_EXEC sccache)

    set_target_properties(${PROJECT_NAME}
        PROPERTIES
        RULE_LAUNCH_COMPILE ${SCCACHE_EXEC}
    )
endif ()

option(MOLD "Enable MOLD linker")
if (MOLD AND UNIX)
    find_program(MOLD_EXEC mold)

    set_target_properties(${PROJECT_NAME}
        PROPERTIES
        LINKER_TYPE MOLD
    )
endif ()

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
