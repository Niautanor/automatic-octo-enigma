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

    for (int i=0;i<10;i++) tick();

    loopback_tb.rx_data = 'B';
    loopback_tb.rx_en = 1;
    tick();
    loopback_tb.rx_data = 'A';
    tick();
    loopback_tb.rx_data = '#';
    tick();
    loopback_tb.rx_en = 0;

    for (int i=0;i<100;++i) tick();

    loopback_tb.rx_en = 1;
    loopback_tb.rx_data = 'Y';
    tick();
    loopback_tb.rx_data = '+';
    tick();
    loopback_tb.rx_data = '5';
    tick();
    loopback_tb.rx_data = 'A';
    tick();
    loopback_tb.rx_data = '7';
    tick();
    loopback_tb.rx_en = 0;
    tick();

    for (int i=0;i<400;++i) tick();

    return 0;
}
