job "DeathStarBench" {
  datacenters = ["dc1"]

  group "social-network" {
    network {
      mode = "bridge"
      port "http" {
        static = 8080
      }
      port "jaeger-ui" {
        static = 16686
      }
    }

    task "nginx-thrift" {
      driver = "docker"

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


    task "media-frontend" {
      driver = "docker"

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



    task "user-mention-service" {
      driver = "docker"

      config {
        image   = "stvdputten/social-network-microservices:latest"
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



    // task "unique-id" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "UniqueIdService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }


    // task "text-service" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "TextService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }


    // task "media-service" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "MediaService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "media-memcached" {
    //   driver = "docker"
    //   config {
    //     image = "memcached:1.6.9"
    //   }
    //   service {
    //     name = "media-memcached"
    //     tags = ["db_mem"]
    //     port = "http"
    //   }
    // }

    // task "media-mongodb" {
    //   driver = "docker"
    //   config {
    //     image   = "mongo:4.4.6"
    //     command = "mongod"
    //     args = [
    //       "--config",
    //       "/social-network-microservices/config/mongod.conf"
    //     ]
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    //   service {
    //     name = "media-mongodb"
    //     port = "http"
    //   }
    // }



    // task "user-service" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "UserService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "user-memcached" {
    //   driver = "docker"
    //   config {
    //     image = "memcached:1.6.9"
    //   }
    //   service {
    //     name = "user-memcached"
    //     tags = ["db_mem"]
    //     port = "http"
    //   }
    // }

    // task "user-mongodb" {
    //   driver = "docker"
    //   config {
    //     image   = "mongo:4.4.6"
    //     command = "mongod"
    //     args = [
    //       "--config",
    //       "/social-network-microservices/config/mongod.conf"
    //     ]
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }


    // task "url-shorten-service" {
    //   driver = "docker"
    //   env {
    //     JAEGER_AGENT_URL = "http://${NOMAD_UPSTREAM_ADDR_jaeger_agent}"
    //   }

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "UrlShortenService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "url-shorten-mongodb" {
    //   driver = "docker"
    //   config {
    //     image   = "mongo:4.4.6"
    //     command = "mongod"
    //     args = [
    //       "--config",
    //       "/social-network-microservices/config/mongod.conf"
    //     ]

    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "url-shorten-memcached" {
    //   driver = "docker"
    //   config {
    //     image = "memcached:1.6.9"
    //   }

    // }


    // task "user-timeline-service" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "UserTimelineService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "user-timeline-mongodb" {
    //   driver = "docker"

    //   config {
    //     image   = "mongo:4.4.6"
    //     command = "mongod"
    //     args = [
    //       "--config",
    //       "/social-network-microservices/config/mongod.conf"
    //     ]
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "user-timeline-redis" {
    //   driver = "docker"
    //   config {
    //     image = "redis:alpine3.13"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //     command = "redis-server"
    //     args = [
    //       "/social-network-microservices/config/redis.conf"
    //     ]
    //   }


    // }

    // task "post-storage-service" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "PostStorageService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "post-storage-memcached" {
    //   driver = "docker"

    //   config {
    //     image = "memcached:1.6.9"
    //   }
    // }

    // task "post-storage-mongodb" {
    //   driver = "docker"

    //   config {
    //     image   = "mongo:4.4.6"
    //     command = "mongod"
    //     args = [
    //       "--config",
    //       "/social-network-microservices/config/mongod.conf"
    //     ]
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "compose-post-service" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "ComposePostService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }



    // task "home-timeline-service" {
    //   driver = "docker"
    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "SocialGraphService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }


    // }

    // task "home-timeline-mongodb" {
    //   driver = "docker"
    //   config {
    //     image   = "mongo:4.4.6"
    //     command = "mongod"
    //     args = [
    //       "--config",
    //       "/social-network-microservices/config/mongod.conf"
    //     ]
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }

    // }

    // task "home-timeline-redis" {
    //   driver = "docker"
    //   config {
    //     image = "redis:alpine3.13"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //     command = "redis-server"
    //     args = [
    //       "/social-network-microservices/config/redis.conf"
    //     ]
    //   }

    // }

    // task "social-graph-service" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/social-network-microservices:latest"
    //     command = "SocialGraphService"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }
    // }

    // task "social-graph-mongodb" {
    //   driver = "docker"
    //   config {
    //     image   = "mongo:4.4.6"
    //     command = "mongod"
    //     args = [
    //       "--config",
    //       "/social-network-microservices/config/mongod.conf"
    //     ]
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //   }

    // }

    // task "social-graph-redis" {
    //   driver = "docker"
    //   config {
    //     image = "redis:alpine3.13"
    //     mount {
    //       type   = "bind"
    //       target = "/keys"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
    //     }
    //     mount {
    //       type   = "bind"
    //       target = "/social-network-microservices/config"
    //       source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
    //     }
    //     command = "redis-server"
    //     args = [
    //       "/social-network-microservices/config/redis.conf"
    //     ]
    //   }

    // }


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