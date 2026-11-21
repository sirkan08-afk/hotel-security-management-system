# Live Supabase Verification Checklist

สถานะ: เตรียมรายการตรวจสอบก่อนเชื่อมระบบใหม่
หลักความปลอดภัย: ตรวจสอบอย่างเดียว (read-only) ห้ามแก้ไข schema, rows, policies, buckets, users หรือ secrets ในขั้นตอนนี้

## Projects in scope

| Module | Supabase project ref |
|---|---|
| Security Patrol + Work Permit | `nldoneixnuapuzpeeznl` |
| Contractor Registration | `aclsqitjruccxkzjtxbl` |

## A. Contractor Registration project

Project: `aclsqitjruccxkzjtxbl`

### Table: `contractor_entries`
In Supabase Dashboard → Table Editor → `contractor_entries`:
- Confirm the table exists and record the visible column names/types.
- Open RLS Policies and capture each policy's operation, USING expression, and WITH CHECK expression.
- Confirm whether RLS is enabled. Do not toggle it.
- Check constraints/indexes only; do not change them.

### Storage: `contractor-private`
In Storage → `contractor-private`:
- Confirm whether the bucket is Public or Private.
- Open Policies and record SELECT, INSERT, UPDATE, DELETE policy expressions.
- Do not make the bucket public and do not change policies.

## B. Patrol + Work Permit project

Project: `nldoneixnuapuzpeeznl`

### Patrol tables
Check RLS status and policy expressions for:
- `patrol_profiles`
- `patrol_points`
- `patrol_logs`
- `patrol_day_plans`

Pay special attention to day-plan INSERT/UPDATE policies and any overlapping policies for patrol evidence.

### Storage: `patrol-evidence`
- Confirm bucket Public/Private setting.
- Record each Storage policy's operation, USING, and WITH CHECK expressions.
- Do not change bucket settings or policies.

### Work Permit tables
Check whether these tables exist and capture RLS status and policy expressions:
- `work_permits`
- `work_permit_workers`
- `work_permit_checklists`
- `work_permit_department_approvals`
- `user_roles`

### Edge Function
In Edge Functions → `submit-work-permit`:
- Confirm deployed function exists and note its deployment/version metadata.
- Inspect source and authorization/validation flow if available.
- Do not copy or share secret values, API keys, JWTs, or environment variable values.
- Do not redeploy or change secrets.

## C. Authentication and role mapping

For both projects, determine:
- Which existing login method is used by each app.
- How authenticated users map to staff profiles/roles.
- Whether staff identities are shared between projects or mapped separately.
- Which roles may read each module and which roles may write.

Do not export user lists or share personal credentials.

## D. Evidence needed to proceed

Please provide screenshots of:
1. Contractor `contractor_entries` → Policies, with each policy opened so USING/WITH CHECK are visible.
2. Contractor Storage `contractor-private` → bucket details and Policies.
3. Patrol tables → Policies for the four Patrol tables.
4. Patrol Storage `patrol-evidence` → bucket details and Policies.
5. Work Permit tables → Policies.
6. Edge Functions list showing `submit-work-permit` exists (hide any secret values).

Screenshots should show policy names, operations, and expressions. Never include passwords, access tokens, service-role keys, or secret values.

## E. Go/no-go criteria

The new portal remains demo-only until:
- Live schema and RLS are verified for both projects.
- Storage access is verified without making private buckets public.
- Work Permit Edge Function behavior and authorization are verified.
- Cross-project identity and role mapping are defined.
- Read-only tests succeed using authorized, non-privileged client access.

Only after these checks may a separate, narrowly scoped write test be planned. Existing applications and data must remain unchanged.
