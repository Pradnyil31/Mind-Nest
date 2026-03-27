# MindNest — Research & Academic Notes

This document contains the academic framing, evaluation guidance, and paper-ready content for the MindNest project. Moved here from README.md to keep the main README clean and developer-friendly.

---

## Research Abstract (Project Framing)

MindNest addresses a common gap in digital wellness tools: many apps provide isolated features (journal, breathing, timers), but few provide a unified personalized workflow with measurable daily activity tracking.  
The system combines onboarding-derived personalization, structured routine execution, and activity analytics in a single cross-platform mobile architecture.  
The implementation emphasizes practical deployability (Flutter + Firebase), user-level data isolation (rules-based ownership), and reproducible engineering workflows for academic reporting.

## Problem Statement

Students and early professionals often struggle to maintain consistent wellness habits due to:
- fragmented tools
- low personalization
- weak progress visibility

MindNest aims to provide a single adaptive workflow from onboarding to daily completion tracking and insights.

## Technical Contributions

The codebase currently supports the following defensible technical contributions:
- Cross-platform Flutter wellness app with multi-feature integration.
- Personalized routine flow based on onboarding profile and user motive.
- Activity event persistence and user-scoped analytics via Firestore.
- Owner-only Firestore and Storage access model with immutable ownership checks.
- Local on-device AI chat integration path using runtime configuration.
- Quality gate scripts for analyzer/tests/rules checks to improve reproducibility.

## Quality Gates (For Paper Appendix / Viva Defense)

Run local verification:

```bash
./tools/quality_gate.sh
./tools/firestore_rules_test.sh
```

PowerShell equivalents:
- `tools/quality_gate.ps1`
- `tools/firestore_rules_test.ps1`

Reference:
- `.github/workflows/flutter-quality-gate.yml`
- `docs/QUALITY_GATES.md`

## Evaluation Plan for Research Paper

Recommended metrics to report:
- Feature action latency: p50/p95 (auth, check-in save, routine completion, journal save).
- Firestore operations per user session (read/write count).
- Crash-free sessions.
- Completion adherence (daily/weekly routine completion rate).
- Retention proxy (streak continuity distribution).
- AI chat fallback/error rate (if included in study).

Recommended tables/figures:
- Feature-to-architecture mapping table.
- Latency chart by feature flow.
- Cost estimate table (Firestore reads/writes per DAU scenario).
- User flow completion funnel.

## Scope, Claims, and Limitations

### Claims supported by current implementation
- Feature-rich cross-platform prototype for mental wellness workflows.
- Personalized routine support with tracked activity analytics.
- Rule-based user data isolation model in Firebase.

### Claims not supported yet (avoid in paper)
- Clinical efficacy or therapeutic outcome claims.
- Large-scale production readiness without further load/security validation.
- Medical-grade intervention performance.

### Known limitations
- Limited large-scale performance benchmarking.
- Limited longitudinal user-study evidence.
- Some advanced hardening is still incremental.

## Ethics and Privacy Notes

- No clinical diagnosis claims are made by the system.
- User-generated wellness content should be handled as sensitive data.
- Any study publication should include informed consent and anonymization process.
- Crisis support behavior should not be represented as professional medical care.

## Paper-Ready Checklist

Before final submission/demo, complete:
- Final analyzer/test/rules pass with archived outputs.
- Updated architecture diagram and sanitized DB/rules screenshots.
- Metric table population from real runs.
- Limitation and threats-to-validity sections aligned with actual evidence.

Reference: `docs/publication_readiness_playbook.md`

## Citation (Template)

```bibtex
@software{mindnest2026,
  title  = {MindNest: A Cross-Platform Mental Wellness App with Personalized Routines and Activity Analytics},
  author = {Pradnyil Patil},
  year   = {2026},
  note   = {Flutter/Firebase-based research prototype},
  url    = {https://github.com/Pradnyil31/Mind-Nest}
}
```
