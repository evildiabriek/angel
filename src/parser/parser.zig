const std = @import("std");
const lexer = @import("../lexer/lexer.zig");
const zlib = @import("../zlib/root.zig");
const tokens = @import("../lexer/tokens.zig");

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
    WhereIsMyFuncName,
    WhereIsMyFuncReturnType,
    WhereIsMyOpenBrace,
    WhereIsMyNameVarParam,
    WhereIsMyTypeVarParam,
    WhereIsMyComma,
};

pub const pars = struct {
    lexx: lexer.lex,
    allocator: std.mem.Allocator,
    pub fn init(lx: lexer.lex, gpa: std.mem.Allocator) @This() {
        return .{
            .lexx = lx,
            .allocator = gpa,
        };
    }

    pub fn program(self: *@This()) !void {
        while (true) {
            const tkn = self.lexx.getNextToken();
            if (tkn.kind == .END) break;
            if (tkn.kind == .SYMBOL and std.mem.eql(u8, tkn.value.?, "let")) {
                try self.variables();
            } else if (tkn.kind == .SYMBOL and std.mem.eql(u8, tkn.value.?, "fn")) {
                try self.defFunc();
            } else if (tkn.kind == .SYMBOL) {
                try self.func(tkn.value.?); //trust trust
            } else return ParsError.NotFuncOrVar; //truust
        }
    }

    pub fn variables(self: *@This()) !void {
        const name = self.lexx.getNextToken();
        if (name.kind != .SYMBOL) return ParsError.NotNameVar;
        if (self.lexx.getNextToken().kind != .COLON) return ParsError.WhereIsMyColon;
        const tyype = self.lexx.getNextToken();
        if (tyype.kind != .SYMBOL) return ParsError.WhereIsMyVarType;
        if (self.lexx.getNextToken().kind != .EQUAL) return ParsError.WhereIsMyEqual;
        try self.expression(); // truuuust
        if (self.lexx.getNextToken().kind != .SEMI_COLON) return ParsError.WhereIsMySemiColon;
    }

    pub fn func(self: *@This(), _: []const u8) !void {
        if (self.lexx.getNextToken().kind != .OPEN_PARANTHESIS) return ParsError.WhereIsMyOpenParenthesis;
        try self.expression();
        if (self.lexx.getNextToken().kind != .CLOSE_PARANTHESIS) return ParsError.WhereIsMyCloseParenthesis;
        if (self.lexx.getNextToken().kind != .SEMI_COLON) return ParsError.WhereIsMySemiColon;
    }

    pub fn defFunc(self: *@This()) !void {
        const name = self.lexx.getNextToken();
        if (name.kind != .SYMBOL) return ParsError.WhereIsMyFuncName;
        if (self.lexx.getNextToken().kind != .OPEN_PARANTHESIS) return ParsError.WhereIsMyOpenParenthesis;
        while (self.lexx.peekNextToken().kind != .CLOSE_PARANTHESIS) {
            const name2 = self.lexx.getNextToken();
            if (name2.kind != .SYMBOL) return ParsError.WhereIsMyNameVarParam;
            if (self.lexx.getNextToken().kind != .COLON) return ParsError.WhereIsMyColon;
            const tyype2 = self.lexx.getNextToken();
            if (tyype2.kind != .SYMBOL) return ParsError.WhereIsMyTypeVarParam;
            const tmp = self.lexx.peekNextToken();
            if (tmp.kind == .COMMA) _ = self.lexx.getNextToken();
        }
        if (self.lexx.getNextToken().kind != .CLOSE_PARANTHESIS) return ParsError.WhereIsMyCloseParenthesis;
        const tyype = self.lexx.getNextToken();
        if (tyype.kind != .SYMBOL) return ParsError.WhereIsMyFuncReturnType;
        if (self.lexx.getNextToken().kind != .OPEN_BRACE) return ParsError.WhereIsMyOpenBrace;
        while (self.lexx.peekNextToken().kind != .CLOSE_BRACE) _ = self.lexx.getNextToken();
        _ = self.lexx.getNextToken();
    }

    pub fn expression(self: *@This()) !void {
        const op1 = self.lexx.getNextToken();
        if (op1.kind != .SYMBOL and op1.kind != .INT) return ParsError.WhereIsMyPrimary;
        const op = self.lexx.peekNextToken();
        if (op.kind != .PLUS and op.kind != .SUBSTRACTION) return;
        _ = self.lexx.getNextToken();
        const op2 = self.lexx.getNextToken();
        if (op2.kind != .SYMBOL and op2.kind != .INT) return ParsError.WhereIsMyPrimary;
    }
};
