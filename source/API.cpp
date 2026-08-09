#include "API.hpp"
#include "wayland.hpp"
#include "renderer.hpp"
#include "object.hpp"
#include "island.hpp"
#include "log.hpp"

namespace {

const auto config = Island::state();

}

void API::init() {
    Island::init();
    Log::logger(Log::Debug, "Load config successfully");

    Wayland::init();
    Log::logger(Log::Debug, "Wayland initialized successfully");

    Renderer::init();
    Log::logger(Log::Debug, "Renderer initialized successfully");

    Wayland::set_report_click(Object::click);

    Wayland::apply_config(
       config->island_width,
       config->island_height,
       config->zone,
       config->anchor_top
    );
}

void API::resize(uint32_t width, uint32_t height) {
    Wayland::request_resize(width, height);
}

void API::draw_rectangle(RectDesc rect_desc){
    Object::add_rectangle(rect_desc);
}

void API::run(){

}