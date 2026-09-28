const std = @import("std");
const vec = @import("vector.zig");
const string = []const u8;
const permission = std.Io.Dir.Permissions;

var IO: std.Io = undefined;
var allocator: std.mem.Allocator = undefined;

const FsFolderError = error{
    AlreadyExist,
    AlreadyNotExist,
    NotExist,
};

const FsFileError = error{
    AlreadyExist,
    AlreadyNotExist,
    NotExist,
};

pub fn _init(io: std.Io, gpa: std.mem.Allocator) void {
    IO = io;
    allocator = gpa;
}

fn cutPath(path: string) struct { []const u8, []const u8 } {
    var buffpath = path;
    if (std.mem.endsWith(u8, buffpath, "/")) buffpath = buffpath[0 .. buffpath.len - 1];
    var idx = std.mem.findLast(u8, buffpath, "/");
    if (idx.? == 0) idx.? = idx.? + 1;
    return .{ buffpath[0..idx.?], buffpath[idx.? + 1 .. buffpath.len] };
}

pub const Folder = struct {
    const self = @This();
    pub fn createFolder(path: string, perm: ?std.Io.Dir.Permissions) !bool {
        if (self.ifExist(path)) return FsFolderError.AlreadyExist;
        std.Io.Dir.createDirAbsolute(IO, path, perm orelse .default_dir) catch {
            return false;
        };
        return true;
    }

    pub fn deleteFolder(path: string) !bool {
        if (!self.ifExist(path)) return FsFolderError.AlreadyNotExist;
        std.Io.Dir.deleteDirAbsolute(IO, path) catch {
            return false;
        };
        return true;
    }

    pub fn deleteAllFolder(path: string) !bool {
        if (!self.ifExist(path)) return FsFolderError.AlreadyNotExist;
        std.Io.Dir.deleteDirAbsolute(IO, path) catch |err| {
            switch (err) {
                error.DirNotEmpty => {
                    var buffpath = path;
                    if (std.mem.endsWith(u8, buffpath, "/")) buffpath = buffpath[0 .. buffpath.len - 1];
                    const idx = std.mem.findLast(u8, buffpath, "/");
                    var tmpdir = try std.Io.Dir.openDirAbsolute(IO, buffpath[0..idx.?], .{});
                    defer tmpdir.close(IO);
                    try std.Io.Dir.deleteTree(tmpdir, IO, buffpath[idx.? + 1 .. buffpath.len]);
                },
                else => return false,
            }
        };
        return true;
    }

    pub fn listElements(path: string) !vec.CreateVec([]const u8) {
        if (!self.ifExist(path)) return FsFolderError.NotExist;
        var dir = try std.Io.Dir.openDirAbsolute(IO, path, .{ .iterate = true });
        defer dir.close(IO);
        var it = dir.iterate();
        var vector = vec.CreateVec([]const u8).init(allocator);
        while (try it.next(IO)) |entry| {
            _ = try vector.append(entry.name);
        }
        return vector;
    }

    pub fn ifExist(path: string) bool {
        _ = std.Io.Dir.openDirAbsolute(IO, path, .{}) catch {
            return false;
        };
        return true;
    }
};

pub const File = struct {
    const self = @This();

    pub fn ifExist(path: string) bool {
        _ = std.Io.Dir.openFileAbsolute(IO, path, .{}) catch {
            return false;
        };
        return true;
    }

    pub fn createFile(path: string, flags: std.Io.Dir.CreateFileOptions) !bool {
        if (self.ifExist(path)) return FsFileError.AlreadyExist;
        _ = std.Io.Dir.createFileAbsolute(IO, path, flags) catch {
            return false;
        };
        return true;
    }

    pub fn deleteFile(path: string) !bool {
        if (!self.ifExist(path)) return FsFileError.AlreadyNotExist;
        _ = std.Io.Dir.deleteFileAbsolute(IO, path) catch {
            return false;
        };
        return true;
    }

    pub fn readFile(path: string, limit: ?std.Io.Limit) ![]const u8 {
        if (!self.ifExist(path)) return FsFileError.NotExist;
        const part = cutPath(path);
        var tmpdir = try std.Io.Dir.openDirAbsolute(IO, part.@"0", .{});
        defer tmpdir.close(IO);
        return std.Io.Dir.readFileAlloc(tmpdir, IO, part.@"1", allocator, limit orelse .unlimited);
    }

    pub fn writeFile(path: string, content: string) !void {
        if (!self.ifExist(path)) return FsFileError.NotExist;
        var f = try std.Io.Dir.openFileAbsolute(IO, path, .{ .mode = .read_write });
        defer f.close(IO);
        var buf: [10524]u8 = undefined;
        var fw = f.writer(IO, &buf);
        var fwi = &fw.interface;
        _ = try fwi.write(content);
        try fwi.flush();
    }

    pub fn writeFileSeek(path: string, content: string, pos: u64) !void {
        if (!self.ifExist(path)) return FsFileError.NotExist;
        var f = try std.Io.Dir.openFileAbsolute(IO, path, .{ .mode = .read_write });
        defer f.close(IO);
        var buf: [10524]u8 = undefined;
        var fw = f.writer(IO, &buf);
        var fwi = &fw.interface;
        try fw.seekTo(pos);
        _ = try fwi.write(content);
        try fw.flush();
    }
};
