#include "utils.hpp"

#include "verilated.h"

#include "Vcpu.h"

int main(int, char**) {
    Verilated::traceEverOn(true);

    Vcpu cpu;
    TraceScope trace(cpu, "cpu.vcd");

    for (uint64_t tick = 0; tick < 1000000; ++tick) {
        cpu.clk = 0;
        cpu.eval();
        trace.dump(tick * 10);

        cpu.clk = 1;
        cpu.eval();
        trace.dump(tick * 10 + 5);
    }
}
