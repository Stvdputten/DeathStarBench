job "hotel-reservation" {
  datacenters = ["dc1"]

  group "hotel-reservation" {
    network {
      mode = "bridge"
      port "frontend" {
        static = 5000
        to     = 5000
      }
      port "dns-ui" {
        static = 4000
        to     = 8500
      }
      port "jaeger-ui" {
        static = 16686
        to = 16686
      }
      // port "jaeger-5778" {
      //   to     = 5778
      // }
      // port "jaeger-6832" {
      //   to = 6832
      // }
      port "jaeger" {
        to = 6831
      }
    }

    task "consul" {
      driver = "docker"
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      config {
        image = "consul:1.9.6"
        ports = ["dns-ui"]
        command = "consul"
        args = [
          "agent",
          "-dev",
          "-data-dir=/consul/data",
          "-enable-script-checks",
          "-client",
          "0.0.0.0",
          "-bind",
          "{{ GetInterfaceIP \"eth0\"}}",
          "-dns-port",
          "53"
        ]
      }
    }
  

    task "frontend" {
      driver = "docker"
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }

      config {
        image = "stvdputten/hotel_reserv_frontend_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"frontend-hotel\",  \"address\":\"127.0.0.1\", \"Port\":5000}' localhost:8500/v1/agent/service/register && frontend"
        ]
        ports       = ["frontend"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
      volumes = [
          "local/resolv.conf:/etc/resolv.conf"
      ]
      }
    }

    task "profile" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }

      config {
        image   = "stvdputten/hotel_reserv_profile_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"profile-hotel\",  \"address\":\"127.0.0.1\", \"Port\":8081}' localhost:8500/v1/agent/service/register && profile"
        ]
        ports   = ["profile"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
        volumes = [
            "local/resolv.conf:/etc/resolv.conf"
        ]
      }
    }

    task "memcached-profile" {
      driver = "docker"

      env {
        MEMCACHED_CACHE_SIZE = "128"
        MEMCACHED_THREADS    = "2"
      }
      config {
        command = "sh"
        args = ["-c", 
         "curl -X PUT -d '{\"name\":\"memcached-profile-hotel\",  \"address\":\"127.0.0.1\",\"Port\":11213}' localhost:8500/v1/agent/service/register && memcached -p 11213"
        ]
       image="stvdputten/memcached"
        ports = ["mem-profile"]
      }
    }

    task "mongodb-profile" {
      driver = "docker"

      config {    
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"mongodb-profile-hotel\", \"address\":\"127.0.0.1\",\"Port\":27019}' localhost:8500/v1/agent/service/register && mongod --port 27019"
        ]
        image = "stvdputten/mongo"
        ports = ["mongo-profile"]
      }
    }

    task "geo" {
      driver = "docker"
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      config {
        image   = "stvdputten/hotel_reserv_geo_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"geo-hotel\",  \"address\":\"127.0.0.1\", \"Port\":8083}' localhost:8500/v1/agent/service/register && geo"
        ]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
        volumes = [
            "local/resolv.conf:/etc/resolv.conf"
        ]
      }
    }

    task "mongodb-geo" {
      driver = "docker"

      config {    
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"mongodb-geo-hotel\",  \"address\":\"127.0.0.1\", \"Port\":27018}' localhost:8500/v1/agent/service/register && mongod --port 27018"
        ]
        image = "stvdputten/mongo"
      }
    }


    task "rate" {
      driver = "docker"
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }

      config {
        image   = "stvdputten/hotel_reserv_rate_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"rate-hotel\",  \"address\":\"127.0.0.1\", \"Port\":8084}' localhost:8500/v1/agent/service/register && rate"
        ]
        ports   = ["rate"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
        volumes = [
            "local/resolv.conf:/etc/resolv.conf"
        ]
      }
    }

    task "memcached-rate" {
      driver = "docker"

      env {
        MEMCACHED_CACHE_SIZE = "128"
        MEMCACHED_THREADS    = "2"
      }
      config {
        command = "sh"
        args = ["-c", 
         "curl -X PUT -d '{\"name\":\"memcached-rate-hotel\",  \"address\":\"127.0.0.1\",\"Port\":11212}' localhost:8500/v1/agent/service/register && memcached -p 11212"
        ]
       image="stvdputten/memcached"
        ports = ["mem-rate"]
      }
    }

    task "mongodb-rate" {
      driver = "docker"

      config {    
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"mongodb-rate-hotel\",  \"address\":\"127.0.0.1\", \"Port\":27020}' localhost:8500/v1/agent/service/register && mongod --port 27020"
        ]
        image = "stvdputten/mongo"
      }
    }

    task "recommendation" {
      driver = "docker"
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }

      config {
        image   = "stvdputten/hotel_reserv_recommendation_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"recommendation-hotel\",  \"address\":\"127.0.0.1\", \"Port\":8085}' localhost:8500/v1/agent/service/register && recommendation"
        ]
        ports   = ["recommendation"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
      volumes = [
          "local/resolv.conf:/etc/resolv.conf"
      ]
      }
    }

    task "mongodb-recommendation" {
      driver = "docker"

      config {    
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"mongodb-recommendation-hotel\",  \"address\":\"127.0.0.1\", \"Port\":27021}' localhost:8500/v1/agent/service/register && mongod --port 27021"
        ]
        image = "stvdputten/mongo"
      }
    }

    task "user" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_user_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"user-hotel\",  \"address\":\"127.0.0.1\", \"Port\":8086}' localhost:8500/v1/agent/service/register && user"
        ]
        ports   = ["user"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
      volumes = [
          "local/resolv.conf:/etc/resolv.conf"
      ]
      }
    }

    task "mongodb-user" {
      driver = "docker"

      config {    
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"mongodb-user-hotel\",  \"address\":\"127.0.0.1\", \"Port\":27023}' localhost:8500/v1/agent/service/register && mongod --port 27023"
        ]
        image = "stvdputten/mongo"
      }
    }

    task "reservation" {
      driver = "docker"
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }

      config {
        image   = "stvdputten/hotel_reserv_reserve_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"reservation-hotel\",  \"address\":\"127.0.0.1\", \"Port\":8087}' localhost:8500/v1/agent/service/register && reservation"
        ]
        ports   = ["reservation"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
        volumes = [
            "local/resolv.conf:/etc/resolv.conf"
        ]
      }
    }

    task "memcached-reserve" {
      driver = "docker"

      env {
        MEMCACHED_CACHE_SIZE = "128"
        MEMCACHED_THREADS    = "2"
      }
      config {
        command = "sh"
        args = ["-c", 
         "curl -X PUT -d '{\"name\":\"memcached-reservation-hotel\",  \"address\":\"127.0.0.1\",\"Port\":11214}' localhost:8500/v1/agent/service/register && memcached -p 11214"
        ]
       image="stvdputten/memcached"
      }
    }

    task "mongodb-reserve" {
      driver = "docker"

      config {    
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"mongodb-reservation-hotel\",  \"address\":\"127.0.0.1\", \"Port\":27022}' localhost:8500/v1/agent/service/register && mongod --port 27022"
        ]
        image = "stvdputten/mongo"
      }
    }

    task "search" {
      driver = "docker"
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      template {
        destination = "local/resolv.conf"
        data        = <<EOF
nameserver 127.0.0.1
nameserver 128.110.156.4
search service.consul
EOF
      }

      config {
        image   = "stvdputten/hotel_reserv_search_single_node:nomad"
        command = "sh"
        args = ["-c",
         "curl -X PUT -d '{\"name\":\"search-hotel\",  \"address\":\"127.0.0.1\", \"Port\":8082}' localhost:8500/v1/agent/service/register && search"
        ]
        ports   = ["search"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
        volumes = [
            "local/resolv.conf:/etc/resolv.conf"
        ]
      }
    }

    task "jaeger" {
      driver = "docker"

      config {
        image = "jaegertracing/all-in-one:1.23.0"
        ports = ["jaeger"]
      }
      service {
        name = "jaeger-hr"
        check {
          type = "script"
          interval = "10s"
          timeout = "2s"
          name     = "Install packages"
          command = "apk" 
          args = ["add", "curl"]
        }
        check {
          type = "script"
          interval = "10s"
          timeout = "2s"
          name     = "Service registration through http"
          command = "curl" 
          args = ["-X", "PUT", "-d", "{\"name\":\"jaeger-hotel\",   \"address\":\"127.0.0.1\", \"Port\":6831}", "http://localhost:8500/v1/agent/service/register"]
        }
      } 
    }

  }
}