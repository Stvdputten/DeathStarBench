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
      // port "jaeger-5775" {
      //   to = 5775
      // }
      // port "jaeger-14269" {
      //   to = 14269
      // }
      // port "jaeger-14268" {
      //   to = 14268
      // }
    }

    task "consul" {
      driver = "docker"
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
//       template {
//         data = <<EOTC
// { "service": { "name":"frontend", "address":"127.0.0.1", "port":5000 } }
//         EOTC
//         destination = "local/frontend.json"
//       }
//       template {
//         data = <<EOTC
// { "service": { "name":"jaeger-hotel", "address":"127.0.0.1", "port":6831 } }
//         EOTC
//         destination = "local/jaeger.json"
//       }
//       template {
//         data = <<EOTC
// { "service": { "name":"profile-hotel", "address":"127.0.0.1", "port":6831 } }
//         EOTC
//         destination = "local/profile.json"
//       }
//       template {
//         data = <<EOTC
// { "service": { "name":"mongodb-profile-hotel", "address":"127.0.0.1", "port":27019 } }
//         EOTC
//         destination = "local/mongo-profile.json"
//       }
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
        // volumes = [
        //     "local/frontend.json:/etc/consul.d/frontend.json",
        //     "local/jaeger.json:/etc/consul.d/jaeger.json",
        //     "local/mongo-profile.json:/etc/consul.d/mongo-profile.json",
        //     "local/profile.json:/etc/consul.d/profile.json"
        // ]
      }
    }
  

//     task "frontend" {
//       driver = "docker"
//       template {
//         destination = "local/resolv.conf"
//         data        = <<EOF
// nameserver 127.0.0.1
// nameserver 128.110.156.4
// search service.consul
// EOF
//       }

//       config {
//         image = "stvdputten/hotel_reserv_frontend_single_node"
//         command = "frontend"
//         ports       = ["frontend"]
//         mount {
//           type   = "bind"
//           target = "/go/src/github.com/harlow/go-micro-services/config.json"
//           source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
//         }
//       volumes = [
//           "local/resolv.conf:/etc/resolv.conf"
//       ]
//       }
//       service {
//         name = "frontend-hr"
//         check {
//           type = "script"
//           interval = "10s"
//           timeout = "2s"
//           name     = "Service registration through http"
//           command = "curl" 
//           args = ["-X", "PUT", "-d", "{\"name\":\"frontend\", \"Port\":5000}", "http://localhost:8500/v1/agent/service/register"]
//         }
//       } 
//     }

    // task "profile" {
    //   driver = "docker"

    //   service {
    //     name = "profile-hr"
    //     check {
    //       type = "script"
    //       interval = "10s"
    //       timeout = "2s"
    //       name     = "Service registration through http"
    //       command = "curl" 
    //       args = ["-X", "PUT", "-d", "{\"name\":\"profile-hotel\", \"Port\":8081}", "http://localhost:8500/v1/agent/service/register"]
    //     }
    //   } 
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
        privileged = true
        command = "memcached"
        args = ["-p", "11213"]
        image = "memcached:1.6.9"
        // image = "memcached:1.6.9-alpine"
      //  image="bitnami/memcached:1.6.9"
        ports = ["mem-profile"]
      }
      service {
        name = "memcached-profile-hr"
        check {
          type = "script"
          interval = "10s"
          timeout = "2s"
          name     = "service registration through http"
          command = "curl" 
          args = ["-X", "PUT", "-d", "{\"name\":\"memcached-profile-hotel\", \"Port\":112113}", "http://localhost:8500/v1/agent/service/register"]
        }
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
      service {
        name = "mongodb-profile-hr"
        check {
          type = "script"
          interval = "10s"
          timeout = "2s"
          name     = "Service registration through http"
          command = "curl" 
          args = ["-X", "PUT", "-d", "{\"name\":\"mongodb-profile-hotel\", \"Port\":27019}", "http://localhost:8500/v1/agent/service/register"]
        }
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
      // service {
      //   name = "geo-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"geo-hotel\", \"Port\":8083}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 

    // }

    // task "mongodb-geo" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-geo"]
    //   }
      // service {
      //   name = "mongodb-geo-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"mongodb-geo\", \"Port\":27017}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
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
      // service {
      //   name = "rate-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"rate-hotel\", \"Port\":8084}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
    // }

    // task "memcached-rate" {
    //   driver = "docker"
      // service {
      //   name = "memcached-rate-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"memcached-rate-hotel\", \"Port\":11212}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 

    //     env {
    //       MEMCACHED_CACHE_SIZE = "128"
    //       MEMCACHED_THREADS    = "2"
    //     }
    //   config {
    //     image = "memcached:1.6.9"
    //     ports = ["mem-rate"]
    //     command = "memcached"
    //     args = ["-p", "11212"]
    //   }
    // }

    // task "mongodb-rate" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-rate"]
    //     command = "mongod"
    //     args = ["--port", "27020"]
    //   }
      // service {
      //   name = "mongodb-rate-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"mongodb-rate-hotel\", \"Port\":27020}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
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
      // service {
      //   name = "recommendation-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"recommendation-hotel\", \"Port\":8085}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
    // }

    // task "mongodb-recommendation" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-recommendation"]
    //     command = "mongod"
    //     args = ["--port", "27021"]
    //   }
      // service {
      //   name = "mongodb-recommendation-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"mongodb-recommendation-hotel\", \"Port\":27021}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
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
      // service {
      //   name = "user-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"user-hotel\", \"Port\":8086}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
    // }

    // task "mongodb-user" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-user"]
    //     command = "mongod"
    //     args = ["--port", "27023"]
    //   }
      // service {
      //   name = "mongodb-user-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"mongodb-user-hotel\", \"Port\":27023}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
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
      // service {
      //   name = "reservation-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"reservation-hotel\", \"Port\":8087}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
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
    //    command = "memcached"
    //    args = ["-p", "11214"]
    //   }
      // service {
      //   name = "memcached-reservation-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"memcached-reservation-hotel\", \"Port\":11214}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
    // }

    // task "mongodb-reserve" {
    //   driver = "docker"

    //   config {
    //     image = "mongo:4.4.6"
    //     ports = ["mongo-reservation"]
    //     command = "mongod"
    //     args = ["--port", "27022"]
    //   }
      // service {
      //   name = "mongodb-reservation-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"mongodb-reservation-hotel\", \"Port\":27022}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
    // }

    // task "search" {
    //   driver = "docker"

    //   config {
    //     image   = "stvdputten/hotel_reserv_search_single_node"
    //     command = "search"
    //     ports   = ["search"]
    //     mount {
    //       type   = "bind"
    //       target = "/go/src/github.com/harlow/go-micro-services/config.json"
    //       source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
    //     }
    //   }
      // service {
      //   name = "search-hr"
      //   check {
      //     type = "script"
      //     interval = "10s"
      //     timeout = "2s"
      //     name     = "Service registration through http"
      //     command = "curl" 
      //     args = ["-X", "PUT", "-d", "{\"name\":\"search-hotel\", \"Port\":8082}", "http://localhost:8500/v1/agent/service/register"]
      //   }
      // } 
    // }

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
          args = ["-X", "PUT", "-d", "{\"name\":\"jaeger-hotel\", \"Port\":6831}", "http://localhost:8500/v1/agent/service/register"]
        }
      } 
    }

  }
}