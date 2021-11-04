variable "hostname" {
  type    = string
  default = "node1"
}

variable "jaeger" {
  type    = string
  default = "128.110.217.86"
}

variable "compose" {
  type    = string
  default = "128.110.217.82"
}

variable "dns" {
  type    = string
  default = "128.110.217.107"
}

job "media-microservices10" {
  datacenters = ["dc1"]
  // constraint {
  //   operator = "distinct_hosts"
  //   value    = "true"
  // }

  group "nginx-web-server" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value = "node3.stvdp-109700.sched-serv-pg0.utah.cloudlab.us"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
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
        args    = ["-c", "echo '127.0.0.1 jaeger' >> /etc/hosts && /usr/local/openresty/bin/openresty -g 'daemon off;'"]
        // command = "sh"
        // args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && echo '127.0.0.1  unique-id-service' >> /etc/hosts && echo '127.0.0.1  movie-id-service' >> /etc/hosts && echo '127.0.0.1  text-service' >> /etc/hosts && echo '127.0.0.1  rating-id-service' >> /etc/hosts && echo '127.0.0.1  user-service' >> /etc/hosts && echo '127.0.0.1  compose-review-service' >> /etc/hosts && echo '127.0.0.1  review-storage-service' >> /etc/hosts && echo '127.0.0.1  user-review-service' >> /etc/hosts &&  echo '127.0.0.1  movie-review-service' >> /etc/hosts && echo '127.0.0.1  movie-review-service' >> /etc/hosts &&  echo '127.0.0.1  cast-info-service' && echo '127.0.0.1  plot-service' >> /etc/hosts &&  echo '127.0.0.1  movie-info-service' >> /etc/hosts && /usr/local/openresty/bin/openresty -g 'daemon off;'"]
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
        cores = 4
        memory = 1000
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "unique-id-service" {
      service {
        name = "unique-id-service"
        // port = "9090"
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        // args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && echo '127.0.0.1  unique-id-service' >> /etc/hosts && echo '127.0.0.1  compose-review-service' >> /etc/hosts && UniqueIdService"]
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && UniqueIdService"]
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }


    task "movie-id-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      service {
        name = "movie-id-service"
        // port = "9091"
      }
      driver = "docker"
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        // args    = ["-c", "echo '127.0.0.1  compose-review-service' >> /etc/hosts && echo '${var.jaeger}  jaeger' >> /etc/hosts && echo '127.0.0.1  movie-id-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-id-memcached' >> /etc/hosts && MovieIdService"]
        args  = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && echo '127.0.0.1  movie-id-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-id-memcached' >> /etc/hosts && MovieIdService"]
        ports = ["http"]
      }
    }

    task "movie-id-mongodb" {
      driver = "docker"
      service {
        name    = "movie-id-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-id-memcached" {
      driver = "docker"
      service {
        name    = "movie-id-memcached"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }


    task "text-service" {
      driver = "docker"
      service {
        name = "text-service"
        // port = "9092"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        // args    = ["-c", "echo '${var.compose} compose-review-service' >> /etc/hosts && echo '${var.jaeger}  jaeger' >> /etc/hosts && TextService"]
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && TextService"]
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "rating-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "rating-service"
        // port = "9093"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts &&  echo '127.0.0.1  rating-redis' >> /etc/hosts && RatingService"]
        ports   = ["http"]
      }
    }

    task "rating-redis" {
      driver = "docker"
      service {
        name    = "rating-redis"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }


    task "user-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "user-service"
        // port = "9094"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        // args    = ["-c", "echo '${var.compose}  compose-review-service' >> /etc/hosts && echo '${var.jaeger}  jaeger' >> /etc/hosts &&  echo '127.0.0.1  user-mongodb' >> /etc/hosts &&  echo '127.0.0.1  user-memcached' >> /etc/hosts && UserService"]
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts &&  echo '127.0.0.1  user-mongodb' >> /etc/hosts &&  echo '127.0.0.1  user-memcached' >> /etc/hosts && UserService"]
        ports   = ["http"]
      }
    }

    task "user-mongodb" {
      driver = "docker"
      service {
        name    = "user-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "user-memcached" {
      driver = "docker"
      service {
        name    = "user-memcached"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "compose-review-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "compose-review-service"
        // port = "9095"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts &&  echo '127.0.0.1  compose-review-memcached' >> /etc/hosts && ComposeReviewService"]
        ports   = ["http"]
      }
    }

    task "compose-review-memcached" {
      driver = "docker"
      service {
        name    = "compose-review-memcached"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "review-storage-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "review-storage-service"
        // port = "9096"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts &&  echo '127.0.0.1  review-storage-mongodb' >> /etc/hosts && echo '127.0.0.1  review-storage-memcached' >> /etc/hosts && ReviewStorageService"]
        ports   = ["http"]
      }
    }

    task "review-storage-mongodb" {
      driver = "docker"
      service {
        name    = "review-storage-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "review-storage-memcached" {
      driver = "docker"
      service {
        name    = "review-storage-memcached"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "user-review-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "user-review-service"
        // port = "9097"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts &&  echo '127.0.0.1  user-review-mongodb' >> /etc/hosts && echo '127.0.0.1  user-review-redis' >> /etc/hosts && UserReviewService"]
        ports   = ["http"]
      }
    }

    task "user-review-mongodb" {
      driver = "docker"
      service {
        name    = "user-review-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "user-review-redis" {
      driver = "docker"
      service {
        name    = "user-review-redis"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "movie-review-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "movie-review-service"
        // port = "9098"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts &&  echo '127.0.0.1  movie-review-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-review-redis' >> /etc/hosts && MovieReviewService"]
        ports   = ["http"]
      }
    }

    task "movie-review-mongodb" {
      driver = "docker"
      service {
        name    = "movie-review-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-review-redis" {
      driver = "docker"
      service {
        name    = "movie-review-redis"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "cast-info-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "cast-info-service"
        // port = "9099"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && echo '127.0.0.1  cast-info-mongodb' >> /etc/hosts && echo '127.0.0.1  cast-info-memcached' >> /etc/hosts && CastInfoService"]
        ports   = ["http"]
      }
    }

    task "cast-info-mongodb" {
      driver = "docker"
      service {
        name    = "cast-info-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "cast-info-memcached" {
      driver = "docker"
      service {
        name    = "cast-info-memcached"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "plot-service" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      service {
        name = "plot-service"
        // port = "9100"
      }
      config {
        image   = "stvdputten/media-microservices:nomad"
        command = "sh"
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && echo '127.0.0.1  plot-mongodb' >> /etc/hosts && echo '127.0.0.1  plot-memcached' >> /etc/hosts && PlotService"]
        ports   = ["http"]
      }
    }

    task "plot-mongodb" {
      driver = "docker"
      service {
        name    = "plot-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "plot-memcached" {
      driver = "docker"
      service {
        name    = "plot-memcached"
        // address = "127.0.0.1"
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
        servers = ["8.8.8.8", "${var.dns}"]  
        searches = ["service.consul"]
      }
    }

    task "movie-info-service" {
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
        args    = ["-c", "echo '${var.jaeger}  jaeger' >> /etc/hosts && echo '127.0.0.1  movie-info-mongodb' >> /etc/hosts && echo '127.0.0.1  movie-info-memcached' >> /etc/hosts && MovieInfoService"]
        ports   = ["http"]
      }
    }

    task "movie-info-mongodb" {
      driver = "docker"
      service {
        name    = "movie-info-mongodb"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/mongo"
      }
    }

    task "movie-info-memcached" {
      driver = "docker"
      service {
        name    = "movie-info-memcached"
        // address = "127.0.0.1"
      }
      config {
        image = "stvdputten/memcached"
      }
    }
  }
}