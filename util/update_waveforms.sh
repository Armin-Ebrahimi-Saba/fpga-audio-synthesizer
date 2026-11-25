#!/usr/bin/env bash
python3 ./gen_waveforms.py > $(git rev-parse --show-toplevel)/src/sw/project/hal/waveforms.h
