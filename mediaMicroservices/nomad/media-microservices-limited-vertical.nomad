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

  group "nginx-web-server" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "${var.hostname}"
    }
    network {
      mode = "bridge"
      port "nginx" {
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
        cores = "8.0"
        memory_max = "8590"
      }

      config {
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
        cores  = 4
        memory = 16000 * 4
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
      }
      dns {
        servers  = ["${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "unique-id-service" {
      count = 1
      resources {
        cores = "2.0"
        memory_max = "2147"
      }
      service {
        name = "unique-id-service"

      }
      driver = "docker"
      config {
        image = "stvdputten/media-microservices:nomad"
        command = "UniqueIdService"
        ports   = ["http"]
      }
    }
  }

  group "movie-id-service" {
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
        cores = "2.0"
        memory_max = "2147"
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args  = ["-c", "echo '127.0.0.1  movie-id-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-id-memcached' >> /etc/hosts && MovieIdService"]
        ports = ["http"]
      }
    }

    task "movie-id-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147"
      }
      driver = "docker"
      service {
        name = "movie-id-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-id-memcached" {
      resources {
        cores = "2.0"
        memory_max = "2147"
      }
      driver = "docker"
      service {
        name = "movie-id-memcached"

      }
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "text-service" {
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
        cores = "2.0"
        memory_max = "2147"
      }
      driver = "docker"
      service {
        name = "text-service"

      }
      config {
        image = "stvdputten/media-microservices:nomad"
        command = "TextService"
        ports   = ["http"]
      }
    }
  }

  group "rating-service" {
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
        cores = "2.0"
        memory_max = "2147"
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  rating-redis' >> /etc/hosts && RatingService"]
        ports = ["http"]
      }
    }

    task "rating-redis" {
      resources {
        cores = "2.0"
        memory_max = "2147"
      }
      driver = "docker"
      service {
        name = "rating-redis"

      }
      config {
        image = "redis:alpine3.13"
      }
    }
  }

  group "user-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"


        args  = ["-c", "echo '127.0.0.1  user-mongodb' >> /etc/hosts &&  echo '127.0.0.1  user-memcached' >> /etc/hosts && UserService"]
        ports = ["http"]
      }
    }

    task "user-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }

      driver = "docker"
      service {
        name = "user-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "user-memcached" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }

      driver = "docker"
      service {
        name = "user-memcached"

      }
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "compose-review-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  compose-review-memcached' >> /etc/hosts && ComposeReviewService"]
        ports = ["http"]
      }
    }

    task "compose-review-memcached" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "compose-review-memcached"

      }
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "review-storage-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  review-storage-mongodb' >> /etc/hosts && echo '127.0.0.1  review-storage-memcached' >> /etc/hosts && ReviewStorageService"]
        ports = ["http"]
      }
    }

    task "review-storage-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "review-storage-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "review-storage-memcached" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "review-storage-memcached"

      }
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "user-review-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  user-review-mongodb' >> /etc/hosts && echo '127.0.0.1  user-review-redis' >> /etc/hosts && UserReviewService"]
        ports = ["http"]
      }
    }

    task "user-review-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "user-review-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "user-review-redis" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "user-review-redis"

        address_mode = "driver"
      }
      config {
        image = "redis:alpine3.13"
      }
    }
  }

  group "movie-review-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  movie-review-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-review-redis' >> /etc/hosts && MovieReviewService"]
        ports   = ["http"]
      }
    }

    task "movie-review-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "movie-review-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-review-redis" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "movie-review-redis"

      }
      config {
        image = "redis:alpine3.13"
      }
    }
  }

  group "cast-info-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  cast-info-mongodb' >> /etc/hosts && echo '127.0.0.1  cast-info-memcached' >> /etc/hosts && CastInfoService"]
        ports   = ["http"]
      }
    }

    task "cast-info-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "cast-info-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "cast-info-memcached" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "cast-info-memcached"

      }
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "plot-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '127.0.0.1  plot-mongodb' >> /etc/hosts && echo '127.0.0.1  plot-memcached' >> /etc/hosts && PlotService"]
        ports   = ["http"]
      }
    }

    task "plot-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "plot-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "plot-memcached" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }
      driver = "docker"
      service {
        name = "plot-memcached"

      }
      config {
        image = "stvdputten/memcached"
      }
    }
  }

  group "movie-info-service" {
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
        cores = "2.0"
        memory_max = "2147" 
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
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"

        args  = ["-c", "echo '127.0.0.1  movie-info-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-info-memcached' >> /etc/hosts && MovieInfoService"]
        ports = ["http"]
      }
    }

    task "movie-info-mongodb" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }

      driver = "docker"
      service {
        name = "movie-info-mongodb"

      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-info-memcached" {
      resources {
        cores = "2.0"
        memory_max = "2147" 
      }

      driver = "docker"
      service {
        name = "movie-info-memcached"
      }
      
      config {
        image = "stvdputten/memcached"
      }
    }
  }
}