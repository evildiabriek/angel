const std = @import("std");
const lexer = @import("lexer/lexer.zig");
const parser = @import("parser/parser.zig");

pub fn main(init: std.process.Init) !void {
    var lex = try lexer.lex.init(init.gpa, init.io, "/home/evild/dev/zig/angel-langage/test.agl");
    defer lex.deinit();
    var p = parser.pars.init(lex);
    try p.program();
}
