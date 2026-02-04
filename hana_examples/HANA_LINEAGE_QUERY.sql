-- =====================================================================
-- HANA Calculation View Lineage Query
-- =====================================================================
-- Purpose: Recursively pull all lineages (base objects) for calculation views
--          in a hierarchical format, showing all dependent objects at all levels
-- 
-- Uses: OBJECT_DEPENDENCIES table with DEPENDENCY_TYPE = 1
-- =====================================================================

-- =====================================================================
-- SECTION 1: BASIC LINEAGE QUERY
-- Shows direct dependencies for a specific calculation view
-- =====================================================================

-- Replace 'CV_TEST' and 'SGUNNAM' with your calculation view name and schema
SELECT 
    DEPENDENT_SCHEMA_NAME,
    DEPENDENT_OBJECT_NAME,
    DEPENDENT_OBJECT_TYPE,
    BASE_SCHEMA_NAME,
    BASE_OBJECT_NAME,
    BASE_OBJECT_TYPE,
    DEPENDENCY_TYPE
FROM 
    SYS.OBJECT_DEPENDENCIES
WHERE 
    DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
    AND DEPENDENT_OBJECT_NAME = 'CV_TEST'
    AND DEPENDENCY_TYPE = 1
ORDER BY 
    BASE_OBJECT_NAME;

-- Expected Output:
-- Shows immediate base objects (tables, views, or other CVs) used by CV_TEST


-- =====================================================================
-- SECTION 2: RECURSIVE LINEAGE QUERY (COMPLETE HIERARCHY)
-- Shows all levels of dependencies recursively
-- =====================================================================

WITH RECURSIVE LINEAGE_HIERARCHY AS (
    -- Base case: Direct dependencies of the target calculation view
    SELECT 
        DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
        DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
        DEPENDENT_OBJECT_TYPE AS ROOT_TYPE,
        DEPENDENT_SCHEMA_NAME,
        DEPENDENT_OBJECT_NAME,
        DEPENDENT_OBJECT_TYPE,
        BASE_SCHEMA_NAME,
        BASE_OBJECT_NAME,
        BASE_OBJECT_TYPE,
        1 AS LEVEL,
        CAST(BASE_SCHEMA_NAME || '.' || BASE_OBJECT_NAME AS NVARCHAR(500)) AS LINEAGE_PATH,
        CAST('  └─ ' || BASE_SCHEMA_NAME || '.' || BASE_OBJECT_NAME || ' (' || BASE_OBJECT_TYPE || ')' AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        SYS.OBJECT_DEPENDENCIES
    WHERE 
        DEPENDENT_SCHEMA_NAME = 'SGUNNAM'  -- Change to your schema
        AND DEPENDENT_OBJECT_NAME = 'CV_TEST'  -- Change to your CV name
        AND DEPENDENCY_TYPE = 1
    
    UNION ALL
    
    -- Recursive case: Dependencies of the base objects
    SELECT 
        LH.ROOT_SCHEMA,
        LH.ROOT_OBJECT,
        LH.ROOT_TYPE,
        OD.DEPENDENT_SCHEMA_NAME,
        OD.DEPENDENT_OBJECT_NAME,
        OD.DEPENDENT_OBJECT_TYPE,
        OD.BASE_SCHEMA_NAME,
        OD.BASE_OBJECT_NAME,
        OD.BASE_OBJECT_TYPE,
        LH.LEVEL + 1 AS LEVEL,
        LH.LINEAGE_PATH || ' -> ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME AS LINEAGE_PATH,
        CAST(LPAD('', (LH.LEVEL + 1) * 2, ' ') || '└─ ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME || ' (' || OD.BASE_OBJECT_TYPE || ')' AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        LINEAGE_HIERARCHY LH
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
            ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
            AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
    WHERE 
        LH.LEVEL < 10  -- Prevent infinite loops (max 10 levels)
        AND LH.LINEAGE_PATH NOT LIKE '%' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME || '%'  -- Prevent circular dependencies
)
SELECT 
    ROOT_SCHEMA,
    ROOT_OBJECT AS ROOT_CALCULATION_VIEW,
    ROOT_TYPE,
    LEVEL,
    BASE_SCHEMA_NAME,
    BASE_OBJECT_NAME,
    BASE_OBJECT_TYPE,
    LINEAGE_PATH,
    HIERARCHY_DISPLAY
FROM 
    LINEAGE_HIERARCHY
ORDER BY 
    LEVEL, BASE_OBJECT_NAME;

-- Expected Output:
-- Level 1: Immediate dependencies (CV_TEST → CUSTOMERS, SALES, PRODUCTS)
-- Level 2: Dependencies of those objects (if they are also CVs)
-- Level N: Continues until all base tables are found


-- =====================================================================
-- SECTION 3: HIERARCHICAL TREE DISPLAY
-- Beautiful tree-like display of the entire lineage
-- =====================================================================

-- This version provides a clean, easy-to-read hierarchy
WITH RECURSIVE LINEAGE_HIERARCHY AS (
    -- Base case: Direct dependencies of the target calculation view
    SELECT 
        DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
        DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
        BASE_SCHEMA_NAME,
        BASE_OBJECT_NAME,
        BASE_OBJECT_TYPE,
        1 AS LEVEL,
        CAST(BASE_SCHEMA_NAME || '.' || BASE_OBJECT_NAME AS NVARCHAR(500)) AS LINEAGE_PATH,
        CAST('└─ ' || BASE_OBJECT_NAME || ' [' || BASE_OBJECT_TYPE || ']' AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        SYS.OBJECT_DEPENDENCIES
    WHERE 
        DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
        AND DEPENDENT_OBJECT_NAME = 'CV_TEST'
        AND DEPENDENCY_TYPE = 1
    
    UNION ALL
    
    -- Recursive case: Dependencies of the base objects
    SELECT 
        LH.ROOT_SCHEMA,
        LH.ROOT_OBJECT,
        OD.BASE_SCHEMA_NAME,
        OD.BASE_OBJECT_NAME,
        OD.BASE_OBJECT_TYPE,
        LH.LEVEL + 1 AS LEVEL,
        LH.LINEAGE_PATH || ' -> ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME AS LINEAGE_PATH,
        CAST(LPAD('', (LH.LEVEL + 1) * 2, ' ') || '└─ ' || OD.BASE_OBJECT_NAME || ' [' || OD.BASE_OBJECT_TYPE || ']' AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        LINEAGE_HIERARCHY LH
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
            ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
            AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
    WHERE 
        LH.LEVEL < 10
        AND LH.LINEAGE_PATH NOT LIKE '%' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME || '%'
)
SELECT 
    'Level ' || CAST(LEVEL AS VARCHAR) AS LEVEL_LABEL,
    HIERARCHY_DISPLAY AS DEPENDENCY_TREE,
    BASE_OBJECT_TYPE,
    CASE 
        WHEN BASE_OBJECT_TYPE = 'TABLE' THEN '✓ Base Table'
        WHEN BASE_OBJECT_TYPE = 'CALC VIEW' THEN '→ Calculation View (has more dependencies)'
        WHEN BASE_OBJECT_TYPE = 'VIEW' THEN '→ Database View'
        ELSE BASE_OBJECT_TYPE
    END AS OBJECT_DESCRIPTION
FROM 
    LINEAGE_HIERARCHY
ORDER BY 
    LEVEL, HIERARCHY_DISPLAY;

-- Example Output:
-- Level 1  └─ CUSTOMERS [TABLE]                      ✓ Base Table
-- Level 1  └─ PRODUCTS [TABLE]                       ✓ Base Table
-- Level 1  └─ SALES [TABLE]                          ✓ Base Table


-- =====================================================================
-- SECTION 4: SQLSCRIPT PROCEDURE FOR DYNAMIC LINEAGE
-- Can be called with any calculation view name
-- =====================================================================

CREATE OR REPLACE PROCEDURE GET_CV_LINEAGE(
    IN IV_SCHEMA_NAME NVARCHAR(256),
    IN IV_OBJECT_NAME NVARCHAR(256),
    OUT OT_LINEAGE TABLE (
        ROOT_SCHEMA NVARCHAR(256),
        ROOT_OBJECT NVARCHAR(256),
        LEVEL INT,
        BASE_SCHEMA NVARCHAR(256),
        BASE_OBJECT NVARCHAR(256),
        BASE_TYPE NVARCHAR(32),
        LINEAGE_PATH NVARCHAR(5000),
        HIERARCHY_DISPLAY NVARCHAR(5000)
    )
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS
BEGIN
    OT_LINEAGE = 
        WITH RECURSIVE LINEAGE_HIERARCHY AS (
            -- Base case: Direct dependencies
            SELECT 
                DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
                DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
                BASE_SCHEMA_NAME,
                BASE_OBJECT_NAME,
                BASE_OBJECT_TYPE,
                1 AS LEVEL,
                CAST(BASE_SCHEMA_NAME || '.' || BASE_OBJECT_NAME AS NVARCHAR(5000)) AS LINEAGE_PATH,
                CAST('└─ ' || BASE_OBJECT_NAME || ' [' || BASE_OBJECT_TYPE || ']' AS NVARCHAR(5000)) AS HIERARCHY_DISPLAY
            FROM 
                SYS.OBJECT_DEPENDENCIES
            WHERE 
                DEPENDENT_SCHEMA_NAME = :IV_SCHEMA_NAME
                AND DEPENDENT_OBJECT_NAME = :IV_OBJECT_NAME
                AND DEPENDENCY_TYPE = 1
            
            UNION ALL
            
            -- Recursive case: Dependencies of base objects
            SELECT 
                LH.ROOT_SCHEMA,
                LH.ROOT_OBJECT,
                OD.BASE_SCHEMA_NAME,
                OD.BASE_OBJECT_NAME,
                OD.BASE_OBJECT_TYPE,
                LH.LEVEL + 1 AS LEVEL,
                LH.LINEAGE_PATH || ' -> ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME AS LINEAGE_PATH,
                CAST(LPAD('', (LH.LEVEL + 1) * 2, ' ') || '└─ ' || OD.BASE_OBJECT_NAME || ' [' || OD.BASE_OBJECT_TYPE || ']' AS NVARCHAR(5000)) AS HIERARCHY_DISPLAY
            FROM 
                LINEAGE_HIERARCHY LH
                INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
                    ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
                    AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
                    AND OD.DEPENDENCY_TYPE = 1
            WHERE 
                LH.LEVEL < 10
                AND LH.LINEAGE_PATH NOT LIKE '%' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME || '%'
        )
        SELECT 
            ROOT_SCHEMA,
            ROOT_OBJECT,
            LEVEL,
            BASE_SCHEMA_NAME,
            BASE_OBJECT_NAME,
            BASE_OBJECT_TYPE,
            LINEAGE_PATH,
            HIERARCHY_DISPLAY
        FROM 
            LINEAGE_HIERARCHY
        ORDER BY 
            LEVEL, BASE_OBJECT_NAME;
END;

-- Usage example:
-- CALL GET_CV_LINEAGE('SGUNNAM', 'CV_TEST', ?);


-- =====================================================================
-- SECTION 5: LINEAGE SUMMARY BY OBJECT TYPE
-- Shows count of dependencies by object type at each level
-- =====================================================================

WITH RECURSIVE LINEAGE_HIERARCHY AS (
    SELECT 
        DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
        DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
        BASE_SCHEMA_NAME,
        BASE_OBJECT_NAME,
        BASE_OBJECT_TYPE,
        1 AS LEVEL,
        CAST(BASE_SCHEMA_NAME || '.' || BASE_OBJECT_NAME AS NVARCHAR(500)) AS LINEAGE_PATH
    FROM 
        SYS.OBJECT_DEPENDENCIES
    WHERE 
        DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
        AND DEPENDENT_OBJECT_NAME = 'CV_TEST'
        AND DEPENDENCY_TYPE = 1
    
    UNION ALL
    
    SELECT 
        LH.ROOT_SCHEMA,
        LH.ROOT_OBJECT,
        OD.BASE_SCHEMA_NAME,
        OD.BASE_OBJECT_NAME,
        OD.BASE_OBJECT_TYPE,
        LH.LEVEL + 1 AS LEVEL,
        LH.LINEAGE_PATH || ' -> ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME AS LINEAGE_PATH
    FROM 
        LINEAGE_HIERARCHY LH
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
            ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
            AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
    WHERE 
        LH.LEVEL < 10
        AND LH.LINEAGE_PATH NOT LIKE '%' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME || '%'
)
SELECT 
    ROOT_OBJECT AS CALCULATION_VIEW,
    LEVEL,
    BASE_OBJECT_TYPE,
    COUNT(*) AS OBJECT_COUNT,
    STRING_AGG(BASE_OBJECT_NAME, ', ') AS OBJECTS_LIST
FROM 
    LINEAGE_HIERARCHY
GROUP BY 
    ROOT_OBJECT, LEVEL, BASE_OBJECT_TYPE
ORDER BY 
    LEVEL, BASE_OBJECT_TYPE;

-- Example Output:
-- CALCULATION_VIEW | LEVEL | BASE_OBJECT_TYPE | OBJECT_COUNT | OBJECTS_LIST
-- CV_TEST          | 1     | TABLE           | 3            | CUSTOMERS, PRODUCTS, SALES


-- =====================================================================
-- SECTION 6: COMPLETE LINEAGE PATH VIEW
-- Shows all complete paths from CV to base tables
-- =====================================================================

WITH RECURSIVE LINEAGE_HIERARCHY AS (
    SELECT 
        DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
        DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
        DEPENDENT_OBJECT_TYPE AS ROOT_TYPE,
        BASE_SCHEMA_NAME,
        BASE_OBJECT_NAME,
        BASE_OBJECT_TYPE,
        1 AS LEVEL,
        CAST(DEPENDENT_SCHEMA_NAME || '.' || DEPENDENT_OBJECT_NAME AS NVARCHAR(5000)) AS LINEAGE_PATH,
        DEPENDENT_SCHEMA_NAME || '.' || DEPENDENT_OBJECT_NAME AS START_OBJECT
    FROM 
        SYS.OBJECT_DEPENDENCIES
    WHERE 
        DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
        AND DEPENDENT_OBJECT_NAME = 'CV_TEST'
        AND DEPENDENCY_TYPE = 1
    
    UNION ALL
    
    SELECT 
        LH.ROOT_SCHEMA,
        LH.ROOT_OBJECT,
        LH.ROOT_TYPE,
        OD.BASE_SCHEMA_NAME,
        OD.BASE_OBJECT_NAME,
        OD.BASE_OBJECT_TYPE,
        LH.LEVEL + 1 AS LEVEL,
        LH.LINEAGE_PATH || ' → ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME AS LINEAGE_PATH,
        LH.START_OBJECT
    FROM 
        LINEAGE_HIERARCHY LH
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
            ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
            AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
    WHERE 
        LH.LEVEL < 10
        AND LH.LINEAGE_PATH NOT LIKE '%' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME || '%'
)
SELECT 
    ROOT_OBJECT AS SOURCE_CV,
    LEVEL AS DEPTH,
    BASE_OBJECT_NAME AS TARGET_OBJECT,
    BASE_OBJECT_TYPE AS TARGET_TYPE,
    LINEAGE_PATH AS COMPLETE_PATH,
    CASE 
        WHEN BASE_OBJECT_TYPE = 'TABLE' THEN 'YES'
        ELSE 'NO'
    END AS IS_BASE_TABLE
FROM 
    LINEAGE_HIERARCHY
ORDER BY 
    LINEAGE_PATH, LEVEL;

-- Example Output:
-- SOURCE_CV | DEPTH | TARGET_OBJECT | TARGET_TYPE | COMPLETE_PATH                                    | IS_BASE_TABLE
-- CV_TEST   | 1     | CUSTOMERS     | TABLE       | SGUNNAM.CV_TEST → SGUNNAM.CUSTOMERS              | YES
-- CV_TEST   | 1     | PRODUCTS      | TABLE       | SGUNNAM.CV_TEST → SGUNNAM.PRODUCTS               | YES
-- CV_TEST   | 1     | SALES         | TABLE       | SGUNNAM.CV_TEST → SGUNNAM.SALES                  | YES


-- =====================================================================
-- SECTION 7: USAGE EXAMPLES FOR DIFFERENT CALCULATION VIEWS
-- =====================================================================

-- Example 1: Get lineage for CV_SALES_ANALYSIS
/*
WITH RECURSIVE LINEAGE_HIERARCHY AS (
    SELECT 
        DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
        DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
        BASE_SCHEMA_NAME,
        BASE_OBJECT_NAME,
        BASE_OBJECT_TYPE,
        1 AS LEVEL,
        CAST('└─ ' || BASE_OBJECT_NAME || ' [' || BASE_OBJECT_TYPE || ']' AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        SYS.OBJECT_DEPENDENCIES
    WHERE 
        DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
        AND DEPENDENT_OBJECT_NAME = 'CV_SALES_ANALYSIS'
        AND DEPENDENCY_TYPE = 1
    
    UNION ALL
    
    SELECT 
        LH.ROOT_SCHEMA,
        LH.ROOT_OBJECT,
        OD.BASE_SCHEMA_NAME,
        OD.BASE_OBJECT_NAME,
        OD.BASE_OBJECT_TYPE,
        LH.LEVEL + 1 AS LEVEL,
        CAST(LPAD('', (LH.LEVEL + 1) * 2, ' ') || '└─ ' || OD.BASE_OBJECT_NAME || ' [' || OD.BASE_OBJECT_TYPE || ']' AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        LINEAGE_HIERARCHY LH
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
            ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
            AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
    WHERE 
        LH.LEVEL < 10
)
SELECT * FROM LINEAGE_HIERARCHY ORDER BY LEVEL;
*/

-- Example 2: Get lineage for CV_CUSTOMER_360
/*
-- Replace 'CV_CUSTOMER_360' in any of the queries above
WHERE 
    DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
    AND DEPENDENT_OBJECT_NAME = 'CV_CUSTOMER_360'
    AND DEPENDENCY_TYPE = 1
*/

-- Example 3: Get lineage for multiple CVs at once
/*
WITH RECURSIVE LINEAGE_HIERARCHY AS (
    SELECT 
        DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
        DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
        BASE_SCHEMA_NAME,
        BASE_OBJECT_NAME,
        BASE_OBJECT_TYPE,
        1 AS LEVEL
    FROM 
        SYS.OBJECT_DEPENDENCIES
    WHERE 
        DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
        AND DEPENDENT_OBJECT_NAME IN ('CV_TEST', 'CV_SALES_ANALYSIS', 'CV_CUSTOMER_360')
        AND DEPENDENCY_TYPE = 1
    
    UNION ALL
    
    SELECT 
        LH.ROOT_SCHEMA,
        LH.ROOT_OBJECT,
        OD.BASE_SCHEMA_NAME,
        OD.BASE_OBJECT_NAME,
        OD.BASE_OBJECT_TYPE,
        LH.LEVEL + 1 AS LEVEL
    FROM 
        LINEAGE_HIERARCHY LH
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
            ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
            AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
    WHERE 
        LH.LEVEL < 10
)
SELECT 
    ROOT_OBJECT,
    LEVEL,
    BASE_OBJECT_NAME,
    BASE_OBJECT_TYPE
FROM 
    LINEAGE_HIERARCHY
ORDER BY 
    ROOT_OBJECT, LEVEL, BASE_OBJECT_NAME;
*/


-- =====================================================================
-- SECTION 8: NOTES AND DOCUMENTATION
-- =====================================================================

/*
ABOUT OBJECT_DEPENDENCIES TABLE:
---------------------------------
The SYS.OBJECT_DEPENDENCIES table contains dependency information between database objects.

Key Columns:
- DEPENDENT_SCHEMA_NAME: Schema of the object that depends on another
- DEPENDENT_OBJECT_NAME: Name of the dependent object (e.g., calculation view)
- DEPENDENT_OBJECT_TYPE: Type (e.g., 'CALC VIEW', 'VIEW', 'TABLE')
- BASE_SCHEMA_NAME: Schema of the object being depended upon
- BASE_OBJECT_NAME: Name of the base object
- BASE_OBJECT_TYPE: Type of base object
- DEPENDENCY_TYPE: Type of dependency (1 = direct dependency)

DEPENDENCY_TYPE = 1:
--------------------
This represents direct dependencies. When a calculation view uses a table or another CV,
there's a direct dependency relationship with DEPENDENCY_TYPE = 1.

HIERARCHY LEVELS:
-----------------
Level 1: Direct dependencies of the target CV
Level 2: Dependencies of Level 1 objects (if they are also CVs)
Level 3: Dependencies of Level 2 objects
... and so on until all base tables are reached

PREVENTING INFINITE LOOPS:
---------------------------
1. Maximum level check (LEVEL < 10)
2. Path checking to prevent circular dependencies
3. LINEAGE_PATH NOT LIKE check prevents revisiting objects

OBJECT TYPES:
-------------
Common object types you'll see:
- TABLE: Base database table
- CALC VIEW: Calculation view
- VIEW: Standard database view
- PROCEDURE: Stored procedure
- FUNCTION: User-defined function

PERFORMANCE CONSIDERATIONS:
---------------------------
- Recursive CTEs can be expensive for deep hierarchies
- Consider adding WHERE clauses to limit scope
- Use indexes on OBJECT_DEPENDENCIES if available
- For production, consider caching results

SECURITY:
---------
- Requires SELECT privilege on SYS.OBJECT_DEPENDENCIES
- User must have access to view system metadata
- May need SYS schema access depending on HANA version
*/


-- =====================================================================
-- SECTION 9: ADVANCED QUERY - LINEAGE WITH METADATA
-- Includes additional information about objects
-- =====================================================================

WITH RECURSIVE LINEAGE_HIERARCHY AS (
    SELECT 
        DEPENDENT_SCHEMA_NAME AS ROOT_SCHEMA,
        DEPENDENT_OBJECT_NAME AS ROOT_OBJECT,
        DEPENDENT_OBJECT_TYPE AS ROOT_TYPE,
        BASE_SCHEMA_NAME,
        BASE_OBJECT_NAME,
        BASE_OBJECT_TYPE,
        1 AS LEVEL,
        CAST(BASE_SCHEMA_NAME || '.' || BASE_OBJECT_NAME AS NVARCHAR(500)) AS LINEAGE_PATH,
        CAST('└─ ' || BASE_OBJECT_NAME AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        SYS.OBJECT_DEPENDENCIES
    WHERE 
        DEPENDENT_SCHEMA_NAME = 'SGUNNAM'
        AND DEPENDENT_OBJECT_NAME = 'CV_TEST'
        AND DEPENDENCY_TYPE = 1
    
    UNION ALL
    
    SELECT 
        LH.ROOT_SCHEMA,
        LH.ROOT_OBJECT,
        LH.ROOT_TYPE,
        OD.BASE_SCHEMA_NAME,
        OD.BASE_OBJECT_NAME,
        OD.BASE_OBJECT_TYPE,
        LH.LEVEL + 1 AS LEVEL,
        LH.LINEAGE_PATH || ' -> ' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME AS LINEAGE_PATH,
        CAST(LPAD('', (LH.LEVEL + 1) * 2, ' ') || '└─ ' || OD.BASE_OBJECT_NAME AS NVARCHAR(1000)) AS HIERARCHY_DISPLAY
    FROM 
        LINEAGE_HIERARCHY LH
        INNER JOIN SYS.OBJECT_DEPENDENCIES OD 
            ON LH.BASE_SCHEMA_NAME = OD.DEPENDENT_SCHEMA_NAME
            AND LH.BASE_OBJECT_NAME = OD.DEPENDENT_OBJECT_NAME
            AND OD.DEPENDENCY_TYPE = 1
    WHERE 
        LH.LEVEL < 10
        AND LH.LINEAGE_PATH NOT LIKE '%' || OD.BASE_SCHEMA_NAME || '.' || OD.BASE_OBJECT_NAME || '%'
)
SELECT 
    LH.ROOT_OBJECT AS CALCULATION_VIEW,
    LH.LEVEL,
    LH.HIERARCHY_DISPLAY,
    LH.BASE_SCHEMA_NAME || '.' || LH.BASE_OBJECT_NAME AS FULL_OBJECT_NAME,
    LH.BASE_OBJECT_TYPE,
    CASE 
        WHEN LH.BASE_OBJECT_TYPE = 'TABLE' THEN 'Physical Table'
        WHEN LH.BASE_OBJECT_TYPE = 'CALC VIEW' THEN 'Calculation View (check next level)'
        WHEN LH.BASE_OBJECT_TYPE = 'VIEW' THEN 'Database View'
        WHEN LH.BASE_OBJECT_TYPE = 'SYNONYM' THEN 'Synonym (resolve to actual object)'
        ELSE 'Other: ' || LH.BASE_OBJECT_TYPE
    END AS OBJECT_DESCRIPTION,
    LH.LINEAGE_PATH AS FULL_PATH
FROM 
    LINEAGE_HIERARCHY LH
ORDER BY 
    LH.LEVEL, LH.BASE_OBJECT_NAME;


-- =====================================================================
-- END OF HANA LINEAGE QUERY
-- =====================================================================
