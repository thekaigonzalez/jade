// $Id: VJTest.zig

const std = @import("std");
const page = std.heap.page_allocator;
const jade_Cpu = @import("VJCpu.zig").jade_Cpu;
const jade_Reg = @import("VJRegister.zig").jade_Reg;
const jade_Sec = @import("VJSection.zig").jade_Section;
const jade_Context = @import("VJContext.zig").jade_Context;
const jade_Preloader = @import("VJPreload.zig").jade_VJ32BitPreloader;
const jade_Walker32 = @import("VJWalk.zig").jade_Walker32;
const jade_String = @import("VJStr.zig").jade_Str;
const jade_FromU8Const = @import("VJStr.zig").jade_FromU8Const;
const jade_Hash = @import("VJHash.zig").jade_Hash;
const jade_Stringify = @import("VJStringify.zig").stringify32;

const ArenaAllocator = std.heap.ArenaAllocator;

pub fn test_1() i8 {
    var register1 = jade_Reg.create();

    register1.push(1);
    register1.push(2);
    register1.push(3);

    const value = register1.pop();

    std.debug.print("value: {}\n", .{value});

    return 0;
}

pub fn test_2() i8 {
    var sec1 = jade_Sec.create();

    sec1.setlab(145);

    std.debug.print("label: {}\n", .{sec1.label});

    for (sec1.data) |value| {
        if (value != 0)
            std.debug.print("value: {}\n", .{value});
    }

    return 0;
}

pub fn test_3() i8 {
    var cpu = jade_Cpu.create();
    var section = cpu.init_section(45);

    var bytes = [_]u32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    section.write(bytes[0..]);

    const that_section = try cpu.find_section(45);
    _ = that_section;

    return 0;
}

pub fn test_4() !i8 {
    var context = try jade_Context.create();
    defer context.deinit();
    
    try context.push(1);
    try context.push(2);
    try context.push(3);

    const value = context.pop();

    std.debug.print("value: {}\n", .{value});

    return 0;
}

// pub fn test_5() !i8 {
//     const test_file = try jade_Preload(u32, 32, "a.bin");
//     defer page.free(test_file); // works!

//     std.debug.print("{any}\n", .{test_file});
    
//     return 0;
// }

pub fn test_6() !i8 {
    var loader = jade_Preloader.create();

    try loader.load("a.bin");

    std.debug.print("{any}\n", .{loader.data});

    return 0;
}

pub fn test_7() !i8 {
    var loader = jade_Preloader.create();

    try loader.load("a.bin");

    var walker = jade_Walker32.create(loader.data);
    _ = try walker.walk();
    const n = walker.walk();

    std.debug.print("value: {any}\n", .{n});

    return 0;
}

pub fn test_8() !i8 {
    var allo = ArenaAllocator.init(page);
    defer allo.deinit();
    
    var str1 = jade_String.create(allo.allocator());

    str1.write("abc");

    std.debug.print("{s}\n", .{str1.read()});

    return 0;
}

pub fn test_9() !i8 {
    var allo = ArenaAllocator.init(page);
    defer allo.deinit();

    var hash = jade_Hash.create(allo.allocator());

    const strabc = jade_FromU8Const(allo.allocator(), "abc");
    const strdef = jade_FromU8Const(allo.allocator(), "def");
    
    try hash.set(1, strabc);
    try hash.set(2, strdef);

    std.debug.print("1: {s}\n", .{hash.get(1).?.read()});
    std.debug.print("2: {s}\n", .{hash.get(2).?.read()});

    return 0;
}

pub fn test_10() !i8 {
    var allo = ArenaAllocator.init(page);
    defer allo.deinit();

    var hash = jade_Hash.create(allo.allocator());

    const astr = jade_FromU8Const(allo.allocator(), "abc");
    try hash.set(45, astr);

    var bytes = [_]u32{ 45, 1, 3 };
    const sample_chunk = bytes[0..];

    const str = try jade_Stringify(allo.allocator(), &hash, 32, sample_chunk);

    std.debug.print("{s}\n", .{str});

    return 0;
}

pub fn main() !void {
    const tests = [_]*const fn () i8{ test_1, test_2, test_3 };

    var tind: usize = 1;

    for (tests) |teste| {
        if (teste() != 0) {
            std.debug.print("test {} failed\n", .{tind});
        } else {
            std.debug.print("test {} passed\n", .{tind});
        }

        tind += 1;
    }

    std.debug.print("all LIFO-based tests passed\n", .{});

    _ = try test_4();
    _ = try test_6();
    _ = try test_7();
    _ = try test_8();
    _ = try test_9();
    _ = try test_10();
    
    return;
}
