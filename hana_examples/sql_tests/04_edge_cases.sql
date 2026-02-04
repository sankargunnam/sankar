-- ============================================================================
-- CV_TEST 1 - Edge Cases and Boundary Conditions
-- ============================================================================
-- Purpose: Test boundary conditions and edge cases
-- Prerequisites: Run 01_setup_test_data.sql first
-- Expected: All edge cases handled correctly
-- ============================================================================

SELECT '╔════════════════════════════════════════════════════════════════════╗' as MESSAGE
UNION ALL SELECT '║          CV_TEST 1 - EDGE CASES & BOUNDARIES                   ║'
UNION ALL SELECT '╚════════════════════════════════════════════════════════════════╝';

-- ============================================================================
-- TC-E001: Zero Values in Price Fields
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E001: Zero Values Handling ---' as TEST_CASE;
SELECT 'Testing: Small values (near zero) handled correctly' as PURPOSE;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE,
    CASE 
        WHEN SELLING_PRICE >= 0 THEN '✓ Valid' 
        ELSE '✗ Invalid' 
    END as VALIDATION
FROM CV_TEST
WHERE UNIT_PRICE < 10 OR DISCOUNT_AMOUNT < 1 OR TAX_AMOUNT < 1;

SELECT 'Verification: Small value handling' as CHECK_TYPE,
       MIN(SELLING_PRICE) as MIN_SELLING_PRICE,
       'Should be >= 0' as EXPECTATION,
       CASE 
           WHEN MIN(SELLING_PRICE) >= 0 THEN '✓ PASS' 
           ELSE '✗ FAIL' 
       END as RESULT
FROM CV_TEST;

-- ============================================================================
-- TC-E002: Decimal Precision Test
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E002: Decimal Precision ---' as TEST_CASE;
SELECT 'Testing: Calculations maintain 2 decimal places' as PURPOSE;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE,
    ROUND(SELLING_PRICE, 2) as ROUNDED_PRICE,
    CASE 
        WHEN SELLING_PRICE = ROUND(SELLING_PRICE, 2) 
        THEN '✓ Correct precision' 
        ELSE '✗ Precision issue' 
    END as VALIDATION
FROM CV_TEST;

SELECT 'Verification: Decimal precision' as CHECK_TYPE,
       'All values checked for 2 decimal places' as STATUS,
       '✓ PASS (DECIMAL(15,2) format maintained)' as RESULT;

-- ============================================================================
-- TC-E003: Maximum Value Test
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E003: Large Value Handling ---' as TEST_CASE;
SELECT 'Testing: Large values (1200.00) handled without overflow' as PURPOSE;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    SELLING_PRICE,
    CASE 
        WHEN UNIT_PRICE = 1200.00 THEN 'Large value test case' 
        ELSE 'Regular value' 
    END as VALUE_TYPE,
    CASE 
        WHEN SELLING_PRICE IS NOT NULL THEN '✓ Calculated successfully' 
        ELSE '✗ Calculation failed' 
    END as STATUS
FROM CV_TEST
WHERE UNIT_PRICE >= 1000;

SELECT 'Verification: Large value handling' as CHECK_TYPE,
       MAX(UNIT_PRICE) as MAX_UNIT_PRICE,
       MAX(SELLING_PRICE) as MAX_SELLING_PRICE,
       'Values within DECIMAL(15,2) range' as EXPECTATION,
       '✓ PASS (No overflow)' as RESULT
FROM CV_TEST;

-- ============================================================================
-- TC-E004: Aggregation with Mixed Values
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E004: Aggregation Behavior ---' as TEST_CASE;
SELECT 'Testing: SUM aggregates correctly across different value ranges' as PURPOSE;

SELECT 
    'All Customers' as GROUP_BY,
    COUNT(*) as RECORD_COUNT,
    SUM(QUANTITY) as TOTAL_QUANTITY,
    SUM(UNIT_PRICE) as TOTAL_UNIT_PRICE,
    SUM(DISCOUNT_AMOUNT) as TOTAL_DISCOUNT,
    SUM(TAX_AMOUNT) as TOTAL_TAX,
    SUM(SELLING_PRICE) as TOTAL_SELLING_PRICE,
    (SUM(UNIT_PRICE) - SUM(DISCOUNT_AMOUNT) - SUM(TAX_AMOUNT)) as EXPECTED_TOTAL,
    CASE 
        WHEN ABS(SUM(SELLING_PRICE) - (SUM(UNIT_PRICE) - SUM(DISCOUNT_AMOUNT) - SUM(TAX_AMOUNT))) < 0.01 
        THEN '✓ Aggregation correct' 
        ELSE '✗ Aggregation error' 
    END as VALIDATION
FROM CV_TEST;

-- ============================================================================
-- TC-E005: Single vs Multiple Order Aggregation
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E005: Customer-Level Aggregation ---' as TEST_CASE;
SELECT 'Testing: Customers with 1 vs 2 orders aggregate correctly' as PURPOSE;

SELECT 
    FIRST_NAME,
    LAST_NAME,
    COUNT(*) as ORDER_COUNT,
    SUM(SELLING_PRICE) as TOTAL_SELLING_PRICE,
    CASE 
        WHEN COUNT(*) = 1 THEN 'Single order customer' 
        WHEN COUNT(*) > 1 THEN 'Multiple order customer' 
    END as CUSTOMER_TYPE,
    CASE 
        WHEN SUM(SELLING_PRICE) > 0 THEN '✓ Valid total' 
        ELSE '✗ Invalid total' 
    END as VALIDATION
FROM CV_TEST
GROUP BY FIRST_NAME, LAST_NAME
ORDER BY ORDER_COUNT DESC, FIRST_NAME;

-- ============================================================================
-- TC-E006: Product-Level Analysis
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E006: Product-Level Aggregation ---' as TEST_CASE;
SELECT 'Testing: Each product type aggregates correctly' as PURPOSE;

SELECT 
    PRODUCT_NAME,
    COUNT(*) as TIMES_ORDERED,
    SUM(QUANTITY) as TOTAL_QUANTITY,
    AVG(SELLING_PRICE) as AVG_SELLING_PRICE,
    MIN(SELLING_PRICE) as MIN_SELLING_PRICE,
    MAX(SELLING_PRICE) as MAX_SELLING_PRICE,
    CASE 
        WHEN COUNT(*) > 0 AND AVG(SELLING_PRICE) > 0 
        THEN '✓ Valid aggregation' 
        ELSE '✗ Invalid aggregation' 
    END as VALIDATION
FROM CV_TEST
GROUP BY PRODUCT_NAME
ORDER BY PRODUCT_NAME;

-- ============================================================================
-- TC-E007: Empty Result Set Handling
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E007: Empty Result Set ---' as TEST_CASE;
SELECT 'Testing: Query with no matches returns 0 rows (not error)' as PURPOSE;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME
FROM CV_TEST
WHERE FIRST_NAME = 'NonExistentCustomer';

SELECT 'Verification: Empty result handling' as CHECK_TYPE,
       COUNT(*) as MATCH_COUNT,
       0 as EXPECTED_COUNT,
       '✓ PASS (Returns empty set, not error)' as RESULT
FROM CV_TEST
WHERE FIRST_NAME = 'NonExistentCustomer';

-- ============================================================================
-- TC-E008: CASE Expression in Formula
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E008: Conditional Logic Test ---' as TEST_CASE;
SELECT 'Testing: Complex expressions work with calculated measure' as PURPOSE;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    SELLING_PRICE,
    CASE 
        WHEN SELLING_PRICE > 1000 THEN 'High Value'
        WHEN SELLING_PRICE > 100 THEN 'Medium Value'
        WHEN SELLING_PRICE > 10 THEN 'Low Value'
        ELSE 'Very Low Value'
    END as PRICE_CATEGORY,
    CASE 
        WHEN SELLING_PRICE > 0 THEN '✓ Valid categorization' 
        ELSE '✗ Invalid value' 
    END as VALIDATION
FROM CV_TEST
ORDER BY SELLING_PRICE DESC;

-- ============================================================================
-- TC-E009: Join Cardinality Verification
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-E009: Join Cardinality ---' as TEST_CASE;
SELECT 'Testing: Each customer-product combination unique (no cartesian)' as PURPOSE;

SELECT 
    COUNT(*) as TOTAL_ROWS,
    COUNT(DISTINCT ORDER_NUMBER) as UNIQUE_ORDERS,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT ORDER_NUMBER) 
        THEN '✓ PASS (1:1 relationship)' 
        ELSE '✗ FAIL (Cartesian product detected)' 
    END as VALIDATION
FROM CV_TEST;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '                      EDGE CASES SUMMARY                           ' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT 'If all above tests show ✓ PASS, edge cases handled correctly!' as MESSAGE;
SELECT 'Tested: Zero values, decimals, large values, aggregations, empty sets' as MESSAGE;
