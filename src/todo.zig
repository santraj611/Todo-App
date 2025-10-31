pub const Task = struct {
    id: usize,
    summery: []const u8,
    // due_date: ?[]const u8,
    description: ?[]const u8,
    completed: bool,
};
