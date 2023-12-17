//! VJOpFlags
//! 
//! Defines optimization flags
//! -O0 disables all optimizations
//! -O2 is basic optimization
//! -Ofast is the fastest possible optimization
//! 
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅
// $Id: VJOpFlags.zig

const std = @import("std");

/// none - no optimization
/// level2 - basic optimization
/// aggressive - aggressive optimization
pub const jade_OptimizationFlags = enum {
  none,
  level2,
  aggressive,
};
