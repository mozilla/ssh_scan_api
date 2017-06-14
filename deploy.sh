docker-compose build && \
docker stop $(docker ps -a -q) && \
docker-compose scale database=1 api=1 worker=1