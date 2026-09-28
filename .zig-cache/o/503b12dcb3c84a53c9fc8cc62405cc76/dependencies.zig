pub const packages = struct {
    pub const @"Zlib-0.0.0-mbriNcRmAACwBMcDjaaj_-CxPnU56ttHN8iFavHUGbB8" = struct {
        pub const build_root = "/home/evild/dev/zig/angel-langage/zig-pkg/Zlib-0.0.0-mbriNcRmAACwBMcDjaaj_-CxPnU56ttHN8iFavHUGbB8";
        pub const build_zig = @import("Zlib-0.0.0-mbriNcRmAACwBMcDjaaj_-CxPnU56ttHN8iFavHUGbB8");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "Zlib", "Zlib-0.0.0-mbriNcRmAACwBMcDjaaj_-CxPnU56ttHN8iFavHUGbB8" },
};
