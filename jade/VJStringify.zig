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
const jade_Ruleset = @import("VJEmulation.zig").jade_Rules;

pub fn stringify32(allocator: std.mem.Allocator, hash: *jade_Hash, wideness: usize, chunk: []i32, ruleset: jade_Ruleset) !jade_Str {
    _ = wideness;

    var ret = jade_Str.create(allocator);
    var state: u8 = 0;
    var pc: u32 = 0;

    var current_byte: ?i32 = 0;
    var walker = jade_Walker32.create(chunk);

    while (current_byte != null) {
        current_byte = walker.walk();

        if (current_byte == null) {
            break;
        }

        if (state == 1 and pc == 0 and current_byte.? != ruleset.endsub) {
            ret.write("  ");
        }

        if (hash.has(current_byte.?) and current_byte.? != 10 and pc == 0) {
            ret.write(hash.get(current_byte.?).?.read());
        } else if (current_byte.? == 10 and state == 0) {
            ret.write("SUB");

            current_byte = walker.walk();

            if (current_byte == null) {
                std.debug.print("jade: warn: subroutine requires a label", .{});
                break;
            }

            ret.writefmt(" {} (label)\n", .{current_byte.?}) catch {
                std.debug.print("jade: stringify: could not format label\n", .{});
                break;
            };
            state = 1;
            pc = 0;
        } else if (current_byte.? == ruleset.term and pc > 0) {
            pc = 0;
            ret.write("\n");
        } else if (current_byte.? == ruleset.end and state == 0 and pc == 0) {
            ret.write("(end of bytecode)\n");
            break;
        } else if (current_byte.? == ruleset.end and state > 0) {
            ret.write("END\n");

            if (state == 0) {
                break;
            }

            pc = 0;
        } else if (current_byte.? == ruleset.endsub and state > 0) {
            state = 0;
            pc = 0;

            ret.write("END SUB");
            ret.write("\n");
        } else {
            try ret.writefmt(" {}", .{current_byte.?});
            pc += 1;
        }
    }

    return ret;
}
