job "deathstarbench12" {
  datacenters = ["dc1"]
  // constraint {
  //   operator = "distinct_hosts"
  //   value = "true"
  // }

  group "nginx+jaeger" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "node3.stvdp-109588.sched-serv-pg0.utah.cloudlab.us"
    }

    network {
      mode = "bridge"
      port "http" {
        static = 8080
      }
      port "jaeger-ui" {
        static = 16686
      }
      port "jaeger" {
        static = 6831
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    // service {
    //   name = "nginx-upstreams"

    //   connect {
    //     sidecar_service {
    //       proxy {
    //         upstreams {
    //           destination_name = "media-frontend"
    //           local_bind_port  = 8081
    //         }
    //         // upstreams {
    //         //   destination_name = "user-service"
    //         //   local_bind_port  = 9090
    //         // }
    //         // upstreams {
    //         //   destination_name = "social-graph-service"
    //         //   local_bind_port  = 9091
    //         // }
    //         // upstreams {
    //         //   destination_name = "media-service"
    //         //   local_bind_port  = 9092
    //         // }
    //         // upstreams {
    //         //   destination_name = "user-timeline-service"
    //         //   local_bind_port  = 9093
    //         // }
    //         upstreams {
    //           destination_name = "compose-post-service"
    //           local_bind_port  = 9094
    //         }
    //         // upstreams {
    //         //   destination_name = "home-timeline-service"
    //         //   local_bind_port  = 9095
    //         // }
    //         upstreams {
    //           destination_name = "user-mention-service"
    //           local_bind_port  = 9096
    //         }
    //         // upstreams {
    //         //   destination_name = "post-storage-service"
    //         //   local_bind_port  = 9097
    //         // }
    //         upstreams {
    //           destination_name = "text-service"
    //           local_bind_port  = 9098
    //         }
    //         upstreams {
    //           destination_name = "unique-id-service"
    //           local_bind_port  = 9099
    //         }
    //         // upstreams {
    //         //   destination_name = "url-shorten-service"
    //         //   local_bind_port  = 9100
    //         // }
    //       }
    //     }
    //   }
    // }

    task "nginx-thrift" {
      driver = "docker"
      resources {
        cpu    = 100 * 4
        memory = 256 * 4
      }

      service {
        name = "nginx-thrift"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image   = "stvdputten/openresty-thrift:latest"
        ports   = ["http"]
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger' >> /etc/hosts && /usr/local/openresty/bin/openresty -g 'daemon off;'"]

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


    task "jaeger" {
      driver = "docker"

      service {
        name = "jaeger"
      }

      config {
        image = "jaegertracing/all-in-one:1.23.0"
      }
    }
  }

  group "social-graph" {
    network {
      mode = "bridge"
      port "http" {
        static = 9091
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    task "social-graph-service" {
      driver = "docker"

      service {
        name = "social-graph-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image = "stvdputten/social-network-microservices:nomad"
        // command = "SocialGraphService"
        command = "sh"
        // args    = ["-c", "echo '128.110.217.82 user-service.service.consul' >> /etc/hosts && echo '127.0.0.1 social-graph' >> /etc/hosts && echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && SocialGraphService"]
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && SocialGraphService"]
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
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
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
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        // }
        command = "redis-server"
        args = [
          "--port",
          "6382"
        ]
      }
    }

  }

  group "post-storage" {
    network {
      mode = "bridge"
      port "http" {
        static = 9097
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }
    task "post-storage-service" {
      driver = "docker"

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        // command = "PostStorageService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && PostStorageService"]
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
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        // }
      }
    }
  }

  group "home-timeline" {
    network {
      mode = "bridge"
      port "http" {
        static = 9095
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    task "home-timeline-service" {
      driver = "docker"

      service {
        name = "home-timeline-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        // command = "HomeTimelineService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && HomeTimelineService"]
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
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        // }
        command = "redis-server"
        args = [
          "--port",
          "6379"
        ]
      }
    }
  }


  group "user-timeline" {
    network {
      mode = "bridge"
      port "http" {
        static = 9093
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    task "user-timeline-service" {
      driver = "docker"

      service {
        name = "user-timeline-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UserTimelineService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && UserTimelineService"]
        mount {
          type   = "bind"
          target = "/keys"
          source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
        }
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        // }
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
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        // }
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
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        // }
      }
    }

  }

  group "url-shorten" {
    network {
      mode = "bridge"
      port "http" {
        static = 9100
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    task "url-shorten-service" {
      driver = "docker"

      service {
        name = "url-shorten-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UrlShortenService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && UrlShortenService"]
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

  }

  group "user" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "node4.stvdp-109588.sched-serv-pg0.utah.cloudlab.us"
    }

    network {
      mode = "bridge"
      port "http" {
        static = 9090
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    task "user-service" {
      driver = "docker"

      service {
        name = "user-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UserService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && UserService"]

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
  }

  group "media" {
    network {
      mode = "bridge"
      port "http" {
        static = 9092
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    // service {
    //   name = "media-service"
    //   port = 9094
    //   connect {
    //     sidecar_service {}
    //   }
    // }

    task "media-service" {
      driver = "docker"

      service {
        name = "media-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image = "stvdputten/social-network-microservices:nomad"
        // command = "MediaService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && MediaService"]
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
        // mount {
        //   type   = "bind"
        //   target = "/social-network-microservices/config"
        //   source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
        // }
      }
    }
  }

  group "compose-post" {
    network {
      mode = "bridge"
      port "http" {
        static = 9094
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    // service {
    //   name = "compose-post-service"
    //   port = 9094
    //   connect {
    //     sidecar_service {}
    //   }
    // }

    task "compose-post-service" {
      driver = "docker"

      service {
        name = "compose-post-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "ComposePostService"
        // dns_servers = ["128.110.217.84", "128.110.156.4"]
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && ComposePostService"]
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

  group "text-service" {
    network {
      mode = "bridge"
      port "http" {
        static = 9098
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    // service {
    //   name = "text-service"
    //   port = 9098
    //   connect {
    //     sidecar_service {}
    //   }
    // }

    task "text-service" {
      driver = "docker"

      service {
        name = "text-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image = "stvdputten/social-network-microservices:nomad"
        // command = "TextService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && TextService"]
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

  group "user-mention" {
    network {
      mode = "bridge"
      port "http" {
        static = 9096
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    // service {
    //   name = "user-mention-service"
    //   port = 9096
    //   connect {
    //     sidecar_service {}
    //   }
    // }

    task "user-mention-service" {
      driver = "docker"

      service {
        name = "user-mention-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
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


  group "unique-id-service" {
    network {
      mode = "bridge"
      port "http" {
        static = 9099
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }

    // service {
    //   name = "unique-id-service"
    //   port = "9099"
    //   connect {
    //     sidecar_service {}
    //   }
    // }

    task "unique-id-service" {
      driver = "docker"

      service {
        name = "unique-id-service"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UniqueIdService"
        command = "sh"
        args    = ["-c", "echo '128.110.217.76  jaeger.service.consul' >> /etc/hosts && UniqueIdService"]
        ports   = ["http"]
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

  group "media-frontend" {
    network {
      mode = "bridge"
      port "media" {
        static = 8081
        to     = 8080
      }
      dns {    
        servers = ["8.8.8.8", "128.110.217.84"]  
      }
    }
    // service {
    //   name = "media-frontend"
    //   port = "8080"
    //   connect {
    //     sidecar_service {}
    //   }
    // }

    task "media-frontend" {
      driver = "docker"
      resources {
        cpu    = 100 * 4
        memory = 256 * 4
      }

      service {
        name = "media-frontend-service"
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