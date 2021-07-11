job "social-network" {
    datacenters = ["dc1"]

    group "social-graph" {
        task "social-graph-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "SocialGraphService" 
            }
        } 

        task "social-graph-mongodb" {
            driver = "docker"
            
            config {
                image = "mongo"
            }
        }

        task "social-graph-redis" {
            driver = "docker"
            
            config {
                image = "redis"
            }
        }

    }

    group "write-home-timeline" {
        // task "write-home-timeline-service" {
        //     config {
        //         image = "yg397/social-network-microservices"
        //         entrypoint = "WriteHomeTimelineService"
        //     }
        // }

        // task "write-home-timeline-rabbitmq" {
        //     config {
        //         image = "yg397/social-network-microservices"
                
        //     }

        //     env {
        //         RABBITMQ_ERLANG_COOKIE = "WRITE-HOME-TIMELINE-RABBITMQ",
        //         RABBITMQ_DEFAULT_VHOST = "/"
        //     }


        //     lifecycle {
        //         hook = "prestart"
        //         sidecar = false
        //     }
        // }

        

        task "compose-post-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "ComposePostService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }

        task "compose-post-redis" {
            driver = "docker"

            config {
                image = "redis"
            }

        }


    } 

    group "post-storage" {
        task "post-storage-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "PostStorageService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }

        task "post-storage-memcached" {
            driver = "docker"

            config {
                image = "memcached"
            }
        }

        task "post-storage-mongodb" {
            driver = "docker"

            config {
                image = "mongo"
            }
        }
    }

    group "user-timeline" {
        task "user-timeline-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "UserTimelineService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }

        task "post-storage-redis" {
            driver = "docker"

            config {
                image = "redis"
            }
        }

        task "post-storage-mongodb" {
            driver = "docker"

            config {
                image = "mongo"
            }
        }
    }

    group "url-shorten" {
        task "url-shorten-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "UrlShortenService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }

        task "url-shorten-memcached" {
            driver = "docker"

            config {
                image = "memcached"
            }
        }

        task "url-shorten-mongodb" {
            driver = "docker"

            config {
                image = "mongo"
            }
        }
    }

    group "user" {
        task "user-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "UserService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }

        task "user-memcached" {
            driver = "docker"

            config {
                image = "memcached"
            }
        }

        task "user-mongodb" {
            driver = "docker"

            config {
                image = "mongo"
            }
        }
    }

    group "media" {
        task "media-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "MediaService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }

        task "media-memcached" {
            driver = "docker"

            config {
                image = "memcached"
            }
        }

        task "media-mongodb" {
            driver = "docker"

            config {
                image = "mongo"
            }
        }
    }

    group "text" {
        task "text-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "TextService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }
    }

    group "unique-id" {
        task "unique-id-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices"
                entrypoint = "UniqueIdService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }
    }

    group "user-mention" {
        task "user-mention-service" {
            driver = "docker"
            
            config {
                image = "yg397/social-network-microservices"
                entrypoint = "UserMentionService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        }
    }

    group "home-timeline" {

        task "home-timeline-service" {
            driver = "docker"

            config {
                image = "yg397/social-network-microservices" 
                entrypoint = "HomeTimelineService"
                volumes = [
                    "./config:/social-network-microservices/config"
                ]
            }
        } 

        task "home-timeline-redis" {
            driver = "docker"

            config {
                image = "redis"
            }
        }
    }

    group "frontend" {
        network {
            port "nginx" {}
            port "media" {
                static = 8081
                to = 8080
            }
            port "jaeger" {}
        }

        task "nginx-thrift" {
            driver = "docker"

            config {
                image = "yg397/openresty-thrift:xenial" 
                ports = ["nginx"]
                volumes = [
                    "./nginx-web-server/lua-scripts:/usr/local/openresty/nginx/lua-scripts",
                    "./nginx-web-server/pages:/usr/local/openresty/nginx/pages",
                    "./nginx-web-server/conf/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf",
                    "./nginx-web-server/jaeger-config.json:/usr/local/openresty/nginx/jaeger-config.json",
                    "./gen-lua:/gen-lua"
                ]
            }
        } 

        task "media-frontend" {
            driver = "docker"

            config {
                image = "yg397/openresty-thrift:xenial" 
                ports = ["media"]
                volumes = [
                    "./media-frontend/lua-scripts:/usr/local/openresty/nginx/lua-scripts",
                    "./media-frontend/conf/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf"
                ]
            }
        }

        task "jaeger" {
            driver = "docker"

            config {
                image = "jaegertracing/all-in-one:latest" 
                ports = ["jaeger"]
            }
            env {
                COLLECTOR_ZIPKIN_HTTP_PORT = "9411"
            }
        }  
    }  

}