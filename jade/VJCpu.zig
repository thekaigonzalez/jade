//! VJCpu
//! Contains the structure of a VOLT Cpu
//! All CPUs contain 256 registers, 256 memory locations, and 256 sections,
//! 32-bit VM (JADE), for 8-bit VM (JADE)

// $Id: VJStructure.zig

const std = @import("std");

const jade_Reg = @import("VJRegister.zig").jade_Reg;
const jade_Section = @import("VJSection.zig").jade_Section;
const jade_CpuState = @import("VJCpuState.zig").jade_CpuState;
const jade_CpuMode = @import("VJCpuMode.zig").jade_CpuMode;

const jade_Tracer = @import("VJTrace.zig").jade_Tracer;
const jade_Ruleset = @import("VJEmulation.zig").jade_Rules;
const jade_Stack = @import("VJStack.zig").jade_Stack;

/// the JADE VM Cpu structure
///
/// `256reg, 256sec`
pub const jade_Cpu = struct {
    regs: [256]jade_Reg,
    sections: [256]jade_Section,
    sectsz: u8 = 0,

    stack: jade_Stack = undefined,// only used in Rasterized mode

    mode: jade_CpuMode = jade_CpuMode.regular,
    state: jade_CpuState = jade_CpuState.base,

    tracer: ?jade_Tracer = null,
    ruleset: ?jade_Ruleset = null,

    allocator: std.mem.Allocator = undefined,

    pub fn create() jade_Cpu {
        return jade_Cpu{
            .regs = [_]jade_Reg{jade_Reg.create()} ** 256,
            .sections = [_]jade_Section{jade_Section.create()} ** 256,
        };
    }

    pub fn set_allocator(self: *jade_Cpu, allocator: std.mem.Allocator) void {
        self.allocator = allocator;
        self.stack = jade_Stack.create(allocator, 256);
    }

    pub fn print_tracer(self: *jade_Cpu) void {
        if (self.tracer) |tracer| {
            _ = tracer;
            for (0..self.tracer.?.get_traces().len) |i| {
                std.debug.print("{s}\n", .{self.tracer.?.get_traces()[i].msg.read()});
            }
        }
    }

    pub fn start_tracer(self: *jade_Cpu, allocator: std.mem.Allocator) void {
        self.tracer = jade_Tracer.create(allocator);
    }

    pub fn set_version(self: *jade_Cpu, str: []const u8) void {
        self.ruleset = jade_Ruleset.init(str);
    }

    /// NOTE: this will overwrite any existing register, probaby not needed
    pub fn init_register(self: *jade_Cpu, pos: usize) void {
        if (pos >= self.regs.len) {
            std.debug.print("jade: error: register index out of bounds\n", .{});
            std.process.exit(1);
        }

        self.regs[pos] = jade_Reg.create();
    }

    pub fn get_register(self: *jade_Cpu, pos: usize) *jade_Reg {
        if (pos >= self.regs.len) {
            std.debug.print("jade: error: register index out of bounds\n", .{});
            return &self.regs[0];
        }

        return &self.regs[pos];
    }
    pub fn init_section(self: *jade_Cpu, lab: i32) *jade_Section {
        self.sections[self.sectsz] = jade_Section.create();
        self.sections[self.sectsz].setlab(lab);

        self.sectsz += 1;

        return &self.sections[self.sectsz - 1];
    }

    pub fn find_section(self: *jade_Cpu, lab: i32) !*jade_Section {
        for (0..self.sectsz) |i| {
            if (self.sections[i].label == lab) {
                return &self.sections[i];
            }
        }

        std.debug.print("jade: error: could not find section with label `{}'\n", .{lab});
        std.process.exit(1);
    }
};
