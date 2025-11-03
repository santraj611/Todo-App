const std = @import("std");
const Db = @import("database.zig");

pub const Task = struct {
    id: usize,
    summery: []const u8,
    description: []const u8,
    completed: u1, // 1 for completed and 0 for unfinished

    pub fn deinit(self: *Task, alloc: std.mem.Allocator) void {
        alloc.free(self.summery);
        alloc.free(self.description);
    }
};

/// Adds a task to the database
pub fn add(alloc: std.mem.Allocator, db: *Db, task: *Task) !void {
    const query: [:0]const u8 = try std.fmt.allocPrintSentinel(alloc,
        \\INSERT INTO todos (summery, description, completed) VALUES('{s}', '{s}', {d})
    , .{ task.summery, task.description, task.completed }, 0);
    defer alloc.free(query);

    // std.debug.print("summery: {s}\ndescription: {s}\ncompleted: {d}\n", .{ task.summery, task.description, task.completed });

    try db.exec(query);
}

pub fn freeTasks(list: *std.ArrayList(Task), alloc: std.mem.Allocator) void {
    for (list.items) |*task| {
        task.deinit(alloc);
    }
    list.deinit(alloc);
}
