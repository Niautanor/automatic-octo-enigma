cmake_minimum_required(VERSION 3.17)
project(uart)

find_package(verilator REQUIRED)
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found")
endif()

set(SYNTHESIZE FALSE CACHE BOOL "Whether to synthesize fpga images with yosys and nextpnr")

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

add_executable(cpu_test cpu_test.cpp)
set_property(TARGET cpu_test PROPERTY CXX_STANDARD 17)

verilate(cpu_test COVERAGE_TRACE
    VERILATOR_ARGS --trace -Wall -O3
    SOURCES cpu.v)

add_custom_target(run COMMAND cpu_test)

if (${SYNTHESIZE})
    add_custom_command(
        OUTPUT vga_fpga.json
        COMMAND ${CMAKE_COMMAND} -E echo "-- Synthesizing Design"
        COMMAND yosys -q -p "synth_ice40 -json vga_fpga.json" ${CMAKE_CURRENT_SOURCE_DIR}/vga.v
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/vga.v)
    add_custom_command(
        OUTPUT vga_fpga.txt
        COMMAND ${CMAKE_COMMAND} -E echo "-- Placing and Routing"
        COMMAND nextpnr-ice40 --hx8k --package tq144:4k --pcf ${CMAKE_CURRENT_SOURCE_DIR}/vga.pcf --json vga_fpga.json --asc vga_fpga.txt
        DEPENDS vga_fpga.json ${CMAKE_CURRENT_SOURCE_DIR}/vga.pcf)
    add_custom_command(
        OUTPUT vga_fpga.bin
        COMMAND ${CMAKE_COMMAND} -E echo "-- Running icepack"
        COMMAND icepack vga_fpga.txt vga_fpga.bin
        DEPENDS vga_fpga.txt)
    add_custom_target(vga_fpga ALL DEPENDS vga_fpga.bin)
endif()
