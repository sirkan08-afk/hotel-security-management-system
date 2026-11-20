# Integration Plan — Hotel Security Management System

## Goal
Build one new staff-facing application that provides Security Patrol, Contractor Registration, and Work Permit while continuing to use the existing applications' databases. Existing applications and their data must remain operational and unchanged during development.

## Confirmed source repositories
- New portal: `sirkan08-afk/hotel-security-management-system`
- Contractor Registration: `sirkan08-afk/contractor-app-`
- Patrol and Work Permit: `sirkan08-afk/Contactor-visitor`

## Confirmed database endpoints from existing client configuration
| Module | Supabase project | Evidence in source |
|---|---|---|
| Security Patrol | `nldoneixnuapuzpeeznl` | `patrol/index.html` |
| Work Permit | `nldoneixnuapuzpeeznl` | `work-permit/index.html` |
| Contractor Registration | `aclsqitjruccxkzjtxbl` | `contractor-app-/index.html` |

These are two separate Supabase projects. The client-side publishable keys are intentionally not copied into this document.

## Existing data objects found in application code
### Security Patrol
- Tables: `patrol_profiles`, `patrol_points`, `patrol_logs`
- Additional table in schema: `patrol_day_plans`
- Private Storage bucket: `patrol-evidence`
- Existing schema file: `patrol/supabase/schema.sql`
- Existing app handles authentication, QR checkpoints, round times, status and evidence.

### Contractor Registration
- Table: `contractor_entries`
- Storage bucket: `contractor-private`
- Existing app repository: `sirkan08-afk/contractor-app-`

### Work Permit
- Tables referenced in client: `work_permits`, `work_permit_workers`, `work_permit_checklists`, `work_permit_department_approvals`, `user_roles`
- Existing app shares the Patrol Supabase project.
- Existing Work Permit client uses the same project endpoint as Patrol.

## Integration principles
1. Keep all three existing applications available during development.
2. Do not alter, rename, migrate, truncate, or delete existing tables, rows, buckets, policies, users, or QR tokens.
3. Start with read-only integration and compare portal results against each original app.
4. Preserve each module's existing authentication and authorization rules; do not assume a Patrol login grants Contractor or Work Permit access.
5. Never place a Supabase service-role key in browser code. Any cross-project privileged access must be performed by a secured server-side function with narrowly scoped authorization.
6. Preserve original evidence and attachments; do not expose private Storage buckets publicly.
7. Only enable writes from the new portal after each module's write path and permission checks have been verified.
8. Keep demo data visibly separate from live records.

## Remaining verification before live integration
- Inspect actual live schemas, RLS policies, Storage policies and Auth configuration in both Supabase projects.
- Confirm Work Permit Edge Function deployment and its exact request/response contract; it was not found in the checked repository paths.
- Confirm Contractor table columns and private Storage access policy.
- Test read-only queries against live projects using authorized credentials without exposing secrets.
- Define how users authenticate across the three modules and what roles are allowed to read/write each module.

## Current status
Repository and client-code inventory is complete at a preliminary level. No Supabase database, Storage bucket, user, policy, or existing application has been modified. Live integration has not yet been enabled.
