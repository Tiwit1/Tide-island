#pragma once

#include <chrono>

namespace Timer {

void init();
void push(
    std::chrono::microseconds duration,
    void (*callback)()
);
void handle_timerfd();

}
