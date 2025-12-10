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
    if (${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set_target_properties(${TARGET}
            PROPERTIES
            CXX_VISIBILITY_PRESET default
            VISIBILITY_INLINES_HIDDEN ON
        )
    endif ()
endfunction()

function(set_common_compile_options TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        target_compile_options(${TARGET}
            PRIVATE
            -Wall -Wextra -Wpedantic

            $<$<CONFIG:Debug>:
            -g3
            $<IF:$<CXX_COMPILER_ID:GNU>,-ggdb3,-glldb>
            -Og
            -fsanitize=address -fsanitize=undefined -fsanitize=leak
            >

            $<$<CONFIG:Release>:$<IF:$<CXX_COMPILER_ID:GNU>,-Ofast,-O3 -ffast-math>>

            $<$<AND:$<CONFIG:Release>,$<BOOL:${NATIVE}>>:-march=native>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${TARGET}
            PRIVATE
            /permissive- /utf-8 /W4 /MP
            $<$<CONFIG:Debug>:/sdl /fsanitize=address>
            $<$<CONFIG:Release>:/Ob3 /GT /Gy /fp:fast>
        )
    endif ()
endfunction()

function(set_common_link_options TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:-fsanitize=address -fsanitize=undefined -fsanitize=leak>

            $<$<CONFIG:Release>:
            $<IF:$<CXX_COMPILER_ID:GNU>,-Ofast,-O3 -ffast-math>
            -ffunction-sections -fdata-sections
            >

            LINKER:--warn-common,--warn-once,--as-needed,--no-undefined
            $<$<CONFIG:Debug>:LINKER:--compress-debug-sections=zstd>
            $<$<CONFIG:Release>:LINKER:--gc-sections,-s,--icf=all,--ignore-data-address-equality,--pack-dyn-relocs=relr,-z,now>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:/OPT:REF,ICF /LTCG:incremental>
        )
    endif ()
endfunction()

function(set_common_build_tools TARGET)
    if (SCCACHE)
        find_program(SCCACHE_EXEC sccache)

        set_target_properties(${TARGET}
            PROPERTIES
            RULE_LAUNCH_COMPILE ${SCCACHE_EXEC}
        )
    endif ()

    if (MOLD AND UNIX)
        find_program(MOLD_EXEC mold)

        set_target_properties(${TARGET}
            PROPERTIES
            LINKER_TYPE MOLD
        )
    endif ()
endfunction()
