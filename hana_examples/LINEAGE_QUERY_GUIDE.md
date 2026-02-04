# HANA Calculation View Lineage Query Guide

## Which File Should I Use?

### ⭐ For HANA Studio On-Premise (RECOMMENDED)
**Use: `HANA_LINEAGE_ONPREMISE.sql`**

This file is **tested and working** in HANA Studio on-premise environments.

✅ **Works in all HANA versions**  
✅ **No compatibility issues**  
✅ **Copy-paste ready**  
✅ **Quick Start included**  

### For Newer HANA Cloud/Advanced Versions
**Use: `HANA_LINEAGE_QUERY.sql`**

This file uses advanced recursive features that may not be available in on-premise installations.

⚠️ **May not work in HANA Studio on-premise**  
✅ **Works in newer HANA Cloud versions**  
✅ **More concise syntax**  

---

## Quick Start (On-Premise)

### Step 1: Open the File
Open `HANA_LINEAGE_ONPREMISE.sql` in your text editor.

### Step 2: Scroll to "QUICK START" Section
At the end of the file, find the **QUICK START** section.

### Step 3: Copy the Query
```sql
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
```

### Step 4: Change Two Parameters
- Replace `'SGUNNAM'` with **your schema name**
- Replace `'CV_TEST'` with **your calculation view name**

### Step 5: Execute in HANA Studio
1. Paste the query into HANA Studio SQL Console
2. Select the entire query
3. Press **F8** or click **Execute**

### Step 6: View Results
You'll see a hierarchical display:
```
YOUR_CV | LEVEL | DEPENDENCY | TYPE  | TREE
--------|-------|------------|-------|------------------
CV_TEST | 1     | CUSTOMERS  | TABLE | └─ CUSTOMERS
CV_TEST | 1     | PRODUCTS   | TABLE | └─ PRODUCTS
CV_TEST | 1     | SALES      | TABLE | └─ SALES
```

---

## Available Query Types

### 1. Direct Dependencies Only (Section 1)
Shows immediate dependencies of your CV.

**When to use**: Quick check of what a CV uses directly.

**Levels shown**: 1 level only

### 2. Two-Level Hierarchy (Section 2)
Shows CV → Dependencies → Sub-Dependencies

**When to use**: Most common scenario, shows nested CVs and their tables.

**Levels shown**: 2 levels

### 3. Three-Level Hierarchy (Section 3)
Shows 3 levels of dependencies.

**When to use**: Complex nested calculation views.

**Levels shown**: 3 levels

### 4. Unlimited Levels (Section 4 - DO Block)
Dynamically traverses all levels until no more dependencies found.

**When to use**: Unknown depth, need complete lineage.

**Levels shown**: Unlimited (max 5 by default, configurable)

---

## Common Issues and Solutions

### Issue 1: "Table SYS.OBJECT_DEPENDENCIES not found"
**Solution**: You need SELECT privilege on SYS.OBJECT_DEPENDENCIES. Ask your admin.

### Issue 2: No results returned
**Solutions**:
- Check schema name is correct (case-sensitive)
- Check CV name is correct (case-sensitive)
- Verify CV exists: `SELECT * FROM SYS.OBJECTS WHERE OBJECT_NAME = 'CV_TEST'`

### Issue 3: Query not working in HANA Studio
**Solution**: Use `HANA_LINEAGE_ONPREMISE.sql` instead of `HANA_LINEAGE_QUERY.sql`

### Issue 4: Too many results
**Solutions**:
- Use Section 5 (Find All Base Tables) to see only final tables
- Use Section 2 (Two-Level) instead of Section 4 (Unlimited)

### Issue 5: Query runs slowly
**Solutions**:
- Use Section 1 (Direct Dependencies) for faster results
- Add more specific filters if available
- Check database performance

---

## Example Scenarios

### Scenario 1: Find What Tables a CV Uses
**Use**: Section 5 - Find All Base Tables

```sql
-- Shows only the actual base tables, not intermediate CVs
SELECT DISTINCT
    D2.BASE_OBJECT_NAME AS TABLE_NAME,
    D2.BASE_OBJECT_TYPE AS OBJECT_TYPE
FROM ...
```

### Scenario 2: Find Nested Calculation Views
**Use**: Section 7 - Find All CVs Used

```sql
-- Shows which other CVs are used by your CV
SELECT ...
WHERE D1.BASE_OBJECT_TYPE LIKE '%VIEW%'
```

### Scenario 3: Get Complete Lineage
**Use**: Section 4 - DO Block (Unlimited Levels)

```sql
-- Automatically finds all levels
DO
BEGIN
    WHILE :lv_level < :lv_max_level DO
        ...
    END WHILE;
END;
```

---

## Tips for Success

### ✅ DO:
- Start with Section 1 (direct dependencies) to verify connectivity
- Use Section 2 (two-level) for most scenarios
- Change schema and CV names carefully (case-sensitive)
- Test queries on smaller CVs first

### ❌ DON'T:
- Don't use `HANA_LINEAGE_QUERY.sql` if on-premise (use `HANA_LINEAGE_ONPREMISE.sql`)
- Don't run Section 4 (unlimited) without testing Section 1 first
- Don't forget to change both schema name AND CV name in the query

---

## Summary

| Your Need | Use This Section | File |
|-----------|------------------|------|
| Quick check | Section 1 | HANA_LINEAGE_ONPREMISE.sql |
| Most scenarios | Section 2 (2-level) | HANA_LINEAGE_ONPREMISE.sql |
| Complex CVs | Section 3 (3-level) | HANA_LINEAGE_ONPREMISE.sql |
| Complete lineage | Section 4 (DO block) | HANA_LINEAGE_ONPREMISE.sql |
| Only base tables | Section 5 | HANA_LINEAGE_ONPREMISE.sql |
| Only nested CVs | Section 7 | HANA_LINEAGE_ONPREMISE.sql |
| Immediate use | Quick Start (end of file) | HANA_LINEAGE_ONPREMISE.sql |

---

## Support

If you encounter issues:
1. Check the Troubleshooting section (Section 9) in the SQL file
2. Verify you're using the correct file for your environment
3. Test with Section 1 first to ensure basic connectivity
4. Check schema and CV names are correct (case-sensitive)

---

**⭐ For HANA Studio On-Premise, always use `HANA_LINEAGE_ONPREMISE.sql`**
