# Configurable FIFO IP

Version: 1.0

Status: Frozen

Project Type: Reusable RTL IP

Language: SystemVerilog IEEE 1800

------------------------------------------------------------------------------

# 1. Project Overview

The Configurable FIFO IP is an industrial-quality reusable FIFO library
supporting both synchronous and asynchronous FIFO implementations.

The project is intended to demonstrate professional RTL Design and
Verification methodology suitable for semiconductor interviews, FPGA
development and ASIC development.

The repository shall emphasize modularity, parameterization, portability,
verification readiness and maintainability.

------------------------------------------------------------------------------

# 2. Project Objectives

The project shall satisfy the following objectives.

Functional Objectives

- Support synchronous FIFO.
- Support asynchronous FIFO.
- Support configurable data width.
- Support configurable FIFO depth.
- Support runtime programmable thresholds.
- Support First Word Fall Through mode.
- Support selectable memory read during write modes.
- Support configurable memory initialization.

Engineering Objectives

- Produce reusable synthesizable RTL.
- Produce reusable verification components.
- Maintain modular architecture.
- Follow professional coding standards.
- Produce interview quality documentation.
- Maintain repository consistency.

------------------------------------------------------------------------------

# 3. Repository Structure

docs/

Project documentation

rtl/

RTL implementation

rtl/common/

Reusable modules

rtl/sync/

Synchronous FIFO implementation

rtl/async/

Asynchronous FIFO implementation

interfaces/

SystemVerilog interfaces

tb/

Verification environment

assertions/

SystemVerilog Assertions

coverage/

Functional coverage

scripts/

Simulation automation

sim/

Simulation files

waveforms/

Waveform outputs

reports/

Simulation reports

------------------------------------------------------------------------------

# 4. Supported Features

The final project shall support

- Synchronous FIFO
- Asynchronous FIFO
- Parameterized Data Width
- Parameterized FIFO Depth
- Runtime Almost Full Threshold
- Runtime Almost Empty Threshold
- Flush
- Enable
- Simultaneous Read and Write
- Overflow Detection
- Underflow Detection
- Peak Occupancy Counter
- Read Counter
- Write Counter
- Overflow Counter
- Underflow Counter
- Debug Information
- First Word Fall Through
- Configurable Memory Initialization
- Configurable Read During Write Policy

------------------------------------------------------------------------------

# 5. Module List

Common RTL

fifo_pkg.sv

Shared package definitions.

fifo_mem.sv

Reusable parameterized memory.

Synchronous RTL

sync_fifo_ctrl.sv

Controller implementation.

sync_fifo_top.sv

Top-level integration.

Asynchronous RTL

gray_counter.sv

Gray code utilities.

synchronizer.sv

Clock domain synchronizer.

async_fifo_ctrl.sv

Asynchronous controller.

async_fifo_top.sv

Top-level integration.

------------------------------------------------------------------------------

# 6. Design Principles

The following principles shall never be violated.

- One module shall own one primary responsibility.
- Memory shall only store data.
- Controller shall own all FIFO state.
- Flags shall be derived.
- Occupancy shall be explicitly stored.
- Pointer wrap information shall remain inside the controller.
- Memory shall only receive address bits.
- Every reusable block shall be parameterized.
- All RTL shall be synthesizable.
- Vendor-specific primitives are prohibited.
- Readability shall be preferred over minimizing code size.

------------------------------------------------------------------------------

# 7. Functional Requirements

The FIFO shall preserve data ordering.

The FIFO shall never corrupt stored data.

The FIFO shall support simultaneous read and write.

The FIFO shall prevent illegal occupancy values.

The FIFO shall detect overflow.

The FIFO shall detect underflow.

The FIFO shall support runtime threshold programming.

The FIFO shall support flush.

The FIFO shall support enable control.

The FIFO shall support deterministic reset behavior.

------------------------------------------------------------------------------

# 8. Non Functional Requirements

The RTL shall

- Compile without syntax errors.
- Be synthesizable.
- Be parameterized.
- Avoid inferred latches.
- Avoid combinational loops.
- Use meaningful signal names.
- Use meaningful comments.
- Support FPGA synthesis.
- Support ASIC synthesis.

------------------------------------------------------------------------------

# 9. Verification Requirements

The project shall include

- Transaction class
- Generator
- Driver
- Monitor
- Scoreboard
- Reference Model
- Environment
- Directed Tests
- Random Tests
- Assertions
- Functional Coverage
- Regression Tests

------------------------------------------------------------------------------

# 10. Deliverables

The completed repository shall contain

- Complete RTL
- Complete Verification Environment
- Assertions
- Coverage
- Documentation
- Simulation Scripts
- Waveforms
- GitHub Repository

------------------------------------------------------------------------------

# 11. Acceptance Criteria

The project shall be considered complete only when

- All RTL modules compile successfully.
- All verification components compile successfully.
- Directed tests pass.
- Random tests pass.
- Assertions pass.
- Functional coverage targets are achieved.
- No known architectural inconsistencies remain.
- Repository documentation is complete.

------------------------------------------------------------------------------

# 12. Development Policy

Architecture is frozen.

Modules shall be implemented one at a time.

Every generated module shall be reviewed before integration.

No module shall modify another completed module without explicit approval.

Documentation shall remain synchronized with implementation.

------------------------------------------------------------------------------