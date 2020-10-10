#include "Vloopback_tb.h"
#include "verilated.h"
#include "utils.hpp"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vloopback_tb loopback_tb {};
    TraceScope trace(loopback_tb, "loopback_tb.vcd");

    uint64_t tick_count = 0;
    const auto tick = [&]() {
        loopback_tb.clk = 0;
        loopback_tb.eval();
        trace.dump(tick_count * 10);

        loopback_tb.clk = 1;
        loopback_tb.eval();
        trace.dump(tick_count * 10 + 5);

        tick_count += 1;
    };

    const auto push_byte = [&](char c) {
        loopback_tb.rx_data = c;
        loopback_tb.rx_valid = 1;
        do {
            tick();
        } while (!loopback_tb.rx_ready);
        loopback_tb.rx_valid = 0;
    };

    for (int i=0;i<10;i++) tick();

    push_byte('B');
    push_byte('A');
    push_byte('#');

    for (int i=0;i<100;++i) tick();

    push_byte('Y');
    push_byte('+');
    push_byte('5');
    push_byte('A');
    push_byte('7');

    for (int i=0;i<400;++i) tick();

    return 0;
}
