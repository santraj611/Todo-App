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
    const path: [*:0]const u8 = try alloc.dupeZ(u8, file_path);

    var db: ?*sqlite.sqlite3 = undefined;
    const rc: c_int = sqlite.sqlite3_open(path, &db);
    if (rc != sqlite.SQLITE_OK) {
        std.debug.print("Failed to Open the Database due to {any}\n", .{sqlite.sqlite3_errmsg(db)});
        return error.OpenFailed;
    }

    return .{ .db = db };
}

pub fn close(self: *Db) void {
    const rc: c_int = sqlite.sqlite3_close(self.db);
    if (rc != sqlite.SQLITE_OK) {
        std.debug.print("Failed to close the database\n", .{});
    }
}
