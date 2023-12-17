//! Defines emulation mode rules
//! Supports: 32-bit ✅
//! Supports: 8-bit  ⚠️ - NOTE: 8-bit emulation will potentially need to be
//! casted from i32

// $Id: VJEmulation.zig

const std = @import("std");

/// JADE Emulation Mode
///
/// Depending on implementation, JADE supports different kinds of VMs and line endings
pub const jade_Rules = struct {
    end: i32 = 22, // to signify the end of the program, the JADE VM does not use this
    term: i32 = 0, // to terminate a statement - a MOV (assum. MOV=45) call would be: 45 1 34 0
    endsub: i32 = 0, // to signify the end of a subroutine, the JADE VM does not use this
    gosub: i32 = 15, // moving to a subroutine
    sub: i32 = 10, // starting a subroutine
    pub fn init(name: []const u8) jade_Rules {
        if (std.mem.eql(u8, name, "JADE")) {
            return jade_Rules{
                .end = 22,
                .term = 0xAF,
                .endsub = -1,
            };
        }

        if (std.mem.eql(u8, name, "OpenLUD")) {
            return jade_Rules{
                .end = 12,
                .term = 0,
                .endsub = -1,
            };
        }

        if (std.mem.eql(u8, name, "NexFUSE")) {
            return jade_Rules{
                .end = 22,
                .term = 0,
                .endsub = 0x80,
            };
        }

        if (std.mem.eql(u8, name, "MercuryPIC")) {
            return jade_Rules{
                .end = 22,
                .term = 0xAF,
                .endsub = 0x80,
            };
        }

        return jade_Rules{
            .end = 22,
            .term = 0,
        };
    }
};
