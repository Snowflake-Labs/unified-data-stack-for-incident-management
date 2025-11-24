{% macro create_cortex_agent(agent_name, stage_name, spec_file, agent_profile) %}

{% call statement('agent_spec_builder', fetch_result=True) %}
    EXECUTE IMMEDIATE $$
    BEGIN
        LET scoped_file_path STRING := BUILD_SCOPED_FILE_URL(@{{ stage_name }}, '{{ spec_file }}');
        LET agent_spec STRING := INCIDENT_MANAGEMENT.DBT_PROJECT_DEPLOYMENTS.READ_STAGE_FILE(:scoped_file_path);
    
        RETURN agent_spec;           
    END;
    $$;
{% endcall %}

{%- set agent_spec = load_result('agent_spec_builder') -%}

{% set cortex_agent_ddl %}
    CREATE OR REPLACE AGENT {{ target.database }}.GOLD_ZONE.{{ agent_name }}
    PROFILE = '{"display_name": "Incident Management 360", "avatar": "Agent", "color": "green"}'
    FROM SPECIFICATION
    $$
    {{ agent_spec['data'][0][0] }}
    $$;
{% endset %}

{% do run_query(cortex_agent_ddl) %}

{% endmacro %}
