#!/bin/bash

set -e

cd test_pgm
sh build.sh
cd ..
~/verilator/bin/verilator -DBENCH -Wno-fatal --top-module tb -cc -exe --trace-depth 2 --trace bench.cpp tb.v 6507.v
cd obj_dir
make -f Vtb.mk
cd ..
