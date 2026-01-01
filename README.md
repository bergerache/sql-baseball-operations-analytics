# ⚾ Baseball Operations Analytics

> **Advanced SQL analytics demonstrating window functions, CTEs, and cumulative calculations — techniques directly applicable to financial services reporting**

---

## 🎯 Overview

This project showcases advanced SQL techniques through baseball operations data analysis. The queries demonstrate skills commonly required in banking and fintech analytics roles: identifying top performers, calculating running totals, tracking tenure, and analysing trends over time.

---

## 📊 Analysis Sections

### 1. Team Spending Analysis
- Identifying top 20% of teams by average annual spending (NTILE)
- Cumulative spending over time (running totals)
- First year each team exceeded $1 billion total investment

### 2. Player Career Analysis
- Career length and tenure calculations
- Starting vs ending team identification (FIRST_VALUE, LAST_VALUE)
- Long-term loyalty patterns (10+ year same-team players)

### 3. Talent Pipeline Analysis
- Top schools producing professional players
- Decade-over-decade trend analysis (LAG)

### 4. Workforce Composition
- Distribution analysis across categories
- Physical attribute trends over decades

---

## 🏦 Banking & Fintech Applications

These SQL patterns translate directly to financial services:

| Baseball Scenario | Banking Equivalent |
|-------------------|-------------------|
| Top 20% teams by spending | High-value customer identification |
| Cumulative salary spending | Running account balance / Cumulative AUM |
| First year spending exceeded $1B | Time-to-threshold analysis (first £1M deposit) |
| Player career tenure | Customer relationship length |
| Same team loyalty (10+ years) | Long-term customer retention analysis |
| Decade-over-decade trends | YoY / MoM performance reporting |
| Workforce composition | Portfolio composition / Customer segmentation |

---

## 🛠️ Skills Demonstrated

### Window Functions
```sql
-- Percentile ranking
NTILE(5) OVER (ORDER BY avg_spend DESC) AS spend_quintile

-- Running totals
SUM(total_spend) OVER (PARTITION BY teamID ORDER BY yearID) AS cumulative_spend

-- Period-over-period comparison
LAG(avg_weight) OVER (ORDER BY decade) AS previous_decade_weight

-- First/last value identification
FIRST_VALUE(teamID) OVER (PARTITION BY playerID ORDER BY yearID) AS first_team
```

### Common Table Expressions (CTEs)
- Modular, readable query structure
- Multi-step transformations
- Reusable intermediate results

### Additional Techniques
- Date manipulation and tenure calculations
- Conditional aggregation with CASE WHEN
- Multi-table joins
- Filtering with HAVING clauses

---

## 📁 Files

| File | Description |
|------|-------------|
| `baseball_operations_analytics.sql` | Complete SQL queries organised by business theme |

---

## 🚀 How to Use
```sql
-- Queries are written for MySQL
-- Each section can be run independently
-- Comments explain the business logic and banking parallels
```

---

## 💡 Why This Matters for Finance Roles

Financial services analytics relies heavily on these exact patterns:

- **Running totals** → Account balances, cumulative deposits, AUM tracking
- **NTILE/percentiles** → Customer tiering, risk segmentation
- **LAG/LEAD** → Month-over-month changes, trend analysis
- **FIRST_VALUE** → Customer acquisition date, first transaction
- **Tenure calculations** → Customer lifetime, relationship length

---

**Demonstrating production-ready SQL for business analytics**
