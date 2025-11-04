const std = @import("std");
const builtin = @import("builtin");

const cli = @import("cli.zig");
const Db = @import("database.zig");
const todo = @import("todo.zig");

pub fn helpFn(w: *std.Io.Writer) !void {
    try w.print("This is a todo list app.\n", .{});
    try w.print("help              {s}\n", .{"This prints the help menu"});
    try w.print("add               {s}\n", .{"This command adds a new task"});
    try w.print("done              {s}\n", .{"This command makes a task done"});
    try w.print("remove            {s}\n", .{"This command removes the task from list"});
}

pub fn doneFn(db: *Db, gpa: std.mem.Allocator, w: *std.Io.Writer, r: *std.Io.Reader) !void {
    var tasks = try db.fetchAll(gpa);
    defer todo.freeTasks(&tasks, gpa);
    for (tasks.items) |task| {
        try w.print("{s}\n", .{"#" ** 30});
        try w.print("Id: {d}\nSummery: {s}\nDescription: {s}\nCompleted: {d}\n", .{ task.id, task.summery, task.description, task.completed });
        try w.flush();
    }
    try w.print("\n", .{});
    try w.flush();

    // get user task id from user, which to be maked done
    try w.print("Which task would you like to make done?\n", .{});
    try w.print("ID? ", .{});
    try w.flush();

    // get int from user
    const line: []u8 = try cli.getTask(gpa, r);
    defer gpa.free(line);

    const id: usize = try std.fmt.parseInt(usize, line, 10);

    try todo.markDone(db, id);
}

pub fn addFn(db: *Db, gpa: std.mem.Allocator, w: *std.Io.Writer, r: *std.Io.Reader) !void {
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
    try todo.addTask(gpa, db, task);
}

pub fn listFn(db: *Db, gpa: std.mem.Allocator, w: *std.Io.Writer) !void {
    var tasks = try db.fetchAll(gpa);
    defer todo.freeTasks(&tasks, gpa);
    for (tasks.items) |task| {
        try w.print("{s}\n", .{"#" ** 30});
        try w.print("Id: {d}\nSummery: {s}\nDescription: {s}\nCompleted: {d}\n", .{ task.id, task.summery, task.description, task.completed });
        try w.flush();
    }
    try w.print("\n", .{});
    try w.flush();
}

pub fn removeFn(db: *Db, gpa: std.mem.Allocator, w: *std.Io.Writer, r: *std.Io.Reader) !void {

    // Print All Pending Tasks.
    var tasks = try db.fetchAll(gpa);
    defer todo.freeTasks(&tasks, gpa);
    for (tasks.items) |task| {
        try w.print("{s}\n", .{"#" ** 30});
        try w.print("Id: {d}\nSummery: {s}\nDescription: {s}\nCompleted: {d}\n", .{ task.id, task.summery, task.description, task.completed });
        try w.flush();
    }
    try w.print("\n", .{});
    try w.flush();

    // get user task id from user, which to be removed
    try w.print("Which task would you like to remove?\n", .{});
    try w.print("ID? ", .{});
    try w.flush();

    // get int from user
    const line: []u8 = try cli.getTask(gpa, r);
    defer gpa.free(line);

    const id: usize = try std.fmt.parseInt(usize, line, 10);

    try todo.removeTask(db, id);

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
