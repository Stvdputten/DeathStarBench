#!/usr/bin/env bash
./wrk -D exp -t 2 -c 4 -d 30s -L -s ./scripts/media-microservices/compose-review.lua http://localhost:8080/wrk2-api/review/compose -R 200