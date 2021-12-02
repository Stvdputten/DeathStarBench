#!/usr/bin/env bash
if [ -z "$nginx_ip" ]
  then
    echo "No argument supplied"
    echo "using default"
    ./wrk -D exp -t 4 -c 8 -d 30s -L -s ./scripts/social-network/compose-post.lua http://localhost:8080/wrk2-api/post/compose -R 200
  else
    ./wrk -D exp -t 4 -c 8 -d 30s -L -s ./scripts/social-network/compose-post.lua http://$nginx_ip:8080/wrk2-api/post/compose -R 200
fi
