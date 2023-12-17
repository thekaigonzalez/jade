//! VJRegister
//! Contains the structure of a VOLT Register
//! primarily used for input, output, and stack
//! when running optimizations, stack is the primary i/o dev
//! 32-bit VM (JADE), for 8-bit VM (JADE)

// $Id: VJRegister.zig

const std = @import("std");
const JadeValues = @import("VJDefit.zig");

pub const jade_Reg = struct {
    data: [JadeValues.JADE_MAX_REGISTERS]i32,
    ptr: u32 = 0,
    locked: bool = false,
    passphrase: i32 = 0,

    /// Creates a new register
    pub fn create() jade_Reg {
        return jade_Reg{ .data = [_]i32{0} ** 256 };
    }

    /// Writes VALUE to INDEX
    pub fn write(self: *jade_Reg, index: i32, value: i32) void {
        if (index >= JadeValues.JADE_MAX_REGISTERS) {
            std.debug.print("jade: register index out of bounds: `{}'\n", .{index});
            std.debug.print("jade: note: max index is `{}'\n", .{JadeValues.JADE_MAX_REGISTERS});

            return;
        }

        self.data[index] = value;
    }

    /// Locks the Register
    pub fn lock(self: *jade_Reg, passphrase: i32) void {
        self.locked = true;
        self.passphrase = passphrase;
    }

    /// unlocks the register
    pub fn unlock(self: *jade_Reg, passphrase: i32) void {
        if (!self.locked) return;
        
        if (self.passphrase != passphrase) {
            std.debug.print("jade: warning: could not unlock register because owner does not match the one that locked it\n", .{});
        }

        self.locked = false;
        self.passphrase = 0;
    }

    /// Reads INDEX from the current register, returns -1 if out of bounds
    /// returns either 0 or the value in the register
    pub fn read(self: *jade_Reg, index: i32) i32 {
        if (index >= JadeValues.JADE_MAX_REGISTERS) {
            std.debug.print("jade: register index out of bounds: `{}'\n", .{index});
            std.debug.print("jade: note: max index is `{}'\n", .{JadeValues.JADE_MAX_REGISTERS});

            return -1;
        }

        return self.data[index];
    }

    /// Pushes VALUE onto the register
    pub fn push(self: *jade_Reg, value: i32) void {
        if (self.ptr >= JadeValues.JADE_MAX_REGISTERS) {
            std.debug.print("jade: register pointer exceeds limit of `{}'\n", .{self.ptr});
            std.debug.print("jade: note: max index is {}\n", .{JadeValues.JADE_MAX_REGISTERS});
            return;
        }

        self.data[self.ptr] = value;
        self.ptr += 1;
    }

    /// Pops the last value from the register
    /// ```
    /// var register1 = jade_Reg.create();
    /// register1.push(1);
    /// register1.push(2);
    /// register1.push(3);
    /// // [1,2,3,0...]
    ///
    /// const value = register1.pop(); // 3
    /// // [1,2,0...]
    /// ```
    pub fn pop(self: *jade_Reg) i32 {
        if (self.ptr == 0 or self.ptr - 1 < 0) {
            return 0;
        }

        self.ptr -= 1;

        const value: i32 = self.data[self.ptr];
        self.data[self.ptr] = 0;

        return value;
    }
};
