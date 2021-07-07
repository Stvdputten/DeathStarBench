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

		restart {
			attempts = 2
			delay = "15s"
			mode = "fail"
		}

		// resources {
		network {
			// mode = "bridge"

			port "jaeger_ui" {
				static = 16686
				to = 16686
			}
		}
		// }


		// task "social-graph-service" {
		// 	driver = "docker"
		// 	config {
		// 		image = "stvdputten/social-network-microservices:latest"
		// 		// entrypoint = "SocialGraphService"
		// 		command = "SocialGraphService"
		// 		volumes = [
		// 				"./config:/social-network-microservices/config",
		// 				"./keys:/keys"
		// 		]
		// 	}

		// }

		// task "social-graph-mongodb" {
		// 	driver = "docker"
		// 	config {
		// 		image = "mongo:4.4.6"
				// entrypoint = "SocialGraphService"
				// command = "--config /social-network-microservices/config/mongod.conf"
				// volumes = [
				// 		"/home/stvdputten/Documents/Orchestration/Hashi/NomadConsul/local/DeathStarBench/socialNetwork/config:/social-network-microservices/config",
				// 		"/home/stvdputten/Documents/Orchestration/Hashi/NomadConsul/local/DeathStarBench/socialNetwork/keys:/keys"
				// ]
			// }
			// service {
			// 	name = "mongodb"
            //      tags = ["db_m"]
            //      port = "db_m"
            //      check {
            //           type = "tcp"
            //           interval = "10s"
            //           timeout = "4s"
            //  }
			// }
			

		// }

		task "jaeger" {
			driver = "docker"
			config {
				image = "jaegertracing/all-in-one:1.23.0"
			}
			service {
				name = "jaeger-tracing"
				port = "jaeger_ui"
			}

		}


	} 

}