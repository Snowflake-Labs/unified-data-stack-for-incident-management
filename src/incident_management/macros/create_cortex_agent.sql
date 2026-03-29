{% macro create_cortex_agent(agent_name, database, schema, stage_name, agent_spec_file) %}

{% call statement('agent_spec_builder', fetch_result=True) %}
    EXECUTE IMMEDIATE $$
    BEGIN
        LET scoped_file_path STRING := BUILD_SCOPED_FILE_URL(@{{ database }}.{{ schema }}.{{ stage_name }}, '{{ agent_spec_file }}');
        LET agent_spec STRING := {{database}}.dbt_project_deployments.READ_STAGE_FILE(:scoped_file_path);
    
        RETURN agent_spec;           
    END;
    $$;
{% endcall %}

{%- set agent_spec = load_result('agent_spec_builder') -%}

{% call statement('agent_exists', fetch_result=True) %}
   EXECUTE IMMEDIATE $$
    DECLARE
        agent_name VARCHAR := '';
        agent_exists BOOLEAN DEFAULT FALSE;
    BEGIN
        SHOW AGENTS LIKE '{{agent_name}}';
        agent_name := (SELECT "name" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE contains("name", '{{agent_name}}'));
        RETURN (agent_name IS NOT NULL AND agent_name != '' AND agent_name ='{{agent_name}}');
    END;
    $$;
{% endcall %}

{%- set agent_exists = load_result('agent_exists') -%}

{% set cortex_agent_ddl %}
    {% if agent_exists is none or agent_exists['data'][0][0] is false %}
        CREATE OR REPLACE AGENT {{ target.database }}.{{schema}}.{{ agent_name }}
        COMMENT = $${'spec_file_name': '{{agent_spec_file}}'}$$
        PROFILE = '{"display_name": "Agent assisted Incident Management", "color": "green"}'
        FROM SPECIFICATION
        $$
        {{ agent_spec['data'][0][0] }}
        $$;

        ALTER SNOWFLAKE INTELLIGENCE {{var('snowflake_intelligence_object')}} ADD AGENT {{ target.database }}.{{schema}}.{{ agent_name }};
    {% else %}
        ALTER AGENT {{ target.database }}.{{schema}}.{{ agent_name }} 
        SET COMMENT = $${'spec_file_name': '{{agent_spec_file}}'}$$;
        
        ALTER AGENT {{ target.database }}.{{schema}}.{{ agent_name }} 
        MODIFY LIVE VERSION SET SPECIFICATION = 
        $$
        {{ agent_spec['data'][0][0] }}
        $$;
    {% endif %}
{% endset %}

{% do run_query(cortex_agent_ddl) %}

{% endmacro %}
