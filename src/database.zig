const std = @import("std");
const builtin = @import("builtin");
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
