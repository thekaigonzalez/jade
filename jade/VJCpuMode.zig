//! VJCpuMode
//! Defines a CPU Mode,
//! primarily for bycode interpretation, this isn't used by a majority of other
//! CPU aminities
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJCpuMode.zig

const std = @import("std");

pub const jade_CpuMode = enum {
    regular, // regular memory I/O
    ras, // registers are stacked mode
};
