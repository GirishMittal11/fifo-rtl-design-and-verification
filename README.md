# FIFO RTL Design and Verification

A Verilog project containing three FIFO architectures, with RTL implementations and directed simulation testbenches:

1. **Standard synchronous FIFO** — circular-buffer storage with read and write pointers.
2. **Fall-through synchronous FIFO** — shift-register-style storage with the oldest word presented directly at the output.
3. **Asynchronous FIFO** — independent read and write clock domains, binary/Gray-coded pointers, and pointer synchronizers.

The project is intended to demonstrate RTL design, simulation, and verification of FIFO control behaviour.

## Repository structure

```text
fifo-rtl-design-and-verification/
├── Asynchronous FIFO/
│   ├── fifo_async.v
│   ├── fifo_mem.v
│   ├── rptr_empty.v
│   ├── wptr_full.v
│   ├── sync_r2w.v
│   ├── sync_w2r.v
│   └── Testbench_fifo_async.v
│
├── Synchronous FIFO/
│   ├── Standard FIFO/
│   │   ├── sync_fifo.v
│   │   └── Testbench_Sync_Fifo.v
│   │
│   └── Fall Through FIFO/
│       ├── FF_fifo.v
│       └── Testbench_Fall_fifo.v
│
└── .gitignore
```

## 1. Standard synchronous FIFO

**RTL:** `Synchronous FIFO/Standard FIFO/sync_fifo.v`  
**Testbench:** `Synchronous FIFO/Standard FIFO/Testbench_Sync_Fifo.v`

This FIFO uses a circular memory array and separate read and write pointers. The pointer width includes an additional wrap bit so the control logic can distinguish a full FIFO from an empty FIFO when the address portions of the pointers match.

Main interface behaviour:

- A write is accepted when `wr_en` is asserted and `full` is deasserted.
- A read is accepted when `rd_en` is asserted and `empty` is deasserted.
- The empty condition is determined from the read and write pointers.
- The full condition is determined using the pointer address and wrap-bit relationship.
- The read output is registered on an accepted read operation.

The RTL is parameterised for data width and FIFO depth. The pointer/full logic is intended for power-of-two FIFO depths.

### Simulation

Run these commands from the repository root in PowerShell:

```powershell
iverilog -g2012 -s Testbench_Sync_Fifo -o standard_fifo_sim.vvp "Synchronous FIFO/Standard FIFO/sync_fifo.v" "Synchronous FIFO/Standard FIFO/Testbench_Sync_Fifo.v"
vvp standard_fifo_sim.vvp
```

The testbench is intended to exercise reset, filling the FIFO, a write attempt while full, reading stored values in order, and the empty condition after draining.

## 2. Fall-through synchronous FIFO

**RTL:** `Synchronous FIFO/Fall Through FIFO/FF_fifo.v`  
**Testbench:** `Synchronous FIFO/Fall Through FIFO/Testbench_Fall_fifo.v`

This implementation uses shift-register-style storage rather than circular read and write pointers.

Main design features:

- `count` tracks the number of stored words.
- `full` is asserted when the occupancy reaches `DEPTH`; `empty` is asserted when the occupancy is zero.
- The oldest stored word is held at the output end of the storage array and is presented directly on `r_data`.
- A write-only operation inserts a word into the next available storage position.
- A read-only operation removes the oldest word and shifts the remaining words toward the output.
- A simultaneous accepted read and write replaces the consumed word while preserving occupancy.

This is a single-clock FIFO. “Fall-through” describes its output behaviour; it does not mean the FIFO is asynchronous.

### Simulation

Run these commands from the repository root in PowerShell:

```powershell
iverilog -g2012 -s Testbench_Fall_fifo -o fall_through_sim.vvp "Synchronous FIFO/Fall Through FIFO/FF_fifo.v" "Synchronous FIFO/Fall Through FIFO/Testbench_Fall_fifo.v"
vvp fall_through_sim.vvp
```

The testbench is intended to exercise reset, filling the FIFO, a write attempt while full, reading values in order, and the empty condition after draining. Inputs are driven away from the DUT's active sampling edge to avoid testbench/DUT race conditions.

## 3. Asynchronous FIFO

**Top-level RTL:** `Asynchronous FIFO/fifo_async.v`  
**Testbench:** `Asynchronous FIFO/Testbench_fifo_async.v`

This FIFO has independent write and read clock domains (`wclk` and `rclk`). Its storage depth is determined by `ADDRSIZE`, with a depth of `2**ADDRSIZE` words.

The RTL is split into functional blocks:

- `fifo_mem.v` — storage array and data access.
- `wptr_full.v` — write-side binary and Gray-coded pointers and full-flag logic.
- `rptr_empty.v` — read-side binary and Gray-coded pointers and empty-flag logic.
- `sync_r2w.v` — synchronises the read pointer into the write-clock domain.
- `sync_w2r.v` — synchronises the write pointer into the read-clock domain.

Binary pointers are used for memory addressing. Gray-coded pointers are transferred across clock domains because adjacent Gray-code values differ by one bit. Each clock domain uses a two-stage synchronizer for the pointer received from the opposite domain. The full and empty flags are generated locally using the next Gray-coded pointer and the synchronised pointer.

The reset connections for both pointer synchronizers should be maintained when modifying the top-level module. The full-flag implementation assumes `ADDRSIZE >= 2`.

### Simulation

Run these commands from the repository root in PowerShell:

```powershell
iverilog -g2012 -s Testbench_fifo_async -o async_fifo_sim.vvp "Asynchronous FIFO/fifo_async.v" "Asynchronous FIFO/fifo_mem.v" "Asynchronous FIFO/rptr_empty.v" "Asynchronous FIFO/wptr_full.v" "Asynchronous FIFO/sync_r2w.v" "Asynchronous FIFO/sync_w2r.v" "Asynchronous FIFO/Testbench_fifo_async.v"
vvp async_fifo_sim.vvp
```

The testbench uses independent read and write clocks and is intended to exercise reset, filling, full/empty behaviour, reading stored data, and pointer wrap-around. It also includes a simulation timeout guard.

## Tools

- **Verilog HDL** — RTL and testbench source.
- **Icarus Verilog** — compilation and simulation.
- **GTKWave** — optional waveform inspection when the testbench writes a VCD file.

For example, to open a generated waveform:

```powershell
gtkwave wave.vcd
```

## Verification status and limitations

The directed testbenches have been developed for execution using Icarus Verilog. Simulation should be rerun after any RTL or testbench modifications.


- formal verification of all possible input sequences;
- CDC sign-off or quantified metastability reliability;
- synthesis results, resource utilisation, or timing closure;
- FPGA/ASIC implementation or hardware validation.

Those would require additional verification and implementation steps. No synthesis, timing, FPGA, ASIC, or silicon results are claimed in this repository.

