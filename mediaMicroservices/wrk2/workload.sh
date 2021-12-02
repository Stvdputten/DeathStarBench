#!/usr/bin/env bash
if [ -z "$nginx_ip" ]
  then
    echo "No argument supplied"
    echo "using default"
    ./wrk -D exp -t 2 -c 4 -d 30s -L -s ./scripts/media-microservices/compose-review.lua http://localhost:8080/wrk2-api/review/compose -R 200
  else
    ./wrk -D exp -t 2 -c 4 -d 30s -L -s ./scripts/media-microservices/compose-review.lua http://$nginx_ip:8080/wrk2-api/review/compose -R 200
fi
