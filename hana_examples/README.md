# HANA Calculation View Examples

This directory contains example HANA calculation views that demonstrate how GitHub Agent can assist with development.

## Example Files

### Calculation Views
- `CV_SALES_ANALYSIS.hdbcalculationview` - Sales analysis calculation view with joins and aggregations
- `CV_CUSTOMER_360.hdbcalculationview` - Customer 360 view with multiple data sources
- `CV_TEST 1.hdbcalculationview` - Test calculation view with Products join, calculated measure, customer filter, and product parameter
- `CV_TEST.hdbcalculationview` - Basic test calculation view

### Documentation
- `CV_SALES_ANALYSIS_CHANGELOG.md` - Change history for Sales Analysis view
- `CV_TEST_1_TEST_CASES.md` - **Comprehensive test cases for CV_TEST 1** (19 test scenarios)
- `CV_TEST_1_QUICK_REFERENCE.md` - **Quick reference guide for CV_TEST 1 testing**
- `CV_TEST_1_PARAMETER_GUIDE.md` - **Product name parameter usage guide**
- `CV_TEST_1_SQL_EQUIVALENT.sql` - **HANA SQL equivalent of CV_TEST 1 calculation view**
- `HANA_LINEAGE_QUERY.sql` - **Recursive lineage query for calculation views** ✨ (NEW)

## CV_TEST 1 - Test Documentation

### Test Cases Available
The CV_TEST 1 calculation view has comprehensive test documentation including:

#### 📋 Full Test Cases (`CV_TEST_1_TEST_CASES.md`)
- **8 Positive Test Cases** - What should work
- **8 Negative Test Cases** - What should not happen
- **3 Edge Cases** - Boundary conditions
- Complete SQL queries for validation
- Expected vs Not Expected results
- Data setup scripts

#### ⚡ Quick Reference (`CV_TEST_1_QUICK_REFERENCE.md`)
- Quick validation checklist
- 5-query validation script
- Common issues and solutions
- Pass/Fail criteria

#### 📝 SQL Equivalent (`CV_TEST_1_SQL_EQUIVALENT.sql`)
- Complete HANA SQL representation of CV_TEST 1
- 3 different SQL formats (Simple SELECT, SQLScript, CTE)
- Usage examples and parameter handling
- Performance optimization notes
- Testing queries

#### 🔍 Lineage Query ✨ NEW

**⭐ RECOMMENDED: `HANA_LINEAGE_ONPREMISE.sql`** - For HANA Studio On-Premise
- ✅ **Tested and working** in HANA Studio on-premise
- No WITH RECURSIVE (uses HANA-compatible syntax)
- Multiple approaches: UNION ALL, DO blocks, explicit JOINs
- Copy-paste ready queries with clear parameter markers
- Quick Start section for immediate use
- 2-level, 3-level, and unlimited level options
- Uses `OBJECT_DEPENDENCIES` table with `DEPENDENCY_TYPE = 1`

**`HANA_LINEAGE_QUERY.sql`** - Advanced (may not work on-premise)
- Recursive SQL to pull all lineages for calculation views
- Uses `OBJECT_DEPENDENCIES` table with `DEPENDENCY_TYPE = 1`
- Shows complete hierarchy (CV → CV → Table)
- Hierarchical tree display with visual indicators
- Stored procedure for reusable queries
- ⚠️ Note: WITH RECURSIVE may not work in HANA Studio on-premise

### Features in CV_TEST 1
1. **Products Join** - Displays PRODUCT_NAME instead of PRODUCT_ID
2. **SELLING_PRICE Calculated Measure** - Formula: UNIT_PRICE - DISCOUNT_AMOUNT - TAX_AMOUNT
3. **Active Customer Filter** - Only shows customers with STATUS='Active'
4. **Product Name Parameter** ✨ (NEW) - Optional dropdown to filter by product (Laptop, Mobile Phone, Camera, Watch, TV, Smart bulb)

### Quick Test
```sql
-- Run this to validate CV_TEST 1 is working correctly
SELECT COUNT(DISTINCT FIRST_NAME) FROM CV_TEST; -- Should return 3 (active customers)

-- Test with product parameter
SELECT * FROM CV_TEST('IP_PRODUCT_NAME' => 'Laptop'); -- Filter by Laptop

-- Or use the SQL equivalent (see CV_TEST_1_SQL_EQUIVALENT.sql)
WITH PR_CUSTOMERS AS (
    SELECT CUSTOMER_ID, FIRST_NAME, LAST_NAME
    FROM SGUNNAM.CUSTOMERS WHERE STATUS = 'Active'
), ...
-- See full query in CV_TEST_1_SQL_EQUIVALENT.sql
```

## How to Use These Examples

1. Review the XML structure of calculation views
2. Use GitHub Agent to modify or enhance them
3. Import them into your HANA system for testing
4. Run test cases to validate functionality
5. Customize based on your data model

## GitHub Agent Capabilities

Ask GitHub Agent to:
- Add new data sources
- Create calculated columns
- Optimize join logic
- Add filters and variables
- Generate documentation
- **Create comprehensive test cases** (as demonstrated with CV_TEST 1)
- **Convert calculation views to SQL** (see CV_TEST_1_SQL_EQUIVALENT.sql)
- **Generate lineage queries** (see HANA_LINEAGE_QUERY.sql) ✨ NEW

## Testing Best Practices

When modifying calculation views:
1. ✅ Run positive test cases to verify expected functionality
2. ❌ Run negative test cases to ensure unwanted behavior doesn't occur
3. 🔍 Test edge cases and boundary conditions
4. 📊 Validate aggregation logic
5. 🎯 Check filter effectiveness
6. 🔗 Verify join relationships

See `CV_TEST_1_TEST_CASES.md` for a complete testing methodology example.

