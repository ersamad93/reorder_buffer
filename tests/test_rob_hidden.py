"""Hidden tests for the ROB (Reorder Buffer) module."""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer


@cocotb.test()
async def test_reset(dut):
    """Test that reset puts ROB in correct initial state."""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.disp_valid.value = 0
    dut.cpl_valid.value = 0
    dut.commit_ready.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # After reset: disp_ready should be 1 (ROB empty), commit_valid should be 0
    assert dut.disp_ready.value == 1, f"Expected disp_ready=1 after reset, got {dut.disp_ready.value}"
    assert dut.commit_valid.value == 0, f"Expected commit_valid=0 after reset, got {dut.commit_valid.value}"


@cocotb.test()
async def test_single_dispatch_complete_commit(dut):
    """Test single entry: dispatch -> complete -> commit."""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.disp_valid.value = 0
    dut.cpl_valid.value = 0
    dut.commit_ready.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Dispatch entry 0
    dut.disp_valid.value = 1
    await RisingEdge(dut.clk)
    assert dut.disp_tag.value == 0, f"Expected disp_tag=0, got {dut.disp_tag.value}"

    dut.disp_valid.value = 0
    await RisingEdge(dut.clk)

    # Complete entry 0
    dut.cpl_valid.value = 1
    dut.cpl_tag.value = 0
    await RisingEdge(dut.clk)

    dut.cpl_valid.value = 0
    await RisingEdge(dut.clk)

    # Now commit_valid should be 1, commit_tag=0
    assert dut.commit_valid.value == 1, f"Expected commit_valid=1, got {dut.commit_valid.value}"
    assert dut.commit_tag.value == 0, f"Expected commit_tag=0, got {dut.commit_tag.value}"

    # Commit
    dut.commit_ready.value = 1
    await RisingEdge(dut.clk)
    dut.commit_ready.value = 0
    await RisingEdge(dut.clk)

    # After commit, commit_valid should be 0
    assert dut.commit_valid.value == 0, f"Expected commit_valid=0 after commit, got {dut.commit_valid.value}"


@cocotb.test()
async def test_multiple_dispatches_in_order(dut):
    """Test multiple dispatches and in-order commit."""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.disp_valid.value = 0
    dut.cpl_valid.value = 0
    dut.commit_ready.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Dispatch 3 entries
    for i in range(3):
        dut.disp_valid.value = 1
        await RisingEdge(dut.clk)
        assert dut.disp_tag.value == i, f"Expected disp_tag={i}, got {dut.disp_tag.value}"
    dut.disp_valid.value = 0
    await RisingEdge(dut.clk)

    # Complete all 3 in order
    for i in range(3):
        dut.cpl_valid.value = 1
        dut.cpl_tag.value = i
        await RisingEdge(dut.clk)
    dut.cpl_valid.value = 0
    await RisingEdge(dut.clk)

    # Commit all 3 in order
    for i in range(3):
        assert dut.commit_valid.value == 1, f"Expected commit_valid=1 at step {i}"
        assert dut.commit_tag.value == i, f"Expected commit_tag={i}, got {dut.commit_tag.value}"
        dut.commit_ready.value = 1
        await RisingEdge(dut.clk)
        dut.commit_ready.value = 0
        await RisingEdge(dut.clk)

    assert dut.commit_valid.value == 0, "Expected commit_valid=0 after all commits"


@cocotb.test()
async def test_out_of_order_completion(dut):
    """Test out-of-order completion: dispatch 0,1,2 then complete 2,0,1 - commit must be 0,1,2."""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.disp_valid.value = 0
    dut.cpl_valid.value = 0
    dut.commit_ready.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Dispatch 0, 1, 2
    for i in range(3):
        dut.disp_valid.value = 1
        await RisingEdge(dut.clk)
    dut.disp_valid.value = 0
    await RisingEdge(dut.clk)

    # Complete out of order: 2, 0, 1
    for tag in [2, 0, 1]:
        dut.cpl_valid.value = 1
        dut.cpl_tag.value = tag
        await RisingEdge(dut.clk)
    dut.cpl_valid.value = 0
    await RisingEdge(dut.clk)

    # Commit must be in order: 0, 1, 2
    for expected_tag in [0, 1, 2]:
        assert dut.commit_valid.value == 1, f"Expected commit_valid=1"
        assert dut.commit_tag.value == expected_tag, (
            f"Expected commit_tag={expected_tag} (in-order), got {dut.commit_tag.value}"
        )
        dut.commit_ready.value = 1
        await RisingEdge(dut.clk)
        dut.commit_ready.value = 0
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_full_rob_disp_ready(dut):
    """Test that disp_ready goes low when ROB is full (DEPTH=8)."""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.disp_valid.value = 0
    dut.cpl_valid.value = 0
    dut.commit_ready.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Dispatch 8 entries to fill ROB
    for i in range(8):
        dut.disp_valid.value = 1
        await RisingEdge(dut.clk)
        assert dut.disp_tag.value == i, f"Expected disp_tag={i}, got {dut.disp_tag.value}"

    dut.disp_valid.value = 0
    await RisingEdge(dut.clk)

    # ROB should be full, disp_ready = 0
    assert dut.disp_ready.value == 0, f"Expected disp_ready=0 when full, got {dut.disp_ready.value}"


# REQUIRED: Pytest wrapper function
def test_rob_hidden_runner():
    import os
    from pathlib import Path
    from cocotb_tools.runner import get_runner

    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent

    sources = [proj_path / "sources/rob.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="rob",
        always=True,
    )
    runner.test(
        hdl_toplevel="rob",
        test_module="test_rob_hidden",
    )
