//! Contexts
//!
//! Similar to NexFUSE's FCtx()
//! contains bytes used by JADE Opbindings

// $Id: VJContext.zig

const std = @import("std");
const page = std.heap.page_allocator;

/// Context designed for JADE Opbindings
pub const jade_Context = struct {
    pc: []u32 = undefined,
    ac: usize = 0,

    pub fn create() !jade_Context {
        const blk = try page.alloc(u32, 256);

        return jade_Context{
            .pc = blk,
            .ac = 0,
        };
    }

    pub fn push(self: *jade_Context, value: u32) !void {
        if (self.ac >= self.pc.len) { // if we're at the end of the array
            // double the size
            self.pc = try page.realloc(self.pc, self.pc.len * 2);
        }
        self.pc[self.ac] = value;

        self.ac += 1;
    }

    pub fn pop(self: *jade_Context) u32 {
        const arg = self.pc[self.ac - 1];

        self.ac -= 1;

        return arg;
    }

    pub fn clone(self: *jade_Context) !jade_Context {
        const blk = try page.alloc(u32, self.pc.len);

        @memcpy(blk, self.pc);

        return jade_Context{
            .pc = blk,
            .ac = self.ac,
        };
    }

    /// free memory used by the context
    pub fn deinit(self: *jade_Context) void {
        page.free(self.pc);
    }

    /// returns 32-bit integer at index
    pub fn at(self: *jade_Context, index: usize) u32 {
        if (index >= self.pc.len or index < 0 or index > self.ac) {
            std.debug.print("jade: context index out of bounds: `{}'\n", .{index});
            std.debug.print("jade: note: max index is `{}'\n", .{self.pc.len});

            return 0;
        }
        return self.pc[index];
    }
};
