---
date: 2025-01-08
host: srv-test-2
service: Postgres
tags:
  - incident
  - postgres
  - collation
status: resolved
---
# 🛠️ Incident – Postgres Collation Mismatch on `srv-test-2`

## 🧩 Problem

[[Postgres]] on [[srv-test-2]] failed to start. The `ExecPostStart` script (used for `ensureDatabase` logic for [[Vaultwarden]] and [[NextCloud]]) triggered an error on launch.

## 🕵️ Root Cause

A collation version mismatch in the `template1` database caused startup issues for PostgreSQL.

## 📜 Timeline / Log

- PostgreSQL failed to start on `srv-test-2`
- Error appeared in logs via `journalctl -xeu postgresql`:
  ```text
  ERROR: database "nextcloud" has a collation version mismatch
  ```
- Temporary workaround: Disabled the `ensureDatabase` statements for `srv-test-2` to allow startup.
- Investigated the collation mismatch using psql.
## ✅ Resolution Steps

### 1. Investigate Errors
```
journalctl -xeu postgresql
```
### 2. Log into Postgres
```
sudo -u postgres psql
```
### 3. Find Affected Objects
```sql
SELECT *
FROM pg_collation
WHERE collversion IS NOT NULL
  AND collversion <> pg_collation_actual_version(oid);
```
### 4. Connect to the affected database
```
\c nextcloud
```
### 5. Fix the Database
```sql
ALTER DATABASE nextcloud REFRESH COLLATION VERSION;
REINDEX DATABASE nextcloud;
```
## 🔁 Follow-up
- [ ] Consider making `ExecPostStart` failure-tolerant for non-critical issues
- [ ] Test collation version during host provisioning
