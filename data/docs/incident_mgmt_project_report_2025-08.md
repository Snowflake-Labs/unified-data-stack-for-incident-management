## Incident Management Project Report — August 2025

### Executive summary
August showed steady reliability with a modest reduction in critical incidents and improved response times. MTTA improved to 6 minutes and MTTR to 2h 40m. SLA breaches trended down (5.2%). Primary drivers were code regressions and routine infrastructure maintenance side-effects. Remediations prioritized deployment safeguards and runbook hardening.

### Key metrics
- **Incidents opened**: 124
- **Incidents closed**: 121
- **Severity mix**: P1: 3, P2: 12, P3: 54, P4: 55
- **MTTA**: 6 minutes
- **MTTR (overall)**: 2 hours 40 minutes (160 minutes)
- **MTTR (P1)**: 48 minutes
- **SLA breach rate**: 5.2%
- **Reopen rate**: 3.7%
- **Change failure rate**: 18%
- **Postmortems completed within 7 days**: 92%
- **Customer-visible incidents**: 31
- **On-call pages**: 286 (9.2/day)

### Trends and observations
- Reduced P1s vs prior month; P2 volume stable.
- MTTR down ~9% driven by improved triage of noisy alerts.
- SLA breaches concentrated in long-running P3 investigations tied to data pipeline lag.

### Notable incidents
- 2025-08-05 — Elevated 500s on API v2 (P2): Canary missed edge-case; hotfix within 2h.
- 2025-08-14 — Delayed invoices generation (P2): Downstream queue congestion; added rate shaping.
- 2025-08-26 — Search partial outage in EU (P1): Misconfigured feature flag scope; rollback in 41m.

### Root cause distribution (opened = 124)
- Code change regressions: 55
- Infrastructure faults: 27
- Third-party/SaaS dependencies: 15
- Data quality/latency: 11
- Configuration errors: 9
- Abuse/traffic anomalies: 4
- Unknown/other: 3

### Actions completed
- Enabled deployment guardrails: mandatory canary + automated rollback criteria.
- Hardened runbooks for data pipeline backpressure with step-by-step verification.
- Tuned alert thresholds to reduce duplicate paging in off-peak hours.
- Added aggressive cache TTLs for EU search during degraded mode.
- Instituted postmortem office hours to raise completion from 88% to 92%.

### Risks and blockers
- Aging Kafka cluster segment on legacy infra raises recovery RTO risk.
- Limited observability on billing batch windows complicates SLO measurement.

### Focus for September
- Finish Kafka upgrade (partition rebalancing + ISR tuning).
- Expand synthetic monitoring for billing & search critical paths.
- Pilot incident commander rotation shadowing for new responders.

### Budget and tooling notes
- Approved spend for log storage tiering; projected 18% cost reduction.
- Evaluating error budget burn alerts in addition to static SLO alerts.

### Headcount and staffing
- 10 primary responders, 6 secondary; onboarding 2 new hires in September.
