-- =====================================================================
-- HANA SQL Equivalent for CV_TEST 1 Calculation View
-- =====================================================================
-- Description: This SQL script represents the complete logic of the 
--              CV_TEST 1 calculation view in pure SQL format.
--
-- Author: Generated from CV_TEST 1.hdbcalculationview
-- Date: 2026-02-04
-- =====================================================================

-- =====================================================================
-- SECTION 1: BASIC QUERY (Non-Parameterized)
-- =====================================================================
-- This version shows all products (equivalent to parameter = '%')

SELECT 
    -- Attributes (Dimensions)
    C.FIRST_NAME,
    C.LAST_NAME,
    P.PRODUCT_NAME,
    
    -- Base Measures (Aggregated)
    SUM(S.QUANTITY) AS QUANTITY,
    SUM(S.UNIT_PRICE) AS UNIT_PRICE,
    SUM(S.DISCOUNT_AMOUNT) AS DISCOUNT_AMOUNT,
    SUM(S.TAX_AMOUNT) AS TAX_AMOUNT,
    SUM(S.SHIPPING_AMOUNT) AS SHIPPING_AMOUNT,
    
    -- Calculated Measure
    SUM(S.UNIT_PRICE - S.DISCOUNT_AMOUNT - S.TAX_AMOUNT) AS SELLING_PRICE

FROM 
    -- PR_CUSTOMERS: Customer projection with Active filter
    (SELECT 
        CUSTOMER_ID,
        FIRST_NAME,
        LAST_NAME,
        STATUS
     FROM SGUNNAM.CUSTOMERS
     WHERE STATUS = 'Active'
    ) AS C
    
    -- JN_CUST_SALES: Join with Sales data
    INNER JOIN SGUNNAM.SALES AS S
        ON C.CUSTOMER_ID = S.CUSTOMER_ID
    
    -- JN_SALES_PRODUCTS: Join with Products
    INNER JOIN SGUNNAM.PRODUCTS AS P
        ON S.PRODUCT_ID = P.PRODUCT_ID

-- Optional: Filter by product name (when not showing all)
-- Uncomment and replace 'Laptop' with desired product name
-- WHERE P.PRODUCT_NAME LIKE 'Laptop'

GROUP BY 
    C.FIRST_NAME,
    C.LAST_NAME,
    P.PRODUCT_NAME

ORDER BY 
    C.FIRST_NAME,
    C.LAST_NAME,
    P.PRODUCT_NAME;


-- =====================================================================
-- SECTION 2: PARAMETERIZED QUERY USING CTE
-- =====================================================================
-- This version uses Common Table Expressions (CTEs) to better represent
-- the calculation view structure with parameter support

DO (
    IN IP_PRODUCT_NAME NVARCHAR(50) => '%'  -- Parameter with default value
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS
BEGIN
    -- CTE for PR_CUSTOMERS: Active customers only
    PR_CUSTOMERS = SELECT 
        CUSTOMER_ID,
        FIRST_NAME,
        LAST_NAME,
        STATUS
    FROM SGUNNAM.CUSTOMERS
    WHERE STATUS = 'Active';
    
    -- CTE for PR_SALES: All sales data
    PR_SALES = SELECT 
        CUSTOMER_ID,
        ORDER_NUMBER,
        QUANTITY,
        PRODUCT_ID,
        UNIT_PRICE,
        DISCOUNT_AMOUNT,
        TAX_AMOUNT,
        SHIPPING_AMOUNT
    FROM SGUNNAM.SALES;
    
    -- CTE for PR_PRODUCTS: Products filtered by parameter
    PR_PRODUCTS = SELECT 
        PRODUCT_ID,
        PRODUCT_NAME
    FROM SGUNNAM.PRODUCTS
    WHERE PRODUCT_NAME LIKE :IP_PRODUCT_NAME;
    
    -- CTE for JN_SALES_PRODUCTS: Join Sales with Products
    JN_SALES_PRODUCTS = SELECT 
        S.CUSTOMER_ID,
        S.ORDER_NUMBER,
        S.QUANTITY,
        P.PRODUCT_NAME,
        S.UNIT_PRICE,
        S.DISCOUNT_AMOUNT,
        S.TAX_AMOUNT,
        S.SHIPPING_AMOUNT
    FROM :PR_SALES AS S
    INNER JOIN :PR_PRODUCTS AS P
        ON S.PRODUCT_ID = P.PRODUCT_ID;
    
    -- Final result: JN_CUST_SALES with aggregation
    SELECT 
        -- Attributes (Dimensions)
        C.FIRST_NAME,
        C.LAST_NAME,
        SP.PRODUCT_NAME,
        
        -- Base Measures (Aggregated)
        SUM(SP.QUANTITY) AS QUANTITY,
        SUM(SP.UNIT_PRICE) AS UNIT_PRICE,
        SUM(SP.DISCOUNT_AMOUNT) AS DISCOUNT_AMOUNT,
        SUM(SP.TAX_AMOUNT) AS TAX_AMOUNT,
        SUM(SP.SHIPPING_AMOUNT) AS SHIPPING_AMOUNT,
        
        -- Calculated Measure
        SUM(SP.UNIT_PRICE - SP.DISCOUNT_AMOUNT - SP.TAX_AMOUNT) AS SELLING_PRICE
        
    FROM :PR_CUSTOMERS AS C
    INNER JOIN :JN_SALES_PRODUCTS AS SP
        ON C.CUSTOMER_ID = SP.CUSTOMER_ID
    
    GROUP BY 
        C.FIRST_NAME,
        C.LAST_NAME,
        SP.PRODUCT_NAME
    
    ORDER BY 
        C.FIRST_NAME,
        C.LAST_NAME,
        SP.PRODUCT_NAME;
END;


-- =====================================================================
-- SECTION 3: INLINE CTE VERSION (SQL Standard)
-- =====================================================================
-- This version uses WITH clause for better readability and can be
-- executed as a single SELECT statement

WITH 
    -- PR_CUSTOMERS: Active customers only
    PR_CUSTOMERS AS (
        SELECT 
            CUSTOMER_ID,
            FIRST_NAME,
            LAST_NAME,
            STATUS
        FROM SGUNNAM.CUSTOMERS
        WHERE STATUS = 'Active'
    ),
    
    -- PR_SALES: All sales data
    PR_SALES AS (
        SELECT 
            CUSTOMER_ID,
            ORDER_NUMBER,
            QUANTITY,
            PRODUCT_ID,
            UNIT_PRICE,
            DISCOUNT_AMOUNT,
            TAX_AMOUNT,
            SHIPPING_AMOUNT
        FROM SGUNNAM.SALES
    ),
    
    -- PR_PRODUCTS: Products (filter can be added in WHERE)
    PR_PRODUCTS AS (
        SELECT 
            PRODUCT_ID,
            PRODUCT_NAME
        FROM SGUNNAM.PRODUCTS
        -- Add filter here if needed, e.g.:
        -- WHERE PRODUCT_NAME LIKE '%'  -- For all products
        -- WHERE PRODUCT_NAME LIKE 'Laptop'  -- For specific product
    ),
    
    -- JN_SALES_PRODUCTS: Join Sales with Products
    JN_SALES_PRODUCTS AS (
        SELECT 
            S.CUSTOMER_ID,
            S.ORDER_NUMBER,
            S.QUANTITY,
            P.PRODUCT_NAME,
            S.UNIT_PRICE,
            S.DISCOUNT_AMOUNT,
            S.TAX_AMOUNT,
            S.SHIPPING_AMOUNT
        FROM PR_SALES AS S
        INNER JOIN PR_PRODUCTS AS P
            ON S.PRODUCT_ID = P.PRODUCT_ID
    )

-- Final aggregation: JN_CUST_SALES
SELECT 
    -- Attributes (Dimensions)
    C.FIRST_NAME,
    C.LAST_NAME,
    SP.PRODUCT_NAME,
    
    -- Base Measures (Aggregated)
    SUM(SP.QUANTITY) AS QUANTITY,
    SUM(SP.UNIT_PRICE) AS UNIT_PRICE,
    SUM(SP.DISCOUNT_AMOUNT) AS DISCOUNT_AMOUNT,
    SUM(SP.TAX_AMOUNT) AS TAX_AMOUNT,
    SUM(SP.SHIPPING_AMOUNT) AS SHIPPING_AMOUNT,
    
    -- Calculated Measure
    SUM(SP.UNIT_PRICE - SP.DISCOUNT_AMOUNT - SP.TAX_AMOUNT) AS SELLING_PRICE
    
FROM PR_CUSTOMERS AS C
INNER JOIN JN_SALES_PRODUCTS AS SP
    ON C.CUSTOMER_ID = SP.CUSTOMER_ID

GROUP BY 
    C.FIRST_NAME,
    C.LAST_NAME,
    SP.PRODUCT_NAME

ORDER BY 
    C.FIRST_NAME,
    C.LAST_NAME,
    SP.PRODUCT_NAME;


-- =====================================================================
-- SECTION 4: USAGE EXAMPLES
-- =====================================================================

-- Example 1: Show all products (equivalent to parameter = '%')
-- Use SECTION 1 or SECTION 3 as-is

-- Example 2: Filter by specific product (e.g., Laptop)
-- Modify the WHERE clause in PR_PRODUCTS CTE:
/*
WITH 
    PR_CUSTOMERS AS (...),
    PR_SALES AS (...),
    PR_PRODUCTS AS (
        SELECT 
            PRODUCT_ID,
            PRODUCT_NAME
        FROM SGUNNAM.PRODUCTS
        WHERE PRODUCT_NAME LIKE 'Laptop'  -- <-- Change here
    ),
    ...
*/

-- Example 3: Call parameterized version (SECTION 2)
/*
CALL _SYS_BIC."path/to/CV_TEST"(
    IP_PRODUCT_NAME => 'Laptop'
) WITH OVERVIEW;
*/

-- Example 4: Using prepared statement for parameter
/*
PREPARE STMT FROM 
'SELECT 
    C.FIRST_NAME,
    C.LAST_NAME,
    P.PRODUCT_NAME,
    SUM(S.QUANTITY) AS QUANTITY,
    SUM(S.UNIT_PRICE) AS UNIT_PRICE,
    SUM(S.DISCOUNT_AMOUNT) AS DISCOUNT_AMOUNT,
    SUM(S.TAX_AMOUNT) AS TAX_AMOUNT,
    SUM(S.SHIPPING_AMOUNT) AS SHIPPING_AMOUNT,
    SUM(S.UNIT_PRICE - S.DISCOUNT_AMOUNT - S.TAX_AMOUNT) AS SELLING_PRICE
FROM 
    (SELECT CUSTOMER_ID, FIRST_NAME, LAST_NAME, STATUS
     FROM SGUNNAM.CUSTOMERS
     WHERE STATUS = ''Active'') AS C
    INNER JOIN SGUNNAM.SALES AS S ON C.CUSTOMER_ID = S.CUSTOMER_ID
    INNER JOIN SGUNNAM.PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_NAME LIKE ?
GROUP BY C.FIRST_NAME, C.LAST_NAME, P.PRODUCT_NAME
ORDER BY C.FIRST_NAME, C.LAST_NAME, P.PRODUCT_NAME';

EXECUTE STMT USING 'Laptop';
*/


-- =====================================================================
-- SECTION 5: STRUCTURE MAPPING
-- =====================================================================
/*
Calculation View Structure → SQL Mapping:

1. DATA SOURCES
   - SGUNNAM.CUSTOMERS → SGUNNAM.CUSTOMERS table
   - SGUNNAM.SALES → SGUNNAM.SALES table
   - SGUNNAM.PRODUCTS → SGUNNAM.PRODUCTS table

2. PROJECTION VIEWS (CTEs)
   - PR_CUSTOMERS → SELECT with STATUS = 'Active' filter
   - PR_SALES → SELECT all columns from SALES
   - PR_PRODUCTS → SELECT with PRODUCT_NAME LIKE parameter filter

3. JOIN VIEWS
   - JN_SALES_PRODUCTS → INNER JOIN PR_SALES and PR_PRODUCTS on PRODUCT_ID
   - JN_CUST_SALES → INNER JOIN PR_CUSTOMERS and JN_SALES_PRODUCTS on CUSTOMER_ID

4. LOGICAL MODEL (Final SELECT)
   - Attributes: FIRST_NAME, LAST_NAME, PRODUCT_NAME (GROUP BY)
   - Base Measures: QUANTITY, UNIT_PRICE, DISCOUNT_AMOUNT, TAX_AMOUNT, SHIPPING_AMOUNT (SUM)
   - Calculated Measure: SELLING_PRICE = (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT) (SUM)

5. PARAMETER
   - IP_PRODUCT_NAME (NVARCHAR(50), default: '%')
   - Used in PR_PRODUCTS filter: WHERE PRODUCT_NAME LIKE parameter

6. AGGREGATION
   - Type: SUM for all measures
   - GROUP BY: All attribute columns (FIRST_NAME, LAST_NAME, PRODUCT_NAME)
*/


-- =====================================================================
-- SECTION 6: PERFORMANCE NOTES
-- =====================================================================
/*
1. FILTERS
   - Active customer filter applied early (reduces dataset)
   - Product name filter applied early (reduces dataset)
   - Both filters use indexes if available

2. JOIN ORDER
   - CUSTOMERS filtered first (smallest dataset)
   - SALES joined next
   - PRODUCTS filtered and joined last
   - This order matches the calculation view's join order

3. AGGREGATION
   - SUM operations performed after all joins
   - GROUP BY on dimension attributes
   - Aggregation happens at SQL engine level

4. OPTIMIZATION
   - Use indexes on: CUSTOMER_ID, PRODUCT_ID, STATUS, PRODUCT_NAME
   - Consider column store for large tables
   - Statistics should be up-to-date

5. PARAMETER USAGE
   - Using LIKE with '%' allows showing all products
   - Using LIKE with specific name filters efficiently
   - Wildcard at start (e.g., '%Laptop') prevents index usage
*/


-- =====================================================================
-- SECTION 7: TESTING QUERIES
-- =====================================================================

-- Test 1: Count total rows (all products)
/*
SELECT COUNT(*) AS TOTAL_ROWS
FROM (
    SELECT C.FIRST_NAME, C.LAST_NAME, P.PRODUCT_NAME
    FROM (SELECT CUSTOMER_ID, FIRST_NAME, LAST_NAME FROM SGUNNAM.CUSTOMERS WHERE STATUS = 'Active') AS C
    INNER JOIN SGUNNAM.SALES AS S ON C.CUSTOMER_ID = S.CUSTOMER_ID
    INNER JOIN SGUNNAM.PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
    GROUP BY C.FIRST_NAME, C.LAST_NAME, P.PRODUCT_NAME
) AS T;
*/

-- Test 2: Verify SELLING_PRICE calculation
/*
SELECT 
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    TAX_AMOUNT,
    SELLING_PRICE,
    (UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT) AS CALCULATED_CHECK
FROM (
    <insert full query from SECTION 3 here>
) AS T;
*/

-- Test 3: Compare with calculation view
/*
-- Run both queries and compare results
SELECT * FROM "SGUNNAM"."CV_TEST"('IP_PRODUCT_NAME' => '%');
-- vs
<SECTION 3 query>
*/


-- =====================================================================
-- END OF SQL SCRIPT
-- =====================================================================
