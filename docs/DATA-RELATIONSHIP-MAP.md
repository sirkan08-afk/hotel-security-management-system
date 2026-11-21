# Data Relationship Map — Hotel Security Management System

Date: 2026-11-21

## Scope and evidence

This map is based on:
- Live read-only row-count tests performed by the user in Supabase for the tables listed below.
- The checked-in Patrol SQL schema.
- Existing Work Permit and Contractor frontend queries.
- Contractor table columns shown in the user's Supabase Table Editor screenshots.

A successful SELECT/count test proves that the signed-in test account can read a table. It does **not** prove that every column, relationship, foreign key, Storage object, or business rule has been verified.

## Supabase project boundaries

| Module | Supabase project ref | Main objects |
|---|---|---|
| Contractor Registration | `aclsqitjruccxkzjtxbl` | `contractor_entries`, Storage `contractor-private` |
| Security Patrol | `nldoneixnuapuzpeeznl` | Patrol tables, Storage `patrol-evidence` |
| Work Permit | `nldoneixnuapuzpeeznl` | Work Permit tables |

Contractor is in a separate Supabase project. The portal must use a separate authenticated client/session for it or a secured server-side integration. Do not attempt cross-project joins in browser SQL.

## Contractor Registration

### Table: `public.contractor_entries`

Columns confirmed from the Table Editor screenshot:
- `id` (uuid)
- `work_date` (date)
- `time_in` (timestamp)
- `time_out` (timestamp)
- `id_last4` (bpchar)
- `full_name` (text)
- `company_name` (text)
- `car_plate` (text)
- `department` (text)
- `work_location` (text)
- `team_size` (numeric)
- `id_card_path` (text)
- `car_image_path` (text)
- `created_by` (uuid)
- `created_at` (timestamp)

### Relationships / interpretation
- Each row is one contractor registration entry.
- `team_size` is the headcount represented by that entry; do not confuse row count with people count.
- `time_out IS NULL` means the contractor is still on site / no exit has been recorded.
- `time_out IS NOT NULL` means an exit has been recorded.
- The current on-site metric must be computed across all relevant dates, not only today's `work_date`.
- The daily report is filtered by `work_date`.
- `id_card_path` and `car_image_path` point to private objects in `contractor-private`; they are not public image URLs.
- Frontend behavior confirms the app reads by `work_date`, matches exit registration by `work_date + id_last4 + time_out IS NULL`, then updates `time_out`.

Foreign-key constraints for `created_by` and the exact relationship to Auth users have not yet been verified from live catalog metadata.

## Security Patrol

### Tables and relationships from checked-in `patrol/supabase/schema.sql`

- `patrol_profiles`: staff profile; `id` references `auth.users(id)`.
- `patrol_points`: checkpoint master; `id` is referenced by patrol logs.
- `patrol_logs`: patrol event; `point_id` references `patrol_points(id)`; `guard_id` references `patrol_profiles(id)`.
- `patrol_day_plans`: one daily plan per `patrol_date`; `configured_by` references `patrol_profiles(id)`.

### Dashboard joins
- Patrol log → checkpoint: `patrol_logs.point_id = patrol_points.id`.
- Patrol log → reporting guard: `patrol_logs.guard_id = patrol_profiles.id`.
- Day plan → configuring profile: `patrol_day_plans.configured_by = patrol_profiles.id`.

The schema's round values are 10:00, 14:00, 18:00, and 22:00. Patrol statuses include normal, abnormal, and inaccessible. Keep the original status values; map them to display labels only in the UI.

## Work Permit

### Tables confirmed by frontend usage
- `work_permits`
- `work_permit_workers`
- `work_permit_checklists`
- `work_permit_department_approvals`
- `user_roles`

### Relationships evidenced by frontend queries
- `work_permit_workers.permit_id` is used to retrieve workers for a permit.
- `work_permit_checklists.permit_id` is used to retrieve checklist items for a permit.
- `work_permit_department_approvals.permit_id` is used to retrieve permits associated with approval rows.
- Staff role lookup uses `user_roles.user_id = auth user id` and reads `role`.

The Work Permit frontend uses `work_permits.id` as the permit identifier in queries. This strongly suggests the child-table `permit_id` values refer to `work_permits.id`, but the actual live foreign-key constraints and complete column definitions have **not** yet been inspected. Treat this as an application-level join assumption until verified.

### Work Permit join plan (read-only)
- Permit → workers: `work_permits.id = work_permit_workers.permit_id`.
- Permit → checklist: `work_permits.id = work_permit_checklists.permit_id`.
- Permit → department approvals: `work_permits.id = work_permit_department_approvals.permit_id`.
- Current staff role: `user_roles.user_id = auth.uid()`.

The current read-only test returned 0 rows for `work_permit_checklists`. The table was readable, but no checklist rows were returned at the time of the test.

## Live read-only test results captured 2026-11-21

| Table | Rows returned |
|---|---:|
| `patrol_profiles` | 5 |
| `patrol_points` | 47 |
| `patrol_logs` | 544 |
| `patrol_day_plans` | 1 |
| `work_permits` | 6 |
| `work_permit_workers` | 29 |
| `work_permit_checklists` | 0 |
| `work_permit_department_approvals` | 6 |
| `user_roles` | 5 |
| `contractor_entries` | 211 (separate earlier read-only test) |

Counts are snapshots at test time and can change. They are not totals guaranteed to remain constant.

## Still to verify before live dashboard release

1. Inspect live column metadata, data types, primary keys, foreign keys, unique constraints, and indexes for all nine Patrol/Work Permit tables.
2. Inspect Work Permit `work_permits` and child-table full column definitions; confirm FK constraints, status values, date/time fields, and approval state model.
3. Confirm Contractor live column definitions and `created_by` relationship; screenshot-based inventory is not a substitute for catalog metadata.
4. Verify private Storage bucket flags and object policies in both projects.
5. Verify cross-project identity mapping and session lifecycle. Do not assume a login in one project authenticates the other.
6. Keep all portal operations read-only until the above is complete.

## Safety constraints

- No migrations or schema changes are part of this audit.
- Do not truncate, delete, update, or insert any existing production rows.
- Do not expose service-role keys or private Storage URLs in browser code.
- Do not display ID-card images or full personal identifiers on the dashboard.
