function(set_common_properties TARGET)
    set_target_properties(${TARGET}
        PROPERTIES
        CXX_STANDARD ${CMAKE_CXX_STANDARD_LATEST}
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS ON
        COMPILE_WARNING_AS_ERROR ON
        LINK_WARNING_AS_ERROR OFF
        INTERPROCEDURAL_OPTIMIZATION_RELEASE ON
    )
endfunction(set_common_properties)

function(set_common_compile_options TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(${TARGET}
            PRIVATE
            -Wall -Wextra -Wpedantic

            $<$<CONFIG:Debug>:-g3 -ggdb3 -Og>

            $<$<CONFIG:Release>:-Ofast>

            $<$<AND:$<CONFIG:Release>,$<BOOL:${NATIVE}>>:-march=native>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        target_compile_options(${TARGET}
            PRIVATE
            -stdlib=libc++

            -Wall -Wextra -Wpedantic

            $<$<CONFIG:Debug>:-g3 -glldb -Og>

            $<$<CONFIG:Release>:-O3>

            $<$<AND:$<CONFIG:Release>,$<BOOL:${NATIVE}>>:-march=native>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${TARGET}
            PRIVATE
            /permissive- /utf-8 /W4 /MP
            $<$<CONFIG:Release>:/Ob3 /GT /Gy /fp:fast>
        )
    else ()
        message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif ()
endfunction(set_common_compile_options)

function(set_common_link_options TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:-Ofast -ffunction-sections -fdata-sections>

            LINKER:--warn-common,--warn-once,--as-needed,--no-undefined
            $<$<CONFIG:Debug>:LINKER:--compress-debug-sections=zstd>
            $<$<CONFIG:Release>:LINKER:--gc-sections,-s,-z,now>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        target_link_options(${TARGET}
            PRIVATE
            -stdlib=libc++

            $<$<CONFIG:Release>:-O3 -ffunction-sections -fdata-sections>

            LINKER:--warn-common,--warn-once,--as-needed,--no-undefined
            $<$<CONFIG:Debug>:LINKER:--compress-debug-sections=zstd>
            $<$<CONFIG:Release>:LINKER:--gc-sections,-s,-z,now>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:/OPT:REF,ICF /LTCG:incremental>
        )
    else ()
        message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif ()
endfunction(set_common_link_options)

function(set_common_build_tools TARGET)
    if (SCCACHE)
        find_program(SCCACHE_EXEC sccache)

        set_target_properties(${TARGET}
            PROPERTIES
            RULE_LAUNCH_COMPILE ${SCCACHE_EXEC}
        )
    endif (SCCACHE)

    if (LINKER STREQUAL "LLD")
        find_program(LLD_EXEC lld)

        set_target_properties(${TARGET}
            PROPERTIES
            LINKER_TYPE LLD
        )

        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:LINKER:--icf=all,--ignore-data-address-equality,--pack-dyn-relocs=relr>
        )
    elseif (LINKER STREQUAL "MOLD")
        find_program(MOLD_EXEC mold)

        set_target_properties(${TARGET}
            PROPERTIES
            LINKER_TYPE MOLD
        )

        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Release>:LINKER:--icf=all,--ignore-data-address-equality,--pack-dyn-relocs=relr>
        )
    endif ()
endfunction(set_common_build_tools)

function(set_hidden_visibility TARGET)
    if (${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set_target_properties(${TARGET}
            PROPERTIES
            CXX_VISIBILITY_PRESET hidden
            VISIBILITY_INLINES_HIDDEN ON
            DEFINE_SYMBOL CPP_DEMO_EXPORTS
        )
    endif ()
endfunction(set_hidden_visibility)

function(set_sanitizer TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
    )
        target_compile_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:-fsanitize=address -fsanitize=undefined -fsanitize=leak>
        )

        target_link_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:-fsanitize=address -fsanitize=undefined -fsanitize=leak>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${TARGET}
            PRIVATE
            $<$<CONFIG:Debug>:/fsanitize=address>
        )
    else ()
        message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif ()
endfunction(set_sanitizer)
