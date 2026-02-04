# Reorder Buffer (ROB) - Verilog Problem

HUD evaluation problem for implementing a Reorder Buffer module in SystemVerilog.

## Structure

- `sources/rob.sv` - The ROB module (baseline: empty, golden: complete implementation)
- `tests/test_rob_hidden.py` - Hidden cocotb tests with pytest wrapper

## Significance

- The Reorder Buffer is the Backbone of a Processor.
- A CPU requires out-of-order instruction execution, but it must commit the results in order (to maintain dependency)
- Reorder Buffer is the structure that reconciles these conflicting requirements.

## Industry Usage

- Processors (x86 cores, RISC-V OoO cores)
- Network on Chip (AXI4)
