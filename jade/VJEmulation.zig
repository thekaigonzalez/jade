//! Defines emulation mode rules
//! Supports: 32-bit ✅
//! Supports: 8-bit  ⚠️ - NOTE: 8-bit emulation will potentially need to be
//! casted from u32

// $Id: VJEmulation.zig

const std = @import("std");

/// JADE Emulation Mode
/// 
/// Depending on implementation, JADE supports different kinds of VMs and line endings
const jade_Rules = struct {
  end: i32 = 22, // to signify the end of the program, the JADE VM does not use this
  term: i32 = 0, // to terminate a statement - a MOV (assum. MOV=45) call would be: 45 1 34 0  

  pub fn init(name: []const u8) jade_Rules {
    if (std.mem.eql(u8, name, "JADE")) {
      return jade_Rules{
        .end = 22,
        .term = 0xAF,
      };
    }

    if (std.mem.eql(u8, name, "OpenLUD")) {
      return jade_Rules{
        .end = 22,
        .term = 0,
      };
    }

    if (std.mem.eql(u8, name, "NexFUSE")) {
      return jade_Rules{
        .end = 22,
        .term = 0,
      };
    }

    if (std.mem.eql(u8, name, "MercuryPIC")) {
      return jade_Rules{
        .end = 22,
        .term = 0xAF,
      };
    }
  }
};
