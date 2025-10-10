//
//  convert_fmt.cpp
//  Kodi Remote
//
//  Created by Buschmann on 10.10.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#include "convert_fmt.hpp"
#include <fmt/core.h>

void convert_fmt(char *output, int size, const char *format, int value) {
    // Initialize char array with zeros
    memset(output, 0, size);
    
    // Only fill up to size-1 to esnure null-termination
    fmt::format_to_n(output, size - 1, format, value);
}
