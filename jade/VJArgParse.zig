//! Simple argument parser
//! Supports: 32-bit ✅
//! Supports: 8-bit  ✅
//! (it's an argument parser, doesn't really matter what it supports)

// $Id: VJArgParse.zig

const std = @import("std");

pub const jade_ArgumentType = enum {
    boolean,
    string,
    number,
    compound_any, // so this one's a bit of a stretch, but needed so compound flags and GNU-style flags can work together
};

pub const jade_FlagType = enum {
    positional, // a.out
    short, // -f
    long, // --flag
};

pub fn jade_AssumeFlagType(flag: []const u8) jade_FlagType {
    if (std.mem.startsWith(u8, flag, "--")) {
        return .long;
    } else if (std.mem.startsWith(u8, flag, "-")) {
        return .short;
    } else {
        return .positional;
    }
}

pub fn jade_ParseFlag(flag: []const u8) []const u8 {
    const atype: jade_FlagType = jade_AssumeFlagType(flag);

    if (atype == .long) {
        return flag[2..];
    }

    if (atype == .short) {
        return flag[1..];
    }

    return flag;
}

pub const jade_Flag = struct {
    short: u8,
    long: []const u8,
    type: jade_ArgumentType,
    description: []const u8,
    value: ?[]const u8 = null,

    pub fn new(short: u8, long: []const u8, atype: jade_ArgumentType, description: []const u8) jade_Flag {
        return jade_Flag{ .short = short, .long = long, .type = atype, .description = description };
    }

    pub fn set_value(self: *jade_Flag, value: []const u8) void {
        self.value = value;
    }

    pub fn get_value(self: *jade_Flag) []const u8 {
        return self.value.?;
    }

    pub fn convert(self: *jade_Flag, comptime T: type) T {
        if (T == bool) {
            if (self.value == null) {
                return false;
            }
            return (std.mem.eql(u8, self.value.?, "true"));
        } else if (T == []const u8) {
            if (self.value == null) {
                return "";
            }
            return self.value.?;
        } else if (T == i32) {
            if (self.value == null) {
                return 0;
            }
            return try std.fmt.parseInt(i32, self.value.?, 10);
        }
        return 0;
    }
};

pub fn leftPad(str: []const u8, width: usize, paddingChar: u8) []const u8 {
    const maxInt = std.math.maxInt;
    const paddingLength = maxInt(width - str.len, 0);
    const paddedText = std.fmt.format("{.*c}{s}", .{ paddingLength, paddingChar, str });
    return paddedText;
}

pub const jade_Flags = struct {
    length: u32 = 0,
    flags: []jade_Flag = undefined,
    alloc: std.mem.Allocator,

    pub fn create(allocator: std.mem.Allocator) jade_Flags {
        return jade_Flags{
            .length = 0,
            .alloc = allocator,
            .flags = allocator.alloc(jade_Flag, 256) catch {
                std.debug.print("jade: error: out of memory\n", .{});
                std.process.exit(1);
            },
        };
    }

    pub fn add_flag(self: *jade_Flags, flag: jade_Flag) void {
        if (self.length >= self.flags.len) {
            self.flags = self.alloc.realloc(self.flags, self.flags.len * 2) catch {
                std.debug.print("jade: error: out of memory\n", .{});
                std.process.exit(1);
            };
        }
        self.flags[self.length] = flag;
        self.length += 1;
    }

    pub fn append(self: *jade_Flags, flag: jade_Flag) void {
        self.add_flag(flag);
    }

    pub fn destroy(self: *jade_Flags) void {
        self.alloc.free(self.flags);
    }
};

pub const jade_ArgumentParser = struct {
    flags: jade_Flags,
    positional: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,
    usage: []const u8 = "",
    desc: []const u8 = "",
    prog: []const u8 = "",

    pub fn create(allocator: std.mem.Allocator) jade_ArgumentParser {
        return jade_ArgumentParser{
            .flags = jade_Flags.create(allocator),
            .positional = std.ArrayList([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn set3(self: *jade_ArgumentParser, usage: []const u8, desc: []const u8, prog: []const u8) void {
        self.usage = usage;
        self.desc = desc;
        self.prog = prog;
    }

    pub fn add_flag(self: *jade_ArgumentParser, short: u8, long: []const u8, atype: jade_ArgumentType, description: []const u8) !*jade_Flag {
        var setup = jade_Flag{ .short = short, .long = long, .type = atype, .description = description };

        if (setup.type == .boolean) {
            setup.value = "false";
        } else if (setup.type == .string) {
            setup.value = "";
        } else if (setup.type == .number) {
            setup.value = "0";
        }

        self.flags.append(setup);

        return &self.flags.flags[self.flags.length - 1];
    }

    pub fn search_flag_long(self: *jade_ArgumentParser, flag: []const u8) ?*jade_Flag {
        for (0..self.flags.length) |i| {
            if (std.mem.eql(u8, self.flags.flags[i].long, flag)) {
                return &self.flags.flags[i];
            }
        }

        return null;
    }

    pub fn search_flag_short(self: *jade_ArgumentParser, flag: u8) ?*jade_Flag {
        for (0..self.flags.length) |i| {
            if (self.flags.flags[i].short == flag) {
                return &self.flags.flags[i];
            }
        }

        return null;
    }

    pub fn parse_args(self: *jade_ArgumentParser, args: [][]const u8) !void {
        var state: i32 = 0;

        var last_flag: u8 = 0;

        for (args) |item| {
            const typeof = jade_AssumeFlagType(item);

            if (typeof == .positional) {
                if (state == 0) {
                    try self.positional.append(item);
                } else if (state == 1) {
                    const fala = self.search_flag_short(last_flag);

                    if (fala != null) {
                        fala.?.set_value(item);
                    }
                    state = 0;

                    last_flag = 0;
                }
            } else if (typeof == .long) {
                const stripped = item[2..];

                var flag = self.search_flag_long(stripped);

                if (flag == null) {
                    std.debug.print("{s}: error: unknown flag: `{s}'\n", .{ self.prog, item });
                    const help_flag = self.search_flag_short('h');

                    if (help_flag != null) {
                        std.debug.print("{s}: type `{s} -h' for help\n", .{ self.prog, self.prog });
                    }
                    std.process.exit(1);
                }

                if (flag.?.type == .boolean) {
                    flag.?.set_value("true");
                } else if (flag.?.type == .number) {
                    flag.?.set_value(item);
                } else {
                    state = 1;
                    last_flag = flag.?.short;
                }
            } else if (typeof == .short) {
                const stripped = item[1..];

                for (0..stripped.len) |i| { // Compound flags
                    const flag = self.search_flag_short(stripped[i]);

                    if (flag == null) {
                        std.debug.print("{s}: fatal: unrecognized short flag in compound: `{c}'\n", .{ self.prog, stripped[i] });
                        const help_flag = self.search_flag_short('h');

                        if (help_flag != null) {
                            std.debug.print("{s}: type `{s} -h' for help\n", .{ self.prog, self.prog });
                        }
                        std.process.exit(1);
                    }

                    if (flag.?.type == .boolean) {
                        flag.?.set_value("true");
                    } else if (flag.?.type == .compound_any) {
                        flag.?.set_value(stripped[i + 1 ..]);
                        break;
                    } else {
                        state = 1;
                        last_flag = flag.?.short;
                    }
                }
            }
        }
    }

    pub fn print_help(self: *jade_ArgumentParser) void {
        std.debug.print("usage: {s}\n{s}\nOptions:\n", .{ self.usage, self.desc });

        for (0..self.flags.length) |j| {
            std.debug.print("\t-{c}\t\t{s}\n", .{ self.flags.flags[j].short, self.flags.flags[j].description });
        }
    }

    pub fn flag_exists(self: *jade_ArgumentParser, short: u8) bool {
        for (0..self.flags.length) |i| {
            if (self.flags.flags[i].short == short) {
                return true;
            }
        }
    }
};

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const args = try std.process.argsAlloc(arena_allocator.allocator());

    var argparser = jade_ArgumentParser.create(arena_allocator.allocator());
    argparser.set3("test [-fh]", "A Test Program.", "test");

    var flag1 = try argparser.add_flag('f', "flag", .compound_any, "this is a flag");
    var help = try argparser.add_flag('h', "help", .boolean, "this is a help");
    const help2 = try argparser.add_flag('a', "help2", .boolean, "this is a help");
    _ = help2;
    _ = help2;
    const flag4 = try argparser.add_flag('b', "flag4", .compound_any, "this is a flag");
    _ = flag4;
    const flag5 = try argparser.add_flag('c', "flag5", .boolean, "this is a flag");
    _ = flag5;
    const flag6 = try argparser.add_flag('d', "flag6", .boolean, "this is a flag");
    _ = flag6;
    const flag7 = try argparser.add_flag('e', "flag7", .compound_any, "this is a flag");
    _ = flag7;
    const flag8 = try argparser.add_flag('i', "flag8", .boolean, "this is a flag");
    _ = flag8;
    const flag9 = try argparser.add_flag('j', "flag9", .boolean, "this is a flag");
    _ = flag9;

    try argparser.parse_args(args[1..]);

    if (help.convert(bool)) {
        argparser.print_help();
        std.process.exit(0);
    }

    std.debug.print("flag1 value: {s}\n", .{flag1.convert([]const u8)});

    std.process.argsFree(arena_allocator.allocator(), args);
}
