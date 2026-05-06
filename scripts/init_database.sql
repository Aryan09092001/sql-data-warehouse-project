/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script sets up a database called 'DataWarehouse'. If a database
    with that name already exists, it gets removed first and then created
    again from scratch. The script also sets up three "schemas" named
    'bronze', 'silver', and 'gold'.

    NOTE: In MySQL, SCHEMA and DATABASE mean the same thing, so
    bronze/silver/gold end up as INDEPENDENT DATABASES rather than
    schemas living inside DataWarehouse. To mimic the medallion
    architecture, we rely on table name prefixes (for example,
    bronze_customers) instead.

WARNING:
    Executing this script will erase the 'DataWarehouse', 'bronze',
    'silver', and 'gold' databases if they are already present. Every
    piece of data inside them will be lost for good. Move carefully
    and confirm we have backups in place before we run this.
*/

-- Wipe out and rebuild the 'DataWarehouse' database
DROP DATABASE IF EXISTS DataWarehouse;
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

-- Set up the "Schemas" (which in MySQL are actually separate databases)
DROP DATABASE IF EXISTS bronze;
CREATE DATABASE bronze;

DROP DATABASE IF EXISTS silver;
CREATE DATABASE silver;

DROP DATABASE IF EXISTS gold;
CREATE DATABASE gold;
