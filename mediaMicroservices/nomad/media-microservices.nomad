variable "home_dir" {
  type    = string
  default = "/users/stvdp"
}

job "media-microservices" {
  datacenters = ["dc1"]
  constraint {
    operator = "distinct_hosts"
    value    = "true"
  }

  group "consul" {
    count = 1
    service {
      name = "consul-dns"
      port = "8600"

      connect {
        sidecar_service {}
      }
    }
    service {
      name = "consul-ui"
      port = "8500"

      connect {
        sidecar_service {}
      }
    }

    network {
      mode = "bridge"
      port "dns-ui" {
        static = 4000
        to     = 8500
      }
    }

    task "consul" {
      driver = "docker"
      env {
        CONSUL_ALLOW_PRILEGED_PORTS = ""
      }
      config {
        image = "consul:1.9.6"
        ports = ["dns-ui", "dns"]
        // "-bind",
          // "0.0.0.0",
          // "-dns-port",
          // "53",
          // "-recursor",
          // "8.8.8.8"
        command = "consul"
        args = [
          "agent",
          "-dev",
          "-data-dir=/consul/data",
          "-client",
          "{{ GetInterfaceIP \"eth0\"}}",
        ]
      }
    }

    task "movie-id-mongodb" {
      //       template {
      //         destination = "local/resolv.conf"
      //         data        = <<EOF
      // nameserver 127.0.0.1
      // nameserver 128.110.156.4
      // search service.consul
      // EOF
      //       }
      driver = "docker"
      config {
        image = "stvdputten/mongo"
        // volumes = [
        //     "local/resolv.conf:/etc/resolv.conf"
        // ]
      }
    }
  }

  // group "id-service" {
  //   network {
  //     mode = "bridge"
  //   }
  //   task "unique-id-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "UniqueIdService"
  //     }
  //   }
  // }

  group "movie-id-service" {
    network {
      mode = "bridge"
      // dns { 
      //   servers = ["127.0.0.1"] 
      // }
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "consul-dns"
              local_bind_port  = 8600
            }
            upstreams {
              destination_name = "consul-ui"
              local_bind_port  = 8500
            }
          }
        }
      }
    }

    // task "movie-id-service" {
    //   driver = "docker"
    //   config {
    //     image   = "stvdputten/media-microservices:latest"
    //     command = "MovieIdService"
    //   }
    // }

    task "movie-id-mongodb" {
      //       template {
      //         destination = "local/resolv.conf"
      //         data        = <<EOF
      // nameserver 127.0.0.1
      // nameserver 128.110.156.4
      // search service.consul
      // EOF
      //       }
      driver = "docker"
      config {
        image = "stvdputten/mongo"

        // volumes = [
        //     "local/resolv.conf:/etc/resolv.conf"
        // ]
        // dns_servers = ["0.0.0.0", "127.0.0.1"]
      }
    }

    task "movie-id-memcached" {
      driver = "docker"
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  // group "text-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "text-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "TextService"
  //     }
  //   }
  // }

  // group "rating-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "rating-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "RatingService"
  //     }
  //   }

  //   task "rating-redis" {
  //     driver = "docker"
  //     config {
  //       image = "redis:alpine3.13"
  //     }
  //   }
  // }

  // group "user-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "user-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "UserService"
  //     }
  //   }

  //   task "user-mongodb" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/mongo"
  //     }
  //   }

  //   task "user-memcached" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/memcached"
  //     }
  //   }
  // }

  // group "compose-review-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "compose-review-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "ComposeReviewService"
  //     }
  //   }

  //   task "compose-review-memcached" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/memcached"
  //     }
  //   }
  // }

  // group "review-storage-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "review-storage-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "ReviewStorageService"
  //     }
  //   }

  //   task "review-storage-mongodb" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/mongo"
  //     }
  //   }

  //   task "review-storage-memcached" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/memcached"
  //     }
  //   }
  // }

  // group "user-review-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "user-review-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "UserReviewService"
  //     }
  //   }

  //   task "user-review-mongodb" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/mongo"
  //     }
  //   }

  //   task "user-review-redis" {
  //     driver = "docker"
  //     config {
  //       image = "redis:alpine3.13"
  //     }
  //   }
  // }

  // group "movie-review-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "movie-review-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "MovieReviewService"
  //     }
  //   }

  //   task "movie-review-mongodb" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/mongo"
  //     }
  //   }

  //   task "movie-review-redis" {
  //     driver = "docker"
  //     config {
  //       image = "redis:alpine3.13"
  //     }
  //   }
  // }

  // group "nginx-web-server" {
  //   network {
  //     mode = "bridge"
  //     port "nginx" {
  //       static = 8080
  //       to     = 8080
  //     }
  //   }

  //   task "nginx-web-server" {
  //     driver = "docker"
  //     config {
  //       image = "yg397/openresty-thrift:xenial"
  //       ports = ["nginx"]
  //       mount {
  //         type   = "bind"
  //         target = "/usr/local/openresty/nginx/configsmaps/lua-scripts"
  //         source = "/users/stvdp/DeathStarBench/mediaMicroservice/configsmaps/lua-scripts"
  //       }
  //       mount {
  //         type   = "bind"
  //         target = "/usr/local/openresty/nginx/conf/nginx.conf"
  //         source = "/users/stvdp/DeathStarBench/mediaMicroservice/configmaps/nginx.conf"
  //       }
  //       mount {
  //         type   = "bind"
  //         target = "/usr/local/openresty/nginx/jaeger-config.json"
  //         source = "/users/stvdp/DeathStarBench/mediaMicroservice/nomad/configmaps/jaeger-config.json"
  //       }
  //       mount {
  //         type   = "bind"
  //         target = "/gen-lua"
  //         source = "/users/stvdp/DeathStarBench/mediaMicroservice/nomad/configmaps/gen-lua"
  //       }
  //     }

  //   }

  // }

  // group "cast-info-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "cast-info-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "CastInfoService"
  //     }
  //   }

  //   task "cast-info-mongodb" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/mongo"
  //     }
  //   }

  //   task "cast-info-memcached" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/memcached"
  //     }
  //   }
  // }

  // group "plot-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "plot-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "PlotService"
  //     }
  //   }

  //   task "plot-mongodb" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/mongo"
  //     }
  //   }

  //   task "plot-memcached" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/memcached"
  //     }
  //   }
  // }

  // group "movie-info-service" {
  //   network {
  //     mode = "bridge"
  //   }

  //   task "movie-info-service" {
  //     driver = "docker"
  //     config {
  //       image   = "stvdputten/media-microservices:latest"
  //       command = "MovieInfoService"
  //     }
  //   }

  //   task "movie-info-mongodb" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/mongo"
  //     }
  //   }

  //   task "movie-info-memcached" {
  //     driver = "docker"
  //     config {
  //       image = "stvdputten/memcached"
  //     }
  //   }
  // }

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
