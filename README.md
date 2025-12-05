<img width="700" height="223" alt="image" src="https://github.com/user-attachments/assets/9bce9535-7813-4eec-900a-f82e470c49bf" /># SQL Test Solutions

## 📋 Table of Contents
- [Overview](#overview)
- [Database Schema](#database-schema)
- [Solutions](#solutions)
- [Setup Instructions](#setup-instructions)
- [Execution Screenshots](#execution-screenshots)
- [Assumptions](#assumptions)
- [Technologies Used](#technologies-used)

---

## 🎯 Overview

This repository contains comprehensive SQL solutions for a technical assessment focused on data manipulation, analytical queries, and problem-solving skills. The test includes 8 questions ranging from basic aggregations to complex window functions and time-based calculations.

**Completion Time:** Within 1 hour as required  
**Submission Date:** December 5, 2025

---

## 🗄️ Database Schema

### Tables Structure

#### `transactions` Table
| Column | Type | Description |
|--------|------|-------------|
| `transaction_id` | INTEGER | Primary key, unique transaction identifier |
| `buyer_id` | INTEGER | Foreign key to buyer |
| `store_id` | INTEGER | Store identifier |
| `transaction_time` | TIMESTAMP | Time of purchase |
| `refund_time` | TIMESTAMP | Time of refund (NULL if not refunded) |
| `gross_transaction_value` | DECIMAL | Total transaction value |

#### `items` Table
| Column | Type | Description |
|--------|------|-------------|
| `item_id` | INTEGER | Primary key, unique item identifier |
| `transaction_id` | INTEGER | Foreign key to transactions |
| `item_name` | VARCHAR | Name of the purchased item |

### Sample Data Overview
- **10 transactions** spanning September to November 2020
- **5 unique buyers** (buyer_id: 1-5)
- **3 stores** (store_id: 101-103)
- **3 refunded transactions** with varying refund intervals
- **12 items** including Laptops, Mice, Keyboards, Monitors, and Headphones

---

## 💡 Solutions

### Question 1: Monthly Purchase Count (Excluding Refunds)

**Objective:** Calculate the number of purchases per month, excluding refunded transactions.

**Approach:**
- Filter out transactions where `refund_time IS NULL`
- Group by year-month format
- Count distinct transaction IDs

**SQL Query:**
```sql
SELECT 
    DATE_FORMAT(transaction_time, '%Y-%m') AS purchase_month,
    COUNT(DISTINCT transaction_id) AS purchase_count
FROM transactions
WHERE refund_time IS NULL
GROUP BY DATE_FORMAT(transaction_time, '%Y-%m')
ORDER BY purchase_month;
```
<img width="700" height="223" alt="image" src="https://github.com/user-attachments/assets/8082ef68-fd1e-4e86-8445-1ff12403c4d4" />

### Question 2: Stores with 5+ Orders in October 2020
```sql
SELECT 
    COUNT(DISTINCT store_id) AS store_count
FROM (
    SELECT 
        store_id,
        COUNT(DISTINCT transaction_id) AS transaction_count
    FROM transactions
    WHERE transaction_time >= '2020-10-01' 
      AND transaction_time < '2020-11-01'
    GROUP BY store_id
    HAVING COUNT(DISTINCT transaction_id) >= 5
) AS stores_with_min_orders;

```

### 
