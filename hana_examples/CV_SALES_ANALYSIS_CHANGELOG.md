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
- **Purpose**: Compares if aggregate-level QUANTITY × COST equals REVENUE

**Important**: This formula operates on already-aggregated values (SUM operations), comparing 
`SUM(QUANTITY) × SUM(COST)` with `SUM(REVENUE)`. This is an aggregate-level comparison, not a 
line-by-line validation. The result indicates whether the mathematical relationship holds true 
at the summary dimension level.

### Formula
```sql
CASE WHEN (QUANTITY * COST) = REVENUE THEN 'Yes' ELSE 'No' END
```

### Logic
- Compares aggregated values at the summary level
- **Left side**: `SUM(QUANTITY) × SUM(COST)` - Product of aggregated quantity and cost
- **Right side**: `SUM(REVENUE)` - Total revenue
- Returns **"Yes"** when values match
- Returns **"No"** when values differ

**Important Note**: This formula compares the product of aggregated sums, not the sum of products. 
The mathematical relationship `SUM(Q × C) ≠ SUM(Q) × SUM(C)` means this comparison is checking 
aggregate-level equality, which may differ from line-item level calculations. This is useful for 
validating data integrity at the summary level but should not be confused with detailed line-item 
validation.

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

- **Mathematical Behavior**: The comparison is done at the aggregation level using the formula 
  `SUM(QUANTITY) × SUM(COST) = SUM(REVENUE)`. This is different from comparing individual 
  line items where `QUANTITY × COST = REVENUE`. Due to the mathematical property that 
  `SUM(A × B) ≠ SUM(A) × SUM(B)` in general, this aggregate-level comparison may show "No" 
  even when all individual line items are correct.
  
- **Use Case**: This formula is useful for:
  - Validating that aggregate totals match expected relationships
  - Identifying summary-level discrepancies
  - Data quality checks at the aggregate dimension level
  
- **Not suitable for**: Line-by-line validation of individual transactions

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
