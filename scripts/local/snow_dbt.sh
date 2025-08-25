#! /usr/bin/env bash

source  ../environment_variables.env

## Refresh local Git repo for the dbt Project where


## Deploy the dbt project to Snowflake

### If new dbt project
snow dbt deploy jaffle_shop --force --source /path/to/dbt/directory --profiles-dir ~/.dbt/

### Else if refresh an existing dbt project
snow dbt deploy jaffle_shop --source /path/to/dbt/directory --profiles-dir ~/.dbt/