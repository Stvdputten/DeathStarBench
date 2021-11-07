export NOMAD_VAR_jaeger="127.0.0.1"

# Overview of services and ports 
dns-media 
unique-id-service /   
movie-id-service / 
  movie-id-memcached
  movie-id-mongodb
text-service / 
rating-service / 
  rating-redis
user-service / 
  user-mongodb 
compose-review-service /
  compose-review-memcached
review-storage-service / 
  review-storage-memcached
  review-storage-mongodb
user-review-service / 
  user-review-mongodb 
  user-review-redis 
movie-review-service / 
  movie-review-redis
  movie-review-mongodb
nginx-web-server
cast-info-service /
  cast-info-mongodb
  cast-info-memcached
plot-service / 
  plot-memcached
  plot-mongodb
movie-info-service /
  movie-info-memcached
  movie-info-mongodb

jaeger


# Overview of service names for dns
  "unique-id-service": {
    "addr": "unique-id-service",
    "port": 9090
  },
  "movie-id-service": {
    "addr": "movie-id-service",
    "port": 9090
  },
  "movie-id-mongodb": {
    "addr": "movie-id-mongodb",
    "port": 27017
  },
  "movie-id-memcached": {
    "addr": "movie-id-memcached",
    "port": 11211
  },
  "user-mongodb": {
    "addr": "user-mongodb",
    "port": 27017
  },
  "user-memcached": {
    "addr": "user-memcached",
    "port": 11211
  },
  "text-service": {
    "addr": "text-service",
    "port": 9090
  },
  "rating-service": {
    "addr": "rating-service",
    "port": 9090
  },
  "rating-redis": {
    "addr": "rating-redis",
    "port": 6379
  },
  "user-service": {
    "addr": "user-service",
    "port": 9090
  },
  "compose-review-service": {
    "addr": "compose-review-service",
    "port": 9090
  },
  "compose-review-memcached": {
    "addr": "compose-review-memcached",
    "port": 11211
  },
  "review-storage-service": {
    "addr": "review-storage-service",
    "port": 9090
  },
  "review-storage-mongodb": {
    "addr": "review-storage-mongodb",
    "port": 27017
  },
  "review-storage-memcached": {
    "addr": "review-storage-memcached",
    "port": 11211
  },
  "user-review-service": {
    "addr": "user-review-service",
    "port": 9090
  },
  "user-review-mongodb": {
    "addr": "user-review-mongodb",
    "port": 27017
  },
  "user-review-redis": {
    "addr": "user-review-redis",
    "port": 6379
  },
  "movie-review-service": {
    "addr": "movie-review-service",
    "port": 9090
  },
  "movie-review-mongodb": {
    "addr": "movie-review-mongodb",
    "port": 27017
  },
  "movie-review-redis": {
    "addr": "movie-review-redis",
    "port": 6379
  },
  "cast-info-service": {
    "addr": "cast-info-service",
    "port": 9090
  },
  "cast-info-mongodb": {
    "addr": "cast-info-mongodb",
    "port": 27017
  },
  "cast-info-memcached": {
    "addr": "cast-info-memcached",
    "port": 11211
  },
  "plot-service": {
    "addr": "plot-service",
    "port": 9090
  },
  "plot-mongodb": {
    "addr": "plot-mongodb",
    "port": 27017
  },
  "plot-memcached": {
    "addr": "plot-memcached",
    "port": 11211
  },
  "movie-info-service": {
    "addr": "movie-info-service",
    "port": 9090
  },
  "movie-info-mongodb": {
    "addr": "movie-info-mongodb",
    "port": 27017
  },
  "movie-info-memcached": {
    "addr": "movie-info-memcached",
    "port": 11211
  },
  "page-service": {
    "addr": "page-service",
    "port": 9090
  }
}


# Issues
(Consul connect doesn't add hosts)[https://www.google.com/search?client=firefox-b-d&q=extra+hosts+nomad]

# /etc/hosts setup
127.0.0.1  jaeger
127.0.0.1  unique-id-service
127.0.0.1  movie-id-service
127.0.0.1  cast-info-service
127.0.0.1  text-service
127.0.0.1  rating-id-service
127.0.0.1  user-service
127.0.0.1  compose-review-service
127.0.0.1  review-storage-service
127.0.0.1  user-review-service
127.0.0.1  movie-review-service
127.0.0.1  movie-review-service
127.0.0.1  plot-service
127.0.0.1  movie-info-service