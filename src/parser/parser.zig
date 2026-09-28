const std = @import("std");
const lexer = @import("../lexer/lexer.zig");
const zlib = @import("../zlib/root.zig");

pub const ParsError = error{
    NotNameVar,
    NotFuncOrVar,
    WhereIsMyColon,
    WhereIsMyVarType,
    WhereIsMyEqual,
    WhereIsMyOpenParenthesis,
    WhereIsMyPrimary,
    WhereIsMyOperator,
    WhereIsMySemiColon,
    WhereIsMyCloseParenthesis,
};

pub const pars = struct {
    lexx: lexer.lex,
    pub fn init(lx: lexer.lex) @This() {
        return .{
            .lexx = lx,
        };
    }

    pub fn program(self: *@This()) ParsError!void {
        while (true) {
            const tkn = self.lexx.getNextToken();
            if (tkn.kind == .TOKEN_END) break;
            if (tkn.kind == .TOKEN_SYMBOL and std.mem.eql(u8, tkn.value.?, "let")) {
                try self.variables();
            } else if (tkn.kind == .TOKEN_SYMBOL) {
                try self.func(tkn.value.?); //trust trust
            } else return ParsError.NotFuncOrVar; //truust
            if (self.lexx.getNextToken().kind != .TOKEN_SEMI_COLON) return ParsError.WhereIsMySemiColon;
        }
    }

    pub fn variables(self: *@This()) ParsError!void {
        const name = self.lexx.getNextToken();
        if (name.kind != .TOKEN_SYMBOL) return ParsError.NotNameVar;
        if (self.lexx.getNextToken().kind != .TOKEN_COLON) return ParsError.WhereIsMyColon;
        const tyype = self.lexx.getNextToken();
        if (tyype.kind != .TOKEN_SYMBOL) return ParsError.WhereIsMyVarType;
        if (self.lexx.getNextToken().kind != .TOKEN_EQUAL) return ParsError.WhereIsMyEqual;
        try self.expression(); // truuuust
    }

    pub fn func(self: *@This(), _: []const u8) ParsError!void {
        if (self.lexx.getNextToken().kind != .TOKEN_OPEN_PARANTHESIS) return ParsError.WhereIsMyOpenParenthesis;
        try self.expression();
        if (self.lexx.getNextToken().kind != .TOKEN_CLOSE_PARANTHESIS) return ParsError.WhereIsMyCloseParenthesis;
    }

    pub fn expression(self: *@This()) ParsError!void {
        const op1 = self.lexx.getNextToken();
        if (op1.kind != .TOKEN_SYMBOL and op1.kind != .TOKEN_INT) return ParsError.WhereIsMyPrimary;
        const op = self.lexx.peekNextToken();
        if (op.kind != .TOKEN_PLUS) return;
        _ = self.lexx.getNextToken();
        const op2 = self.lexx.getNextToken();
        if (op2.kind != .TOKEN_SYMBOL and op2.kind != .TOKEN_INT) return ParsError.WhereIsMyPrimary;
    }
};
