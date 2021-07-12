job "social-network" {
 	datacenters = ["dc1"]

	group "media-frontend" {
		 count = 1
		 network {
			 mode = "bridge"
			 port "http" {
				static = 8081
				to = 8080
			 }	
		 }
		 task "media-frontend" {
			 driver = "docker"

			 config {
				 image = "yg397/media-frontend:xenial"
			 }
			mount {
				type = "bind"
				target = "/usr/local/openresty/nginx/lua-scripts"
				source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/media-frontend/lua-scripts"
			}
			mount {
				type = "bind"
				target = "/usr/local/openresty/nginx/conf/nginx.conf"
				source = "/users/stvdp/DeathStarBench/socialNetwork/nomad/media-frontend/conf/nginx.conf"
			}
		 }
	 }

	group "user-mention" {
		count = 1
		network {
			mode = "bridge"
			port "http" { }
		}

		task "user-mention-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "UserMentionService"
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
				name = "user-mention-service"
				port = "http"
			}
		}
	}


	group "unique-id" {
		count = 1
		network {
			mode = "bridge"
			port "http" { }
		}

		task "unique-id" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "UniqueIdService"
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
				name = "unique-id-service"
				port = "http"
			}
		}
	}

	group "text" {
		count = 1
		network {
			mode = "bridge"
			port "http" { }
		}

		task "text-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "TextService"
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
				name = "text-service"
				port = "http"
			}
		}
	}

	group "media" {
		network {
			mode = "bridge"
			port "http" { }
		}
		count = 1

		task "media-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "MediaService"
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
				name = "media-service"
				port = "http"
			}
		}

		task "media-memcached" {
			driver = "docker"
			config {
				image = "memcached:1.6.9"
			}
			service {
				name = "media-memcached"
				tags = ["db_mem"]
				port = "http"
			}
		}

		task "media-mongodb" {
			driver = "docker"
			config {
				image = "mongo:4.4.6"
				command = "mongod"
				args = [
					"--config",
					"/social-network-microservices/config/mongodb.conf"
				]
			}
			service {
				name = "media-mongodb"
				port = "http"
			}
		}
	}

	group "user" {
		network {
			mode = "bridge"
			port "http" { }
		}

		task "user-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "UserService"
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
				name = "user-service"
				port = "http"
			}
		}

		task "user-memcached" {
			driver = "docker"
			config {
				image = "memcached:1.6.9"
			}
			service {
				name = "user-memcached"
				tags = ["db_mem"]
				port = "http"
			}
		}

		task "user-mongodb" {
			driver = "docker"
			config {
				image = "mongo:4.4.6"
				command = "mongod"
				args = [
					"--config",
					"/social-network-microservices/config/mongodb.conf"
				]
			}
			service {
				name = "user-mongodb"
				port = "http"
			}
		}
	}

	group "url-shorten" {
		network {
			mode = "bridge"
			port "http" { }
		}
		
		task "url-shorten-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "UrlShortenService"
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
				name = "url-shorten-service"
				port = "http"
			}
		}

		task "url-shorten-mongodb" {
			driver = "docker"
			config {
				image = "mongo:4.4.6"
				command = "mongod"
				args = [
					"--config",
					"/social-network-microservices/config/mongodb.conf"
				]
			}
			service {
				name = "url-shorten-mongodb"
				port = "http"
			}
		}

		task "url-shorten-memcached" {
			driver = "docker"
			config {
				image = "memcached:1.6.9"
			}

			service {
				name = "url-shorten-memcached"
				tags = ["db_r"]
				port = "http"
			}
		}
	}

	group "user-timeline" {
		network {
			mode = "bridge"
			port "http" { }
		}
		
		task "user-timeline-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "UserTimelineService"
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
				name = "user-timeline-service"
				port = "http"
			}
		}

		task "user-timeline-mongodb" {
			driver = "docker"

			config {
				image = "mongo:4.4.6"
				command = "mongod"
				args = [
					"--config",
					"/social-network-microservices/config/mongodb.conf"
				]
			}
			service {
				name = "user-timeline-mongodb"
				port = "http"
			}
		}

		task "user-timeline-redis" {
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
				name = "user-timeline-redis"
				tags = ["db_r"]
				port = "http"
			}
		}
	}

	group "post-storage" {
		network {
			mode = "bridge"
			port "http" { }
		}
		
		task "post-storage-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "PostStorageService"
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
				name = "post-storage-service"
				port = "http"
			}
		}

		task "post-storage-memcached" {
			driver = "docker"

			config {
				image = "memcached:1.6.9"
			}
			service {
				name = "post-storage-memcached"
				port = "http"
			}
		}

		task "post-storage-mongodb" {
			driver = "docker"

			config {
				image = "mongo:4.4.6"
				command = "mongod"
				args = [
					"--config",
					"/social-network-microservices/config/mongodb.conf"
				]
			}
			service {
				name = "post-storage-mongodb"
				port = "http"
			}
		}
	}

	group "compose-post" {

		network {
			mode = "bridge"
			port "http" { }
		}
		
		task "compose-post-service" {
			driver = "docker"

			config {
				image = "stvdputten/social-network-microservices:latest"
				command = "ComposePostService"
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
				name = "compose-post-service"
				tags = ["cp_service"]
				port = "http"
			}
		}

	}


	// } 
	group "home-timeline" {
		network {
			mode = "bridge"

			port "http" { }
		}

		task "home-timeline-service" {
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

			service {
				name = "home-timeline-service"
				tags = ["sg_service"]
				port = "http"
				// check {
				// 	type = "tcp"
				// 	interval = "10s"
				// 	timeout = "4s"
				// }
			// https://www.nomadproject.io/docs/integrations/consul-connect
			}
		}

		task "home-timeline-mongodb" {
			driver = "docker"
			config {
				image = "mongo:4.4.6"
				command = "mongod"
				args = [
				 	"--config",
					"/social-network-microservices/config/mongod.conf"
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
				name = "home-timeline-mongodb"
				tags = ["db_m"]
				port = "http"
				// check {
				// 	type = "tcp"
				// 	interval = "10s"
				// 	timeout = "4s"
				// }
			}
		}

		task "home-timeline-redis" {
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
				name = "home-timeline-redis"
				tags = ["db_r"]
				port = "http"

				// check {
				// 	type = "tcp"
				// 	interval = "10s"
				// 	timeout = "4s"
				// }
			}
		}

	} 


	group "social-network" {

		network {
			mode = "bridge"

			port "http" { }
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

			service {
				name = "social-graph-service"
				tags = ["sg_service"]
				port = "http"
				// check {
				// 	type = "tcp"
				// 	interval = "10s"
				// 	timeout = "4s"
				// }
			// https://www.nomadproject.io/docs/integrations/consul-connect
			}
		}

		task "social-graph-mongodb" {
			driver = "docker"
			config {
				image = "mongo:4.4.6"
				command = "mongod"
				args = [
				 	"--config",
					"/social-network-microservices/config/mongod.conf"
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
				name = "social-graph-mongodb"
				tags = ["db_m"]
				port = "http"
				// check {
				// 	type = "tcp"
				// 	interval = "10s"
				// 	timeout = "4s"
				// }
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
				port = "http"

				// check {
				// 	type = "tcp"
				// 	interval = "10s"
				// 	timeout = "4s"
				// }
			}
		}

	} 

	group "jaeger"{
		network {
			mode = "bridge"

			port "http" {
				static = 16686
			 }
		}

		task "jaeger" {
			driver = "docker"
			config {
				image = "jaegertracing/all-in-one:1.23.0"
			}
			service {
				name = "jaeger-agent"
				port = "http"
			}
			env {
				COLLECTOR_ZIPKIN_HTTP_PORT="9411"
			}
		}
	}
}