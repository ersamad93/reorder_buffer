# Reorder Buffer (ROB) – Specification

## Overview

The Reorder Buffer (ROB) tracks in-flight operations, allows out-of-order completion,
and enforces in-order commit.

The ROB must ensure architectural state is updated in program order.

---

## Interfaces

### Dispatch
- Dispatches occur in program order

### Completion
- Completions may arrive in any order

### Commit
- Commit must occur in program order

---

## Functional Rules

- Entries are allocated sequentially
- Completed entries may wait before commit

---
