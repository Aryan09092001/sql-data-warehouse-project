# Data Warehouse and Analytics Project

This repository walks through an end-to-end data warehousing and analytics solution — from raw CSV ingestion to a star-schema gold layer ready for business reporting. Built as a portfolio project, it reflects modern data engineering practices, layered architecture, and analytics-first design thinking.

---
## 🏗️ High-Level Data Architecture

The warehouse follows the **Medallion Architecture** pattern, with data flowing left-to-right through four distinct stages — from raw source files, through three progressively refined warehouse layers, and finally into consumption tools.

```
📁 Sources  ──►  🥉 Bronze  ──►  🥈 Silver  ──►  🥇 Gold  ──►  📊 Consume
```

### Stage-by-Stage Breakdown

| Stage             | 📁 **Sources**                       | 🥉 **Bronze Layer**                                | 🥈 **Silver Layer**                                                                        | 🥇 **Gold Layer**                                                  | 📊 **Consume**                                              |
|-------------------|--------------------------------------|----------------------------------------------------|--------------------------------------------------------------------------------------------|--------------------------------------------------------------------|-------------------------------------------------------------|
| **Role**          | Raw input from upstream systems      | Untouched landing zone for ingested data           | Cleansed, conformed, and standardized data                                                 | Business-ready analytical model                                    | Downstream consumption of warehouse data                    |
| **Object Type**   | CSV files                            | Tables                                             | Tables                                                                                     | Views                                                              | Dashboards, queries, and ML pipelines                       |
| **Data Content**  | ERP and CRM source extracts          | Raw data, exactly as received                      | Cleaned and standardized data                                                              | Business-ready data                                                | Aggregated insights and predictions                         |
| **Interface**     | Files in folders                     | Loaded via stored procedures                       | Loaded via stored procedures                                                               | Surfaced via SQL views                                             | BI tools, SQL clients, ML notebooks                         |
| **Load Strategy** | N/A (delivered manually)             | • Batch processing<br>• Full load<br>• Truncate & insert | • Batch processing<br>• Full load<br>• Truncate & insert                                   | No physical load (views compute on read)                           | Read-only access                                            |
| **Transformations** | None                               | None — data is preserved as-is                     | • Data cleansing<br>• Data standardization<br>• Data normalization<br>• Derived columns<br>• Data enrichment | • Data integration<br>• Aggregations<br>• Business logic           | Defined inside the consumer (BI tool, query, or model)      |
| **Data Model**    | None (as-is)                         | None (as-is)                                       | None (as-is)                                                                               | • Star schema<br>• Flat tables<br>• Aggregated tables              | Tailored to the consumption use case                        |
| **Engine**        | Source systems                       | SQL Server                                         | SQL Server                                                                                 | SQL Server                                                         | Power BI, Tableau, SQL clients, Python/ML frameworks        |

---

### What Each Layer Adds

| Layer       | What It Adds Over the Previous Stage                                                                  |
|-------------|--------------------------------------------------------------------------------------------------------|
| 🥉 **Bronze** | A reliable, queryable copy of source data — no more parsing CSVs ad-hoc.                              |
| 🥈 **Silver** | Trust — data is now clean, deduplicated, validated, and consistent across source systems.             |
| 🥇 **Gold**   | Business meaning — raw entities become customers, products, and sales modeled for analytical questions.|

---

### Consumption Patterns

The Gold layer is designed to serve three distinct consumer profiles, each with different needs:

| Consumer Type            | Typical Tools                          | What They Need from Gold                                |
|--------------------------|----------------------------------------|---------------------------------------------------------|
| 📊 **BI & Reporting**     | Power BI, Tableau, Looker              | Pre-modeled dimensions and facts for dashboards         |
| 🔎 **Ad-Hoc SQL Analysts**| SSMS, DBeaver, DataGrip                | Clean, joinable views for exploratory queries           |
| 🤖 **Machine Learning**   | Python, scikit-learn, TensorFlow       | Flat, feature-rich tables for model training            |

## 📖 Project Overview

This project covers the full life cycle of building a data warehouse, including:

1. **Data Architecture Design** — Establishing a layered Medallion warehouse (Bronze → Silver → Gold) using SQL Server as the storage and processing engine.
2. **ETL Pipeline Development** — Engineering extraction, transformation, and load scripts that move data through each layer with appropriate quality checks.
3. **Dimensional Data Modeling** — Designing fact and dimension tables (star schema) tuned for high-performance analytical queries.
4. **Analytics & Reporting** — Authoring SQL queries that surface customer, product, and sales insights ready for dashboards or stakeholder consumption.
5. **Data Quality Validation** — Implementing automated checks for surrogate-key uniqueness, referential integrity, and business-rule compliance at every layer.
6. **Documentation** — Maintaining catalogs, naming conventions, and architecture diagrams so the warehouse stays understandable as it grows.

🎯 The project is designed as a hands-on showcase for skills in:
- SQL Development
- Data Architecture
- Data Engineering
- ETL Pipeline Construction
- Dimensional Data Modeling
- Data Analytics & BI Reporting

---

## 🛠️ Tools & Resources Used

Everything used in this project is **free and open**:

- **[Datasets](datasets/):** ERP and CRM source CSV files included in the repo.
- **[SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads):** Lightweight SQL Server edition for hosting the warehouse locally.
- **[SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16):** Graphical client for writing queries and managing databases.
- **[GitHub](https://github.com/):** Version control and collaboration platform for the codebase.
- **[Draw.io](https://www.drawio.com/):** Diagramming tool for architecture, data flow, and ER diagrams.
- **[Notion](https://www.notion.com/):** Workspace for tracking project tasks, notes, and milestones.

---

## 🚀 Project Requirements

### 🏗️ Building the Data Warehouse (Data Engineering Track)

#### Objective
Design and build a modern data warehouse on SQL Server that consolidates ERP and CRM data into a single, analytics-ready source of truth.

#### Specifications
- **Data Sources:** Two source systems — **ERP** and **CRM** — delivered as CSV files.
- **Data Quality:** Identify and remediate quality issues (nulls, duplicates, format inconsistencies, invalid dates, business-rule violations) before data reaches the Gold layer.
- **Integration:** Merge both source systems into one cohesive, unified data model that hides upstream complexity from analysts.
- **Scope:** Only the **most recent snapshot** of data is retained — historization (SCD Type 2 etc.) is out of scope for this iteration.
- **Documentation:** Ship the warehouse with a data catalog, naming convention guide, and architecture diagrams so non-engineers can navigate the model.

---

### 📊 BI: Analytics & Reporting (Data Analysis Track)

#### Objective
Translate the warehouse into actionable business insight using SQL-based analytics across three core domains:

- **Customer Behavior** — Who are the customers, where do they come from, and how do they segment?
- **Product Performance** — Which products and categories drive the most revenue and volume?
- **Sales Trends** — How are sales evolving across time, geography, and product lines?

The goal is to give stakeholders the metrics and trends they need to make confident, data-backed decisions.

For deeper requirement specs, see [`docs/requirements.md`](docs/requirements.md).

---

## 📂 Repository Structure

```
data-warehouse-project/
│
├── datasets/                           # Raw source CSV files (ERP and CRM)
│   ├── source_crm/                     # CRM source data
│   └── source_erp/                     # ERP source data
│
├── docs/                               # Project documentation and architecture artifacts
│   ├── etl.drawio                      # Diagram outlining ETL approaches and patterns
│   ├── data_architecture.drawio        # High-level architecture diagram
│   ├── data_catalog.md                 # Catalog of tables, columns, and metadata
│   ├── data_flow.drawio                # End-to-end data flow diagram
│   ├── data_models.drawio              # Star schema and dimensional model diagrams
│   └── naming_conventions.md           # Naming standards for schemas, tables, columns, and procedures
│
├── scripts/                            # SQL scripts for each warehouse layer
│   ├── bronze/                         # Raw ingestion scripts (CSV → SQL Server)
│   ├── silver/                         # Cleansing, standardization, and transformation logic
│   └── gold/                           # Star-schema dimension and fact view definitions
│
├── tests/                              # Quality-check scripts and validation queries
│
├── README.md                           # You are here — project overview and entry point
├── LICENSE                             # MIT license for open use and modification
├── .gitignore                          # Files and directories excluded from version control
└── requirements.txt                    # Python or tooling dependencies (if applicable)
```

---

## 🔄 How the Pipeline Flows

```
   📁 CSV Sources (ERP + CRM)
            │
            ▼
   🥉 Bronze Layer  ──►  Raw, untouched copies of source data
            │
            ▼
   🥈 Silver Layer  ──►  Cleansed, standardized, deduplicated data
            │
            ▼
   🥇 Gold Layer    ──►  Star schema (dim_customers, dim_products, fact_sales)
            │
            ▼
   📊 Analytics & Reporting
```

Each transition between layers is governed by a dedicated SQL script and accompanied by automated quality checks under `tests/`.

---

## ✅ Getting Started

If you'd like to run this project locally, the rough order of operations is:

1. **Install** SQL Server Express and SSMS.
2. **Clone** this repository to your machine.
3. **Create** the `bronze`, `silver`, and `gold` databases (or schemas, depending on your setup).
4. **Load** the source CSVs from `datasets/` into the Bronze layer using the scripts in `scripts/bronze/`.
5. **Run** the Silver-layer transformation scripts from `scripts/silver/`.
6. **Build** the Gold-layer views using `scripts/gold/`.
7. **Validate** everything by executing the quality-check scripts in `tests/`.
8. **Explore** the Gold layer with your favorite SQL client or BI tool.

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.
