//! Handle CPU states
//! 
//! States:
//! * Base
//! * Subroutine
//! * etc.
//! 
//! Essentially just defines CPU states for bytecode

// $Id: VJCpuState.zig

const std = @import("std");

pub const jade_CpuState = enum {
  base,
  subroutine,
};
