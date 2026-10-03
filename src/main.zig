const std = @import("std");
const lexer = @import("lexer/lexer.zig");
const parser = @import("parser/parser.zig");
const interpreter = @import("Interpreter/interpreter.zig");

pub fn main(init: std.process.Init) !void {
    var lex = try lexer.lex.init(init.gpa, init.io, "/home/evild/dev/zig/angel-langage/test.agl");
    defer lex.deinit();
    var p = parser.pars.init(lex, init.gpa);
    defer p.deinit();
    errdefer p.errordeinit();
    try p.program();
    for (p.functions.items) |itm| {
        std.log.debug("name: {s}", .{itm.name});
        for (itm.code.items) |itm2| {
            std.log.debug("  {any}", .{itm2});
        }
    }
    var itr = interpreter.inter.init(p.functions.getLast().code, init.gpa, p.functions);
    defer itr.deinit();
    while (!try itr.step()) {}
}
