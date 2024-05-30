variable "hostname" {
  type    = string
  default = "node3.stvdp-109788.sched-serv-pg0.utah.cloudlab.us"
}

variable "jaeger" {
  type    = string
  default = "128.110.217.69"
}

variable "dns" {
  type    = string
  default = "128.110.217.60"
}

job "media-microservices" {
  datacenters = ["dc1"]

  group "ingress" {
    network {
      mode = "bridge"
      port "inbound" {
        static = 8080
        to = 8080
      }
    }
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "${var.hostname}"
    }

    service {
      name = "my-ingress"
      port = 8080

      connect {
        gateway {
          proxy {}

          ingress {

            listener {
              port     = 8080
              protocol = "tcp"
              service {
                name = "uuid-api"
              }
            }
          }
        }
      }
    }
  }


  group "nginx-web-server" {
    count = 2

    service {      
      name = "uuid-api"      
      port = "api"
      connect {        
        sidecar_service {}
      }    
    }

    network {
      mode = "bridge"
      port "api" {
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

    task "nginx-web-server" {
      driver = "docker"

      resources {
        cpu = 4000
        memory_max = 4000
      }

      config {
        memory_hard_limit = 4000
        cpu_hard_limit = true

        image   = "yg397/openresty-thrift:xenial"
        ports   = ["nginx"]
        command = "sh"
        args    = ["-c", "echo '127.0.0.1 jaeger.service.consul' >> /etc/hosts && echo '127.0.0.1 jaeger' >> /etc/hosts && /usr/local/openresty/bin/openresty -g 'daemon off;'"]
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


    task "jaeger" {
      resources {
        cpu = 4000
        memory = 16000 
      }
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      service {
        name = "jaeger"
      }
      driver = "docker"
      config {
        // memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "jaegertracing/all-in-one:latest"
        ports = ["jaeger", "jaeger-ui"]
      }
    }
  }


  group "unique-id-service" {
    count = 2
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

    task "unique-id-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      service {
        name = "unique-id-service"

      }
      driver = "docker"
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/media-microservices:nomad"
        command = "UniqueIdService"
        ports   = ["http"]
      }
    }
  }

  group "movie-id-service" {
    count = 2
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

    task "movie-id-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      service {
        name = "movie-id-service"

      }
      driver = "docker"
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args  = ["-c", "echo '127.0.0.1  movie-id-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-id-memcached' >> /etc/hosts && MovieIdService"]
        ports = ["http"]
      }
    }

    task "movie-id-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "movie-id-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "movie-id-memcached" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "movie-id-memcached"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/memcached"
      }
    }
  }

  group "text-service" {
    count = 2
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

    task "text-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "text-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/media-microservices:nomad"
        command = "TextService"
        ports   = ["http"]
      }
    }
  }

  group "rating-service" {
    count = 2  
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

    task "rating-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "rating-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  rating-redis' >> /etc/hosts && RatingService"]
        ports = ["http"]
      }
    }

    task "rating-redis" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "rating-redis"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "redis:alpine3.13"
      }
    }
  }

  group "user-service" {
    count = 2
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


    task "user-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "user-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"


        args  = ["-c", "echo '127.0.0.1  user-mongodb' >> /etc/hosts &&  echo '127.0.0.1  user-memcached' >> /etc/hosts && UserService"]
        ports = ["http"]
      }
    }

    task "user-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }

      driver = "docker"
      service {
        name = "user-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "user-memcached" {
      resources {
        cpu = 1000
        memory_max = 1000
      }

      driver = "docker"
      service {
        name = "user-memcached"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/memcached"
      }
    }
  }

  group "compose-review-service" {
    count = 2
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

    task "compose-review-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "compose-review-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  compose-review-memcached' >> /etc/hosts && ComposeReviewService"]
        ports = ["http"]
      }
    }

    task "compose-review-memcached" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "compose-review-memcached"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/memcached"
      }
    }
  }

  group "review-storage-service" {
    count = 2
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

    task "review-storage-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "review-storage-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  review-storage-mongodb' >> /etc/hosts && echo '127.0.0.1  review-storage-memcached' >> /etc/hosts && ReviewStorageService"]
        ports = ["http"]
      }
    }

    task "review-storage-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "review-storage-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "review-storage-memcached" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "review-storage-memcached"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/memcached"
      }
    }
  }

  group "user-review-service" {
    count = 2
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

    task "user-review-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "user-review-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  user-review-mongodb' >> /etc/hosts && echo '127.0.0.1  user-review-redis' >> /etc/hosts && UserReviewService"]
        ports = ["http"]
      }
    }

    task "user-review-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "user-review-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "user-review-redis" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "user-review-redis"

        address_mode = "driver"
      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "redis:alpine3.13"
      }
    }
  }

  group "movie-review-service" {
    count = 2
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

    task "movie-review-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "movie-review-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  movie-review-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-review-redis' >> /etc/hosts && MovieReviewService"]
        ports   = ["http"]
      }
    }

    task "movie-review-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "movie-review-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "movie-review-redis" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "movie-review-redis"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "redis:alpine3.13"
      }
    }
  }

  group "cast-info-service" {
    count = 2
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

    task "cast-info-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "cast-info-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  cast-info-mongodb' >> /etc/hosts && echo '127.0.0.1  cast-info-memcached' >> /etc/hosts && CastInfoService"]
        ports   = ["http"]
      }
    }

    task "cast-info-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "cast-info-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "cast-info-memcached" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "cast-info-memcached"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/memcached"
      }
    }
  }

  group "plot-service" {
    count = 2
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

    task "plot-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "plot-service"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  plot-mongodb' >> /etc/hosts && echo '127.0.0.1  plot-memcached' >> /etc/hosts && PlotService"]
        ports   = ["http"]
      }
    }

    task "plot-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "plot-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "plot-memcached" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      driver = "docker"
      service {
        name = "plot-memcached"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/memcached"
      }
    }
  }

  group "movie-info-service" {
    count = 2
    network {
      mode = "bridge"
      port "http" {
        static = 9101
      }
      dns {
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "movie-info-service" {
      resources {
        cpu = 1000
        memory_max = 1000
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "movie-info-service"
        port = "http"
      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  movie-info-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-info-memcached' >> /etc/hosts && MovieInfoService"]
        ports = ["http"]
      }
    }

    task "movie-info-mongodb" {
      resources {
        cpu = 1000
        memory_max = 1000
      }

      driver = "docker"
      service {
        name = "movie-info-mongodb"

      }
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/mongo"
      }
    }

    task "movie-info-memcached" {
      resources {
        cpu = 1000
        memory_max = 1000
      }

      driver = "docker"
      service {
        name = "movie-info-memcached"
      }
      
      config {
        memory_hard_limit = 1000
        cpu_hard_limit = true

        image = "stvdputten/memcached"
      }
    }
  }
}