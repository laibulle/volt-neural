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
        std.debug.print("Usage: volt_neural <input.wav> <model.nam> <output.wav> [ir.wav] [OPTIONS]\n", .{});
        std.debug.print("\nOptions:\n", .{});
        std.debug.print("  --gain dB        Gain reduction before convolution (default: 0, no reduction)\n", .{});
        std.debug.print("  --no-ir          Process with NAM only, skip IR even if provided\n", .{});
        std.debug.print("\nExamples:\n", .{});
        std.debug.print("  volt_neural input.wav model.nam output.wav\n", .{});
        std.debug.print("  volt_neural input.wav model.nam output.wav cabinet.wav\n", .{});
        std.debug.print("  volt_neural input.wav model.nam output.wav cabinet.wav --gain -6\n", .{});
        std.debug.print("  volt_neural input.wav model.nam output.wav cabinet.wav --no-ir  (ignore IR)\n", .{});
        return;
    }

    const input_path = args[1];
    const model_path = args[2];
    const output_path = args[3];

    var ir_path: ?[]const u8 = null;
    var gain_db: f64 = 0.0; // Changed from -6.0 to 0.0 (no reduction by default)
    var skip_ir = false;

    // Parse remaining arguments
    var i: usize = 4;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--gain")) {
            if (i + 1 < args.len) {
                gain_db = std.fmt.parseFloat(f64, args[i + 1]) catch 0.0;
                i += 1;
            }
        } else if (std.mem.eql(u8, args[i], "--no-ir")) {
            skip_ir = true;
        } else if (!std.mem.startsWith(u8, args[i], "--")) {
            // Assume it's IR path if not a flag
            if (ir_path == null) {
                ir_path = args[i];
            }
        }
    }

    // Skip IR if requested
    if (skip_ir) {
        ir_path = null;
    }

    std.debug.print("Input:  {s}\n", .{input_path});
    std.debug.print("Model:  {s}\n", .{model_path});
    if (ir_path) |ir| {
        std.debug.print("IR:     {s}\n", .{ir});
        std.debug.print("Gain:   {d} dB\n", .{gain_db});
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

    // Apply gain setting if IR is used
    if (ir_path != null) {
        processor.pre_convolution_gain_db = gain_db;
    }

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
