-- Hotel Security Management System
-- READ-ONLY AUDIT ONLY. Run in Supabase SQL Editor.
-- These queries inspect metadata; they do not insert, update, delete, or alter anything.

-- 1) Columns and data types
SELECT c.table_name, c.ordinal_position, c.column_name, c.data_type, c.udt_name, c.is_nullable, c.column_default
FROM information_schema.columns AS c
WHERE c.table_schema = 'public' AND c.table_name IN ('contractor_entries','patrol_profiles','patrol_points','patrol_logs','patrol_day_plans','work_permits','work_permit_workers','work_permit_checklists','work_permit_department_approvals','user_roles')
ORDER BY c.table_name, c.ordinal_position;

-- 2) Foreign-key relationships
SELECT tc.table_name AS source_table, kcu.column_name AS source_column, ccu.table_name AS target_table, ccu.column_name AS target_column, tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.constraint_schema = kcu.constraint_schema
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.constraint_schema = tc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.constraint_schema = 'public'
AND tc.table_name IN ('contractor_entries','patrol_profiles','patrol_points','patrol_logs','patrol_day_plans','work_permits','work_permit_workers','work_permit_checklists','work_permit_department_approvals','user_roles')
ORDER BY source_table, constraint_name, kcu.ordinal_position;

-- 3) Primary keys and unique constraints
SELECT tc.table_name, tc.constraint_type, tc.constraint_name, string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS columns
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.constraint_schema = kcu.constraint_schema
WHERE tc.table_schema = 'public' AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
AND tc.table_name IN ('contractor_entries','patrol_profiles','patrol_points','patrol_logs','patrol_day_plans','work_permits','work_permit_workers','work_permit_checklists','work_permit_department_approvals','user_roles')
GROUP BY tc.table_name, tc.constraint_type, tc.constraint_name
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- 4) RLS enabled/forced status
SELECT n.nspname AS schema_name, c.relname AS table_name, c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS rls_forced
FROM pg_class AS c JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname IN ('contractor_entries','patrol_profiles','patrol_points','patrol_logs','patrol_day_plans','work_permits','work_permit_workers','work_permit_checklists','work_permit_department_approvals','user_roles')
ORDER BY c.relname;

-- 5) Storage bucket settings only; no object names or file contents
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets WHERE id IN ('contractor-private', 'patrol-evidence') ORDER BY id;
