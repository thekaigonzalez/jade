//! VJStringify
//! Parses JADE bytecode into a string, using the jade_Hash table provided
//!
//! NOTE: subroutines are handled by default
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

const std = @import("std");

// $Id: VJStringify.zig

const jade_Hash = @import("VJHash.zig").jade_Hash;
const jade_Str = @import("VJStr.zig").jade_Str;
const jade_Walker32 = @import("VJWalk.zig").jade_Walker32;

pub fn stringify32(allocator: std.mem.Allocator, hash: *jade_Hash, wideness: usize, chunk: []u32) !jade_Str {
    _ = wideness;
    var ret = jade_Str.create(allocator);
    var state: u8 = 0;

    const current_byte: ?u32 = 0;
    var walker = jade_Walker32.create(chunk);

    while (current_byte != -1) {
        current_byte = walker.walk();

        if (hash.has(current_byte) and current_byte != 10 and state == 0) {
            ret.write(hash.get(current_byte).?.read());
        }
        else if (current_byte == 10 and state == 0) {
            ret.write("SUB");
            state = 1;
        }
        else {
          if (current_byte > 0 and current_byte < 256) {
            ret.write(current_byte);
          }
        }
    }
}
