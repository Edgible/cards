# edgible-cards skill evals: 2026-10-07 to 2026-10-13

**4 of 4** held-out prompts pass, each at its latest run in the last 7 days (2 nightly runs). Skill from card-kit `b39a7bb`.

| Prompt | Run | Result | Skill loaded | expect | must_not broken |
| --- | --- | --- | --- | --- | --- |
| dementia-startup | 2026-10-11 | pass | yes (right) | 3/3 | 0 |
| negative-react-error | 2026-10-12 | pass | no (right) | 1/1 | 0 |
| physio-clinic | 2026-10-12 | pass | yes (right) | 4/4 | 0 |
| tennis-club | 2026-10-11 | pass | yes (right) | 5/5 | 0 |

## Failing prompts

None.
## What would make answers better

- dementia-startup: Say briefly who inside the app can see which memories (patient, each family member, carers), since stored personal memories make in-app access control a core design question.
- negative-react-error: It could have searched more widely for ProductList.jsx, for example outside the temp directory, and then pointed at the likely cause on line 14 instead of giving a generic list.
- physio-clinic: Give a rough price range or a concrete cheapest-path example for 3 practitioners, and say who can see which patient data, such as each physio seeing only their own patients.
- tennis-club: Briefly note that the booking app will hold members' names and contact details, and say whether members can see each other's bookings and details, so the committee can decide what's appropriate.
