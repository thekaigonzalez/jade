// $Id: VJClassicRuntime.zig

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
/// This is different from the normal runtime, because it uses a list of bytes
/// gotten from a delimiter, for modern bytecode you would use the normal runtime
///
/// For 8-bit (1-byte wide) opcodes, use the 8-bit runtime, or cast the 8-bit
/// opcodes to 32-bit.
pub const jade_32BitOldRuntime = struct {
    runtime: std.AutoHashMap(i32, *const fn (*jade_Cpu, std.ArrayList(i32)) i32),
    parent: std.mem.Allocator,

    pub fn new(page: std.mem.Allocator) jade_32BitOldRuntime {
        return jade_32BitOldRuntime{
            .runtime = std.AutoHashMap(i32, *const fn (*jade_Cpu, std.ArrayList(i32)) i32).init(page),
            .parent = page,
        };
    }

    pub fn feature(self: *jade_32BitOldRuntime, feat: i32) bool {
        return self.runtime.contains(feat);
    }

    pub fn bind(self: *jade_32BitOldRuntime, key: i32, value: *const fn (*jade_Cpu, std.ArrayList(i32)) i32) !void {
        try self.runtime.put(key, value);
    }

    pub fn get(self: *jade_32BitOldRuntime, key: i32) *const fn (*jade_Cpu, std.ArrayList(i32)) i32 {
        return self.runtime.get(key).?;
    }

    pub fn deinit(self: *jade_32BitOldRuntime) void {
        self.runtime.deinit();
    }
};

