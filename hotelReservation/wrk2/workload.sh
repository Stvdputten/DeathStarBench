#!/usr/bin/env bash
./wrk -D exp -t 2 -c 4 -d 30s -L -s ./wrk2_lua_scripts/mixed-workload_type_1.lua http://localhost:5000 -R 200