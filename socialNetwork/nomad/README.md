
# ports in nginx forwarded by service mesh
jaeger-agent: 6831 - ZIPKIN 9411
jaeger-agent-ui: 16686
user-mention-service: 9096
unique-id-service: 9099  
text-service: 9098
social-graph-service: 9091 - mongodb: 27020 - redis - 6382
compose-post-service: 9094 - redis 6380
home-timeline-service: 9095 - redis 6379
media-service: 9092 - mongodb: 27017 - memcached - 11211
user-service: 9090 - mongodb: 27018 - memcached - 11212
user-timeline-service: 9093 - mongodb 27019 - redis: 6381
post-storage-service: 9097 - mongodb: 27021 - memcached: 11214
url-shorten-service: 9100 - mongodb: 27022 - memcached - 11213 

# Overview ports and ip per group in nomad
/nginx-thrift
	/nginx-thrift
/media-frontend
	/media-frontend
/user-mention
	/user-mention-service
/unique-id
	/unique-id
/text
	/text-service
/compose-post
	/compose-post-service
/home-timeline
	/home-timeline-service
	/home-timeline-redis
/media
	/media-service
	/media-memcached
	/media-mongodb
/user
	/user-service
	/user-memcached
	/user-mongodb
/url-shorten
	/url-shorten-service
	/url-shorten-memcached
	/url-shorten-mongodb
/user-timeline
	/user-timeline-service
	/user-timeline-redis
	/user-timeline-mongodb
/post-storage
	/post-storage-service
	/post-storage-memcached
	/post-storage-mongodb
/social-graph
	/post-storage-service
	/post-storage-redis
	/post-storage-mongodb
/jaeger
	/jaeger