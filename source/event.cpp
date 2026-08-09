#include "event.hpp"
#include "wayland.hpp"

#include <queue>
#include <sys/timerfd.h>
#include <unistd.h>
#include "log.hpp"

using namespace std;
using namespace std::chrono;

namespace {

struct TimerCompare {
    bool operator()(const Event::Timer& a, const Event::Timer& b) const {
        return a.deadline > b.deadline;
    }
};

std::priority_queue<Event::Timer, std::vector<Event::Timer>, TimerCompare> timers{};
int timer_fd = -1;
int wayland_fd = -1;

void set_timer_at(steady_clock::time_point deadline) {
    duration since_epoch = deadline.time_since_epoch();
    duration seconds_part = duration_cast<seconds>(since_epoch);
    auto nanoseconds_part = duration_cast<nanoseconds>(since_epoch - seconds_part);
    itimerspec spec{};

    spec.it_value.tv_sec = static_cast<time_t>(seconds_part.count());

    spec.it_value.tv_nsec = static_cast<long>(nanoseconds_part.count());

    if (timerfd_settime(
        timer_fd,
        TFD_TIMER_ABSTIME,
        &spec,
        nullptr
    ) == -1) {
        Log::fatal("timerfd_settime failed");
    }
}

} // namespace

void Event::init() {
    timer_fd = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK);
    if (timer_fd == -1) {
        Log::fatal("Failed to create timerfd");
    }

    wayland_fd = Wayland::get_wayland_fd();

    if (wayland_fd == -1) {
        Log::fatal("Failed to get Wayland file descriptor");
    }
}

void Event::add_timer(std::chrono::microseconds duration, void (*callback)()){
    auto deadline = steady_clock::now() + duration;
    timers.emplace(deadline, callback);
}

void Event::impl_wait() {

    pollfd fds[] = {
        {
            .fd = wayland_fd,
            .events = POLLIN,
            .revents = 0,
        },
        {
            .fd = timer_fd,
            .events = POLLIN,
            .revents = 0,
        },
    };

    if ( wl_prepere_read() == -1) {
        Log::fatal("wl_prepare_read failed");
    }
}

void Event::handle_timerfd() {
    while (!timers.empty()) {
        auto& top_timer = timers.top();
        auto now = steady_clock::now();

        if (now >= top_timer.deadline) {
            if (!top_timer.callback) {
                Log::fatal("Timer callback is nullptr");
            }
            top_timer.callback();
            timers.pop();

        } else {
            set_timer_at(top_timer.deadline);
            break;
        }
    }
}