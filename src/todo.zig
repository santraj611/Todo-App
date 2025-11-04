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
pub fn addTask(alloc: std.mem.Allocator, db: *Db, task: *Task) !void {
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

/// removes a task from the database
/// takes the id of task to remove it.
pub fn removeTask(db: *Db, id: usize) !void {
    var buf: [216]u8 = undefined;
    const sql: [:0]const u8 = try std.fmt.bufPrintZ(&buf, "DELETE FROM todos WHERE id = {d}", .{id});
    try db.exec(sql);
}

/// this function marks a task done.
pub fn markDone(db: *Db, id: usize) !void {
    var buf: [512]u8 = undefined;
    const sql: [:0]const u8 = try std.fmt.bufPrintZ(&buf,
        \\UPDATE todos
        \\SET completed = {d}
        \\WHERE id = {}
    , .{ 1, id });
    try db.exec(sql);
}
