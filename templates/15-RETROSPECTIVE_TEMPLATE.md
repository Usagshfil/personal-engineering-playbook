# Milestone / Sprint Retrospective: [Milestone Name]

> **Date**: [YYYY-MM-DD]  
> **Facilitator**: [Team Lead / Scrum Master]  
> **Participants**: [Engineering Team Members]  
> **Milestone Delivered**: [Milestone Number / Release Tag]  

---

## 1. Milestone Goals & Delivery Assessment

* **Planned Commitments**: [List of planned features or user stories]
* **Delivered Outcomes**: [List of completed and verified capabilities]
* **Spillover / Deferred Items**: [Items not completed and reason for deferral]

---

## 2. What Went Exceptionally Well? 🌟

* *Engineering Excellence*: [e.g. Risk-Based Testing caught 3 critical concurrency bugs before QA]
* *Process & Speed*: [e.g. Clear Technical Design Document accelerated implementation by 2 days]
* *Collaboration & AI Pairing*: [e.g. Systematic planning prompts prevented AI hallucinated code]

---

## 3. What Went Wrong or Caused Friction? ⚠️

* *Friction 1*: [e.g. Unclear requirements around tax rounding caused rework in the calculation service]
* *Friction 2*: [e.g. Local developer environment differed from CI runner due to missing tool in PATH]
* *Friction 3*: [e.g. PR reviews took $> 24\text{h}$ on average due to oversized diffs]

---

## 4. Key Learnings & Insights 💡

1. [Learning 1: e.g. Always define statutory financial rounding rules upfront in the Requirements Spec]
2. [Learning 2: e.g. Keep pull requests under 400 lines of code to maintain review velocity]

---

## 5. Concrete Action Items for Next Milestone 🎯

| Action Item | Specific Ownership | Success Metric / Verification |
| :--- | :---: | :--- |
| **Enforce PR size limits** | Entire Team | No PR $> 400$ LOC without lead architect approval |
| **Add staging volume generator** | QA Lead | Staging seeded with $50\text{k}$ orders prior to testing |
| **Update ADR for rounding policy**| Tech Lead | ADR-0004 merged into `docs/adr/` |
