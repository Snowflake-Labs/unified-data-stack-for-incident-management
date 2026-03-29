use role <% ctx.env.dbt_project_admin_role %>;
use database <% ctx.env.dbt_project_database %>;
use schema <% ctx.env.dbt_project_database %>.dbt_project_deployments;

-- Fetch latest code from Git
ALTER GIT REPOSITORY <% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo FETCH;

-- Redeploy the dbt project with a new version from the updated Git repo
ALTER DBT PROJECT <% ctx.env.dbt_project_database %>.dbt_project_deployments.<% ctx.env.dbt_project_name %>
  ADD VERSION
  FROM '@<% ctx.env.dbt_project_database %>.dbt_project_deployments.project_git_repo/branches/<% ctx.env.git_branch %>/src/incident_management';