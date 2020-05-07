#include <cstdlib>
#include <vector>
#include <array>
#include <experimental/array>
#include <string>

#include "catch.hpp"

#include "Vuart_rx.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

class Frequency {
public:
    constexpr Frequency(double f) : f(f) {}

    constexpr double getF() const { return f; }
    constexpr double getT() const { return 1/f; }

    constexpr auto operator * (double factor) const {
        return Frequency { f * factor };
    }

private:
    double f;
};

static constexpr auto tickRate = Frequency(100e6);

struct VCDEntry {
    double time;
    bool value;
};

template <typename Container> // should be Container<VCDEntry>
constexpr bool replayVCD(const Container& vcd, bool defaultValue, double t) {
    // find the last element where t >= elem.time (i.e. the first from the back)
    const auto iter = std::find_if(std::rbegin(vcd), std::rend(vcd), [t](const auto& elem) {
        return t >= elem.time;
    });

    if (iter == std::rend(vcd)) {
        return defaultValue;
    }

    return iter->value;
}

class UartSimulation {
public:
    UartSimulation() = default;

    constexpr bool isDone(uint64_t tickCount) {
        const auto t = tickCount * tickRate.getT();
        return t >= 10e-3;
    }

    template <size_t N>
    static constexpr auto getTimings(std::array<std::pair<uint8_t, Frequency>, N> bits, double tStart) {
        std::vector<VCDEntry> ret;
        double t = tStart;
        for (const auto& bit : bits) {
            std::vector<bool> values(10);
            values.push_back(0);
            for (uint8_t i = 0; i < 8; ++i) {
                values.push_back(bit.first);
            }
            values.push_back(1);

            for (const auto& value : values) {
                ret.push_back({t, value});
                t += bit.second.getT();
            }
        }
        return ret;
    }

    bool getUart(uint64_t tickCount) const {
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
        static const auto timings = getTimings(bits, 100e-6);
        const auto t = tickCount * tickRate.getT();
        return replayVCD(timings, true, t);
    }
};

class TraceScope final {
public:
    template <class V>
    TraceScope(V& v, const std::string& file) {
        v.trace(&trace, 99);
        trace.open(file.c_str());
    }

    ~TraceScope() {
        trace.close();
    }

    void dump(uint64_t ticks) {
        trace.dump(ticks);
    }

private:
    VerilatedVcdC trace;
};

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

    Vuart_rx uart;
    TraceScope trace(uart, "bytes.vcd");

    UartSimulation uartSim;
    uint64_t tick_count = 0;
    bool dataIsNew = false;
    std::vector<uint8_t> data;

    while (!uartSim.isDone(tick_count)) {
        uart.rx = uartSim.getUart(tick_count);
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
    REQUIRE(data == std::vector<uint8_t> { 0xAA, 0x55, 0x55, 'h', 'e', 'l', 'l', 'o' });
}
