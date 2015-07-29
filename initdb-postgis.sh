#!/bin/sh

set -e

# Perform all actions as user 'postgres'
export PGUSER=postgres

# Create the 'template_postgis' template db
psql <<EOSQL
CREATE DATABASE template_postgis;
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
EOSQL

# Populate 'template_postgis'
cd /usr/share/postgresql/$PG_MAJOR/contrib/postgis-$POSTGIS_MAJOR
psql --dbname template_postgis < postgis.sql
psql --dbname template_postgis < topology.sql
psql --dbname template_postgis < spatial_ref_sys.sql

psql -c "CREATE DATABASE geocoder;"
mkdir -p /gisdata/temp
chmod 777 /gisdata

set -f 
psql --dbname geocoder <<'EOSQL'
CREATE EXTENSION postgis;   
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;
INSERT INTO tiger.loader_platform(os, declare_sect, pgbin, wget, unzip_command,
   psql, path_sep, 
   loader, environ_set_command, county_process_command)
   SELECT 'geocoder', 
'TMPDIR="${staging_fold}/temp/"
UNZIPTOOL="/usr/bin/unzip" 
WGETTOOL="/usr/bin/wget"
export PGBIN=/usr/lib/postgresql/${PG_MAJOR}/bin/
export PGPORT=5432
export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=postgres
export PGDATABASE=geocoder
PSQL=${PGBIN}/psql
SHP2PGSQL=/usr/bin/shp2pgsql
cd ${staging_fold}', 
   pgbin, wget, unzip_command, psql, path_sep, 
     loader, environ_set_command, county_process_command
   FROM tiger.loader_platform
   WHERE os = 'sh';
EOSQL

psql -d geocoder -o /gisdata/nation.sh -A -t -c "SELECT loader_generate_nation_script('geocoder');"
chmod +x /gisdata/nation.sh
