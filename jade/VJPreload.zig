//! A simple framework to preload a 32-bit/8-bit bytecode file into an array

// contains abstract methods for unloading
// $Id: VJPreload.zig

const std = @import("std");

/// # Bytecode
/// Preloads a 32-bit/8-bit little-endian bytecode file
///
/// note: file must be either 32-bit aligned or 8-bit, using EXTERNAL measure to
/// ensure this, otherwise this function could potentially crash the VM.
/// Do NOT trust this function unless you know what you're doing.
pub fn jade_BuiltinLoadbyteCode(comptime T: type, width: usize, path: []const u8) ![]T {
    // open the file
    const file = std.fs.cwd().openFile(path, .{}) catch unreachable;

    // read the file
    const sizeof_file = file.getEndPos() catch 0;

    if (sizeof_file % 4 != 0 and width == 32) { // 32-bit (u32)
        std.debug.print("jade: file is not 32-bit aligned\n", .{});
        return undefined;
    } else if (sizeof_file % 2 != 0 and width == 8) { // 8-bit (u8)
        std.debug.print("jade: file is not 8-bit aligned\n", .{});
        return undefined;
    }

    if (width == 32) {
        const other_growable = try std.heap.page_allocator.alloc(T, sizeof_file / 4);

        const reader = file.reader();

        for (0..sizeof_file / 4) |i| {
            const integ = try reader.readInt(T, std.builtin.Endian.little);
            other_growable[i] = integ;
        }

        file.close();

        return other_growable;
    } else if (width == 8) {
        const other_growable = try std.heap.page_allocator.alloc(T, sizeof_file);
        defer std.heap.page_allocator.free(other_growable);

        const reader = file.reader();

        for (0..sizeof_file / 1) |i| {
            const integ = try reader.readByte();
            other_growable[i] = integ;
        }

        file.close();

        return other_growable;
    }

    return undefined;
}

pub const jade_VJ8BitPreloader = struct {
    data: []u8,

    pub fn create() jade_VJ8BitPreloader {
        return jade_VJ8BitPreloader{ .data = undefined };
    }

    pub fn load(self: *jade_VJ8BitPreloader, path: []const u8) !void {
        self.data = try jade_BuiltinLoadbyteCode(u8, 8, path);

        if (self.data == undefined) {
            std.debug.print("jade: error: file is not 8-bit aligned\n", .{});
            std.process.exit(1);
            return;
        }
    }
};

pub const jade_VJ32BitPreloader = struct {
    data: []u32,

    pub fn create() jade_VJ32BitPreloader {
        return jade_VJ32BitPreloader{ .data = undefined };
    }

    pub fn load(self: *jade_VJ32BitPreloader, path: []const u8) !void {
        self.data = try jade_BuiltinLoadbyteCode(u32, 32, path);
    }
};
