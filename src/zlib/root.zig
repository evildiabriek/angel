pub const dictionnary = @import("dictionnary.zig");
pub const fs = @import("fs.zig");
pub const net = @import("net.zig");
pub const vector = @import("vector.zig");
pub const env = @import("env.zig");
const std = @import("std");
pub fn init(gpa: std.mem.Allocator, IO: std.Io, em: *std.process.Environ.Map) !void {
    fs._init(IO, gpa);
    try net._init(gpa, IO);
    env.init(gpa, em);
}

pub fn deinit() void {
    net._deinit();
}
