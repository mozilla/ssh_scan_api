docker-compose build --no-cache && \
docker stop $(docker ps -a -q) && \
# For debug only...
# docker-compose up
docker-compose up -d --scale base=0 --scale database=1 --scale api=1 --scale worker=3 --no-recreate