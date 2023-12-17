//! Handle CPU states
//! 
//! States:
//! * Base
//! * Subroutine
//! * etc.
//! 
//! Essentially just defines CPU states for bytecode
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅
//! 

// $Id: VJCpuState.zig

const std = @import("std");

pub const jade_CpuState = enum {
  base,
  subroutine,
};
