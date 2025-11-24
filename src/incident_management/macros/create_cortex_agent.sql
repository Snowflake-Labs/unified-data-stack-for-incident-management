{% macro create_cortex_agent(agent_name, stage_name, spec_file, agent_profile) %}

{% set sql %}
    EXECUTE IMMEDIATE $$
        BEGIN
            LET scoped_file_path STRING := BUILD_SCOPED_FILE_URL(@{{ stage_name }}, '{{ spec_file }}');
            LET agent_spec STRING := INCIDENT_MANAGEMENT.DBT_PROJECT_DEPLOYMENTS.READ_STAGE_FILE(:scoped_file_path);

            CREATE OR REPLACE AGENT {{ target.database }}.GOLD_ZONE.{{ agent_name }}
            PROFILE = '{"display_name": "Incident Management 360", "avatar": "Agent", "color": "green"}'
            FROM SPECIFICATION
            ':agent_spec';
        END;
    $$
    ;
{% endset %}

{% do run_query(sql) %}

{% endmacro %}
