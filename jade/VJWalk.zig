//! VJWalk
//! Walks through the bytecode and analyzes it, updating the CPU states as needed
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJWalk.zig

const std = @import("std");

const jade_Cpu = @import("VJCpu.zig").jade_Cpu;
const jade_CpuState = @import("VJCpuState.zig").jade_CpuState;
const jade_CpuMode = @import("VJCpuMode.zig").jade_CpuMode;

/// A 32-bit bytecode walker
pub const jade_Walker32 = struct {
    mode: jade_CpuMode,
    chunk: []i32, // this is the main thing we're walking
    place: usize = 0,

    pub fn create(chunk: []i32) jade_Walker32 {
        return jade_Walker32{
            .mode = jade_CpuMode.regular,
            .chunk = chunk,
        };
    }

    /// keep in mind
    /// this function can return undefined
    pub fn walk(self: *jade_Walker32) ?i32 {
        if (self.place >= self.chunk.len) {
            return null;
        }
        const current = self.chunk[self.place];

        self.place += 1; // move the pointer forward

        return current;
    }

    /// peek
    pub fn peek(self: *jade_Walker32) ?i32 {
        if (self.place >= self.chunk.len) {
            return null;
        }

        return self.chunk[self.place];
    }
};

pub const jade_Walker8 = struct {
    mode: jade_CpuMode,
    chunk: []i8, // this is the main thing we're walking
    place: usize = 0,

    pub fn create(chunk: []i8) jade_Walker32 {
        return jade_Walker8{
            .mode = jade_CpuMode.regular,
            .chunk = chunk,
        };
    }

    /// keep in mind
    /// this function can return undefined
    pub fn walk(self: *jade_Walker8) ?i8 {
        if (self.place >= self.chunk.len) {
            return null;
        }
        const current = self.chunk[self.place];

        self.place += 1; // move the pointer forward

        return current;
    }

    /// peek
    pub fn peek(self: *jade_Walker32) ?i8 {
        if (self.place >= self.chunk.len) {
            return null;
        }

        return self.chunk[self.place];
    }
};
