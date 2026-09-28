pub const tokens = enum { TOKEN_KEYWORD, TOKEN_SYMBOL, TOKEN_OPEN_PARANTHESIS, TOKEN_CLOSE_PARANTHESIS, TOKEN_COLON, TOKEN_SEMI_COLON, TOKEN_EQUAL, TOKEN_PLUS, TOKEN_INT, TOKEN_END };

pub const s_token = struct {
    kind: tokens,
    value: ?[]const u8,
};
