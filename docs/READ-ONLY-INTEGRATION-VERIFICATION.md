# Read-only Integration Verification

**Date checked:** 2026-11-21  
**Environment:** Supabase production projects, checked manually in SQL Editor  
**Purpose:** Verify that the new Hotel Security Management System can read the existing operational data before any write integration is considered.

## 1. Read-only row-count checks

The user ran authenticated sign-in and SELECT-only checks from the integration test page. The displayed results were:

| Source project | Table | Rows returned |
|---|---|---:|
| Contractor Registration | `contractor_entries` | 211 |
| Security Patrol | `patrol_profiles` | 5 |
| Security Patrol | `patrol_points` | 47 |
| Security Patrol | `patrol_logs` | 544 |
| Security Patrol | `patrol_day_plans` | 1 |
| Work Permit | `work_permits` | 6 |
| Work Permit | `work_permit_workers` | 29 |
| Work Permit | `work_permit_checklists` | 0 |
| Work Permit | `work_permit_department_approvals` | 6 |
| Work Permit | `user_roles` | 5 |

**Result:** 10 table checks were displayed as successful (the earlier test page showed 4 rows of results; the later expanded test showed 9 rows for Patrol + Work Permit, in addition to Contractor). A zero-row result for `work_permit_checklists` is a successful query, not evidence of an error.

## 2. Contractor Registration access checks

The SQL Editor screenshots showed:

- SELECT policy `Authenticated staff can read entries`: `USING (true)`, role `authenticated`.
- INSERT policy `Authenticated staff can insert entries`: `WITH CHECK (auth.uid() = created_by)`.
- UPDATE policy `Authenticated staff can update entries`: `USING (true)` and `WITH CHECK (true)`.
- DELETE policy `admin001_delete_contractor_entries`: restricted by the JWT email claim to `admin001@contractor.local`.
- Table privilege check for role `authenticated`: SELECT, INSERT, UPDATE and DELETE returned true; TRUNCATE returned false.
- The column-privilege listing showed `is_grantable = NO`; this means the role cannot grant those privileges onward. It does not mean the privilege itself is absent.
- The role-table-grants listing showed `is_grantable = NO` for authenticated grants; this is also not a denial of the underlying privilege.

## 3. Contractor image Storage policy checks

The screenshots showed four policies on `storage.objects` for bucket `contractor-private`:

- SELECT: authenticated staff read contractor images, constrained to the bucket.
- INSERT: authenticated staff upload contractor images, constrained to the bucket.
- DELETE: authenticated staff delete contractor images, constrained to the bucket.
- An additional admin-specific DELETE policy for the same bucket.

The screenshots do not establish whether the bucket's public flag is disabled, nor do they show an UPDATE policy for Storage objects. Verify bucket visibility and any required update behavior before enabling image operations in the new app.

## 4. Important safety interpretation

- These checks establish that the test session could sign in and run SELECT queries and return the row counts shown.
- They do **not** establish that every application workflow, image download, Edge Function, or every user's access is correct.
- Do not add write, update, delete, or storage mutation calls to the new app yet.
- Do not change existing app authentication or existing policies as part of this read-only phase.
- Never place a Supabase `service_role` secret in browser code.
- Keep the old Contractor, Patrol, and Work Permit apps unchanged while the new app is being validated.

## 5. Next verification gates

1. Confirm the `contractor-private` bucket is private in Supabase Storage settings.
2. Test SELECT for a normal authenticated staff account, not only ADMIN001.
3. Verify that the new app can read the required tables without exposing private columns or images unnecessarily.
4. Inspect Patrol and Work Permit policies and grants, and inspect the deployed `submit-work-permit` Edge Function separately.
5. Only after these checks, prepare a separately reviewed write-access plan. No production writes are authorized by this document.

---
This document records observations from the screenshots and test output supplied during the session. It is not an independent live audit and does not change any Supabase configuration.
