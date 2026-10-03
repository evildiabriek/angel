const std = @import("std");

pub const operations = enum { ASSIGN, PLUS, SUBSTRACTION, MULTIPLY, DIVISION, ARGUMENT, CALL, JMP, JMPIFNOT, INFERIOR, SUPERIOR, OL_AND, OL_OR, COMPARE };

pub const operandsType = enum {
    VALUE,
    STRING,
    TMP,
    LABEL,
};

pub const operands = union(operandsType) {
    VALUE: i32,
    STRING: []const u8,
    TMP: u32,
    LABEL: usize,
};

pub const irm = struct {
    operation: operations,
    op1: operands,
    op2: ?operands,
    result: ?operands,
};
