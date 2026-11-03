---
date: 2025-06-24
host: srv-prod-2
service: NextCloud
tags:
  - incident
status: open
---
# 🛠️ Incident – NextCloud not reachable

## 🧩 Problem

NextCloud not reachable after weekly flake update was rolled out.

## 🕵️ Root Cause

Collabora document server started in docker not available at nginx start up.
## 📜 Timeline / Log

- Logged into [[srv-prod-2]] and inspected systemd status. Nginx is down.
- Inspected nginx journal entries. Turns out it was not started because the docker dependency was not ready.
## ✅ Resolution Steps

- Restart nginx.

## 🔁 Follow-up
- [x] #todo/homelab Migrate to systemd based collabora document server deployment.