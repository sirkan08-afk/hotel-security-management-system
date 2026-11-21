# Existing Supabase Schema & Access Audit

Date: 2026-11-20
Scope: source-code and checked-in SQL inspection only. This is not a live Supabase database inspection.

## Project mapping confirmed from frontend configuration
- Patrol + Work Permit: Supabase project ref `nldoneixnuapuzpeeznl`
- Contractor Registration: Supabase project ref `aclsqitjruccxkzjtxbl`

No credentials or publishable keys are recorded in this audit.

## Patrol project — checked-in SQL

Source: `patrol/supabase/schema.sql`

### Tables and columns
- `patrol_profiles`: `id` (FK to `auth.users`), `full_name`, `employee_code` (unique), `role` (guard/admin), `active`, `created_at`.
- `patrol_points`: `id`, `point_code` (unique), `area_code`, `area_name`, `point_name`, `qr_token` (unique UUID), `sort_order`, `active`, `created_at`.
- `patrol_logs`: `id`, `point_id`, `guard_id`, `status` (normal/abnormal/inaccessible), `notes`, `evidence_path`, `created_at`, `round_time` (10:00/14:00/18:00/22:00).
- `patrol_day_plans`: `patrol_date`, `plan_type` (full_day/morning_only/afternoon_only), `configured_by`, `created_at`, `updated_at`.

### RLS policies visible in checked-in SQL
- RLS is enabled for all four Patrol tables.
- Active users can read profiles, points, logs, and day plans.
- Guards can insert their own patrol logs when active.
- Admins can manage patrol points.
- Admins can insert/update day plans in the main schema file. Additional setup SQL contains broader active-user day-plan insert/update policies; this difference must be reconciled against the actual deployed policies before relying on any write behavior.
- Evidence bucket policies restrict access to authenticated/active Patrol users, with upload paths scoped to the user's auth UUID. The SQL includes overlapping read policies (team read and own/admin read); deployed behavior must be checked in Supabase.

### Storage
- Bucket referenced by the app/schema: `patrol-evidence`.
- SQL indicates private/authenticated access patterns; confirm the bucket's actual public flag and deployed Storage policies.

## Work Permit project — frontend references
Source: `work-permit/index.html`

Tables referenced:
- `work_permits`
- `work_permit_workers`
- `work_permit_checklists`
- `work_permit_department_approvals`
- `user_roles`

The public submission and tracking flows call the Edge Function `submit-work-permit` with actions `submit` and `track`. Staff UI reads and updates the listed tables directly through the Supabase client. The Edge Function source was not found at the checked repository path, so its deployed implementation, authorization, validation, Turnstile verification, and tracking behavior remain unverified here.

No Work Permit table definitions or RLS policies were present in the checked frontend file. Do not infer deployed policies from the frontend calls.

## Contractor Registration project — frontend references
Source: `sirkan08-afk/contractor-app-/index.html`

- Table: `contractor_entries`
- Storage bucket: `contractor-private`
- Frontend reads entries by `work_date`, inserts entry records, updates `time_out`, and deletes selected records.
- Referenced fields include `id`, `work_date`, `id_last4`, `full_name`, `company_name`, `car_plate`, `department`, `work_location`, `team_size`, `id_card_path`, `car_image_path`, `time_out`.
- The app downloads, uploads, and removes objects in `contractor-private`.

No Contractor table DDL, Storage policies, or RLS policies were found in the inspected repository root. Actual schema and access rules remain unverified.

## Integration readiness

| Module | Source inventory | Deployed schema/RLS verified | Safe for portal reads/writes |
|---|---|---|---|
| Patrol | Partial SQL + frontend | No | Not yet |
| Work Permit | Frontend references only | No | Not yet |
| Contractor Registration | Frontend references only | No | Not yet |

## Required live checks before implementation
1. In each Supabase project, inspect Table Editor columns, constraints, indexes, RLS status, and Policies.
2. Inspect Storage bucket settings and policies for `patrol-evidence` and `contractor-private`.
3. Confirm Auth users, roles, and how staff identity maps across projects.
4. Confirm the deployed `submit-work-permit` Edge Function code and secrets/configuration without exposing secret values.
5. Compare deployed definitions with the checked-in Patrol SQL, especially the overlapping day-plan and evidence policies.
6. Run read-only tests under representative authenticated user roles. Do not use service-role credentials in the browser.

## Safety status
No live database, Storage object, user, policy, or existing application was changed during this audit.


## 2026-11-21 follow-up — Work Permit frontend flow inspection

The existing `work-permit/index.html` in `sirkan08-afk/Contactor-visitor` was inspected.

Observed frontend behavior:
- Uses the Patrol/Work Permit Supabase project `nldoneixnuapuzpeeznl` with a publishable key in the browser.
- Public submission invokes Edge Function `submit-work-permit` with `action: "submit"` and a Cloudflare Turnstile response token.
- Public tracking invokes the same function with `action: "track"`.
- Staff sign-in uses the email pattern `<staff_user_id lowercase>@patrol.com`.
- After staff sign-in, the frontend reads `user_roles.role` for the authenticated user.
- The staff approval queue reads `work_permit_department_approvals`; ADMIN sees all departments, while other roles are filtered to their own department and pending status.
- The staff UI reads permit and worker details from `work_permits` and `work_permit_workers`.
- Inspection save logic checks for ADMIN, SAFETY, or SECURITY and writes checklist rows to `work_permit_checklists`.

Work Permit status labels visible in the frontend:
- Permit: `draft`, `submitted`, `under_review`, `approved`, `rejected`, `revision_requested`, `closed`.
- Department approval: `pending`, `approved`, `rejected`, `revision_requested`.

**Important limitation:** The deployed Edge Function source was not found in the inspected GitHub repository at the expected paths, and GitHub code search returned no matching source file. The frontend alone does not prove the deployed function's validation, authorization, Turnstile verification, database writes, tracking-code hashing, or rate limiting. These remain unverified. Do not treat the public submission/tracking flow as security-audited until the deployed function source is reviewed.

No production database, Edge Function, Storage policy, or existing app was changed during this follow-up.
