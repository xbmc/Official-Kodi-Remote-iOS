#!/usr/bin/env python3

from macholib.MachO import MachO
from macholib.mach_o import LC_BUILD_VERSION
import sys

newDeploymentTarget = sys.argv[1]
binaryPath = sys.argv[2]

macho = MachO(binaryPath)
buildVersionCommand = next(
    (command for command in macho.headers[0].commands if command[0].cmd == LC_BUILD_VERSION),
    None
)

# deployment target must have 3 components, add trailing zeros as needed
major, minor, patch = (list(map(int, newDeploymentTarget.split("."))) + [0, 0])[:3]
buildVersionCommand[1].minos = (major << 16) | (minor << 8) | patch

with open(binaryPath, "r+b") as fp:
    macho.write(fp)
