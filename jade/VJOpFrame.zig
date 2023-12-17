//! VJOpFrame
//! Handles optimization of bytecode
//! a simple growable list with the capability of replicating either 32-bit or
//! 8-bit instructions, allowing unfolding to generate seemingly
//! identical bytecode
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJOpFrame.zig

const std = @import("std");

/// ## Optimization Frames
///
/// To generate a similar bytecode structure, primarily used for optimizing or
/// replicating similar bytecode.
///
/// ## Unfold
///
/// Supports unfolding, for example, loading a subroutine's bytecode and unfolding
/// it
///
/// ```
/// bytes = cpu.get_section(12345);
///
/// opframe.unfold(bytes); // instead of adding a jump call to 12345, replace
///                        // the code with the actual bytecode to optimize it
/// ```
///
/// ### 32-bit & 8-bit
///
/// NOTE: this struct supports 32-bit and 8-bit CPU modes

pub const jade_OpFrame32 = struct {
    frame: std.ArrayList(i32),

    pub fn create(allocator: std.mem.Allocator) jade_OpFrame32 {
        return jade_OpFrame32{ .frame = std.ArrayList(i32).init(allocator) };
    }

    pub fn deinit(self: *jade_OpFrame32) void {
        self.frame.deinit();
    }

    pub fn unfold(self: *jade_OpFrame32, bytes: []i32) void {
        for (0..bytes.len) |i| {
            self.frame.append(bytes[i]) catch {
                std.debug.panic("jade: unfold: failed to append to opframe", .{});
            };
        }
    }

    pub fn unfold1(self: *jade_OpFrame32, bytes: []i32) void {
        for (0..bytes.len) |i| {
            if (bytes[i] == 0) continue;
            
            self.frame.append(bytes[i]) catch {
                std.debug.panic("jade: unfold: failed to append to opframe", .{});
            };
        }
    }

    pub fn get_frame(self: *jade_OpFrame32) []i32 {
        return self.frame.items;
    }

    pub fn len(self: *jade_OpFrame32) usize {
        return self.frame.items.len;
    }

    pub fn pop(self: *jade_OpFrame32) i32 {
        return self.frame.pop();
    }

    pub fn push(self: *jade_OpFrame32, value: i32) void {
        self.frame.append(value) catch {
            std.debug.panic("jade: push: failed to append to opframe", .{});
        };
    }

    pub fn destroy(self: *jade_OpFrame32) void {
        self.deinit();
    }
};
pub const jade_OpFrame8 = struct {
    frame: std.ArrayList(i8),

    pub fn create(allocator: std.mem.Allocator) jade_OpFrame8 {
        return jade_OpFrame8{ .frame = std.ArrayList(i8).init(allocator) };
    }

    pub fn deinit(self: *jade_OpFrame8) void {
        self.frame.deinit();
    }

    pub fn unfold(self: *jade_OpFrame8, bytes: []i8) void {
        for (0..bytes.len) |i| {
            self.frame.append(bytes[i]) catch {
                std.debug.panic("jade: unfold: failed to append to opframe", .{});
            };
        }
    }

    pub fn get_frame(self: *jade_OpFrame8) []i8 {
        return self.frame.items;
    }

    pub fn len(self: *jade_OpFrame8) usize {
        return self.frame.items.len;
    }

    pub fn pop(self: *jade_OpFrame8) i8 {
        return self.frame.pop();
    }

    pub fn push(self: *jade_OpFrame8, value: i8) void {
        self.frame.append(value) catch {
            std.debug.panic("jade: push: failed to append to opframe", .{});
        };
    }

    pub fn destroy(self: *jade_OpFrame8) void {
        self.deinit();
    }
};

