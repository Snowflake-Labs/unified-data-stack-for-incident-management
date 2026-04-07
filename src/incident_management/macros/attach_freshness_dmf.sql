{% macro attach_freshness_dmf(schedule='TRIGGER_ON_CHANGES') %}

    {# Attaches Snowflake system FRESHNESS DMF to the current model's table. #}

    {% set fqn = this.database ~ '.' ~ this.schema ~ '.' ~ this.identifier %}

    {# Step 1: Set the metric schedule on the table #}
    {% set schedule_sql %}
        ALTER TABLE {{ fqn }}
            SET DATA_METRIC_SCHEDULE = '{{ schedule }}';
    {% endset %}
    {% do run_query(schedule_sql) %}

    {# Step 2: Attach each requested DMF #}
    {% for dmf_name in dmfs %}
        {% set attach_sql %}
            ALTER TABLE {{ fqn }}
                ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.FRESHNESS
                ON ();
        {% endset %}

        {% do run_query(attach_sql) %}
    {% endfor %}

{% endmacro %}