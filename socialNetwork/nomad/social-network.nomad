job "social-network" {
  datacenters = ["dc1"]

  group "nginx-thrift" {
    network {
      mode = "bridge"
      // dns {    
      //   servers = ["172.17.0.1"]  
      // }
      port "http" {
        static = 8080
        to     = 8080
      }
    }

    service {
      name = "nginx-thrift-jaeger-agent"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger-agent"
              local_bind_port  = 6831
            }
            upstreams {
                    destination_name = "jaeger-agent-ui"
                    local_bind_port =  16686
            }
            upstreams {
              destination_name = "user-service"
              local_bind_port  = 9090
            }
            upstreams {
              destination_name = "social-graph-service"
              local_bind_port  = 9091
            }
            upstreams {
              destination_name = "media-service"
              local_bind_port  = 9092
            }
            upstreams {
              destination_name = "user-timeline-service"
              local_bind_port  = 9093
            }
            upstreams {
              destination_name = "compose-post-service"
              local_bind_port  = 9094
            }
            upstreams {
              destination_name = "home-timeline-service"
              local_bind_port  = 9095
            }
            upstreams {
              destination_name = "user-mention-service"
              local_bind_port  = 9096
            }
            upstreams {
              destination_name = "post-storage-service"
              local_bind_port  = 9097
            }
            upstreams {
              destination_name = "text-service"
              local_bind_port  = 9098
            }
            upstreams {
              destination_name = "unique-id-service"
              local_bind_port  = 9099
            }
            upstreams {
              destination_name = "url-shorten-service"
              local_bind_port  = 9100
            }
          }
        }
      }
    }

    task "nginx-thrift" {
      driver = "docker"

      config {
        image        = "stvdputten/openresty-thrift:latest"
        ports = ["http"]
        // privileged = true

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
          source = "/users/stvdp/DeathStarBench/socialNetwork/gen-lua"
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
  }

    group "media-frontend" {
      count = 1
      network {
        mode = "bridge"
        port "http" {
          static = 8080
          to     = 8080
        }
      }

      service {
        name = "media-frontend-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
              upstreams {
                destination_name = "jaeger-agent-ui"
                local_bind_port  = 16686
              }
            }
          }
        }
      }

      task "media-frontend" {
        driver       = "docker"

        config {
          image = "yg397/media-frontend:xenial"
          ports = ["http"]
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

    group "user-mention" {
      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "user-mention-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "user-mention-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
            }
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
    }


    group "unique-id" {
      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "unique-id-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "unique-id-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
              upstreams {
                destination_name = "jaeger-agent-ui"
                local_bind_port  = 16686
              }
            }
          }
        }
      }

      task "unique-id" {
        driver = "docker"

        config {
          image   = "stvdputten/social-network-microservices:nomad"
          command = "UniqueIdService"
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
    }

    group "text" {
      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "text-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "text-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
            }
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
    }

    group "media" {
      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "media-service"
        port = "9090"
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "media-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
            }
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
          image = "memcached:1.6.9"
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
          image   = "mongo:4.4.6"
          command = "mongod"
          args = [
            "--config",
            "/social-network-microservices/config/mongod.conf"
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
    }

    group "user" {
      network {
        mode = "bridge"
        port "http" {
          // static = 9090
        }
      }

      service {
        name = "user-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "user-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
            }
          }
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
          image = "memcached:1.6.9"
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
            "--config",
            "/social-network-microservices/config/mongod.conf"
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
          name = "user-mongodb"
          port = "http"
        }
      }
    }

  group "url-shorten" {
    network {
      mode = "bridge"
      port "http" {}
    }

    service {
      name = "url-shorten-service"
      port = 9090
      connect {
        sidecar_service {}
      }
    }

    service {
      name = "us-jaeger-agent"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger-agent"
              local_bind_port  = 6831
            }
          }
        }
      }
    }

    task "url-shorten-service" {
      driver = "docker"
      env { 
        JAEGER_AGENT_URL = "http://${NOMAD_UPSTREAM_ADDR_jaeger_agent}" 
      }

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
          "--config",
          "/social-network-microservices/config/mongod.conf"
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
        name = "url-shorten-mongodb"
        port = "http"
      }
    }

    task "url-shorten-memcached" {
      driver = "docker"
      config {
        image = "memcached:1.6.9"
      }

      service {
        name = "url-shorten-memcached"
        tags = ["db_r"]
        port = "http"
      }
    }
  }

    group "user-timeline" {
      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "user-timeline-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "ut-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
              // upstreams {
              //   destination_name = "jaeger-agent-ui"
              //   local_bind_port  = 16686
              // }
            }
          }
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
            "--config",
            "/social-network-microservices/config/mongod.conf"
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
          name = "user-timeline-mongodb"
          port = "http"
        }
      }

      task "user-timeline-redis" {
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
            "/social-network-microservices/config/redis.conf"
          ]
        }

        service {
          name = "user-timeline-redis"
          tags = ["db_r"]
          port = "http"
        }
      }
    }

    group "post-storage" {
      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "post-storage-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "ps-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
            }
          }
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
          image = "memcached:1.6.9"
        }
        service {
          name = "post-storage-memcached"
          port = "http"
        }
      }

      task "post-storage-mongodb" {
        driver = "docker"

        config {
          image   = "mongo:4.4.6"
          command = "mongod"
          args = [
            "--config",
            "/social-network-microservices/config/mongod.conf"
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
          name = "post-storage-mongodb"
          port = "http"
        }
      }
    }

    group "compose-post" {

      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "compose-post-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "cp-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
            }
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

    }


    group "home-timeline" {
      network {
        mode = "bridge"

        port "http" {}
      }

      service {
        name = "home-timeline-service"
        port = 9090
        connect {
          sidecar_service {}
        }
      }

      service {
        name = "ht-jaeger-agent"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
            }
          }
        }
      }

      task "home-timeline-service" {
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

      task "home-timeline-mongodb" {
        driver = "docker"
        config {
          image   = "mongo:4.4.6"
          command = "mongod"
          args = [
            "--config",
            "/social-network-microservices/config/mongod.conf"
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
          name = "home-timeline-mongodb"
          tags = ["db_m"]
          port = "http"
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
            "/social-network-microservices/config/redis.conf"
          ]
        }

        service {
          name = "home-timeline-redis"
          tags = ["db_r"]
          port = "http"
        }
      }

    }


    group "social-graph" {

      network {
        mode = "bridge"
        port "http" {}
      }

      service {
        name = "social-graph-service"
        port = 9090

        connect {
          sidecar_service {}
        }
      }

      service {
        name = "sg-jaeger-agent"
        //  port the api service listens on
        // port = "6831"

        connect {
          sidecar_service {
            proxy {
              upstreams {
                destination_name = "jaeger-agent"
                local_bind_port  = 6831
              }
              // upstreams {
              //         destination_name = "jaeger-agent-ui"
              //         local_bind_port =  16686
              // }
            }
          }
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
            "--config",
            "/social-network-microservices/config/mongod.conf"
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
          name = "social-graph-mongodb"
          tags = ["db_m"]
          port = "http"
          // check {
          // 	type = "tcp"
          // 	interval = "10s"
          // 	timeout = "4s"
          // }
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
            "/social-network-microservices/config/redis.conf"
          ]
        }

        service {
          name = "social-graph-redis"
          tags = ["db_r"]
          port = "http"

          // check {
          // 	type = "tcp"
          // 	interval = "10s"
          // 	timeout = "4s"
          // }
        }
      }

    }

  group "jaeger" {
    network {
      mode = "bridge"

      port "http" {
        static = 16686
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
      name = "jaeger-agent-ui"
      port = "16686"
      connect {
        sidecar_service {}
      }
    }


    task "jaeger" {
      driver = "docker"
      config {
        image = "jaegertracing/all-in-one:1.23.0"
      }
      service {
        name = "jaeger-agent"
        port = "http"
      }
      env {
        COLLECTOR_ZIPKIN_HTTP_PORT = "9411"
      }
    }
  }
}