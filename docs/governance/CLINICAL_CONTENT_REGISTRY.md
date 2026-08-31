# Harbor Clinical Content Registry

**Version:** 0.1 draft

**Catalog version:** `2026.08.31-source-draft.2`

**Updated:** 2026-08-31
**Release status:** Not approved for clinical release

This registry controls every health-information entry shipped in Harbor. Content may be implemented and tested before release, but it cannot pass the clinical-content release gate until a qualified postpartum clinician and a pediatric clinician have reviewed the applicable entries, requested corrections are resolved, and the approval fields below are signed and dated.

Harbor is educational support, not diagnosis, triage, monitoring, or a substitute for professional care. “Common” does not mean a woman must tolerate a symptom or delay asking for help. The app must always permit the user to contact her own clinician, and emergency content must provide a direct handoff rather than a self-assessment score.

## Controlled source set

| Source ID | Publisher and page | Scope used in Harbor | Source state | Harbor review due |
|---|---|---|---|---|
| ACOG-PP-PAIN-2025 | [ACOG — Postpartum Pain Management](https://www.acog.org/womens-health/faqs/postpartum-pain-management) | Common postpartum recovery experiences and emergency warning signs | Accessed 2026-08-30 | Before clinical release and every 6 months |
| ACOG-PP-HEMORRHAGE-2022 | [ACOG — Conditions to Watch for After Childbirth](https://www.acog.org/womens-health/infographics/conditions-to-watch-for-after-childbirth) | Heavy bleeding and urgent postpartum warning signs | Accessed 2026-08-30 | Before clinical release and every 6 months |
| ACOG-PP-PREECLAMPSIA-2022 | [ACOG — Conditions to Watch for After Childbirth](https://www.acog.org/womens-health/infographics/conditions-to-watch-for-after-childbirth) | Severe headache, visual symptoms, swelling, and abdominal pain | Accessed 2026-08-30 | Before clinical release and every 6 months |
| ACOG-PP-ENDOMETRITIS-2026 | [ACOG — 3 Conditions to Watch for After Childbirth](https://www.acog.org/womens-health/experts-and-stories/the-latest/3-conditions-to-watch-for-after-childbirth) | Fever, chills, abdominal tenderness, and foul-smelling discharge requiring prompt postpartum care | Accessed 2026-08-31 | Before clinical release and every 6 months |
| ACOG-PPD-2025 | [ACOG — Postpartum Depression](https://www.acog.org/womens-health/faqs/postpartum-depression) | Baby blues, postpartum depression, first-year timing, when to contact a professional | Source says reviewed December 2025; accessed 2026-08-30 | Before clinical release and every 6 months |
| NIMH-PERINATAL-DEPRESSION-2026 | [National Institute of Mental Health — Perinatal Depression](https://www.nimh.nih.gov/health/publications/perinatal-depression) | Postpartum psychosis symptoms and immediate 911/emergency-room handoff | Accessed 2026-08-31 | Before clinical release and every 6 months |
| AAP-NEWBORN-ILLNESS | [American Academy of Pediatrics — Newborn Illness: How Can I Find Out?](https://www.healthychildren.org/English/ages-stages/baby/Pages/Newborn-Illness-How-Can-I-Find-Out.aspx) | Feeding change, unusual behavior, breathing difficulty, color change, weakness, and wakefulness | Accessed 2026-08-30 | Before clinical release and every 6 months |
| AAP-INFANT-FEVER-2025 | [American Academy of Pediatrics — Fever and Your Baby](https://www.healthychildren.org/English/health-issues/conditions/fever/Pages/Fever-and-Your-Baby.aspx) | Temperature threshold and immediate evaluation for babies younger than three months | Accessed 2026-08-30 | Before clinical release and every 6 months |
| AAP-JAUNDICE-2024 | [American Academy of Pediatrics — Jaundice in Newborns](https://www.healthychildren.org/English/ages-stages/baby/Pages/Jaundice.aspx) | Jaundice warning signs, clinician contact, and sunlight warning | Source says updated August 2024; accessed 2026-08-30 | Before clinical release and every 6 months |
| 988-US | [988 Suicide & Crisis Lifeline — What to Expect](https://988lifeline.org/get-help/what-to-expect/) | U.S. crisis call/text handoff | Accessed 2026-08-30 | Before each release and every 3 months |

## Implemented content inventory

| Harbor entry ID | Audience | Severity | Source ID | Clinical approval |
|---|---|---|---|---|
| woman-recovery-early | Woman | Learn / ask freely | ACOG-PP-PAIN-2025 | Pending |
| woman-heavy-bleeding | Woman | Contact clinician now | ACOG-PP-HEMORRHAGE-2022 | Pending |
| woman-headache-vision | Woman | Contact clinician now | ACOG-PP-PREECLAMPSIA-2022 | Pending |
| woman-postpartum-infection | Woman | Get medical care right away | ACOG-PP-ENDOMETRITIS-2026 | Pending |
| woman-postpartum-psychosis | Woman | Emergency | NIMH-PERINATAL-DEPRESSION-2026 | Pending |
| woman-emergency | Woman | Emergency | ACOG-PP-PAIN-2025 | Pending |
| woman-baby-blues | Woman | Learn / contact if concerned | ACOG-PPD-2025 | Pending |
| woman-mood-anytime | Woman | Contact clinician | ACOG-PPD-2025 | Pending |
| baby-feeding-change | Baby | Contact clinician now | AAP-NEWBORN-ILLNESS | Pending |
| baby-fever | Baby | Immediate medical care | AAP-INFANT-FEVER-2025 | Pending |
| baby-breathing | Baby | Emergency | AAP-NEWBORN-ILLNESS | Pending |
| baby-jaundice | Baby | Contact clinician | AAP-JAUNDICE-2024 | Pending |

## Required approvals

| Review | Reviewer | Credential / organization | Date | Decision |
|---|---|---|---|---|
| Postpartum and perinatal mental-health content | Unassigned | Must be qualified for the intended release jurisdiction | — | Pending |
| Newborn and infant content | Unassigned | Must be qualified for the intended release jurisdiction | — | Pending |
| Crisis and emergency handoffs | Unassigned | Clinical safety lead plus jurisdictional review | — | Pending |
| Plain-language and feminist-language review | Unassigned | Women-led lived-experience panel; compensated | — | Pending |

## Change control

1. Each app entry must retain a unique ID and a source ID from this registry.
2. A source change, threshold change, severity change, or action change requires clinical re-review.
3. Automated tests must reject missing IDs, missing source metadata, unsupported stages, and emergency entries without an immediate handoff.
4. A scheduled source review must check for updated guidance, retired URLs, jurisdiction changes, and crisis-line changes.
5. Expired or disputed content must be removed from the release build or clearly disabled; silence is not approval.
6. Harbor must not make probabilistic diagnoses, tell a woman she is “fine,” or suppress access to professional care.

## Current gate result

**Fail — release-blocking.** The initial source-backed content and automated structural tests exist, but no qualified clinical or lived-experience reviewers have approved it. This is truthful enabling work, not completed clinical validation.
