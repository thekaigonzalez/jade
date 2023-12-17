//! Provide an easy way to add trace logs
//! In essence, provides ways to declare and use logs like "Register 1 read
//! here, ", etc.
//!
//! uses time to track the time of declarations
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅

// $Id: VJTrace.zig

const std = @import("std");
const mem = std.mem;
const time = std.time.timestamp;

const jade_Str = @import("VJStr.zig").jade_Str;

/// Trace Types
pub const jade_TraceType = enum {
    read, // register read here
    write, // register wrote to here
    jmp, // jump here
    call, // call here
};

/// # Traces
///
/// For the CPU to find all calls and subroutines
///
/// ```
/// (<time>) register 1 read here for values: 1
/// (<time>) register write here (value)
/// ```
pub const jade_Trace = struct {
    time: i64 = 0,
    msg: jade_Str = undefined,
    t: jade_TraceType = undefined,

    pub fn create(allocator: mem.Allocator) jade_Trace {
        return jade_Trace{ .msg = jade_Str.create(allocator), .time = time() };
    }

    pub fn add_details(self: *jade_Trace, typeof: jade_TraceType, args: anytype) !void {
        self.t = typeof;

        if (typeof == jade_TraceType.read) {
            try self.msg.writefmt("[ \x1b[35;1m{}\x1b[0m ] -> register {} read here for values: {}", .{ self.time, args[0], args[1] });
        } else if (typeof == .write) {
            try self.msg.writefmt("[ \x1b[35;1m{}\x1b[0m ] -> register {} write here ({})", .{ self.time, args[0], args[1] });
        } else if (typeof == .jmp) {
            try self.msg.writefmt("[ \x1b[35;1m{}\x1b[0m ] -> jump here ({})", .{ self.time, args[0] });
        } else if (typeof == .call) {
            try self.msg.writefmt("[ \x1b[35;1m{}\x1b[0m ] -> call here ({})", .{ self.time, args[0] });
        }
    }
};

pub const jade_Tracer = struct {
    traces: std.ArrayList(jade_Trace),
    allocator: mem.Allocator,

    pub fn create(allocator: mem.Allocator) jade_Tracer {
        return jade_Tracer{
            .traces = std.ArrayList(jade_Trace).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn add_trace(self: *jade_Tracer, trace: jade_Trace) !void {
        try self.traces.append(trace);
    }

    pub fn get_traces(self: *jade_Tracer) []jade_Trace {
        return self.traces.items;
    }

    pub fn last_trace(self: *jade_Tracer) ?jade_Trace {
        if (self.traces.items.len > 0) {
            return self.traces.items[self.traces.items.len - 1];
        }
        return null;
    }

    pub fn filter(self: *jade_Tracer, typeof: jade_TraceType) []jade_Trace {
        var list = std.ArrayList(jade_Trace).init(self.allocator);
        for (self.traces.items) |trace| {
            if (trace.type == (typeof)) {
                try list.append(trace);
            }
        }
        return list.items;
    }

    pub fn deinit(self: *jade_Tracer) void {
        self.traces.deinit();
    }
};
