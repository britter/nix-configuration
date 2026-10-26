---
name: calculations
description: Rules for computing arithmetic reliably — never calculate in your head, use bc or Python, mind base-10 vs base-2 units, show the full computation chain. Use whenever a task involves any non-trivial calculation, unit conversion, or file/disk size math (MB vs MiB, parted vs du, storage sizing, benchmark numbers).
---

# Calculations

Never generate arithmetic results from memory — LLM arithmetic is
unreliable. Compute every non-trivial calculation by calling a
program: `bc -l` (`nix run nixpkgs#bc -- -l <<< "2+2"` when not on
PATH), or a small Python script for anything involving units or
formatting.

File and disk sizes: mind the base. SI units (MB, GB, TB) are base
10, binary units (MiB, GiB, TiB) are base 2. Tools disagree:
`parted`, disk vendors, and marketing use base 10; `ls -h`, `du -h`,
and `df -h` show base 2. Always state which base you computed with
and match it to the tool you are feeding.

When calculating, show the full chain: the expression handed to the
calculator, its raw output, and the intermediate results leading to
the final number. No unexplained jumps.
