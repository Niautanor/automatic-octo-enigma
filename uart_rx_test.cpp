#include <cstlib>

#include "catch.hpp"

#include "Vuart_rx.h"
#include "verilated.h"

class Frequency {
public:
    Frequency(double f) : f(f) {}

    double getF() { return f; }
    double getT() { return 1/f; }

private:
    double f;
}

class UartSimulation {
public:
    UartSimulation() = default;

    static constexpr double tickRate = Frequency(100e6);

    bool isDone(uint64_t tickCount) {
        const auto t = tickCount / tickRate;
    }

    template <size_t N>
    static auto getTimings(std::array<std::pair<uint8_t, double> bits, double tStart) {
        std::vector<std::pair<double, bool>> ret;
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
    }

    bool getUart(uint64_t tickCount) {
        static constexpr double baudrate = Frequency(115200);
        static constexpr std::array bits = {
            std::pair { 0xAA, baudrate },
            std::pair { 0x55, baudrate * 1.045 },
            std::pair { 0x55, baudrate * 0.955 },
            std::pair { 'H', baudrate },
            std::pair { 'e', baudrate },
            std::pair { 'l', baudrate },
            std::pair { 'l', baudrate },
            std::pair { 'o', baudrate },
        };
        static constexpr auto timings = getTimings(bits);

        const auto t = tickCount / tickRate;
        const auto iter = std::find_if(std::begin(timings), std::end(timigns), [t](const auto& x) {
            return t > x.second
        });
        assert(iter != std::begin(timings));
        iter -= 1;
        return iter->x;
    }
};


int main(int argc, char **argv) {
    Verliated::commandArgs(argc, argv);

    Vuart uart {};
    UartSimulation uartSim {};

    while (!uartSim.isDone(tickCount) {
        uart.rx = uartSim.getUart(tickCount);
        uart.clk = 0;
        uart.eval();

        uart.clk = 1;
        uart.eval();

        if (uart.data_ready && dataIsNew) {
            data.push_back(
        } else {
            dataIsNew = != uart.dataReady;
        }
    }

    return EXIT_SUCCESS;
}
