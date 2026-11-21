# Contractor Registration Security Hardening Plan

## Purpose

Prepare the existing Contractor Registration Supabase project for safe read-only integration with the new Hotel Security Management System, while keeping the legacy Contractor Registration application working.

**Target project:** `aclsqitjruccxkzjtxbl`  
**Table:** `public.contractor_entries`  
**Storage bucket:** `contractor-private`

This document records observations from the Supabase Dashboard screenshots and a staged remediation plan. It is not evidence that the live project has been changed.

## Safety rules

- Do not delete, truncate, migrate, rename, or overwrite existing rows, objects, users, tables, buckets, or policies during this work.
- Do not turn the `contractor-private` bucket public.
- Do not put a `service_role` key in browser code, GitHub Pages, or a client-side environment variable.
- Do not change existing policies until the legacy app's required behavior has been mapped and tested.
- Use a separate test account and a controlled test record/object for permission tests. Do not test destructive actions against production records.
- Keep the existing Contractor app available and unchanged until the new portal passes acceptance tests.

## Observed live configuration (from user-provided Dashboard screenshots)

### Bucket settings

| Setting | Observed value |
|---|---|
| Bucket | `contractor-private` |
| Public bucket | Off (private) |
| File size restriction | On; 5 MB |
| MIME type restriction | On |
| Allowed types | `image/jpeg`, `image/png`, `image/webp` |

### RLS policies on `public.contractor_entries`

| Policy | Command | Target role | Observed expression |
|---|---|---|---|
| Authenticated staff can read entries | SELECT | authenticated | `USING (true)` |
| Authenticated staff can insert entries | INSERT | authenticated | `WITH CHECK (auth.uid() = created_by)` |
| Authenticated staff can update entries | UPDATE | authenticated | `USING (true) WITH CHECK (true)` |
| admin001_delete_contractor_entries | DELETE | authenticated | JWT email equals `admin001@contractor.local` |

Interpretation:
- Any authenticated user covered by the SELECT policy can read every row.
- INSERT checks that `created_by` equals the caller's Auth UID.
- Any authenticated user covered by the UPDATE policy can update any row; the policy does not restrict rows or changed columns by owner/role.
- The Admin DELETE policy is email-specific. This only describes that policy; confirm there are no other permissive DELETE policies before concluding who can delete rows.

### Table grants reported by SQL

The user supplied a query result showing `anon` and `authenticated` with table-level grants including SELECT, INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, and REFERENCES on `public.contractor_entries`. The `postgres` and `service_role` rows also appeared.

Important:
- RLS policies and SQL table privileges are separate layers; both must allow an operation.
- RLS does not protect against TRUNCATE. A role with TRUNCATE privilege may bypass row-level policy filtering for that operation.
- The grant output alone does not show whether a privilege is inherited from PUBLIC, a role membership, or a direct grant, and it does not establish whether the application exposes a usable anonymous route. Confirm effective privileges and role membership before changing grants.

### Storage policies on `storage.objects` for `contractor-private`

| Policy | Command | Target role | Observed expression |
|---|---|---|---|
| Authenticated staff read contractor images | SELECT | authenticated | `bucket_id = 'contractor-private'` |
| Authenticated staff upload contractor images | INSERT | authenticated | `WITH CHECK (bucket_id = 'contractor-private')` |
| Authenticated staff delete contractor images | DELETE | authenticated | `USING (bucket_id = 'contractor-private')` |
| admin001_delete_contractor_images | DELETE | authenticated | Bucket condition AND JWT email equals `admin001@contractor.local` |

Interpretation:
- The bucket itself is private, but authenticated staff have a policy to read all objects in it.
- Authenticated staff have a policy to upload objects to the bucket.
- The broad staff DELETE policy permits authenticated staff to delete objects in the bucket. Because Supabase/Postgres permissive policies are OR-combined, the additional Admin-specific DELETE policy does not restrict the broad policy.
- Folder names shown in the Storage browser (such as `ADMIN001` and `SEC001`) are object paths, not proof of access isolation. Current expressions do not check those folder names.

## Recommended target access model (to confirm with app owners before applying)

| Role / user group | Read contractor records | Create records | Update records | Delete records | Read/upload images | Delete images |
|---|---|---|---|---|---|---|
| ADMIN001 | All records | Yes | All records | Yes | All bucket objects | Yes |
| SEC001–SEC003 | Operationally required records | Yes | Only approved operational updates | No, unless legacy workflow requires it | Operationally required images | No, unless legacy workflow requires it |

This is a proposed least-privilege target, not a statement of current behavior. Confirm whether Security staff need to correct other staff's records, delete an image when correcting an entry, or use the same login identities across the old and new applications before implementing it.

## Staged remediation plan

### Stage 0 — Preserve and document current state

1. Export or otherwise securely preserve the current policy definitions and relevant grants.
2. Confirm a recoverable database backup exists and note its restore procedure.
3. Record the current legacy app version and test its login, entry, exit, image upload, image viewing, image deletion, row deletion, Excel export, and PDF export.
4. Do not change production settings during this stage.

### Stage 1 — Complete read-only privilege diagnostics

Run the following read-only checks in the SQL Editor and save the results securely.

**Effective table privileges:**

```sql
SELECT
  r.rolname,
  has_table_privilege(r.rolname, 'public.contractor_entries', 'SELECT') AS can_select,
  has_table_privilege(r.rolname, 'public.contractor_entries', 'INSERT') AS can_insert,
  has_table_privilege(r.rolname, 'public.contractor_entries', 'UPDATE') AS can_update,
  has_table_privilege(r.rolname, 'public.contractor_entries', 'DELETE') AS can_delete,
  has_table_privilege(r.rolname, 'public.contractor_entries', 'TRUNCATE') AS can_truncate,
  has_table_privilege(r.rolname, 'public.contractor_entries', 'TRIGGER') AS can_trigger,
  has_table_privilege(r.rolname, 'public.contractor_entries', 'REFERENCES') AS can_references
FROM pg_roles AS r
WHERE r.rolname IN ('anon', 'authenticated', 'service_role', 'postgres')
ORDER BY r.rolname;
```

**Policies and expressions:**

```sql
SELECT
  schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE (schemaname = 'public' AND tablename = 'contractor_entries')
   OR (schemaname = 'storage' AND tablename = 'objects')
ORDER BY schemaname, tablename, policyname;
```

**Object-level bucket visibility:**

```sql
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'contractor-private';
```

Do not paste API keys, JWTs, signed URLs, or private image URLs into GitHub or chat.

### Stage 2 — Prepare a minimal permission change set (not yet applied)

Subject to Stage 1 results and legacy-app workflow confirmation:

1. Remove unnecessary `TRUNCATE`, `TRIGGER`, and `REFERENCES` privileges from `anon` and `authenticated` if no documented workflow needs them.
2. Revoke unnecessary table privileges from `anon` only after confirming no unauthenticated legacy workflow depends on them. RLS currently has no shown `anon` policy, but table grants should still be minimized.
3. Replace broad UPDATE access with a role/ownership-aware rule only after confirming which fields SEC users must update and whether staff must update records created by other staff.
4. Remove or narrow the broad Storage DELETE policy if the approved workflow says only ADMIN001 may delete images. Keep a single unambiguous delete policy for the approved role.
5. Keep the bucket private. Keep the current size and MIME restrictions unless the app's documented requirements require a reviewed change.
6. Do not alter SELECT access until the portal's required data scope is defined. Contractor records include personal information, so broad read access must be an explicit operational decision.

Do not copy/paste a generic REVOKE script into production. Generate exact SQL only after effective privileges, role memberships, legacy workflows, and rollback steps have been verified.

### Stage 3 — Test changes safely

1. Prefer a staging project or isolated test table/bucket with equivalent policies.
2. Test as ADMIN001, SEC001, SEC002, SEC003, and an unauthenticated `anon` request.
3. Verify allowed and denied cases for SELECT, INSERT, UPDATE, DELETE, TRUNCATE, image SELECT, image INSERT, and image DELETE.
4. Verify object paths cannot be accessed by guessing another user's folder.
5. Confirm signed URLs are short-lived and are issued only after an authorized server-side request, if signed URLs are used.
6. Re-run the legacy app's full regression checklist.

### Stage 4 — Read-only integration for the new portal

1. Connect the new portal to the Contractor project using only the publishable key and an authenticated user session; never use the service-role key in the browser.
2. Begin with SELECT-only access to the minimum fields required for the dashboard and reports.
3. Do not expose full ID-card images or unnecessary personal fields in dashboard views.
4. Compare daily totals, on-site counts, exited counts, and team-size totals with the legacy app.
5. Keep writes, image deletion, and record deletion disabled in the new portal until separately approved and tested.

### Stage 5 — Controlled write enablement

Enable one operation at a time (create, update, upload) after tests pass. Keep delete operations disabled in the new portal until the Admin-only workflow is confirmed and tested. Monitor errors and retain a rollback plan.

## Acceptance checklist

- [ ] Existing Contractor app login and daily registration still work.
- [ ] Exit registration still updates only the intended entry and preserves blank `time_out` values for contractors still on site.
- [ ] Images remain private and visible only to authorized authenticated users.
- [ ] Only approved users can upload, update, or delete records and images.
- [ ] No non-admin role can TRUNCATE the table.
- [ ] No browser bundle or GitHub file contains a service-role key.
- [ ] New portal initially performs read-only access and matches legacy app results.
- [ ] No existing data, Storage objects, or QR identifiers were deleted or migrated.

## Current status

- Dashboard screenshots have confirmed the listed RLS expressions and the bucket's private setting.
- Effective privilege inheritance, full Auth user/role mapping, and the legacy app's exact image-deletion workflow still need confirmation.
- No production grants, RLS policies, bucket settings, tables, rows, or Storage objects have been changed as part of this plan.
