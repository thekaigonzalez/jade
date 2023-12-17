//! VJStr
//! defines a JADE string
//! primarily used for buffering, etc.
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJStr.zig

const std = @import("std");

/// JADE String Size Increment
///
/// How many bytes to increment the string size by once it reaches its maximum
pub const JADE_STR_SIZE_INCREMENT = 256;

/// NOTE: this is not a rich structure by any means, it's simply a string
/// framework to grow a dynamic string, writing an allocated string to prevent any
/// issues from popping up
pub const jade_Str = struct {
    data: []u8,
    len: u32 = 0,
    allocator: std.mem.Allocator,

    pub fn create(allocator: std.mem.Allocator) jade_Str {
        return jade_Str{
            .data = allocator.alloc(u8, JADE_STR_SIZE_INCREMENT) catch
                {
                std.debug.print("jade: error: out of memory\n", .{});
                std.process.exit(1);
            },
            .len = 0,
            .allocator = allocator,
        };
    }

    pub fn write(self: *jade_Str, data: []const u8) void {
        for (0..data.len) |i| {
            write1(self, data[i]);
        }
    }

    pub fn write1(self: *jade_Str, data: u8) void {
        if (self.len >= self.data.len) {
            self.data = self.allocator.realloc(self.data, self.data.len * 2) catch {
                std.debug.print("jade: error: out of memory\n", .{});
                std.process.exit(1);
            };
        }
        self.data[self.len] = data;
        self.len += 1;
    }

    pub fn read(self: *const jade_Str) []u8 {
        return self.data[0..self.len];
    }

    /// wrapper around std.fmt.bufPrint() for the string
    pub fn writefmt(self: *jade_Str, comptime fmt: []const u8, args: anytype) !void {
        const neededSpace = std.fmt.count(fmt, args);

        if (self.len + neededSpace >= self.data.len) {
            self.data = self.allocator.realloc(self.data, self.data.len + neededSpace * 2) catch {
                std.debug.print("jade: error: out of memory\n", .{});
                std.process.exit(1);
            };
        }

        const slice = self.data[self.len..][0..neededSpace];
        _ = try std.fmt.bufPrint(slice, fmt, args);

        self.len += @intCast(neededSpace);
    }

    pub fn destroy(self: *jade_Str) void {
        self.allocator.free(self.data);
    }
};

pub fn jade_FromU8Const(alloc: std.mem.Allocator, str: []const u8) jade_Str {
    var _str = jade_Str.create(alloc);

    _str.write(str);

    return _str;
}
