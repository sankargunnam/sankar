# Section 4b Quick Reference - Columnar Lineage Format

## What It Does
Displays calculation view lineage in columnar format with columns: **Object, L1, L2, L3, L4**

## Output Format
```
Object   | L1        | L2          | L3        | L4
---------|-----------|-------------|-----------|----------
CV_TEST  | CUSTOMERS | NULL        | NULL      | NULL
CV_TEST  | CV_SALES  | SALES_DATA  | NULL      | NULL
CV_TEST  | CV_SALES  | PRODUCTS    | NULL      | NULL
```

## Quick Start (3 Steps)

### Step 1: Open File
```
File: hana_examples/HANA_LINEAGE_ONPREMISE.sql
Section: 4b (around line 238)
```

### Step 2: Change Parameters
```sql
DECLARE lv_schema NVARCHAR(256) := 'SGUNNAM';     -- ← Your schema
DECLARE lv_cv_name NVARCHAR(256) := 'CV_TEST';   -- ← Your CV name
```

### Step 3: Execute
- Select entire DO block (Section 4b)
- Press **F8** or click **Execute**
- Results appear in columnar format!

## Column Meanings

| Column | Description | Example Values |
|--------|-------------|----------------|
| **Object** | Root calculation view you're analyzing | CV1, CV_TEST, CV_MAIN |
| **L1** | First level dependency | CV2, CUSTOMERS, PRODUCTS |
| **L2** | Second level dependency | Table 1, CV3, SALES_DATA |
| **L3** | Third level dependency | Table 3, CV 7 |
| **L4** | Fourth level dependency | Table 5, Table 6 |

## Example Output

### For Simple CV (Direct Tables):
```
Object   | L1        | L2   | L3   | L4
---------|-----------|------|------|----
CV_TEST  | CUSTOMERS | NULL | NULL | NULL
CV_TEST  | PRODUCTS  | NULL | NULL | NULL
CV_TEST  | SALES     | NULL | NULL | NULL
```

### For Complex CV (Nested CVs):
```
Object | L1  | L2       | L3      | L4
-------|-----|----------|---------|----------
CV1    | CV2 | Table 1  | NULL    | NULL
CV1    | CV2 | Table 2  | NULL    | NULL
CV1    | CV2 | CV3      | Table 3 | NULL
CV1    | CV4 | CV5      | Table 4 | NULL
CV1    | CV4 | CV5      | CV 7    | Table 5
CV1    | CV4 | CV6      | CV 8    | Table 6
CV1    | CV4 | CV6      | CV 9    | Table 7
```

## Benefits
- ✅ Clean columnar format (no tree symbols)
- ✅ Easy to export to Excel/CSV
- ✅ One complete path per row
- ✅ NULL for unused levels
- ✅ Perfect for analysis and reporting

## Tips
1. **To see all paths**: Leave parameters as is and execute
2. **To export**: Copy results to Excel directly
3. **To analyze**: Sort by any column in Excel
4. **For deeper hierarchies**: Levels beyond L4 won't show (max 5 levels)

## Troubleshooting

### No results?
- Check schema name is correct
- Check CV name exists
- Verify you have permissions

### Missing levels?
- Check DEPENDENCY_TYPE = 1 in OBJECT_DEPENDENCIES table
- Ensure CV has dependencies

### Too many results?
- This is normal - shows all possible paths
- Each unique path gets its own row

## When to Use

### Use Section 4b (Columnar) for:
- ✅ Excel export
- ✅ Data analysis
- ✅ Reports
- ✅ Clean tabular data

### Use Section 4 (Tree) for:
- Visual hierarchy
- Quick understanding
- Presentations

---

**File Location**: `hana_examples/HANA_LINEAGE_ONPREMISE.sql` - Section 4b  
**Format**: Object | L1 | L2 | L3 | L4  
**Ready to Use**: Change 2 parameters and execute!
