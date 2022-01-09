#!/usr/bin/env python3
#
# Copyright (c) 2022 Patrick Dowling
# See project LICENSE file.
#
# Simple preprocessor for .asm files.
# Supports very basic .include "filename" directive
# Reads from stdin, outputs to stdout

import re
import sys

if __name__ == "__main__":
    include_pattern = re.compile("^\s*\.include.*?\"(.+?)\"\s*$", flags=re.IGNORECASE)
    for line in sys.stdin:
        m = include_pattern.match(line)
        if m:
            include = m.group(1).strip()
            with open(include, 'r') as f:
                sys.stdout.write(f"; .include {include}\n")
                sys.stdout.write(f.read())
                sys.stdout.write("; .include\n")
        else:
            sys.stdout.write(line)


