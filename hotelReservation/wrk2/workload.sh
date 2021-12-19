#!/usr/bin/env bash
while getopts t:c:d:R: flag
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
  if [ -z "$threads" ] || [ -z "$connections" ]  || [ -z "$duration" ] || [ -z "$requests" ]
    then
      echo "No argument supplied nginx"
      echo "using default args"
      ./wrk -D exp -t 2 -c 4 -d 30s -L -s ./wrk2_lua_scripts/mixed-workload_type_1.lua http://localhost:5000 -R 200
    else 
      echo "No argument supplied nginx"
      echo "using  args: threads=$threads and connections=$connections and duration=$duration and requests=$requests"
      ./wrk -D exp -t $threads -c $connections -d "$duration"s -L -s ./wrk2_lua_scripts/mixed-workload_type_1.lua http://localhost:5000 -R requests
  fi
else
  if [ -z "$threads"] || [ -z "$connections" ] || [ -z "$duration" ] || [ -z "$requests" ]
    then
      echo "Using argument nginx"
      echo "using default args"
      ./wrk -D exp -t 2 -c 4 -d 30s -L -s ./wrk2_lua_scripts/mixed-workload_type_1.lua http://$nginx_ip:5000 -R 200
    else 
    else
      echo "Using argument nginx"
      echo "using  args: threads=$threads and connections=$connections and duration=$duration and requests=$requests"
      ./wrk -D exp -t $threads -c $connections -d "$duration"s -L -s ./wrk2_lua_scripts/mixed-workload_type_1.lua http://$nginx_ip:5000 -R $requests
  fi
fi
