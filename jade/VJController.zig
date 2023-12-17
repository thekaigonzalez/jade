//! VJController
//! Manages CPU bytecode calls/instructions
//!
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJController.zig

const std = @import("std");

const jade_Cpu = @import("VJCpu.zig").jade_Cpu;
const jade_CpuState = @import("VJCpuState.zig").jade_CpuState;
const jade_CpuMode = @import("VJCpuMode.zig").jade_CpuMode;

const jade_Runtime32 = @import("VJRuntime.zig").jade_32BitRuntime;
const jade_OldRuntime32 = @import("VJClassicRuntime.zig").jade_32BitOldRuntime;
const jade_Walker32 = @import("VJWalk.zig").jade_Walker32;

const jade_Section = @import("VJSection.zig").jade_Section;

/// Controls the CPU, executes instructions onto it, and manages its state
///
/// NOTE: optimizations are handled by the runtime and caller, not by the controller
pub const jade_VJController32 = struct {
    cpu: *jade_Cpu,
    runtime: jade_Runtime32 = undefined,
    classic_runtime: jade_OldRuntime32 = undefined,

    pub fn new(cpu: *jade_Cpu) jade_VJController32 {
        return jade_VJController32{
            .cpu = cpu,
        };
    }

    /// classic execution
    pub fn run_bytecode_classic(self: *jade_VJController32, bytes: []i32) !void {
        var walker = jade_Walker32.create(bytes);
        var pc: i32 = 0;
        var state: i32 = 0;

        const rules = self.cpu.ruleset.?;

        if (walker.chunk.len == 0) {
            std.debug.print("jade: note: empty bytecode\n", .{});
            return;
        }

        var current_byte: ?i32 = walker.walk();

        var subsec: ?*jade_Section = null;

        var tmp = std.ArrayList(i32).init(std.heap.page_allocator);
        defer tmp.deinit();

        while (true) {
            if (current_byte == rules.end and state == 0 and pc == 0) {
                break;
            }
            if (current_byte == rules.term and pc > 0 and state == 0) {
                pc = 0;

                if (tmp.items.len > 0) {
                    if (!self.classic_runtime.feature(tmp.items[0])) {
                        std.debug.print("jade: error: invalid bytecode\n", .{});
                        std.debug.print("jade: error: could not find runtime instruction `{}'\n", .{tmp.items[0]});
                        std.process.exit(1);
                    }
                    _ = self.classic_runtime.get(tmp.items[0])(self.cpu, tmp);
                }

                tmp.clearRetainingCapacity();
            }
            else if (current_byte == rules.sub and state == 0) {
                state = 1;

                subsec = self.cpu.init_section(walker.walk().?);

                tmp.clearRetainingCapacity();
            }

            else if (current_byte == rules.endsub and state == 1) {
                state = 0;

                if (tmp.items.len > 0) {
                    subsec.?.write(tmp.items[0..]);
                    tmp.clearRetainingCapacity();
                    subsec = null;
                }
            }

            else if (current_byte == rules.gosub and state == 0) {
                const labl = walker.walk();
                
                if (labl != null) {
                    var sec_torun = try self.cpu.find_section(labl.?);

                    try self.run_bytecode_classic(sec_torun.read());
                }

                tmp.clearRetainingCapacity();
            }
            else {
                if (current_byte == null) {
                    break;
                }
                try tmp.append(current_byte.?);
                pc += 1;
            }
            current_byte = walker.walk();
        }
    }
};
