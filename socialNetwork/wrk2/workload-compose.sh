#!/usr/bin/env bash
./wrk -D exp -t 4 -c 8 -d 30s -L -s ./scripts/social-network/compose-post.lua http://localhost:8080/wrk2-api/post/compose -R 200
