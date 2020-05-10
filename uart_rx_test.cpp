#include <cstdlib>
#include <vector>
#include <array>
#include <experimental/array>
#include <string>

#include "catch.hpp"

#include "utils.hpp"

#include "Vuart_rx.h"
#include "verilated.h"

static constexpr auto tickRate = Frequency(100e6);

template <size_t N>
static constexpr auto getUartTimings(std::array<std::pair<uint8_t, Frequency>, N> bits, double tStart) {
    std::array<VCDEntry, N * 10> ret {};
    double t = tStart;
    size_t i = 0;
    for (const auto& bit : bits) {
        std::array<bool, 10> values {};
        size_t k = 0;
        values[k++] = false;
        for (uint8_t i = 0; i < 8; ++i) {
            values[k++] = (bit.first & (1 << i));
        }
        values[k++] = true;

        for (const auto& value : values) {
            ret[i++] = {t, value};
            t += bit.second.getT();
        }
    }
    return ret;
}

TEST_CASE ("Uart start bit gets detected") {
    constexpr auto baudrate = Frequency(115200);
    constexpr auto vcd = std::experimental::to_array<const VCDEntry>({
        { 100e-6, false },
        { 100e-6 + baudrate.getT(), true },
        { 200e-6, false },
        { 200e-6 + baudrate.getT(), true },
        { 300e-6, false },
        { 300e-6 + 12 * baudrate.getT(), true },
    });

    Vuart_rx uart;
    TraceScope trace(uart, "startbit.vcd");

    uint64_t tick_count = 0;
    bool lastDataReady = uart.data_ready;
    int dataReadyEdges = 0;

    while (tick_count * tickRate.getT() < 1e-3) {
        uart.rx = replayVCD(vcd, true, tick_count * tickRate.getT());
        uart.clk = 0;
        uart.eval();
        trace.dump(tick_count * 10);

        uart.clk = 1;
        uart.eval();
        trace.dump(tick_count * 10 + 5);

        if (uart.data_ready != lastDataReady) {
            if (uart.data_ready) {
                dataReadyEdges++;
            }
            lastDataReady = uart.data_ready;
        }

        tick_count++;
    }

    // signal state at the end of the simulation
    CHECK(uart.data_ready == false);

    // the start bits triggered one byte output but only if the end bit was
    // high
    CHECK(dataReadyEdges == 2);
}

//int main(int argc, char **argv) {
TEST_CASE ("Uart produces the expected bytes") {
    //Verilated::commandArgs(argc, argv);
    static constexpr auto baudrate = Frequency(115200);
    static constexpr std::array bits = {
        std::pair { uint8_t { 0xAA }, baudrate },
        std::pair { uint8_t { 0x55 }, baudrate * 1.045 },
        std::pair { uint8_t { 0x55 }, baudrate * 0.955 },
        std::pair { uint8_t {  'H' }, baudrate },
        std::pair { uint8_t {  'e' }, baudrate },
        std::pair { uint8_t {  'l' }, baudrate },
        std::pair { uint8_t {  'l' }, baudrate },
        std::pair { uint8_t {  'o' }, baudrate },
    };
    static constexpr auto timings = getUartTimings(bits, 100e-6);

    Vuart_rx uart;
    TraceScope trace(uart, "bytes.vcd");

    uint64_t tick_count = 0;
    bool dataIsNew = false;
    std::vector<uint8_t> data;

    while (tick_count * tickRate.getT() < 10e-3) {
        uart.rx = replayVCD(timings, true, tick_count * tickRate.getT());
        uart.clk = 0;
        uart.eval();
        trace.dump(tick_count * 10);

        uart.clk = 1;
        uart.eval();
        trace.dump(tick_count * 10 + 5);

        if (uart.data_ready && dataIsNew) {
            data.push_back(uart.data);
        } else {
            dataIsNew = !uart.data_ready;
        }

        tick_count++;
    }

    // signal state at the end of the simulation
    REQUIRE(uart.data_ready == false);
    // received values
    REQUIRE(data == std::vector<uint8_t> { 0xAA, 0x55, 0x55, 'H', 'e', 'l', 'l', 'o' });
}
