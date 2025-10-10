//
//  convert_fmt.cpp
//  Kodi Remote
//
//  Created by Buschmann on 10.10.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#include "convert_fmt.hpp"
#include <fmt/core.h>

char* convert_fmt(const char *format, int value) {
    static char s[128];
    memset(s, 0, sizeof(s));
    fmt::format_to(s, format, value);
    return s;
}
