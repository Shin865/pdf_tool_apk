# Spike A — Office Engine Evaluation

## Status: 🔲 Not started (Phase 1)

## Objective
Evaluate whether a full office engine (LibreOffice/Collabora or Java/Kotlin
DOCX/XLSX libraries) can be embedded into the Flutter app without a server
or external apps.

## Pass/Fail Criteria (written BEFORE coding)
| Metric | Pass | Fail |
|---|---|---|
| APK size delta | < 50 MB | ≥ 50 MB |
| DOCX open time (10-page) | < 3 s | ≥ 3 s |
| Peak RAM usage | < 200 MB | ≥ 200 MB |
| Save quality (validate in Word/LibreOffice) | No corruption | Any corruption |
| Build complexity | Automated via Gradle | Manual steps required |
| License | Apache-2.0 / MIT | GPL / AGPL |

## Candidates
- [ ] Collabora Online (LOKit) — MPL-2.0, full fidelity, large (~40 MB)
- [ ] Apache POI (Java) — Apache-2.0, DOCX/XLSX read+write, no render
- [ ] docx4j — Apache-2.0, DOCX only, moderate fidelity
- [ ] Custom Kotlin XML parser — MIT, limited fidelity, small size

## Procedure (to be executed)
1. Create `spikes/spike_a_office/` as a minimal Flutter + Android app
2. Integrate each candidate one at a time
3. Measure each metric with real test files
4. Document results in this file

## Results
> 🔲 Not yet executed.

## Recommendation
> 🔲 Pending spike execution.

## Plan B
Read-only viewer + Export to PDF (using a permissive PDF library).

