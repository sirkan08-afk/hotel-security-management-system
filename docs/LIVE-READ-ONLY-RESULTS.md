# Live Read-only Connection Results

Date: 2026-11-21
Scope: Results reported by the user from the Supabase SQL Editor / Read-only Connection Check page. Counts only; no personal row contents were retrieved in the test summary.

## Confirmed read-only table counts

| Project | Table | Rows returned by exact count |
|---|---|---:|
| Contractor (aclsqitjruccxkzjtxbl) | contractor_entries | 211 |
| Patrol + Work Permit (nldoneixnuapuzpeeznl) | patrol_profiles | 5 |
| Patrol + Work Permit | patrol_points | 47 |
| Patrol + Work Permit | patrol_logs | 544 |
| Patrol + Work Permit | patrol_day_plans | 1 |
| Patrol + Work Permit | work_permits | 6 |
| Patrol + Work Permit | work_permit_workers | 29 |
| Patrol + Work Permit | work_permit_checklists | 0 |
| Patrol + Work Permit | work_permit_department_approvals | 6 |
| Patrol + Work Permit | user_roles | 5 |

The read-only test reported successful sign-in and SELECT access for Contractor and Patrol/Work Permit.

## Important interpretation

- A successful exact count confirms that the tested authenticated session could execute the count query for that table at the time of the test.
- It does not verify every column, row-level filtering, joins, Storage object access, or write permissions.
- work_permit_checklists returning 0 means the table was readable and the count was zero at test time; it does not prove checklist functionality is configured.
- These results do not authorize write operations. Existing applications and databases remain unchanged.

## Next verification required

Run the read-only SQL in READ-ONLY-RELATIONSHIP-AUDIT.sql separately in each relevant Supabase project:
1. Contractor project: inspect contractor_entries.
2. Patrol/Work Permit project: inspect the four Patrol and five Work Permit tables.

The query reports column definitions, foreign-key relationships, primary/unique constraints, RLS flags, and the two relevant Storage bucket settings. It does not read personal records or change database objects.

After receiving these results, finalize the data mapping for the new Dashboard and module list views. Keep the new portal read-only until field-level access, joins, Storage rules, and user-role mapping are verified.
