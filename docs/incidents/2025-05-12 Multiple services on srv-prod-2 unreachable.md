---
date: 2025-05-12
host: srv-prod-2
services:
  - NextCloud
  - git
tags:
  - incident
status: open
---
# 🛠️ Incident – Multiple services on srv-prod-2 unavailable

## 🧩 Problem

[[NextCloud]] and [[git server|git]] are not reachable.

## 🕵️ Root Cause

[[pve]] crashed and all VM disconnected from the network due to that.
## 📜 Timeline / Log

- Try to SSH into the host - not possible
- Try to ping to host - not possible
- Hypothesis: Either the VM is down or Proxmox is down.
- Try [[Proxmox]] via web UI - not possible
- Checked [[FritzBox]] and it turns out that [[pve]] is not connected
## ✅ Resolution Steps

1. Hardware reset of [[pve]].
## 🔁 Follow-up
- [ ] Consider connecting [[pve]] to [[JetKVM]].