#include "cpp-demo.hpp"

#include <print>

using namespace std::string_view_literals;

auto cpp_demo::hello() -> void { std::println("Hello cpp-demo!"sv); }
