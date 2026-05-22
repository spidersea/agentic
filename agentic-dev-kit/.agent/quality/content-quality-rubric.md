# Content Quality Rubric

Content quality is a delivery surface, not a polish afterthought. Apply this rubric to UI copy, docs, onboarding, error states, empty states, labels, tables, generated text, and user-facing data explanations.

## Rubric

| Dimension | PASS Criteria | Failure Examples |
|---|---|---|
| Completeness | The user has enough information to complete the task. | Missing next step, unexplained state, absent success/failure feedback. |
| Accuracy | Text matches actual behavior, data, permissions, and limits. | Button says "Save" but performs publish; stale limits; wrong status. |
| Specificity | Errors and empty states name the concrete problem and recovery path. | "Something went wrong" with no action. |
| Scannability | Labels, headings, and summaries are short and structured for repeated use. | Dense paragraphs in operational UI. |
| Edge States | Loading, empty, failure, permission, and long-content states are covered. | Blank panel, clipped label, overflowed value. |
| Tone Fit | Voice matches product context and user stress level. | Playful copy during destructive or security-sensitive actions. |
| Internationalization Safety | Long strings, numbers, dates, and locale-sensitive values do not break layout or meaning. | Truncated IDs, ambiguous dates, hard-coded local formats. |

## Required Evidence

For content-touching changes, the Evidence Ledger must include at least one of:

- A screenshot or browser check covering the changed surface.
- A content review artifact with rubric verdict.
- A test that asserts critical labels, states, or generated content.
- A risk acceptance row explaining why manual product review is required.
