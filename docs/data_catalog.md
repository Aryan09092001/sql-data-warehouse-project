# Gold Layer — Data Catalog

## Overview
The Gold Layer is the **business-ready, analytics-facing tier** of the data warehouse. It exposes cleaned, conformed, and enriched data through a **star schema** designed for reporting, dashboarding, and ad-hoc analysis. The layer is composed of:

- **Dimension tables** (`dim_*`) — descriptive context about business entities (who, what, where).
- **Fact tables** (`fact_*`) — measurable business events tied to those dimensions (how much, how many, when).

All tables in this layer are surfaced as **views** built on top of the Silver layer, so any downstream changes propagate automatically once the Silver layer is refreshed.

---

## Schema Diagram

```
        ┌────────────────────┐
        │ gold.dim_customers │
        └─────────┬──────────┘
                  │ customer_key
                  │
        ┌─────────▼──────────┐         ┌────────────────────┐
        │   gold.fact_sales  │◄────────│ gold.dim_products  │
        └────────────────────┘ product_key────────────────┘
```

Each fact row references exactly one row from each dimension via surrogate keys.

---

## 1. `gold.dim_customers`

- **Purpose:** Holds a 360° view of each customer, blending CRM master data with ERP-sourced demographics and geography.
- **Grain:** One row per unique customer.
- **Source tables:** `silver.crm_cust_info`, `silver.erp_cust_az12`, `silver.erp_loc_a101`

### Columns

| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| customer_key     | INT           | Auto-generated surrogate key — the canonical identifier used for joining to fact tables.      |
| customer_id      | INT           | Numeric business identifier coming from the CRM source system.                                |
| customer_number  | NVARCHAR(50)  | Alphanumeric customer code used for human-readable lookups and cross-system reconciliation.   |
| first_name       | NVARCHAR(50)  | Given name of the customer, sourced from CRM.                                                 |
| last_name        | NVARCHAR(50)  | Surname / family name of the customer, sourced from CRM.                                      |
| country          | NVARCHAR(50)  | Country of residence resolved from the ERP location feed (e.g., `Australia`, `United States`).|
| marital_status   | NVARCHAR(50)  | Standardized marital status (e.g., `Married`, `Single`).                                      |
| gender           | NVARCHAR(50)  | Gender, with CRM as the primary source and ERP as a fallback (e.g., `Male`, `Female`, `n/a`). |
| birthdate        | DATE          | Customer's date of birth in `YYYY-MM-DD` format (e.g., `1971-10-06`).                         |
| create_date      | DATE          | Date the customer record was first registered in the source system.                           |

---

## 2. `gold.dim_products`

- **Purpose:** Describes every active product offered, combining core product attributes with category metadata.
- **Grain:** One row per currently-active product (historical/discontinued products are filtered out).
- **Source tables:** `silver.crm_prd_info`, `silver.erp_px_cat_g1v2`

### Columns

| Column Name          | Data Type     | Description                                                                                   |
|----------------------|---------------|-----------------------------------------------------------------------------------------------|
| product_key          | INT           | Auto-generated surrogate key — the canonical identifier used for joining to fact tables.      |
| product_id           | INT           | Internal numeric identifier assigned to the product by the source system.                     |
| product_number       | NVARCHAR(50)  | Structured alphanumeric SKU used for inventory management and categorization.                 |
| product_name         | NVARCHAR(50)  | Descriptive product label including model, color, and size details.                           |
| category_id          | NVARCHAR(50)  | Foreign key linking the product to its category classification.                               |
| category             | NVARCHAR(50)  | High-level product family (e.g., `Bikes`, `Components`, `Clothing`).                          |
| subcategory          | NVARCHAR(50)  | More granular grouping within the category (e.g., `Mountain Bikes`, `Helmets`).               |
| maintenance_required | NVARCHAR(50)  | Flag indicating whether the product needs ongoing maintenance (`Yes` / `No`).                 |
| cost                 | INT           | Base cost of the product, expressed in whole currency units.                                  |
| product_line         | NVARCHAR(50)  | Brand or series the product belongs to (e.g., `Road`, `Mountain`, `Touring`).                 |
| start_date           | DATE          | Date the product became available for sale.                                                   |

---

## 3. `gold.fact_sales`

- **Purpose:** Captures every sales transaction at the order-line level for revenue, volume, and trend analysis.
- **Grain:** One row per product line item within a sales order.
- **Source tables:** `silver.crm_sales_details` (joined to `gold.dim_products` and `gold.dim_customers` for surrogate keys).

### Columns

| Column Name   | Data Type     | Description                                                                                   |
|---------------|---------------|-----------------------------------------------------------------------------------------------|
| order_number  | NVARCHAR(50)  | Unique alphanumeric ID for the sales order (e.g., `SO54496`).                                 |
| product_key   | INT           | Foreign key referencing `gold.dim_products.product_key`.                                      |
| customer_key  | INT           | Foreign key referencing `gold.dim_customers.customer_key`.                                    |
| order_date    | DATE          | Date the order was placed by the customer.                                                    |
| shipping_date | DATE          | Date the order was dispatched.                                                                |
| due_date      | DATE          | Date by which payment for the order was expected.                                             |
| sales_amount  | INT           | Total revenue for the line item, in whole currency units (e.g., `25`).                        |
| quantity      | INT           | Number of product units sold on this line item (e.g., `1`).                                   |
| price         | INT           | Per-unit price of the product on this line item (e.g., `25`).                                 |

### Business Rule
For every row: `sales_amount = quantity * price` (validated by the Gold-layer quality checks).

---

## Common Query Patterns

**Total revenue by country:**
```sql
SELECT c.country, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;
```

**Top 10 best-selling product categories:**
```sql
SELECT p.category, SUM(f.quantity) AS units_sold
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY units_sold DESC
LIMIT 10;
```

**Monthly sales trend:**
```sql
SELECT DATE_FORMAT(f.order_date, '%Y-%m') AS month,
       SUM(f.sales_amount)                AS revenue
FROM gold.fact_sales f
GROUP BY DATE_FORMAT(f.order_date, '%Y-%m')
ORDER BY month;
```

---

## Refresh Cadence
The Gold Layer views automatically reflect the underlying Silver Layer state. No separate ETL job is required — refreshing Silver propagates downstream.

---

## Data Quality
All Gold-layer tables are validated by `gold_quality_checks.sql`, which verifies:
- Surrogate key uniqueness across dimensions.
- Referential integrity between facts and dimensions (no orphan keys).
- Consistency of business rules (e.g., `sales_amount = quantity * price`).

Run these checks after every Silver-to-Gold refresh.
