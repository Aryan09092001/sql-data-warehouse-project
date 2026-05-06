/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
    Actions Performed:
        - Truncates Silver tables.
        - Inserts transformed and cleansed data from Bronze into Silver tables.
        - Tracks per-table load durations and total batch duration.
        - Captures errors via DECLARE HANDLER (MySQL equivalent of TRY/CATCH).

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    SQL Server:  EXEC silver.load_silver;
    MySQL:       CALL silver.load_silver();

Note on MySQL vs SQL Server differences handled in this script:
    - GETDATE()                 → NOW()
    - DATEDIFF(SECOND, a, b)    → TIMESTAMPDIFF(SECOND, a, b)
    - PRINT 'message'           → SELECT 'message' (MySQL has no PRINT)
    - CAST(x AS NVARCHAR)       → CONCAT() does auto-conversion
    - ISNULL(value, default)    → IFNULL(value, default)
    - LEN(string)               → CHAR_LENGTH(string)
    - date - 1                  → DATE_SUB(date, INTERVAL 1 DAY)
    - CAST(x AS VARCHAR)        → CAST(x AS CHAR)
    - BEGIN TRY / BEGIN CATCH   → DECLARE EXIT HANDLER FOR SQLEXCEPTION
    - CREATE OR ALTER PROCEDURE → DROP PROCEDURE IF EXISTS + CREATE PROCEDURE
===============================================================================
*/

USE silver;

-- Drop the old version if it exists (MySQL equivalent of CREATE OR ALTER)
DROP PROCEDURE IF EXISTS silver.load_silver;

-- Switch the statement delimiter so semicolons inside the procedure
-- don't end the CREATE statement prematurely
DELIMITER $$

CREATE PROCEDURE silver.load_silver()
BEGIN

    -- ============================================================
    -- Variables for tracking timing across the procedure
    -- ============================================================
    DECLARE v_start_time       DATETIME;
    DECLARE v_end_time         DATETIME;
    DECLARE v_batch_start_time DATETIME;
    DECLARE v_batch_end_time   DATETIME;

    -- ============================================================
    -- Error handler — MySQL equivalent of BEGIN CATCH ... END CATCH
    -- ============================================================
    DECLARE v_error_code INT DEFAULT 0;
    DECLARE v_error_msg  TEXT DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_code = MYSQL_ERRNO,
            v_error_msg  = MESSAGE_TEXT;

        SELECT '==========================================' AS error_log
        UNION ALL SELECT 'ERROR OCCURED DURING LOADING SILVER LAYER'
        UNION ALL SELECT CONCAT('Error Number: ',  v_error_code)
        UNION ALL SELECT CONCAT('Error Message: ', v_error_msg)
        UNION ALL SELECT '==========================================';

        -- Re-throw the error so the caller knows the procedure failed
        RESIGNAL;
    END;

    -- ============================================================
    -- Main logic — equivalent to BEGIN TRY ... END TRY block
    -- ============================================================

    SET v_batch_start_time = NOW();

    SELECT '================================================' AS status
    UNION ALL SELECT 'Loading Silver Layer'
    UNION ALL SELECT '================================================';

    SELECT '------------------------------------------------' AS status
    UNION ALL SELECT 'Loading CRM Tables'
    UNION ALL SELECT '------------------------------------------------';

    -- ============================================================
    -- Loading silver.crm_cust_info
    -- ============================================================
    SET v_start_time = NOW();
    SELECT '>> Truncating Table: silver.crm_cust_info' AS status;
    TRUNCATE TABLE silver.crm_cust_info;

    SELECT '>> Inserting Data Into: silver.crm_cust_info' AS status;
    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname)  AS cst_lastname,
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END AS cst_marital_status,                                    -- Normalize marital status values to readable format
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END AS cst_gndr,                                              -- Normalize gender values to readable format
        cst_create_date
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;                                              -- Select the most recent record per customer

    SET v_end_time = NOW();
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, v_start_time, v_end_time), ' seconds') AS status
    UNION ALL SELECT '>> -------------';

    -- ============================================================
    -- Loading silver.crm_prd_info
    -- ============================================================
    SET v_start_time = NOW();
    SELECT '>> Truncating Table: silver.crm_prd_info' AS status;
    TRUNCATE TABLE silver.crm_prd_info;

    SELECT '>> Inserting Data Into: silver.crm_prd_info' AS status;
    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,        -- Extract category ID
        SUBSTRING(prd_key, 7, CHAR_LENGTH(prd_key)) AS prd_key,       -- Extract product key (LEN -> CHAR_LENGTH)
        prd_nm,
        IFNULL(prd_cost, 0) AS prd_cost,                              -- Replace NULL cost with 0 (ISNULL -> IFNULL)
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,                                              -- Map product line codes to descriptive values
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        DATE_SUB(
            LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt),
            INTERVAL 1 DAY
        ) AS prd_end_dt                                               -- Calculate end date as one day before the next start date

    FROM bronze.crm_prd_info;

    SET v_end_time = NOW();
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, v_start_time, v_end_time), ' seconds') AS status
    UNION ALL SELECT '>> -------------';

    -- ============================================================
    -- Loading silver.crm_sales_details
    -- ============================================================
    SET v_start_time = NOW();
    SELECT '>> Truncating Table: silver.crm_sales_details' AS status;
    TRUNCATE TABLE silver.crm_sales_details;

    SELECT '>> Inserting Data Into: silver.crm_sales_details' AS status;
    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
            WHEN sls_order_dt = 0 OR CHAR_LENGTH(CAST(sls_order_dt AS CHAR)) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS CHAR) AS DATE)
        END AS sls_order_dt,
        CASE
            WHEN sls_ship_dt = 0 OR CHAR_LENGTH(CAST(sls_ship_dt AS CHAR)) != 8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS CHAR) AS DATE)
        END AS sls_ship_dt,
        CASE
            WHEN sls_due_dt = 0 OR CHAR_LENGTH(CAST(sls_due_dt AS CHAR)) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS CHAR) AS DATE)
        END AS sls_due_dt,
        CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,                                             -- Recalculate sales if original value is missing or incorrect
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price                                            -- Derive price if original value is invalid
        END AS sls_price
    FROM bronze.crm_sales_details;

    SET v_end_time = NOW();
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, v_start_time, v_end_time), ' seconds') AS status
    UNION ALL SELECT '>> -------------';

    -- ============================================================
    -- Loading silver.erp_cust_az12
    -- ============================================================
    SET v_start_time = NOW();
    SELECT '>> Truncating Table: silver.erp_cust_az12' AS status;
    TRUNCATE TABLE silver.erp_cust_az12;

    SELECT '>> Inserting Data Into: silver.erp_cust_az12' AS status;
    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, CHAR_LENGTH(cid))    -- Remove 'NAS' prefix if present
            ELSE cid
        END AS cid,
        CASE
            WHEN bdate > NOW() THEN NULL
            ELSE bdate
        END AS bdate,                                                 -- Set future birthdates to NULL
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
            ELSE 'n/a'
        END AS gen                                                    -- Normalize gender values and handle unknown cases
    FROM bronze.erp_cust_az12;

    SET v_end_time = NOW();
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, v_start_time, v_end_time), ' seconds') AS status
    UNION ALL SELECT '>> -------------';

    SELECT '------------------------------------------------' AS status
    UNION ALL SELECT 'Loading ERP Tables'
    UNION ALL SELECT '------------------------------------------------';

    -- ============================================================
    -- Loading silver.erp_loc_a101
    -- ============================================================
    SET v_start_time = NOW();
    SELECT '>> Truncating Table: silver.erp_loc_a101' AS status;
    TRUNCATE TABLE silver.erp_loc_a101;

    SELECT '>> Inserting Data Into: silver.erp_loc_a101' AS status;
    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry                                                  -- Normalize and handle missing or blank country codes
    FROM bronze.erp_loc_a101;

    SET v_end_time = NOW();
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, v_start_time, v_end_time), ' seconds') AS status
    UNION ALL SELECT '>> -------------';

    -- ============================================================
    -- Loading silver.erp_px_cat_g1v2
    -- ============================================================
    SET v_start_time = NOW();
    SELECT '>> Truncating Table: silver.erp_px_cat_g1v2' AS status;
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    SELECT '>> Inserting Data Into: silver.erp_px_cat_g1v2' AS status;
    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;

    SET v_end_time = NOW();
    SELECT CONCAT('>> Load Duration: ', TIMESTAMPDIFF(SECOND, v_start_time, v_end_time), ' seconds') AS status
    UNION ALL SELECT '>> -------------';

    -- ============================================================
    -- Final batch summary
    -- ============================================================
    SET v_batch_end_time = NOW();

    SELECT '==========================================' AS status
    UNION ALL SELECT 'Loading Silver Layer is Completed'
    UNION ALL SELECT CONCAT('   - Total Load Duration: ',
                            TIMESTAMPDIFF(SECOND, v_batch_start_time, v_batch_end_time),
                            ' seconds')
    UNION ALL SELECT '==========================================';

END $$

DELIMITER ;

-- CALL silver.load_silver(); --
/*
SELECT 'crm_cust_info' AS table_name, COUNT(*) AS rows_loaded FROM silver.crm_cust_info
UNION ALL SELECT 'crm_prd_info',     COUNT(*) FROM silver.crm_prd_info
UNION ALL SELECT 'crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'erp_loc_a101',      COUNT(*) FROM silver.erp_loc_a101
UNION ALL SELECT 'erp_cust_az12',     COUNT(*) FROM silver.erp_cust_az12
UNION ALL SELECT 'erp_px_cat_g1v2',   COUNT(*) FROM silver.erp_px_cat_g1v2;
*/

