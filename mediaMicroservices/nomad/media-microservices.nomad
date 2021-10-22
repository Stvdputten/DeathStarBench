variable "home_dir" {
  type    = string
  default = "/users/stvdp"
}

job "media-microservices" {
  datacenters = ["dc1"]
  // constraint {
  //   operator = "distinct_hosts"
  //   value    = "true"
  // }

  group "nginx-web-server" {
    network {
      mode = "bridge"
      port "nginx" {
        static = 8080
        to     = 8080
      }
    }

    task "nginx-web-server" {
      driver = "docker"
      config {
        image = "yg397/openresty-thrift:xenial"
        ports = ["nginx"]
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/lua-scripts"
          source = "/users/stvdp/DeathStarBench/mediaMicroservice/lua-scripts"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/conf/nginx.conf"
          source = "/users/stvdp/DeathStarBench/mediaMicroservice/nginx.conf"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/jaeger-config.json"
          source = "/users/stvdp/DeathStarBench/mediaMicroservice/nomad/jaeger-config.json"
        }
        mount {
          type   = "bind"
          target = "/gen-lua"
          source = "/users/stvdp/DeathStarBench/mediaMicroservice/nomad/gen-lua"
        }
      }

    }


  }


  group "unique-id-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "unique-id-service" {
      // lifecycle {
      //   hook    = "poststart"
      //   sidecar = true
      // }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && UniqueIdService"]
      }
    }
  }

  group "movie-id-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "movie-id-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && echo '127.0.0.1  movie-id-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-id-memcached' >> /etc/hosts && MovieIdService"]
      }
    }

    task "movie-id-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-id-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "text-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "text-service" {
      // lifecycle {
      //   hook    = "poststart"
      //   sidecar = true
      // }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && TextService"]
      }
    }
  }

  group "rating-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "rating-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  rating-redis' >> /etc/hosts && RatingService"]
      }
    }

    task "rating-redis" {
      driver = "docker"
      config {
        image = "redis:alpine3.13"
      }
    }
  }

  group "user-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "user-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  user-mongodb' >> /etc/hosts &&  echo '127.0.0.1  user-memcached' >> /etc/hosts && UserService"]
      }
    }

    task "user-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "user-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "compose-review-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "compose-review-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  compose-review-memcached' >> /etc/hosts && ComposeReviewService"]
      }
    }

    task "compose-review-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "review-storage-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "review-storage-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  review-storage-mongodb' >> /etc/hosts && echo '127.0.0.1  review-storage-memcached' >> /etc/hosts && ReviewStorageService"]
      }
    }

    task "review-storage-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "review-storage-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "user-review-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "user-review-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  user-review-mongodb' >> /etc/hosts && echo '127.0.0.1  user-review-redis' >> /etc/hosts && UserReviewService"]
      }
    }

    task "user-review-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "user-review-redis" {
      driver = "docker"
      config {
        image = "redis:alpine3.13"
      }
    }
  }

  group "movie-review-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "movie-review-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  movie-review-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-review-redis' >> /etc/hosts && MovieReviewService"]
      }
    }

    task "movie-review-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-review-redis" {
      driver = "docker"
      config {
        image = "redis:alpine3.13"
      }
    }
  }


  group "cast-info-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "cast-info-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && echo '127.0.0.1  cast-info-mongodb' >> /etc/hosts && echo '127.0.0.1  cast-info-memcached' >> /etc/hosts && CastInfoService"]
      }
    }

    task "cast-info-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "cast-info-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "plot-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "plot-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && echo '127.0.0.1  plot-mongodb' >> /etc/hosts && echo '127.0.0.1  plot-memcached' >> /etc/hosts && PlotService"]
      }
    }

    task "plot-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "plot-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "movie-info-service" {
    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "movie-info-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && echo '127.0.0.1  movie-info-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-info-memcached' >> /etc/hosts && MovieInfoService"]
      }
    }

    task "movie-info-mongodb" {
      driver = "docker"
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-info-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "jaeger" {
    network {
      mode = "bridge"
      port "jaeger-ui" {
        static = 16686
        to     = 16686
      }
      port "jaeger" {
        to = 6831
      }
    }
    service {
      name = "jaeger"
      port = "6831"
      connect {
        sidecar_service {}
      }
    }
    service {
      name = "jaeger-ui"
      port = "16686"
      connect {
        sidecar_service {}
      }
    }


    task "jaeger" {
      driver = "docker"
      env {
        COLLECTOR_ZIPKIN_HTTP_PORT = "9411"
      }
      config {
        image = "jaegertracing/all-in-one:latest"
        ports = ["jaeger", "jaeger-ui"]
      }
    }
  }

}
