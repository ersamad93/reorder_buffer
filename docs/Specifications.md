# Reorder Buffer (ROB) — Specification

## Overview
The Reorder Buffer (ROB) tracks in-flight operations, allows out-of-order completion, and enforces strictly in-order commit.

Only the oldest completed entry may commit.

---

## Interfaces

### Dispatch (In-order)
- `disp_valid`, `disp_ready`
- `disp_tag`

Rules:
- Allocate one entry when `disp_valid && disp_ready`
- Entries are allocated in order
- No dispatch when ROB is full

---

### Completion (Out-of-order)
- `cpl_valid`
- `cpl_tag`

Rules:
- Marks an entry as completed
- Completions may arrive in any order
- Completion does not free the entry

---

### Commit (In-order)
- `commit_valid`, `commit_ready`
- `commit_tag`

Rules:
- Commit occurs when `commit_valid && commit_ready`
- Only the oldest completed entry may commit
- At most one commit per cycle

---

## Key Rules

- Commit order must match dispatch order
- Younger entries must never commit before older ones
- Pointer wraparound must not break ordering
- Dispatch, completion, and commit may occur in the same cycle

---

## Corner Cases

- Out-of-order completion with older entries incomplete
- Full ROB blocks dispatch
- Empty ROB blocks commit
- Commit stalled by `commit_ready == 0`
- Pointer wraparound with in-flight entries

---

## Reset

On active-low reset:
- All entries invalid
- All completion flags cleared
- Allocation and commit pointers set to zero
- ROB empty and ready to accept dispatches
