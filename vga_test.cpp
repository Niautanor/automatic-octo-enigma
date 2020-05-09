#include <optional>

#include "catch.hpp"

#include "utils.hpp"

// #include "Vvga.h"

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

        if (time >  next->time + next->slack) {
            result = CheckFailReason::ExpectedChangeDidNotOccur;
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

// detect changes in signals
// check if the change comes at an acceptable time

TEST_CASE ("Sync timing") {
    /*
    uint64_t tickCount = 0;
    Vvga vga;

    // test 10 frames
    for (int i = 0; i < 10; ++i) {
        vga.clk = 0;
        vga.eval();

        // evaluate changes for tickCount * tickRate.getT() / 2

        vga.clk = 1;
        vga.eval();

        // evaluate changes for tickCount * tickRate.getT()

        tickCount++;
    }
    */
}