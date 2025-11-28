cmake_minimum_required(VERSION 4.0 FATAL_ERROR)

project(cpp-demo LANGUAGES CXX)

add_executable(${PROJECT_NAME})

set_target_properties(${PROJECT_NAME}
    PROPERTIES
    CXX_STANDARD ${CMAKE_CXX_STANDARD_LATEST}
    CXX_STANDARD_REQUIRED ON
    INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
    COMPILE_WARNING_AS_ERROR ON
    LINK_WARNING_AS_ERROR ON
)

file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS
    src/*.cpp
)

target_sources(${PROJECT_NAME}
    PRIVATE
    ${SOURCES}
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

        $<$<CONFIG:Release>:
        $<IF:$<CXX_COMPILER_ID:GNU>,-Ofast,-O3 -ffast-math>
        -fvisibility=hidden
        >

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
    if (NOT SCCACHE_EXEC)
        message(FATAL_ERROR "sccache not found but SCCACHE option is enabled")
    endif ()

    set_target_properties(${PROJECT_NAME}
        PROPERTIES
        RULE_LAUNCH_COMPILE ${SCCACHE_EXEC}
    )
endif ()

option(MOLD "Enable MOLD linker")
if (MOLD AND UNIX)
    find_program(MOLD_EXEC mold)
    if (NOT MOLD_EXEC)
        message(FATAL_ERROR "MOLD linker not found but MOLD option is enabled")
    endif ()

    set_target_properties(${PROJECT_NAME}
        PROPERTIES
        LINKER_TYPE MOLD
    )
endif ()
