# Test Cases for CV_TEST 1.hdbcalculationview

## Document Information
- **Calculation View**: CV_TEST 1.hdbcalculationview
- **Test Date**: 2026-02-04
- **Version**: Current
- **Purpose**: Validate all changes made to the calculation view

---

## Summary of Changes Tested

### Change 1: Products Table Join (Commit: 00b06a2)
- **Change**: Added PRODUCTS table join to display PRODUCT_NAME instead of PRODUCT_ID
- **Join Type**: Inner join between SALES and PRODUCTS on PRODUCT_ID
- **Impact**: Users see product names instead of cryptic product IDs

### Change 2: SELLING_PRICE Calculated Measure (Commit: d76285f)
- **Change**: Added calculated measure at aggregation level
- **Formula**: `UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT`
- **Impact**: Provides net selling price insights

### Change 3: Active Customer Filter (Commit: d76285f)
- **Change**: Filter on CUSTOMERS table where STATUS = 'Active'
- **Location**: PR_CUSTOMERS projection view
- **Impact**: Only active customers appear in results

---

## Test Environment Setup

### Required Test Data

#### CUSTOMERS Table
```sql
-- Active Customers (Should Appear)
INSERT INTO SGUNNAM.CUSTOMERS VALUES (1, 'John', 'Smith', 'Active');
INSERT INTO SGUNNAM.CUSTOMERS VALUES (2, 'Bob', 'Johnson', 'Active');
INSERT INTO SGUNNAM.CUSTOMERS VALUES (3, 'Alice', 'Williams', 'Active');

-- Inactive Customers (Should NOT Appear)
INSERT INTO SGUNNAM.CUSTOMERS VALUES (4, 'Jane', 'Doe', 'Inactive');
INSERT INTO SGUNNAM.CUSTOMERS VALUES (5, 'Mike', 'Brown', 'Pending');
INSERT INTO SGUNNAM.CUSTOMERS VALUES (6, 'Sarah', 'Davis', NULL);
```

#### PRODUCTS Table
```sql
-- Products with Names
INSERT INTO SGUNNAM.PRODUCTS VALUES (101, 'Laptop Computer');
INSERT INTO SGUNNAM.PRODUCTS VALUES (102, 'Wireless Mouse');
INSERT INTO SGUNNAM.PRODUCTS VALUES (103, 'USB Cable');
INSERT INTO SGUNNAM.PRODUCTS VALUES (104, 'External Monitor');

-- Orphan Product (No Sales)
INSERT INTO SGUNNAM.PRODUCTS VALUES (999, 'Discontinued Item');
```

#### SALES Table
```sql
-- Sales for Active Customers
INSERT INTO SGUNNAM.SALES VALUES (1, 'ORD001', 2, 101, 1200.00, 100.00, 50.00, 25.00);  -- John's Laptop
INSERT INTO SGUNNAM.SALES VALUES (1, 'ORD002', 1, 102, 25.00, 2.00, 1.00, 5.00);        -- John's Mouse
INSERT INTO SGUNNAM.SALES VALUES (2, 'ORD003', 10, 103, 5.00, 0.50, 0.25, 2.00);        -- Bob's Cables
INSERT INTO SGUNNAM.SALES VALUES (3, 'ORD004', 1, 104, 300.00, 30.00, 15.00, 20.00);    -- Alice's Monitor

-- Sales for Inactive Customers (Should be filtered out)
INSERT INTO SGUNNAM.SALES VALUES (4, 'ORD005', 5, 102, 25.00, 0.00, 1.25, 5.00);        -- Jane's Mouse
INSERT INTO SGUNNAM.SALES VALUES (5, 'ORD006', 1, 101, 1200.00, 0.00, 60.00, 25.00);    -- Mike's Laptop

-- Sale with non-existent Product (Should not appear due to inner join)
INSERT INTO SGUNNAM.SALES VALUES (1, 'ORD007', 1, 888, 50.00, 0.00, 2.50, 5.00);        -- Missing Product
```

---

## POSITIVE TEST CASES (Expected Behavior)

### TC-001: Active Customer Filter - Verify Only Active Customers Appear
**Objective**: Confirm only customers with STATUS='Active' are included

**Test Query**:
```sql
SELECT DISTINCT 
    FIRST_NAME,
    LAST_NAME
FROM CV_TEST
ORDER BY FIRST_NAME;
```

**Expected Results**:
| FIRST_NAME | LAST_NAME |
|------------|-----------|
| Alice      | Williams  |
| Bob        | Johnson   |
| John       | Smith     |

**✅ PASS Criteria**: 
- Exactly 3 customers returned
- Jane Doe (Inactive) NOT in results
- Mike Brown (Pending) NOT in results
- Sarah Davis (NULL status) NOT in results

**❌ FAIL Criteria**:
- If Jane, Mike, or Sarah appear in results
- If more than 3 customers returned

---

### TC-002: Product Name Display - Verify Product Names Appear Instead of IDs
**Objective**: Confirm PRODUCT_NAME is displayed instead of PRODUCT_ID

**Test Query**:
```sql
SELECT 
    PRODUCT_NAME,
    COUNT(*) as ORDER_COUNT
FROM CV_TEST
GROUP BY PRODUCT_NAME
ORDER BY PRODUCT_NAME;
```

**Expected Results**:
| PRODUCT_NAME        | ORDER_COUNT |
|---------------------|-------------|
| External Monitor    | 1           |
| Laptop Computer     | 1           |
| USB Cable           | 1           |
| Wireless Mouse      | 1           |

**✅ PASS Criteria**:
- Product names are human-readable text (not IDs like 101, 102)
- All products from active customers' orders appear
- Product names match PRODUCTS table

**❌ FAIL Criteria**:
- If PRODUCT_ID numbers appear instead of names
- If product names are NULL or empty

---

### TC-003: SELLING_PRICE Calculation - Verify Formula Correctness
**Objective**: Validate SELLING_PRICE = UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE,
    (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT) as MANUAL_CALCULATION
FROM CV_TEST
WHERE FIRST_NAME = 'John' AND PRODUCT_NAME = 'Laptop Computer';
```

**Expected Results**:
| FIRST_NAME | LAST_NAME | PRODUCT_NAME    | UNIT_PRICE | DISCOUNT | TAX   | SELLING_PRICE | MANUAL_CALC |
|------------|-----------|-----------------|------------|----------|-------|---------------|-------------|
| John       | Smith     | Laptop Computer | 1200.00    | 100.00   | 50.00 | 1050.00       | 1050.00     |

**✅ PASS Criteria**:
- SELLING_PRICE = 1050.00
- SELLING_PRICE matches MANUAL_CALCULATION
- Formula: 1200 - 100 - 50 = 1050

**❌ FAIL Criteria**:
- If SELLING_PRICE ≠ MANUAL_CALCULATION
- If SELLING_PRICE is NULL
- If calculation is incorrect

---

### TC-004: SELLING_PRICE Aggregation - Verify SUM Works Correctly
**Objective**: Confirm SELLING_PRICE aggregates correctly across multiple orders

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    LAST_NAME,
    SUM(QUANTITY) as TOTAL_QUANTITY,
    SUM(UNIT_PRICE) as TOTAL_UNIT_PRICE,
    SUM(DISCOUNT_AMOUNT) as TOTAL_DISCOUNT,
    SUM(TAX_AMOUNT) as TOTAL_TAX,
    SUM(SELLING_PRICE) as TOTAL_SELLING_PRICE
FROM CV_TEST
WHERE FIRST_NAME = 'John'
GROUP BY FIRST_NAME, LAST_NAME;
```

**Expected Results**:
| FIRST_NAME | LAST_NAME | TOTAL_QTY | TOTAL_UNIT_PRICE | TOTAL_DISCOUNT | TOTAL_TAX | TOTAL_SELLING_PRICE |
|------------|-----------|-----------|------------------|----------------|-----------|---------------------|
| John       | Smith     | 3         | 1225.00          | 102.00         | 51.00     | 1072.00             |

**Calculation Breakdown**:
- Orders: Laptop (1200) + Mouse (25) = 1225
- Discounts: 100 + 2 = 102
- Taxes: 50 + 1 = 51
- Selling Price: 1225 - 102 - 51 = 1072

**✅ PASS Criteria**:
- TOTAL_SELLING_PRICE = 1072.00
- Aggregation sums correctly

**❌ FAIL Criteria**:
- If TOTAL_SELLING_PRICE ≠ 1072.00
- If aggregation fails

---

### TC-005: Inner Join Behavior - Products Without Sales
**Objective**: Verify that products without sales don't appear (inner join behavior)

**Test Query**:
```sql
SELECT PRODUCT_NAME
FROM CV_TEST
WHERE PRODUCT_NAME = 'Discontinued Item';
```

**Expected Results**:
- **0 rows returned** (empty result set)

**✅ PASS Criteria**:
- No rows returned
- Product ID 999 (Discontinued Item) not in results

**❌ FAIL Criteria**:
- If 'Discontinued Item' appears in results

---

### TC-006: Complete Output Schema - Verify All Expected Columns
**Objective**: Confirm all expected attributes and measures are present

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    QUANTITY,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SHIPPING_AMOUNT,
    SELLING_PRICE
FROM CV_TEST
LIMIT 1;
```

**Expected Results**:
- All 9 columns returned
- No errors

**✅ PASS Criteria**:
- All columns exist
- No NULL column names
- Data types correct (DECIMAL for numeric fields, VARCHAR for names)

**❌ FAIL Criteria**:
- If any column is missing
- If PRODUCT_ID appears instead of PRODUCT_NAME
- If column order is incorrect

---

### TC-007: Edge Case - Zero Discount and Tax
**Objective**: Verify SELLING_PRICE when discount and tax are zero

**Setup**: Bob's USB Cable order (DISCOUNT=0.50, TAX=0.25)

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE
FROM CV_TEST
WHERE FIRST_NAME = 'Bob';
```

**Expected Results**:
| FIRST_NAME | PRODUCT_NAME | UNIT_PRICE | DISCOUNT | TAX  | SELLING_PRICE |
|------------|--------------|------------|----------|------|---------------|
| Bob        | USB Cable    | 5.00       | 0.50     | 0.25 | 4.25          |

**✅ PASS Criteria**:
- SELLING_PRICE = 4.25 (5.00 - 0.50 - 0.25)
- Small decimal values handled correctly

**❌ FAIL Criteria**:
- If rounding errors occur
- If calculation is incorrect

---

### TC-008: Multiple Products per Customer
**Objective**: Verify correct handling when one customer has multiple orders

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    SELLING_PRICE
FROM CV_TEST
WHERE FIRST_NAME = 'John'
ORDER BY PRODUCT_NAME;
```

**Expected Results**:
| FIRST_NAME | PRODUCT_NAME    | SELLING_PRICE |
|------------|-----------------|---------------|
| John       | Laptop Computer | 1050.00       |
| John       | Wireless Mouse  | 22.00         |

**✅ PASS Criteria**:
- 2 rows returned for John
- Both products correctly calculated

**❌ FAIL Criteria**:
- If products are merged incorrectly
- If only 1 row returned

---

## NEGATIVE TEST CASES (What Should NOT Happen)

### TC-N001: Inactive Customers Should NOT Appear
**Objective**: Confirm customers with STATUS ≠ 'Active' are filtered out

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    LAST_NAME
FROM CV_TEST
WHERE FIRST_NAME IN ('Jane', 'Mike', 'Sarah');
```

**Expected Results**:
- **0 rows returned**

**✅ PASS Criteria**:
- No rows for Jane (Inactive)
- No rows for Mike (Pending)
- No rows for Sarah (NULL status)

**❌ FAIL Criteria**:
- If any of these customers appear
- Filter not working

**Why This Should NOT Happen**:
- Filter explicitly requires STATUS = 'Active'
- Inactive/Pending/NULL statuses should be excluded

---

### TC-N002: Product ID Should NOT Appear in Results
**Objective**: Verify PRODUCT_ID column is not exposed

**Test Query**:
```sql
-- This query should FAIL with column not found error
SELECT PRODUCT_ID FROM CV_TEST;
```

**Expected Results**:
- **ERROR**: Column 'PRODUCT_ID' not found or invalid column name

**✅ PASS Criteria**:
- Query fails with column not found error
- PRODUCT_ID is not accessible in output

**❌ FAIL Criteria**:
- If query succeeds
- If PRODUCT_ID values are returned

**Why This Should NOT Happen**:
- PRODUCT_ID was replaced with PRODUCT_NAME
- Only PRODUCT_NAME should be in logical model

---

### TC-N003: Sales Without Matching Products Should NOT Appear
**Objective**: Verify orphan sales (no matching product) are excluded due to inner join

**Test Query**:
```sql
-- Check if order ORD007 (Product 888 - doesn't exist) appears
SELECT * FROM CV_TEST WHERE ORDER_NUMBER = 'ORD007';
```

**Expected Results**:
- **0 rows returned**

**✅ PASS Criteria**:
- ORD007 not in results
- Inner join correctly filters non-matching products

**❌ FAIL Criteria**:
- If ORD007 appears
- If NULL product names appear

**Why This Should NOT Happen**:
- Inner join on PRODUCT_ID requires match in both tables
- Product ID 888 doesn't exist in PRODUCTS table

---

### TC-N004: Negative SELLING_PRICE Should NOT Occur (Data Quality Issue)
**Objective**: Identify if discounts/taxes exceed unit price (data quality issue)

**Test Scenario**: If DISCOUNT + TAX > UNIT_PRICE

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE
FROM CV_TEST
WHERE SELLING_PRICE < 0;
```

**Expected Results** (with clean data):
- **0 rows returned**

**✅ PASS Criteria** (Data Quality Check):
- No negative SELLING_PRICE values
- All values ≥ 0

**❌ FAIL Criteria** (Indicates Data Problem):
- If negative values appear
- This indicates data integrity issue in source tables

**Why This Should NOT Happen**:
- Business rule: Selling price should never be negative
- If it occurs, indicates bad data in SALES table

---

### TC-N005: Customer STATUS Column Should NOT Appear in Output
**Objective**: Verify STATUS column is used for filtering but not exposed

**Test Query**:
```sql
-- This should FAIL
SELECT STATUS FROM CV_TEST;
```

**Expected Results**:
- **ERROR**: Column 'STATUS' not found

**✅ PASS Criteria**:
- Query fails
- STATUS not accessible

**❌ FAIL Criteria**:
- If STATUS column is returned
- Column was meant for filtering only

**Why This Should NOT Happen**:
- STATUS is in PR_CUSTOMERS but not in JN_CUST_SALES view attributes
- Not mapped to logical model

---

### TC-N006: NULL Values Should NOT Break Calculations
**Objective**: Verify NULL handling in SELLING_PRICE calculation

**Test Scenario**: If any of UNIT_PRICE, DISCOUNT_AMOUNT, or TAX_AMOUNT is NULL

**Setup** (if such data exists):
```sql
-- Theoretical test - assumes NULL values in source
SELECT 
    FIRST_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE
FROM CV_TEST
WHERE UNIT_PRICE IS NULL 
   OR DISCOUNT_AMOUNT IS NULL 
   OR TAX_AMOUNT IS NULL;
```

**Expected Results** (with clean data):
- **0 rows** (no NULLs in test data)

**Alternative Expected Result** (if NULLs exist):
- SELLING_PRICE should be NULL (NULL arithmetic = NULL)

**✅ PASS Criteria**:
- Either no rows with NULLs, or SELLING_PRICE is NULL
- No error/exception

**❌ FAIL Criteria**:
- If calculation throws error
- If NULL is treated as 0 incorrectly

**Why This Should NOT Happen**:
- Source tables should have NOT NULL constraints
- If NULLs exist, calculation should handle gracefully

---

### TC-N007: Duplicate Records Should NOT Appear
**Objective**: Verify no cartesian product or duplicate results

**Test Query**:
```sql
SELECT 
    FIRST_NAME,
    LAST_NAME,
    ORDER_NUMBER,
    PRODUCT_NAME,
    COUNT(*) as DUPLICATE_COUNT
FROM CV_TEST
GROUP BY FIRST_NAME, LAST_NAME, ORDER_NUMBER, PRODUCT_NAME
HAVING COUNT(*) > 1;
```

**Expected Results**:
- **0 rows returned**

**✅ PASS Criteria**:
- No duplicates found
- Each order appears exactly once

**❌ FAIL Criteria**:
- If any duplicates found
- Indicates join problem

**Why This Should NOT Happen**:
- Joins are on primary/foreign keys
- Should be 1:1 relationship (one sale to one product)

---

### TC-N008: Performance - Large Result Sets Should NOT Time Out
**Objective**: Verify filter reduces data volume appropriately

**Test Query**:
```sql
-- Check total row count
SELECT COUNT(*) as TOTAL_ROWS FROM CV_TEST;
```

**Expected Results**:
- Row count should equal: (Active Customers) × (Their Orders with Valid Products)
- With test data: 4 rows (John: 2 orders, Bob: 1 order, Alice: 1 order)

**✅ PASS Criteria**:
- Query completes in reasonable time (<5 seconds)
- Row count matches expected

**❌ FAIL Criteria**:
- If result includes inactive customer orders (should be 4 rows, not 6)
- If query times out

**Why This Should NOT Happen**:
- Filter applied early (at projection)
- Reduces data processed in joins

---

## BOUNDARY & EDGE CASES

### TC-E001: Zero Values in Price Fields
**Test Scenario**: UNIT_PRICE = 0, DISCOUNT = 0, TAX = 0

**Expected**: SELLING_PRICE = 0 (valid calculation)

---

### TC-E002: Very Large Decimal Values
**Test Scenario**: UNIT_PRICE = 999999999999.99

**Expected**: Calculation works without overflow, result within DECIMAL(15,2)

---

### TC-E003: Precision Test - Decimal Places
**Test Scenario**: Values with 2 decimal places

**Expected**: Result maintains 2 decimal places, no rounding errors

---

## DATA VALIDATION CHECKLIST

### Before Running Tests:

- [ ] CUSTOMERS table has both Active and Inactive records
- [ ] PRODUCTS table has product names populated
- [ ] SALES table has data for both active and inactive customers
- [ ] At least one orphan sale (product doesn't exist)
- [ ] At least one orphan product (no sales)
- [ ] Numeric fields have no NULLs (unless testing NULL handling)

### After Running Tests:

- [ ] All positive test cases passed
- [ ] All negative test cases confirmed expected "not found" behavior
- [ ] No unexpected data appears
- [ ] Performance is acceptable
- [ ] Calculation accuracy verified

---

## EXPECTED vs NOT EXPECTED - Quick Reference

### ✅ EXPECTED (Should Happen):

| Behavior | Description |
|----------|-------------|
| Only Active customers | Customers with STATUS='Active' only |
| Product names visible | PRODUCT_NAME instead of PRODUCT_ID |
| SELLING_PRICE calculated | Formula: UNIT_PRICE - DISCOUNT - TAX |
| Aggregation works | SUM(SELLING_PRICE) aggregates correctly |
| Inner join behavior | Only matching records from all tables |
| 4 rows in test data | John (2), Bob (1), Alice (1) orders |

### ❌ NOT EXPECTED (Should NOT Happen):

| Behavior | Description |
|----------|-------------|
| Inactive customers appear | Jane, Mike, Sarah should NOT appear |
| PRODUCT_ID visible | Only PRODUCT_NAME should be exposed |
| STATUS column in output | STATUS used for filter, not output |
| Negative SELLING_PRICE | Would indicate data quality issue |
| Orphan products in results | Products without sales excluded |
| Orphan sales in results | Sales without products excluded |
| Duplicate records | No cartesian products |
| NULL in calculations | Should handle gracefully or be prevented |

---

## TEST EXECUTION SUMMARY TEMPLATE

```
Test Execution Date: _______________
Tester Name: _______________
Environment: _______________

Positive Test Cases:
  TC-001: [ ] Pass  [ ] Fail
  TC-002: [ ] Pass  [ ] Fail
  TC-003: [ ] Pass  [ ] Fail
  TC-004: [ ] Pass  [ ] Fail
  TC-005: [ ] Pass  [ ] Fail
  TC-006: [ ] Pass  [ ] Fail
  TC-007: [ ] Pass  [ ] Fail
  TC-008: [ ] Pass  [ ] Fail

Negative Test Cases:
  TC-N001: [ ] Pass  [ ] Fail
  TC-N002: [ ] Pass  [ ] Fail
  TC-N003: [ ] Pass  [ ] Fail
  TC-N004: [ ] Pass  [ ] Fail
  TC-N005: [ ] Pass  [ ] Fail
  TC-N006: [ ] Pass  [ ] Fail
  TC-N007: [ ] Pass  [ ] Fail
  TC-N008: [ ] Pass  [ ] Fail

Edge Cases:
  TC-E001: [ ] Pass  [ ] Fail
  TC-E002: [ ] Pass  [ ] Fail
  TC-E003: [ ] Pass  [ ] Fail

Overall Result: [ ] All Pass  [ ] Some Failures

Comments/Issues:
_________________________________
_________________________________
```

---

## SQL Script - Run All Tests

```sql
-- ============================================
-- CV_TEST 1 - Complete Test Suite
-- ============================================

PRINT '=== Starting Test Suite for CV_TEST 1 ===';

-- TC-001: Active Customers Only
PRINT 'TC-001: Active Customer Filter';
SELECT DISTINCT FIRST_NAME, LAST_NAME FROM CV_TEST ORDER BY FIRST_NAME;
-- Expected: Alice, Bob, John (3 customers)

-- TC-002: Product Names
PRINT 'TC-002: Product Names Display';
SELECT PRODUCT_NAME, COUNT(*) as ORDER_COUNT 
FROM CV_TEST 
GROUP BY PRODUCT_NAME 
ORDER BY PRODUCT_NAME;
-- Expected: 4 products with names (not IDs)

-- TC-003: SELLING_PRICE Calculation
PRINT 'TC-003: SELLING_PRICE Formula';
SELECT 
    FIRST_NAME, PRODUCT_NAME, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SELLING_PRICE,
    (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT) as EXPECTED
FROM CV_TEST
WHERE FIRST_NAME = 'John' AND PRODUCT_NAME = 'Laptop Computer';
-- Expected: SELLING_PRICE = 1050.00

-- TC-004: Aggregation
PRINT 'TC-004: SELLING_PRICE Aggregation';
SELECT 
    FIRST_NAME,
    SUM(SELLING_PRICE) as TOTAL_SELLING_PRICE
FROM CV_TEST
WHERE FIRST_NAME = 'John'
GROUP BY FIRST_NAME;
-- Expected: 1072.00

-- TC-N001: Inactive Customers
PRINT 'TC-N001: Inactive Customers Should NOT Appear';
SELECT COUNT(*) as INACTIVE_COUNT
FROM CV_TEST
WHERE FIRST_NAME IN ('Jane', 'Mike', 'Sarah');
-- Expected: 0 rows

-- TC-N007: Duplicate Check
PRINT 'TC-N007: No Duplicates';
SELECT 
    FIRST_NAME, ORDER_NUMBER, COUNT(*) as DUP_COUNT
FROM CV_TEST
GROUP BY FIRST_NAME, ORDER_NUMBER
HAVING COUNT(*) > 1;
-- Expected: 0 rows

PRINT '=== Test Suite Complete ===';
```

---

## Troubleshooting Guide

### If Tests Fail:

1. **TC-001 Fails** (Wrong customers appear)
   - Check: PR_CUSTOMERS filter syntax
   - Verify: STATUS column values in CUSTOMERS table
   - Look for: Missing filter or incorrect filter condition

2. **TC-002 Fails** (Product IDs instead of names)
   - Check: JN_SALES_PRODUCTS join configuration
   - Verify: PRODUCT_NAME in view attributes
   - Look for: Missing join or incorrect mapping

3. **TC-003 Fails** (Wrong SELLING_PRICE)
   - Check: Formula in calculatedMeasures section
   - Verify: Column references use double quotes
   - Look for: Typo in formula or wrong operator

4. **TC-N001 Fails** (Inactive customers appear)
   - Check: Filter is applied and not commented out
   - Verify: Filter syntax: `&quot;STATUS&quot; = 'Active'`
   - Look for: XML encoding issues with quotes

---

## Conclusion

This test suite provides comprehensive coverage of:
- ✅ 8 Positive test cases (expected behavior)
- ❌ 8 Negative test cases (what should not happen)
- 🔍 3 Edge cases (boundary conditions)

**Total**: 19 test scenarios covering all aspects of the calculation view changes.
