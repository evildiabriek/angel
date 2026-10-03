const std = @import("std");
const zlib = @import("../zlib/root.zig");
const ir = @import("../IR/IR.zig");
const parser = @import("../parser/parser.zig");

// Trash func
fn boolToInt(b: bool) i32 {
    if (b) {
        return 1;
    } else {
        return 0;
    }
}

pub const inter = struct {
    code: zlib.vector.CreateVec(ir.irm),
    cursor: usize,
    vars: std.StringHashMap(i32),
    tmpvars: std.AutoHashMap(u32, i32),
    argv: zlib.vector.CreateVec(i32),
    funcs: zlib.vector.CreateVec(parser.s_func),
    itr: ?*inter,
    pub fn init(code: zlib.vector.CreateVec(ir.irm), gpa: std.mem.Allocator, funcs: zlib.vector.CreateVec(parser.s_func)) @This() {
        return .{ .code = code, .cursor = 0, .vars = .init(gpa), .tmpvars = .init(gpa), .argv = .init(gpa), .funcs = funcs, .itr = null };
    }

    pub fn step(self: *@This()) !bool {
        if (self.itr != null) {
            const bstep = try self.itr.?.step();
            self.itr.?.deinit();
            if (bstep == true) self.itr = null;
        }
        if (self.cursor >= self.code.length()) return true;
        const fcode = try self.code.getValue(self.cursor);
        self.cursor += 1;
        try switch (fcode.operation) {
            .ASSIGN => self.setValue(fcode.op1, self.getValue(fcode.op2.?)),
            .PLUS => self.setValue(fcode.result.?, self.getValue(fcode.op1) + self.getValue(fcode.op2.?)),
            .SUBSTRACTION => self.setValue(fcode.result.?, self.getValue(fcode.op1) - self.getValue(fcode.op2.?)),
            .MULTIPLY => self.setValue(fcode.result.?, self.getValue(fcode.op1) * self.getValue(fcode.op2.?)),
            .DIVISION => self.setValue(fcode.result.?, @divTrunc(self.getValue(fcode.op1), self.getValue(fcode.op2.?))),
            .INFERIOR => self.setValue(fcode.result.?, boolToInt(self.getValue(fcode.op1) < self.getValue(fcode.op2.?))),
            .SUPERIOR => self.setValue(fcode.result.?, boolToInt(self.getValue(fcode.op1) > self.getValue(fcode.op2.?))),
            .OL_AND => self.setValue(fcode.result.?, boolToInt(self.getValue(fcode.op1) != 0 and self.getValue(fcode.op2.?) != 0)),
            .OL_OR => self.setValue(fcode.result.?, boolToInt(self.getValue(fcode.op1) != 0 or self.getValue(fcode.op2.?) != 0)),
            .COMPARE => self.setValue(fcode.result.?, boolToInt(self.getValue(fcode.op1) == self.getValue(fcode.op2.?))),
            .ADD_EQUAL => self.setValue(fcode.op1, self.getValue(fcode.op1) + self.getValue(fcode.op2.?)),
            .PLUSPLUS => self.setValue(fcode.op1, self.getValue(fcode.op1) + self.getValue(fcode.op2.?)),
            .SUBSTRACTION_EQUAL => self.setValue(fcode.op1, self.getValue(fcode.op1) - self.getValue(fcode.op2.?)),
            .MULTIPLY_EQUAL => self.setValue(fcode.op1, self.getValue(fcode.op1) * self.getValue(fcode.op2.?)),
            .DIVISION_EQUAL => self.setValue(fcode.op1, @divTrunc(self.getValue(fcode.op1), self.getValue(fcode.op2.?))),
            .ARGUMENT => _ = try self.argv.append(self.getValue(fcode.op1)),
            .CALL => {
                for (self.funcs.items) |val| {
                    if (std.mem.eql(u8, val.name, fcode.op1.STRING)) {
                        self.itr = try self.code.allocator.create(inter);
                        self.itr.?.* = .init(val.code, val.code.allocator, self.funcs);
                        break;
                    }
                }
                if (std.mem.eql(u8, fcode.op1.STRING, "print")) {
                    for (self.argv.items) |arg| {
                        std.debug.print("{d}\n", .{arg});
                    }
                }
                try self.argv.clear();
            },
            .JMP => self.cursor = fcode.op1.LABEL,
            .JMPIFNOT => {
                if (self.getValue(fcode.op1) == 0) self.cursor = fcode.result.?.LABEL;
            },
        };
        return false;
    }

    pub fn setValue(self: *@This(), vidx: ir.operands, val: i32) !void {
        try switch (vidx) {
            .STRING => self.vars.put(vidx.STRING, val),
            .TMP => self.tmpvars.put(vidx.TMP, val),
            else => unreachable, // On mets la poussière sous le tapis
        };
    }

    pub fn getValue(self: *@This(), vidx: ir.operands) i32 {
        switch (vidx) {
            .VALUE => return vidx.VALUE,
            .STRING => return self.vars.get(vidx.STRING).?,
            .TMP => return self.tmpvars.get(vidx.TMP).?,
            else => unreachable,
        }
    }

    pub fn deinit(self: *@This()) void {
        self.argv.deinit();
        self.vars.deinit();
        self.tmpvars.deinit();
        if (self.itr) |itr| {
            self.code.allocator.destroy(itr);
        }
    }
};
