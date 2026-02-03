# Reorder Buffer (ROB) – Specification

## Overview

The Reorder Buffer (ROB) tracks in-flight operations, allows out-of-order completion,
and enforces in-order commit.

The ROB must ensure architectural state is updated in program order.

---

## Interfaces

### Dispatch
- Allocates a new ROB entry
- Dispatches occur in program order
- Dispatch may stall when ROB is full

### Completion
- Marks an entry as completed
- Completions may arrive in any order
- Completion does not immediately remove the entry

### Commit
- Commits completed entries
- Commit must occur in program order
- Only one entry may commit per cycle

---

## Functional Rules

- Entries are allocated sequentially
- Completed entries may wait before commit
- Younger entries must not commit before older ones
- The ROB must handle pointer wraparound correctly

---
