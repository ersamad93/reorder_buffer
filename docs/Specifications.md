# Reorder Buffer (ROB) – Specification

## Overview

The Reorder Buffer (ROB) tracks in-flight operations, allows out-of-order completion,
and enforces in-order commit.

The ROB must ensure architectural state is updated in program order.

