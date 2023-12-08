#!/bin/sh
# This script creates the Sqlite database, executing the DDL script
#
# Delete the old database:
rm cell_writer.db
#
# Create the database:
# we could run this from a data definition list file viz:
#   sqlite3 cell_writer.db < database_schema.ddl
# but we have already set up gnatcoll_db2ada
#gnatcoll_sqlite2ada -dbtype=sqlite -createdb -dbmodel=database_schema.dbmodel -dbname=cell_writer.db
gnatcoll_db2ada -dbtype=sqlite -createdb -dbmodel=database_schema.dbmodel -dbname=cell_writer.db

# Set up the blob fields to load.  Requires tobase64 to be on the search path.
#tobase64 -i 1.png -o 1.b64
tobase64 -i cellwriter.svg -o cell_writer.b64

# Load up the default data:
sqlite3 cell_writer.db < default_data.sql
echo "loaded default_data.sql"
sqlite3 cell_writer.db < word_data.sql
echo "loaded word_data.sql"
sqlite3 cell_writer.db < word_frequency_data.sql
echo "loaded word_frequency_data.sql"
sqlite3 cell_writer.db < default_reports.sql
echo "loaded default_reports.sql"

# Clean up the base 64 fields after them being used
rm *.b64

# Create the Ada packages for the database (database.ads, database.adb...)
#gnatcoll_sqlite2ada -dbtype=sqlite -api database -dbmodel=database_schema.dbmodel
gnatcoll_db2ada -dbtype=sqlite -api database -dbmodel=database_schema.dbmodel
# Add in dependency for GNATCOLL.SQL_Date_and_Time and GNATCOLL.SQL_Blob in
# with clauses at top of database.ads:
sed  -i '2i with GNATCOLL.SQL_Date_and_Time; use  GNATCOLL.SQL_Date_and_Time;' database.ads
sed  -i '2i with GNATCOLL.SQL_BLOB; use  GNATCOLL.SQL_BLOB;' database.ads
# In database.ads, Convert SQL_Field_Date to SQL_Field_tDate and convert
# SQL_Field_Time to SQL_Field_tTime.
sed -i 's/SQL_Field_Date/SQL_Field_tDate/g' database.ads
sed -i 's/SQL_Field_Time/SQL_Field_tTime/g' database.ads
# In database_names.ads, add in NC_Image and N_Image just before end of package
sed -i '143i   NC_Image : aliased constant String := """Image""";' database_names.ads
sed -i '144i   N_Image : constant Cst_String_Access := NC_Image'"'"'Access;' database_names.ads
# In database.ads, change 'Sample : SQL_Field_Text' to 'Sample : SQL_Field_Blob'
# at row 333 and row 364
sed -i 's/Sample : SQL_Field_Text/Sample : SQL_Field_Blob/g' database.ads
# In database.ads, add in Image : SQL_Field_Blob at row 94.
#sed -i '94i     Image : SQL_Field_Blob (Ta_Colourchart, Instance, N_Image, Index);' database.ads
#
# and move the Ada pacages to ../src
mv database.ad? ../src/
mv database_names.ads ../src/
