#include "lib.h"

int add(int a, int b) { return a + b; }

std::vector<int> squares(int n) {
    std::vector<int> out;
    for (int i = 0; i < n; i++) {
        out.push_back(i * i);
    }
    return out;
}

std::map<std::string, int> tally(const std::vector<std::string>& words) {
    std::map<std::string, int> counts;
    for (const auto& word : words) {
        counts[word]++;
    }
    return counts;
}
