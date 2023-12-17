// $Id: Jade.zig

const std = @import("std");
const page = std.heap.page_allocator;
const jade_Cpu = @import("VJCpu.zig").jade_Cpu;
const jade_Reg = @import("VJRegister.zig").jade_Reg;
const jade_Sec = @import("VJSection.zig").jade_Section;
const jade_Context = @import("VJContext.zig").jade_Context;
const jade_Preloader = @import("VJPreload.zig").jade_VJ32BitPreloader;
const jade_Preloader8Bit = @import("VJPreload.zig").jade_VJ8BitPreloader;
const jade_Walker32 = @import("VJWalk.zig").jade_Walker32;
const jade_String = @import("VJStr.zig").jade_Str;
const jade_FromU8Const = @import("VJStr.zig").jade_FromU8Const;
const jade_Hash = @import("VJHash.zig").jade_Hash;
const jade_Stringify = @import("VJStringify.zig").stringify32;
const jade_Rules = @import("VJEmulation.zig").jade_Rules;
const jade_Trace = @import("VJTrace.zig").jade_Trace;
const jade_OpFrame = @import("VJOpFrame.zig").jade_OpFrame32;
const jade_Optimize32 = @import("VJOptimize.zig").optimize32bit;
const jade_OpFlag = @import("VJOpFlags.zig").jade_OptimizationFlags;
const jade_Runtime = @import("VJRuntime.zig").jade_32BitRuntime;
const jade_ArgumentParser = @import("VJArgParse.zig").jade_ArgumentParser;
const jade_Controller32 = @import("VJController.zig").jade_VJController32;
const jade_OldRuntime32 = @import("VJClassicRuntime.zig").jade_32BitOldRuntime;
const jade_VJController32 = @import("VJController.zig").jade_VJController32;

const VJRuntimeAbstractions = @import("VJRuntimeAbstractions.zig").VJRuntimeAbstractions;

const JADE_VERSION = "1.0.0";

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const args = try std.process.argsAlloc(arena_allocator.allocator());

    var argparser = jade_ArgumentParser.create(arena_allocator.allocator());
    argparser.set3("jade [options...] filename", "A Test Program.", "test");

    var help = try argparser.add_flag('h', "help", .boolean, "shows this text and exits");
    const version = try argparser.add_flag('v', "version", .boolean, "shows the version and exits");
    const verbose = try argparser.add_flag('V', "verbose", .boolean, "verbose mode");
    _ = verbose;

    const mode = try argparser.add_flag('m', "mode", .compound_any, "runs the code in either 32-bit or 8-bit mode");
    const optimizations = try argparser.add_flag('O', "optimize", .compound_any, "optimizes the code depending on the level set");
    const as_text = try argparser.add_flag('t', "text", .boolean, "prints the code as English-itized text");
    const debugger = try argparser.add_flag('g', "debug", .boolean, "interactively debugs the code");
    _ = debugger;
    const rasterized = try argparser.add_flag('r', "rasterized", .boolean, "enables RASterized mode");
    const delimited = try argparser.add_flag('I', "delimited", .boolean, "enables Delimited mode");

    const engine = try argparser.add_flag('W', "engine", .string, "sets the execution engine");

    const tracer = try argparser.add_flag('T', "tracer", .boolean, "enables the tracer");

    try argparser.parse_args(args[1..]);

    var bits: i32 = 32;

    if (std.mem.eql(u8, mode.convert([]const u8), "32")) {
        bits = 32;
    } else if (std.mem.eql(u8, mode.convert([]const u8), "8")) {
        bits = 8;
    }

    if (help.convert(bool)) {
        const src =
            \\Usage: jade [options...] filenme
            \\
            \\Options:
            \\  -h                  shows this text and exits (also --help)
            \\  -v                  shows the version and exits (also --version)
            \\  -V                  verbose mode (also --verbose)
            \\
            \\  -m[arch...]         runs the code in either 32-bit or 8-bit mode (also --mode)
            \\  -O[0|2|fast]        optimizes the code depending on the level set (also --optimize)
            \\
            \\  -t                  prints the code as English-itized text (also --text)
            \\  -d                  runs the code in debug mode (also --debug)
            \\  -r                  enables RASterized mode (also --rasterized)
            \\  -I                  runs the code in classic mode (also --delimited)
            \\  -T                  Prints the trace log (Also --trace)
            \\
            \\  --engine <eng...>   runs the code with the specified emulation
            \\                              OpenLUD
            \\                              JADE
            \\                              NexFUSE
            \\                              MercuryPIC
            \\
        ;
        std.debug.print(src, .{});
        std.process.exit(0);
    }

    if (version.convert(bool)) {
        std.debug.print("jade: version {s}\n", .{JADE_VERSION});
        std.process.exit(0);
    }

    if (argparser.positional.items.len < 1) {
        std.debug.print("jade: error: missing filename\n", .{});
        std.debug.print("jade: type `jade -h` for help\n", .{});
        std.process.exit(1);
    }

    // check if file exsits
    const dir = std.fs.Dir.access;

    dir(std.fs.cwd(), argparser.positional.items[0], .{}) catch {
        std.debug.print("jade: error: file not found: `{s}'\n", .{argparser.positional.items[0]});
        std.process.exit(1);
    };

    var preloader = jade_Preloader.create();
    var preloader8bit = jade_Preloader8Bit.create();

    if (bits == 32) {
        try preloader.load(argparser.positional.items[0]);
    } else {
        try preloader8bit.load(argparser.positional.items[0]);
    }

    var dat: []i32 = undefined;

    if (bits == 32) {
        dat = preloader.data;
    } else {
        dat = preloader8bit.convert_32bit(preloader8bit.data);
    }

    var op_level = jade_OpFlag.none;

    if (std.mem.eql(u8, optimizations.convert([]const u8), "0")) {
        op_level = .none;
    } else if (std.mem.eql(u8, optimizations.convert([]const u8), "2")) {
        op_level = .level2;
    } else if (std.mem.eql(u8, optimizations.convert([]const u8), "fast")) {
        op_level = .aggressive;
    }

    var cpu = jade_Cpu.create();
    cpu.ruleset = jade_Rules.init(engine.convert([]const u8));
    cpu.set_allocator(arena_allocator.allocator());

    if (rasterized.convert(bool)) {
        cpu.mode = .ras;
    }

    var op_frame: jade_OpFrame = undefined;

    op_frame = jade_Optimize32(arena_allocator.allocator(), op_level, dat, &cpu);

    if (tracer.convert(bool)) {
        cpu.start_tracer(arena_allocator.allocator());
    }

    var controller = jade_VJController32.new(&cpu);

    var hashy = jade_Hash.create(arena_allocator.allocator());

    const mov_fn = jade_FromU8Const(arena_allocator.allocator(), "mov");

    try hashy.set(41, mov_fn);
    try hashy.set(41, mov_fn);
    try hashy.set(41, mov_fn);

    if (as_text.convert(bool)) {
        const jade_stringify = jade_Stringify;

        std.debug.print("{s}", .{(try jade_stringify(arena_allocator.allocator(), &hashy, 32, preloader.data, cpu.ruleset.?)).read()});
        std.process.exit(0);
    }

    if (delimited.convert(bool)) {
        controller.classic_runtime = jade_OldRuntime32.new(arena_allocator.allocator());

        // add the standard runtime
        try controller.classic_runtime.bind(40, VJRuntimeAbstractions.CVJECHOFunction);
        try controller.classic_runtime.bind(41, VJRuntimeAbstractions.CVJMOVFunction);
        try controller.classic_runtime.bind(42, VJRuntimeAbstractions.CVJEACHFunction);

        try controller.run_bytecode_classic(op_frame.get_frame());
    } else {
        std.debug.print("jade: fatal: stripped bytecode is not supported (rerun with -I)\n", .{});
    }

    if (tracer.convert(bool)) {
        cpu.print_tracer();
    }

    std.process.argsFree(arena_allocator.allocator(), args);
}
