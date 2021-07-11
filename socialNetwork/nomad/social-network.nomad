job "social-network" {
  datacenters = ["dc1"]

	// group "social-graph" {

	// 	restart {
	// 		attempts = 2
	// 		delay = "15s"
	// 		mode = "fail"
	// 	}

	// 	// resources {
	// 	// network {
	// 	// 	mode = "bridge"

	// 	// 	port "jaeger_ui" {
	// 	// 		static = 16686
	// 	// 		// to = 16686
	// 	// 	}
	// 	// }
	// 	// }

	// 	service {
	// 		name = "social-graph-service"
	// 		// port = "jaeger_ui"
	// 	}




	// } 

	group "social-network" {

		// restart {
		// 	attempts = 2
		// 	delay = "15s"
		// 	mode = "fail"
		// }

		network {
			mode = "bridge"

			port "db_r" {
				to = 6379
			}

			port "db_m" {
				to = 27017
			}
			port "http" {
			}

			port "jaeger_ui" {
				static = 16686
				to = 16686
			}
		}

		task "social-graph-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "SocialGraphService"
				mount {
					type = "bind"
					target = "/keys"
					source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
				}
				mount {
					type = "bind"
					target = "/social-network-microservices/config"
					source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
				}
			}
			// https://www.nomadproject.io/docs/integrations/consul-connect

		}

		task "social-graph-mongodb" {
			driver = "docker"
			config {
				image = "mongo:4.4.6"
				// entrypoint = "mongod"
				command = "mongod"
				args = [
				 	"--config /social-network-microservices/config/mongod.conf"
				 ]
				mount {
					type = "bind"
					target = "/keys"
					source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
				}
				mount {
					type = "bind"
					target = "/social-network-microservices/config"
					source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
				}
			}

			service {
				name = "mongodb"
				tags = ["db_m"]
				port = "db_m"
				// port = "27017"
				// connect {        
				// 	 sidecar_service {}      
				// }
				// port = "http"

				check {
					type = "tcp"
					interval = "10s"
					timeout = "4s"
				}
			}
		}

		task "social-graph-redis" {
			driver = "docker"
			config {
				image = "redis:alpine3.13"
				mount {
					type = "bind"
					target = "/keys"
					source = "/users/stvdp/DeathStarBench/socialNetwork/keys"
				}
				mount {
					type = "bind"
					target = "/social-network-microservices/config"
					source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/config"
				}
				command = "redis-server"
				args = [
					"/social-network-microservices/config/redis.conf"
				]
			}

			service {
				name = "social-graph-redis"
				tags = ["db_r"]
				port = "db_r"
				// port = "6379"
				// port = "http"
				// connect {        
				// 	 sidecar_service {}      
				// }
				check {
					type = "tcp"
					interval = "10s"
					timeout = "4s"
				}
			}
		}

		task "jaeger" {
			driver = "docker"
			config {
				image = "jaegertracing/all-in-one:1.23.0"
			}
			service {
				name = "jaeger-agent"
				port = "jaeger_ui"
				// port = "http"
			}
			env {
				COLLECTOR_ZIPKIN_HTTP_PORT="9411"
			}

		}


	} 

}