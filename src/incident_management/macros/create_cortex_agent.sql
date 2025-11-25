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
    COMMENT = $$
    This is a Cortex Agent that can be used to answer a variety of questions about the incident management process.
    It has access to different tools to help it answer the questions. 
    It can use hybrid search to answer questions about the incident management process from the unstructured incident documentation like policy documents, runbooks, and best practices etc.
    It can also use the a semantic view to query structured data including incident details, metrics, trends, and quaterly review metrics etc.
    $$
    PROFILE = '{"display_name": "Incident Management 360", "avatar": "Agent", "color": "green"}'
    FROM SPECIFICATION
    $$
    {{ agent_spec['data'][0][0] | indent(4) }}
    $$;
{% endset %}

{% do run_query(cortex_agent_ddl) %}

{% endmacro %}
