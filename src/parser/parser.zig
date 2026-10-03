const std = @import("std");
const lexer = @import("../lexer/lexer.zig");
const zlib = @import("../zlib/root.zig");
const tokens = @import("../lexer/tokens.zig");
const ir = @import("../IR/IR.zig");

pub const ParsError = error{
    NotNameVar,
    NotFuncOrVar,
    ExistingVar,
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
    WhereIsMyStatment,
    WhereIsMyVariable,
};

pub const s_func = struct {
    name: []const u8,
    code: zlib.vector.CreateVec(ir.irm),
    vars: zlib.vector.CreateVec([]const u8),
    fn addCode(self: *@This(), irmm: ir.irm) usize {
        return self.code.append(irmm) catch {
            unreachable; // On met la poussière sous le tapîs
        };
    }

    fn addVar(self: *@This(), str: []const u8) usize {
        return self.vars.append(str) catch {
            unreachable; // On met la poussière sous le tapîs
        };
    }

    fn hasVar(self: *@This(), str: []const u8) bool {
        for (self.vars.items) |itm| {
            if (std.mem.eql(u8, itm, str)) return true;
        }
        return false;
    }
};

pub const pars = struct {
    lexx: lexer.lex,
    allocator: std.mem.Allocator,
    tmpcounter: u32,
    fstack: zlib.vector.CreateVec(s_func),
    functions: zlib.vector.CreateVec(s_func),
    pub fn init(lx: lexer.lex, gpa: std.mem.Allocator) @This() {
        return .{ .lexx = lx, .allocator = gpa, .tmpcounter = 0, .fstack = .init(gpa), .functions = .init(gpa) };
    }

    fn addCode(self: *@This(), irmm: ir.irm) usize {
        //var tmp = self.fstack.getLast();
        return self.fstack.items[self.fstack.n_of_element - 1].code.append(irmm) catch {
            unreachable;
        };
    }

    fn addVar(self: *@This(), str: []const u8) usize {
        //var tmp = self.fstack.getLast();
        return self.fstack.items[self.fstack.n_of_element - 1].vars.append(str) catch {
            unreachable;
        };
    }

    fn hasVar(self: *@This(), str: []const u8) bool {
        return self.fstack.items[self.fstack.n_of_element - 1].hasVar(str);
    }

    fn getTmp(self: *@This()) u32 {
        defer self.tmpcounter += 1;
        return self.tmpcounter;
    }

    pub fn program(self: *@This()) !void {
        _ = self.fstack.append(.{ .name = "<root>", .code = .init(self.allocator), .vars = .init(self.allocator) }) catch {
            unreachable;
        };
        while (true) {
            const tkn = self.lexx.peekNextToken();
            if (tkn.kind == .END) break;
            try self.statements();
        }
        _ = self.functions.append(self.fstack.getLast()) catch {
            unreachable;
        };
        self.fstack.remove(self.fstack.length() - 1) catch {
            unreachable;
        };
    }

    pub fn statements(self: *@This()) ParsError!void {
        const tkn = self.lexx.getNextToken();
        if (tkn.kind == .SYMBOL and std.mem.eql(u8, tkn.value.?, "let")) {
            try self.variables();
        } else if (tkn.kind == .SYMBOL and std.mem.eql(u8, tkn.value.?, "fn")) {
            try self.defFunc();
        } else if (tkn.kind == .SYMBOL and std.mem.eql(u8, tkn.value.?, "if")) {
            try self.iff(); // trust trust
        } else if (tkn.kind == .SYMBOL and std.mem.eql(u8, tkn.value.?, "while")) {
            try self.whilee();
            //} else if (tkn.kind == .SYMBOL and std.mem.eql(u8, tkn.value.?, "for")) {
            //try self.forr();
        } else if (tkn.kind == .SYMBOL) {
            const next = self.lexx.peekNextToken();
            if (next.kind == .OPEN_PARANTHESIS) {
                try self.func(tkn.value.?);
            } else if (next.kind == .EQUAL) {
                try self.assign(tkn.value.?); // trust trust
            }
        } else return ParsError.NotFuncOrVar; //truust
    }

    pub fn assign(self: *@This(), name: []const u8) !void {
        if (!self.hasVar(name)) return ParsError.WhereIsMyVariable;
        if (self.lexx.getNextToken().kind != .EQUAL) return ParsError.WhereIsMyEqual;
        const new_val = try self.expression();
        if (self.lexx.getNextToken().kind != .SEMI_COLON) return ParsError.WhereIsMySemiColon;
        _ = self.addCode(.{ .operation = .ASSIGN, .op1 = .{ .STRING = name }, .op2 = new_val, .result = null });
    }

    pub fn variables(self: *@This()) !void {
        const name = self.lexx.getNextToken();
        if (name.kind != .SYMBOL) return ParsError.NotNameVar;
        if (self.lexx.getNextToken().kind != .COLON) return ParsError.WhereIsMyColon;
        const tyype = self.lexx.getNextToken();
        if (tyype.kind != .SYMBOL) return ParsError.WhereIsMyVarType;
        if (self.lexx.getNextToken().kind != .EQUAL) return ParsError.WhereIsMyEqual;
        const jsp = try self.expression(); // truuuust
        if (self.lexx.getNextToken().kind != .SEMI_COLON) return ParsError.WhereIsMySemiColon;
        if (self.hasVar(name.value.?)) return ParsError.ExistingVar;
        _ = self.addVar(name.value.?);
        _ = self.addCode(.{ .operation = .ASSIGN, .op1 = .{ .STRING = name.value.? }, .op2 = jsp, .result = null });
    }

    pub fn func(self: *@This(), name: []const u8) !void {
        if (self.lexx.getNextToken().kind != .OPEN_PARANTHESIS) return ParsError.WhereIsMyOpenParenthesis;
        const jsp = try self.expression();
        if (self.lexx.getNextToken().kind != .CLOSE_PARANTHESIS) return ParsError.WhereIsMyCloseParenthesis;
        if (self.lexx.getNextToken().kind != .SEMI_COLON) return ParsError.WhereIsMySemiColon;
        _ = self.addCode(.{ .operation = .ARGUMENT, .op1 = jsp, .op2 = null, .result = null });
        _ = self.addCode(.{ .operation = .CALL, .op1 = .{ .STRING = name }, .op2 = null, .result = null });
    }

    pub fn defFunc(self: *@This()) !void {
        const name = self.lexx.getNextToken();
        if (name.kind != .SYMBOL) return ParsError.WhereIsMyFuncName;
        _ = self.fstack.append(.{ .name = name.value.?, .code = .init(self.allocator), .vars = .init(self.allocator) }) catch {
            unreachable;
        };
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
        while (self.lexx.peekNextToken().kind != .CLOSE_BRACE) try self.statements();
        _ = self.lexx.getNextToken();
        _ = self.functions.append(self.fstack.getLast()) catch {
            unreachable;
        };
        self.fstack.remove(self.fstack.length() - 1) catch {
            unreachable;
        };
    }

    pub fn iff(self: *@This()) !void {
        if (self.lexx.getNextToken().kind != .OPEN_PARANTHESIS) return ParsError.WhereIsMyOpenParenthesis;
        const jsp = try self.expression();
        if (self.lexx.getNextToken().kind != .CLOSE_PARANTHESIS) return ParsError.WhereIsMyCloseParenthesis;
        if (self.lexx.getNextToken().kind != .OPEN_BRACE) return ParsError.WhereIsMyOpenBrace;
        const idx = self.addCode(.{ .operation = .JMPIFNOT, .op1 = jsp, .op2 = null, .result = null });
        while (self.lexx.peekNextToken().kind != .CLOSE_BRACE) try self.statements();
        var tmp = self.fstack.getLast();
        tmp.code.items[idx].result = .{ .LABEL = tmp.code.length() };
        _ = self.lexx.getNextToken();
    }

    pub fn whilee(self: *@This()) !void {
        if (self.lexx.getNextToken().kind != .OPEN_PARANTHESIS) return ParsError.WhereIsMyOpenParenthesis;
        var tmp = self.fstack.getLast();
        const alen = tmp.code.length();
        const jsp = try self.expression();
        if (self.lexx.getNextToken().kind != .CLOSE_PARANTHESIS) return ParsError.WhereIsMyCloseParenthesis;
        if (self.lexx.getNextToken().kind != .OPEN_BRACE) return ParsError.WhereIsMyOpenBrace;
        const idx = self.addCode(.{ .operation = .JMPIFNOT, .op1 = jsp, .op2 = null, .result = null });
        while (self.lexx.peekNextToken().kind != .CLOSE_BRACE) try self.statements();
        _ = self.addCode(.{ .operation = .JMP, .op1 = .{ .LABEL = alen }, .op2 = null, .result = null });
        self.fstack.items[self.fstack.n_of_element - 1].code.items[idx].result = .{ .LABEL = tmp.code.length() };
        _ = self.lexx.getNextToken();
    }

    //    pub fn forr(self: *@This()) !void {
    //        if (self.lexx.getNextToken().kind != .OPEN_PARANTHESIS) return ParsError.WhereIsMyOpenParenthesis;
    //        try self.expression();
    //        if (self.lexx.getNextToken().kind != .CLOSE_PARANTHESIS) return ParsError.WhereIsMyCloseParenthesis;
    //        if (self.lexx.getNextToken().kind != .OPEN_BRACE) return ParsError.WhereIsMyOpenBrace;
    //        while (self.lexx.peekNextToken().kind != .CLOSE_BRACE) try self.statements();
    //        _ = self.lexx.getNextToken();
    //    }

    fn tokenToPrimary(self: *@This(), tkn: tokens.s_token) !ir.operands {
        if (tkn.kind == .SYMBOL) {
            if (!self.hasVar(tkn.value.?)) return ParsError.WhereIsMyVariable;
            return .{ .STRING = tkn.value.? };
        } else if (tkn.kind == .INT) {
            return .{ .VALUE = std.fmt.parseInt(i32, tkn.value.?, 10) catch {
                return ParsError.WhereIsMyPrimary;
            } };
        } else unreachable;
    }

    pub fn expression(self: *@This()) !ir.operands {
        var opp: ir.operands = try self.primary();
        var op = self.lexx.peekNextToken();
        const tab = [_]tokens.tokens{ .PLUS, .SUBSTRACTION, .MULTIPLY, .DIVISION, .INFERIOR, .SUPERIOR, .OL_AND, .OL_OR, .COMPARE };
        while (std.mem.containsAtLeastScalar2(tokens.tokens, &tab, op.kind, 1)) {
            _ = self.lexx.getNextToken();
            const tmp: ir.operations = blk: {
                switch (op.kind) {
                    .PLUS => break :blk .PLUS,
                    .SUBSTRACTION => break :blk .SUBSTRACTION,
                    .MULTIPLY => break :blk .MULTIPLY,
                    .DIVISION => break :blk .DIVISION,
                    .INFERIOR => break :blk .INFERIOR,
                    .SUPERIOR => break :blk .SUPERIOR,
                    .OL_AND => break :blk .OL_AND,
                    .OL_OR => break :blk .OL_OR,
                    .COMPARE => break :blk .COMPARE,
                    else => unreachable,
                }
            };
            const jsp = ir.irm{ .operation = tmp, .op1 = opp, .op2 = try self.primary(), .result = .{ .TMP = self.getTmp() } };
            _ = self.addCode(jsp);
            opp = jsp.result.?;
            op = self.lexx.peekNextToken();
        }
        return opp;
    }

    pub fn primary(self: *@This()) ParsError!ir.operands {
        const op1 = self.lexx.getNextToken();
        if (op1.kind == .SYMBOL or op1.kind == .INT) {
            return self.tokenToPrimary(op1);
        } else if (op1.kind == .OPEN_PARANTHESIS) {
            const ret = try self.expression();
            if (self.lexx.getNextToken().kind != .CLOSE_PARANTHESIS) {
                return ParsError.WhereIsMyCloseParenthesis;
            }
            return ret;
        } else if (op1.kind == .SUBSTRACTION) {
            const irm = try self.primary();
            const jsp = ir.irm{ .operation = .SUBSTRACTION, .op1 = .{ .VALUE = 0 }, .op2 = irm, .result = .{ .TMP = self.getTmp() } };
            _ = self.addCode(jsp);
            return jsp.result.?;
        } else {
            return ParsError.WhereIsMyPrimary;
        }
    }

    pub fn deinit(self: *@This()) void {
        for (0..self.functions.items.len) |idx| {
            self.functions.items[idx].code.deinit();
            self.functions.items[idx].vars.deinit();
        }
        self.fstack.deinit();
        self.functions.deinit();
    }

    pub fn errordeinit(self: *@This()) void {
        for (0..self.fstack.items.len) |idx| {
            self.fstack.items[idx].code.deinit();
            self.fstack.items[idx].vars.deinit();
        }
    }
};
