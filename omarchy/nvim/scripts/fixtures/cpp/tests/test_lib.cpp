#include <gtest/gtest.h>
#include "lib.h"

TEST(Lib, AddOk) { EXPECT_EQ(add(1, 2), 3); }
TEST(Lib, AddBad) { EXPECT_EQ(add(1, 2), 4); }
