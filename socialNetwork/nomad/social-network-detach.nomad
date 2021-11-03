job "deathstarbench" {
  datacenters = ["dc1"]
  constraint {
    operator = "distinct_hosts"
    value    = "true"
  }

  group "social-network" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value    = "node3.stvdp-109579.sched-serv-pg0.utah.cloudlab.us"
    }
    network {
      mode = "bridge"
      port "http" {
        static = 8080
      }
      port "jaeger-ui" {
        static = 16686
      }
      port "jaeger-agent" {
        static = 6831
      }
    }

    service {
      name = "jaeger-agent"
      port = "6831"
      connect {
        sidecar_service {}
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
              destination_name = "media-frontend"
              local_bind_port  = 8081
            }
            upstreams {
              destination_name = "unique-id-service"
              local_bind_port  = 9099
            }
          }
        }
      }
    }

    task "nginx-thrift" {
      driver = "docker"
      resources {
        cpu    = 100 * 4
        memory = 256 * 4
      }

      config {
        image = "stvdputten/openresty-thrift:latest"
        ports = ["http"]

        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/lua-scripts"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/nginx-web-server/lua-scripts-nomad"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/pages"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/nginx-web-server/pages"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/conf/nginx.conf"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/nginx-web-server/conf/nginx.conf"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/jaeger-config.json"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/nginx-web-server/jaeger-config.json"
        }
        mount {
          type   = "bind"
          target = "/gen-lua"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/nginx-web-server/gen-lua"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/lualib/thrift"
          source = "/users/stvdp/DeathStarBench/socialNetwork/docker/openresty-thrift/lua-thrift"
        }
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }

      }
    }



    task "user-mention-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "UserMentionService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }


    task "text-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "TextService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "compose-post-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "ComposePostService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "media-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "MediaService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "media-memcached" {
      driver = "docker"
      config {
        image   = "stvdputten/memcached"
        command = "memcached"
      }
      service {
        name = "media-memcached"
        tags = ["db_mem"]
        port = "http"
      }
    }

    task "media-mongodb" {
      driver = "docker"
      config {
        image   = "stvdputten/mongo"
        command = "mongod"
        args = [
          "--port",
          "27017"
        ]
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
      service {
        name = "media-mongodb"
        port = "http"
      }
    }



    task "user-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "UserService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "user-memcached" {
      driver = "docker"
      config {
        image   = "stvdputten/memcached"
        command = "memcached"
        args = [
          "-p",
          "11212"
        ]

      }
      service {
        name = "user-memcached"
        tags = ["db_mem"]
        port = "http"
      }
    }

    task "user-mongodb" {
      driver = "docker"
      config {
        image   = "mongo:4.4.6"
        command = "mongod"
        args = [
          "--port",
          "27018"
        ]
      }
    }


    task "url-shorten-service" {
      driver = "docker"
      // env {
      //   JAEGER_AGENT_URL = "http://${NOMAD_UPSTREAM_ADDR_jaeger_agent}"
      // }

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "UrlShortenService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "url-shorten-mongodb" {
      driver = "docker"
      config {
        image   = "mongo:4.4.6"
        command = "mongod"
        args = [
          "--port",
          "27022"
        ]

      }
    }

    task "url-shorten-memcached" {
      driver = "docker"
      config {
        image   = "stvdputten/memcached"
        command = "memcached"
        args = [
          "-p",
          "11213"
        ]
      }

    }


    task "user-timeline-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "UserTimelineService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "user-timeline-mongodb" {
      driver = "docker"

      config {
        image   = "mongo:4.4.6"
        command = "mongod"
        args = [
          "--port",
          "27019"
        ]
      }
    }

    task "user-timeline-redis" {
      driver = "docker"
      config {
        image   = "redis:alpine3.13"
        command = "redis-server"
        args = [
          "--port",
          "6381"
        ]
      }
    }

    task "post-storage-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "PostStorageService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "post-storage-memcached" {
      driver = "docker"

      config {
        image   = "memcached:1.6.9"
        command = "memcached"
        args = [
          "-p",
          "11214"
        ]
      }
    }

    task "post-storage-mongodb" {
      driver = "docker"

      config {
        image   = "mongo:4.4.6"
        command = "mongod"
        args = [
          "--port",
          "27021"
        ]
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "home-timeline-service" {
      driver = "docker"
      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "HomeTimelineService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "home-timeline-redis" {
      driver = "docker"
      config {
        image = "redis:alpine3.13"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
        command = "redis-server"
        args = [
          "--port",
          "6379"
        ]
      }

    }

    task "social-graph-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:nomad"
        command = "SocialGraphService"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }
    }

    task "social-graph-mongodb" {
      driver = "docker"
      config {
        image   = "mongo:4.4.6"
        command = "mongod"
        args = [
          "--port",
          "27020"
        ]
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
      }

    }

    task "social-graph-redis" {
      driver = "docker"
      config {
        image = "redis:alpine3.13"
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        mount {
          type   = "bind"
          target = "/social-network-microservices/config"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        }
        command = "redis-server"
        args = [
          "--port",
          "6382"
        ]
      }
    }

    task "jaeger" {
      driver = "docker"
      config {
        image = "jaegertracing/all-in-one:1.23.0"
      }
      env {
        COLLECTOR_ZIPKIN_HTTP_PORT = "9411"
      }
    }
  }

  group "unique-id-service" {
    network {
      mode = "bridge"
    }
    // service {
    //   connect {
    //     sidecar_service {
    //       proxy {
    //         upstreams {
    //           destination_name = "jaeger-agent"
    //           local_bind_port  = 6831
    //         }
    //       }
    //     }
    //   }
    // }

    service {
      name = "unique-id-service"
      port = "9099"
      connect {
        sidecar_service {}
      }
    }

    task "unique-id" {
      driver = "docker"

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UniqueIdService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76  jaeger' >> /etc/hosts && UniqueIdService"]
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
      }
    }
  }

  group "media-frontend" {
    network {
      mode = "bridge"
      port "media" {
        static = 8081
        to     = 8080
      }
    }
    service {
      name = "media-frontend"
      port = "8080"
      connect {
        sidecar_service {}
      }
    }

    task "media-frontend" {
      driver = "docker"
      resources {
        cpu    = 100 * 4
        memory = 256 * 4
      }

      config {
        image = "yg397/media-frontend:xenial"
        ports = ["media"]
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/lua-scripts"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/media-frontend/lua-scripts-nomad"
        }
        mount {
          type   = "bind"
          target = "/usr/local/openresty/nginx/conf/nginx.conf"
          source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/media-frontend/conf/nginx.conf"
        }
      }
    }
  }
}