
# ports in nginx forwarded by service mesh
jaeger-agent: 6831 - ZIPKIN 9411
jaeger-agent-ui: 16686
user-service: 9090
social-graph-service: 9091
media-service: 9092
user-timeline-service: 9093
compose-post-service: 9094
home-timeline-service: 9095
user-mention-service: 9096
post-storage-service: 9097
text-service: 9098
unique-id-service: 9099
url-shorten-service: 9100

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
/compose-post
	/compose-post-service
/home-timeline
	/post-storage-service
	/post-storage-redis
	/post-storage-mongodb
/social-graph
	/post-storage-service
	/post-storage-redis
	/post-storage-mongodb
/jaeger
	/jaeger