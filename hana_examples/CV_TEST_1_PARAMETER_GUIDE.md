# CV_TEST 1 - Product Name Parameter

## Overview

CV_TEST 1 calculation view now includes an optional input parameter that allows users to filter results by product name using a dropdown selection.

## Parameter Details

### IP_PRODUCT_NAME

**Description**: Product Name  
**Type**: Input Parameter (Static List)  
**Data Type**: NVARCHAR(50)  
**Selection**: Single selection  
**Mandatory**: No (Optional)

## Available Values

The parameter provides 6 predefined product options:

1. **Laptop**
2. **Mobile Phone**
3. **Camera**
4. **Watch**
5. **TV**
6. **Smart bulb**

## How to Use

### In HANA Studio

1. Open CV_TEST 1 calculation view
2. Click "Data Preview" or execute the view
3. A parameter prompt will appear
4. Select a product from the "Product Name" dropdown
5. Click OK to view filtered results

### In SQL

You can pass the parameter value directly in your query:

```sql
-- Filter by specific product
SELECT * FROM CV_TEST('IP_PRODUCT_NAME' => 'Laptop');

-- View all products (no filter)
SELECT * FROM CV_TEST;
```

### In SAP Analytics Cloud or BI Tools

The parameter appears as a dropdown filter when the calculation view is consumed in reporting tools.

## Behavior

### With Parameter Selection
When a product is selected:
- Only data for that specific product is displayed
- Filter is applied at the PR_PRODUCTS projection level
- Improves query performance by reducing data early

### Without Parameter Selection
When no product is selected:
- All products are displayed
- Standard view behavior (no filtering)
- Backward compatible with existing queries

## Examples

### Example 1: Get Laptop Sales
```sql
SELECT 
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    SELLING_PRICE
FROM CV_TEST('IP_PRODUCT_NAME' => 'Laptop')
ORDER BY FIRST_NAME;
```

**Expected Output** (with test data):
```
FIRST_NAME | LAST_NAME | PRODUCT_NAME    | SELLING_PRICE
-----------|-----------|-----------------|---------------
John       | Smith     | Laptop Computer | 1050.00
```

### Example 2: Get Mobile Phone Sales
```sql
SELECT 
    FIRST_NAME,
    LAST_NAME,
    PRODUCT_NAME,
    SELLING_PRICE
FROM CV_TEST('IP_PRODUCT_NAME' => 'Mobile Phone')
ORDER BY FIRST_NAME;
```

### Example 3: All Products (No Filter)
```sql
SELECT 
    PRODUCT_NAME,
    SUM(SELLING_PRICE) as TOTAL_REVENUE
FROM CV_TEST
GROUP BY PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC;
```

## Technical Implementation

### Variable Definition

```xml
<variable id="IP_PRODUCT_NAME" parameter="true">
  <descriptions defaultDescription="Product Name"/>
  <variableProperties datatype="NVARCHAR" length="50" mandatory="false">
    <valueDomain type="StaticList">
      <listEntry id="Laptop">
        <descriptions defaultDescription="Laptop"/>
      </listEntry>
      <listEntry id="Mobile Phone">
        <descriptions defaultDescription="Mobile Phone"/>
      </listEntry>
      <listEntry id="Camera">
        <descriptions defaultDescription="Camera"/>
      </listEntry>
      <listEntry id="Watch">
        <descriptions defaultDescription="Watch"/>
      </listEntry>
      <listEntry id="TV">
        <descriptions defaultDescription="TV"/>
      </listEntry>
      <listEntry id="Smart bulb">
        <descriptions defaultDescription="Smart bulb"/>
      </listEntry>
    </valueDomain>
    <selection multiLine="false" type="Single"/>
  </variableProperties>
</variable>
```

### Variable Mapping

The variable is mapped to the PR_PRODUCTS projection view:

```xml
<mapping xsi:type="Calculation:VariableMapping" dataSource="#PR_PRODUCTS" variable="IP_PRODUCT_NAME">
  <mapping xsi:type="Calculation:AttributeMapping" target="PRODUCT_NAME" source="IP_PRODUCT_NAME"/>
</mapping>
```

## Benefits

### User Experience
- ✅ **Easy Selection** - Dropdown prevents typing errors
- ✅ **Guided Input** - Only valid values can be selected
- ✅ **Optional** - Users can choose to filter or view all

### Performance
- ✅ **Early Filtering** - Reduces data at projection level
- ✅ **Optimized Queries** - Smaller result sets when filtered
- ✅ **Index Usage** - Database can optimize for specific product

### Data Quality
- ✅ **Standardized Values** - Predefined list ensures consistency
- ✅ **No Typos** - Eliminates manual entry errors
- ✅ **Validation** - Only valid products can be selected

## Integration with Existing Features

The product parameter works seamlessly with existing CV_TEST 1 features:

1. **Active Customer Filter**: Still applies (only Active customers shown)
2. **Products Join**: Filter applied after join is complete
3. **SELLING_PRICE Calculation**: Calculated normally for filtered products
4. **Aggregation**: Measures aggregate correctly for selected product

## Combination Example

You can use the parameter in combination with other filters:

```sql
-- Get Laptop sales for customers named John
SELECT * 
FROM CV_TEST('IP_PRODUCT_NAME' => 'Laptop')
WHERE FIRST_NAME = 'John';
```

## Important Notes

### Product Name Matching

The parameter performs **exact match** filtering on the PRODUCT_NAME field. Ensure that:

1. Product names in the PRODUCTS table match the static list values
2. Or update the static list to match your actual product names
3. Consider using partial matching (LIKE) if needed

### Current Test Data Compatibility

With the existing test data:
- "Laptop" parameter should match products containing "Laptop"
- Exact product name: "Laptop Computer"

If filtering returns no results, verify that product names in the PRODUCTS table match or contain the parameter values.

## Modifying the Static List

To add or change product options:

1. Open `CV_TEST 1.hdbcalculationview`
2. Locate the `<localVariables>` section
3. Add/modify `<listEntry>` elements within the `<valueDomain>`
4. Save and activate the calculation view

Example - Adding "Tablet":

```xml
<listEntry id="Tablet">
  <descriptions defaultDescription="Tablet"/>
</listEntry>
```

## Testing

### Test Scenarios

1. **No Parameter** - Verify all products display
2. **Select Laptop** - Verify only Laptop results
3. **Select Mobile Phone** - Verify only Mobile Phone results
4. **Each Option** - Test all 6 static list values
5. **Performance** - Compare query time with/without filter

### Validation Query

```sql
-- Check what products are available in test data
SELECT DISTINCT PRODUCT_NAME 
FROM SGUNNAM.PRODUCTS
ORDER BY PRODUCT_NAME;

-- Verify parameter works
SELECT COUNT(*) as PRODUCT_COUNT
FROM CV_TEST('IP_PRODUCT_NAME' => 'Laptop');
```

## Troubleshooting

### Issue: No Results When Parameter Selected

**Cause**: Product names in database don't match static list values

**Solution**: 
1. Check actual product names: `SELECT DISTINCT PRODUCT_NAME FROM SGUNNAM.PRODUCTS`
2. Update static list to match actual names
3. Or use partial matching logic

### Issue: Parameter Not Showing in Tool

**Cause**: Calculation view not activated or cached

**Solution**:
1. Activate the calculation view
2. Clear cache in your reporting tool
3. Refresh metadata

### Issue: Error "Unknown parameter"

**Cause**: Using old version of calculation view

**Solution**:
1. Ensure CV_TEST 1 is activated
2. Refresh in database
3. Re-import in consuming application

## Change History

| Date | Change | Version |
|------|--------|---------|
| 2026-02-04 | Added IP_PRODUCT_NAME parameter with 6 static values | Current |

## Related Documentation

- **CV_TEST 1 Test Cases**: `CV_TEST_1_TEST_CASES.md`
- **Quick Reference**: `CV_TEST_1_QUICK_REFERENCE.md`
- **SQL Tests**: `sql_tests/` directory

---

## Summary

The IP_PRODUCT_NAME parameter enhances CV_TEST 1 by providing:
- User-friendly dropdown selection
- Standardized product filtering
- Optional parameter (backward compatible)
- Improved query performance when filtering

Simply select a product from the list when executing the view, or leave it empty to see all products!
