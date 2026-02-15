function(set_common_properties TARGET)
    set_target_properties(${TARGET}
        PROPERTIES
        CXX_STANDARD ${CMAKE_CXX_STANDARD_LATEST}
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF
        COMPILE_WARNING_AS_ERROR ON
        LINK_WARNING_AS_ERROR ON
    )
endfunction(set_common_properties)

function(set_common_visibility_hidden TARGET)
    if (NOT ${CMAKE_BUILD_TYPE} STREQUAL "Debug")
        set_target_properties(${TARGET}
            PROPERTIES
            CXX_VISIBILITY_PRESET hidden
            VISIBILITY_INLINES_HIDDEN ON
            DEFINE_SYMBOL CPP_DEMO_EXPORTS
        )
    endif ()
endfunction(set_common_visibility_hidden)

option(NATIVE "Enable native optimization")
function(set_common_compiler_options TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
    )
        set(OPTIMIZE_FLAGS "")
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            set(OPTIMIZE_FLAGS "-Og")
        elseif (CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
            set(OPTIMIZE_FLAGS "-Os")
        elseif (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
            set(OPTIMIZE_FLAGS "-O2")
        elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
            set(OPTIMIZE_FLAGS "-O3")
        else ()
            message(FATAL_ERROR "Unknown CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
        endif ()

        target_compile_options(${TARGET}
            PRIVATE
            -Wall
            -Wextra
            -Wpedantic

            ${OPTIMIZE_FLAGS}

            $<$<CONFIG:Debug>:
            -g3
            -ggdb3
            >

            $<$<AND:$<NOT:$<CONFIG:Debug>>,$<BOOL:${NATIVE}>>:
            -march=native
            >
        )

        target_link_options(${TARGET}
            PRIVATE
            ${OPTIMIZE_FLAGS}

            $<$<NOT:$<CONFIG:Debug>>:
            -ffunction-sections
            -fdata-sections
            >
        )

        if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
            target_compile_options(${TARGET}
                PRIVATE
                -stdlib=libc++

                $<$<CONFIG:Debug>:
                -glldb
                >
            )

            target_link_options(${TARGET}
                PRIVATE
                -stdlib=libc++
            )
        endif ()
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${TARGET}
            PRIVATE
            /utf-8
            /permissive-
            /W4
            /MP

            $<$<NOT:$<CONFIG:Debug>>:
            /GT
            >

            $<$<CONFIG:Release>:
            /Ob3
            >
        )
    else ()
        message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif ()
endfunction(set_common_compiler_options)

function(set_common_linker_options TARGET)
    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "LLD" OR
        CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MOLD"
    )
        target_link_options(${TARGET}
            PRIVATE
            LINKER:--warn-common
            LINKER:--warn-once

            $<$<CONFIG:Debug>:
            LINKER:--compress-debug-sections=zstd
            >

            $<$<NOT:$<CONFIG:Debug>>:
            LINKER:--no-undefined
            LINKER:--as-needed

            #LINKER:--execute-only # 适用于aarch64下的可执行文件

            LINKER:--hash-style=gnu

            LINKER:-Bsymbolic
            LINKER:--exclude-libs,ALL
            LINKER:-z,now

            LINKER:--gc-sections
            #LINKER:-z,nosectionheader # 适用于可执行文件
            >
        )

        if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "LLD" OR CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MOLD")
            target_link_options(${TARGET}
                PRIVATE
                LINKER:--color-diagnostics

                $<$<CONFIG:Debug>:
                LINKER:--gdb-index
                >

                $<$<NOT:$<CONFIG:Debug>>:
                LINKER:-z,rodynamic

                LINKER:--icf=all
                LINKER:--ignore-data-address-equality
                LINKER:--pack-dyn-relocs=relr
                >
            )

            if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "LLD")
                target_link_options(${TARGET}
                    PRIVATE
                    $<$<NOT:$<CONFIG:Debug>>:
                    LINKER:-O2
                    LINKER:--ignore-function-address-equality
                    >
                )
            else ()
                target_link_options(${TARGET}
                    PRIVATE
                    $<$<CONFIG:Debug>:
                    LINKER:--separate-debug-file
                    >

                    $<$<NOT:$<CONFIG:Debug>>:
                    LINKER:-z,rewrite-endbr
                    #LINKER:--zero-to-bss
                    >
                )
            endif ()
        endif ()
    elseif (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "AppleClang")
        target_link_options(${TARGET}
            PRIVATE
            LINKER:-warn_commons

            $<$<NOT:$<CONFIG:Debug>>:
            LINKER:-dead_strip_dylibs

            LINKER:-dead_strip
            LINKER:-merge_zero_fill_sections
            >
        )
    elseif (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MSVC")
        target_link_options(${TARGET}
            PRIVATE
            $<$<NOT:$<CONFIG:Debug>>:
            /OPT:REF,ICF=9,LBR
            >
        )
    else ()
        message(FATAL_ERROR "Unsupported linker: ${CMAKE_CXX_COMPILER_LINKER_ID}")
    endif ()
endfunction(set_common_linker_options)

function(set_common_lto TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
    )
        target_compile_options(${TARGET}
            PRIVATE
            $<$<NOT:$<CONFIG:Debug>>:
            -flto
            -fno-fat-lto-objects
            >
        )

        target_link_options(${TARGET}
            PRIVATE
            $<$<NOT:$<CONFIG:Debug>>:
            -flto
            -fno-fat-lto-objects
            >
        )

        if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            target_compile_options(${TARGET}
                PRIVATE
                $<$<NOT:$<CONFIG:Debug>>:
                -fuse-linker-plugin

                -fwhole-program
                >
            )

            target_link_options(${TARGET}
                PRIVATE
                $<$<NOT:$<CONFIG:Debug>>:
                -fuse-linker-plugin

                -fwhole-program
                >
            )
        else ()
            target_compile_options(${TARGET}
                PRIVATE
                $<$<NOT:$<CONFIG:Debug>>:
                -fwhole-program-vtables
                -fvirtual-function-elimination
                >
            )

            target_link_options(${TARGET}
                PRIVATE
                $<$<NOT:$<CONFIG:Debug>>:
                -fwhole-program-vtables
                -fvirtual-function-elimination
                >
            )

            if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
                target_compile_options(${TARGET}
                    PRIVATE
                    $<$<NOT:$<CONFIG:Debug>>:
                    -funified-lto
                    >
                )

                target_link_options(${TARGET}
                    PRIVATE
                    $<$<NOT:$<CONFIG:Debug>>:
                    -funified-lto
                    >
                )
            endif ()
        endif ()
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${TARGET}
            PRIVATE
            $<$<NOT:$<CONFIG:Debug>>:
            /GL
            >
        )
    else ()
        message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif ()

    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "LLD")
        target_link_options(${TARGET}
            PRIVATE
            $<$<NOT:$<CONFIG:Debug>>:
            LINKER:--lto-O3
            >
        )
    elseif (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "AppleClang" OR
        CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MOLD"
    )
    else ()
        message(FATAL_ERROR "Unsupported linker: ${CMAKE_CXX_COMPILER_LINKER_ID}")
    endif ()
endfunction(set_common_lto)

function(set_common_strip TARGET)
    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "LLD" OR
        CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MOLD"
    )
        target_link_options(${TARGET}
            PRIVATE
            $<$<NOT:$<CONFIG:Debug>>:
            LINKER:-s
            >
        )
    elseif (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "AppleClang")
        target_link_options(${TARGET}
            PRIVATE
            $<$<NOT:$<CONFIG:Debug>>:
            LINKER:-S
            LINKER:-x
            >
        )
    else ()
        message(FATAL_ERROR "Unsupported linker: ${CMAKE_CXX_COMPILER_LINKER_ID}")
    endif ()
endfunction(set_common_strip)

option(SCCACHE "Enable sccache")
function(set_common_build_tools TARGET)
    if (SCCACHE)
        find_program(SCCACHE_EXEC sccache)

        set_target_properties(${TARGET}
            PROPERTIES
            RULE_LAUNCH_COMPILE ${SCCACHE_EXEC}
        )
    endif (SCCACHE)
endfunction(set_common_build_tools)

function(set_sanitizer TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
    )
        target_compile_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:
            -fsanitize=address
            -fsanitize=undefined
            >
        )

        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:
            -fsanitize=address
            -fsanitize=undefined
            >
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:
            /fsanitize=address
            >
        )
    else ()
        message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif ()
endfunction(set_sanitizer)
