const std = @import("std");
const tokens = @import("tokens.zig");
const zlib = @import("../zlib/root.zig");

pub const LexError = error{
    InvalidCharacter,
};

pub const lex = struct {
    buff_file: []const u8,
    cursor: usize,
    io: std.Io,
    allocator: std.mem.Allocator,

    pub fn init(gpa: std.mem.Allocator, IO: std.Io, path: []const u8) !@This() {
        zlib.fs._init(IO, gpa);
        return .{
            .buff_file = try zlib.fs.File.readFile(path, null),
            .cursor = 0,
            .io = IO,
            .allocator = gpa,
        };
    }

    pub fn isEndLen(self: *@This()) bool {
        if (self.cursor >= self.buff_file.len) return true;
        return false;
    }

    fn skipWhiteSpace(self: *@This()) void {
        while (self.cursor < self.buff_file.len and
            (self.buff_file[self.cursor] == ' ' or
                self.buff_file[self.cursor] == '\n' or
                self.buff_file[self.cursor] == '\t')) self.cursor += 1;
    }

    pub fn getNextToken(self: *@This()) tokens.s_token {
        skipWhiteSpace(self);
        if (isEndLen(self)) return .{ .kind = .END, .value = null };
        if (std.ascii.isAlphabetic(self.buff_file[self.cursor])) {
            const lcursor = self.cursor;
            while (std.ascii.isAlphanumeric(self.buff_file[self.cursor]) and !isEndLen(self)) self.cursor += 1;
            return .{
                .kind = .SYMBOL,
                .value = self.buff_file[lcursor..self.cursor],
            };
        } else if (std.ascii.isDigit(self.buff_file[self.cursor])) {
            const lcursor = self.cursor;
            while (std.ascii.isDigit(self.buff_file[self.cursor]) and !isEndLen(self)) self.cursor += 1;
            return .{
                .kind = .INT,
                .value = self.buff_file[lcursor..self.cursor],
            };
        } else {
            defer self.cursor += 1;
            switch (self.buff_file[self.cursor]) {
                '+' => return .{ .kind = .PLUS, .value = null },
                '=' => return .{ .kind = .EQUAL, .value = null },
                ':' => return .{ .kind = .COLON, .value = null },
                ';' => return .{ .kind = .SEMI_COLON, .value = null },
                '(' => return .{ .kind = .OPEN_PARANTHESIS, .value = null },
                ')' => return .{ .kind = .CLOSE_PARANTHESIS, .value = null },
                '{' => return .{ .kind = .OPEN_BRACE, .value = null },
                '}' => return .{ .kind = .CLOSE_BRACE, .value = null },
                '-' => return .{ .kind = .SUBSTRACTION, .value = null },
                else => unreachable,
            }
        }
    }

    pub fn peekNextToken(self: *@This()) tokens.s_token {
        const lcursor = self.cursor;
        const stok = self.getNextToken();
        self.cursor = lcursor;
        return stok;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.buff_file);
    }
};
