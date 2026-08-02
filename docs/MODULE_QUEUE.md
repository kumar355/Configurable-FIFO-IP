# Configurable FIFO IP

Version: 1.0

Status: Active Development

------------------------------------------------------------------------------

# Development Rules

Only one RTL module shall be actively developed at a time.

A module is considered complete only after

- RTL generation
- Architecture review
- Compilation
- Initial simulation
- Verification review
- Git commit

No dependent module shall begin until its prerequisite modules are complete.

------------------------------------------------------------------------------

# Module Status Legend

NOT_STARTED

IN_PROGRESS

GENERATED

REVIEW_REQUIRED

READY_TO_COMPILE

COMPILED

VERIFIED

COMPLETED

------------------------------------------------------------------------------

# Phase 1

Common RTL

------------------------------------------------------------------------------

Module

fifo_pkg.sv

Purpose

Shared package definitions

Dependencies

None

Current Status

COMPLETED

------------------------------------------------------------------------------

Module

fifo_mem.sv

Purpose

Reusable parameterized memory

Dependencies

fifo_pkg.sv

Current Status

COMPLETED

------------------------------------------------------------------------------

# Phase 2

Synchronous FIFO

------------------------------------------------------------------------------

Module

sync_fifo_ctrl.sv

Purpose

FIFO controller

Dependencies

fifo_pkg.sv

fifo_mem.sv

Current Status

NOT_STARTED

Priority

CRITICAL

------------------------------------------------------------------------------

Module

sync_fifo_top.sv

Purpose

Top level integration

Dependencies

sync_fifo_ctrl.sv

fifo_mem.sv

Current Status

NOT_STARTED

Priority

HIGH

------------------------------------------------------------------------------

# Phase 3

Asynchronous FIFO

------------------------------------------------------------------------------

Module

gray_counter.sv

Purpose

Gray code utilities

Dependencies

fifo_pkg.sv

Current Status

NOT_STARTED

Priority

HIGH

------------------------------------------------------------------------------

Module

synchronizer.sv

Purpose

Clock domain synchronizer

Dependencies

None

Current Status

NOT_STARTED

Priority

HIGH

------------------------------------------------------------------------------

Module

async_fifo_ctrl.sv

Purpose

Asynchronous FIFO controller

Dependencies

gray_counter.sv

synchronizer.sv

fifo_pkg.sv

fifo_mem.sv

Current Status

NOT_STARTED

Priority

CRITICAL

------------------------------------------------------------------------------

Module

async_fifo_top.sv

Purpose

Top level integration

Dependencies

async_fifo_ctrl.sv

fifo_mem.sv

Current Status

NOT_STARTED

Priority

HIGH

------------------------------------------------------------------------------

# Phase 4

Verification Environment

------------------------------------------------------------------------------

transaction.sv

NOT_STARTED

config.sv

NOT_STARTED

generator.sv

NOT_STARTED

driver.sv

NOT_STARTED

monitor.sv

NOT_STARTED

reference_model.sv

NOT_STARTED

scoreboard.sv

NOT_STARTED

environment.sv

NOT_STARTED

base_test.sv

NOT_STARTED

------------------------------------------------------------------------------

# Phase 5

Assertions

------------------------------------------------------------------------------

fifo_assertions.sv

NOT_STARTED

------------------------------------------------------------------------------

# Phase 6

Coverage

------------------------------------------------------------------------------

fifo_coverage.sv

NOT_STARTED

------------------------------------------------------------------------------

# Phase 7

Regression

------------------------------------------------------------------------------

directed_tests.sv

NOT_STARTED

random_tests.sv

NOT_STARTED

stress_tests.sv

NOT_STARTED

corner_case_tests.sv

NOT_STARTED

------------------------------------------------------------------------------

# Current Development Target

sync_fifo_ctrl.sv

------------------------------------------------------------------------------

# Repository Completion Checklist

Common RTL

COMPLETE

Synchronous FIFO

PENDING

Asynchronous FIFO

PENDING

Verification

PENDING

Assertions

PENDING

Coverage

PENDING

Regression

PENDING

Documentation

IN_PROGRESS

------------------------------------------------------------------------------

# Claude Instructions

Before generating any RTL

Read

CLAUDE.md

Read

docs/PROJECT_SPEC.md

Read

docs/MODULE_QUEUE.md

Read every dependency of the requested module.

Generate only one module.

Do not modify completed modules.

If a required dependency is missing

Stop.

Report the missing dependency.

Do not invent architecture.

------------------------------------------------------------------------------

# Next Module

rtl/sync/sync_fifo_ctrl.sv

------------------------------------------------------------------------------