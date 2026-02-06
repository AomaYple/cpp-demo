cmake_minimum_required(VERSION 4.1 FATAL_ERROR)

project(cpp-demo-test VERSION 1.0.0 LANGUAGES CXX)

add_executable(${PROJECT_NAME})

set_common_properties(${PROJECT_NAME})

set_common_compiler_options(${PROJECT_NAME})
set_common_linker_options(${PROJECT_NAME})

set_common_build_tools(${PROJECT_NAME})

#set_sanitizer(${PROJECT_NAME})

file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS
    src/*.cpp
)

target_sources(${PROJECT_NAME}
    PRIVATE
    ${SOURCES}
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
    cpp-demo
)
