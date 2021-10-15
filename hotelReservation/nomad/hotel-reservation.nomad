job "hotel-reservation" {
  datacenters = ["dc1"]

  group "hotel-reservation" {
    network {
      mode = "bridge"
      port "http" {
        static = 5000
        to     = 5000
      }
      port "dns" {
        // static = 53
        to = 8600
      }
    }

    task "consul" {
      driver = "docker"
      service { 
        name = "hr-consul-docker"
      }

      config {
        image        = "consul:1.9.6"
        // network_mode = "bridge"
        ports = ["dns"]
          // ["8300/tcp"] = 8300
          // ["8400/tcp"] = 8400
          // ["8500/tcp"] = 8500
          // ["8300/udp"] = 8300
          // ["8400/udp"] = 8400
          // ["8500/udp"] = 8500
          // ["8600/udp"] = 8600
      }
    }

    task "frontend" {
      driver = "docker"

      config {
        image        = "stvdputten/hotel_reserv_frontend_single+node"
        command = "frontend"
        ports = ["http"]
      }
    }
  }
}