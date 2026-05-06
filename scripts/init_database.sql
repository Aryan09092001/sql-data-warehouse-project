/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three
    "schemas": 'bronze', 'silver', and 'gold'.
    
    NOTE: MySQL treats SCHEMA and DATABASE as synonyms, so bronze/silver/gold are created as
    SEPARATE DATABASES, not as schemas inside DataWarehouse. We use table name prefixes
    (e.g., bronze_customers) to simulate the medallion architecture.

WARNING:
    Running this script will drop the 'DataWarehouse', 'bronze', 'silver', and 'gold' databases
    if they exist. All data will be permanently deleted. Proceed with caution and ensure we
    have proper backups before running this script.
*/

-- Drop and recreate the 'DataWarehouse' database
DROP DATABASE IF EXISTS DataWarehouse;
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

-- Create "Schemas" (in MySQL these are separate databases)
DROP DATABASE IF EXISTS bronze;
CREATE DATABASE bronze;

DROP DATABASE IF EXISTS silver;
CREATE DATABASE silver;

DROP DATABASE IF EXISTS gold;
CREATE DATABASE gold;
