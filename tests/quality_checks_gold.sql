/*
===============================================================================
Data Quality Validation Script
===============================================================================
Purpose:
    Runs a set of validation checks against the Gold Layer to confirm its
    integrity, consistency, and analytical reliability. The checks confirm:
    - Surrogate keys remain unique inside each dimension table.
    - Fact-to-dimension relationships hold (no broken references).
    - The star schema is properly wired for downstream reporting.
Notes:
    - Any rows returned indicate an issue that needs to be investigated and fixed.
===============================================================================
*/

-- ====================================================================
-- Validation: gold.dim_customers
-- ====================================================================
-- Confirm that customer_key values are not repeated across the dimension.
-- Expected outcome: zero rows returned.
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Validation: gold.dim_products
-- ====================================================================
-- Confirm that product_key values are unique inside the product dimension.
-- Expected outcome: zero rows returned.
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Validation: gold.fact_sales
-- ====================================================================
-- Verify referential linkage between the fact table and its dimensions.
-- Any row returned means a sales record points to a missing customer or product.
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL
   OR c.customer_key IS NULL;
