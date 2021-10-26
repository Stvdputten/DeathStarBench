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
      port "jaeger-ui" {
        static = 16686
        to     = 16686
      }
      port "jaeger" {
        static = 6831
        to = 6831
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            // upstreams {
            //   destination_name = "jaeger"
            //   local_bind_port  = 6831
            // }
            // upstreams {
            //   destination_name = "jaeger-zipkin"
            //   local_bind_port  = 9411
            // }
            upstreams {
              destination_name = "unique-id-service"
              local_bind_port  = 9090
            }
            upstreams {
              destination_name = "movie-id-service"
              local_bind_port  = 9091
            }
            upstreams {
              destination_name = "text-service"
              local_bind_port  = 9092
            }
            upstreams {
              destination_name = "rating-service"
              local_bind_port  = 9093
            }
            upstreams {
              destination_name = "user-service"
              local_bind_port  = 9094
            }
            upstreams {
              destination_name = "compose-review-service"
              local_bind_port  = 9095
            }
            upstreams {
              destination_name = "review-storage-service"
              local_bind_port  = 9096
            }
            upstreams {
              destination_name = "user-review-service"
              local_bind_port  = 9097
            }
            upstreams {
              destination_name = "movie-review-service"
              local_bind_port  = 9098
            }
            upstreams {
              destination_name = "cast-info-service"
              local_bind_port  = 9099
            }
            upstreams {
              destination_name = "plot-service"
              local_bind_port  = 9100
            }
            upstreams {
              destination_name = "movie-info-service"
              local_bind_port  = 9101
            }
          }
        }
      }
    }

    task "nginx-web-server" {
      driver = "docker"
      config {
        image = "yg397/openresty-thrift:xenial"
        ports = ["nginx"]
        // command = "/usr/local/openresty/bin/openresty"
        // args = ["-g", "daemon off;"]
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && /usr/local/openresty/bin/openresty -g 'daemon off;'"]
        // command = "sh"
        // args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && echo '127.0.0.1  unique-id-service' >> /etc/hosts && echo '127.0.0.1  movie-id-service' >> /etc/hosts && echo '127.0.0.1  text-service' >> /etc/hosts && echo '127.0.0.1  rating-id-service' >> /etc/hosts && echo '127.0.0.1  user-service' >> /etc/hosts && echo '127.0.0.1  compose-review-service' >> /etc/hosts && echo '127.0.0.1  review-storage-service' >> /etc/hosts && echo '127.0.0.1  user-review-service' >> /etc/hosts &&  echo '127.0.0.1  movie-review-service' >> /etc/hosts && echo '127.0.0.1  movie-review-service' >> /etc/hosts &&  echo '127.0.0.1  cast-info-service' && echo '127.0.0.1  plot-service' >> /etc/hosts &&  echo '127.0.0.1  movie-info-service' >> /etc/hosts && /usr/local/openresty/bin/openresty -g 'daemon off;'"]
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/lua-scripts"
          source = "/users/stvdp/DeathStarBench/mediaMicroservices/nomad/lua-scripts"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/conf/nginx.conf"
          source = "/users/stvdp/DeathStarBench/mediaMicroservices/nomad/nginx.conf"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/jaeger-config.json"
          source = "/users/stvdp/DeathStarBench/mediaMicroservices/nomad/jaeger-config.json"
        }
        mount {
          type   = "bind"
          target = "/gen-lua"
          source = "/users/stvdp/DeathStarBench/mediaMicroservices/nomad/gen-lua"
        }
      }
    }

    
    service {
      name = "jaeger"
      port = "6831"
      connect {
        sidecar_service {}
      }
    }
    // service {
    //   name = "jaeger-ui"
    //   port = "16686"
    //   connect {
    //     sidecar_service {}
    //   }
    // }


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


  group "unique-id-service" {
    network {
      mode = "bridge"
      port "http" {
        static = 9090
        to     = 9090
      }
    }
    service {
      name = "unique-id-service"
      port = "9090"
      connect {
        sidecar_service {}
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "compose-review-service"
              local_bind_port  = 9095
            }
          }
        }
      }
    }

    task "unique-id-service" {
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && echo '127.0.0.1  unique-id-service' >> /etc/hosts && echo '127.0.0.1  compose-review-service' >> /etc/hosts && UniqueIdService"]
        ports = ["http"]
      }
    }
  }

  group "movie-id-service" {
    network {
      mode = "bridge"
      port "http" {
        static = 9091
        to     = 9091
      }
    }

    service {
      name = "movie-id-service"
      port = "9091"
      connect {
        sidecar_service {}
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "compose-review-service"
              local_bind_port  = 9095
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
        args    = ["-c", "echo '127.0.0.1  compose-review-service' >> /etc/hosts && echo '127.0.0.1  jaeger' >> /etc/hosts && echo '127.0.0.1  movie-id-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-id-memcached' >> /etc/hosts && MovieIdService"]
        ports = ["http"]
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
    service {
      name = "text-service"
      port = "9092"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9092
        to     = 9092
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "compose-review-service"
              local_bind_port  = 9095
            }
          }
        }
      }
    }

    task "text-service" {
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  compose-review-service' >> /etc/hosts  && echo '127.0.0.1  jaeger' >> /etc/hosts && TextService"]
        ports = ["http"]
      }
    }
  }

  group "rating-service" {
    service {
      name = "rating-service"
      port = "9093"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9093
        to     = 9093
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "compose-review-service"
              local_bind_port  = 9095
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
        args    = ["-c", "echo '127.0.0.1  compose-review-service' >> /etc/hosts && echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  rating-redis' >> /etc/hosts && RatingService"]
        ports = ["http"]
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
    service {
      name = "user-service"
      port = "9094"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9094
        to     = 9094
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "compose-review-service"
              local_bind_port  = 9095
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
        args    = ["-c", "echo '127.0.0.1  compose-review-service' >> /etc/hosts && echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  user-mongodb' >> /etc/hosts &&  echo '127.0.0.1  user-memcached' >> /etc/hosts && UserService"]
        ports = ["http"]
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
    service {
      name = "compose-review-service"
      port = "9095"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9095
        to     = 9095
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "cast-info-service"
              local_bind_port  = 9099
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
        args    = ["-c", "echo '127.0.0.1  cast-info-service' >> /etc/hosts && echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  compose-review-memcached' >> /etc/hosts && ComposeReviewService"]
        ports = ["http"]
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
    service {
      name = "review-storage-service"
      port = "9096"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9096
        to     = 9096
      }
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
        ports = ["http"]
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
    service {
      name = "user-review-service"
      port = "9097"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9097
        to     = 9097
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "unique-id-service"
              local_bind_port  = 9090
            }
            upstreams {
              destination_name = "compose-review-service"
              local_bind_port  = 9095
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
        args    = ["-c", "echo '127.0.0.1  unique-id-service' >> /etc/hosts  && echo '127.0.0.1  compose-review-service' >> /etc/hosts && echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  user-review-mongodb' >> /etc/hosts && echo '127.0.0.1  user-review-redis' >> /etc/hosts && UserReviewService"]
        ports = ["http"]
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
    service {
      name = "movie-review-service"
      port = "9098"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9098
        to     = 9098
      }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger"
              local_bind_port  = 6831
            }
            upstreams {
              destination_name = "review-storage-service"
              local_bind_port  = 9096
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
        args    = ["-c", "echo '127.0.0.1  review-storage-service' >> /etc/hosts && echo '127.0.0.1  jaeger' >> /etc/hosts &&  echo '127.0.0.1  movie-review-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-review-redis' >> /etc/hosts && MovieReviewService"]
        ports = ["http"]
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
    service {
      name = "cast-info-service"
      port = "9099"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9099
        to     = 9099
      }
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
        ports = ["http"]
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
    service {
      name = "plot-service"
      port = "9100"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9100
        to     = 9100
      }
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
        ports = ["http"]
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
    service {
      name = "movie-info-service"
      port = "9101"
      connect {
        sidecar_service {}
      }
    }
    network {
      mode = "bridge"
      port "http" {
        static = 9101
        to     = 9101
      }
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
        ports = ["http"]
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

  // group "jaeger" {
  //   network {
  //     mode = "bridge"
  //     port "jaeger-ui" {
  //       static = 16686
  //       to     = 16686
  //     }
  //     port "jaeger" {
  //       static = 6831
  //       to = 6831
  //     }
  //   }
  //   service {
  //     name = "jaeger"
  //     port = "6831"
  //     connect {
  //       sidecar_service {}
  //     }
  //   }
  //   service {
  //     name = "jaeger-ui"
  //     port = "16686"
  //     connect {
  //       sidecar_service {}
  //     }
  //   }
  //   service {
  //     name = "jaeger-zipkin"
  //     port = "9411"
  //     connect {
  //       sidecar_service {}
  //     }
  //   }


  //   task "jaeger" {
  //     driver = "docker"
  //     env {
  //       COLLECTOR_ZIPKIN_HTTP_PORT = "9411"
  //     }
  //     config {
  //       image = "jaegertracing/all-in-one:latest"
  //       ports = ["jaeger", "jaeger-ui"]
  //     }
  //   }
  // }

}