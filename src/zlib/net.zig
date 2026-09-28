const std = @import("std");
var allocator: std.mem.Allocator = undefined;
var IO: std.Io = undefined;
const string = []const u8;
var order: []u8 = undefined;
var used = false;

pub fn _init(gpa: std.mem.Allocator, io: std.Io) !void {
    allocator = gpa;
    IO = io;
    order = undefined;
}

pub fn sendWebhook(webhook: string, msg: string, json_payload: ?string) !void {
    var client = std.http.Client{ .allocator = allocator, .io = IO };
    defer client.deinit();
    const buf = try std.fmt.allocPrint(allocator, "{{\"content\":\"{s}\"}}", .{msg});
    defer allocator.free(buf);
    _ = try client.fetch(.{
        .location = .{ .uri = try std.Uri.parse(webhook) },
        .method = .POST,
        .headers = .{ .content_type = .{ .override = "application/json" } },
        .payload = json_payload orelse buf,
        .keep_alive = false,
    });
}

pub fn getPageRaw(website: string) ![]u8 {
    var resbuff = std.Io.Writer.Allocating.init(allocator);
    defer resbuff.deinit();
    var client = std.http.Client{ .allocator = allocator, .io = IO };
    defer client.deinit();
    _ = try client.fetch(.{
        .location = .{ .uri = try std.Uri.parse(website) },
        .method = .GET,
        .response_writer = &resbuff.writer,
    });
    order = try allocator.dupe(u8, resbuff.written());
    if (order[order.len - 1] == '\n') order = try allocator.realloc(order, order.len - 1);
    used = true;
    return order;
}

pub fn _deinit() void {
    if (used) allocator.free(order);
}
