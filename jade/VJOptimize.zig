//! VJOptimize
//!
//! Optimizes bytecode following VJOpFlags
//! NOTE: this only performs general optimizations and
//! does not take into account specific instructions, that is
//! handled by the CPU runtime
//!
//! This returns an Optimization Frame, containing all of the unfolded/optimized code
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJOptimize.zig

const std = @import("std");
const jade_OptimizationFlags = @import("VJOpFlags.zig").jade_OptimizationFlags;
const jade_OptimizationFrame32bit = @import("VJOpFrame.zig").jade_OpFrame32;
const jade_OptimizationFrame8bit = @import("VJOpFrame.zig").jade_OpFrame8;

const jade_Section = @import("VJSection.zig").jade_Section;
const jade_Cpu = @import("VJCpu.zig").jade_Cpu;

/// Optimizes BYTES using the specified optimization level, essentially parses
/// the bytecode and returns it in a new frame
pub fn optimize32bit(allocator: std.mem.Allocator, flags: jade_OptimizationFlags, bytes: []i32, cpu: *jade_Cpu) jade_OptimizationFrame32bit {
    var frame = jade_OptimizationFrame32bit.create(allocator);

    if (flags == .none) {
        frame.unfold(bytes);
        return frame;
    }

    var tmp = std.ArrayList(i32).init(allocator);
    defer tmp.deinit();

    var counter: i32 = 0; // counter for arguments, etc.

    var current_section: ?*jade_Section = null;

    var i: u32 = 0;

    for (0..bytes.len) |_| {
        if (i >= bytes.len) {
            break;
        }
        if (bytes[i] == cpu.ruleset.?.sub and counter == 0 and cpu.state == .base) {
            cpu.state = .subroutine;
            counter = 0;

            if (i + 1 > bytes.len) {
                std.debug.print("jade: optimize32bit: subroutine requires a header\n", .{});
                std.process.exit(1);
            }
            i += 1;

            current_section = cpu.init_section(bytes[i]);
        } else if (bytes[i] == cpu.ruleset.?.endsub and cpu.state == .subroutine) {
            cpu.state = .base;

            counter = 0;

            current_section.?.write(tmp.items);

            tmp.clearRetainingCapacity();

            current_section = null;
        } else if (bytes[i] == cpu.ruleset.?.gosub and cpu.state == .base and (flags == .aggressive or flags == .level2) and counter == 0) {
            counter = 0;
            std.debug.print("jade: optimize32bit: gosub not supported\n", .{});
            var section = try cpu.find_section(bytes[i + 1]);
            frame.unfold1(section.read());

            tmp.clearRetainingCapacity();
        } else {
            if (cpu.state != .subroutine) {
                frame.push(bytes[i]);
            }

            tmp.append(bytes[i]) catch {
                std.debug.print("jade: optimize32bit: failed to append to tmp", .{});
                std.process.exit(1);
            };
            counter += 1;
        }

        i += 1;
    }

    return frame;
}
