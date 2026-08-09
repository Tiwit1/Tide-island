#pragma once

#include <chrono>

namespace Event {

using Callback = void (*)();

struct Timer {
    std::chrono::steady_clock::time_point deadline;
    Callback callback;
};

void init();

void add_timer(
    std::chrono::microseconds duration,
    Callback callback
);

void impl_wait();
void handle_timerfd();
}
