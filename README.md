# postgis-geocoder
Derived from https://github.com/appropriate/docker-postgis

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
```

If all you want to do is find out which state a latitude and longitude is in you
do not have to do anything else. If you want to actually geocode entire
addresses then you need the specific details TIGER Data for each state, this
involves a couple of steps, we will do the District of Columbia since it's small
```
docker exec some-postgis-geocoder psql -U postgres -d geocoder -o /gisdata/DC.sh -A -t -c "SELECT loader_generate_script(ARRAY['DC'], 'geocoder') AS result;"
docker exec some-postgis-geocoder chmod +x /gisdata/DC.sh
docker exec -it some-postgis-geocoder bash /gisdata/DC.sh
```
It will take a few minutes to download and install all the data. Once it
finishes you need to update the indexes:
```
docker exec some-postgis-geocoder psql -U postgis -d geocoder -c "SELECT install_missing_indexes();"
```
Now lets test and see if all of this works:
```
✗ docker exec -it tiger psql -d geocoder -U postgres
psql (9.3.9)
Type "help" for help.
#first lets find all states that overlap with a circle of radius 38558 meters
#from a latitude and longitude

geocoder=# SELECT z.name FROM tiger_data.state_all z
geocoder-#   WHERE ST_INTERSECTS(
geocoder(#     ST_Transform(
geocoder(# ST_Buffer(
geocoder(# ST_Transform(
geocoder(# ST_SetSRID(ST_MakePoint(-119.921619, 38.531740),4326), 26986)
geocoder(# ,38558,8),4269),
geocoder(#     z.the_geom);
    name
------------
 California
 Nevada
(2 rows)

#Now geocode an address into a latitude and longitude from a string

geocoder=# SELECT g.rating, ST_X(g.geomout) As lon, ST_Y(g.geomout) As lat,
geocoder-# (addy).address As stno, (addy).streetname As street,
geocoder-# (addy).streettypeabbrev As styp, (addy).location As city, (addy).stateabbrev As st,(addy).zip
geocoder-# FROM geocode('1600 Pennsylvania Ave NW, Washington, DC 20500') As g;
 rating |        lon        |       lat        | stno |    street    | styp |    city    | st |  zip
--------+-------------------+------------------+------+--------------+------+------------+----+-------
      2 | -77.0351147858455 | 38.8986709360362 | 1600 | Pennsylvania | Ave  | Washington | DC | 20502
(1 row)
geocoder-# \q
```

See [the PostGIS documentation](http://postgis.net/docs/postgis_installation.html#create_new_db_extensions)
for more details on your options for creating and using a spatially-enabled database.
