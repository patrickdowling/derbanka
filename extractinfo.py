#!/usr/bin/env python3
#
# Copyright (c) 2022 Patrick Dowling
# See project LICENSE file.
#
# Retains the annotation of .asm files as used here:
# https://github.com/ndf-zz/fv1build/blob/master/scripts/drvtext

import os
import re
import sys

class ProgramInfo:
    name = '?'
    pot0 = '?'
    pot1 = '?'
    pot2 = '?'

    def set_name(self, string):
        if len(string):
            self.name = string[0:20]

    def set_pot(self, pot, string):
        if len(string):
            if 0 == pot:
                self.pot0 = string[0:20]
            elif 1 == pot:
                self.pot1 = string[0:20]
            elif 2 == pot:
                self.pot2 = string[0:20]

    def WriteBinary(self, filename):
        header = self.name.ljust(20) + '\n'
        header += self.pot0.ljust(20) + '\n'
        header += self.pot1.ljust(20) + '\n'
        header += self.pot2.ljust(20) + '\n'

        with open(filename, 'wb') as f:
            f.write(header.encode('latin_1'))

def ExtractProgramInfo(filename):
    program_pattern = re.compile('^;\s+Program.*?:(.*)$')
    pot_pattern = re.compile('^;\s+POT([012]).*?:(.*)$')

    program_info = ProgramInfo()
    program_info.name = os.path.basename(os.path.splitext(filename)[0])
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if 'Program' in line:
                m = program_pattern.match(line)
                if m:
                    program_info.set_name(m.group(1).strip())
            elif 'POT' in line:
                m = pot_pattern.match(line)
                if m:
                    n = int(m.group(1))
                    t = m.group(2).strip()
                    program_info.set_pot(n, t)
    return program_info


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} in (out)')
        sys.exit(1);

    program_info = ExtractProgramInfo(sys.argv[1])

    if len(sys.argv) > 2:
        program_info.WriteBinary(sys.argv[2])
    else:
        print(f'PROG: {program_info.name}')
        print(f'POT0: {program_info.pot0}')
        print(f'POT1: {program_info.pot1}')
        print(f'POT2: {program_info.pot2}')
