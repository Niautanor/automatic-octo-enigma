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
