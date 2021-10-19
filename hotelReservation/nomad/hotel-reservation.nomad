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
      port "test" {
        static = 5001
        to = 5000
      }
    }

    task "consul" {
      driver = "docker"
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      template {
        data = <<EOTC
{ "service": { "name":"frontend", "address":"127.0.0.1", "port":5000 } }
        EOTC
        destination = "local/frontend.json"
      }
      template {
        data = <<EOTC
{ "service": { "name":"jaeger-hotel", "address":"127.0.0.1", "port":6831 } }
        EOTC
        destination = "local/jaeger.json"
      }
      template {
        data = <<EOTC
{ "service": { "name":"profile-hotel", "address":"127.0.0.1", "port":6831 } }
        EOTC
        destination = "local/profile.json"
      }
      template {
        data = <<EOTC
{ "service": { "name":"mongodb-profile-hotel", "address":"127.0.0.1", "port":27019 } }
        EOTC
        destination = "local/mongo-profile.json"
      }
      config {
        image = "consul:1.9.6"
        // network_mode = "bridge"
        ports = ["dns-ui"]
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
          "-dev",
          "-data-dir=/consul/data",
          "-config-dir=/etc/consul.d",
          "-enable-script-checks",
          "-client",
          "0.0.0.0",
          "-bind",
          "{{ GetInterfaceIP \"eth0\"}}",
          "-dns-port",
          "53"
        ]
        volumes = [
            "local/frontend.json:/etc/consul.d/frontend.json",
            "local/jaeger.json:/etc/consul.d/jaeger.json",
            "local/mongo-profile.json:/etc/consul.d/mongo-profile.json",
            "local/profile.json:/etc/consul.d/profile.json"
        ]
      }
    }
  

    task "frontend" {
      env = {
        "test" = "'bob'"
      }
      service {
        name = "frontend-hr"
        port = "test"
        check {
          type = "script"
          interval = "10s"
          timeout = "2s"
          name     = "curl"
          // command = "curl -X PUT -d '{\"name\":\"bob\"}' http://localhost:8500/v1/agent/service/register" 
          command = "curl" 
          args = ["-X", "PUT", "-d", "{\"name\":\"frontend\", \"Port\":5000}", "http://localhost:8500/v1/agent/service/register"]
          // args = ["-X", "PUT", "-d", "${}", "http://localhost:8500/v1/agent/service/register"]
        }
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
        image = "stvdputten/hotel_reserv_frontend_single_node"
        command = "frontend"
        ports       = ["frontend"]
        // advertise_ipv6_address = true
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
        }
      volumes = [
          "local/resolv.conf:/etc/resolv.conf"
      ]

      }
    }

    // task "profile" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/hotel_reserv_profile_single_node"
    //     command = "profile"
    //     ports   = ["profile"]
    //     mount {
    //       type   = "bind"
    //       target = "/go/src/github.com/harlow/go-micro-services/config.json"
    //       source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
    //     }
    //   }
    // }

    task "memcached-profile" {
      driver = "docker"

      env {
        MEMCACHED_CACHE_SIZE = "128"
        MEMCACHED_THREADS    = "2"
      }
      config {
        command = "memcached"
        args = ["-p", "11213"]
        image = "memcached:1.6.9"
        ports = ["mem-profile"]
      }
    }

    task "mongodb-profile" {
      driver = "docker"

      config {    
        command = "mongod"
        args = ["--port", "27019"]
        image = "mongo:4.4.6"
        ports = ["mongo-profile"]
      }
    }

    // task "geo" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/hotel_reserv_geo_single_node"
    //     command = "geo"
    //     ports   = ["geo"]
    //     mount {
    //       type   = "bind"
    //       target = "/go/src/github.com/harlow/go-micro-services/config.json"
    //       source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
    //     }
    //   }
    // }

    // task "mongodb-geo" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-geo"]
    //   }
    // }


    // task "rate" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/hotel_reserv_rate_single_node"
    //     command = "rate"
    //     ports   = ["rate"]
    //     mount {
    //       type   = "bind"
    //       target = "/go/src/github.com/harlow/go-micro-services/config.json"
    //       source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
    //     }
    //   }
    // }

    // task "memcached-rate" {
    //   driver = "docker"

    //     env {
    //       MEMCACHED_CACHE_SIZE = "128"
    //       MEMCACHED_THREADS    = "2"
    //     }
    //   config {
    //     image = "memcached:1.6.9"
    //     ports = ["mem-rate"]
    //   }
    // }

    // task "mongodb-rate" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-rate"]
    //   }
    // }


    // task "recommendation" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/hotel_reserv_recommend_single_node"
    //     command = "recommendation"
    //     ports   = ["recommendation"]
    //     mount {
    //       type   = "bind"
    //       target = "/go/src/github.com/harlow/go-micro-services/config.json"
    //       source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
    //     }
    //   }
    // }

    // task "mongodb-recommendation" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-recommendation"]
    //   }
    // }


    // task "user" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/hotel_reserv_user_single_node"
    //     command = "user"
    //     ports   = ["user"]
    //     mount {
    //       type   = "bind"
    //       target = "/go/src/github.com/harlow/go-micro-services/config.json"
    //       source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
    //     }
    //   }
    // }

    // task "mongodb-user" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-user"]
    //   }
    // }

    // task "reservation" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/hotel_reserv_reservation_single_node"
    //     command = "reservation"
    //     ports   = ["reservation"]
    //     mount {
    //       type   = "bind"
    //       target = "/go/src/github.com/harlow/go-micro-services/config.json"
    //       source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
    //     }
    //   }
    // }

    // task "memcached-reserve" {
    //   driver = "docker"

    //   config {
    //     image = "memcached:1.6.9"
    //     ports = ["mem-reserve"]
    //     env {
    //       MEMCACHED_CACHE_SIZE = "128"
    //       MEMCACHED_THREADS    = "2"
    //     }
    //   }
    // }

    // task "mongodb-reserve" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-reservation"]
    //   }
    // }

    task "jaeger" {
      driver = "docker"

      config {
        image = "jaegertracing/all-in-one:1.23.0"
        ports = ["jaeger"]
      }
    }

  }
}