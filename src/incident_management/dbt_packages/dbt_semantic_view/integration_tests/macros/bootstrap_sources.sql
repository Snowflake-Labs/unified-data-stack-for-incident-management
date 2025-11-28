-- Copyright 2025 Snowflake Inc. 
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

{% macro create_base_table2() %}
  {% set sql %}
    create or replace table {{ target.database }}.{{ target.schema }}.BASE_TABLE2 as
    SELECT
        1 AS id,
        200 AS value
    UNION ALL
    SELECT
        2 AS id,
        300 AS value
    UNION ALL
    SELECT
        3 AS id,
        400 AS value;
  {% endset %}
  {% do run_query(sql) %}
{% endmacro %}

{% macro create_raw_semantic_view() %}
  {% set sql %}
    create or replace semantic view {{ target.database }}.{{ target.schema }}.RAW_SEMANTIC_VIEW
    tables (t1 as {{ target.database }}.{{ target.schema }}.BASE_TABLE2)
    dimensions (t1.count as value)
    metrics (t1.total_rows as sum(t1.value))
  {% endset %}
  {% do run_query(sql) %}
{% endmacro %}