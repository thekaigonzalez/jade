//! Framework to bind OpCodes to Zig functions
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJRuntime.zig

const std = @import("std");

const jade_Cpu = @import("VJCpu.zig").jade_Cpu;
const jade_Walker32 = @import("VJWalk.zig").jade_Walker32;

/// ## Runtimes
///
/// A 32-bit runtime
///
/// Allows the binding of 32-bit (4-byte wide) opcodes to Zig functionalities.
///
/// For 8-bit (1-byte wide) opcodes, use the 8-bit runtime, or cast the 8-bit
/// opcodes to 32-bit.
pub const jade_32BitRuntime = struct {
    runtime: std.AutoHashMap(i32, *const fn (*jade_Cpu, *?jade_Walker32) i32),
    parent: std.mem.Allocator,

    pub fn new(page: std.mem.Allocator) jade_32BitRuntime {
        return jade_32BitRuntime{
            .runtime = std.AutoHashMap(i32, *const fn (*jade_Cpu, *?jade_Walker32) i32).init(page),
            .parent = page,
        };
    }

    pub fn feature(self: *jade_32BitRuntime, feat: i32) !void {
        try self.runtime.contains(feat);
    }

    pub fn bind(self: *jade_32BitRuntime, key: i32, value: *const fn (*jade_Cpu, *?jade_Walker32) i32) !void {
        try self.runtime.put(key, value);
    }

    pub fn get(self: *jade_32BitRuntime, key: i32) *const fn (*jade_Cpu, *?jade_Walker32) i32 {
        return self.runtime.get(key).?;
    }

    pub fn deinit(self: *jade_32BitRuntime) void {
        self.runtime.deinit();
    }
};
