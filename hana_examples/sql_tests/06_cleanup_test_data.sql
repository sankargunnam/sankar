-- ============================================================================
-- CV_TEST 1 - Cleanup Test Data
-- ============================================================================
-- Purpose: Remove test data after validation is complete
-- Usage: Run this script after all tests are finished
-- Warning: This will delete test records from CUSTOMERS, PRODUCTS, and SALES
-- ============================================================================

SELECT '╔════════════════════════════════════════════════════════════════════╗' as MESSAGE
UNION ALL SELECT '║              CV_TEST 1 - CLEANUP TEST DATA                     ║'
UNION ALL SELECT '╚════════════════════════════════════════════════════════════════╝';

SELECT '' as MESSAGE;
SELECT 'Starting cleanup of test data...' as MESSAGE;
SELECT '' as MESSAGE;

-- ============================================================================
-- Count Before Cleanup
-- ============================================================================
SELECT '--- Records Before Cleanup ---' as MESSAGE;

SELECT 'CUSTOMERS' as TABLE_NAME, 
       COUNT(*) as RECORD_COUNT 
FROM SGUNNAM.CUSTOMERS 
WHERE CUSTOMER_ID IN (1,2,3,4,5,6)
UNION ALL
SELECT 'PRODUCTS' as TABLE_NAME, 
       COUNT(*) as RECORD_COUNT 
FROM SGUNNAM.PRODUCTS 
WHERE PRODUCT_ID IN (101,102,103,104,888,999)
UNION ALL
SELECT 'SALES' as TABLE_NAME, 
       COUNT(*) as RECORD_COUNT 
FROM SGUNNAM.SALES 
WHERE CUSTOMER_ID IN (1,2,3,4,5,6);

-- ============================================================================
-- Delete Test Data
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- Deleting Test Data ---' as MESSAGE;

-- Delete Sales first (foreign key dependencies)
DELETE FROM SGUNNAM.SALES 
WHERE CUSTOMER_ID IN (1,2,3,4,5,6);

SELECT 'Deleted SALES records' as STATUS;

-- Delete Customers
DELETE FROM SGUNNAM.CUSTOMERS 
WHERE CUSTOMER_ID IN (1,2,3,4,5,6);

SELECT 'Deleted CUSTOMERS records' as STATUS;

-- Delete Products
DELETE FROM SGUNNAM.PRODUCTS 
WHERE PRODUCT_ID IN (101,102,103,104,888,999);

SELECT 'Deleted PRODUCTS records' as STATUS;

-- ============================================================================
-- Verify Cleanup
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '--- Verification After Cleanup ---' as MESSAGE;

SELECT 'CUSTOMERS' as TABLE_NAME, 
       COUNT(*) as REMAINING_COUNT,
       CASE WHEN COUNT(*) = 0 THEN '✓ Cleaned' ELSE '✗ Records remain' END as STATUS
FROM SGUNNAM.CUSTOMERS 
WHERE CUSTOMER_ID IN (1,2,3,4,5,6)
UNION ALL
SELECT 'PRODUCTS' as TABLE_NAME, 
       COUNT(*) as REMAINING_COUNT,
       CASE WHEN COUNT(*) = 0 THEN '✓ Cleaned' ELSE '✗ Records remain' END as STATUS
FROM SGUNNAM.PRODUCTS 
WHERE PRODUCT_ID IN (101,102,103,104,888,999)
UNION ALL
SELECT 'SALES' as TABLE_NAME, 
       COUNT(*) as REMAINING_COUNT,
       CASE WHEN COUNT(*) = 0 THEN '✓ Cleaned' ELSE '✗ Records remain' END as STATUS
FROM SGUNNAM.SALES 
WHERE CUSTOMER_ID IN (1,2,3,4,5,6);

-- ============================================================================
-- Summary
-- ============================================================================
SELECT '' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '                      CLEANUP COMPLETE                             ' as MESSAGE;
SELECT '═══════════════════════════════════════════════════════════════════' as MESSAGE;
SELECT '' as MESSAGE;
SELECT 'Test data has been removed from:' as MESSAGE;
SELECT '  • SGUNNAM.CUSTOMERS (IDs: 1-6)' as MESSAGE;
SELECT '  • SGUNNAM.PRODUCTS (IDs: 101-104, 888, 999)' as MESSAGE;
SELECT '  • SGUNNAM.SALES (Customer IDs: 1-6)' as MESSAGE;
SELECT '' as MESSAGE;
SELECT 'You can now safely close this session.' as MESSAGE;
SELECT '' as MESSAGE;
