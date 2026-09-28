const std = @import("std");
const builtin = @import("builtin");
const vector = @import("vector.zig");

var allocator: std.mem.Allocator = undefined;
var envmap: *std.process.Environ.Map = undefined;

pub fn _init(gpa: std.mem.Allocator, em: *std.process.Environ.Map) void {
    allocator = gpa;
    envmap = em;
}

pub fn getKey(key: []const u8) ?[]const u8 {
    return envmap.get(key);
}

pub fn expandUser(str: []const u8) []const u8 {
    switch (builtin.os.tag) {
        .windows => {
            const first_pourcent = std.mem.find(u8, str, "%");
            var buff: [500]u8 = undefined;
            const reallen = blk: for (str[(first_pourcent.? + 1)..], 0..) |chr, idx| {
                if (chr == '%') break :blk idx;
                buff[idx] = chr;
            } else {
                break :blk 0;
            };
            return try allocator.dupe(u8, envmap.get(buff[0..reallen]).?);
        },
        .linux => {
            if (std.mem.eql(u8, str, "~")) return try allocator.dupe(u8, envmap.get("HOME").?);
            return try allocator.dupe(u8, envmap.get(str));
        },
    }
}

pub fn getApproximativeKey(str: []const u8) !vector.CreateVec([]const u8) {
    var vct = vector.CreateVec([]const u8).init(allocator);
    for (envmap.keys()) |key| {
        if (std.mem.find(u8, key, str)) {
            _ = try vct.append(key);
        }
    }
    return vct;
}

pub fn count() usize {
    return envmap.count();
}
