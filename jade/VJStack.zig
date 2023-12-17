//! Stack used by JADE
//! Primarily used in RASterized mode
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅
//!

// $Id: VJStack.zig

const std = @import("std");

pub const jade_Stack = struct {
    stack: []i32, // holds any number values
    length: usize = 0,
    allocator: std.mem.Allocator,

    pub fn create(page: std.mem.Allocator, _size: usize) jade_Stack {
        var stack = jade_Stack{
            .stack = page.alloc(i32, _size) catch undefined, 
            .length = 0,
            .allocator = page,
        };

        for (0.._size) |i| {
            stack.stack[i] = 0;
        }

        return stack;
    }

    pub fn push(self: *jade_Stack, value: i32) void {
        if (self.length >= self.stack.len) {
            self.stack = self.allocator.realloc(self.stack, self.stack.len * 2) catch {
                std.debug.print("jade: error: out of memory\n", .{});
                std.process.exit(1);
            };

            for (self.stack.len..self.stack.len * 2) |i| {
                self.stack[i] = 0;
            }
        }
        self.stack[self.length] = value;
        self.length += 1;
    }

    pub fn pop(self: *jade_Stack) i32 {
        self.length -= 1;

        const byte = self.stack[self.length];

        self.stack[self.length] = 0;
        return byte;
    }

    pub fn peek(self: *jade_Stack) i32 {
        return self.stack[self.length - 1];
    }

    pub fn clear(self: *jade_Stack) void {
        for (0..self.length) |i| {
            self.stack[i] = 0;
        }
        self.length = 0;
    }

    pub fn size(self: *jade_Stack) usize {
        return self.length;
    }

    pub fn deinit(self: *jade_Stack) void {
        self.allocator.free(self.stack);
    }
};
