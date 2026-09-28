const std = @import("std");
const string = []const u8;

pub const DicError = error{
    IndexAlreadyUsed,
    InvalidIndex,
};

fn fnv1a(data: []const u8) u64 {
    var hash: u64 = 0xcbf29ce484222325;
    for (data) |byte| {
        hash ^= byte;
        hash *%= 0x100000001b3;
    }
    return hash;
}

pub fn createDic(comptime T: type) type {
    return struct {
        items: []?T,
        allocator: std.mem.Allocator,
        maxsize: usize,

        pub fn _init(gpa: std.mem.Allocator) !@This() {
            const items = try gpa.alloc(?T, 10);
            @memset(items, null);
            return .{ .allocator = gpa, .maxsize = 0, .items = items };
        }

        pub fn append(self: *@This(), name: string, elem: T) !void {
            var finalIndex: usize = 0;
            for (0..name.len, name) |idx, chr| {
                if (idx % 2 == 0) {
                    finalIndex = finalIndex + chr;
                } else if (chr < finalIndex) {
                    finalIndex = finalIndex - chr;
                } else {
                    continue;
                }
            }
            if (finalIndex >= self.maxsize) {
                self.items = try self.allocator.realloc(self.items, finalIndex + 1);
                @memset(self.items[self.maxsize..], null);
                self.maxsize = finalIndex + 1;
            } else if (self.items[finalIndex] != null) {
                return DicError.IndexAlreadyUsed;
            }
            if (comptime @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .slice) {
                self.items[finalIndex] = try self.allocator.dupe(std.meta.Elem(T), elem);
            } else {
                self.items[finalIndex] = elem;
            }
        }

        pub fn getValue(self: *@This(), name: string) !T {
            var finalIndex: usize = 0;
            for (0..name.len, name) |idx, chr| {
                if (idx % 2 == 0) {
                    finalIndex = finalIndex + chr;
                } else if (chr < finalIndex) {
                    finalIndex = finalIndex - chr;
                } else {
                    continue;
                }
            }
            if (finalIndex >= self.maxsize or self.items[finalIndex] == null) return DicError.InvalidIndex;
            return self.items[finalIndex].?;
        }

        pub fn _deinit(self: *@This()) void {
            var i: usize = 0;
            if (comptime @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .slice) {
                while (i < self.maxsize) {
                    if (self.items[i]) |val| {
                        self.allocator.free(val);
                    }
                    i += 1;
                }
            }
            self.allocator.free(self.items);
        }
    };
}
