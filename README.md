# Mobile Money Transactions — SQL Analysis

> SQL portfolio project analyzing mobile money transactions in a West African fintech context.  
> Inspired by the [PaySim dataset](https://www.kaggle.com/datasets/ealaxi/paysim1) used in fraud detection research.

---

## Project Overview

This project models a mobile money system (similar to Wave, Orange Money, or Free Money)
and demonstrates practical SQL skills through 15 business-oriented queries covering:

- Transaction volume and activity analysis
- Regional performance breakdown
- Merchant payment analytics
- Fraud detection and alert management
- Account health monitoring

---

## Database Schema

5 relational tables:

## Entity-Relationship Diagram (ERD)

The following diagram illustrates the relationships between the tables in the Mobile Money database:

![ERD Mobile Money](docs/erd_mobile_money.png)

### Legend
- **Straight arrow**: mandatory relationship (foreign key NOT NULL).
- **Arrow with circle**: optional relationship (foreign key can be NULL).

```

| Table               | Description                                      |
|---------------------|--------------------------------------------------|
| `clients`           | Mobile money account holders                     |
| `merchants`         | Registered businesses accepting payments         |
| `transaction_types` | Transaction categories (CASH_IN, TRANSFER, etc.) |
| `transactions`      | Core fact table — 200 generated transactions     |
| `fraud_alerts`      | Flags raised on suspicious transactions          |

### Entity-Relationship Summary

- A **client** can make many **transactions**
- A **transaction** belongs to one **transaction_type**
- A **transaction** may involve one **merchant** (for PAYMENT type)
- A **fraudulent transaction** may trigger one or more **fraud_alerts**

---

## SQL Concepts Demonstrated

| Concept              | Queries   |
|----------------------|-----------|
| SELECT, WHERE, ORDER BY | Q1–Q15 |
| Aggregate functions (COUNT, SUM, AVG) | Q1, Q2, Q3, Q4, Q7, Q8 |
| GROUP BY + HAVING    | Q5        |
| INNER JOIN           | Q1–Q9, Q13–Q15 |
| LEFT JOIN            | Q14       |
| Subqueries (IN)      | Q6, Q11, Q15 |
| Scalar subquery      | Q13       |
| CASE WHEN            | Q8, Q14   |
| DATE_TRUNC           | Q2        |
| NULLS LAST           | Q14       |

---

## Setup & Usage

### Prerequisites
- PostgreSQL 13+
- `psql` CLI or any SQL client (DBeaver, TablePlus, pgAdmin)

### Run the project

```bash
# 1. Create database
createdb mobile_money_db

# 2. Create schema
psql -d mobile_money_db -f schema/01_create_tables.sql

# 3. Load data
psql -d mobile_money_db -f data/02_seed_data.sql

# 4. Run queries
psql -d mobile_money_db -f queries/03_business_queries.sql
```

---

## Key Business Questions Answered

1. **Which transaction type generates the highest volume?**  
   → Q1: aggregate by type with SUM and COUNT

2. **Which regions are most active?**  
   → Q4, Q5: JOIN + GROUP BY + HAVING

3. **Which merchants receive the most payments?**  
   → Q6: JOIN + subquery to filter by type

4. **What is the fraud rate by transaction type?**  
   → Q8: CASE WHEN inside aggregate

5. **Which high-value CASH_OUT/TRANSFER transactions are unreviewed?**  
   → Q15: multi-condition WHERE + NOT IN subquery

---

## Project Structure

```
mobile_money_sql/
├── schema/
│   └── 01_create_tables.sql     # DDL: tables, constraints, indexes
├── data/
│   └── 02_seed_data.sql         # 200 transactions + reference data
├── queries/
│   └── 03_business_queries.sql  # 15 business queries (commented)
└── README.md
```

---

## Author

**Cheick Oumar Doumbia**  
Engineering Student — Data & AI | ESMT Dakar  
[LinkedIn](https://linkedin.com/in/cheick-oumar-doumbia-77991b3a0) · [GitHub](https://github.com/cdoumb)
