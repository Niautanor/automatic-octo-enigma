#define CATCH_CONFIG_RUNNER
#include "catch.hpp"

#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    return Catch::Session().run(argc, argv);
}
