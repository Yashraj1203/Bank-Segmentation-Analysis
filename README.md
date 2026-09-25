# 🏦 Banking Customer Segmentation & Transaction Analytics

A MySQL case study that simulates retail banking data, engineers customer-level features, and segments customers by value, engagement, and product depth.

## Business Problem

A retail bank wants to understand **who its customers are, how they use banking products, and which customer groups require different forms of attention**.

This project answers four analytical questions:

1. Which customers generate the highest transaction inflows and activity?
2. Which customers/accounts are active, low-activity, or dormant?
3. Which customers have single-product versus multi-product relationships?
4. How do customer value and engagement vary across cities and transaction services?

> **Important:** The dataset is simulated for analytical demonstration. Findings should not be interpreted as evidence about actual Nigerian banking customers or markets.

## Analytical Architecture

```
Simulated Banking Data
        ↓
Relational Data Model
        ↓
Data Quality Checks
        ↓
Customer-Level Feature Engineering
        ↓
Value / Engagement / Product Segmentation
        ↓
Customer & Transaction Analysis
        ↓
Business Implications
```

## Data Model

The project uses three core tables:

| Table | Purpose |
|---|---|
| `customers` | Customer identity, demographics, signup date, and city |
| `accounts` | Customer account relationships, product type, opening date, and balance |
| `transactions` | Transaction date, amount, type, and service description |

The generated dataset contains **200 customers** and **2,000 transactions**, with 1–3 accounts generated per customer.

### Account Products

The simulation currently uses:

- Savings
- Current
- Loan

## Segmentation Framework

Customer segmentation is built across three independent dimensions.

### 1. Customer Value

Based primarily on total credit inflows:

- **High Value** — top third
- **Medium Value** — middle third
- **Low Value** — bottom third

The value tiers are derived with `NTILE(3)` so that thresholds adapt to the simulated dataset rather than relying on arbitrary currency cutoffs.

### 2. Engagement

Based on transaction recency:

| Segment | Definition |
|---|---|
| Active | Most recent transaction within 90 days |
| Low Activity | Most recent transaction 91–365 days ago |
| Dormant | No transaction or no transaction within the last 365 days |

### 3. Product Relationship

Based on the number of distinct account products:

- **Single Product** — one distinct account type
- **Multi Product** — more than one distinct account type

These dimensions can then be combined to identify customer profiles such as:

- High Value + Active + Multi Product
- High Value + Dormant
- Medium Value + Active + Single Product
- Low Value + Active + Single Product

## SQL Analysis

The analysis is organized around business questions rather than SQL difficulty levels.

### Customer Value

- Total debit spend per customer
- Top customers by total credit inflows
- Highest spender by city

### Engagement

- Transaction activity by account
- Customer dormancy
- Monthly and yearly transaction trends
- Service usage patterns

### Product Relationship

- Single-product customers
- Multi-product customers
- Account/product depth by customer

### Transaction Behavior

- Debit versus credit volume
- Average transaction size
- Salary credit trends
- Most-used transaction services

### Geography

- Customer and transaction volume by city
- Active and dormant account distribution by city
- Highest-value customers by city

## Data Quality

The project includes dedicated validation checks for:

- Customer, account, and transaction row counts
- Null key fields
- Orphaned accounts
- Orphaned transactions
- Duplicate account numbers
- Invalid transaction types
- Non-positive transaction amounts
- Future-dated transactions
- Negative account balances

See:

`04_data_quality_checks.sql`

## Customer Feature Layer

`05_customer_features.sql` creates a reusable customer-level analytical dataset containing:

- Customer and city
- Account count
- Product count
- Relationship balance
- Total credit
- Total debit
- Transaction count
- Average transaction value
- Active months
- Last transaction date
- Credit/debit ratio
- Salary transaction count and value

This feature layer separates **data preparation** from **segmentation logic**.

## Customer Segmentation

`06_customer_segmentation.sql` applies the segmentation framework to the feature layer and produces one analytical row per customer with:

```
customer_id
value_segment
engagement_segment
product_segment
city
total_credit
total_debit
transaction_count
relationship_balance
last_transaction_date
```

## Technical Skills Demonstrated

- MySQL
- Relational data modeling
- Data quality validation
- CTEs
- Joins
- Aggregations
- Conditional logic
- Date functions
- Window functions
- Customer-level feature engineering
- Segmentation
- Business-oriented SQL analysis

## Repository Structure

```
Bank-Segmentation-Analysis/
│
├── README.md
├── analysis_case_summary.md
│
├── 01_schema_setup_mysql.sql
├── 02_data_generation_mysql.sql
├── 03_bank_segmentation_mysql.sql
├── 04_data_quality_checks.sql
├── 05_customer_features.sql
└── 06_customer_segmentation.sql
```

## Business Interpretation Boundaries

Because the data is simulated and intentionally simplified, this project does **not** claim:

- Actual Nigerian banking market behavior
- Customer profitability or lifetime value
- Credit risk or default probability
- Causal relationships between customer characteristics and behavior
- Real-world regional market performance

The analysis demonstrates the **SQL and analytical workflow** used to derive customer insights from structured banking data.

## Outcome

The project demonstrates an end-to-end analyst workflow:

> **Data → Validation → Feature Engineering → Segmentation → Insight**

It is designed to showcase practical SQL, customer analytics, and business reasoning for data analyst and business analyst roles.
