//! VJHash
//! Hash table for byte -> string values
//! 
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJHash.zig

const std = @import("std");
const jade_Str = @import("VJStr.zig").jade_Str;

/// A hashtable for byte -> string values
pub const jade_Hash = struct {
    data: std.hash_map.AutoHashMap(i32, jade_Str),
    parent: std.mem.Allocator,

    pub fn create(page: std.mem.Allocator) jade_Hash {
        return jade_Hash{
            .data = std.hash_map.AutoHashMap(i32, jade_Str).init(page),
            .parent = page,
        };
    }

    pub fn deinit(self: *jade_Hash) void {
        self.data.deinit();
    }

    pub fn set(self: *jade_Hash, key: i32, value: jade_Str) !void {
        try self.data.put(key, value);
    }

    pub fn get(self: *jade_Hash, key: i32) ?jade_Str {
        return self.data.get(key);
    }

    pub fn has(self: *jade_Hash, key: i32) bool {
        return self.data.contains(key);
    }
};
