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
      port "dns" {
        static = 4001
        to     = 8600
      }
    }

    task "consul" {
      driver = "docker"
      service {
        name = "hr-consul-docker"
      }

      config {
        image = "consul:1.9.6"
        // network_mode = "bridge"
        ports = ["dns-ui", "dns"]
        // ["8300/tcp"] = 8300
        // ["8400/tcp"] = 8400
        // ["8500/tcp"] = 8500
        // ["8300/udp"] = 8300
        // ["8400/udp"] = 8400
        // ["8500/udp"] = 8500
        // ["8600/udp"] = 8600
        command = "consul"
        args = [
          "agent",
          "-data-dir=/consul/data",
          "-config-dir=/consul/config",
          "-dev",
          "-client",
          "0.0.0.0",
          "-bind",
          "{{ GetInterfaceIP \"eth0\"}}"
        ]
      }
    }

    task "profile" {
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_profile_single_node"
        command = "profile"
        ports   = ["profile"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/deathstarbench/hotelreservation/nomad/configmaps/config.json"
        }
      }
    }

    task "memcached-profile" {
      driver = "docker"

      config {
        image = "memcached:1.6.9"
        ports = ["mem-profile"]
        env {
          MEMCACHED_CACHE_SIZE = "128"
          MEMCACHED_THREADS    = "2"
        }
      }
    }

    task "mongodb-profile" {
      driver = "docker"

      config {
        image = "mongo:4.4.6"
        ports = ["mongo-profile"]
      }
    }

    task "geo" {
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_geo_single_node"
        command = "geo"
        ports   = ["geo"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/deathstarbench/hotelreservation/nomad/configmaps/config.json"
        }
      }
    }

    task "mongodb-geo" {
      driver = "docker"

      config {
        image = "mongo:4.4.6"
        ports = ["mongo-geo"]
      }
    }


    task "rate" {
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_rate_single_node"
        command = "rate"
        ports   = ["rate"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/deathstarbench/hotelreservation/nomad/configmaps/config.json"
        }
      }
    }

    task "memcached-rate" {
      driver = "docker"

      config {
        image = "memcached:1.6.9"
        ports = ["mem-rate"]
        env {
          MEMCACHED_CACHE_SIZE = "128"
          MEMCACHED_THREADS    = "2"
        }
      }
    }

    task "mongodb-rate" {
      driver = "docker"

      config {
        image = "mongo:4.4.6"
        ports = ["mongo-rate"]
      }
    }


    task "recommendation" {
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_recommend_single_node"
        command = "recommendation"
        ports   = ["recommendation"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/deathstarbench/hotelreservation/nomad/configmaps/config.json"
        }
      }
    }

    task "mongodb-recommendation" {
      driver = "docker"

      config {
        image = "mongo:4.4.6"
        ports = ["mongo-recommendation"]
      }
    }


    task "user" {
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_user_single_node"
        command = "user"
        ports   = ["user"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/deathstarbench/hotelreservation/nomad/configmaps/config.json"
        }
      }
    }

    task "mongodb-user" {
      driver = "docker"

      config {
        image = "mongo:4.4.6"
        ports = ["mongo-user"]
      }
    }

    task "reservation" {
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_reservation_single_node"
        command = "reservation"
        ports   = ["reservation"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/deathstarbench/hotelreservation/nomad/configmaps/config.json"
        }
      }
    }

    task "memcached-reserve" {
      driver = "docker"

      config {
        image = "memcached:1.6.9"
        ports = ["mem-reserve"]
        env {
          MEMCACHED_CACHE_SIZE = "128"
          MEMCACHED_THREADS    = "2"
        }
      }
    }

    task "mongodb-reserve" {
      driver = "docker"

      config {
        image = "mongo:4.4.6"
        ports = ["mongo-reservation"]
      }
    }

    task "jaeger" {
      driver = "docker"
      service {
        name = "jaeger-hotel"
      }

      config {
        image = "jaegertracing/all-in-one:1.23.0"
        ports = ["jaeger"]
        // dns_servers = ["${NOMAD_ADDR_dns}"]
        extra_hosts = ["consul-hotel:127.0.0.1", "jaeger-hotel:127.0.0.1"]
      }
    }

  }
}