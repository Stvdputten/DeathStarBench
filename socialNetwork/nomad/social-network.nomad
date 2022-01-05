variable "hostname" {
  type    = string
  default = "node3.stvdp-109953.sched-serv-pg0.utah.cloudlab.us"
}

variable "jaeger" {
  type    = string
  default = "128.110.217.144"
}

variable "dns" {
  type    = string
  default = "128.110.217.140"
}

job "social-network" {
  datacenters = ["dc1"]
  // constraint {
  //   operator = "distinct_hosts"
  //   value = "true"
  // }

  group "nginx+jaeger" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "${var.hostname}"
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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "nginx-thrift" {
      driver = "docker"

      service {
        name = "nginx-thrift"
      }

      config {
        // dns_servers = ["128.110.217.84", "8.8.8.8"]
        image   = "stvdputten/openresty-thrift:latest"
        ports   = ["http"]
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  jaeger.service.consul' >> /etc/hosts && echo '127.0.0.1  jaeger' >> /etc/hosts && /usr/local/openresty/bin/openresty -g 'daemon off;'"]

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
      resources {
        cores = 4
        memory = 2000
      }

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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "social-graph-service" {
      driver = "docker"

      service {
        name = "social-graph-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "SocialGraphService"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 social-graph-mongodb' >> /etc/hosts && echo '127.0.0.1 social-graph-redis' >> /etc/hosts && SocialGraphService"]
        // args = ["-c", "echo '128.110.217.76 jaeger.service.consul' >> /etc/hosts && SocialGraphService"]
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
        image   = "stvdputten/mongo"
        command = "mongod"
        args = [
          "--port",
          "27020"
        ]
      }
    }

    task "social-graph-redis" {
      driver = "docker"
      config {
        image   = "redis:alpine3.13"
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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "post-storage-service" {
      driver = "docker"

      service {
        name = "post-storage-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "PostStorageService"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 post-storage-mongodb' >> /etc/hosts && echo '127.0.0.1 post-storage-memcached' >> /etc/hosts && PostStorageService"]
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
        image   = "stvdputten/memcached"
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
        image   = "stvdputten/mongo"
        command = "mongod"
        args = [
          "--port",
          "27021"
        ]
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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "home-timeline-service" {
      driver = "docker"

      service {
        name = "home-timeline-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "HomeTimelineService"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 home-timeline-redis' >> /etc/hosts && HomeTimelineService"]
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
        image   = "redis:alpine3.13"
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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "user-timeline-service" {
      driver = "docker"

      service {
        name = "user-timeline-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UserTimelineService"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 user-timeline-redis' >> /etc/hosts && echo '127.0.0.1 user-timeline-mongodb' >> /etc/hosts && UserTimelineService"]
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
        image   = "stvdputten/mongo"
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
  }

  group "url-shorten" {
    network {
      mode = "bridge"
      port "http" {
        static = 9100
      }
      dns {
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "url-shorten-service" {
      driver = "docker"

      service {
        name = "url-shorten-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UrlShortenService"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 url-shorten-memcached' >> /etc/hosts && echo '127.0.0.1 url-shorten-mongodb' >> /etc/hosts && UrlShortenService"]
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
        image   = "stvdputten/mongo"
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
    // constraint {
    //   attribute = "${attr.unique.hostname}"
    //   value     = "node4.stvdp-109588.sched-serv-pg0.utah.cloudlab.us"
    // }

    network {
      mode = "bridge"
      port "http" {
        static = 9090
      }
      dns {
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "user-service" {
      driver = "docker"

      service {
        name = "user-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "UserService"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 user-mongodb' >> /etc/hosts && echo '127.0.0.1 user-memcached' >> /etc/hosts && UserService"]
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
        image   = "stvdputten/mongo"
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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "media-service" {
      driver = "docker"

      service {
        name = "media-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        // command = "MediaService"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 media-mongodb' >> /etc/hosts && echo '127.0.0.1 media-memcached' >> /etc/hosts && MediaService"]
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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "compose-post-service" {
      driver = "docker"

      service {
        name = "compose-post-service"
      }

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

  group "text-service" {
    network {
      mode = "bridge"
      port "http" {
        static = 9098
      }
      dns {
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "text-service" {
      driver = "docker"

      service {
        name = "text-service"
      }

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

  group "user-mention" {
    network {
      mode = "bridge"
      port "http" {
        static = 9096
      }
      dns {
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "user-mention-service" {
      driver = "docker"

      service {
        name = "user-mention-service"
      }

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


  group "unique-id-service" {
    network {
      mode = "bridge"
      port "http" {
        static = 9099
      }
      dns {
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "unique-id-service" {
      driver = "docker"

      service {
        name = "unique-id-service"
      }

      config {
        image = "stvdputten/social-network-microservices:nomad"
        command = "UniqueIdService"
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
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "media-frontend" {
      driver = "docker"

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