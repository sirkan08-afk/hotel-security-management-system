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

**Result:** 10 table checks were displayed as successful. A zero-row result for `work_permit_checklists` is a successful query, not evidence of an error.

## 2. Contractor Registration access checks

The SQL Editor screenshots showed:

- SELECT policy `Authenticated staff can read entries`: `USING (true)`, role `authenticated`.
- INSERT policy `Authenticated staff can insert entries`: `WITH CHECK (auth.uid() = created_by)`.
- UPDATE policy `Authenticated staff can update entries`: `USING (true)` and `WITH CHECK (true)`.
- DELETE policy `admin001_delete_contractor_entries`: restricted by the JWT email claim to `admin001@contractor.local`.
- Table privilege check for role `authenticated`: SELECT, INSERT, UPDATE and DELETE returned true; TRUNCATE returned false.
- The column-privilege listing showed `is_grantable = NO`; this means the role cannot grant those privileges onward. It does not mean the privilege itself is absent.

## 3. Contractor image Storage checks

Bucket `contractor-private` was confirmed in the Contractor Registration project with:

- `public = false` (private bucket).
- Maximum file size: 5,242,880 bytes (5 MB).
- Allowed MIME types: image/jpeg, image/png, image/webp.

The user-provided Storage policy query showed four policies on `storage.objects` for this bucket:

- SELECT: authenticated staff read contractor images, constrained only by `bucket_id = 'contractor-private'`.
- INSERT: authenticated staff upload contractor images, constrained only by the bucket.
- DELETE: authenticated staff delete contractor images, constrained only by the bucket.
- Additional admin-specific DELETE policy for the same bucket, with an ADMIN001 email condition.

**Security observation:** the general authenticated DELETE policy means any authenticated staff account allowed by the policy can delete any object in this bucket; the ADMIN001 policy is additive and does not restrict the general policy. The general SELECT policy allows authenticated staff to read all objects in the bucket. Do not change these production policies as part of this read-only integration phase. A separate, reviewed permissions change would be needed to narrow deletion rights.

### 3.1 Contractor image path and object consistency

The user-provided read-only SQL results established:

| Check | Result |
|---|---:|
| Contractor entries | 211 |
| Entries with ID-card path | 134 |
| Entries with vehicle-image path | 42 |
| ID-card paths without a folder segment | 0 |
| Vehicle paths without a folder segment | 0 |
| ID-card paths found in Storage | 134 / 134 |
| Vehicle paths found in Storage | 42 / 42 |
| Missing referenced Storage objects | 0 |

Storage object names were observed under first-level folders such as `ADMIN001/` and `SEC001/`, with timestamp-based filenames ending in `-id-card.jpg` or `-vehicle.jpg`. The path comparison found every referenced object (176 total) in the private bucket.

These checks confirm path/object existence at the time of testing. They do not independently verify that every object can be downloaded by every intended user, nor do they validate the image contents.

## 4. Important safety interpretation

- These checks establish that the supplied test session could sign in and run SELECT queries and return the row counts shown.
- They do **not** establish that every application workflow, image download, Edge Function, or every user's access is correct.
- Do not add write, update, delete, or Storage mutation calls to the new app yet.
- Do not change existing app authentication or existing policies as part of this read-only phase.
- Never place a Supabase `service_role` secret in browser code.
- Keep the old Contractor, Patrol, and Work Permit apps unchanged while the new app is being validated.

## 5. Next verification gates

1. Test SELECT and private-image download with a normal authenticated staff account, not only ADMIN001.
2. Confirm the actual login/email mapping for representative Patrol and Work Permit roles.
3. Inspect the deployed `submit-work-permit` Edge Function separately, including authorization and public submission/tracking behavior; do not expose secret values.
4. Verify any required image access from the new portal without adding broad Storage permissions.
5. Only after these checks, prepare a separately reviewed write-access plan. No production writes are authorized by this document.

---
This document records observations from the user's SQL results and screenshots. It is not an independent live audit and does not change any Supabase configuration.
