/*
===============================================================================
Silver Layer Data Quality Checks
===============================================================================
Purpose:
    Runs a battery of validation queries against the 'silver' layer to verify
    data consistency, correctness, and standardization. The checks cover:
    - Missing or duplicated primary key values.
    - Stray leading/trailing whitespace in text columns.
    - Standardized values across categorical fields.
    - Logical date ranges and chronological ordering.
    - Cross-field consistency for derived business rules.

How to use:
    - Execute these queries after the Silver layer has been loaded.
    - Any rows returned indicate data issues that need to be reviewed and fixed.
===============================================================================
*/

-- ====================================================================
-- Validation: silver.crm_cust_info
-- ====================================================================
-- Look for missing or repeated primary key values.
-- Expected outcome: zero rows.
SELECT
    cst_id,
    COUNT(*) AS occurrence_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Detect leading/trailing whitespace in the customer key.
-- Expected outcome: zero rows.
SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key <> TRIM(cst_key);

-- Inspect distinct marital status values for standardization.
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;

-- ====================================================================
-- Validation: silver.crm_prd_info
-- ====================================================================
-- Look for missing or repeated product IDs.
-- Expected outcome: zero rows.
SELECT
    prd_id,
    COUNT(*) AS occurrence_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Detect leading/trailing whitespace in product names.
-- Expected outcome: zero rows.
SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

-- Flag null or negative product costs.
-- Expected outcome: zero rows.
SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Inspect distinct product line values for standardization.
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

-- Flag any record where the start date comes after the end date.
-- Expected outcome: zero rows.
SELECT
    *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ====================================================================
-- Validation: silver.crm_sales_details
-- ====================================================================
-- Identify malformed due-date values stored as integers (YYYYMMDD format).
-- Expected outcome: no malformed dates.
SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
   OR LENGTH(sls_due_dt) <> 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101;

-- Flag rows where the order date is later than the ship or due date.
-- Expected outcome: zero rows.
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Verify that sales = quantity * price, and that none of the values are
-- null, zero, or negative.
-- Expected outcome: zero rows.
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales    IS NULL
   OR sls_quantity IS NULL
   OR sls_price    IS NULL
   OR sls_sales    <= 0
   OR sls_quantity <= 0
   OR sls_price    <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ====================================================================
-- Validation: silver.erp_cust_az12
-- ====================================================================
-- Surface birthdates that fall outside a sensible range.
-- Expected window: between 1924-01-01 and today's date.
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > CURDATE();

-- Inspect distinct gender values for standardization.
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;

-- ====================================================================
-- Validation: silver.erp_loc_a101
-- ====================================================================
-- Inspect distinct country values for standardization.
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ====================================================================
-- Validation: silver.erp_px_cat_g1v2
-- ====================================================================
-- Detect leading/trailing whitespace in category-related fields.
-- Expected outcome: zero rows.
SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE cat         <> TRIM(cat)
   OR subcat      <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);

-- Inspect distinct maintenance flag values for standardization.
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;
