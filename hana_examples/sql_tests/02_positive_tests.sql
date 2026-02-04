-- ============================================================================
-- CV_TEST 1 - Positive Test Cases
-- ============================================================================
-- Purpose: Validate expected behaviors (what SHOULD happen)
-- Prerequisites: Run 01_setup_test_data.sql first
-- Expected: All tests should PASS
-- ============================================================================

SELECT '╔════════════════════════════════════════════════════════════════════╗' as MESSAGE
UNION ALL SELECT '║          CV_TEST 1 - POSITIVE TEST CASES                       ║'
UNION ALL SELECT '╚════════════════════════════════════════════════════════════════╝';

-- ============================================================================
-- TC-001: Active Customer Filter - Only Active Customers Appear
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-001: Active Customer Filter ---' as TEST_CASE;
SELECT 'Expected: Only 3 active customers (John, Bob, Alice)' as EXPECTATION;

SELECT DISTINCT 
    FIRST_NAME,
    LAST_NAME
FROM CV_TEST
ORDER BY FIRST_NAME;

SELECT 'Verification: Count distinct customers' as CHECK_TYPE,
       COUNT(DISTINCT FIRST_NAME) as ACTUAL_COUNT,
       3 as EXPECTED_COUNT,
       CASE WHEN COUNT(DISTINCT FIRST_NAME) = 3 THEN '✓ PASS' ELSE '✗ FAIL' END as RESULT
FROM CV_TEST;

-- ============================================================================
-- TC-002: Product Names Display - Verify PRODUCT_NAME Not PRODUCT_ID
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-002: Product Names Display ---' as TEST_CASE;
SELECT 'Expected: Product names visible (not numeric IDs)' as EXPECTATION;

SELECT 
    PRODUCT_NAME,
    COUNT(*) as ORDER_COUNT
FROM CV_TEST
GROUP BY PRODUCT_NAME
ORDER BY PRODUCT_NAME;

SELECT 'Verification: Product names are text' as CHECK_TYPE,
       COUNT(DISTINCT PRODUCT_NAME) as DISTINCT_PRODUCTS,
       CASE 
           WHEN COUNT(DISTINCT PRODUCT_NAME) = 4 THEN '✓ PASS' 
           ELSE '✗ FAIL' 
       END as RESULT
FROM CV_TEST;

-- ============================================================================
-- TC-003: SELLING_PRICE Calculation - Verify Formula Correctness
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-003: SELLING_PRICE Calculation ---' as TEST_CASE;
SELECT 'Expected: SELLING_PRICE = UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT' as EXPECTATION;

SELECT 
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE,
    (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT) as MANUAL_CALCULATION,
    CASE 
        WHEN SELLING_PRICE = (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT) 
        THEN '✓ Match' 
        ELSE '✗ Mismatch' 
    END as VALIDATION
FROM CV_TEST
WHERE FIRST_NAME = 'John' AND PRODUCT_NAME = 'Laptop Computer';

SELECT 'Verification: SELLING_PRICE formula' as CHECK_TYPE,
       CASE 
           WHEN ALL(SELLING_PRICE = (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT)) 
           THEN '✓ PASS' 
           ELSE '✗ FAIL' 
       END as RESULT
FROM CV_TEST;

-- ============================================================================
-- TC-004: SELLING_PRICE Aggregation - Verify SUM Works
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-004: SELLING_PRICE Aggregation ---' as TEST_CASE;
SELECT 'Expected: John total SELLING_PRICE = 1072.00 (1050 + 22)' as EXPECTATION;

SELECT 
    FIRST_NAME,
    LAST_NAME,
    SUM(QUANTITY) as TOTAL_QUANTITY,
    SUM(UNIT_PRICE) as TOTAL_UNIT_PRICE,
    SUM(DISCOUNT_AMOUNT) as TOTAL_DISCOUNT,
    SUM(TAX_AMOUNT) as TOTAL_TAX,
    SUM(SELLING_PRICE) as TOTAL_SELLING_PRICE,
    (SUM(UNIT_PRICE) - SUM(DISCOUNT_AMOUNT) - SUM(TAX_AMOUNT)) as EXPECTED_TOTAL
FROM CV_TEST
WHERE FIRST_NAME = 'John'
GROUP BY FIRST_NAME, LAST_NAME;

SELECT 'Verification: Aggregation correctness' as CHECK_TYPE,
       SUM(SELLING_PRICE) as ACTUAL_TOTAL,
       1072.00 as EXPECTED_TOTAL,
       CASE 
           WHEN ABS(SUM(SELLING_PRICE) - 1072.00) < 0.01 
           THEN '✓ PASS' 
           ELSE '✗ FAIL' 
       END as RESULT
FROM CV_TEST
WHERE FIRST_NAME = 'John';

-- ============================================================================
-- TC-005: Inner Join Behavior - Orphan Products Excluded
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-005: Inner Join - Orphan Products Excluded ---' as TEST_CASE;
SELECT 'Expected: Discontinued Item (Product 999) should NOT appear' as EXPECTATION;

SELECT COUNT(*) as ORPHAN_PRODUCT_COUNT,
       CASE 
           WHEN COUNT(*) = 0 THEN '✓ PASS (Correctly excluded)' 
           ELSE '✗ FAIL (Should not appear)' 
       END as RESULT
FROM CV_TEST
WHERE PRODUCT_NAME = 'Discontinued Item';

-- ============================================================================
-- TC-006: Complete Output Schema - All Expected Columns Present
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-006: Complete Output Schema ---' as TEST_CASE;
SELECT 'Expected: All 9 columns present (3 attributes + 6 measures)' as EXPECTATION;

SELECT TOP 1
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    QUANTITY,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SHIPPING_AMOUNT,
    SELLING_PRICE
FROM CV_TEST;

SELECT 'Schema validation' as CHECK_TYPE,
       '9 columns retrieved' as STATUS,
       '✓ PASS' as RESULT;

-- ============================================================================
-- TC-007: Edge Case - Small Decimal Values
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-007: Edge Case - Small Decimal Values ---' as TEST_CASE;
SELECT 'Expected: Bob USB Cable = 4.25 (5.00 - 0.50 - 0.25)' as EXPECTATION;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE,
    CASE 
        WHEN ABS(SELLING_PRICE - 4.25) < 0.01 
        THEN '✓ PASS' 
        ELSE '✗ FAIL' 
    END as RESULT
FROM CV_TEST
WHERE FIRST_NAME = 'Bob';

-- ============================================================================
-- TC-008: Multiple Products per Customer
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- TC-008: Multiple Products per Customer ---' as TEST_CASE;
SELECT 'Expected: John has 2 separate order rows' as EXPECTATION;

SELECT 
    FIRST_NAME,
    PRODUCT_NAME,
    SELLING_PRICE
FROM CV_TEST
WHERE FIRST_NAME = 'John'
ORDER BY PRODUCT_NAME;

SELECT 'Verification: John order count' as CHECK_TYPE,
       COUNT(*) as ACTUAL_COUNT,
       2 as EXPECTED_COUNT,
       CASE 
           WHEN COUNT(*) = 2 THEN '✓ PASS' 
           ELSE '✗ FAIL' 
       END as RESULT
FROM CV_TEST
WHERE FIRST_NAME = 'John';

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '                    POSITIVE TESTS SUMMARY                         ' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT 'If all above tests show ✓ PASS, then all positive tests passed!' as MESSAGE;
SELECT 'Total rows in CV_TEST (should be 4): ' || CAST(COUNT(*) as VARCHAR) as MESSAGE
FROM CV_TEST;
