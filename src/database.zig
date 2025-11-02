const std = @import("std");
const builtin = @import("builtin");

const todo = @import("todo.zig");

const sqlite = @cImport({
    @cInclude("sqlite3.h");
});

const Db = @This();

db: ?*sqlite.sqlite3,

/// This function initializes the database
pub fn init(alloc: std.mem.Allocator) !Db {
    // create a dir for database
    const home = std.posix.getenv("HOME");
    const db_dir = try std.fs.path.join(alloc, &.{ home.?, ".local", "state", "todo-app" });
    defer alloc.free(db_dir);

    std.fs.makeDirAbsolute(db_dir) catch |err| switch (err) {
        std.fs.Dir.MakeError.PathAlreadyExists => {},
        else => return err,
    };

    const file_path = try std.fs.path.join(alloc, &.{ db_dir, "database.db" });
    defer alloc.free(file_path);
    const path = try alloc.dupeZ(u8, file_path);
    defer alloc.free(path);

    var db: ?*sqlite.sqlite3 = null;
    const rc: c_int = sqlite.sqlite3_open(path, &db);
    if (rc != sqlite.SQLITE_OK) {
        std.debug.print("Failed to Open the Database due to {any}\n", .{sqlite.sqlite3_errmsg(db)});
        return error.OpenFailed;
    }

    var errMsg: [*c]u8 = undefined;
    const sql: [:0]const u8 =
        \\CREATE TABLE IF NOT EXISTS todos (
        \\    id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\    summery TEXT,
        \\    description TEXT,
        \\    completed INTEGER
        \\ )
    ;
    const r: c_int = sqlite.sqlite3_exec(db, sql, null, null, &errMsg);

    if (r != sqlite.SQLITE_OK) {
        std.debug.print("Error Executing command\n", .{});
        sqlite.sqlite3_free(errMsg);
        return error.ExecError;
    }

    return .{ .db = db };
}

pub fn close(self: *Db) void {
    const rc: c_int = sqlite.sqlite3_close(self.db);
    if (rc != sqlite.SQLITE_OK) {
        std.debug.print("Failed to close the database\n", .{});
    }
}

pub fn exec(self: *Db, sql: [:0]const u8) !void {
    var errMsg: [*c]u8 = undefined;
    const rc: c_int = sqlite.sqlite3_exec(self.db, sql, null, null, &errMsg);

    if (rc != sqlite.SQLITE_OK) {
        std.debug.print("Error Executing command\n", .{});
        sqlite.sqlite3_free(errMsg);
        return error.ExecError;
    }
}

pub fn fetchAll(self: *Db, alloc: std.mem.Allocator) !std.array_list.Aligned(todo.Task, null) {
    const sql = "SELECT * FROM todos;";
    var stmt: ?*sqlite.sqlite3_stmt = null;

    if (sqlite.sqlite3_prepare_v2(self.db.?, sql, -1, &stmt, null) != sqlite.SQLITE_OK) {
        std.debug.print("Failed to prepare query\n", .{});
        _ = sqlite.sqlite3_close(self.db.?);
        return error.PrepareError;
    }

    const col_count = sqlite.sqlite3_column_count(stmt.?);
    // std.debug.print("Columns: {d}\n", .{col_count});

    var list: std.ArrayList(todo.Task) = try .initCapacity(alloc, 10);

    while (true) {
        const rc = sqlite.sqlite3_step(stmt.?);
        if (rc == sqlite.SQLITE_ROW) {
            var i: c_int = 0;

            var task: todo.Task = undefined;
            // const task = try alloc.create(todo.Task);
            // defer alloc.destroy(task);

            while (i < col_count) : (i += 1) {
                const text_ptr = sqlite.sqlite3_column_text(stmt.?, i);
                const text = if (text_ptr) |ptr| std.mem.span(ptr) else "NULL";
                // const owned = try alloc.dupe(u8, text);

                switch (i) {
                    0 => {
                        const id = try std.fmt.parseInt(u8, text, 10);
                        task.id = @as(usize, @intCast(id));
                    },
                    1 => {
                        task.summery = try alloc.dupe(u8, text);
                    },
                    2 => {
                        task.description = try alloc.dupe(u8, text);
                    },
                    3 => {
                        const status = try std.fmt.parseInt(u8, text, 10);
                        task.completed = @as(u1, @intCast(status));
                    },
                    else => {},
                }
            }
            try list.append(alloc, task);
        } else if (rc == sqlite.SQLITE_DONE) {
            break;
        } else {
            std.debug.print("Error stepping through rows\n", .{});
            break;
        }
    }

    _ = sqlite.sqlite3_finalize(stmt.?);
    return list;
}
