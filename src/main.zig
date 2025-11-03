const std = @import("std");
const builtin = @import("builtin");

const cli = @import("cli.zig");
const cmd = @import("commands.zig");
const Db = @import("database.zig");
const todo = @import("todo.zig");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const native_os = builtin.target.os.tag;
    const gpa, const is_debug = gpa: {
        if (native_os == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    var db: Db = try Db.init(gpa);
    defer db.close();

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
        if (std.mem.eql(u8, arg, "add")) {
            try w.print("What Would You like To Add?\n", .{});
            try w.print("Summery: ", .{});
            try w.flush();
            const summery = try cli.getTask(gpa, r);
            defer gpa.free(summery);

            try w.print("Description: ", .{});
            try w.flush();
            const description = try cli.getTask(gpa, r);
            defer gpa.free(description);

            // Add this task to db
            const task: *todo.Task = try gpa.create(todo.Task);
            defer gpa.destroy(task);
            task.completed = 0;
            task.summery = summery;
            task.description = description;
            try todo.add(gpa, &db, task);
        }

        if (std.mem.eql(u8, arg, "list")) {
            var tasks = try db.fetchAll(gpa);
            defer todo.freeTasks(&tasks, gpa);
            for (tasks.items) |task| {
                try w.print("Id: {d}\nSummery: {s}\nDescription: {s}\nCompleted: {d}\n", .{ task.id, task.summery, task.description, task.completed });
                try w.flush();
            }
        }

        if (std.mem.eql(u8, arg, "remove")) {
            // Print All Pending Tasks.
            // const tasks: []todo.Task = undefined;
            // for (tasks) |t| {
            //     w.print("#{d}. {s}\n", .{ t.id, t.summery });
            // }

            // get user task id from user, which to be removed
            // try w.print("Which task would you like to remove?\n", .{});
            // try w.print("ID? ", .{});
            // try w.flush();
            // const id: u8 = try r.takeByte();

            // check if it's a valid id.
            // for (tasks) |t| {
            //     // if valid remove task from db
            //     if (t.id == id) {
            // Remove Task from DB
            // try w.print("Task removed successfuly", .{});
            //     }
            // } else {
            //     std.debug.print("Invalid ID?\n", .{});
            //     return;
            // }
        }
    }
}
