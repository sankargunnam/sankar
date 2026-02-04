# CV_TEST 1 - SQL Validation Scripts

This directory contains comprehensive SQL scripts to validate all changes made to the **CV_TEST 1.hdbcalculationview** calculation view.

## 📋 Overview

The scripts test three major features:
1. **Products Join** - PRODUCT_NAME displayed instead of PRODUCT_ID
2. **SELLING_PRICE Calculated Measure** - Formula: UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT
3. **Active Customer Filter** - Only STATUS='Active' customers included

---

## 🚀 Quick Start

### Option 1: Run Complete Test Suite (Recommended)
```sql
-- Single script that runs all validations
\i 05_run_all_tests.sql
```

### Option 2: Run Individual Scripts
```sql
-- Step 1: Setup test data
\i 01_setup_test_data.sql

-- Step 2: Run positive tests
\i 02_positive_tests.sql

-- Step 3: Run negative tests
\i 03_negative_tests.sql

-- Step 4: Run edge cases
\i 04_edge_cases.sql

-- Step 5: Cleanup (optional)
\i 06_cleanup_test_data.sql
```

---

## 📁 Script Files

### 01_setup_test_data.sql
**Purpose**: Creates test data for validation  
**Duration**: < 5 seconds  
**Action**: Inserts test records into CUSTOMERS, PRODUCTS, and SALES tables

**Test Data Created**:
- 6 Customers (3 Active, 3 Inactive/Pending/NULL)
- 5 Products (4 with sales, 1 orphan)
- 7 Sales records (4 valid, 2 filtered, 1 orphan)

**Expected Output**: Confirmation of 6 customers, 5 products, 7 sales inserted

---

### 02_positive_tests.sql
**Purpose**: Validate expected behaviors (what SHOULD happen)  
**Duration**: < 10 seconds  
**Tests**: 8 positive test cases

**Test Cases**:
- TC-001: Active Customer Filter (expect 3 customers)
- TC-002: Product Names Display (expect text, not IDs)
- TC-003: SELLING_PRICE Calculation (verify formula)
- TC-004: SELLING_PRICE Aggregation (verify SUM works)
- TC-005: Inner Join Behavior (orphan products excluded)
- TC-006: Complete Output Schema (all 9 columns present)
- TC-007: Small Decimal Values (Bob's USB Cable = 4.25)
- TC-008: Multiple Products per Customer (John has 2 orders)

**Expected**: All tests show ✓ PASS

---

### 03_negative_tests.sql
**Purpose**: Validate what should NOT happen  
**Duration**: < 10 seconds  
**Tests**: 8 negative test cases

**Test Cases**:
- TC-N001: Inactive Customers Should NOT Appear (Jane, Mike, Sarah)
- TC-N002: PRODUCT_ID Should NOT Be Accessible
- TC-N003: Orphan Sales Should NOT Appear (ORD007)
- TC-N004: Negative SELLING_PRICE Should NOT Occur
- TC-N005: STATUS Column Should NOT Be Accessible
- TC-N006: NULL Values Should NOT Break Calculations
- TC-N007: Duplicate Records Should NOT Appear
- TC-N008: Query Should NOT Time Out

**Expected**: All validations confirm unwanted behaviors prevented

---

### 04_edge_cases.sql
**Purpose**: Test boundary conditions and edge cases  
**Duration**: < 10 seconds  
**Tests**: 9 edge case scenarios

**Test Cases**:
- TC-E001: Zero Values Handling
- TC-E002: Decimal Precision (2 decimal places)
- TC-E003: Large Value Handling (1200.00)
- TC-E004: Aggregation with Mixed Values
- TC-E005: Single vs Multiple Order Aggregation
- TC-E006: Product-Level Aggregation
- TC-E007: Empty Result Set Handling
- TC-E008: Conditional Logic Test
- TC-E009: Join Cardinality Verification

**Expected**: All edge cases handled correctly

---

### 05_run_all_tests.sql
**Purpose**: Execute complete test suite in one script  
**Duration**: < 30 seconds  
**Includes**:
- Quick validation summary (5 tests)
- Detailed data validation
- Formula verification for all rows
- Aggregation tests
- Product analysis
- Filter effectiveness check
- Data quality checks
- Expected vs Actual summary
- Final summary

**Expected**: All validations show ✓ PASS

---

### 06_cleanup_test_data.sql
**Purpose**: Remove test data after validation  
**Duration**: < 5 seconds  
**Action**: Deletes test records from all tables

**⚠️ Warning**: This permanently deletes test data. Only run after testing is complete.

---

## ✅ Expected Results

### With Test Data Loaded

```
Total Rows:           4
Distinct Customers:   3 (John, Bob, Alice)
Distinct Products:    4 (Laptop, Mouse, Cable, Monitor)
Inactive Customers:   0 (Jane, Mike, Sarah filtered out)
```

### Sample Output

```
FIRST_NAME | LAST_NAME | PRODUCT_NAME     | UNIT_PRICE | DISCOUNT | TAX   | SELLING_PRICE
-----------|-----------|------------------|------------|----------|-------|---------------
John       | Smith     | Laptop Computer  | 1200.00    | 100.00   | 50.00 | 1050.00
John       | Smith     | Wireless Mouse   | 25.00      | 2.00     | 1.00  | 22.00
Bob        | Johnson   | USB Cable        | 5.00       | 0.50     | 0.25  | 4.25
Alice      | Williams  | External Monitor | 300.00     | 30.00    | 15.00 | 255.00
```

---

## 📊 Test Coverage Summary

| Category | Test Count | Description |
|----------|------------|-------------|
| Positive Tests | 8 | Expected behaviors |
| Negative Tests | 8 | What should NOT happen |
| Edge Cases | 9 | Boundary conditions |
| **Total** | **25** | **Complete coverage** |

---

## 🎯 Pass/Fail Criteria

### All Tests PASS If:
- ✓ Only 3 active customers in results
- ✓ Product names (not IDs) displayed
- ✓ SELLING_PRICE calculated correctly (UNIT_PRICE - DISCOUNT - TAX)
- ✓ No inactive customers appear
- ✓ No duplicate records
- ✓ Aggregation (SUM) works correctly
- ✓ All data quality checks pass

### Tests FAIL If:
- ✗ Any inactive customer appears
- ✗ PRODUCT_ID visible instead of name
- ✗ SELLING_PRICE calculation wrong
- ✗ STATUS column in output
- ✗ Negative SELLING_PRICE values
- ✗ Duplicate rows exist

---

## 🔧 Troubleshooting

### Issue: "Table not found" error
**Solution**: Ensure SGUNNAM schema exists and you have access rights

### Issue: "Calculation view not found"
**Solution**: Activate CV_TEST 1.hdbcalculationview in HANA first

### Issue: Test data already exists
**Solution**: Run `06_cleanup_test_data.sql` first, then re-run setup

### Issue: Wrong number of rows
**Solution**: 
1. Check if calculation view is activated
2. Verify test data setup completed successfully
3. Ensure no other test data conflicts

---

## 📝 Notes

### Test Data IDs
- Customer IDs: 1-6
- Product IDs: 101-104, 888, 999
- Order Numbers: ORD001-ORD007

These IDs are chosen to avoid conflicts with production data.

### Execution Order
1. **Always** run `01_setup_test_data.sql` first
2. Run test scripts in any order (they're independent)
3. **Optionally** run `06_cleanup_test_data.sql` at the end

### Re-running Tests
You can re-run test scripts multiple times without re-running setup. The test data remains until you run the cleanup script.

---

## 📚 Related Documentation

- **Test Cases**: `../CV_TEST_1_TEST_CASES.md` - Detailed test documentation
- **Quick Reference**: `../CV_TEST_1_QUICK_REFERENCE.md` - Quick validation guide
- **Calculation View**: `../CV_TEST 1.hdbcalculationview` - The view being tested

---

## ✨ Features

✅ **Comprehensive** - 25 test scenarios covering all changes  
✅ **Automated** - SQL scripts run automatically  
✅ **Self-Validating** - Scripts show PASS/FAIL for each test  
✅ **Independent** - Each test script can run standalone  
✅ **Clean** - Cleanup script removes test data  
✅ **Production-Ready** - Professional test framework  

---

## 🎓 Usage Examples

### Example 1: Quick Validation
```sql
-- Just want to verify it works?
\i 05_run_all_tests.sql
-- Look for all ✓ PASS indicators
```

### Example 2: Detailed Testing
```sql
-- Want detailed test results?
\i 01_setup_test_data.sql
\i 02_positive_tests.sql
\i 03_negative_tests.sql
\i 04_edge_cases.sql
\i 06_cleanup_test_data.sql
```

### Example 3: Specific Feature Testing
```sql
-- Only test SELLING_PRICE calculation?
\i 01_setup_test_data.sql
-- Then look at TC-003 and TC-004 in 02_positive_tests.sql
```

---

## 🆘 Support

If tests fail:
1. Review the specific test case that failed
2. Check calculation view definition
3. Verify filter syntax in PR_CUSTOMERS
4. Validate join configuration in JN_SALES_PRODUCTS
5. Confirm formula in calculatedMeasures

---

## Summary

This comprehensive SQL test suite provides:
- **25 automated test scenarios**
- **Self-validating scripts** with PASS/FAIL indicators
- **Complete test data setup and cleanup**
- **Production-ready** validation framework

All scripts are ready to execute in SAP HANA immediately!
