cmake_minimum_required(VERSION 3.17)
project(uart)

find_package(verilator)
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found")
endif()

add_executable(rx_test catch_main.cpp uart_rx_test.cpp)

set_property(TARGET rx_test PROPERTY CXX_STANDARD 17)

verilate(rx_test COVERAGE_TRACE
    VERILATOR_ARGS --trace -Wall -Wno-fatal -O3
    SOURCES uart_rx.v)

