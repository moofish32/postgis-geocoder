# postgis-geocoder

[![Build Status](https://travis-ci.org/moofish32/postgis-geocoder.svg)](https://travis-ci.org/moofish32/postgis-geocoder) 

The `postgis-geocoder` image provides a Docker container running Postgres 9 with
[PostGIS 2.1](http://postgis.net/docs/manual-2.1/) installed. This image is
based on the official [`postgres`](https://registry.hub.docker.com/_/postgres/)
image and provides variants for each version of Postgres 9 supported by the
base image (9.1-9.4).

On the version 9.1+ images, the PostGIS extensions can be installed into your
database in [the standard way](http://postgis.net/docs/postgis_installation.html#create_new_db_extensions) via `psql`:

```SQL
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION postgis;   
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;
```

If prefer to use the older template database
mechanism for installing PostGIS, the image also provides a `template_postgis` template
database with `postgis.sql`, `topology.sql`, and `spatial_ref_sys.sql` loaded.

## Usage

In order to run a basic container capable of serving a PostGIS-enabled database,
start a container as follows:

    docker run --name some-postgis-geocoder -e POSTGRES_PASSWORD=mysecretpassword -d moofish32/postgis-geocoder

For more detailed instructions about how to start and control your Postgres
container, see the documentation for the `postgres` image
[here](https://registry.hub.docker.com/_/postgres/).

Once you have started a database container, you are going to want to set up the
TIGER Line data. The data is large and not included in the container directly.
The first step is the national data and can be run by:

```
docker exec -it some-postgis-geocoder bash /gisdata/nation.sh

    docker run -it --link some-postgis:postgres --rm postgres \
        sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres'

Using the resulting `psql` shell, you can create a PostGIS-enabled database by
using the `CREATE EXTENSION` mechanism (or by using `template_postgis` for Postgres 9.0):

```SQL
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
```

See [the PostGIS documentation](http://postgis.net/docs/postgis_installation.html#create_new_db_extensions)
for more details on your options for creating and using a spatially-enabled database.
