#!/bin/sh
# This script creates the Sqlite database, executing the DDL script
#
# Create the database:
# we could run this from a data definition list file viz:
#   sqlite3 cell_writer.db < database_schema.ddl
# but we have already set up gnatcoll_db2ada
gnatcoll_sqlite2ada -dbtype=sqlite -createdb -dbmodel=database_schema.dbmodel -dbname=cell_writer.db

# Set up the blob fields to load.  Requires tobase64 to be on the search path.
tobase64 -i 1.png -o 1.b64
tobase64 -i ../src/cell_writer.png -o cell_writer.b64

# Load up the default data:
/usr/local/bin/sqlite3 cell_writer.db < default_data.sql
sqlite3 cell_writer.db < default_reports.sql

# Clean up the base 64 fields after them being used
rm *.b64

# Create the Ada packages for the database (database.ads, database.adb...)
gnatcoll_sqlite2ada -dbtype=sqlite -api database -dbmodel=database_schema.dbmodel
# Add in dependency for GNATCOLL.SQL_Blob in with clauses at top of database.ads:
sed  -i '2i with GNATCOLL.SQL_BLOB; use  GNATCOLL.SQL_BLOB;' database.ads
# In database_names.ads, add in NC_Image and N_Image just before end of package
sed -i '115i   NC_Image : aliased constant String := """Image""";' database_names.ads
sed -i '116i   N_Image : constant Cst_String_Access := NC_Image'"'"'Access;' database_names.ads
# In database.ads, add in Image : SQL_Field_Blob at row 94.
#sed -i '94i     Image : SQL_Field_Blob (Ta_Colourchart, Instance, N_Image, Index);' database.ads
#
# and move the Ada pacages to ../src
#mv database.ad? ../src/
#mv database_names.ads ../src/
