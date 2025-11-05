const std = @import("std");
const builtin = @import("builtin");

const cli = @import("cli.zig");
const cmd = @import("commands.zig");
const Db = @import("database.zig");
const todo = @import("todo.zig");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const gpa, const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
        .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    var db: *Db = try Db.init(gpa);
    defer db.close(gpa);

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    // writer
    var writer_buffer: [1024]u8 = undefined;
    var stdout: std.fs.File.Writer = std.fs.File.stdout().writer(&writer_buffer);
    const w: *std.Io.Writer = &stdout.interface;

    // reader
    var reader_buff: [1024]u8 = undefined;
    var stdin: std.fs.File.Reader = std.fs.File.stdin().reader(&reader_buff);
    const r: *std.Io.Reader = &stdin.interface;

    // iter over args
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "add")) try cmd.addFn(db, gpa, w, r);
        if (std.mem.eql(u8, arg, "list")) try cmd.listFn(db, gpa, w);
        if (std.mem.eql(u8, arg, "remove")) try cmd.removeFn(db, gpa, w, r);
        if (std.mem.eql(u8, arg, "done")) try cmd.doneFn(db, gpa, w, r);
    } else {
        try cmd.helpFn(w);
    }
}
