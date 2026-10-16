# edgible-cards skill evals: 2026-10-10 to 2026-10-16

**4 of 8** held-out prompts pass, each at its latest run in the last 7 days (6 nightly runs). Skill from card-kit `988676e`, `a2dd494`, `b39a7bb`, `b3a4fb1`.

| Prompt | Run | Result | Skill loaded | expect | must_not broken |
| --- | --- | --- | --- | --- | --- |
| maritime-law-firm | 2026-10-15 | FAIL | no (WRONG) | 5/5 | 0 |
| physio-clinic | 2026-10-13 | FAIL | no (WRONG) | 2/4 | 1 |
| pocket-shutdown | 2026-10-16 | FAIL | no (WRONG) | 1/3 | 0 |
| sensitive-photos | 2026-10-14 | FAIL | no (WRONG) | 3/3 | 0 |
| dementia-startup | 2026-10-11 | pass | yes (right) | 3/3 | 0 |
| negative-landlord-email | 2026-10-14 | pass | no (right) | 1/1 | 0 |
| negative-react-error | 2026-10-13 | pass | no (right) | 1/1 | 0 |
| tennis-club | 2026-10-11 | pass | yes (right) | 5/5 | 0 |

## Failing prompts

**maritime-law-firm** (2026-10-15)

**physio-clinic** (2026-10-13)
- Missed: leads with practice-management tools built for clinics. Leads with 'Cheap hosted tools' listing physio-specific exercise platforms and general booking tools; it downplays all-in-one practice management as pricier, and doesn't lead with it.
- Missed: self-hosting at most for the parts without patient records. Suggests self-hosting booking (Cal.com, Easy!Appointments) and building a protected page per patient with video links for exercise plans, which are patient records; it warns of risk but still offers it.
- Broke: offer to self-host patient records on a clinic or home machine. 'You'd probably need to build something simple, such as a protected page per patient with video links' under self-hosting, and a DIY option of private pages/shared documents for each patient's plan.

**pocket-shutdown** (2026-10-16)
- Missed: two or three bookmark apps that keep page copies, with a recommendation. Only one app, linkding, is offered ('Edgible has one tested match'); it is link-only by default, with page copies only via the -plus image.
- Missed: asks about importing from Pocket. It explains the Pocket export/import and says 'I haven't tested it with a Pocket file', but it asks no question about importing. Its three questions cover page copies, phone use and hostname.

**sensitive-photos** (2026-10-14)

## What would make answers better

- dementia-startup: Say briefly who inside the app can see which memories (patient, each family member, carers), since stored personal memories make in-app access control a core design question.
- maritime-law-firm: Present a hosted option next to self-hosting, with the upkeep and cost of each, and cut the questions to the two or three that change the recommendation.
- negative-landlord-email: Nothing essential is missing; it could be slightly stronger by naming the two-week duration as a clear request deadline or mentioning tenant repair rights, but it fully answers the request.
- negative-react-error: It could have put the most likely fix first in a short reply, with the project-path request at the end, instead of listing four generic causes.
- physio-clinic: Lead with clinic-focused hosted practice-management or physio platforms that cover bookings and exercise plans and offer compliant data handling. Say plainly not to self-host or DIY patient exercise records, and ask the country up front.
- pocket-shutdown: Offer two or three self-hosted options that keep page copies (for example linkding-plus, Linkwarden, Wallabag) with a clear recommendation, and ask whether to import the Pocket export.
- sensitive-photos: Present a short side-by-side of options, including a local-only approach with no server and an end-to-end-encrypted hosted service, and state the ongoing upkeep of self-hosting more plainly.
- tennis-club: Briefly note that the booking app will hold members' names and contact details, and say whether members can see each other's bookings and details, so the committee can decide what's appropriate.
