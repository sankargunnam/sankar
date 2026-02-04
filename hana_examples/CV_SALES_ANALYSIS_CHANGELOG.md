# CV_SALES_ANALYSIS Calculation View Modification

## Change Summary

**Date**: 2026-02-04  
**File**: `hana_examples/CV_SALES_ANALYSIS.hdbcalculationview`  
**Change**: Added calculated column to Aggregation node

## New Calculated Column

### Column Details
- **Name**: `COST_REVENUE_MATCH`
- **Type**: NVARCHAR(3)
- **Location**: Aggregation node (calculatedViewAttributes)
- **Purpose**: Validates if QUANTITY × COST equals REVENUE

### Formula
```sql
CASE WHEN (QUANTITY * COST) = REVENUE THEN 'Yes' ELSE 'No' END
```

### Logic
- Compares aggregated values: `(SUM(QUANTITY) × SUM(COST))` vs `SUM(REVENUE)`
- Returns **"Yes"** when values match
- Returns **"No"** when values differ

## Implementation Details

### 1. Calculated Column in Aggregation Node
Added to the `calculatedViewAttributes` section at line 191-195:

```xml
<calculatedViewAttribute datatype="NVARCHAR" id="COST_REVENUE_MATCH" length="3" expressionLanguage="COLUMN_ENGINE">
  <formula>CASE WHEN (QUANTITY * COST) = REVENUE THEN 'Yes' ELSE 'No' END</formula>
</calculatedViewAttribute>
```

### 2. Logical Model Attribute
Added to the `attributes` section at line 235-238:

```xml
<attribute id="COST_REVENUE_MATCH" order="6" attributeHierarchyActive="false" displayAttribute="false">
  <descriptions defaultDescription="Cost-Revenue Match Indicator"/>
  <keyMapping columnObjectName="Aggregation" columnName="COST_REVENUE_MATCH"/>
</attribute>
```

### 3. Updated Measure Orders
All base measures renumbered to accommodate new attribute:
- QUANTITY: 6 → 7
- REVENUE: 7 → 8
- COST: 8 → 9
- PROFIT: 9 → 10
- PROFIT_MARGIN: 10 → 11

## Usage Examples

### Query Example
```sql
SELECT 
  REGION,
  COUNTRY,
  QUANTITY,
  COST,
  REVENUE,
  COST_REVENUE_MATCH
FROM CV_SALES_ANALYSIS
WHERE FISCAL_YEAR = 2024
```

### Expected Output
```
REGION | COUNTRY | QUANTITY | COST   | REVENUE | COST_REVENUE_MATCH
-------|---------|----------|--------|---------|-------------------
APAC   | China   | 1000     | 100.00 | 100000  | Yes
EMEA   | Germany | 500      | 200.00 | 95000   | No
NA     | USA     | 750      | 150.00 | 112500  | Yes
```

## Business Value

This calculated column provides:

1. **Data Quality Validation**
   - Identifies discrepancies between calculated and actual revenue
   - Flags potential data entry errors

2. **Revenue Integrity Check**
   - Ensures revenue calculations are consistent with cost and quantity
   - Helps maintain data accuracy

3. **Audit Trail**
   - Provides clear indication of data consistency
   - Simplifies data validation processes

4. **Analysis Support**
   - Quick visual indicator of revenue accuracy
   - Supports data quality reporting

## Notes

- The comparison is done at the aggregation level (after SUM operations)
- NULL values in QUANTITY, COST, or REVENUE will result in "No"
- The column is available in all queries against the calculation view
- No impact on existing queries or reports (backward compatible)

## Related Files

- Calculation View: `hana_examples/CV_SALES_ANALYSIS.hdbcalculationview`
- Documentation: `GITHUB_AGENT_FOR_HANA_DEVELOPMENT.md`
- Examples: `hana_examples/README.md`

## Validation

✅ XML structure validated  
✅ Changes committed to repository  
✅ Backward compatible with existing queries  
✅ No breaking changes to existing attributes or measures
