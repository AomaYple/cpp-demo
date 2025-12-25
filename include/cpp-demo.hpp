#pragma once

#if defined(_WIN32)
    #ifdef CPP_DEMO_EXPORTS
        #define CPP_DEMO_EXPORT __declspec(dllexport)
    #else    // CPP_DEMO_EXPORTS
        #define CPP_DEMO_EXPORT __declspec(dllimport)
    #endif    // CPP_DEMO_EXPORTS
#elif defined(__linux__) || defined(__APPLE__) || defined(__ANDROID__) || defined(__OHOS__)
    #define CPP_DEMO_EXPORT __attribute__((visibility("default")))
#else
    #error "Unsupported platform"
#endif

namespace cpp_demo {
    CPP_DEMO_EXPORT auto hello() -> void;
}    // namespace cpp_demo
