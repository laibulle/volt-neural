const std = @import("std");
const volt_neural = @import("volt_neural");
const audio_processor = @import("audio_processor.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Volt Neural Amp Modeler v0.1\n", .{});
    std.debug.print("========================\n\n", .{});

    // Get arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 4) {
        std.debug.print("Usage: volt_neural <input.wav> <model.nam> <output.wav> [ir.wav]\n", .{});
        std.debug.print("Example: volt_neural input.wav model.nam output.wav\n", .{});
        std.debug.print("Example with IR: volt_neural input.wav model.nam output.wav cabinet.wav\n", .{});
        return;
    }

    const input_path = args[1];
    const model_path = args[2];
    const output_path = args[3];
    const ir_path = if (args.len > 4) args[4] else null;

    std.debug.print("Input:  {s}\n", .{input_path});
    std.debug.print("Model:  {s}\n", .{model_path});
    if (ir_path) |ir| {
        std.debug.print("IR:     {s}\n", .{ir});
    }
    std.debug.print("Output: {s}\n\n", .{output_path});

    // Initialize processor
    var processor = if (ir_path) |ir|
        audio_processor.Processor.initWithIR(allocator, model_path, ir) catch |err| {
            std.debug.print("Failed to initialize processor with IR: {}\n", .{err});
            return err;
        }
    else
        audio_processor.Processor.init(allocator, model_path) catch |err| {
            std.debug.print("Failed to initialize processor: {}\n", .{err});
            return err;
        };
    defer processor.deinit();

    std.debug.print("Model loaded successfully!\n", .{});
    std.debug.print("Expected sample rate: {d} Hz\n", .{processor.model.expected_sample_rate});
    std.debug.print("Has input level: {}\n", .{processor.model.hasInputLevel()});
    std.debug.print("Has output level: {}\n", .{processor.model.hasOutputLevel()});
    if (processor.model.getLoudness()) |loudness| {
        std.debug.print("Loudness: {d} dB\n", .{loudness});
    }
    std.debug.print("\n", .{});

    // Process file
    processor.processFile(input_path, output_path) catch |err| {
        std.debug.print("Processing failed: {}\n", .{err});
        return err;
    };

    std.debug.print("\nDone!\n", .{});
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
