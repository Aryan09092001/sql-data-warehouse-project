# **Naming Conventions**

This document defines the standardized naming rules for all objects in the data warehouse — including schemas, tables, views, columns, stored procedures, and supporting artifacts. Following these conventions consistently keeps the warehouse readable, predictable, and easy to navigate as it grows.

---

## **Table of Contents**
1. [General Principles](#general-principles)
2. [Schema Naming Conventions](#schema-naming-conventions)
3. [Table Naming Conventions](#table-naming-conventions)
   - [Bronze Layer Rules](#bronze-layer-rules)
   - [Silver Layer Rules](#silver-layer-rules)
   - [Gold Layer Rules](#gold-layer-rules)
4. [View Naming Conventions](#view-naming-conventions)
5. [Column Naming Conventions](#column-naming-conventions)
   - [Surrogate Keys](#surrogate-keys)
   - [Foreign Keys](#foreign-keys)
   - [Technical / Audit Columns](#technical--audit-columns)
   - [Boolean Flags](#boolean-flags)
   - [Date and Timestamp Columns](#date-and-timestamp-columns)
6. [Stored Procedure Naming Conventions](#stored-procedure-naming-conventions)
7. [Index and Constraint Naming Conventions](#index-and-constraint-naming-conventions)
8. [Quick-Reference Cheat Sheet](#quick-reference-cheat-sheet)

---

## **General Principles**

- **Casing:** Use **`snake_case`** throughout — all lowercase letters, with underscores (`_`) separating words. No camelCase, PascalCase, or hyphens.
- **Language:** All object names must be in **English**, regardless of the source system's original language.
- **Reserved Words:** Never use SQL reserved keywords (`order`, `user`, `select`, `date`, etc.) as object names. If a source field collides with a reserved word, suffix it (e.g., `order_id` instead of `order`).
- **Length:** Keep names concise but descriptive. Aim for clarity over brevity — `customer_create_date` beats `cust_cr_dt`.
- **Singular vs. Plural:**
  - **Tables:** Use **plural** nouns (`customers`, `products`, `sales`).
  - **Columns:** Use **singular** nouns (`customer_id`, `product_name`).
- **Abbreviations:** Avoid ad-hoc abbreviations. Stick to a small, agreed-upon set (e.g., `id`, `dt`, `ts`, `qty`, `amt`) and use them consistently.
- **No Special Characters:** Names must contain only letters, digits, and underscores. Never start a name with a digit.

---

## **Schema Naming Conventions**

Each layer of the medallion architecture lives in its own schema, named after the layer itself:

| Schema   | Purpose                                                       |
|----------|---------------------------------------------------------------|
| `bronze` | Raw data ingested from source systems with minimal processing |
| `silver` | Cleaned, conformed, and standardized data                     |
| `gold`   | Business-ready, analytics-facing dimension and fact models    |

---

## **Table Naming Conventions**

### **Bronze Layer Rules**

- Tables in this layer mirror the source system one-to-one — **no renaming**, no transformations.
- Every table name must start with the source system identifier.
- **Pattern:** `<source_system>_<entity>`
  - `<source_system>`: Short tag for the originating system (e.g., `crm`, `erp`, `web`).
  - `<entity>`: The original table name as it appears in the source system.
- **Example:** `crm_cust_info` — raw customer information pulled from the CRM.

### **Silver Layer Rules**

- Silver-layer tables retain the same naming pattern as Bronze, since each Silver table is the cleaned counterpart of its Bronze sibling.
- **Pattern:** `<source_system>_<entity>` (identical to Bronze).
- **Example:** `crm_cust_info` — the standardized, deduplicated, and validated version of the corresponding Bronze table.

### **Gold Layer Rules**

- Gold-layer tables abandon source-system naming in favor of **business-friendly, domain-driven names**.
- Every name begins with a **category prefix** that signals the table's role in the analytical model.
- **Pattern:** `<category>_<entity>`
  - `<category>`: The table's modeling role (e.g., `dim`, `fact`, `report`).
  - `<entity>`: A meaningful business term, in the plural form.
- **Examples:**
  - `dim_customers` — dimension table describing customers.
  - `fact_sales` — fact table holding sales transactions.

#### **Category Prefix Glossary**

| Prefix    | Meaning                            | Example(s)                                       |
|-----------|------------------------------------|--------------------------------------------------|
| `dim_`    | Dimension table                    | `dim_customers`, `dim_products`, `dim_date`      |
| `fact_`   | Fact table                         | `fact_sales`, `fact_inventory_movements`         |
| `report_` | Pre-aggregated reporting table     | `report_sales_monthly`, `report_customers_top50` |
| `bridge_` | Many-to-many resolution table      | `bridge_customer_segments`                       |
| `agg_`    | Pre-computed aggregate / summary   | `agg_sales_by_region_daily`                      |

---

## **View Naming Conventions**

- Views follow the **same naming rules as the tables of the layer they belong to**.
- If a view is intentionally a "thin wrapper" over a base table, suffix it with `_v` only if disambiguation is needed.
- **Examples:**
  - `gold.dim_customers` (view, no suffix needed since Gold is view-based by default).
  - `silver.crm_cust_info_v` (only if a view co-exists alongside a table of the same name).

---

## **Column Naming Conventions**

### **Surrogate Keys**

- Every dimension table's primary key must be a **surrogate key**, ending with the suffix `_key`.
- **Pattern:** `<entity>_key`
  - `<entity>`: The singular form of the table's business entity.
  - `_key`: Marks the column as a system-generated surrogate identifier.
- **Example:** `customer_key` — surrogate key in `dim_customers`.

### **Foreign Keys**

- Foreign-key columns reuse the exact name of the surrogate key they point to.
- **Pattern:** `<referenced_entity>_key`
- **Example:** In `fact_sales`, `customer_key` references `dim_customers.customer_key`.

### **Technical / Audit Columns**

- All system-generated metadata columns must use the prefix **`dwh_`** to distinguish them from business columns.
- **Pattern:** `dwh_<descriptor>`
- **Examples:**
  - `dwh_load_date` — date the row was loaded into the warehouse.
  - `dwh_load_ts` — exact timestamp of insertion.
  - `dwh_source_system` — source system the record originated from.
  - `dwh_record_hash` — hash used for change detection.
  - `dwh_is_current` — flag indicating the active version (in SCD Type 2 dimensions).

### **Boolean Flags**

- Boolean columns must use the prefix **`is_`** or **`has_`** to make their truthy nature explicit.
- **Examples:** `is_active`, `is_deleted`, `has_subscription`.

### **Date and Timestamp Columns**

- Use the suffix `_date` for `DATE` columns and `_ts` (or `_timestamp`) for `DATETIME` / `TIMESTAMP` columns.
- **Examples:** `order_date`, `created_ts`, `last_modified_ts`.

---

## **Stored Procedure Naming Conventions**

- Procedures that load data into a layer use the pattern:
- **Pattern:** `load_<layer>`
  - `<layer>`: The destination layer — one of `bronze`, `silver`, or `gold`.
- **Examples:**
  - `load_bronze` — populates the Bronze layer from source extracts.
  - `load_silver` — transforms Bronze into Silver.
  - `load_gold` — refreshes Gold-layer dimension and fact views.

For utility procedures (validation, archiving, etc.), use a verb-first descriptive name:
- **Examples:** `validate_silver_quality`, `archive_old_partitions`, `truncate_staging`.

---

## **Index and Constraint Naming Conventions**

| Object Type       | Pattern                                | Example                              |
|-------------------|----------------------------------------|--------------------------------------|
| Primary Key       | `pk_<table>`                           | `pk_dim_customers`                   |
| Foreign Key       | `fk_<table>_<referenced_table>`        | `fk_fact_sales_dim_customers`        |
| Unique Constraint | `uq_<table>_<column>`                  | `uq_dim_customers_customer_number`   |
| Index             | `ix_<table>_<column(s)>`               | `ix_fact_sales_order_date`           |
| Check Constraint  | `ck_<table>_<rule>`                    | `ck_fact_sales_quantity_positive`    |

---

## **Quick-Reference Cheat Sheet**

| Object            | Pattern                          | Example                          |
|-------------------|----------------------------------|----------------------------------|
| Bronze table      | `<source>_<entity>`              | `crm_cust_info`                  |
| Silver table      | `<source>_<entity>`              | `erp_loc_a101`                   |
| Gold dimension    | `dim_<entity>`                   | `dim_customers`                  |
| Gold fact         | `fact_<entity>`                  | `fact_sales`                     |
| Gold report       | `report_<entity>`                | `report_sales_monthly`           |
| Surrogate key     | `<entity>_key`                   | `product_key`                    |
| Audit column      | `dwh_<descriptor>`               | `dwh_load_date`                  |
| Boolean flag      | `is_<state>` / `has_<thing>`     | `is_active`                      |
| Date column       | `<event>_date`                   | `order_date`                     |
| Timestamp column  | `<event>_ts`                     | `created_ts`                     |
| Load procedure    | `load_<layer>`                   | `load_silver`                    |
| Primary key       | `pk_<table>`                     | `pk_dim_customers`               |
| Foreign key       | `fk_<table>_<referenced>`        | `fk_fact_sales_dim_products`     |
| Index             | `ix_<table>_<column>`            | `ix_fact_sales_order_date`       |

---

> **Tip:** When in doubt, prioritize **clarity** and **consistency** over cleverness. A name that another engineer can understand at a glance — without needing to open documentation — is always the right name.
