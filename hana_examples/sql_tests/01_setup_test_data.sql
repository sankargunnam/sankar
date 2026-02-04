-- ============================================================================
-- CV_TEST 1 - Test Data Setup Script
-- ============================================================================
-- Purpose: Create and populate test data for CV_TEST 1 validation
-- Usage: Run this script first before executing any test validations
-- ============================================================================

-- Clean up existing test data (if any)
DELETE FROM SGUNNAM.SALES WHERE CUSTOMER_ID IN (1,2,3,4,5,6);
DELETE FROM SGUNNAM.CUSTOMERS WHERE CUSTOMER_ID IN (1,2,3,4,5,6);
DELETE FROM SGUNNAM.PRODUCTS WHERE PRODUCT_ID IN (101,102,103,104,888,999);

SELECT 'Cleaning up existing test data' as STATUS;

-- ============================================================================
-- CUSTOMERS Table Setup
-- ============================================================================
SELECT '=== Setting up CUSTOMERS table ===' as STATUS;

-- Active Customers (Should appear in CV_TEST results)
INSERT INTO SGUNNAM.CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, STATUS) 
VALUES (1, 'John', 'Smith', 'Active');

INSERT INTO SGUNNAM.CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, STATUS) 
VALUES (2, 'Bob', 'Johnson', 'Active');

INSERT INTO SGUNNAM.CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, STATUS) 
VALUES (3, 'Alice', 'Williams', 'Active');

-- Inactive Customers (Should NOT appear in CV_TEST results)
INSERT INTO SGUNNAM.CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, STATUS) 
VALUES (4, 'Jane', 'Doe', 'Inactive');

INSERT INTO SGUNNAM.CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, STATUS) 
VALUES (5, 'Mike', 'Brown', 'Pending');

INSERT INTO SGUNNAM.CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, STATUS) 
VALUES (6, 'Sarah', 'Davis', NULL);

SELECT 'Inserted 6 customers (3 Active, 3 Inactive/NULL)' as STATUS;

-- ============================================================================
-- PRODUCTS Table Setup
-- ============================================================================
SELECT '=== Setting up PRODUCTS table ===' as STATUS;

-- Products with sales (Should appear in results)
INSERT INTO SGUNNAM.PRODUCTS (PRODUCT_ID, PRODUCT_NAME) 
VALUES (101, 'Laptop Computer');

INSERT INTO SGUNNAM.PRODUCTS (PRODUCT_ID, PRODUCT_NAME) 
VALUES (102, 'Wireless Mouse');

INSERT INTO SGUNNAM.PRODUCTS (PRODUCT_ID, PRODUCT_NAME) 
VALUES (103, 'USB Cable');

INSERT INTO SGUNNAM.PRODUCTS (PRODUCT_ID, PRODUCT_NAME) 
VALUES (104, 'External Monitor');

-- Orphan product - no sales (Should NOT appear in results)
INSERT INTO SGUNNAM.PRODUCTS (PRODUCT_ID, PRODUCT_NAME) 
VALUES (999, 'Discontinued Item');

SELECT 'Inserted 5 products (4 with sales, 1 orphan)' as STATUS;

-- ============================================================================
-- SALES Table Setup
-- ============================================================================
SELECT '=== Setting up SALES table ===' as STATUS;

-- Sales for Active Customers (Should appear in results)
INSERT INTO SGUNNAM.SALES 
(CUSTOMER_ID, ORDER_NUMBER, QUANTITY, PRODUCT_ID, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT) 
VALUES (1, 'ORD001', 2, 101, 1200.00, 100.00, 50.00, 25.00);

INSERT INTO SGUNNAM.SALES 
(CUSTOMER_ID, ORDER_NUMBER, QUANTITY, PRODUCT_ID, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT) 
VALUES (1, 'ORD002', 1, 102, 25.00, 2.00, 1.00, 5.00);

INSERT INTO SGUNNAM.SALES 
(CUSTOMER_ID, ORDER_NUMBER, QUANTITY, PRODUCT_ID, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT) 
VALUES (2, 'ORD003', 10, 103, 5.00, 0.50, 0.25, 2.00);

INSERT INTO SGUNNAM.SALES 
(CUSTOMER_ID, ORDER_NUMBER, QUANTITY, PRODUCT_ID, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT) 
VALUES (3, 'ORD004', 1, 104, 300.00, 30.00, 15.00, 20.00);

-- Sales for Inactive Customers (Should NOT appear in results)
INSERT INTO SGUNNAM.SALES 
(CUSTOMER_ID, ORDER_NUMBER, QUANTITY, PRODUCT_ID, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT) 
VALUES (4, 'ORD005', 5, 102, 25.00, 0.00, 1.25, 5.00);

INSERT INTO SGUNNAM.SALES 
(CUSTOMER_ID, ORDER_NUMBER, QUANTITY, PRODUCT_ID, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT) 
VALUES (5, 'ORD006', 1, 101, 1200.00, 0.00, 60.00, 25.00);

-- Orphan sale - Product doesn't exist
INSERT INTO SGUNNAM.SALES 
(CUSTOMER_ID, ORDER_NUMBER, QUANTITY, PRODUCT_ID, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT) 
VALUES (1, 'ORD007', 1, 888, 50.00, 0.00, 2.50, 5.00);

SELECT 'Inserted 7 sales records (4 valid, 2 filtered, 1 orphan)' as STATUS;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT '=== Verifying test data setup ===' as STATUS;

SELECT 'CUSTOMERS' as TABLE_NAME, COUNT(*) as RECORD_COUNT 
FROM SGUNNAM.CUSTOMERS WHERE CUSTOMER_ID IN (1,2,3,4,5,6)
UNION ALL
SELECT 'PRODUCTS' as TABLE_NAME, COUNT(*) as RECORD_COUNT 
FROM SGUNNAM.PRODUCTS WHERE PRODUCT_ID IN (101,102,103,104,888,999)
UNION ALL
SELECT 'SALES' as TABLE_NAME, COUNT(*) as RECORD_COUNT 
FROM SGUNNAM.SALES WHERE CUSTOMER_ID IN (1,2,3,4,5,6);

SELECT '=== Test Data Setup Complete ===' as STATUS;
