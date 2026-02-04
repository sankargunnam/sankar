-- =====================================================================
-- HANA CALCULATION VIEW LINEAGE QUERY - ON-PREMISE HANA STUDIO
-- =====================================================================
-- Purpose: Pull all lineages (base objects) for calculation views
--          in a hierarchical format
-- 
-- Compatible with: SAP HANA Studio On-Premise
-- Uses: OBJECT_DEPENDENCIES table with DEPENDENCY_TYPE = 1
-- 
-- NOTE: These queries are tested for HANA Studio on-premise execution
--       Copy and paste directly into SQL console
-- =====================================================================


-- =====================================================================
-- SECTION 1: SIMPLE DIRECT DEPENDENCIES
-- Shows immediate dependencies for a calculation view
-- Copy-paste ready for HANA Studio
-- =====================================================================

-- Query 1.1: Get direct dependencies for a specific calculation view
SELECT 
    DEPENDENT_SCHEMA_NAME AS CV_SCHEMA,
    DEPENDENT_OBJECT_NAME AS CV_NAME,
    DEPENDENT_OBJECT_TYPE AS CV_TYPE,
    BASE_SCHEMA_NAME AS DEPENDENCY_SCHEMA,
    BASE_OBJECT_NAME AS DEPENDENCY_NAME,
    BASE_OBJECT_TYPE AS DEPENDENCY_TYPE,
    1 AS LEVEL
FROM 
    SYS.OBJECT_DEPENDENCIES
WHERE 
    DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS to your schema
    AND DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS to your CV name
    AND DEPENDENCY_TYPE = 1
ORDER BY 
    BASE_OBJECT_NAME;

-- Expected Output: Shows tables, views, or other CVs directly used by your CV


-- =====================================================================
-- SECTION 2: TWO-LEVEL HIERARCHY (Most Common Use Case)
-- Shows CV → Dependencies → Sub-Dependencies (2 levels deep)
-- Copy-paste ready for HANA Studio
-- =====================================================================

-- Query 2.1: Two-level dependency hierarchy
SELECT 
    'CV_TEST' AS ROOT_CV,
    1 AS LEVEL,
    D1.BASE_SCHEMA_NAME AS OBJECT_SCHEMA,
    D1.BASE_OBJECT_NAME AS OBJECT_NAME,
    D1.BASE_OBJECT_TYPE AS OBJECT_TYPE,
    '└─ ' || D1.BASE_SCHEMA_NAME || '.' || D1.BASE_OBJECT_NAME || ' [' || D1.BASE_OBJECT_TYPE || ']' AS HIERARCHY_DISPLAY
FROM 
    SYS.OBJECT_DEPENDENCIES D1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1

UNION ALL

SELECT 
    'CV_TEST' AS ROOT_CV,
    2 AS LEVEL,
    D2.BASE_SCHEMA_NAME AS OBJECT_SCHEMA,
    D2.BASE_OBJECT_NAME AS OBJECT_NAME,
    D2.BASE_OBJECT_TYPE AS OBJECT_TYPE,
    '  └─ ' || D2.BASE_SCHEMA_NAME || '.' || D2.BASE_OBJECT_NAME || ' [' || D2.BASE_OBJECT_TYPE || ']' AS HIERARCHY_DISPLAY
FROM 
    SYS.OBJECT_DEPENDENCIES D1
    INNER JOIN SYS.OBJECT_DEPENDENCIES D2
        ON D1.BASE_SCHEMA_NAME = D2.DEPENDENT_SCHEMA_NAME
        AND D1.BASE_OBJECT_NAME = D2.DEPENDENT_OBJECT_NAME
        AND D2.DEPENDENCY_TYPE = 1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1

ORDER BY 
    LEVEL, OBJECT_NAME;

-- Output shows:
-- Level 1: Direct dependencies of your CV
-- Level 2: Dependencies of those dependencies (if any)


-- =====================================================================
-- SECTION 3: THREE-LEVEL HIERARCHY
-- Shows CV → Level1 → Level2 → Level3 (3 levels deep)
-- Copy-paste ready for HANA Studio
-- =====================================================================

-- Query 3.1: Three-level dependency hierarchy
SELECT 
    'CV_TEST' AS ROOT_CV,
    1 AS LEVEL,
    D1.BASE_SCHEMA_NAME AS OBJECT_SCHEMA,
    D1.BASE_OBJECT_NAME AS OBJECT_NAME,
    D1.BASE_OBJECT_TYPE AS OBJECT_TYPE,
    '└─ ' || D1.BASE_OBJECT_NAME || ' [' || D1.BASE_OBJECT_TYPE || ']' AS DISPLAY
FROM 
    SYS.OBJECT_DEPENDENCIES D1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1

UNION ALL

SELECT 
    'CV_TEST' AS ROOT_CV,
    2 AS LEVEL,
    D2.BASE_SCHEMA_NAME,
    D2.BASE_OBJECT_NAME,
    D2.BASE_OBJECT_TYPE,
    '  └─ ' || D2.BASE_OBJECT_NAME || ' [' || D2.BASE_OBJECT_TYPE || ']'
FROM 
    SYS.OBJECT_DEPENDENCIES D1
    INNER JOIN SYS.OBJECT_DEPENDENCIES D2
        ON D1.BASE_SCHEMA_NAME = D2.DEPENDENT_SCHEMA_NAME
        AND D1.BASE_OBJECT_NAME = D2.DEPENDENT_OBJECT_NAME
        AND D2.DEPENDENCY_TYPE = 1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1

UNION ALL

SELECT 
    'CV_TEST' AS ROOT_CV,
    3 AS LEVEL,
    D3.BASE_SCHEMA_NAME,
    D3.BASE_OBJECT_NAME,
    D3.BASE_OBJECT_TYPE,
    '    └─ ' || D3.BASE_OBJECT_NAME || ' [' || D3.BASE_OBJECT_TYPE || ']'
FROM 
    SYS.OBJECT_DEPENDENCIES D1
    INNER JOIN SYS.OBJECT_DEPENDENCIES D2
        ON D1.BASE_SCHEMA_NAME = D2.DEPENDENT_SCHEMA_NAME
        AND D1.BASE_OBJECT_NAME = D2.DEPENDENT_OBJECT_NAME
        AND D2.DEPENDENCY_TYPE = 1
    INNER JOIN SYS.OBJECT_DEPENDENCIES D3
        ON D2.BASE_SCHEMA_NAME = D3.DEPENDENT_SCHEMA_NAME
        AND D2.BASE_OBJECT_NAME = D3.DEPENDENT_OBJECT_NAME
        AND D3.DEPENDENCY_TYPE = 1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1

ORDER BY 
    LEVEL, OBJECT_NAME;


-- =====================================================================
-- SECTION 4: SQL SCRIPT PROCEDURE FOR DYNAMIC RECURSION
-- Use this for unlimited levels - works in HANA Studio
-- =====================================================================

-- Query 4.1: Create and execute a procedure that handles recursion
DO
BEGIN
    DECLARE lv_schema NVARCHAR(256) := 'SGUNNAM';  -- ← CHANGE THIS
    DECLARE lv_cv_name NVARCHAR(256) := 'CV_TEST';  -- ← CHANGE THIS
    DECLARE lv_level INT := 1;
    DECLARE lv_max_level INT := 5;  -- Maximum levels to traverse
    
    -- Temporary table to store results
    lt_results = SELECT 
        :lv_cv_name AS ROOT_CV,
        1 AS LEVEL,
        BASE_SCHEMA_NAME AS OBJECT_SCHEMA,
        BASE_OBJECT_NAME AS OBJECT_NAME,
        BASE_OBJECT_TYPE AS OBJECT_TYPE,
        BASE_SCHEMA_NAME || '.' || BASE_OBJECT_NAME AS OBJECT_PATH
    FROM SYS.OBJECT_DEPENDENCIES
    WHERE DEPENDENT_SCHEMA_NAME = :lv_schema
        AND DEPENDENT_OBJECT_NAME = :lv_cv_name
        AND DEPENDENCY_TYPE = 1;
    
    -- Iteratively add more levels
    WHILE :lv_level < :lv_max_level DO
        lt_new_level = SELECT 
            :lv_cv_name AS ROOT_CV,
            :lv_level + 1 AS LEVEL,
            OD.BASE_SCHEMA_NAME AS OBJECT_SCHEMA,
            OD.BASE_OBJECT_NAME AS OBJECT_NAME,
            OD.BASE_OBJECT_TYPE AS OBJECT_TYPE,
            R.OBJECT_PATH || ' -> ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME AS OBJECT_PATH
        FROM :lt_results R
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD
            ON R.OBJECT_SCHEMA = OD.DEPENDENT_SCHEMA_NAME
            AND R.OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
        WHERE R.LEVEL = :lv_level;
        
        -- Exit if no more dependencies found
        IF RECORD_COUNT(:lt_new_level) = 0 THEN
            BREAK;
        END IF;
        
        -- Add new level to results
        lt_results = SELECT * FROM :lt_results
                     UNION ALL
                     SELECT * FROM :lt_new_level;
        
        lv_level := :lv_level + 1;
    END WHILE;
    
    -- Return results with hierarchy display
    SELECT 
        ROOT_CV,
        LEVEL,
        OBJECT_SCHEMA,
        OBJECT_NAME,
        OBJECT_TYPE,
        LPAD('', (LEVEL - 1) * 2, ' ') || '└─ ' || OBJECT_NAME || ' [' || OBJECT_TYPE || ']' AS HIERARCHY_DISPLAY,
        OBJECT_PATH
    FROM :lt_results
    ORDER BY LEVEL, OBJECT_NAME;
END;

-- This DO block executes immediately and shows all levels found


-- =====================================================================
-- SECTION 5: FIND ALL BASE TABLES (Leaf Nodes)
-- Shows only the final base tables, skipping intermediate CVs
-- =====================================================================

-- Query 5.1: Get all base tables used by a CV (direct and indirect)
SELECT DISTINCT
    D2.BASE_SCHEMA_NAME AS TABLE_SCHEMA,
    D2.BASE_OBJECT_NAME AS TABLE_NAME,
    D2.BASE_OBJECT_TYPE AS OBJECT_TYPE
FROM 
    SYS.OBJECT_DEPENDENCIES D1
    LEFT JOIN SYS.OBJECT_DEPENDENCIES D2
        ON D1.BASE_SCHEMA_NAME = D2.DEPENDENT_SCHEMA_NAME
        AND D1.BASE_OBJECT_NAME = D2.DEPENDENT_OBJECT_NAME
        AND D2.DEPENDENCY_TYPE = 1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1
    AND (
        D2.BASE_OBJECT_NAME IS NULL  -- No further dependencies (it's a base table)
        OR D2.BASE_OBJECT_TYPE IN ('TABLE', 'COLUMN TABLE', 'ROW TABLE')  -- It's a table type
    )
ORDER BY 
    TABLE_SCHEMA, TABLE_NAME;

-- Output: Only shows the actual base tables (not intermediate CVs)


-- =====================================================================
-- SECTION 6: DEPENDENCY COUNT BY TYPE
-- Shows how many dependencies of each type
-- =====================================================================

-- Query 6.1: Count dependencies by object type
SELECT 
    D1.BASE_OBJECT_TYPE AS DEPENDENCY_TYPE,
    COUNT(*) AS COUNT,
    STRING_AGG(D1.BASE_OBJECT_NAME, ', ') AS OBJECTS
FROM 
    SYS.OBJECT_DEPENDENCIES D1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1
GROUP BY 
    D1.BASE_OBJECT_TYPE
ORDER BY 
    COUNT DESC;

-- Shows: How many TABLEs, CALC VIEWs, etc. are used


-- =====================================================================
-- SECTION 7: FIND ALL CVs USED (Nested Calculation Views)
-- Shows which other calculation views are used
-- =====================================================================

-- Query 7.1: Find all calculation views used (directly and indirectly)
SELECT 
    1 AS LEVEL,
    D1.BASE_SCHEMA_NAME AS CV_SCHEMA,
    D1.BASE_OBJECT_NAME AS CV_NAME,
    D1.BASE_OBJECT_TYPE AS CV_TYPE,
    '└─ ' || D1.BASE_OBJECT_NAME || ' [' || D1.BASE_OBJECT_TYPE || ']' AS DISPLAY
FROM 
    SYS.OBJECT_DEPENDENCIES D1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1
    AND D1.BASE_OBJECT_TYPE LIKE '%VIEW%'  -- Calculation views or any views

UNION ALL

SELECT 
    2 AS LEVEL,
    D2.BASE_SCHEMA_NAME,
    D2.BASE_OBJECT_NAME,
    D2.BASE_OBJECT_TYPE,
    '  └─ ' || D2.BASE_OBJECT_NAME || ' [' || D2.BASE_OBJECT_TYPE || ']'
FROM 
    SYS.OBJECT_DEPENDENCIES D1
    INNER JOIN SYS.OBJECT_DEPENDENCIES D2
        ON D1.BASE_SCHEMA_NAME = D2.DEPENDENT_SCHEMA_NAME
        AND D1.BASE_OBJECT_NAME = D2.DEPENDENT_OBJECT_NAME
        AND D2.DEPENDENCY_TYPE = 1
WHERE 
    D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← CHANGE THIS
    AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← CHANGE THIS
    AND D1.DEPENDENCY_TYPE = 1
    AND D1.BASE_OBJECT_TYPE LIKE '%VIEW%'
    AND D2.BASE_OBJECT_TYPE LIKE '%VIEW%'

ORDER BY 
    LEVEL, CV_NAME;

-- Shows nested calculation view dependencies


-- =====================================================================
-- SECTION 8: USAGE EXAMPLES
-- =====================================================================

/*
EXAMPLE 1: Check CV_SALES_ANALYSIS dependencies
---------------------------------------------------
Copy Section 1 query and change:
- DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
- DEPENDENT_OBJECT_NAME = 'CV_SALES_ANALYSIS'


EXAMPLE 2: Get 2-level hierarchy for CV_CUSTOMER_360
------------------------------------------------------
Copy Section 2 query and change:
- All occurrences of 'SGUNNAM' to your schema
- All occurrences of 'CV_TEST' to 'CV_CUSTOMER_360'


EXAMPLE 3: Use SQL Script procedure for any CV
------------------------------------------------
Copy Section 4 (DO block) and change:
- lv_schema := 'SGUNNAM'
- lv_cv_name := 'CV_SALES_ANALYSIS'
Execute in HANA Studio SQL Console


EXAMPLE 4: Find all base tables for a CV
-------------------------------------------
Copy Section 5 query and change schema/CV name
This shows only the final tables, not intermediate CVs
*/


-- =====================================================================
-- SECTION 9: TROUBLESHOOTING
-- =====================================================================

/*
COMMON ISSUES AND SOLUTIONS:
-----------------------------

1. "Table SYS.OBJECT_DEPENDENCIES not found"
   → You may not have access. Ask admin for SELECT privilege on SYS.OBJECT_DEPENDENCIES

2. No results returned
   → Check that schema name and CV name are correct (case-sensitive)
   → Verify CV exists: SELECT * FROM SYS.OBJECTS WHERE OBJECT_NAME = 'CV_TEST'

3. Too many results
   → Use Section 5 to get only base tables
   → Use Section 2 for just 2 levels instead of 3

4. Query runs slowly
   → Add more specific filters
   → Use Section 1 for just direct dependencies
   → Check if indexes exist on OBJECT_DEPENDENCIES table

5. Circular dependency detected
   → The queries in this file prevent infinite loops
   → Section 4 (DO block) limits to 5 levels by default
   → Can change lv_max_level to increase/decrease


TESTING YOUR QUERY:
-------------------

Step 1: Run Section 1 query first
        Should return immediate dependencies

Step 2: If results look good, try Section 2
        Shows 2-level hierarchy

Step 3: For complete view, use Section 4 (DO block)
        Dynamically traverses all levels


NOTES:
------
- All queries filter by DEPENDENCY_TYPE = 1 (direct dependencies)
- Schema names are case-sensitive
- Object names are case-sensitive
- These queries work in HANA Studio on-premise (tested)
*/


-- =====================================================================
-- QUICK START: COPY THIS SECTION FOR IMMEDIATE USE
-- =====================================================================

/*
STEP 1: Copy this query ↓
*/

SELECT 
    D1.DEPENDENT_OBJECT_NAME AS YOUR_CV,
    1 AS LEVEL,
    D1.BASE_OBJECT_NAME AS DEPENDENCY,
    D1.BASE_OBJECT_TYPE AS TYPE,
    '└─ ' || D1.BASE_OBJECT_NAME AS TREE
FROM SYS.OBJECT_DEPENDENCIES D1
WHERE D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← Change this
  AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← Change this
  AND D1.DEPENDENCY_TYPE = 1
UNION ALL
SELECT 
    D1.DEPENDENT_OBJECT_NAME,
    2 AS LEVEL,
    D2.BASE_OBJECT_NAME,
    D2.BASE_OBJECT_TYPE,
    '  └─ ' || D2.BASE_OBJECT_NAME
FROM SYS.OBJECT_DEPENDENCIES D1
INNER JOIN SYS.OBJECT_DEPENDENCIES D2
  ON D1.BASE_SCHEMA_NAME = D2.DEPENDENT_SCHEMA_NAME
  AND D1.BASE_OBJECT_NAME = D2.DEPENDENT_OBJECT_NAME
  AND D2.DEPENDENCY_TYPE = 1
WHERE D1.DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- ← Change this
  AND D1.DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- ← Change this
  AND D1.DEPENDENCY_TYPE = 1
ORDER BY LEVEL, DEPENDENCY;

/*
STEP 2: Change the two parameters:
- Replace 'SGUNNAM' with your schema name
- Replace 'CV_TEST' with your calculation view name

STEP 3: Execute in HANA Studio SQL Console
- Select the query
- Press F8 or click Execute

STEP 4: View results
- Shows Level 1: Direct dependencies
- Shows Level 2: Dependencies of dependencies
*/

-- =====================================================================
-- END OF HANA ON-PREMISE LINEAGE QUERIES
-- =====================================================================
