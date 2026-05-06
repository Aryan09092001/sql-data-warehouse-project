/*
===============================================================================
Stored Procedure + Script: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This script loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses LOAD DATA LOCAL INFILE (MySQL) instead of BULK INSERT (SQL Server)
      to load data from csv files into bronze tables.
    - Prints progress messages and load durations for each table.
    - Reports total batch load time at the end.
    - Captures errors during truncation with a TRY/CATCH equivalent.

Parameters:
    None.
    This script does not accept any parameters or return any values.

Note on MySQL vs SQL Server:
    The SQL Server tutorial wraps everything in CREATE OR ALTER PROCEDURE
    bronze.load_bronze with BEGIN TRY ... BEGIN CATCH for error handling.
    MySQL on this build does NOT allow LOAD DATA INFILE inside stored
    procedures (Error 1314), so the work is split:
      - bronze.bronze_truncate_step (procedure) handles TRUNCATE,
        progress messages, and error handling via DECLARE HANDLER
        (the MySQL equivalent of BEGIN CATCH).
      - This script calls the procedure step-by-step between LOAD statements
        and tracks per-table + total batch timing.
    End result is functionally equivalent to the SQL Server version.

Usage Example:
    SQL Server:  EXEC bronze.load_bronze;
    MySQL:       Open this file in Workbench and press Ctrl + Shift + Enter
===============================================================================
*/

-- =============================================================
-- Part 1: Create the helper procedure (run once, persists in DB)
-- =============================================================
-- This procedure handles per-table truncation, progress messages,
-- AND error handling (the MySQL equivalent of SQL Server's
-- BEGIN TRY ... BEGIN CATCH block).

USE bronze;

DROP PROCEDURE IF EXISTS bronze.bronze_truncate_step;

DELIMITER $$

CREATE PROCEDURE bronze.bronze_truncate_step(IN p_table_name VARCHAR(100))
BEGIN
    -- ============================================================
    -- Error handler — MySQL equivalent of BEGIN CATCH ... END CATCH
    -- ============================================================
    -- If anything goes wrong inside this procedure, this handler
    -- fires. It captures the error code and message, prints them,
    -- then re-raises the error so the calling script knows it failed.
    DECLARE v_error_code INT DEFAULT 0;
    DECLARE v_error_msg TEXT DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_code = MYSQL_ERRNO,
            v_error_msg  = MESSAGE_TEXT;

        SELECT '==========================================' AS error_log
        UNION ALL SELECT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
        UNION ALL SELECT CONCAT('Error Number: ',  v_error_code)
        UNION ALL SELECT CONCAT('Error Message: ', v_error_msg)
        UNION ALL SELECT '==========================================';

        -- Re-throw the error so the calling script halts cleanly
        RESIGNAL;
    END;

    -- ============================================================
    -- Main logic — equivalent to BEGIN TRY ... END TRY block
    -- ============================================================
    SELECT CONCAT('>> Truncating Table: bronze.', p_table_name) AS status;

    -- Dynamic SQL is needed because TRUNCATE doesn't accept a
    -- variable as a table name directly.
    SET @sql = CONCAT('TRUNCATE TABLE bronze.', p_table_name);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT CONCAT('>> Inserting Data Into: bronze.', p_table_name) AS status;
END $$

DELIMITER ;


-- =============================================================
-- Part 2: The main load script (run this every time to refresh)
-- =============================================================

-- Track the batch start time (equivalent to @batch_start_time in SQL Server)
SET @batch_start_time = NOW();

SELECT '================================================' AS status
UNION ALL SELECT 'Loading Bronze Layer'
UNION ALL SELECT '================================================';

-- ---------- CRM Tables ----------

SELECT '------------------------------------------------' AS status
UNION ALL SELECT 'Loading CRM Tables'
UNION ALL SELECT '------------------------------------------------';

-- ---- crm_cust_info ----
SET @start_time = NOW();
CALL bronze.bronze_truncate_step('crm_cust_info');

LOAD DATA LOCAL INFILE 'F:/SQL/Data_Warehouse_Project/sql-data-warehouse-project-main/sql-data-warehouse-project-main/datasets/source_crm/cust_info.csv'
INTO TABLE bronze.crm_cust_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @end_time = NOW();
SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, @start_time, @end_time), ' seconds') AS status
UNION ALL SELECT '>> -------------';

-- ---- crm_prd_info ----
SET @start_time = NOW();
CALL bronze.bronze_truncate_step('crm_prd_info');

LOAD DATA LOCAL INFILE 'F:/SQL/Data_Warehouse_Project/sql-data-warehouse-project-main/sql-data-warehouse-project-main/datasets/source_crm/prd_info.csv'
INTO TABLE bronze.crm_prd_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @end_time = NOW();
SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, @start_time, @end_time), ' seconds') AS status
UNION ALL SELECT '>> -------------';

-- ---- crm_sales_details ----
SET @start_time = NOW();
CALL bronze.bronze_truncate_step('crm_sales_details');

LOAD DATA LOCAL INFILE 'F:/SQL/Data_Warehouse_Project/sql-data-warehouse-project-main/sql-data-warehouse-project-main/datasets/source_crm/sales_details.csv'
INTO TABLE bronze.crm_sales_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @end_time = NOW();
SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, @start_time, @end_time), ' seconds') AS status
UNION ALL SELECT '>> -------------';

-- ---------- ERP Tables ----------

SELECT '------------------------------------------------' AS status
UNION ALL SELECT 'Loading ERP Tables'
UNION ALL SELECT '------------------------------------------------';

-- ---- erp_loc_a101 ----
SET @start_time = NOW();
CALL bronze.bronze_truncate_step('erp_loc_a101');

LOAD DATA LOCAL INFILE 'F:/SQL/Data_Warehouse_Project/sql-data-warehouse-project-main/sql-data-warehouse-project-main/datasets/source_erp/loc_a101.csv'
INTO TABLE bronze.erp_loc_a101
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @end_time = NOW();
SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, @start_time, @end_time), ' seconds') AS status
UNION ALL SELECT '>> -------------';

-- ---- erp_cust_az12 ----
SET @start_time = NOW();
CALL bronze.bronze_truncate_step('erp_cust_az12');

LOAD DATA LOCAL INFILE 'F:/SQL/Data_Warehouse_Project/sql-data-warehouse-project-main/sql-data-warehouse-project-main/datasets/source_erp/cust_az12.csv'
INTO TABLE bronze.erp_cust_az12
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @end_time = NOW();
SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, @start_time, @end_time), ' seconds') AS status
UNION ALL SELECT '>> -------------';

-- ---- erp_px_cat_g1v2 ----
SET @start_time = NOW();
CALL bronze.bronze_truncate_step('erp_px_cat_g1v2');

LOAD DATA LOCAL INFILE 'F:/SQL/Data_Warehouse_Project/sql-data-warehouse-project-main/sql-data-warehouse-project-main/datasets/source_erp/px_cat_g1v2.csv'
INTO TABLE bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @end_time = NOW();
SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, @start_time, @end_time), ' seconds') AS status
UNION ALL SELECT '>> -------------';

-- =============================================================
-- Final batch summary
-- =============================================================

SET @batch_end_time = NOW();

SELECT '==========================================' AS status
UNION ALL SELECT 'Loading Bronze Layer is Completed'
UNION ALL SELECT CONCAT('   - Total Load Duration: ',
                        TIMESTAMPDIFF(SECOND, @batch_start_time, @batch_end_time),
                        ' seconds')
UNION ALL SELECT '==========================================';

-- =============================================================
-- Verify row counts
-- =============================================================

SELECT 'crm_cust_info' AS table_name, COUNT(*) AS rows_loaded FROM bronze.crm_cust_info
UNION ALL
SELECT 'crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL
SELECT 'crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL
SELECT 'erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
UNION ALL
SELECT 'erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
UNION ALL
SELECT 'erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2;
