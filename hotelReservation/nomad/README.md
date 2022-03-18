# Overview of services and ports
/consul 
/frontend 5000
/profile 8081
  /memcached-profile 11213
  /mongodb-profile 27019:27017
/search 8082
/geo 8083
  /mongodb-geo 27018:27017
/rate 8084
  /memcached-rate 11212
  /mongodb-rate 27020:27017
/recommendation 8085
  /mongodb-recommendation 27021:27017
/user 8086
  /mongodb-user 27023:27017
/reservation 8087
  /memcached-reserve 11214:11211
  /mongodb-reservation 27022:27017
  Jaeger

volumes
geo profile rate recommendation reservation user