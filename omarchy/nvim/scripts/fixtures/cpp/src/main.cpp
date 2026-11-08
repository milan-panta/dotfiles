#include <iostream>
#include "lib.h"

int main(int argc, char** argv) {
    auto values = squares(6);
    auto counts = tally({"a", "b", "a"});
    int total = 0;
    for (int v : values) {
        total = add(total, v);
    }
    std::cout << "total " << total << " args " << argc << std::endl;
    if (argc > 5) {
        int* p = nullptr;
        *p = 1;  // segfault on demand
    }
    (void)argv;
    (void)counts;
    return 0;
}
