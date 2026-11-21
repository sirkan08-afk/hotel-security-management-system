-- Contractor Registration: read-only live audit
-- Target Supabase project: aclsqitjruccxkzjtxbl
-- Run in Supabase SQL Editor with an appropriately privileged dashboard session.
-- Every statement below is SELECT-only. Do not add UPDATE/DELETE/GRANT/REVOKE here.

-- 1) Effective table privileges (includes privileges inherited through role membership).
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

-- 2) Explicit table grants visible through information_schema.
-- Compare this with query 1: explicit grants and effective privileges are not identical concepts.
SELECT
  grantee, privilege_type, is_grantable, grantor,
  table_schema, table_name
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name = 'contractor_entries'
ORDER BY grantee, privilege_type;

-- 3) RLS enabled/forced state for the contractor table.
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'contractor_entries';

-- 4) Exact policy expressions for contractor_entries and Storage objects
-- whose expressions mention the contractor-private bucket.
SELECT
  schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE (schemaname = 'public' AND tablename = 'contractor_entries')
   OR (
     schemaname = 'storage'
     AND tablename = 'objects'
     AND (
       COALESCE(qual, '') ILIKE '%contractor-private%'
       OR COALESCE(with_check, '') ILIKE '%contractor-private%'
     )
   )
ORDER BY schemaname, tablename, policyname;

-- 5) Bucket settings (private/public, size and MIME restrictions).
SELECT
  id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'contractor-private';

-- 6) Role membership paths among the application roles.
-- This helps explain inherited privileges; it does not reveal individual Auth users.
SELECT
  member_role.rolname AS member_role,
  granted_role.rolname AS granted_role,
  m.admin_option
FROM pg_auth_members AS m
JOIN pg_roles AS member_role ON member_role.oid = m.member
JOIN pg_roles AS granted_role ON granted_role.oid = m.roleid
WHERE member_role.rolname IN ('anon', 'authenticated', 'service_role')
   OR granted_role.rolname IN ('anon', 'authenticated', 'service_role')
ORDER BY member_role.rolname, granted_role.rolname;

-- 7) Column-level grants, if any, on contractor_entries.
SELECT
  grantee, privilege_type, column_name, is_grantable
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'contractor_entries'
ORDER BY grantee, column_name, privilege_type;

-- Review output before proposing any permission change.
-- Never publish query output containing user data, credentials, JWTs, or signed URLs.
