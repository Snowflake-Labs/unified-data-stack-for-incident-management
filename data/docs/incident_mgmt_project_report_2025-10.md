## Incident Management Project Report — October 2025

### Executive summary
October marked the third consecutive month of improvement. Incidents decreased to 109 with just one P1. MTTA improved to 4 minutes, MTTR to 1h 58m. SLA breaches dropped to 3.4%. Focus shifted to failover readiness and sustained reliability operations.

### Key metrics
- **Incidents opened**: 109
- **Incidents closed**: 108
- **Severity mix**: P1: 1, P2: 9, P3: 47, P4: 52
- **MTTA**: 4 minutes
- **MTTR (overall)**: 1 hour 58 minutes (118 minutes)
- **MTTR (P1)**: 41 minutes
- **SLA breach rate**: 3.4%
- **Reopen rate**: 2.6%
- **Change failure rate**: 13%
- **Postmortems completed within 7 days**: 100%
- **Customer-visible incidents**: 22
- **On-call pages**: 246 (7.9/day)

### Trends and observations
- Improved resilience due to regional readiness work and circuit breakers.
- Further drop in code-related regressions with stricter pre-merge checks.

### Notable incidents
- 2025-10-07 — EU auth latency spike (P2): BGP route change; traffic shifted, latency normalized.
- 2025-10-19 — Cache stampede on catalog (P3): Introduced request coalescing; reduced thundering herd.

### Root cause distribution (opened = 109)
- Code change regressions: 40
- Infrastructure faults: 22
- Third-party/SaaS dependencies: 12
- Data quality/latency: 12
- Configuration errors: 8
- Abuse/traffic anomalies: 4
- Unknown/other: 11

### Actions completed
- Executed auth and search regional failover game days; documented gaps and fixes.
- Implemented request coalescing and cache TTL smoothing on catalog.
- Automated creation and owner assignment of postmortem action items.
- Rolled out alert deduplication pipeline v2; reduced pages by ~6%.

### Risks and blockers
- Unknown root causes cluster around edge-case request flows; needs deeper trace coverage.

### Focus for November
- Expand tracing coverage for low-frequency, high-latency paths.
- Continue reducing change failure rate via targeted test flake elimination.
- Introduce error budget burn alerts into weekly ops review.

### Budget and tooling notes
- Achieved 19% storage savings from log tiering vs July baseline.

### Headcount and staffing
- 12 primary responders; onboarding complete for 2 new hires.
