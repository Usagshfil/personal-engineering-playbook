# Incident Post-Mortem: [Incident Title]

> **Incident ID**: INC-[Number]  
> **Date of Incident**: [YYYY-MM-DD]  
> **Severity**: `SEV-1 (Critical Outage)` / `SEV-2 (Major Impairment)` / `SEV-3 (Minor Degradation)`  
> **Incident Commander**: [Lead Engineer]  
> **Author**: [Investigating Engineer]  
> **Status**: Resolved / Post-Mortem In Review / Closed  

---

## 1. Executive Summary

*Briefly describe what happened, the duration of user impact, the root cause, and the resolution.*

| Timeline Metric | Timestamp (UTC) | Duration |
| :--- | :---: | :---: |
| **Outage Start Time** | [YYYY-MM-DDTHH:mm:ssZ] | - |
| **Detection Time** | [YYYY-MM-DDTHH:mm:ssZ] | Time to Detect (TTD): [X mins] |
| **Mitigation / Recovery Time**| [YYYY-MM-DDTHH:mm:ssZ] | Time to Mitigate (TTM): [X mins] |
| **Total Incident Duration** | - | [X hours, Y mins] |

---

## 2. Customer & Business Impact

* **Users Impacted**: [e.g. Approximately 450 mobile users (3.2% of active users)]
* **Transaction Failures**: [e.g. 28 checkout attempts failed with 500 error]
* **Data Loss or Corruption**: [None / Details of affected records]

---

## 3. Chronological Timeline of Events (UTC)

* **14:02** — Alert `HighErrorRate` fired from API Gateway.
* **14:05** — On-call engineer acknowledged page and began triage.
* **14:12** — Traces revealed PostgreSQL connection pool exhaustion on `orders` table.
* **14:20** — Identified unindexed query introduced in migration commit `abc1234`.
* **14:32** — Rolled back deployment to previous image tag `v1.1.4`.
* **14:38** — Error rates returned to 0.02% baseline; pool saturation cleared.

---

## 4. Root Cause Analysis (The 5 Whys)

1. **Why did the API return 500 errors?**  
   Because backend worker threads timed out waiting for database connections from the pool.
2. **Why was the connection pool exhausted?**  
   Because database queries on the `orders` table were taking $> 4.5\text{s}$ instead of $< 20\text{ms}$.
3. **Why were queries taking 4.5 seconds?**  
   Because PostgreSQL was performing a full sequential scan (`Seq Scan`) across 2.4 million rows.
4. **Why did it perform a sequential scan?**  
   Because the new status filter query did not match the Left-to-Right prefix rule of the existing composite index.
5. **Why was this not caught before production?**  
   Because staging environment only contained 50 mock rows, where sequential scan latency was undetectable.

---

## 5. Corrective & Preventive Action Items

| Action Item | Category | Assignee | Target Date | Tracking Ticket |
| :--- | :---: | :---: | :---: | :---: |
| Add composite index `idx_orders_status_created` | Fix | [Dev Name] | Immediate | PR #104 |
| Populate staging database with representative volume ($100\text{k}+$ rows) | Prevention | [QA Name] | Next Sprint | TICKET-201 |
| Add CI check enforcing query `EXPLAIN` analysis for new SQL queries | Prevention | [SRE Name] | Q4 | TICKET-202 |

---

## 6. Lessons Learned

* **What Went Well**: Rapid detection via automated gateway alerts; rollback completed in $< 15\text{mins}$.
* **What Could Be Improved**: Staging dataset lacked realistic row volume; query timeout default was too generous.
