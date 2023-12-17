// $Id: VJRuntimeAbstractions.zig

const std = @import("std");

const jade_Cpu = @import("VJCpu.zig").jade_Cpu;
const jade_Walker32 = @import("VJWalk.zig").jade_Walker32;
const jade_Trace = @import("VJTrace.zig").jade_Trace;

pub const VJRuntimeAbstractions = struct {
    /// Classic MOV function
    ///
    /// MOV [reg] [byte]
    /// 
    /// Supports: RAS     ✅
    /// Supports: Regular ✅
    pub fn CVJMOVFunction(cpu: *jade_Cpu, param: std.ArrayList(i32)) i32 {
        if (param.items.len < 3) {
            std.debug.print("jade: mov: error: not enough parameters\n", .{});
            return 1;
        }

        if (cpu.tracer != null) {
            var trace = jade_Trace.create(cpu.allocator);

            trace.add_details(.write, .{ param.items[1], param.items[2] }) catch {
                std.debug.print("jade: mov: error: out of memory\n", .{});
                return 1;
            };

            cpu.tracer.?.add_trace(trace) catch {
                std.debug.print("jade: mov: error: out of memory\n", .{});
                return 1;
            };
        }

        if (cpu.mode == .regular) {
            var regi = cpu.get_register(@intCast(param.items[1]));
            regi.push(param.items[2]);
        } else {
            cpu.stack.push(param.items[2]);
        }

        return 0;
    }

    /// Classic ECHO function
    ///
    /// ECHO [byte]
    ///
    /// Tries to print the given byte as a character
    /// or as a number
    /// 
    /// Supports: RAS     ✅
    /// Supports: Regular ✅
    pub fn CVJECHOFunction(cpu: *jade_Cpu, param: std.ArrayList(i32)) i32 {
        _ = cpu;
        if (param.items.len < 2) {
            std.debug.print("jade: mov: error: not enough parameters\n", .{});
            return 1;
        }

        const byte: u32 = @intCast(param.items[1]);

        if (byte < 256) {
            const cb: u8 = @truncate(byte);
            std.debug.print("{c}", .{cb});
        } else {
            std.debug.print("{d}", .{byte});
        }

        return 0;
    }


    /// Classic EACH Function
    ///
    /// Supports: 32-bit ✅
    /// Supports: 8-bit  ✅
    ///
    /// Supports: RAS     ✅
    /// Supports: Regular ✅
    pub fn CVJEACHFunction(cpu: *jade_Cpu, param: std.ArrayList(i32)) i32 {
        if (cpu.mode == .regular) {
            const reg_num = cpu.get_register(@intCast(param.items[1]));

            for (0..reg_num.data.len) |i| {
                if (reg_num.data[i] != 0) {
                    std.debug.print("{}\n", .{reg_num.data[i]});
                }
            }
        } else {
            for (0..cpu.stack.stack.len) |i| {
                if (cpu.stack.stack[i] != 0) {
                    std.debug.print("{}\n", .{cpu.stack.stack[i]});
                }
            }
        }

        return 0;
    }
};
