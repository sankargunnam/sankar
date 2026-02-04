# CV_TEST 1 - Test Cases Quick Reference

## Overview
This document provides a quick reference for testing CV_TEST 1.hdbcalculationview changes.

---

## 🎯 What We're Testing

### 3 Major Changes:
1. **Products Join** - PRODUCT_NAME instead of PRODUCT_ID
2. **SELLING_PRICE** - Calculated measure (UNIT_PRICE - DISCOUNT - TAX)
3. **Active Filter** - Only customers with STATUS='Active'

---

## ✅ EXPECTED RESULTS - Quick Checklist

### Query: `SELECT * FROM CV_TEST`

**Should See:**
- ✓ Only Active customers (John, Bob, Alice)
- ✓ Product names (Laptop Computer, Wireless Mouse, etc.)
- ✓ SELLING_PRICE column with calculated values
- ✓ 4 total rows (with test data)

**Should NOT See:**
- ✗ Inactive customers (Jane, Mike, Sarah)
- ✗ PRODUCT_ID numbers (101, 102, 103)
- ✗ STATUS column in output
- ✗ Negative SELLING_PRICE values
- ✗ Duplicate records

---

## 📊 Sample Expected Output

```
FIRST_NAME | LAST_NAME | PRODUCT_NAME     | UNIT_PRICE | DISCOUNT | TAX   | SELLING_PRICE
-----------|-----------|------------------|------------|----------|-------|---------------
John       | Smith     | Laptop Computer  | 1200.00    | 100.00   | 50.00 | 1050.00
John       | Smith     | Wireless Mouse   | 25.00      | 2.00     | 1.00  | 22.00
Bob        | Johnson   | USB Cable        | 5.00       | 0.50     | 0.25  | 4.25
Alice      | Williams  | External Monitor | 300.00     | 30.00    | 15.00 | 255.00
```

---

## 🧪 Quick Test Queries

### Test 1: Count Active Customers
```sql
SELECT COUNT(DISTINCT FIRST_NAME) FROM CV_TEST;
-- Expected: 3 (John, Bob, Alice)
```

### Test 2: Verify SELLING_PRICE Formula
```sql
SELECT 
    UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT as MANUAL,
    SELLING_PRICE as CALCULATED
FROM CV_TEST
WHERE FIRST_NAME = 'John' AND PRODUCT_NAME = 'Laptop Computer';
-- Expected: MANUAL = CALCULATED = 1050.00
```

### Test 3: Check for Inactive Customers
```sql
SELECT COUNT(*) FROM CV_TEST WHERE FIRST_NAME = 'Jane';
-- Expected: 0 (Jane is Inactive)
```

### Test 4: Verify Product Names
```sql
SELECT DISTINCT PRODUCT_NAME FROM CV_TEST ORDER BY PRODUCT_NAME;
-- Expected: Names, not IDs
```

---

## ❌ Common Issues & Solutions

### Issue 1: Inactive Customers Appear
**Problem**: Jane, Mike, or Sarah in results  
**Cause**: Filter not working  
**Fix**: Check PR_CUSTOMERS filter: `"STATUS" = 'Active'`

### Issue 2: Product IDs Instead of Names
**Problem**: Seeing 101, 102 instead of "Laptop Computer"  
**Cause**: Join not working or PRODUCT_NAME not mapped  
**Fix**: Verify JN_SALES_PRODUCTS join on PRODUCT_ID

### Issue 3: Wrong SELLING_PRICE
**Problem**: Calculation doesn't match formula  
**Cause**: Formula error or wrong columns  
**Fix**: Verify formula: `("UNIT_PRICE" - "DISCOUNT_AMOUNT" - "TAX_AMOUNT")`

### Issue 4: STATUS Column Visible
**Problem**: STATUS appears in output  
**Cause**: STATUS incorrectly mapped to output  
**Fix**: STATUS should only be in PR_CUSTOMERS for filtering

---

## 📝 Test Data Requirements

### Minimum Test Data Needed:

**CUSTOMERS:**
- 3 Active customers (should appear)
- 2+ Inactive customers (should NOT appear)

**PRODUCTS:**
- 4+ products with names

**SALES:**
- 4+ orders for active customers
- 2+ orders for inactive customers (to test filter)

---

## 🎯 Pass/Fail Criteria

### All Tests PASS If:
- ✅ Only 3 active customers in results
- ✅ Product names (not IDs) displayed
- ✅ SELLING_PRICE calculated correctly
- ✅ No inactive customers
- ✅ No duplicate records
- ✅ Aggregation (SUM) works correctly

### Tests FAIL If:
- ❌ Any inactive customer appears
- ❌ PRODUCT_ID visible instead of name
- ❌ SELLING_PRICE calculation wrong
- ❌ STATUS column in output
- ❌ Negative SELLING_PRICE values
- ❌ Duplicate rows

---

## 🚀 Quick Validation Script

```sql
-- Run this to quickly validate all major functionality
-- Should take < 30 seconds

-- 1. Active Customers Only (expect 3)
SELECT 'Test 1: Active Customers' as TEST, COUNT(DISTINCT FIRST_NAME) as RESULT FROM CV_TEST;

-- 2. Product Names Not IDs (should see text, not numbers)
SELECT 'Test 2: Product Names' as TEST, MIN(PRODUCT_NAME) as RESULT FROM CV_TEST;

-- 3. SELLING_PRICE Exists (should return number)
SELECT 'Test 3: SELLING_PRICE' as TEST, MAX(SELLING_PRICE) as RESULT FROM CV_TEST;

-- 4. Inactive Customers Excluded (expect 0)
SELECT 'Test 4: No Inactive' as TEST, COUNT(*) as RESULT FROM CV_TEST WHERE FIRST_NAME IN ('Jane', 'Mike');

-- 5. No Duplicates (expect 0)
SELECT 'Test 5: No Duplicates' as TEST, COUNT(*) as RESULT FROM (
    SELECT ORDER_NUMBER, COUNT(*) as C FROM CV_TEST GROUP BY ORDER_NUMBER HAVING COUNT(*) > 1
) X;
```

**Expected Results:**
```
TEST                      | RESULT
--------------------------|--------
Test 1: Active Customers  | 3
Test 2: Product Names     | External Monitor (or other name)
Test 3: SELLING_PRICE     | 1050.00 (or highest value)
Test 4: No Inactive       | 0
Test 5: No Duplicates     | 0
```

---

## 📚 Related Documents

- **Full Test Cases**: `CV_TEST_1_TEST_CASES.md`
- **Calculation View**: `CV_TEST 1.hdbcalculationview`
- **Change History**: Git commits 00b06a2 and d76285f

---

## 🆘 Need Help?

If tests fail:
1. Check test data is loaded correctly
2. Verify calculation view is activated in HANA
3. Review filter syntax in PR_CUSTOMERS
4. Check join configuration in JN_SALES_PRODUCTS
5. Validate formula in calculatedMeasures

---

## Summary

- **19 Total Test Cases** (8 positive, 8 negative, 3 edge cases)
- **3 Key Features** tested comprehensively
- **Quick validation** available with 5-query script
- **Clear pass/fail** criteria for each test

✅ Use this as your go-to reference for quick validation!
