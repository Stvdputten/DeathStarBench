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
        to = 8500
      }
      port "dns" {
        static = 4001
        to     = 8600
      }
      port "frontend" {
        static = 5000
        to     = 5000
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

    task "frontend" {
      driver = "docker"

      config {
        image   = "stvdputten/hotel_reserv_frontend_single_node"
        command = "frontend"
        ports   = ["frontend"]
        // dns_servers = ["172.26.64.8"]
        mount {
          type   = "bind"
          target = "/go/src/github.com/harlow/go-micro-services/config.json"
          source = "/users/stvdp/DeathStarBench/hotelReservation/nomad/configmaps/config.json"
        }
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