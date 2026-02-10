function(set_common_properties TARGET)
    set_target_properties(${TARGET}
        PROPERTIES
        CXX_STANDARD ${CMAKE_CXX_STANDARD_LATEST}
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF
        COMPILE_WARNING_AS_ERROR ON
        LINK_WARNING_AS_ERROR ON
        INTERPROCEDURAL_OPTIMIZATION_RELEASE ON
    )
endfunction(set_common_properties)

function(set_common_hidden_visibility TARGET)
    if (${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set_target_properties(${TARGET}
            PROPERTIES
            CXX_VISIBILITY_PRESET hidden
            VISIBILITY_INLINES_HIDDEN ON
            DEFINE_SYMBOL CPP_DEMO_EXPORTS
        )
    endif ()
endfunction(set_common_hidden_visibility)

function(set_common_compiler_options TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
    )
        target_compile_options(${TARGET}
            PRIVATE
            -Wall
            -Wextra
            -Wpedantic

            $<$<CONFIG:Debug>:
            -g3
            -ggdb3
            -Og
            >

            $<$<AND:$<CONFIG:Release>,$<BOOL:${NATIVE}>>:
            -march=native
            >
        )

        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:
            -ffunction-sections
            -fdata-sections
            >
        )
    endif ()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:
            -Ofast
            >
        )

        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:
            -Ofast
            >
        )
    endif ()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
    )
        target_compile_options(${TARGET}
            PRIVATE
            -stdlib=libc++

            $<$<CONFIG:Debug>:
            -glldb
            >

            $<$<CONFIG:Release>:
            -ffast-math
            >
        )

        target_link_options(${TARGET}
            PRIVATE
            -stdlib=libc++

            $<$<CONFIG:Release>:
            -O3
            -ffast-math
            >
        )
    endif ()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${TARGET}
            PRIVATE
            /utf-8
            /permissive-
            /W4
            /MP

            $<$<CONFIG:Release>:
            /Ob3
            /GT
            /fp:fast
            >
        )
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
            #LINKER:--execute-only
            LINKER:-z,rodynamic

            $<$<CONFIG:Debug>:
            LINKER:--gdb-index
            LINKER:--compress-debug-sections=zstd
            >

            $<$<CONFIG:Release>:
            LINKER:--no-undefined
            LINKER:--as-needed

            LINKER:--hash-style=gnu

            LINKER:-Bsymbolic
            LINKER:--exclude-libs,ALL
            LINKER:-z,now

            LINKER:--gc-sections

            LINKER:-s
            >
        )
    endif ()

    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "LLD" OR CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MOLD")
        target_link_options(${TARGET}
            PRIVATE
            LINKER:--color-diagnostics

            $<$<CONFIG:Release>:
            LINKER:--icf=all
            LINKER:--ignore-data-address-equality
            LINKER:--pack-dyn-relocs=relr
            >
        )
    endif ()

    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "LLD")
        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:
            LINKER:-O2
            >
        )

        if (CMAKE_SYSTEM_NAME STREQUAL "Android" OR CMAKE_SYSTEM_NAME STREQUAL "OHOS")
            target_link_options(${TARGET}
                PRIVATE
                $<$<CONFIG:Release>:
                LINKER:--use-android-relr-tags
                >
            )
        endif ()
    endif ()

    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MOLD")
        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:
            LINKER:--separate-debug-file
            >

            $<$<CONFIG:Release>:
            LINKER:-z,rewrite-endbr
            #LINKER:--zero-to-bss
            >
        )
    endif ()

    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "AppleClang")
        target_link_options(${TARGET}
            PRIVATE
            LINKER:-warn_commons

            $<$<CONFIG:Release>:
            LINKER:-dead_strip_dylibs

            LINKER:-dead_strip
            LINKER:-merge_zero_fill_sections

            LINKER:-S
            LINKER:-x
            >
        )
    endif ()

    if (CMAKE_CXX_COMPILER_LINKER_ID STREQUAL "MSVC")
        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:
            /OPT:REF,ICF=9,LBR
            >
        )
    endif ()
endfunction(set_common_linker_options)

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
