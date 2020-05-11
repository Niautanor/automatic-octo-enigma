#include <optional>
#include <iostream>

#include "catch.hpp"

#include "utils.hpp"

#include "Vvga.h"

class Checker {
public:
    struct CheckableValueChange {
        bool value;
        double time;
        double slack;
    };

    enum class CheckFailReason {
        ActualValueChangedUnexpectedly,
        ExpectedChangeDidNotOccur,
        ExpectedListComplete,
    };

    Checker(std::vector<CheckableValueChange> expected) : expected(std::move(expected)) {}

    auto update(bool input, double time) {
        auto result = std::optional<CheckFailReason> {};

        if (next != expected.cend()) {
            UNSCOPED_INFO("Next expected change at t=" << next->time * 1e9 << "ns+-" << next->slack * 1e9 << "ns to value " << next->value);
            if (time >  next->time + next->slack) {
                result = CheckFailReason::ExpectedChangeDidNotOccur;
            }
        } else {
            UNSCOPED_INFO("No change expected");
        }

        if (state != input) {
            state = input;

            if (next == expected.cend()) {
                result = CheckFailReason::ExpectedListComplete;
                return result;
            }

            if (time < next->time - next->slack) {
                result = CheckFailReason::ActualValueChangedUnexpectedly;
            }

            next++;
        }

        return result;
    }

    const std::vector<CheckableValueChange>& getExpected() const {
        return expected;
    }

    bool getExpectation(double time) const {
        const auto iter = std::find_if(expected.crbegin(), expected.crend(), [time](const auto& x) {
            return time > x.time;
        });
        if (iter == expected.crend()) {
            return false;
        }
        return iter->value;
    }

private:
    bool state = false;
    std::vector<CheckableValueChange> expected;
    decltype(expected.cbegin()) next { expected.cbegin() };
};

std::ostream& operator << (std::ostream& stream, Checker::CheckFailReason reason) {
    switch (reason) {
    case Checker::CheckFailReason::ActualValueChangedUnexpectedly:
        return stream << "ActualValueChangedUnexpectedly";
    case Checker::CheckFailReason::ExpectedChangeDidNotOccur:
        return stream << "ExpectedValueChangeDidNotOccur";
    }
    throw;
}

std::ostream& operator << (std::ostream& stream, std::optional<Checker::CheckFailReason> reason) {
    if (!reason) {
        return stream << "{}";
    }
    Checker::CheckFailReason r = *reason;
    stream << "{" << r << "}";
    return stream;
}

TEST_CASE("Simple Checker tests") {
    Checker checker({
        { true, 0.5, 0.1 },
    });

    // value changes unexpectedly early
    CHECK(checker.update(true, 0.3) == Checker::CheckFailReason::ActualValueChangedUnexpectedly);
    // value change after complete list is detected
    CHECK(checker.update(false, 0.7) == Checker::CheckFailReason::ExpectedListComplete);
}

TEST_CASE("Checker tests") {
    Checker checker({
        { true, 0.5, 0.1 },
        { false, 0.75, 0.05 },
        { true, 1, 0.01 },
        { false, 1.1, 0.05 },
        { true, 1.2, 0.04 },
        { false, 1.3, 0.04 },
    });


    // no value change outside of expected change
    CHECK(!checker.update(false, 0.2));
    // no value change inside  of expected change rage
    CHECK(!checker.update(false, 0.45));
    // value changes to expected value early within margin
    CHECK(!checker.update(true, 0.455));
    // no value change afterwards
    CHECK(!checker.update(true, 0.5));
    // value changes late but still in margin on ext
    CHECK(!checker.update(false, 0.754));
    // value changes unexpectedly early
    CHECK(checker.update(true, 0.9) == Checker::CheckFailReason::ActualValueChangedUnexpectedly);
    // but it doesn't change anymore and the next check is on time which means
    // that this is correct
    CHECK(!checker.update(false, 1.1));
    // skipping a value change completely should trigger an error
    CHECK(checker.update(false, 1.3) == Checker::CheckFailReason::ExpectedChangeDidNotOccur);
}

std::ostream& operator << (std::ostream& stream, Checker::CheckableValueChange change) {
    return stream << "{ " << int { change.value } << ", @" << change.time * 1e9 << "ns+-" << change.slack * 1e9 << "ns }";
}

TEST_CASE ("Sync timing") {
    Vvga vga;
    TraceScope trace(vga, "vga_sync.vcd");

    auto sampleClock = Frequency(100e6);
    // the "technically correct" clock to get exactly 60FPS is 25.175 MHz but we
    // reduce it to 25MHz to make the implementation easier
    auto pixelClock = Frequency(25e6);

    auto hPulseStartTime = (640 + 16) * pixelClock.getT();
    auto hPulseReleaseTime = hPulseStartTime + 96 * pixelClock.getT();
    auto lineTime = hPulseReleaseTime + 48 * pixelClock.getT();

    auto vPulseStartTime = (480 + 11) * lineTime;
    auto vPulseReleaseTime = vPulseStartTime + 2 * lineTime;
    auto frameTime = vPulseReleaseTime + 31 * lineTime;

    // I guess that'll be okay
    auto pixelSlack = pixelClock.getT() * 0.5;

    std::vector<Checker::CheckableValueChange> hsyncs;
    for (int line = 0; line < 2 * (480+11+2+31); ++line) {
        hsyncs.push_back({ true,  line * lineTime + hPulseStartTime, pixelSlack });
        hsyncs.push_back({ false, line * lineTime + hPulseReleaseTime, pixelSlack });
    }
    Checker HSyncChecker(hsyncs);
    Checker VSyncChecker({
        { true, vPulseStartTime, pixelSlack },
        { false, vPulseReleaseTime, pixelSlack },
        { true, frameTime + vPulseStartTime, pixelSlack },
        { false, frameTime + vPulseReleaseTime, pixelSlack },
    });

    for (uint64_t tickCount = 0; tickCount < 2 * frameTime / sampleClock.getT(); tickCount++) {
        INFO("t = " << tickCount * sampleClock.getT() * 1e3 << "ms, v = " << int {vga.vsync});
        REQUIRE(HSyncChecker.update(vga.hsync, tickCount * sampleClock.getT()) == std::nullopt);
        REQUIRE(VSyncChecker.update(vga.vsync, tickCount * sampleClock.getT()) == std::nullopt);

        vga.eval();
        vga.clk = 0;
        vga.eval();
        trace.dump(tickCount * 10);

        vga.clk = 1;
        vga.eval();
        trace.dump(tickCount * 10 + 5);
    }
}
