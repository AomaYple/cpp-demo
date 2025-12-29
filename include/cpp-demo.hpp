#pragma once

#if defined(_WIN32)
    #ifdef CPP_DEMO_EXPORTS
        #define CPP_DEMO_EXPORT __declspec(dllexport)
    #else    // CPP_DEMO_EXPORTS
        #define CPP_DEMO_EXPORT __declspec(dllimport)
    #endif    // CPP_DEMO_EXPORTS
#else
    #define CPP_DEMO_EXPORT __attribute__((visibility("default")))
#endif

namespace cpp_demo {
    CPP_DEMO_EXPORT auto hello() -> void;
}    // namespace cpp_demo
