FROM mdillon/postgis:9.3
MAINTAINER Mike Cowgill <moofish32@gmail.com>

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
