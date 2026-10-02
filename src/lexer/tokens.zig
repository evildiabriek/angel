pub const tokens = enum { KEYWORD, SYMBOL, OPEN_PARANTHESIS, CLOSE_PARANTHESIS, COLON, SEMI_COLON, EQUAL, PLUS, INT, OPEN_BRACE, CLOSE_BRACE, SUBSTRACTION, END, COMMA, MULTIPLY, DIVISION, INFERIOR, SUPERIOR };

pub const s_token = struct {
    kind: tokens,
    value: ?[]const u8,
};
