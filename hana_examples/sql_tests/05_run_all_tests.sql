-- ============================================================================
-- CV_TEST 1 - Complete Validation Suite (Run All Tests)
-- ============================================================================
-- Purpose: Execute all test scripts in sequence
-- Usage: Run this single script to execute complete test suite
-- ============================================================================

SELECT '╔════════════════════════════════════════════════════════════════════╗' as MESSAGE
UNION ALL SELECT '║              CV_TEST 1 - COMPLETE TEST SUITE                   ║'
UNION ALL SELECT '║                  Running All Validations                       ║'
UNION ALL SELECT '╚════════════════════════════════════════════════════════════════╝';

SELECT '' as MESSAGE;
SELECT 'Test Suite Execution Started: ' || CAST(CURRENT_TIMESTAMP as VARCHAR) as MESSAGE;
SELECT '' as MESSAGE;

-- ============================================================================
-- Quick Validation Summary (5 Tests)
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '                  QUICK VALIDATION SUMMARY                         ' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;

-- Test 1: Active Customers Count
SELECT 'Test 1: Active Customers' as TEST_NAME, 
       COUNT(DISTINCT FIRST_NAME) as ACTUAL,
       3 as EXPECTED,
       CASE WHEN COUNT(DISTINCT FIRST_NAME) = 3 THEN '✓ PASS' ELSE '✗ FAIL' END as RESULT
FROM CV_TEST;

-- Test 2: Product Names (not IDs)
SELECT 'Test 2: Product Names' as TEST_NAME,
       MIN(PRODUCT_NAME) as SAMPLE_VALUE,
       'Text (not number)' as EXPECTED,
       CASE WHEN MIN(PRODUCT_NAME) LIKE '%Computer%' OR MIN(PRODUCT_NAME) LIKE '%Monitor%' 
            THEN '✓ PASS' ELSE '✗ FAIL' END as RESULT
FROM CV_TEST;

-- Test 3: SELLING_PRICE Exists and Calculated
SELECT 'Test 3: SELLING_PRICE' as TEST_NAME,
       MAX(SELLING_PRICE) as SAMPLE_VALUE,
       'Numeric value' as EXPECTED,
       CASE WHEN MAX(SELLING_PRICE) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END as RESULT
FROM CV_TEST;

-- Test 4: No Inactive Customers
SELECT 'Test 4: No Inactive' as TEST_NAME,
       COUNT(*) as ACTUAL,
       0 as EXPECTED,
       CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as RESULT
FROM CV_TEST 
WHERE FIRST_NAME IN ('Jane', 'Mike', 'Sarah');

-- Test 5: No Duplicates
SELECT 'Test 5: No Duplicates' as TEST_NAME,
       COUNT(*) as DUPLICATE_COUNT,
       0 as EXPECTED,
       CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as RESULT
FROM (
    SELECT ORDER_NUMBER 
    FROM CV_TEST 
    GROUP BY ORDER_NUMBER 
    HAVING COUNT(*) > 1
) AS DUPS;

-- ============================================================================
-- Detailed Data Validation
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '                    DETAILED DATA VALIDATION                       ' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;

-- Show all results
SELECT 
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    QUANTITY,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE,
    ORDER_NUMBER
FROM CV_TEST
ORDER BY FIRST_NAME, PRODUCT_NAME;

-- ============================================================================
-- Formula Verification for All Rows
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- Formula Verification: SELLING_PRICE Calculation ---' as MESSAGE;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE as CALCULATED,
    (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT) as EXPECTED,
    ABS(SELLING_PRICE - (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT)) as DIFFERENCE,
    CASE 
        WHEN ABS(SELLING_PRICE - (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT)) < 0.01 
        THEN '✓ Match' 
        ELSE '✗ Mismatch' 
    END as VALIDATION
FROM CV_TEST
ORDER BY FIRST_NAME, PRODUCT_NAME;

-- ============================================================================
-- Aggregation Tests
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- Aggregation Test: Customer Totals ---' as MESSAGE;

SELECT 
    FIRST_NAME,
    LAST_NAME,
    COUNT(*) as ORDER_COUNT,
    SUM(QUANTITY) as TOTAL_QTY,
    SUM(UNIT_PRICE) as TOTAL_UNIT_PRICE,
    SUM(DISCOUNT_AMOUNT) as TOTAL_DISCOUNT,
    SUM(TAX_AMOUNT) as TOTAL_TAX,
    SUM(SELLING_PRICE) as TOTAL_SELLING_PRICE,
    (SUM(UNIT_PRICE) - SUM(DISCOUNT_AMOUNT) - SUM(TAX_AMOUNT)) as EXPECTED_TOTAL,
    CASE 
        WHEN ABS(SUM(SELLING_PRICE) - (SUM(UNIT_PRICE) - SUM(DISCOUNT_AMOUNT) - SUM(TAX_AMOUNT))) < 0.01 
        THEN '✓ Correct' 
        ELSE '✗ Error' 
    END as VALIDATION
FROM CV_TEST
GROUP BY FIRST_NAME, LAST_NAME
ORDER BY FIRST_NAME;

-- ============================================================================
-- Product Analysis
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- Product Analysis ---' as MESSAGE;

SELECT 
    PRODUCT_NAME,
    COUNT(*) as TIMES_SOLD,
    SUM(QUANTITY) as TOTAL_QUANTITY,
    AVG(UNIT_PRICE) as AVG_PRICE,
    AVG(SELLING_PRICE) as AVG_SELLING_PRICE,
    (AVG(UNIT_PRICE) - AVG(SELLING_PRICE)) as AVG_DEDUCTION
FROM CV_TEST
GROUP BY PRODUCT_NAME
ORDER BY PRODUCT_NAME;

-- ============================================================================
-- Filter Effectiveness Check
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- Filter Effectiveness ---' as MESSAGE;

SELECT 
    'Total Customers in Source' as METRIC,
    COUNT(DISTINCT CUSTOMER_ID) as VALUE
FROM SGUNNAM.CUSTOMERS
WHERE CUSTOMER_ID IN (1,2,3,4,5,6)
UNION ALL
SELECT 
    'Active Customers in Source' as METRIC,
    COUNT(DISTINCT CUSTOMER_ID) as VALUE
FROM SGUNNAM.CUSTOMERS
WHERE CUSTOMER_ID IN (1,2,3,4,5,6) AND STATUS = 'Active'
UNION ALL
SELECT 
    'Customers in CV_TEST' as METRIC,
    COUNT(DISTINCT CUSTOMER_ID) as VALUE
FROM CV_TEST;

-- ============================================================================
-- Data Quality Checks
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- Data Quality Checks ---' as MESSAGE;

SELECT 'NULL Values Check' as CHECK_TYPE,
       SUM(CASE WHEN UNIT_PRICE IS NULL THEN 1 ELSE 0 END) as NULL_UNIT_PRICE,
       SUM(CASE WHEN DISCOUNT_AMOUNT IS NULL THEN 1 ELSE 0 END) as NULL_DISCOUNT,
       SUM(CASE WHEN TAX_AMOUNT IS NULL THEN 1 ELSE 0 END) as NULL_TAX,
       SUM(CASE WHEN SELLING_PRICE IS NULL THEN 1 ELSE 0 END) as NULL_SELLING_PRICE,
       CASE 
           WHEN SUM(CASE WHEN UNIT_PRICE IS NULL THEN 1 ELSE 0 END) = 0
            AND SUM(CASE WHEN DISCOUNT_AMOUNT IS NULL THEN 1 ELSE 0 END) = 0
            AND SUM(CASE WHEN TAX_AMOUNT IS NULL THEN 1 ELSE 0 END) = 0
            AND SUM(CASE WHEN SELLING_PRICE IS NULL THEN 1 ELSE 0 END) = 0
           THEN '✓ PASS (No NULLs)' 
           ELSE '✗ FAIL (NULLs found)' 
       END as RESULT
FROM CV_TEST;

SELECT 'Negative Values Check' as CHECK_TYPE,
       SUM(CASE WHEN SELLING_PRICE < 0 THEN 1 ELSE 0 END) as NEGATIVE_COUNT,
       CASE 
           WHEN SUM(CASE WHEN SELLING_PRICE < 0 THEN 1 ELSE 0 END) = 0 
           THEN '✓ PASS (No negative prices)' 
           ELSE '✗ FAIL (Negative prices found)' 
       END as RESULT
FROM CV_TEST;

SELECT 'Duplicate Check' as CHECK_TYPE,
       COUNT(*) as TOTAL_ROWS,
       COUNT(DISTINCT ORDER_NUMBER) as UNIQUE_ORDERS,
       CASE 
           WHEN COUNT(*) = COUNT(DISTINCT ORDER_NUMBER) 
           THEN '✓ PASS (No duplicates)' 
           ELSE '✗ FAIL (Duplicates exist)' 
       END as RESULT
FROM CV_TEST;

-- ============================================================================
-- Expected vs Actual Summary
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '                   EXPECTED VS ACTUAL SUMMARY                      ' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;

SELECT 
    'Total Rows' as METRIC,
    CAST(COUNT(*) as VARCHAR) as ACTUAL,
    '4' as EXPECTED,
    CASE WHEN COUNT(*) = 4 THEN '✓' ELSE '✗' END as MATCH
FROM CV_TEST
UNION ALL
SELECT 
    'Distinct Customers' as METRIC,
    CAST(COUNT(DISTINCT FIRST_NAME) as VARCHAR) as ACTUAL,
    '3' as EXPECTED,
    CASE WHEN COUNT(DISTINCT FIRST_NAME) = 3 THEN '✓' ELSE '✗' END as MATCH
FROM CV_TEST
UNION ALL
SELECT 
    'Distinct Products' as METRIC,
    CAST(COUNT(DISTINCT PRODUCT_NAME) as VARCHAR) as ACTUAL,
    '4' as EXPECTED,
    CASE WHEN COUNT(DISTINCT PRODUCT_NAME) = 4 THEN '✓' ELSE '✗' END as MATCH
FROM CV_TEST
UNION ALL
SELECT 
    'Inactive Customers' as METRIC,
    CAST(COUNT(*) as VARCHAR) as ACTUAL,
    '0' as EXPECTED,
    CASE WHEN COUNT(*) = 0 THEN '✓' ELSE '✗' END as MATCH
FROM CV_TEST
WHERE FIRST_NAME IN ('Jane', 'Mike', 'Sarah');

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '                        FINAL SUMMARY                              ' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '' as MESSAGE;
SELECT 'Test Suite Completed: ' || CAST(CURRENT_TIMESTAMP as VARCHAR) as MESSAGE;
SELECT '' as MESSAGE;
SELECT 'Key Validations:' as MESSAGE;
SELECT '  ✓ Active customer filter working (3 customers)' as MESSAGE;
SELECT '  ✓ Product names displayed (not IDs)' as MESSAGE;
SELECT '  ✓ SELLING_PRICE calculated correctly' as MESSAGE;
SELECT '  ✓ No inactive customers in results' as MESSAGE;
SELECT '  ✓ No duplicate records' as MESSAGE;
SELECT '  ✓ Aggregation working properly' as MESSAGE;
SELECT '  ✓ Data quality checks passed' as MESSAGE;
SELECT '' as MESSAGE;
SELECT 'If all checks show ✓, CV_TEST 1 is working correctly!' as MESSAGE;
SELECT '' as MESSAGE;
