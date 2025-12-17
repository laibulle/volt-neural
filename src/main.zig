const std = @import("std");
const volt_neural = @import("volt_neural");
const nam = @import("nam.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Volt Neural Amp Modeler v0.1\n", .{});

    // Get arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: volt_neural <input.wav> <model.nam> <output.wav>\n", .{});
        return;
    }

    const input_path = args[1];
    const model_path = args[2];
    const output_path = args[3];

    std.debug.print("Input:  {s}\n", .{input_path});
    std.debug.print("Model:  {s}\n", .{model_path});
    std.debug.print("Output: {s}\n", .{output_path});

    // Try to load the model
    var model = nam.Model.load(allocator, model_path) catch |err| {
        std.debug.print("Failed to load model: {}\n", .{err});
        return;
    };
    defer model.deinit();

    std.debug.print("Model loaded successfully!\n", .{});
    std.debug.print("Expected sample rate: {d} Hz\n", .{model.expected_sample_rate});
    std.debug.print("Has input level: {}\n", .{model.hasInputLevel()});
    std.debug.print("Has output level: {}\n", .{model.hasOutputLevel()});
    if (model.getLoudness()) |loudness| {
        std.debug.print("Loudness: {d} dB\n", .{loudness});
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
