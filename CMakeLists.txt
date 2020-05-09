cmake_minimum_required(VERSION 3.17)
project(uart)

find_package(verilator REQUIRED)
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found")
endif()

add_library(catch catch_main.cpp)
target_include_directories(catch PRIVATE ${VERILATOR_ROOT}/include)

add_executable(rx_test uart_rx_test.cpp)
set_property(TARGET rx_test PROPERTY CXX_STANDARD 17)
target_link_libraries(rx_test PUBLIC catch)

verilate(rx_test COVERAGE_TRACE
    VERILATOR_ARGS --trace -Wall -Wno-fatal -O3
    SOURCES uart_rx.v)

add_executable(vga_test vga_test.cpp)
set_property(TARGET vga_test PROPERTY CXX_STANDARD 17)
target_link_libraries(vga_test PUBLIC catch)

verilate(vga_test COVERAGE_TRACE
    VERILATOR_ARGS --trace -Wall -Wno-fatal -O3
    SOURCES vga.v)

add_custom_target(run COMMAND vga_test)
