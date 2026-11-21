# Contractor Registration — Status & Dashboard Rules

สถานะในเอกสารนี้ยึดตามโครงสร้างตารางเดิม `contractor_entries` และไม่เปลี่ยนแปลงข้อมูลในฐานข้อมูล

## 1. ความหมายของข้อมูล

- `time_out IS NULL` หรือค่าว่าง: ผู้รับเหมายังไม่ได้ลงทะเบียนออก ให้แสดงสถานะ **ยังอยู่ในพื้นที่**
- `time_out IS NOT NULL`: ผู้รับเหมาได้ลงทะเบียนออกแล้ว ให้แสดงสถานะ **ออกจากพื้นที่แล้ว**
- ห้ามเติม `time_out` อัตโนมัติ และห้ามอนุมานเวลาออกจาก `created_at` หรือเวลาอื่น
- `team_size` คือจำนวนคนในทีมของรายการนั้น ไม่ใช่จำนวนรายการผู้รับเหมา

## 2. ตัวเลขบน Dashboard

ควรแสดงอย่างน้อย 4 ค่า โดยแยกจำนวนรายการและจำนวนคนให้ชัดเจน

1. **รายการผู้รับเหมาที่ยังอยู่** — จำนวนแถวที่ `time_out IS NULL`
2. **จำนวนคนที่ยังอยู่ในพื้นที่** — ผลรวม `team_size` ของแถวที่ `time_out IS NULL`
3. **รายการที่ลงทะเบียนออกแล้ววันนี้** — จำนวนแถวที่ `work_date` เป็นวันที่รายงานและ `time_out IS NOT NULL`
4. **จำนวนผู้รับเหมาที่เข้าวันนี้** — จำนวนแถวที่ `work_date` เป็นวันที่รายงาน

ข้อสำคัญ: ตัวเลข “ยังอยู่ในพื้นที่ ณ ตอนนี้” ต้องไม่กรองเฉพาะ `work_date = วันนี้` เพราะอาจมีผู้รับเหมาที่เข้าวันก่อนและยังไม่ได้ลงทะเบียนออก

## 3. ตัวอย่าง SQL สำหรับ Dashboard

จำนวนรายการที่ยังอยู่ในพื้นที่:

```sql
select count(*) as onsite_entries
from public.contractor_entries
where time_out is null;
```

จำนวนคนในทีมที่ยังอยู่ในพื้นที่:

```sql
select coalesce(sum(team_size), 0) as onsite_team_members
from public.contractor_entries
where time_out is null;
```

## 4. ตัวอย่าง SQL สำหรับรายงานประจำวัน

ใช้วันที่ที่ผู้ใช้เลือกแทน `:report_date`:

```sql
select
  count(*) as total_entries,
  count(*) filter (where time_out is not null) as exited_entries,
  count(*) filter (where time_out is null) as still_on_site_entries,
  coalesce(sum(team_size), 0) as total_team_members,
  coalesce(sum(team_size) filter (where time_out is not null), 0) as exited_team_members,
  coalesce(sum(team_size) filter (where time_out is null), 0) as still_on_site_team_members
from public.contractor_entries
where work_date = :report_date;
```

## 5. รูปแบบการแสดงผลในตาราง

| Field | การแสดงผล |
|---|---|
| เวลาเข้า | ใช้ `time_in` |
| เวลาออก | ใช้ `time_out`; ถ้าว่างให้แสดง “ยังไม่ลงทะเบียนออก” |
| สถานะ | “ยังอยู่ในพื้นที่” เมื่อ `time_out` ว่าง; “ออกจากพื้นที่แล้ว” เมื่อมีค่า |
| จำนวนทีม | ใช้ `team_size` |
| วันที่ | ใช้ `work_date` สำหรับการกรองรายงานรายวัน |

## 6. ขอบเขตและความปลอดภัย

- เอกสารนี้เป็นข้อกำหนดการคำนวณ ไม่ได้รัน SQL และไม่ได้แก้ไขข้อมูลใน Supabase
- ก่อนเชื่อมต่อจริง ต้องตรวจสอบ RLS SELECT policy ของ `contractor_entries` และสิทธิ์ผู้ใช้ในแอป
- Dashboard และรายงานต้องแสดงสถานะว่าเป็นข้อมูลจริงหรือข้อมูลตัวอย่างอย่างชัดเจน
- ห้ามใช้ service role key ใน frontend
- การเชื่อมต่อจริงต้องใช้ project/ref และ credentials ที่ได้รับอนุญาตเท่านั้น
