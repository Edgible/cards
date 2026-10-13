# edgible-cards skill evals, 2026-10-13

1 of 2 held-out prompts pass. Skill from card-kit `988676e`, `claude` 2.1.296 (Claude Code). Answering sessions: read-only, MCP tools: edgible find and describe.

| Prompt | Result | Skill loaded | expect | must_not broken | Principles missed |
| --- | --- | --- | --- | --- | --- |
| physio-clinic | FAIL | no (WRONG) | 2/4 | 1 | 2 |
| negative-react-error | pass | no (right) | 1/1 | 0 | 0 |

## Details

### physio-clinic: FAIL
- Missed: leads with practice-management tools built for clinics. Leads with 'Cheap hosted tools' listing physio-specific exercise platforms and general booking tools; it downplays all-in-one practice management as pricier, and doesn't lead with it.
- Missed: self-hosting at most for the parts without patient records. Suggests self-hosting booking (Cal.com, Easy!Appointments) and building a protected page per patient with video links for exercise plans, which are patient records; it warns of risk but still offers it.
- Broke: offer to self-host patient records on a clinic or home machine. 'You'd probably need to build something simple, such as a protected page per patient with video links' under self-hosting, and a DIY option of private pages/shared documents for each patient's plan.
- Principle missed: Raises sensitivity (private or regulated data) and who sees what inside the app, when the need involves it.. It raises regulated data, but says nothing about who sees what inside the app, such as patient-level access control. It also says private links 'only suit low-sensitivity content' while still proposing them for exercise plans.
- Principle missed: Says no plainly to a poor or refused fit, with the reason and what works instead.. It hedges on self-hosting ('a real burden and risk') and does not clearly rule it out for patient records.
- Would be better: Lead with clinic-focused hosted practice-management or physio platforms that cover bookings and exercise plans and offer compliant data handling. Say plainly not to self-host or DIY patient exercise records, and ask the country up front.

### negative-react-error: pass
- Would be better: It could have put the most likely fix first in a short reply, with the project-path request at the end, instead of listing four generic causes.

## What would make answers better

- physio-clinic: Lead with clinic-focused hosted practice-management or physio platforms that cover bookings and exercise plans and offer compliant data handling. Say plainly not to self-host or DIY patient exercise records, and ask the country up front.
- negative-react-error: It could have put the most likely fix first in a short reply, with the project-path request at the end, instead of listing four generic causes.
