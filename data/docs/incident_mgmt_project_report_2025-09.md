## Incident Management Project Report — September 2025

### Executive summary
September continued improvement trends. Incidents fell to 117 with lower severity mix and faster response. SLA breaches dropped to 4.1%. Completion of several reliability epics (Kafka upgrade, better canarying) reduced code- and infra-driven incidents.

### Key metrics
- **Incidents opened**: 117
- **Incidents closed**: 114
- **Severity mix**: P1: 2, P2: 10, P3: 51, P4: 54
- **MTTA**: 5 minutes
- **MTTR (overall)**: 2 hours 22 minutes (142 minutes)
- **MTTR (P1)**: 44 minutes
- **SLA breach rate**: 4.1%
- **Reopen rate**: 3.2%
- **Change failure rate**: 15%
- **Postmortors completed within 7 days**: 96%
- **Customer-visible incidents**: 27
- **On-call pages**: 261 (8.7/day)

### Trends and observations
- Sustained reduction in code regression incidents after rollout of guardrails.
- Better queue tuning cut data-latency incidents by ~9%.
- P1s remained rare with faster containment.

### Notable incidents
- 2025-09-09 — OAuth provider timeouts (P2): Third-party rate-limiting; added retry jitter + fallback route.
- 2025-09-18 — Metrics ingestion lag (P3): Mis-sized consumers; horizontal scale restored in 90m.

### Root cause distribution (opened = 117)
- Code change regressions: 47
- Infrastructure faults: 25
- Third-party/SaaS dependencies: 14
- Data quality/latency: 12
- Configuration errors: 8
- Abuse/traffic anomalies: 5
- Unknown/other: 6

### Actions completed
- Completed Kafka upgrade and ISR tuning, reducing consumer lag tail by 28%.
- Deployed circuit breakers for OAuth failures with exponential backoff.
- Expanded synthetic probes to cover billing happy-path and error-path.
- Finalized incident commander playbook and shadowing checklist.

### Risks and blockers
- Single-region dependency for search embeddings remains a blast-radius concern.

### Focus for October
- Regional failover exercises for search & auth paths.
- Alert dedup pipeline improvements to drop noisy flaps.
- Postmortem automation for action item tracking.

### Budget and tooling notes
- Observability spend trending down 11% MoM via storage tiering.

### Headcount and staffing
- 12 primary responders; rotating 2 senior ICs into mentorship track.
