//! VJStructure
//! Contains the structure of a VOLT Cpu
//! All CPUs contain 256 registers, 256 memory locations, and 256 sections,
//! 32-bit VM (JADE), for 8-bit VM (JADE)

// $Id: VJStructure.zig

const std = @import("std");
const jade_Reg = @import("VJRegister.zig").jade_Reg;
const jade_Section = @import("VJSection.zig").jade_Section;
const jade_CpuState = @import("VJCpuState.zig").jade_CpuState;
const jade_CpuMode = @import("VJCpuMode.zig").jade_CpuMode;

/// the JADE VM Cpu structure
///
/// `256reg, 256sec`
pub const jade_Cpu = struct {
    regs: [256]jade_Reg,

    sections: [256]jade_Section,
    sectsz: u8 = 0,

    mode: jade_CpuMode = jade_CpuMode.regular,
    state: jade_CpuState = jade_CpuState.base,

    pub fn create() jade_Cpu {
        return jade_Cpu{
            .regs = [_]jade_Reg{jade_Reg.create()} ** 256,
            .sections = [_]jade_Section{jade_Section.create()} ** 256,
        };
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
    pub fn init_section(self: *jade_Cpu, lab: u32) *jade_Section {
        self.sections[self.sectsz] = jade_Section.create();
        self.sections[self.sectsz].setlab(lab);

        self.sectsz += 1;

        return &self.sections[self.sectsz - 1];
    }

    pub fn find_section(self: *jade_Cpu, lab: u32) !*jade_Section {
        for (0..self.sectsz) |i| {
            if (self.sections[i].label == lab) {
                return &self.sections[i];
            }
        }

        std.debug.print("jade: error: could not find section with label `{}'\n", .{lab});
        std.process.exit(1);
    }
};
