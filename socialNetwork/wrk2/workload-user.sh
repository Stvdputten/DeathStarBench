#!/usr/bin/env bash
./wrk -D exp -t 4 -c 8 -d 30s -L -s ./scripts/social-network/read-user-timeline.lua http://localhost:8080/wrk2-api/user-timeline/read -R 200
# curl -d "firstn"