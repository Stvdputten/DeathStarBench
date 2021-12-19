#!/usr/bin/env bash
while getopts u:a:f: flag
do
    case "${flag}" in
        t) threads=${OPTARG};;
        c) connections=${OPTARG};;
        d) duration=${OPTARG};;
        R) requests=${OPTARG};;
    esac
done

if [ -z "$nginx_ip" ]
then
  if [ -z "$threads" ] || [-z "$connections" ] || [ -z "$duration" || [ -z "$requests" ]
    then
      echo "No argument supplied nginx"
      echo "using default args"
      ./wrk -D exp -t 4 -c 8 -d 30s -L -s ./scripts/social-network/read-home-timeline.lua http://localhost:8080/wrk2-api/home-timeline/read -R 200
    else 
      echo "No argument supplied nginx"
      echo "using  args: threads=$threads and connections=$connections and duration=$duration and requests=$requests"
      ./wrk -D exp -t $threads -c $connections -d "$duration"s -L -s ./scripts/social-network/read-home-timeline.lua http://localhost:8080/wrk2-api/home-timeline/read -R $requests
  fi
else
  if [ -z "$threads" ] || [ -z "$connections" ] || [ -z "$duration" ] || [ -z "$requests" ]
    then
      echo "Using argument nginx"
      echo "using default args"
      ./wrk -D exp -t 4 -c 8 -d 30s -L -s ./scripts/social-network/read-home-timeline.lua http://$nginx_ip:8080/wrk2-api/home-timeline/read -R 200
    else 
    else
      echo "Using argument nginx"
      echo "using  args: threads=$threads and connections=$connections and duration=$duration and requests=$requests"
      ./wrk -D exp -t $threads -c $connections -d "$duration"s -L -s ./scripts/social-network/read-home-timeline.lua http://$nginx_ip:8080/wrk2-api/home-timeline/read -R $requests
  fi
fi
