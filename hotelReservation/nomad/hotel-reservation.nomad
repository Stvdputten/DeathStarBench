variable "hostname" {
  type    = string
  default = "node3.stvdp-112600.sched-serv-pg0.utah.cloudlab.us"
}

variable "jaeger" {
  type    = string
  default = "128.110.219.109"
}

variable "dns" {
  type    = string
  default = "128.110.219.105"
}

job "hotel-reservation" {
  datacenters = ["dc1"]

  group "frontend" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "${var.hostname}"
    }
    network {
      // mode = "bridge"
      port "frontend" {
        static = 5000
      }
      dns {
        servers  = ["${var.jaeger}", "${var.dns}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "frontend" {
      driver = "docker"
      // lifecycle {
      //   hook    = "poststart"
      //   sidecar = true
      // }

      config {
        image   = "stvdputten/hotel_reserv_frontend_single_node:nomad"
        command = "sh"
        args = ["-c",
          "curl -X PUT -d '{\"name\":\"frontend-hotel\",  \"address\":\"${var.jaeger}\", \"Port\":5000}' ${var.jaeger}:4000/v1/agent/service/register && frontend"
        ]
        ports = ["frontend"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
      }
    }
  }

  group "dns" {
    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "${var.hostname}"
    }
    network {
      mode = "bridge"
      port "jaeger-ui" {
        static = 16686
      }
      port "jaeger" {
        static = 6831
      }
      port "consul" {
        static = 53
      }
      port "dns-ui" {
        static = 4000
        to     = 8500
      }
    }

    task "consul" {
      driver = "docker"
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      config {
        image   = "consul:1.9.6"
        ports   = ["dns-ui"]
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
      service {
        name = "consul-fix"
        check {
          type     = "script"
          interval = "5s"
          timeout  = "2s"
          name     = "Service registration through http"
          command  = "curl"
          args     = ["-X", "PUT", "-d", "{\"name\":\"consul\",  \"address\":\"${var.jaeger}\", \"Port\":53}", "http://localhost:8500/v1/agent/service/register"]
        }
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
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Install packages"
          command  = "apk"
          args     = ["add", "curl"]
        }
        check {
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Test var"
          command  = "echo"
          args     = ["${attr.unique.network.ip-address}"]
        }
        check {
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Service registration through http"
          command  = "curl"
          args     = ["-X", "PUT", "-d", "{\"name\":\"jaeger-hotel\",  \"address\":\"${var.jaeger}\", \"Port\":6831}", "http://localhost:8500/v1/agent/service/register"]
        }
      }
    }
  }

  group "profile" {
    network {
      mode = "bridge"
      port "profile" {
        to     = 8081
        static = 8081
      }
      port "memcached-profile" {
        to     = 11213
        static = 11213
      }
      port "mongodb-profile" {
        to     = 27019
        static = 27019
      }
      dns {
        servers  = ["${var.jaeger}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "profile" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_profile_single_node:nomad"
        command = "profile"
        ports   = ["profile"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
      }
      service {
        name = "profile"
        check {
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Service registration through http"
          command  = "curl"
          args     = ["-X", "PUT", "-d", "{\"name\":\"profile-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":8081}", "http://${var.jaeger}:4000/v1/agent/service/register"]
        }
      }
    }

    task "memcached-profile" {
      driver = "docker"

      env {
        MEMCACHED_CACHE_SIZE = "128"
        MEMCACHED_THREADS    = "2"
      }
      config {
        command = "memcached"
        args    = ["-p", "11213"]
        // "curl -X PUT -d '{\"name\":\"memcached-profile-hotel\",  \"address\":\"${attr.unique.network.ip-address}\",\"Port\":11213}'  ${var.jaeger}:4000/v1/agent/service/register && memcached -p 11213"
        image = "stvdputten/memcached"
        ports = ["memcached-profile"]
      }
      service {
        name = "mem-profile"
        check {
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Service registration through http"
          command  = "curl"
          args     = ["-X", "PUT", "-d", "{\"name\":\"memcached-profile-hotel\",  \"address\":\"127.0.0.1\", \"Port\":11213}", "http://${var.jaeger}:4000/v1/agent/service/register"]
        }
      }
    }

    task "mongodb-profile" {
      driver = "docker"

      config {
        command = "mongod"
        args    = ["--port", "27019"]
        image   = "stvdputten/mongo"
        ports   = ["mongodb-profile"]
      }
      service {
        name = "mongo-profile"
        check {
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Service registration through http"
          command  = "curl"
          args     = ["-X", "PUT", "-d", "{\"name\":\"mongodb-profile-hotel\",  \"address\":\"127.0.0.1\", \"Port\":27019}", "http://${var.jaeger}:4000/v1/agent/service/register"]
        }
      }
    }
  }

  group "geo" {
    network {
      mode = "bridge"
      port "geo" {
        to     = 8083
        static = 8083
      }
      port "mongodb-geo" {
        to     = 27018
        static = 27018
      }
      dns {
        servers  = ["${var.jaeger}", "8.8.8.8"]
        searches = ["service.consul"]
      }
    }

    task "geo" {
      driver = "docker"
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      config {
        image   = "stvdputten/hotel_reserv_geo_single_node:nomad"
        command = "geo"
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
        }
      }
      service {
        name = "geo"
        check {
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Service registration through http"
          command  = "curl"
          args     = ["-X", "PUT", "-d", "{\"name\":\"geo-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":8083}", "http://${var.jaeger}:4000/v1/agent/service/register"]
        }
      }
    }

    task "mongodb-geo" {
      driver = "docker"

      config {
        // command = "sh"
        // args = ["-c",
        //   "curl -X PUT -d '{\"name\":\"mongodb-geo-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":27018}' localhost:8500/v1/agent/service/register && mongod --port 27018"
        // ]
        command = "mongod"
        args    = ["--port", "27018"]
        image = "stvdputten/mongo"
        ports = ["mongodb-geo"]
      }
      service {
        name = "mongo-profile"
        check {
          type     = "script"
          interval = "10s"
          timeout  = "2s"
          name     = "Service registration through http"
          command  = "curl"
          args     = ["-X", "PUT", "-d", "{\"name\":\"mongodb-geo-hotel\",  \"address\":\"127.0.0.1\", \"Port\":27018}", "http://${var.jaeger}:4000/v1/agent/service/register"]
        }
      }
    }
  }
}

//   group "hotel-reservation" {





//     task "rate" {
//       driver = "docker"
//       lifecycle {
//         hook    = "poststart"
//         sidecar = true
//       }
//       template {
//         destination = "local/resolv.conf"
//         data        = <<EOF
// nameserver 127.0.0.1
// nameserver 128.110.156.4
// search service.consul
// EOF
//       }

//       config {
//         image   = "stvdputten/hotel_reserv_rate_single_node:nomad"
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"rate-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":8084}' localhost:8500/v1/agent/service/register && rate"
//         ]
//         ports = ["rate"]
//         mount {
//           type   = "bind"
//           target = "/go/src/github.com/harlow/go-micro-services/config.json"
//           source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
//         }
//         volumes = [
//           "local/resolv.conf:/etc/resolv.conf"
//         ]
//       }
//     }

//     task "memcached-rate" {
//       driver = "docker"

//       env {
//         MEMCACHED_CACHE_SIZE = "128"
//         MEMCACHED_THREADS    = "2"
//       }
//       config {
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"memcached-rate-hotel\",  \"address\":\"${attr.unique.network.ip-address}\",\"Port\":11212}' localhost:8500/v1/agent/service/register && memcached -p 11212"
//         ]
//         image = "stvdputten/memcached"
//         ports = ["mem-rate"]
//       }
//     }

//     task "mongodb-rate" {
//       driver = "docker"

//       config {
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"mongodb-rate-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":27020}' localhost:8500/v1/agent/service/register && mongod --port 27020"
//         ]
//         image = "stvdputten/mongo"
//       }
//     }

//     task "recommendation" {
//       driver = "docker"
//       lifecycle {
//         hook    = "poststart"
//         sidecar = true
//       }
//       template {
//         destination = "local/resolv.conf"
//         data        = <<EOF
// nameserver 127.0.0.1
// nameserver 128.110.156.4
// search service.consul
// EOF
//       }

//       config {
//         image   = "stvdputten/hotel_reserv_recommendation_single_node:nomad"
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"recommendation-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":8085}' localhost:8500/v1/agent/service/register && recommendation"
//         ]
//         ports = ["recommendation"]
//         mount {
//           type   = "bind"
//           target = "/go/src/github.com/harlow/go-micro-services/config.json"
//           source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
//         }
//         volumes = [
//           "local/resolv.conf:/etc/resolv.conf"
//         ]
//       }
//     }

//     task "mongodb-recommendation" {
//       driver = "docker"

//       config {
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"mongodb-recommendation-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":27021}' localhost:8500/v1/agent/service/register && mongod --port 27021"
//         ]
//         image = "stvdputten/mongo"
//       }
//     }

//     task "user" {
//       lifecycle {
//         hook    = "poststart"
//         sidecar = true
//       }
//       template {
//         destination = "local/resolv.conf"
//         data        = <<EOF
// nameserver ${attr.unique.network.ip-address}
// nameserver 128.110.156.4
// search service.consul
// EOF
//       }
//       driver = "docker"

//       config {
//         image   = "stvdputten/hotel_reserv_user_single_node:nomad"
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"user-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":8086}' localhost:8500/v1/agent/service/register && user"
//         ]
//         ports = ["user"]
//         mount {
//           type   = "bind"
//           target = "/go/src/github.com/harlow/go-micro-services/config.json"
//           source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
//         }
//         volumes = [
//           "local/resolv.conf:/etc/resolv.conf"
//         ]
//       }
//     }

//     task "mongodb-user" {
//       driver = "docker"

//       config {
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"mongodb-user-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":27023}' localhost:8500/v1/agent/service/register && mongod --port 27023"
//         ]
//         image = "stvdputten/mongo"
//       }
//     }

//     task "reservation" {
//       driver = "docker"
//       lifecycle {
//         hook    = "poststart"
//         sidecar = true
//       }
//       template {
//         destination = "local/resolv.conf"
//         data        = <<EOF
// nameserver 127.0.0.1
// nameserver 128.110.156.4
// search service.consul
// EOF
//       }

//       config {
//         image   = "stvdputten/hotel_reserv_reserve_single_node:nomad"
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"reservation-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":8087}' localhost:8500/v1/agent/service/register && reservation"
//         ]
//         ports = ["reservation"]
//         mount {
//           type   = "bind"
//           target = "/go/src/github.com/harlow/go-micro-services/config.json"
//           source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
//         }
//         volumes = [
//           "local/resolv.conf:/etc/resolv.conf"
//         ]
//       }
//     }

//     task "memcached-reserve" {
//       driver = "docker"

//       env {
//         MEMCACHED_CACHE_SIZE = "128"
//         MEMCACHED_THREADS    = "2"
//       }
//       config {
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"memcached-reservation-hotel\",  \"address\":\"${attr.unique.network.ip-address}\",\"Port\":11214}' localhost:8500/v1/agent/service/register && memcached -p 11214"
//         ]
//         image = "stvdputten/memcached"
//       }
//     }

//     task "mongodb-reserve" {
//       driver = "docker"

//       config {
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"mongodb-reservation-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":27022}' localhost:8500/v1/agent/service/register && mongod --port 27022"
//         ]
//         image = "stvdputten/mongo"
//       }
//     }

//     task "search" {
//       driver = "docker"
//       lifecycle {
//         hook    = "poststart"
//         sidecar = true
//       }
//       template {
//         destination = "local/resolv.conf"
//         data        = <<EOF
// nameserver 127.0.0.1
// nameserver 128.110.156.4
// search service.consul
// EOF
//       }

//       config {
//         image   = "stvdputten/hotel_reserv_search_single_node:nomad"
//         command = "sh"
//         args = ["-c",
//           "curl -X PUT -d '{\"name\":\"search-hotel\",  \"address\":\"${attr.unique.network.ip-address}\", \"Port\":8082}' localhost:8500/v1/agent/service/register && search"
//         ]
//         ports = ["search"]
//         mount {
//           type   = "bind"
//           target = "/go/src/github.com/harlow/go-micro-services/config.json"
//           source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/config/config.json"
//         }
//         volumes = [
//           "local/resolv.conf:/etc/resolv.conf"
//         ]
//       }
//     }


//   }
// }