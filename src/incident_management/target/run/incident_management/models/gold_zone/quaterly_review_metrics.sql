
  
    

        create or replace transient table incident_management.gold_zone.quaterly_review_metrics
         as
        (

select
  dq.relative_path,
  dq.question_extracts_json:quaterly_review_metrics:quarter::string as quarter,
  -- Service Operational Health
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:overall_uptime::number as soh_overall_uptime,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:critical_services_uptime::number as soh_critical_uptime,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:sev_1_incidents::number as soh_sev1_incidents,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:sev_2_incidents::number as soh_sev2_incidents,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:mtta::number as soh_mtta,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:mttr::number as soh_mttr,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:change_failure_rate::number as soh_cfr,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:slo_breaches::number as soh_slo_breaches,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:error_budget_consumed::number as soh_error_budget,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:service_downtime::number as soh_downtime,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:unplanned_outage_hours::number as soh_unplanned_outage_hours,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:planned_maintenance_hours::number as soh_planned_maintenance_hours,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:sev_1_outage_minutes::number as soh_sev1_outage_minutes,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:sev_2_outage_minutes::number as soh_sev2_outage_minutes,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:longest_single_outage::number as soh_longest_outage,
  dq.question_extracts_json:quaterly_review_metrics:service_operational_health:mtbft::number as soh_mtbft,
  -- Team Utilisation
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:end_of_quarter_it_headcount::number as tu_eoq_it_headcount,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:engineering_headcount::number as tu_eng_headcount,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:on_call_coverage::number as tu_on_call_coverage,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:project_work_allocation::number as tu_project_work_alloc,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:bau_operations_allocation::number as tu_bau_ops_alloc,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:on_call_hours_per_engineer::number as tu_on_call_hours_per_eng,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:after_hours_incidents_handled::number as tu_after_hours_incidents,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:training_hours_per_fte::number as tu_training_hours_per_fte,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:certifications_earned::number as tu_certifications,
  dq.question_extracts_json:quaterly_review_metrics:team_utilisation:attrition::number as tu_attrition,
  -- Tool Licensing Spend
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:atlassian_spend::number as tls_atlassian,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:github_spend::number as tls_github,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:slack_spend::number as tls_slack,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:pagerduty_spend::number as tls_pagerduty,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:datadog_spend::number as tls_datadog,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:sentry_spend::number as tls_sentry,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:okta_spend::number as tls_okta,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:aws_spend::number as tls_aws,
  dq.question_extracts_json:quaterly_review_metrics:tool_licensing_spend:total_spend::number as tls_total
from incident_management.bronze_zone.document_question_extracts dq
        );
      
  