const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const writer = std.io.getStdOut().writer();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var command = args[1];

    _ = try writer.write("Logs from your program will appear here!\n");
    if (std.mem.eql(u8, "decode", command) and args.len >= 3) {
        var bencodeValue = args[2];
        const decoded = decodeBencode(bencodeValue) catch |e| {
            _ = try printErr(allocator, "Error decoding {}", .{e});
            std.os.exit(64);
            return;
        };
        try std.json.encodeJsonString(decoded, .{}, writer);
    } else {
        _ = try writer.write("Command not found");
    }
}

fn decodeBencode(value: []const u8) ![]const u8 {
    if (isDigit(value[0])) {
        var colonIndex: usize = 0;
        for (value, 0..) |v, i| {
            if (v == ':') {
                colonIndex += i;
                break;
            }
        }
        var length = try std.fmt.parseInt(u8, value[0..colonIndex], 10);
        return value[colonIndex + 1 .. colonIndex + 1 + length];
    } else {
        return CommandError.InvalidArgument;
    }
}

const CommandError = error{
    InvalidArgument,
};

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}

fn printErr(allocator: std.mem.Allocator, comptime log: []const u8, args: anytype) !void {
    const writer = std.io.getStdOut().writer();
    const print = try std.fmt.allocPrint(allocator, log, args);
    defer allocator.free(print);
    _ = try writer.write(print);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
