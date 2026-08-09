#pragma once

#include "json.hpp"

namespace Config {

nlohmann::json read();
const nlohmann::json& get_config();
void write(nlohmann::json& config);
void init();
}