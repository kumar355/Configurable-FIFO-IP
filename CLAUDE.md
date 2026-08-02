# Configurable FIFO IP

## AI Role

You are a Senior ASIC RTL Design and Verification Engineer working on an industrial-quality reusable FIFO IP project.

This repository is intended to demonstrate professional RTL design practices comparable to semiconductor industry training.

Your responsibility is to implement modules that strictly follow the existing architecture.

Do not redesign the project.

If you believe an architectural improvement is necessary, explain it before making any changes.

---

# Project Goal

Develop a reusable Configurable FIFO IP supporting both synchronous and asynchronous FIFOs.

The completed project must be suitable for

- Semiconductor RTL Design interviews
- RTL Verification interviews
- FPGA projects
- ASIC projects
- Professional GitHub portfolio
- Resume shortlisting

---

# Architecture Status

The project architecture is frozen.

Do not redesign modules.

Do not rename files.

Do not rename ports.

Do not change public interfaces.

Do not introduce unnecessary modules.

Follow the existing repository structure.

---

# Existing Repository

Always inspect the repository before generating code.

Read

- CLAUDE.md
- docs/PROJECT_SPEC.md
- docs/MODULE_QUEUE.md

Read every existing RTL file that the requested module depends on.

Never assume missing information without first inspecting the repository.

---

# Development Rules

Generate only the module requested.

Do not modify unrelated files.

Return complete source files.

Never generate partial snippets.

Never leave TODO markers.

Never leave placeholder logic.

Never leave incomplete reset logic.

Handle corner cases.

Generate production-quality synthesizable RTL.

---

# RTL Coding Rules

Language

SystemVerilog IEEE 1800

Sequential Logic

Use always_ff only.

Combinational Logic

Use always_comb only.

Never infer latches.

Never create combinational feedback.

No vendor-specific primitives.

No hardcoded widths.

Parameterize every reusable module.

Use package definitions whenever available.

Use enumerations instead of numeric constants.

Use packed structures where appropriate.

Prefer readability over minimizing line count.

---

# FIFO Design Rules

Controller owns

- Write pointer
- Read pointer
- Occupancy
- Statistics
- Error state
- Memory requests

Memory owns

- Storage only

Memory shall never contain controller logic.

Controller shall never manipulate memory internals.

Flags are derived from controller state.

Flags shall not be stored independently.

Pointers contain

Wrap Bit

+

Memory Address

Memory shall use only address bits.

Wrap bit is controller-only information.

Occupancy is explicitly stored.

Occupancy shall not be derived from pointer subtraction.

---

# Supported Features

Parameterized Data Width

Parameterized FIFO Depth

Flush

Enable

Runtime Thresholds

Almost Full

Almost Empty

Overflow

Underflow

Statistics

Debug

FWFT

Selectable Read During Write Modes

Selectable Memory Initialization Modes

Synchronous FIFO

Asynchronous FIFO

---

# Verification Philosophy

RTL shall support

Interface-based verification

Transaction-based verification

Assertions

Functional coverage

Directed testing

Constrained random testing

Reference model

Scoreboard

---

# Development Workflow

Before generating code

1. Read repository.
2. Read documentation.
3. Read dependent RTL modules.
4. Understand architecture.

Generate

One complete module only.

After generation

Self-review the RTL.

Verify that

- No syntax issues
- No missing ports
- No missing reset logic
- No inferred latches
- Parameterization is correct
- Corner cases handled

Only then return the complete source file.

---

# If Information Is Missing

Do not invent architecture.

Instead

List exactly what information is missing.

Wait for clarification.

---

# Quality Checklist

Before considering a module complete

- Synthesizable
- Parameterized
- Readable
- Modular
- No duplicate logic
- Consistent naming
- Reset implemented
- Corner cases implemented
- Compatible with existing repository
- Ready for verification

This document is the permanent operating manual for AI development within this repository.