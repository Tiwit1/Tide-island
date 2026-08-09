#define SOKOL_IMPL

#include "renderer.hpp"
#include "wayland.hpp"
#include "sokol_gfx.h"
#include "basic.glsl.h"
#include "sokol_log.h"
#include "log.hpp"

#include <GLES3/gl3.h>

#if defined(__GLIBC__)
#include <malloc.h>
#endif

using namespace std;

namespace {

struct Vertex {
    int x, y;
    float r, g, b, a;
};

sg_shader rectangle_shader{};
sg_pipeline rectangle_pipeline{};
sg_buffer rect_vertex_buffer{};

array<float, 24> rectangle_vertices(
    Frame frame,
    array<float, 4> color) {
    return { frame.x, frame.y, color[0], color[1],
        color[2], color[3], frame.x + frame.width, frame.y,
        color[0], color[1], color[2], color[3],
        frame.x, frame.y + frame.height, color[0],
        color[1], color[2], color[3], frame.x + frame.width,
        frame.y + frame.height, color[0], color[1], color[2], color[3],
    };
}

project_uniform_t projection() {
    auto surface_size = Wayland::get_surface_size();

    project_uniform_t result{};
    result.proj[0] = 2.0F / static_cast<float>(surface_size[0]);
    result.proj[5] = -2.0F / static_cast<float>(surface_size[1]);
    result.proj[10] = 1.0F;
    result.proj[12] = -1.0F;
    result.proj[13] = 1.0F;
    result.proj[15] = 1.0F;
    return result;
}

radius_uniform_t radius_uniform(Frame frame, float radius) {
    radius_uniform_t result{};
    result.center[0] = frame.x + frame.width / 2.0F;
    result.center[1] = frame.y + frame.height / 2.0F;
    result.half_size[0] = frame.width / 2.0F;
    result.half_size[1] = frame.height / 2.0F;
    result.radius = radius;
    return result;
}

void enable_blending(sg_pipeline_desc& descriptor) {
    auto& blend = descriptor.colors[0].blend;
    blend.enabled = true;
    blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
    blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    blend.src_factor_alpha = SG_BLENDFACTOR_ONE;
    blend.dst_factor_alpha = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
}

sg_swapchain swapchain() {
    auto surface_size= Wayland::get_surface_size();

    sg_swapchain result{};
    result.width = surface_size[0];
    result.height = surface_size[1];
    result.sample_count = 1;
    result.color_format = SG_PIXELFORMAT_RGBA8;
    result.depth_format = SG_PIXELFORMAT_NONE;
    result.gl.framebuffer = 0;
    return result;
}

} // namespace

void Renderer::init() {
    sg_desc descriptor{};
    descriptor.logger.func = slog_func;
    descriptor.environment.defaults.color_format = SG_PIXELFORMAT_RGBA8;
    descriptor.environment.defaults.depth_format = SG_PIXELFORMAT_NONE;
    descriptor.environment.defaults.sample_count = 1;
    sg_setup(&descriptor);
    if (!sg_isvalid()) {
        Log::fatal("Failed to initialize Sokol");
    }

    rectangle_shader = sg_make_shader(rectangle_shader_desc(sg_query_backend()));

    sg_pipeline_desc rectangle_pipe_desc{};

    rectangle_pipe_desc.shader = rectangle_shader;
    rectangle_pipe_desc.layout.attrs[ATTR_rectangle_position].format = SG_VERTEXFORMAT_FLOAT2;
    rectangle_pipe_desc.layout.attrs[ATTR_rectangle_color].format = SG_VERTEXFORMAT_FLOAT4;
    rectangle_pipe_desc.primitive_type = SG_PRIMITIVETYPE_TRIANGLE_STRIP;
    enable_blending(rectangle_pipe_desc);
    rectangle_pipeline = sg_make_pipeline(&rectangle_pipe_desc);

    sg_buffer_desc buffer_descriptor{};
    buffer_descriptor.size = 16 * 1024;
    buffer_descriptor.usage.dynamic_update = true;
    buffer_descriptor.label = "rect_vertex_buffer";
    rect_vertex_buffer = sg_make_buffer(&buffer_descriptor);

    glReleaseShaderCompiler();
    #if defined(__GLIBC__)
        static_cast<void>(malloc_trim(0));
    #endif
}

void Renderer::begin_frame() {
    sg_pass pass{};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {0.0F, 0.0F, 0.0F, 0.0F};
    pass.swapchain = swapchain();
    sg_begin_pass(&pass);
}

void Renderer::end_frame() {
    sg_end_pass();
    sg_commit();

    Wayland::swap_buffer();
}

void Renderer::draw_rectangle(
    Frame frame,
    float radius,
    array<float, 4> color) {

    if (radius <= 0){
        Log::logger(Log::Warning,"Radius should not be neagative");
    }

    auto vertices = rectangle_vertices(frame, color);
    int offset = sg_append_buffer(rect_vertex_buffer, SG_RANGE(vertices));
    if (sg_query_buffer_overflow(rect_vertex_buffer)) {
        Log::fatal("Vertex bufer overflow");
    }

    sg_bindings bindings{};
    bindings.vertex_buffers[0] = rect_vertex_buffer;
    bindings.vertex_buffer_offsets[0] = offset;
    sg_apply_pipeline(rectangle_pipeline);
    sg_apply_bindings(&bindings);
    auto project = projection();
    auto radius_data = radius_uniform(frame, radius);
    sg_apply_uniforms(UB_project_uniform, SG_RANGE(project));
    sg_apply_uniforms(UB_radius_uniform, SG_RANGE(radius_data));
    sg_draw(0, 4, 1);
}