# CV_TEST 1 - Product Name Parameter

## Overview

CV_TEST 1 calculation view now includes an optional input parameter that allows users to filter results by product name using a dropdown selection. The parameter has a default value that displays all products when no specific selection is made.

## Parameter Details

### IP_PRODUCT_NAME

**Description**: Product Name  
**Type**: Input Parameter (Static List)  
**Data Type**: NVARCHAR(50)  
**Selection**: Single selection  
**Mandatory**: No (Optional)  
**Default Value**: "%" (All Products) ✨

## Available Values

The parameter provides 7 predefined options:

1. **All Products** (%) - **DEFAULT** ✨ - Shows all products
2. **Laptop** - Shows only Laptop products
3. **Mobile Phone** - Shows only Mobile Phone products
4. **Camera** - Shows only Camera products
5. **Watch** - Shows only Watch products
6. **TV** - Shows only TV products
7. **Smart bulb** - Shows only Smart bulb products

## How to Use

### In HANA Studio

1. Open CV_TEST 1 calculation view
2. Click "Data Preview" or execute the view
3. A parameter prompt will appear with "All Products" pre-selected
4. Options:
   - **Keep default** ("All Products") to see all products
   - **Select specific product** to filter results
5. Click OK to view results

### In SQL

You can pass the parameter value directly in your query:

```sql
-- View all products (using default)
SELECT * FROM CV_TEST;

-- Explicitly select all products
SELECT * FROM CV_TEST('IP_PRODUCT_NAME' => '%');

-- Filter by specific product
SELECT * FROM CV_TEST('IP_PRODUCT_NAME' => 'Laptop');

-- Filter by another product
SELECT * FROM CV_TEST('IP_PRODUCT_NAME' => 'Mobile Phone');
```

### In SAP Analytics Cloud or BI Tools

The parameter appears as a dropdown filter when the calculation view is consumed in reporting tools. The default "All Products" option is pre-selected.

## Behavior

### Default Behavior (No Selection or "All Products")
When "All Products" is selected (default):
- **Filter Applied**: `"PRODUCT_NAME" LIKE '%'`
- **Result**: All products are displayed
- **Performance**: No filtering overhead
- **Use Case**: General reporting, dashboard overview

### With Specific Product Selection
When a specific product is selected (e.g., "Laptop"):
- **Filter Applied**: `"PRODUCT_NAME" LIKE 'Laptop'`
- **Result**: Only data for that specific product is displayed
- **Performance**: Filter applied at PR_PRODUCTS projection level (early filtering)
- **Use Case**: Product-specific analysis, detailed reports

## Technical Implementation

### Filter Location
The filter is applied at the **PR_PRODUCTS projection view** level:

```xml
<filter>"PRODUCT_NAME" LIKE '$$IP_PRODUCT_NAME$$'</filter>
```

### How It Works
1. User selects parameter value (default: "%")
2. Value replaces `$$IP_PRODUCT_NAME$$` placeholder
3. Filter expression becomes: `"PRODUCT_NAME" LIKE '%'` or `"PRODUCT_NAME" LIKE 'Laptop'`
4. LIKE operator with "%" matches all product names
5. LIKE operator with specific name matches only that product

### Why LIKE Instead of =
- **Flexibility**: Allows wildcard matching
- **Default "All"**: "%" wildcard matches everything
- **Single Expression**: No need for complex conditional logic
- **Extensible**: Can be enhanced for partial matching if needed

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

### Example 3: All Products (Default Behavior)
```sql
-- Option 1: Don't specify parameter (uses default)
SELECT 
    PRODUCT_NAME,
    SUM(SELLING_PRICE) as TOTAL_REVENUE
FROM CV_TEST
GROUP BY PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC;

-- Option 2: Explicitly use wildcard
SELECT 
    PRODUCT_NAME,
    SUM(SELLING_PRICE) as TOTAL_REVENUE
FROM CV_TEST('IP_PRODUCT_NAME' => '%')
GROUP BY PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC;
```

**Expected Output** (with test data):
```
PRODUCT_NAME     | TOTAL_REVENUE
-----------------|---------------
Laptop Computer  | 1050.00
External Monitor | 255.00
Wireless Mouse   | 22.00
USB Cable        | 4.25
```

### Example 4: Compare Products
```sql
-- Get Laptop revenue
SELECT SUM(SELLING_PRICE) as LAPTOP_REVENUE
FROM CV_TEST('IP_PRODUCT_NAME' => 'Laptop');

-- Get all product revenue
SELECT SUM(SELLING_PRICE) as TOTAL_REVENUE
FROM CV_TEST;
```

## Technical Implementation

### Variable Definition

```xml
<variable id="IP_PRODUCT_NAME" parameter="true">
  <descriptions defaultDescription="Product Name"/>
  <variableProperties datatype="NVARCHAR" length="50" mandatory="false" defaultValue="%">
    <valueDomain type="StaticList">
      <listEntry id="%">
        <descriptions defaultDescription="All Products"/>
      </listEntry>
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

### Variable Mapping and Filter

The variable is mapped to the PR_PRODUCTS projection view with a filter:

```xml
<!-- Variable Mapping -->
<mapping xsi:type="Calculation:VariableMapping" dataSource="#PR_PRODUCTS" variable="IP_PRODUCT_NAME">
  <mapping xsi:type="Calculation:AttributeMapping" target="PRODUCT_NAME" source="IP_PRODUCT_NAME"/>
</mapping>

<!-- Filter in PR_PRODUCTS Projection -->
<calculationView xsi:type="Calculation:ProjectionView" id="PR_PRODUCTS">
  ...
  <filter>"PRODUCT_NAME" LIKE '$$IP_PRODUCT_NAME$$'</filter>
</calculationView>
```

**Key Points**:
- Filter uses LIKE operator for pattern matching
- `$$IP_PRODUCT_NAME$$` is replaced with parameter value at runtime
- Default value "%" matches all products (wildcard)
- Specific values match exactly (e.g., "Laptop")

## Benefits

### User Experience
- ✅ **Clear Default**: "All Products" option is pre-selected
- ✅ **No Confusion**: Users know what happens without selection
- ✅ **Explicit Choice**: 7 clear options including "All Products"
- ✅ **Backward Compatible**: Existing queries work unchanged

### Performance
- ✅ **Early Filtering**: Applied at projection level (PR_PRODUCTS)
- ✅ **Reduced Data Volume**: When specific product selected, fewer rows
- ✅ **Optimized Joins**: Less data flowing through downstream joins
- ✅ **Index Friendly**: LIKE with exact match can use indexes

### Development
- ✅ **Simple Logic**: Single LIKE expression handles all cases
- ✅ **No Conditionals**: No need for complex IF/ELSE logic
- ✅ **Maintainable**: Easy to understand and modify
- ✅ **Extensible**: Can add partial matching later if needed

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
