# Incident Management System Tests

This directory contains comprehensive tests for the incident management system, covering both landing_zone and curated_zone models.

## Test Categories

### 1. Landing Zone Model Tests
- **test_landing_zone_incidents.sql**: Data quality and business rules for incidents table
- **test_landing_zone_users.sql**: User data validation and email format checks
- **test_landing_zone_comment_history.sql**: Comment data integrity and referential validation
- **test_landing_zone_attachments.sql**: Attachment data validation and consistency checks

### 2. Curated Zone View Tests
- **test_curated_zone_active_incidents.sql**: Active incidents view validation
- **test_curated_zone_category_performance.sql**: Category performance metrics validation
- **test_curated_zone_high_impact.sql**: High impact incidents logic validation
- **test_curated_zone_incident_overview.sql**: Comprehensive incident overview validation
- **test_curated_zone_trends.sql**: Monthly and weekly trends validation

### 3. Cross-Model Data Quality Tests
- **test_data_quality_cross_model.sql**: Referential integrity across models and data consistency

### 4. Business Logic Validation Tests
- **test_business_logic_validation.sql**: Business rules, SLA compliance, and process validation

### 5. Schema-Based Tests
- **test_schema_models.yml**: dbt schema tests with column-level and table-level validations

## Running Tests

### Run All Tests
```bash
dbt test
```

### Run Tests by Category
```bash
# Run only landing zone tests
dbt test --select "test_landing_zone*"

# Run only curated zone tests
dbt test --select "test_curated_zone*"

# Run cross-model tests
dbt test --select "test_data_quality_cross_model"

# Run business logic tests
dbt test --select "test_business_logic_validation"
```

### Run Tests for Specific Models
```bash
# Test specific model
dbt test --select "incidents"

# Test model and its children
dbt test --select "incidents+"

# Test model and its parents
dbt test --select "+incidents"
```

## Test Coverage

### Data Quality Tests
- ✅ Unique constraints
- ✅ Not null constraints
- ✅ Data type validation
- ✅ Range validations (non-negative values)
- ✅ Format validations (email format)
- ✅ Referential integrity

### Business Logic Tests
- ✅ SLA compliance rules
- ✅ Incident status progression
- ✅ Priority and impact alignment
- ✅ Timeline consistency
- ✅ Process validation
- ✅ Category classification

### Performance Tests
- ✅ Calculation accuracy
- ✅ Aggregation consistency
- ✅ Trend analysis validation
- ✅ Business impact scoring

### Cross-Model Tests
- ✅ Foreign key relationships
- ✅ Data consistency across zones
- ✅ Count reconciliation
- ✅ Orphaned record detection

## Test Failure Handling

When tests fail:

1. **Review the failing test**: Understand what business rule or data quality check failed
2. **Investigate root cause**: Check the underlying data or model logic
3. **Fix the issue**: Either fix the data, update the model, or adjust the test if the rule changed
4. **Re-run tests**: Ensure the fix resolves the issue

## Adding New Tests

To add new tests:

1. **Custom SQL tests**: Create new `.sql` files in the `tests/` directory
2. **Schema tests**: Add tests to `test_schema_models.yml` or the main `schema.yml`
3. **Model-specific tests**: Add tests directly in model configurations

## Test Maintenance

- Review and update tests when business rules change
- Add new tests for new models or columns
- Monitor test performance and optimize slow tests
- Document any test exceptions or known issues
